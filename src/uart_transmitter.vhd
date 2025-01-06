library ieee;
use ieee.std_logic_1164.all;

library basic_rtl;
use basic_rtl.all;

entity uart_transmitter is
    port(
        i_data: in std_logic_vector(7 downto 0);
        i_loadTDR: in std_logic;
        i_clk: in std_logic;
        i_baudClk: in std_logic;
        i_resetn: in std_logic;
        o_tdre: out std_logic;
        o_txd: out std_logic
    );
end uart_transmitter;

architecture rtl of uart_transmitter is
    
    -- Data signals
    signal out_TDR: std_logic_vector(7 downto 0); 
    signal int_in_state0, int_in_state1, int_in_state2, int_in_state3: std_logic;
    signal int_out_state0, int_out_state1, int_out_state2, int_out_state3: std_logic;
    signal int_in_txdBUF, int_out_txdBUF: std_logic;
    signal int_in_tdre, int_out_tdre, int_tdreLd: std_logic;
    signal int_loadTDR_sync, int_out_tsr: std_logic;
    -- Control Singals
    signal int_bitCountZero, int_enableCounter, int_loadCounter: std_logic;
    signal int_loadTSR, int_shiftTSR, int_cenTSR: std_logic; 
    -- Constant Signals
    signal const_vcc, const_gnd: std_logic;
begin
    const_vcc <= '1';
    const_gnd <= '0';

    -- Output drivers
    o_tdre <= int_out_tdre;
    o_txd <= int_out_txdBUF;

    -- Control Logic
    int_loadTSR <=int_out_state1;
    int_shiftTSR <=int_out_state3;
    int_cenTSR <= int_loadTSR or int_shiftTSR;
    int_enableCounter <= int_out_state3 or int_loadCounter;
    int_loadCounter <= int_out_state2;
    int_in_txdBUF <= int_out_state0 or int_out_state1 or (int_out_state3 and int_out_tsr); 
    int_in_tdre <= int_out_state1;
    int_tdreLd <= ((int_out_state0 or int_out_state2 or int_out_state3) and int_loadTDR_sync) or int_out_state1;

    -- Next state logic
    int_in_state0 <= (int_out_state0 and int_out_tdre) or (int_out_state3 and int_bitCountZero);
    int_in_state1 <= (int_out_state0 and not int_out_tdre);
    int_in_state2 <= int_out_state1;
    int_in_state3 <= int_out_state2 or (int_out_state3 and not int_bitCountZero);

    -- Syncronize the load signal from the other clock domain TODO: Remove this sync if possible and clk TDRE with i_clk
    sync_loadTDR: entity basic_rtl.pulse_synchronizer
    port map(
        i_raw => i_loadTDR,
        i_clkIn => i_clk,
        i_clkOut => i_baudClk,
        i_resetn => i_resetn,
        o_pulse => int_loadTDR_sync
    );

    -- Bit counter
    count8: entity basic_rtl.counterNbits
    generic map(
       DataWidth => 3,
       InvertCountDirecton => TRUE
   )
    port map(
       i_in => "111",
       i_load => int_loadCounter,
       i_cen => int_enableCounter,
       i_clk => i_baudClk,
       i_resetn => i_resetn,
       o_value => open,
       o_zero => int_bitCountZero
   );

    -- Transmitter buffers
    TDR: entity basic_rtl.registerNbits
    generic map(
        DataWidth => 8
    )
    port map(
        i_in => i_data,
        i_load => i_loadTDR,
        i_clk => i_clk,
        i_cen => const_vcc,
        i_resetn => i_resetn,
        o_out => out_TDR
    );
    TSR: entity basic_rtl.pipoShiftRegisterNBits
    generic map(
        DataWidth => 8
    )
    port map(
        i_in => out_TDR,
        i_serialIn => const_vcc,
        i_shitleftn_shiftright => const_vcc,
        i_resetn => i_resetn,
        i_load => int_loadTSR,
        i_clk => i_baudClk,
        i_cen => int_cenTSR,
        o_serialOut => int_out_tsr,
        o_out => open
    );
    TXD_BUF: entity basic_rtl.synth_enasdFF
    port map(
        i_d => int_in_txdBUF,
        i_cen => const_vcc,
        i_clk => i_baudClk,
        i_setn => i_resetn,
        o_q => int_out_txdBUF,
        o_qn => open
    );
    TDRE_BUF: entity basic_rtl.synth_enasdFF
    port map(
        i_d => int_in_tdre,
        i_cen => int_tdreLd,
        i_clk => i_baudClk,
        i_setn => i_resetn,
        o_q => int_out_tdre,
        o_qn => open
    );

-- State machine storage
state0: entity basic_rtl.synth_enasdFF
    port map(
        i_d => int_in_state0,
        i_cen => const_vcc,
        i_clk => i_baudClk,
        i_setn => i_resetn,
        o_q => int_out_state0,
        o_qn => open
    );
state1: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state1,
        i_cen => const_vcc,
        i_clk => i_baudClk,
        i_resetn => i_resetn,
        o_q => int_out_state1,
        o_qn => open
    );
state2: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state2,
        i_cen => const_vcc,
        i_clk => i_baudClk,
        i_resetn => i_resetn,
        o_q => int_out_state2,
        o_qn => open
    );
state3: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state3,
        i_cen => const_vcc,
        i_clk => i_baudClk,
        i_resetn => i_resetn,
        o_q => int_out_state3,
        o_qn => open
    );
end rtl;