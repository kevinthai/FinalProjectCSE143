--
-- Sandro Yu	A10812022
-- Kevin Thai	A10716130
-- 
-- 			Final Hardware Design Project
-- 
-- File Name: reg.vhd
-- Description:	The following program defines a regfile to 
-- 		be used as registers passed to and from the I2C
-- 		master and slave. These registers contain the
--		data to be transfered. 
-- 

library ieee;
use ieee.std_logic_1164.all;
package reg is
  constant width:	integer := 8;
  constant reg_depth:	integer := 2**2;
  type regfile is array (0 to reg_depth-1) of std_logic_vector(width-1 downto 0);
end reg;