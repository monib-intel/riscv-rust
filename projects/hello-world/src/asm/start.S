.section .text.entry
.global _start
.type _start, @function

_start:
    # Initialize stack pointer
    la sp, _stack_start
    
    # Zero out the bss section
    la t0, _bss_start
    la t1, _bss_end
    beq t0, t1, bss_zero_done
bss_zero_loop:
    sw zero, 0(t0)
    addi t0, t0, 4
    blt t0, t1, bss_zero_loop
bss_zero_done:
    
    # Jump to Rust main
    call main
    
    # If main returns, just spin
1:  wfi
    j 1b

.size _start, . - _start
