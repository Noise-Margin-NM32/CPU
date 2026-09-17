#define MEM_SIZE 255

volatile int mem[MEM_SIZE];

int add_func(int a, int b) {
    return a + b;              // tests jal/jalr, add
}

/* ========================================================================= */
/* Hazard & Pipeline Stress Test Functions                                    */
/* ========================================================================= */

// RAW Test 1: Chained Back-to-Back ALU Forwarding (Stage 3 -> Stage 2)
static inline int test_raw_alu_chain(int start) {
    int res;
    __asm__ volatile (
        "addi %0, %1, 10\n\t"    // %0 = start + 10
        "addi %0, %0, 20\n\t"    // %0 = %0 + 20 (RAW)
        "sub  %0, %0, %1\n\t"    // %0 = %0 - start (RAW)
        "slli %0, %0, 2\n\t"     // %0 = %0 << 2 (RAW)
        : "=r"(res)
        : "r"(start)
    );
    return res; // (start + 10 + 20 - start) << 2 = 30 << 2 = 120
}

// RAW Test 2: Load-to-Use Hardware Stall + Bubble + Forwarding
static inline int test_raw_load_use(int val) {
    volatile int temp = val;
    int res;
    __asm__ volatile (
        "lw   %0, 0(%1)\n\t"     // Load value
        "addi %0, %0, 42\n\t"    // Immediate consumer! Must stall 1 cycle
        : "=&r"(res)
        : "r"(&temp)
        : "memory"
    );
    return res; // val + 42
}

// RAW Test 3: Multi-Cycle Multiplier RAW Stall + Forwarding
static inline int test_raw_mul(int a, int b) {
    int res;
    __asm__ volatile (
        "mul  %0, %1, %2\n\t"    // Multiplier takes 2 cycles, asserts alu_busy
        "addi %0, %0, 15\n\t"    // Immediate consumer! Must stall until MUL completes
        : "=&r"(res)
        : "r"(a), "r"(b)
    );
    return res; // (a * b) + 15
}

// RAW Test 4: Multi-Cycle Divider RAW Stall + Forwarding
static inline int test_raw_div(int a, int b) {
    int res;
    __asm__ volatile (
        "div  %0, %1, %2\n\t"    // Divider takes 32 cycles, asserts alu_busy
        "addi %0, %0, 99\n\t"    // Immediate consumer! Must stall 32 cycles
        : "=&r"(res)
        : "r"(a), "r"(b)
    );
    return res; // (a / b) + 99
}

// RAW Test 5: Multi-Cycle Multiplier into Store Data & Load
static inline int test_raw_mul_store(int a, int b) {
    volatile int scratch = 0;
    int res;
    __asm__ volatile (
        "mul  t0, %1, %2\n\t"    // t0 = a * b
        "sw   t0, 0(%3)\n\t"     // Store uses t0 immediately
        "lw   %0, 0(%3)\n\t"     // Load back
        "addi %0, %0, 5\n\t"     // Load-use
        : "=&r"(res)
        : "r"(a), "r"(b), "r"(&scratch)
        : "t0", "memory"
    );
    return res; // (a * b) + 5
}

// RAW Test 6: Multi-Cycle Divider into Branch Condition
static inline int test_raw_div_branch(int a, int b, int expected_q) {
    int res = 0;
    __asm__ volatile (
        "div  t0, %1, %2\n\t"    // t0 = a / b (32-cycle)
        "beq  t0, %3, 1f\n\t"    // Branch condition uses t0 immediately!
        "addi %0, zero, 0\n\t"
        "j    2f\n"
        "1:\n\t"
        "addi %0, zero, 1\n"
        "2:\n\t"
        : "=&r"(res)
        : "r"(a), "r"(b), "r"(expected_q)
        : "t0"
    );
    return res; // 1 if condition evaluated correctly after DIV stall
}

// WAR Test 1: Write-After-Read Integrity
static inline int test_war(int x, int y) {
    int res1, res2;
    __asm__ volatile (
        "mv   t0, %2\n\t"        // t0 = x (e.g. 50)
        "mv   t1, %3\n\t"        // t1 = y (e.g. 10)
        "add  %0, t0, t1\n\t"    // %0 = t0 + t1 (Reads t0, t1)
        "addi t0, zero, 999\n\t" // Overwrites t0 immediately in next cycle!
        "mv   %1, t0\n\t"
        : "=&r"(res1), "=&r"(res2)
        : "r"(x), "r"(y)
        : "t0", "t1"
    );
    return (res1 == (x + y) && res2 == 999) ? 1 : 0;
}

// WAW Test 1: Multi-Cycle MUL followed immediately by Single-Cycle Write
static inline int test_waw_mul_alu(int a, int b) {
    int res;
    __asm__ volatile (
        "mul  t0, %1, %2\n\t"    // Multi-cycle write to t0
        "addi t0, zero, 777\n\t" // Single-cycle write to same t0
        "mv   %0, t0\n\t"
        : "=&r"(res)
        : "r"(a), "r"(b)
        : "t0"
    );
    return res; // Must be 777 (younger instruction wins)
}

// WAW Test 2: Consecutive ALU Writes
static inline int test_waw_alu(void) {
    int res;
    __asm__ volatile (
        "addi t0, zero, 111\n\t"
        "addi t0, zero, 222\n\t"
        "addi t0, zero, 333\n\t"
        "mv   %0, t0\n\t"
        : "=&r"(res)
        :
        : "t0"
    );
    return res; // Must be 333
}

// Mixed Multi-Unit Stress Pipeline
static inline int test_mixed_pipeline_stress(void) {
    volatile int scratch = 0;
    int final_val;
    __asm__ volatile (
        "addi t0, zero, 12\n\t"
        "addi t1, zero, 8\n\t"
        "add  t2, t0, t1\n\t"       // t2 = 20 (1 cycle)
        "addi t3, zero, 6\n\t"
        "mul  t4, t2, t3\n\t"       // t4 = 20 * 6 = 120 (2 cycles, RAW on t2)
        "addi t5, zero, 5\n\t"
        "div  t6, t4, t5\n\t"       // t6 = 120 / 5 = 24 (32 cycles, RAW on t4)
        "addi a4, zero, 7\n\t"
        "rem  a5, t6, a4\n\t"       // a5 = 24 % 7 = 3   (32 cycles, RAW on t6)
        "sw   a5, 0(%1)\n\t"        // Store 3 to scratch (RAW on a5)
        "lw   a6, 0(%1)\n\t"        // Load 3
        "addi %0, a6, 200\n\t"      // %0 = 3 + 200 = 203 (Load-use hazard on a6)
        : "=&r"(final_val)
        : "r"(&scratch)
        : "t0","t1","t2","t3","t4","t5","t6","a4","a5","a6","memory"
    );
    return final_val; // Expect 203
}

/* ========================================================================= */
/* Main Test Suite                                                           */
/* ========================================================================= */

void test_riscv_instructions(void) {
    int i;
    int a = 15, b = 7, c = -4, d = 3;
    unsigned int ua = 0xFFFFFF00;

    /* ---- Arithmetic (R-type & I-type) ---- */
    mem[0]  = a + b;           // add
    mem[1]  = a - b;           // sub
    mem[2]  = a * b;           // mul
    mem[3]  = a / b;           // div
    mem[4]  = a % b;           // rem
    mem[5]  = a + 100;         // addi

    /* ---- Logical ---- */
    mem[6]  = a & b;           // and
    mem[7]  = a | b;           // or
    mem[8]  = a ^ b;           // xor
    mem[9]  = a & 0x0F;        // andi
    mem[10] = a | 0x0F;        // ori
    mem[11] = a ^ 0x0F;        // xori

    /* ---- Shifts ---- */
    mem[12] = a << d;          // sll / slli
    mem[13] = a >> d;          // sra / srai (signed)
    mem[14] = (int)(ua >> d);  // srl / srli (unsigned)

    /* ---- Comparisons ---- */
    mem[15] = (a < b) ? 1 : 0;   // slt
    mem[16] = (a < 20) ? 1 : 0;  // slti
    mem[17] = (ua < 5u) ? 1 : 0; // sltu

    /* ---- Branches / loop control ---- */
    int sum = 0;
    for (i = 0; i < 10; i++) {   // beq/bne/blt/bge in loop compare
        sum += i;
    }
    mem[18] = sum;

    if (a == 15) mem[19] = 1; else mem[19] = 0;  // beq
    if (a != b)  mem[20] = 1; else mem[20] = 0;   // bne
    if (a > b)   mem[21] = 1; else mem[21] = 0;   // blt/bge
    if (c < 0)   mem[22] = 1; else mem[22] = 0;   // blt (negative operand)

    /* ---- Function call ---- */
    mem[23] = add_func(a, b);  // jal/jalr, stack usage

    /* ---- Byte / half loads & stores ---- */
    char *cptr = (char *)&mem[24];
    *cptr = 0x7F;               // sb
    mem[25] = *cptr;            // lb

    short *sptr = (short *)&mem[26];
    *sptr = 0x1234;             // sh
    mem[27] = *sptr;            // lh

    unsigned char *ucptr = (unsigned char *)&mem[28];
    *ucptr = 0xFF;
    mem[29] = *ucptr;           // lbu

    /* ---- Word load/store, large immediate ---- */
    mem[30] = 0xDEADBEEF;       // lui + addi/ori + sw
    mem[31] = mem[30];          // lw

    /* ---- Signed edge cases ---- */
    mem[32] = -a;                // sub (0 - a)
    mem[33] = a * -b;            // mul with negative operand

    /* ---- Address computation / array indexing ---- */
    for (i = 0; i < 20; i++) {
        mem[34 + i] = i * i;     // exercises repeated address calc
    }

    /* ---- Hazard & Multi-Unit Stress Tests ---- */
    mem[50] = test_raw_alu_chain(5);               // Expected: 120
    mem[51] = test_raw_load_use(42);               // Expected: 84 (42 + 42)
    mem[52] = test_raw_mul(10, 10);                // Expected: 115 ((10 * 10) + 15)
    mem[53] = test_raw_div(100, 10);               // Expected: 109 ((100 / 10) + 99)
    mem[54] = test_raw_mul_store(7, 10);           // Expected: 75 ((7 * 10) + 5)
    mem[55] = test_raw_div_branch(100, 5, 20);     // Expected: 1 (Branch on DIV quotient)
    mem[56] = test_war(50, 10);                    // Expected: 1 (WAR integrity)
    mem[57] = test_waw_mul_alu(5, 5);              // Expected: 777 (WAW younger write wins)
    mem[58] = test_waw_alu();                      // Expected: 333 (WAW consecutive ALU writes)
    mem[59] = test_mixed_pipeline_stress();        // Expected: 203 (Mixed multi-unit stress)

    /* ---- Completion marker ---- */
    mem[254] = 0xABCD1234;
}

int main(void) {
    test_riscv_instructions();
    while (1) {
        /* halt / spin so bare-metal sim doesn't run off the end */
    }
    return 0;
}