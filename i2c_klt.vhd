LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY I2C_KLT IS
	PORT (	clk		: IN STD_LOGIC;
			data_in	: IN STD_LOGIC_VECTOR (7 downto 0);
			data_out: OUT STD_LOGIC_VECTOR (7 downto 0)
			);
END I2C_KLT;

ARCHITECTURE I2C_KLT_behav OF I2C_KLT IS

	COMPONENT I2C_Master IS
		PORT (	clk		: IN STD_LOGIC;
				data_in	: IN STD_LOGIC_VECTOR (7 downto 0);
				scl		: OUT STD_LOGIC;
				sda		: INOUT STD_LOGIC;
				data_out: OUT STD_LOGIC_VECTOR (7 downto 0)
				);
	END COMPONENT I2C_Master; 
	
	COMPONENT KLT IS
	PORT (	scl		: IN STD_LOGIC;
			sda		: INOUT STD_LOGIC;
			);
	END COMPONENT KLT;
	
	SIGNAL	scl_master_slave,
			sda_master_slave		: STD_LOGIC;
			
BEGIN
	
	master: I2C_Master PORT MAP (	clk		=> clk,
									data_in	=> data_in,
									scl		=> scl_master_slave,
									sda		=> sda_master_slave,
									data_out => data_out
								);
					
	slave_klt: PORT MAP (	scl		=> scl_master_slave, 
							sda		=> sda_master_slave
						);
	

END I2C_KLT_behav;
