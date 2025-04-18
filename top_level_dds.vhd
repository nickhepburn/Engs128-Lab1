----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Top-level file for audio codec tone generator and data passthrough 
--  Target device: Zybo
--
--  SSM2603 audio codec datasheet: 
--      https://www.analog.com/media/en/technical-documentation/data-sheets/ssm2603.pdf
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;
----------------------------------------------------------------------------
-- Entity definition
entity top_level_dds is
    Port (
		sysclk_i : in  std_logic;	
		
		-- User controls
		dds_reset_i       : in STD_LOGIC;
		dds_enable_i      : in STD_LOGIC;
		dds_freq_sel_i    : in STD_LOGIC_VECTOR(2 downto 0);
		ac_mute_en_i      : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o   : out STD_LOGIC;
        ac_mclk_o   : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o   : out STD_LOGIC;
        ac_dac_lrclk_o  : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i   : in STD_LOGIC;
        ac_adc_lrclk_o  : out STD_LOGIC);
        
end top_level_dds;

----------------------------------------------------------------------------
architecture Behavioral of top_level_dds is
----------------------------------------------------------------------------

constant AC_DATA_WIDTH : integer := 24;
constant DDS_PHASE_WIDTH : integer := 16;


signal mclk                 : std_logic := '0';
signal bclk                 : std_logic := '0';
signal lrclk                : std_logic := '0';
signal lrclk_n              : std_logic := '0';

signal left_audio_data_rx   : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_rx  : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_audio_data_tx   : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_tx  : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

signal left_dds_data        : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_dds_data       : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_dds_phase_inc   : std_logic_vector(DDS_PHASE_WIDTH-1 downto 0) := (others => '0');
signal right_dds_phase_inc  : std_logic_vector(DDS_PHASE_WIDTH-1 downto 0) := (others => '0');
signal left_dds_clk         : std_logic := '0';
signal right_dds_clk        : std_logic := '0';

----------------------------------------------------------------------------

component i2s_clock_gen is
    Port (

        -- System clock in
		sysclk_125MHz_i   : in  std_logic;	
		
		-- Forwarded clocks
		mclk_fwd_o		  : out std_logic;	
		bclk_fwd_o        : out std_logic;
		adc_lrclk_fwd_o   : out std_logic;
		dac_lrclk_fwd_o   : out std_logic;

        -- Clocks for I2S components
		mclk_o		      : out std_logic;	
		bclk_o            : out std_logic;
		lrclk_o           : out std_logic);  
end component;

----------------------------------------------------------------------------
    
component i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end component;

----------------------------------------------------------------------------
-- 
component dds_controller is
    Generic ( DDS_DATA_WIDTH : integer := AC_DATA_WIDTH;       -- DDS data width
            PHASE_DATA_WIDTH : integer := DDS_PHASE_WIDTH);      -- DDS phase increment data width
    Port ( 
      clk_i         : in std_logic;
      enable_i      : in std_logic;
      reset_i       : in std_logic;
      phase_inc_i   : in std_logic_vector(PHASE_DATA_WIDTH-1 downto 0);
      
      data_o        : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0)); 
end component;

----------------------------------------------------------------------------

component i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		adc_serial_data_i     : in std_logic;
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0')
		);  
end component;
-----------------------------------------------------------------
begin

audio_receiver: i2s_receiver
port map(
    mclk_i              => mclk,
    bclk_i              => bclk,
    lrclk_i             => lrclk,
    
    adc_serial_data_i   => ac_adc_data_i,
    left_audio_data_o   => left_audio_data_rx,
    right_audio_data_o  => right_audio_data_rx
    );
    
clock_generation: i2s_clock_gen 
port map (
    sysclk_125MHz_i => sysclk_i,
    mclk_fwd_o      => ac_mclk_o,
    bclk_fwd_o      => ac_bclk_o,
    adc_lrclk_fwd_o => ac_adc_lrclk_o,
    dac_lrclk_fwd_o => ac_dac_lrclk_o,
    mclk_o          => mclk,
    bclk_o          => bclk,
    lrclk_o         => lrclk);
    
audio_transmitter: i2s_transmitter
port map(
    mclk_i              => mclk,
    bclk_i              => bclk,
    lrclk_i             => lrclk,
    left_audio_data_i   => left_audio_data_tx,
    right_audio_data_i  => right_audio_data_tx,
    dac_serial_data_o   => ac_dac_data_o);	

left_audio_dds : dds_controller
port map (
    clk_i => left_dds_clk,
    enable_i => dds_enable_i,
    reset_i => dds_reset_i,
    phase_inc_i => left_dds_phase_inc,
    data_o => left_dds_data);
    	
left_dds_clock_bufg : BUFG 
port map (
    O => left_dds_clk,
    I => lrclk);

right_audio_dds : dds_controller
port map (
    clk_i => right_dds_clk,
    enable_i => dds_enable_i,
    reset_i => dds_reset_i,
    phase_inc_i => right_dds_phase_inc,
    data_o => right_dds_data);

right_dds_clock_bufg : BUFG 
port map (
    O => right_dds_clk,
    I => lrclk_n);
    
lrclk_n <= not(lrclk);

----------------------------------------------------------------------------

dds_phase_logic : process(dds_freq_sel_i)
begin

    case(dds_freq_sel_i) is
        when "000" =>
            left_dds_phase_inc  <= "0000000101100110"; -- M = 358
            
            right_dds_phase_inc <= "0000001011001101"; -- M = 717
            
        when "001" => 
            left_dds_phase_inc  <= "0000000110010010"; -- M = 402
            
            right_dds_phase_inc <= "0000001100100101"; -- M = 805
        
        when "010" => 
            left_dds_phase_inc  <= "0000000111000100"; -- M = 452
            
            right_dds_phase_inc <= "0000001110000111"; -- M = 903
        
        when "011" => 
            left_dds_phase_inc  <= "0000000011101110"; -- M = 478
            
            right_dds_phase_inc <= "0000001110111101"; -- M = 957
            
        when "100" => 
            left_dds_phase_inc  <= "0000001000011001"; -- M = 537
            
            right_dds_phase_inc <= "0000010000110010"; -- M = 1074 
            
        when "101" => 
            left_dds_phase_inc  <= "0000001001011011"; -- M = 603
            
            right_dds_phase_inc <= "0000010010110101"; -- M = 1205 
            
        when "110" => 
            left_dds_phase_inc  <= "0000001010100101"; -- M = 677
            
            right_dds_phase_inc <= "0000010101000001"; -- M = 1345 
        
        when "111" => 
            left_dds_phase_inc  <= "0000001011001101"; -- M = 717
            
            right_dds_phase_inc <= "0000010110011010"; -- M = 1434 
            
        when others => 
            left_dds_phase_inc <= (others => '0');
            
            right_dds_phase_inc <= (others => '0');
    
    end case;
    
end process dds_phase_logic;

leftreg : process(mclk)
begin 
    if rising_edge(mclk) then 
        if (dds_enable_i = '1') then
            left_audio_data_tx <= left_dds_data;
        elsif (dds_enable_i = '0') then
             left_audio_data_tx <= left_audio_data_rx;
        end if;
    end if;
end process leftreg;

rightreg : process(mclk)
begin 
    if rising_edge(mclk) then 
        if (dds_enable_i = '1') then
            right_audio_data_tx <= right_dds_data;
        elsif (dds_enable_i = '0') then
             right_audio_data_tx <= right_audio_data_rx;
        end if;
    end if;
end process rightreg;

mutereg : process(mclk)
begin 
if rising_edge(mclk) then 
        ac_mute_n_o <= not ac_mute_en_i;
    end if;
end process mutereg;
----------------------------------------------------------------------------
end Behavioral;