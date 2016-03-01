LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY I2C_Master IS
	PORT (	clk		: IN STD_LOGIC;
			data	: IN STD_LOGIC_VECTOR (7 downto 0);
			scl		: OUT STD_LOGIC;
			sda		: OUT STD_LOGIC;
			);
END FIR;

ACHITECTURE I2C_M_behav OF I2C_Master IS
BEGIN
	sda <= clk;
	
	//temp
	sda <= data[0];
END I2C_M_behav