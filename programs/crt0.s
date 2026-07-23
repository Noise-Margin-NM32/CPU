.section .text.start
.global _start

_start:
    # Initialize stack pointer to the top of data RAM (1024 bytes = 0x400)
    li sp, 1024
    
    # Call the main function of the C program
    call main

_halt:
    # Infinite loop if main returns
    j _halt
