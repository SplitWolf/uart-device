library ieee;
use ieee.std_logic_1164.all;

library basic_rtl;
use basic_rtl.all;

entity uart_device is 
port (
    i_rxd: in std_logic;
    i_address: in std_logic_vector(1 downto 0);
    i_writen_read: in std_logic;
    i_uartSelect: in std_logic;
    i_clk: in std_logic;
    i_resetn: in std_logic;
    o_txd: out std_logic;
    o_irq: out std_logic;
    io_data_bus: inout std_logic_vector(7 downto 0)
);
end uart_device;

architecture rtl of uart_device is
    -- Data Signals
    signal int_SCSR, int_loadTDR, int_loadTDR_flop: std_logic_vector(7 downto 0);
    signal int_out_tdre, int_out_txd: std_logic;
    signal int_out_rdrf, int_out_oe, int_out_fe: std_logic;
    signal out_sccr, out_rdr: std_logic_vector(7 downto 0);
    -- Control Signals
    signal address0, address1, address2, address3: std_logic;
    signal loadSCCR: std_logic;
begin
    -- Receiver
    receive: entity work.uart_receiver
     port map(
        i_rxd => i_rxd,
        i_baudClkx8 => '0',
        i_readRDR => int_readRDR,
        i_resetn => i_resetn,
        o_oe => int_out_oe,
        o_fe => int_out_fe,
        o_rdrf => int_out_rdrf,
        o_rdr => int_out_rdr
    );
    
    -- Transmitter

    int_loadTDR <= (address0 and not i_writen_read);

    loadTDR_ff: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_loadTDR,
        i_cen => const_vcc,
        i_clk => i_clk,
        i_resetn => i_resetn,
        o_q => int_loadTDR_flop,
        o_qn => open
    );

    transmit: entity work.uart_transmitter
        port map (
            i_data => io_data_bus,
            i_loadTDR => int_loadTDR_flop,
            i_clk => i_clk,
            i_baudClk => '0', --TODO: SET BAUD CLK
            i_resetn => i_resetn,
            o_tdre => int_out_tdre,
            o_txd => int_out_txd;
        );

    -- Bus Singals
    addressDecoder: entity basic_rtl.decoder2x4
    port map(
    i_in => i_address,
    o_out0 => address0,
    o_out1 => address1,
    o_out2 => address2,
    o_out3 => address3
    );
    int_SCSR <= int_out_tdre & int_out_rdrf & "0000" & int_out_oe & int_out_fe;
    loadSCCR <= (address2 or address3) and not i_writen_read;

    io_data_bus <= "ZZZZZZZZ";
    io_data_bus <= out_rdr when (address0 and i_writen_read and i_uartSelect) = '1' else "ZZZZZZZZ";
    io_data_bus <= int_SCSR when (address1 and i_writen_read and i_uartSelect) = '1' else "ZZZZZZZZ";
    io_data_bus <= out_sccr when ((address2 or address3) and i_writen_read and i_uartSelect) = '1' else "ZZZZZZZZ";

    -- Storage Components
    SCCR: entity basic_rtl.registerNbits
    generic map(
    DataWidth => 8
    )
    port map(
    i_in => io_data_bus,
    i_load => loadSCCR,
    i_clk => i_clk,
    i_cen => '1',
    i_resetn => i_resetn,
    o_out => out_sccr
    );
    


end rtl ; -- rtl