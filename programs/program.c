#define MEM_SIZE 255

volatile int mem[MEM_SIZE];

int add_func(int a, int b) {
    return a + b;              // tests jal/jalr, add
}

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