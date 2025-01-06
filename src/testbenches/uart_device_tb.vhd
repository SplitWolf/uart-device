library ieee;
use ieee.std_logic_1164.all;

library basic_rtl;
use basic_rtl.all;


entity uart_device_tb is
end uart_device_tb;

architecture sim of uart_device_tb is
    signal clock, reset: std_logic;
    signal data: std_logic_vector(7 downto 0);
    signal address: std_logic_vector(1 downto 0);
    signal RXD, TXD, IRQ: std_logic;
    signal writen_read: std_logic;
    signal uSelect: std_logic;

    signal sim_end : boolean := false;
    constant period: time := 40  ns;

begin

clk: process
begin
    while (not sim_end) loop
        clock <= '1';
        wait for period/2;
        clock <= '0';
        wait for period/2;
    end loop;
    wait;
end process clk;

DUT: entity work.uart_device
 port map(
    i_rxd => RXD,
    i_address => address,
    i_writen_read => writen_read,
    i_uartSelect => uSelect,
    i_clk => clock,
    i_resetn => reset,
    o_txd => TXD,
    o_irq => IRQ,
    io_data_bus => data
);


RXD <= TXD;

tb: process
begin
    -- Init
    address <= 2X"1";
    writen_read <= '0';
    data <= x"00";
    uSelect <= '0';
    reset <= '0', '1' after period;
    wait for period;
    -- Enable Interupts
    address <= 2X"2";
    writen_read <= '0';
    data <= x"C0";
    uSelect <= '1';
    wait for period;
    -- Send x"55"
    address <= 2X"0";
    writen_read <= '0';
    data <= x"55" after 2ns;
    uSelect <= '1';
    wait for period;
    uSelect <= '0';
    wait for period;
    data <= (others => 'Z');
    wait for 400us;
    -- Read the Receive Register (data loopback test)
    address <= 2X"0";
    writen_read <= '1';
    data <= (others => 'Z');
    uSelect <= '1','0' after 10us;
    wait for 15us;
    -- Attempt to write the Status Register (should fail to write)
    address <= 2X"1";
    writen_read <= '0';
    data <= x"FF";
    uSelect <= '1','0' after 10us;
    wait for 15us;
    -- Read the Status Register
    address <= 2X"1";
    writen_read <= '1';
    data <= (others => 'Z');
    uSelect <= '1','0' after 10us;
    wait for 15us;
    -- Read the Control Register
    address <= 2X"2";
    writen_read <= '1';
    data <= (others => 'Z');
    uSelect <= '1','0' after 10us;
    wait for 15us;


    report "Test: OK";
    sim_end <= true;
    wait;
end process;


end sim;