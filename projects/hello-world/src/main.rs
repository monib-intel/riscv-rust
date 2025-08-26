#![no_std]
#![no_main]

use core::panic::PanicInfo;

// PicoRV32 UART base address (adjust based on your actual hardware configuration)
const UART_TX_ADDR: usize = 0x02000000;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// Simple function to write to a memory-mapped register
unsafe fn write_mmio(addr: usize, val: u8) {
    core::ptr::write_volatile(addr as *mut u8, val);
}

// Write a byte to UART
fn uart_putc(c: u8) {
    unsafe {
        write_mmio(UART_TX_ADDR, c);
    }
}

// Write a string to UART
fn uart_puts(s: &str) {
    for c in s.bytes() {
        uart_putc(c);
    }
}

// Entry point directly - no separate assembly
#[no_mangle]
pub extern "C" fn _start() -> ! {
    // Print hello world message
    uart_puts("Hello, World from Rust on PicoRV32!\r\n");
    
    // Loop forever
    loop {}
}
