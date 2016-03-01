LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY I2C_Master IS
	PORT (	clk		: IN STD_LOGIC;
			data_in	: IN STD_LOGIC_VECTOR (7 downto 0);
			scl		: OUT STD_LOGIC;
			sda		: INOUT STD_LOGIC;
			data_out: OUT STD_LOGIC_VECTOR (7 downto 0)
			);
END I2C_Slave;

ARCHITECTURE I2C_M_behav OF I2C_Master IS
BEGIN
	sda <= clk;
	
	-- temporary assignments
	sda <= 'Z';
	data_out = data_in;
	
END I2C_M_behav;

-- data_in may change depending on how the images will be sent.
-- data_out may change depending on how the displacement will be
-- returned.
-- data_in/out sizes is arbitrary set for now