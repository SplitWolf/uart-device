library ieee;
use ieee.std_logic_1164.all;

library basic_rtl;
use basic_rtl.all;


entity uart_receiver_tb is
end uart_receiver_tb;

architecture sim of uart_receiver_tb is
    signal clock, reset, bclockx8: std_logic;
    signal data, rdrf, readRDR, frame_error, overrun_error: std_logic;
    signal data_in, data_out: std_logic_vector(7 downto 0);
    signal sim_end : boolean := false;
    constant period: time := 40 ns;
    -- constant period: time := 39.7220 ns;
    constant bperiod: time := period*41;

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

baudRateGenx8: process
begin
    while (not sim_end) loop
        bclockx8 <= '1';
        wait for bperiod/2;
        bclockx8 <= '0';
        wait for bperiod/2;
    end loop;
    wait;
end process baudRateGenx8;

DUT: entity work.uart_receiver
 port map(
    i_rxd => data,
    i_clk => clock,
    i_baudClkx8 => bclockx8,
    i_readRDR => readRDR,
    i_resetn => reset,
    o_oe => overrun_error,
    o_fe => frame_error,
    o_rdrf => rdrf,
    o_rdr => data_out
);

-- Simulation Controller
tb: process
begin
reset <= '0', '1' after period;
wait for period;

wait for bperiod*135*3;

sim_end <= true;
report "Test: OK";
wait;
end process tb;    

-- Data Generator
dataGen: process
begin
    readRDR <= '0';
    -- DATA = x"55"
    data_in <= x"55";
    -- Stop bits
    for i in 0 to 4 loop
        data <= '1';
        wait for bperiod*8;
    end loop;   
    -- Start Bit
    data <= '0';
    wait for bperiod*8;
    for i in 0 to 7 loop
        data <= data_in(i);
        wait for bperiod*8;
    end loop;
    -- Stop bit -- TODO: FRAME ERROR (DISABLED)
    data <= '1';
    wait for bperiod*8;
    wait for bperiod*8;
    wait for bperiod*8;
    -- DATA = x"AA"
    data_in <= x"AA";
    -- Stop bits
    for i in 0 to 4 loop
        data <= '1';
        wait for bperiod*8;
    end loop;   
    -- Start Bit
    data <= '0';
    wait for bperiod*8;
    for i in 0 to 7 loop
        data <= data_in(i);
        wait for bperiod*8;
    end loop;
    -- Stop bit
    data <= '1';
    wait for bperiod*8;
    readRDR <= '1';
    -- DATA = x"47"
    data_in <= x"47";
    -- Stop bits
    for i in 0 to 4 loop
        data <= '1';
        wait for bperiod*8;
    end loop;   
    -- Start Bit
    data <= '0';
    wait for bperiod*8;
    for i in 0 to 7 loop
        data <= data_in(i);
        wait for bperiod*8;
    end loop;
    -- Stop bit
    data <= '1';
    wait for bperiod*8;
    

    wait;
end process;

end sim ; -- sim