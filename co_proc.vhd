LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.ALL;
use std.env.ALL;

LIBRARY work;
use work.ram.ALL;
use work.reg.ALL;

ENTITY co_proc IS
	PORT (	clk	: IN STD_LOGIC;
			rst	: IN STD_LOGIC;
			scl	: IN STD_LOGIC;
			ram	: INOUT ram_type;
			sda	: INOUT STD_LOGIC;
			int	: OUT STD_LOGIC	--interrupt line; is high when matrix mult is done
			);
END co_proc;

ARCHITECTURE co_proc_behav OF co_proc IS
	COMPONENT I2C_Slave IS
		PORT(	scl		: IN STD_LOGIC;
				clk		: IN STD_LOGIC;
				reset	: IN STD_LOGIC
				rd		: IN STD_LOGIC;
				sda		: INOUT STD_LOGIC;
				data	: OUT STD_LOGIC_VECTOR(7 downto 0)
			);
	END COMPONENT I2C_Slave; 
	
	SIGNAL start_rd		: STD_LOGIC = '0';
	SIGNAL data_out		: STD_LOGIC_VECTOR(7 DOWNTO 0);
			
BEGIN
	
	slave: I2C_Slave PORT MAP (	scl		=> scl,
								clk		=> clk,
								reset	=> rst,
								rd		=> start_rd,
								sda		=> sda,
								data	=> data_out
								); 
	

END co_proc_behav;
