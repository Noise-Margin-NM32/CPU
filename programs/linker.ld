MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 1K   /* 256 instruction words (1024 bytes) */
    RAM (w)   : ORIGIN = 0x00000000, LENGTH = 1K   /* 256 data words (1024 bytes) */
}

SECTIONS
{
    /* Code section maps directly to Instruction ROM */
    .text : {
        *(.text.start)
        *(.text)
        *(.text.*)
    } > ROM

    /* Data and Read-Only Constants map to Data RAM */
    .data : {
        *(.data)
        *(.data.*)
        *(.rodata)
        *(.rodata.*)
    } > RAM AT > ROM

    /* Uninitialized variables (like our mem array) map to RAM */
    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > RAM
}
