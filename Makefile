# ============================================================
#  RISC-V Bare-Metal C Compilation Makefile
# ============================================================

# Toolchain prefix (cross-compiler)
CROSS_COMPILE ?= riscv32-unknown-elf-

CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# Directories
PROG_DIR = programs
FW_DIR   = firmware

# Files
SRC_C   = $(PROG_DIR)/program.c
SRC_S   = $(PROG_DIR)/crt0.s
LDS     = $(PROG_DIR)/linker.ld
ELF     = $(PROG_DIR)/program.elf
BIN     = $(PROG_DIR)/program.bin
HEX     = $(FW_DIR)/program.hex

# Compiler flags
# -march=rv32im   : Generate only RV32I base instructions + M (Multiply/Divide) extension
# -mabi=ilp32     : Standard 32-bit integer ABI
# -ffreestanding  : No OS environment, freestanding execution
# -O3             : Optimization level 3 (aggressive optimization to keep variables in registers)
# -nostdlib       : Do not link standard C libraries
# -nostartfiles   : Do not use default C runtime startup files
# -T              : Use our custom linker script
CFLAGS  = -march=rv32im -mabi=ilp32 -ffreestanding -O3 -nostdlib -nostartfiles -T $(LDS)

.PHONY: all clean compile hex disassemble

all: hex

$(ELF): $(SRC_S) $(SRC_C) $(LDS)
	@mkdir -p $(FW_DIR)
	$(CC) $(CFLAGS) $(SRC_S) $(SRC_C) -o $(ELF)

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

$(HEX): $(BIN)
	@mkdir -p $(FW_DIR)
	od -An -tx4 -w4 -v $(BIN) | tr -d ' ' > $(HEX)
	@echo "--------------------------------------------------------"
	@echo "Success! Compiled: $(SRC_C) -> $(HEX)"
	@echo "--------------------------------------------------------"

disassemble: $(ELF)
	$(OBJDUMP) -d $(ELF) > $(PROG_DIR)/program.dis

compile: $(ELF)

hex: $(HEX)

clean:
	rm -f $(ELF) $(BIN) $(HEX) $(PROG_DIR)/program.dis
