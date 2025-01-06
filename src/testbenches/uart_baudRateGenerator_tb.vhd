library ieee;
use ieee.std_logic_1164.all;


library basic_rtl;
use basic_rtl.all;

entity uart_baudRateGenerator_tb is
end uart_baudRateGenerator_tb;

architecture sim of uart_baudRateGenerator_tb is

    signal clock, reset: std_logic;
    signal rateSel: std_logic_vector(2 downto 0);
    signal bclock, bclockx8: std_logic;
    signal sim_end : boolean := false;
    constant period: time := 39.69780443 ns;
    -- constant period: time := 39.7220 ns; 
    -- constant period: time := 50 ns; 

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

DUT: entity work.uart_baudRateGenerator
        port map (
            i_rateSel => rateSel,
            i_clk => clock,
            i_resetn => reset,
            o_baudClk => bclock,
            o_baudClkx8 => bclockx8
        );

tb: process
begin
rateSel <= "000";
reset <= '0', '1' after period;
wait for period*8000;
-- TODO: Add check for bclk freq and blckx8 freq

sim_end <= true;
report "Test: OK";
wait;
end process tb;    

end sim ; -- sim