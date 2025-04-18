----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: DDS Controller with Block Memory (BROM) for storing the samples
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;             -- required for modulus function
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity dds_controller is
    Generic ( 
        DDS_DATA_WIDTH      : integer := 24;       -- DDS data width
        PHASE_DATA_WIDTH    : integer := 16);      -- DDS phase increment data width
    Port ( 
      clk_i         : in std_logic;
      enable_i      : in std_logic;
      reset_i       : in std_logic;
      phase_inc_i   : in std_logic_vector(PHASE_DATA_WIDTH-1 downto 0);
      
      data_o        : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0)); 
end dds_controller;

----------------------------------------------------------------------------
architecture Behavioral of dds_controller is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
signal phase_accumulator_s  : unsigned(PHASE_DATA_WIDTH-1 downto 0) := (others => '0');
signal bram_address_s       : std_logic_vector(PHASE_DATA_WIDTH-1 downto 0) := (others => '0');
signal bram_data_s          : std_logic_vector(DDS_DATA_WIDTH-1 downto 0) := (others => '0');

component blk_mem_gen_0 is
    PORT (
        clka    : IN STD_LOGIC;
        ena     : IN STD_LOGIC;
        addra   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        douta   : OUT STD_LOGIC_VECTOR(23 DOWNTO 0));
end component;
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
bram_address_s <= std_logic_vector(phase_accumulator_s);

data_o <= bram_data_s;

bram_inst : blk_mem_gen_0 -- Port mapping and instantiating the bram
port map (
    clka    => clk_i,
    ena     => '1',
    addra   => bram_address_s,
    douta   => bram_data_s);
    
counter_process : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            phase_accumulator_s <= (others => '0');
        elsif (enable_i = '1') then
            phase_accumulator_s <= phase_accumulator_s + unsigned(phase_inc_i) + 1;
        end if;
    end if;
end process counter_process;
----------------------------------------------------------------------------   
end Behavioral;