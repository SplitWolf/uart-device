library ieee;
use ieee.std_logic_1164.all;

library basic_rtl;
use basic_rtl.all;

entity uart_receiver is
    port (
      i_rxd: in std_logic;
      i_clk: in std_logic;
      i_baudClkx8: in std_logic;
      i_readRDR: in std_logic;
      i_resetn: in std_logic;
      o_oe: out std_logic;
      o_fe: out std_logic;
      o_rdrf: out std_logic;
      o_rdr: out std_logic_vector(7 downto 0)
    );
end uart_receiver;

architecture rtl of uart_receiver is

    -- Constant Signals
    signal const_vcc, const_gnd: std_logic;
    
    -- Data Signals
    signal int_in_state0, int_in_state1, int_in_state2, int_in_state3, int_in_state4, int_in_state5: std_logic;
    signal int_out_state0, int_out_state1, int_out_state2, int_out_state3, int_out_state4, int_out_state5: std_logic;
    signal int_out_RDR, int_RSR_out: std_logic_vector(7 downto 0); 
    signal int_loadRDR, int_readRDR_sync, int_cenRSR: std_logic;
    signal int_rdrfLd, int_in_rdrf, int_out_rdrf: std_logic;
    signal int_stopLd, int_out_stop: std_logic;
    signal int_feLd, int_in_fe, int_out_fe: std_logic;
    signal int_oeLd,int_in_oe, int_out_oe: std_logic;

    -- Counter Singals
    signal int_count4clocksZ, int_count8clocksZ, int_count8BitsZ: std_logic;
    signal int_count4clocksEn, int_count8clocksEn, int_count8BitsEn: std_logic;
    signal int_count4clocksLd, int_count8clocksLd, int_count8BitsLd: std_logic;

begin
    const_vcc <= '1';
    const_gnd <= '0';

    -- Output drivers
    o_fe <= int_out_fe;
    o_oe <= int_out_oe;
    o_rdr <= int_out_RDR;
    o_rdrf <= int_out_rdrf;

    -- Control logic
    int_in_fe <= (int_out_state5 and not int_out_stop);
    int_in_oe <= (int_out_state4 and not int_readRDR_sync and int_out_rdrf);
    int_in_rdrf <= int_out_state5;

    int_feLd <= (int_out_state0 and not int_out_oe and i_rxd and not int_out_rdrf) 
        or (int_out_state5 and not int_out_stop);
    int_oeLd <= (int_out_state0 and int_out_oe and int_readRDR_sync)
        or (int_out_state4 and not int_readRDR_sync and int_out_rdrf);
    int_rdrfLd <= (int_out_state0 and int_readRDR_sync) 
        or (int_out_state1 and int_readRDR_sync)
        or (int_out_state2 and int_readRDR_sync)
        or (int_out_state3 and int_readRDR_sync)
        or (int_out_state4 and int_readRDR_sync)
        or int_out_state5;

    int_cenRSR <= int_out_state3;
    int_stopLd <= int_out_state4;

    int_loadRDR <= int_out_state5;

    -- Counters
    int_count4clocksLd <= int_out_state0;
    int_count8clocksLd <= int_out_state0 or int_out_state3;
    int_count8BitsLd <= int_out_state0;

    int_count4clocksEn <= int_count4clocksLd or int_out_state1;
    int_count8clocksEn <= int_count8clocksLd or int_out_state2;
    int_count8BitsEn <= int_count8BitsLd or int_out_state3;

    -- Next state logic
    int_in_state0 <= (int_out_state0 and int_out_oe and not int_readRDR_sync)
        or (int_out_state0 and not int_out_oe and i_rxd)
        or (int_out_state0 and not int_out_oe and not i_rxd and int_out_fe)
        or (int_out_state5)
        or (int_out_state4 and not int_readRDR_sync and int_out_rdrf);
    int_in_state1 <= (int_out_state0 and not i_rxd and not int_out_oe and not int_out_fe) or (int_out_state1 and not int_count4clocksZ);
    int_in_state2 <= (int_out_state1 and int_count4clocksZ) or (int_out_state2 and not int_count8clocksZ) or (int_out_state3);
    int_in_state3 <= (int_out_state2 and int_count8clocksZ and not int_count8BitsZ);
    int_in_state4 <=int_out_state2 and int_count8clocksZ and int_count8BitsZ;
    int_in_state5 <= (int_out_state4 and int_readRDR_sync) 
        or (int_out_state4 and not int_readRDR_sync and not int_out_rdrf) 
        or (int_out_state0 and int_out_oe and int_readRDR_sync);

    -- Syncronize the read signal from the other clock domain TODO: Remove this sync if possible and clk RDRF with i_clk
    sync_readRDR: entity basic_rtl.pulse_synchronizer
    port map(
        i_raw => i_readRDR,
        i_clkIn => i_clk,
        i_clkOut => i_baudClkx8,
        i_resetn => i_resetn,
        o_pulse => int_readRDR_sync
    );

    -- Recieve Buffers
    RDR: entity basic_rtl.registerNbits
    generic map(
        DataWidth => 8
    )
    port map(
        i_in => int_RSR_out,
        i_load => int_loadRDR,
        i_clk => i_clk,
        i_cen => const_vcc,
        i_resetn => i_resetn,
        o_out => int_out_RDR
    );
    RSR: entity basic_rtl.pipoShiftRegisterNBits
    generic map(
        DataWidth => 8
    )
    port map(
        i_in => (others => const_gnd),
        i_serialIn => i_rxd,
        i_shitleftn_shiftright => const_vcc,
        i_resetn => i_resetn,
        i_load => const_gnd,
        i_clk => i_baudClkx8,
        i_cen => int_cenRSR,
        o_serialOut => open,
        o_out => int_RSR_out
    );
    RDRF_BUF: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_rdrf,
        i_cen => int_rdrfLd,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_rdrf,
        o_qn => open
    );

    -- Status Flag Registers
    STOP_REG: entity basic_rtl.synth_enardFF
    port map(
        i_d => i_rxd,
        i_cen => int_stopLd,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_stop,
        o_qn => open
    );
    FE_REG: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_fe,
        i_cen => int_feLd,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_fe,
        o_qn => open
    );
    OE_REG: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_oe,
        i_cen => int_oeLd,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_oe,
        o_qn => open
    );


    -- Counters
    count4clocks: entity basic_rtl.counterNbits
    generic map(
        DataWidth => 2,
        InvertCountDirecton => TRUE
    )
    port map(
        i_in => "10",
        i_load => int_count4clocksLd,
        i_clk => i_baudClkx8,
        i_cen =>int_count4clocksEn,
        i_resetn => i_resetn,
        o_value => open,
        o_zero => int_count4clocksZ
    );

    count8clocks: entity basic_rtl.counterNbits
    generic map(
        DataWidth => 3,
        InvertCountDirecton => TRUE
    )
    port map(
        i_in => "110",
        i_load => int_count8clocksLd,
        i_clk => i_baudClkx8,
        i_cen => int_count8clocksEn,
        i_resetn => i_resetn,
        o_value => open,
        o_zero => int_count8clocksZ
    );

    count8bits: entity basic_rtl.counterNbits
    generic map(
        DataWidth => 4,
        InvertCountDirecton => TRUE
    )
    port map(
        i_in => "1000",
        i_load => int_count8BitsLd,
        i_clk => i_baudClkx8,
        i_cen => int_count8BitsEn,
        i_resetn => i_resetn,
        o_value => open,
        o_zero => int_count8BitsZ
    );

    -- State machine storage
    state0: entity basic_rtl.synth_enasdFF
    port map(
        i_d => int_in_state0,
        i_cen => const_vcc,
        i_clk => i_baudClkx8,
        i_setn => i_resetn,
        o_q => int_out_state0,
        o_qn => open
    );
    state1: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state1,
        i_cen => const_vcc,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_state1,
        o_qn => open
    );
    state2: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state2,
        i_cen => const_vcc,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_state2,
        o_qn => open
    );
    state3: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state3,
        i_cen => const_vcc,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_state3,
        o_qn => open
    );
    state4: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state4,
        i_cen => const_vcc,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_state4,
        o_qn => open
    );
    state5: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_in_state5,
        i_cen => const_vcc,
        i_clk => i_baudClkx8,
        i_resetn => i_resetn,
        o_q => int_out_state5,
        o_qn => open
    );

end rtl ; -- rtl