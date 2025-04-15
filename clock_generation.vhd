----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Clock divider with BUFG output
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

library UNISIM;
use UNISIM.VComponents.all;     -- contains BUFG clock buffer

----------------------------------------------------------------------------
-- Entity definition
entity i2s_clock_gen is
    Generic (BCLK_DIV_RATIO : integer := 4;
             LRCLK_DIV_RATIO : integer := 64);
    Port ( mclk_i    : in std_logic; -- 12.288 MHz output of clk_wiz	
		   bclk_o    : out std_logic;	
		   lrclk_o   : out std_logic); 
end i2s_clock_gen;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of i2s_clock_gen is

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant BCLK_DIV_TC : integer := integer(BCLK_DIV_RATIO/2);
constant BCLK_COUNT_BITS : integer := integer(ceil(log2(real(BCLK_DIV_TC))));
constant LRCLK_DIV_TC : integer := integer(LRCLK_DIV_RATIO/2);
constant LRCLK_COUNT_BITS : integer := integer(ceil(log2(real(LRCLK_DIV_TC))));
signal unbuffered_bclk : std_logic := '1';
signal bclock_counter : unsigned(BCLK_COUNT_BITS-1 downto 0) := (others => '0');
signal unbuffered_lrclk : std_logic := '1';
signal lrclock_counter : unsigned(LRCLK_COUNT_BITS-1 downto 0) := (others => '0');


----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------

-- Slow clock counter
bclk_clock_counter : process(mclk_i)
begin
    if rising_edge(mclk_i) then
        if (bclock_counter = BCLK_DIV_TC-1) then 
            bclock_counter <= (others => '0');   -- reset
        else
            bclock_counter <= bclock_counter + 1; -- increment
        end if;
    end if;
end process bclk_clock_counter;

----------------------------------------------------------------------------
-- Slow clock toggle
bclk_clock_ff : process(mclk_i)
begin
    if rising_edge(mclk_i) then
        if (bclock_counter = BCLK_DIV_TC-1) then 
            unbuffered_bclk <= not unbuffered_bclk;
        end if;
    end if;
end process bclk_clock_ff;

----------------------------------------------------------------------------   
-- Clock buffer     
bclk_clock_bufg : BUFG
port map (
   O => bclk_o,     -- 1-bit output: Clock output
   I => unbuffered_bclk  -- 1-bit input: Clock input
);

-- Slow clock counter
lrclk_clock_counter : process(unbuffered_bclk)
begin
    if falling_edge(unbuffered_bclk) then
        if (lrclock_counter = LRCLK_DIV_TC-1) then 
            lrclock_counter <= (others => '0');   -- reset
        else
            lrclock_counter <= lrclock_counter + 1; -- increment
        end if;
    end if;
end process lrclk_clock_counter;

----------------------------------------------------------------------------
-- Slow clock toggle
lrclk_clock_ff : process(unbuffered_bclk)
begin
    if falling_edge(unbuffered_bclk) then
        if (lrclock_counter = LRCLK_DIV_TC-1) then 
            unbuffered_lrclk <= not unbuffered_lrclk;
        end if;
    end if;
end process lrclk_clock_ff;

----------------------------------------------------------------------------   
-- Clock buffer     
lrclk_clock_bufg : BUFG
port map (
   O => lrclk_o,     -- 1-bit output: Clock output
   I => unbuffered_lrclk  -- 1-bit input: Clock input
);


end Behavioral;