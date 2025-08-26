#![no_std]
#![no_main]

use core::panic::PanicInfo;
use riscv_rt::entry;

// NEORV32 UART0 base address (from neorv32 datasheet)
const UART0_BASE: usize = 0xFFFFFFC0;

// Register offsets
const UART_DATA: usize = 0x00;
const UART_CTRL: usize = 0x04;

// UART control bits
const UART_CTRL_EN: u32 = 1 << 0; // UART enable
const UART_CTRL_TX_EN: u32 = 1 << 1; // UART TX enable

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// Simple function to write to a memory-mapped register
unsafe fn write_mmio(addr: usize, val: u32) {
    core::ptr::write_volatile(addr as *mut u32, val);
}

// Simple function to read from a memory-mapped register
unsafe fn read_mmio(addr: usize) -> u32 {
    core::ptr::read_volatile(addr as *const u32)
}

// Initialize UART0
fn init_uart() {
    unsafe {
        // Enable UART0 and TX
        write_mmio(UART0_BASE + UART_CTRL, UART_CTRL_EN | UART_CTRL_TX_EN);
    }
}

// Write a single byte to UART0
fn uart_putc(c: u8) {
    unsafe {
        // Wait until TX buffer is ready (can accept new data)
        while (read_mmio(UART0_BASE + UART_CTRL) & (1 << 15)) == 0 {}
        
        // Write byte to TX buffer
        write_mmio(UART0_BASE + UART_DATA, c as u32);
    }
}

// Write a string to UART0
fn uart_puts(s: &str) {
    for c in s.bytes() {
        uart_putc(c);
    }
}

#[entry]
fn main() -> ! {
    // Initialize UART
    init_uart();
    
    // Print hello world message
    uart_puts("Hello, World from Rust on NEORV32!\r\n");
    
    // Loop forever
    loop {}
}
