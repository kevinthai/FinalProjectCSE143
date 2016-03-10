library ieee;
use ieee.std_logic_1164.all;
package reg is
  constant width:	integer := 8;
  constant reg_depth:	integer := 2**2;
  type regfile is array (0 to depth-1) of std_logic_vector(width-1 downto 0);
end reg;