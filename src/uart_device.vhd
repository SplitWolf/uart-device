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
    -- Constant Signals;
    signal const_vcc, const_gnd: std_logic; 
    -- Data Signals
    -- Baud Rate
    signal int_baudClk: std_logic;
    signal int_baudClkx8: std_logic;
    -- Receive
    signal int_readRDR, int_readRDR_flop, int_readRDR_pulse: std_logic;
    signal int_out_rdr: std_logic_vector(7 downto 0);
    signal int_out_rdrf, int_out_oe, int_out_fe: std_logic;
    -- Transmit
    signal int_loadTDR, int_loadTDR_flop, int_loadTDR_pulse: std_logic;
    signal int_out_tdre, int_out_txd: std_logic;
    -- Common
    signal int_SCSR, int_out_sccr: std_logic_vector(7 downto 0);

    -- Control Signals
    -- Baud Rate
    signal int_rateSel: std_logic_vector(2 downto 0);
    -- UART Device
    signal address0, address1, address2, address3: std_logic;
    signal loadSCCR: std_logic;
begin
    -- TODO: Generate Shorter Interupt Pulses Maybe? Check case where RDRF IRQ goes high right after TRANSMITTER IRQ IS SERVICED or Vise-versa 
    const_vcc <= '1';
    const_gnd <= '0';
    -- Ouput Drivers
    o_txd <= int_out_txd;
    -- Generate IRQ
    o_irq <= (int_out_sccr(7) and int_out_tdre) or (int_out_sccr(6) and (int_out_rdrf or int_out_oe));

    -- Baud Rate Generator
    int_rateSel <= int_out_sccr(2 downto 0);
    baudRateGen: entity work.uart_baudRateGenerator
     port map(
        i_rateSel => int_rateSel,
        i_clk => i_clk,
        i_resetn => i_resetn,
        o_baudClk => int_baudClk,
        o_baudClkx8 => int_baudClkx8
    );

    -- Receiver
    int_readRDR <= address0 and i_writen_read and i_uartSelect;
    readRDR_ff: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_readRDR,
        i_cen => const_vcc,
        i_clk => i_clk,
        i_resetn => i_resetn,
        o_q => int_readRDR_flop,
        o_qn => open
    );

    int_readRDR_pulse <= int_readRDR and not int_readRDR_flop;
    receive: entity work.uart_receiver
     port map(
        i_rxd => i_rxd,
        i_clk => i_clk,
        i_baudClkx8 => int_baudClkx8,
        i_readRDR => int_readRDR_pulse,
        i_resetn => i_resetn,
        o_oe => int_out_oe,
        o_fe => int_out_fe,
        o_rdrf => int_out_rdrf,
        o_rdr => int_out_rdr
    );
    
    -- Transmitter

    int_loadTDR <= (address0 and (not i_writen_read) and i_uartSelect);

    loadTDR_ff: entity basic_rtl.synth_enardFF
    port map(
        i_d => int_loadTDR,
        i_cen => const_vcc,
        i_clk => i_clk,
        i_resetn => i_resetn,
        o_q => int_loadTDR_flop,
        o_qn => open
    );

    int_loadTDR_pulse <= int_loadTDR and not int_loadTDR_flop;

    transmit: entity work.uart_transmitter
        port map (
            i_data => io_data_bus,
            i_loadTDR => int_loadTDR_pulse,
            i_clk => i_clk,
            i_baudClk => int_baudClk,
            i_resetn => i_resetn,
            o_tdre => int_out_tdre,
            o_txd => int_out_txd
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
    loadSCCR <= ((address2 or address3) and not i_writen_read and i_uartSelect);

    io_data_bus <= (others => 'Z');
    io_data_bus <= int_out_rdr when (address0 and i_writen_read and i_uartSelect) = '1' else (others => 'Z');
    io_data_bus <= int_SCSR when (address1 and i_writen_read and i_uartSelect) = '1' else (others => 'Z');
    io_data_bus <= int_out_sccr when ((address2 or address3) and i_writen_read and i_uartSelect) = '1' else (others => 'Z');

    -- Storage Components
    SCCR: entity basic_rtl.registerNbits
    generic map(
    DataWidth => 8
    )
    port map(
    i_in => io_data_bus,
    i_load => loadSCCR,
    i_clk => i_clk,
    i_cen => const_vcc,
    i_resetn => i_resetn,
    o_out => int_out_sccr
    );
    


end rtl ; -- rtl