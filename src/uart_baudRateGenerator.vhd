library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library basic_rtl;
use basic_rtl.all;

entity uart_baudRateGenerator is
    port(
        i_rateSel: in std_logic_vector(2 downto 0);
        i_clk: in std_logic;
        i_resetn: in std_logic;
        o_baudClk: out std_logic;
        o_baudClkx8: out std_logic
    );
end uart_baudRateGenerator;

architecture rtl of uart_baudRateGenerator is

    signal clock_304878Hz: std_logic;
    signal int_count8_value: std_logic_vector(7 downto 0);
    signal count_div8: std_logic_vector(2 downto 0);
    signal int_rateMuxDiv8, baudClk_int: std_logic;
    signal int_rateMuxOut: std_logic;

begin

-- Output Drivers
o_baudClk <= baudClk_int;
o_baudClkx8 <= int_rateMuxOut;

--

clk_div41_inst: entity work.clk_div41
 port map(
    clock_25Mhz => i_clk,
    clock_304878Hz => clock_304878Hz
);

div256: entity basic_rtl.counterNbits
 generic map(
    DataWidth => 8,
    InvertCountDirecton => FALSE
)
 port map(
    i_in => "00000000",
    i_load => '0',
    i_clk => clock_304878Hz,
    i_cen => '1',
    i_resetn => i_resetn,
    o_value => int_count8_value,
    o_zero => open
);


rateSelMux: entity basic_rtl.busMux8x1
    generic map(
        DataWidth => 1
    )
    port map(
        i_in0(0) => int_count8_value(0),
        i_in1(0) => int_count8_value(1),
        i_in2(0) => int_count8_value(2),
        i_in3(0) => int_count8_value(3),
        i_in4(0) => int_count8_value(4),
        i_in5(0) => int_count8_value(5),
        i_in6(0) => int_count8_value(6),
        i_in7(0) => int_count8_value(7),
        i_sel => i_rateSel,
        o_out(0) => int_rateMuxOut
    );
    -- TODO: Turn this into RTL Code
    PROCESS
    BEGIN
        WAIT UNTIL rising_edge(i_clk);
        baudClk_int <= int_rateMuxDiv8;
    END PROCESS;

    PROCESS (int_rateMuxOut, i_resetn)
	BEGIN
        IF i_resetn = '0' THEN
            count_div8 <= "000";
            int_rateMuxDiv8 <='0';
        ELSIF rising_edge(int_rateMuxOut) THEN
            -- IF count_div8 < 7 THEN
                count_div8 <= count_div8 + 1;
			-- ELSE
                -- count_div8 <= "000";
			-- END IF;
			IF count_div8 < 4 THEN
                int_rateMuxDiv8 <= '0';
			ELSE
                int_rateMuxDiv8 <= '1';
			END IF;
        END IF;
	END PROCESS;

end rtl ; -- rtl