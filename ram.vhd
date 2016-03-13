--
-- Sandro Yu	A10812022
-- Kevin Thai	A10716130
-- 
-- 			Final Hardware Design Project
-- 
-- File Name: ram.vhd
-- Description:	The following program defines a ram module,
-- 		which will be instantiated within the top level.
-- 		The ram will store the matrices and result of 
-- 		the matrix multiplication.
-- 

library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.Numeric_Std.all;

--package ram is
--  constant width:	integer := 8;
--  constant ram_depth:	integer := 2**2;
--  type ram_type is array (0 to ram_depth-1) of std_logic_vector(width-1 downto 0);
--end ram;

entity ram is
  port (
    CLK     : in  std_logic;
    RST     : in  std_logic;
    WE      : in  std_logic;
    ADDR    : in  std_logic_vector(22 downto 0);
    D_IN    : in  std_logic_vector(7 downto 0);
    D_OUT   : out std_logic_vector(7 downto 0)
  );
end entity ram;

architecture RTL of ram is

   type ram_type is array (0 to (2**ADDR'length)-1) of std_logic_vector(D_IN'range);
   signal ram : ram_type;
   signal read_address : std_logic_vector(ADDR'range);

begin

  RamProc: process(CLK) is

  begin
    if CLK'event and CLK='1' then
      if WE = '1' then
        ram(to_integer(unsigned(ADDR))) <= D_IN;
      end if;
      read_address <= ADDR;
    end if;
  end process RamProc;

  D_OUT <= ram(to_integer(unsigned(read_address)));

end architecture RTL;
