--
-- Sandro Yu	A10812022
-- Kevin Thai	A10716130
-- 
-- 			Final Hardware Design Project
-- 
-- File Name: co_proc.vhd
-- Description: The folloing program defines the co processor,
-- 		which will be instantiated within the top level. The
-- 		co processor will receive data from the I2C slave and 
-- 		perform matrix multiplication. The result should be
--		stored in the shared ram.
-- 

LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.ALL;
use std.env.ALL;

LIBRARY work;
use work.reg.ALL;

ENTITY co_proc IS
	PORT (	clk	: IN STD_LOGIC;
			rst	: IN STD_LOGIC;
			scl	: IN STD_LOGIC;
			we	:OUT STD_LOGIC;
			addr:OUT STD_LOGIC_VECTOR(22 DOWNTO 0);
			d_in:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			d_out:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			sda	: INOUT STD_LOGIC;
			int	: OUT STD_LOGIC	--interrupt line; is high when matrix mult is done
			);
END co_proc;

ARCHITECTURE co_proc_behav OF co_proc IS
	COMPONENT I2C_Slave IS
		PORT(	scl		: IN STD_LOGIC;
				clk		: IN STD_LOGIC;
				reset	: IN STD_LOGIC;
				rd		: IN STD_LOGIC;
				sda		: INOUT STD_LOGIC;
				data	: OUT regfile;
				busy	: OUT STD_LOGIC
			);
	END COMPONENT I2C_Slave; 
	
	SIGNAL start_rd		: STD_LOGIC := '0';
	SIGNAL data_out		: regfile;
	SIGNAL i2c_busy		: STD_LOGIC;
			
BEGIN
	
	slave: I2C_Slave PORT MAP (	scl		=> scl,
								clk		=> clk,
								reset	=> rst,
								rd		=> start_rd,
								sda		=> sda,
								data	=> data_out,
								busy	=> i2c_busy
								); 
	
	
	CO_PROC_CNTRL: PROCESS(clk, rst) IS
	BEGIN
		IF rst'EVENT and rst='1' THEN
		  addr <= "ZZZZZZZZZZZZZZZZZZZZZZZ";
		  d_out <= "ZZZZZZZZ";
		  we <= 'Z';
		END IF;
	END PROCESS;

END co_proc_behav;
