LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY micro_ctrl IS
END micro_ctrl;

ARCHITECTURE test OF micro_ctrl IS
	COMPONENT I2C_KLT IS
		PORT (	clk		: IN STD_LOGIC;
				data_in	: IN STD_LOGIC_VECTOR (7 downto 0);
				data_out: OUT STD_LOGIC_VECTOR (7 downto 0)
				);
	END COMPONENT I2C_KLT;
	
	SIGNAL clk : STD_LOGIC := '1';
	SIGNAL img : STD_LOGIC_VECTOR := "00000000";
	SIGNAL dis : STD_LOGIC_VECTOR := "00000000";
	
BEGIN
	project: I2C_KLT PORT MAP (	clk		=> clk,
								data_in	=> img,
								data_out => dis
							);

	PROCESS BEGIN
        wait for 100 ns;
        clk <= not clk;
    END PROCESS;
	
END test;
