-- NEORV32 FPGA Top Module for Rust Hello World Application
-- Generic top entity for FPGA implementation

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neorv32_top is
  port (
    -- Global control --
    clk_i       : in  std_logic;
    rstn_i      : in  std_logic;
    
    -- UART0 --
    uart0_txd_o : out std_logic;
    uart0_rxd_i : in  std_logic;
    
    -- GPIO --
    gpio_o      : out std_logic_vector(7 downto 0)
  );
end entity;

architecture neorv32_top_rtl of neorv32_top is

  -- CPU reset signal --
  signal reset_n : std_logic;

begin

  -- Reset signal --
  reset_n <= rstn_i;

  -- The Core of the NEORV32 RISC-V Processor ----------------------------------------
  neorv32_inst: entity work.neorv32_top
    generic map (
      -- General --
      CLOCK_FREQUENCY              => 100000000,  -- clock frequency of clk_i in Hz
      INT_BOOTLOADER_EN            => true,       -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
      
      -- RISC-V CPU Extensions --
      CPU_EXTENSION_RISCV_A        => false,      -- implement atomic extension?
      CPU_EXTENSION_RISCV_B        => false,      -- implement bit-manipulation extension?
      CPU_EXTENSION_RISCV_C        => true,       -- implement compressed extension?
      CPU_EXTENSION_RISCV_E        => false,      -- implement embedded RF extension?
      CPU_EXTENSION_RISCV_M        => true,       -- implement mul/div extension?
      CPU_EXTENSION_RISCV_U        => false,      -- implement user mode extension?
      CPU_EXTENSION_RISCV_Zfinx    => false,      -- implement 32-bit floating-point extension (using INT regs!)
      CPU_EXTENSION_RISCV_Zicntr   => true,       -- implement base counters?
      CPU_EXTENSION_RISCV_Zifencei => true,       -- implement instruction stream sync.?

      -- Memory Configuration: Instruction memory --
      MEM_INT_IMEM_EN              => true,       -- implement processor-internal instruction memory
      MEM_INT_IMEM_SIZE            => 64*1024,    -- size of processor-internal instruction memory in bytes
      
      -- Memory Configuration: Data memory --
      MEM_INT_DMEM_EN              => true,       -- implement processor-internal data memory
      MEM_INT_DMEM_SIZE            => 64*1024,    -- size of processor-internal data memory in bytes
      
      -- Memory Configuration: External memory interface --
      MEM_EXT_EN                   => false,      -- implement external memory bus interface?
      
      -- Processor peripherals --
      IO_GPIO_EN                   => true,       -- implement general purpose input/output port unit (GPIO)?
      IO_MTIME_EN                  => true,       -- implement machine system timer (MTIME)?
      IO_UART0_EN                  => true,       -- implement primary universal asynchronous receiver/transmitter (UART0)?
      IO_UART0_RX_FIFO             => 1,          -- RX fifo depth, has to be a power of two, min 1
      IO_UART0_TX_FIFO             => 1,          -- TX fifo depth, has to be a power of two, min 1
      IO_UART1_EN                  => false       -- implement secondary universal asynchronous receiver/transmitter (UART1)?
    )
    port map (
      -- Global control --
      clk_i       => clk_i,
      rstn_i      => reset_n,
      
      -- UART0 --
      uart0_txd_o => uart0_txd_o,
      uart0_rxd_i => uart0_rxd_i,
      
      -- GPIO (available if IO_GPIO_EN = true) --
      gpio_o      => gpio_o
    );

end architecture;
