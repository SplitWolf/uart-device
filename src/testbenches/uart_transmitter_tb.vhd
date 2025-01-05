library ieee;
use ieee.std_logic_1164.all;

library basic_rtl;
use basic_rtl.all;


entity uart_transmitter_tb is
end uart_transmitter_tb;


architecture sim of uart_transmitter_tb is

    signal clock, reset, TDRE, bclock, data_out, loadTransmit: std_logic;
    signal data : std_logic_vector(7 downto 0);
    signal sim_end : boolean := false;
    constant period: time := 40 ns;
    -- constant period: time := 39.7220 ns; 
    constant bperiod: time := period*41*8;

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

baudRateGen: process
begin
    while (not sim_end) loop
    bclock <= '1';
    wait for bperiod/2;
    bclock <= '0';
    wait for bperiod/2;
    end loop;
    wait;
end process baudRateGen;


DUT: entity work.uart_transmitter
 port map(
    i_data => data,
    i_loadTDR => loadTransmit,
    i_clk => clock,
    i_baudClk => bclock,
    i_resetn => reset,
    o_tdre => tdre,
    o_txd => data_out
);
-- TDRE_in <= '1' when TDRE_set = '1' else TDRE;

tb: process
begin
data <= x"55";
loadTransmit <= '0';
reset <= '0', '1' after period;
wait for period - 2ns;
loadTransmit <= '1', '0' after period;
wait for bperiod*3;
-- wait for bperiod*25*8;
data <= x"AA";
loadTransmit <= '1', '0' after period;
wait for bperiod*25;

sim_end <= true;
report "Test: OK";
wait;
end process tb;    

end sim ; -- sim