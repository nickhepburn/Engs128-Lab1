----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/10/2025 01:49:45 PM
-- Design Name: 
-- Module Name: clock_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity i2s_clock_gen is
    Port (
        sysclk_125MHz_i     : in std_logic;
        
        mclk_fwd_o          : out std_logic;
        bclk_fwd_o          : out std_logic;
        adc_lrclk_fwd_o     : out std_logic;
        dac_lrclk_fwd_o     : out std_logic;
        
        mclk_o              : out std_logic;
        bclk_o              : out std_logic;
        lrclk_o             : out std_logic);
end i2s_clock_gen;

architecture Behavioral of i2s_clock_gen is

constant BCLK_DIV_RATIO : integer := 4;
constant LRCLK_DIV_RATIO : integer := 64;
signal mclk : std_logic := '0'; -- internal signals
signal bclk : std_logic := '0';
signal lrclk : std_logic := '0';
signal lrclk_unbuf : std_logic := '0'; -- for logic, no gated clocks here

component clk_wiz_0 
    Port (
         clk_i  : in  std_logic;
         clk_o : out std_logic
  );
end component;

component i2s_bclk_gen is
    Generic (CLK_DIV_RATIO : integer := BCLK_DIV_RATIO);
    Port (  clk_i : in std_logic;
            clk_unbuf_o : out std_logic;
            clk_o : out std_logic);
end component;

component i2s_lrclk_gen is 
    Generic (CLK_DIV_RATIO : integer := LRCLK_DIV_RATIO);
    Port (  clk_i : in std_logic;
            clk_unbuf_o : out std_logic;
            clk_o : out std_logic);
end component;
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
mclk_o <= mclk;
bclk_o <= bclk;
lrclk_o <= lrclk;
mclk <= sysclk_125MHz_i;

--mclk_gen: clk_wiz_0
--    port map( 
--        clk_i => sysclk_125MHz_i,
--        clk_o => mclk
--   );

bclk_gen : i2s_bclk_gen
    port map (
        clk_i => mclk,
        clk_unbuf_o => open,
        clk_o => bclk);

lrclk_gen : i2s_lrclk_gen
    port map (
        clk_i => bclk,
        clk_unbuf_o => open,
        clk_o => lrclk);

mclk_forward_oddr : ODDR
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
        INIT => '0', -- Initial value for Q port ('1' or '0')
        SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => mclk_fwd_o,     -- 1-bit DDR output
 C => mclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

bclk_forward_oddr : ODDR
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
        INIT => '0', -- Initial value for Q port ('1' or '0')
        SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (
        Q => bclk_fwd_o,     -- 1-bit DDR output
        C => bclk,     -- 1-bit clock input
        CE => '1', -- 1-bit clock enable input
        D1 => '1', -- 1-bit data input (positive edge)
        D2 => '0', -- 1-bit data input (negative edge)
        R => '0', -- 1-bit reset input
        S => '0' -- 1-bit set input
    );

adc_lrclk_forward_oddr : ODDR
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
        INIT => '0', -- Initial value for Q port ('1' or '0')
        SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (
        Q => adc_lrclk_fwd_o,     -- 1-bit DDR output
        C => lrclk,     -- 1-bit clock input
        CE => '1', -- 1-bit clock enable input
        D1 => '1', -- 1-bit data input (positive edge)
        D2 => '0', -- 1-bit data input (negative edge)
        R => '0', -- 1-bit reset input
        S => '0' -- 1-bit set input
    );

dac_lrclk_forward_oddr : ODDR
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
        INIT => '0', -- Initial value for Q port ('1' or '0')
        SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (
        Q => dac_lrclk_fwd_o,     -- 1-bit DDR output
        C => lrclk,     -- 1-bit clock input
        CE => '1', -- 1-bit clock enable input
        D1 => '1', -- 1-bit data input (positive edge)
        D2 => '0', -- 1-bit data input (negative edge)
        R => '0', -- 1-bit reset input
        S => '0' -- 1-bit set input
    );


end Behavioral;
