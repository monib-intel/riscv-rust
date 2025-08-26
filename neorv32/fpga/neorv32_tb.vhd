-- NEORV32 Testbench for simulating the Rust Hello World Application

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neorv32_tb is
end entity;

architecture neorv32_tb_rtl of neorv32_tb is

  -- DUT signals
  signal clk        : std_logic := '0';
  signal rst_n      : std_logic := '0';
  signal uart_tx    : std_logic;
  signal uart_rx    : std_logic := '1';  -- idle high
  signal gpio       : std_logic_vector(7 downto 0);
  
  -- Simulation control
  signal sim_done   : boolean := false;
  constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

begin

  -- Clock generator
  clk_gen: process
  begin
    while not sim_done loop
      clk <= not clk;
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Reset process
  reset_gen: process
  begin
    rst_n <= '0';
    wait for 100 ns;
    rst_n <= '1';
    wait;
  end process;

  -- Device Under Test
  DUT: entity work.neorv32_top
    port map (
      clk_i       => clk,
      rstn_i      => rst_n,
      uart0_txd_o => uart_tx,
      uart0_rxd_i => uart_rx,
      gpio_o      => gpio
    );

  -- UART receiver monitor
  uart_monitor: process
    variable uart_data : integer;
    variable bit_time  : time := 8680 ns; -- for 115200 baud rate
  begin
    wait until uart_tx = '0';  -- start bit
    wait for bit_time * 1.5;   -- middle of first data bit
    
    for i in 0 to 7 loop
      uart_data := uart_data * 2;
      if uart_tx = '1' then
        uart_data := uart_data + 1;
      end if;
      wait for bit_time;  -- next bit
    end loop;
    
    -- Print the received character
    report "UART received: " & character'val(uart_data);
    
    -- Check for stop bit
    assert uart_tx = '1' report "UART stop bit not detected!" severity error;
    wait for bit_time;
  end process;

  -- Simulation control
  sim_control: process
  begin
    wait for 100 ms;  -- Simulate for 100 ms
    sim_done <= true;
    wait;
  end process;

end architecture;
