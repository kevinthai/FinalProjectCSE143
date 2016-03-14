--
-- Sandro Yu	A10812022
-- Kevin Thai	A10716130
-- 
-- 			Final Hardware Design Project
-- 
-- File Name: micro_ctrl.vhd
-- Description: The following program contains the micro controller 
-- 		module that will be instantiated within the top level. 
-- 		This processor runs like a procesor (similar to top) and
--		initiates the call to the co processor to start matrix
--		multiplication. 
-- 

LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.ALL;
use std.env.ALL;

LIBRARY work;
use work.reg.ALL;

ENTITY micro_ctrl IS
	PORT(	clk: IN STD_LOGIC;
			rst: IN STD_LOGIC;
			int: IN STD_LOGIC; --interrupt line; is high when matrix mult is done
			we	:OUT STD_LOGIC;
			addr:OUT STD_LOGIC_VECTOR(22 DOWNTO 0);
			d_in:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			d_out:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			sda: INOUT std_logic;
			scl: OUT STD_LOGIC
		);
END micro_ctrl;

ARCHITECTURE test OF micro_ctrl IS
	COMPONENT I2C_Master IS
		PORT(	clk		: IN STD_LOGIC;
				reset	: IN STD_LOGIC;
				start	: IN STD_LOGIC;
				wr		: IN STD_LOGIC; 
				data	: IN regfile;
				data_len: IN NATURAL RANGE 0 to 16;
				scl		: OUT STD_LOGIC;
				sda		: INOUT STD_LOGIC;
				busy	: OUT STD_LOGIC
			);
	END COMPONENT I2C_Master;
	
	SIGNAL i2c_start	: STD_LOGIC := '0';
	SIGNAL start_wr		: STD_LOGIC := '0';
	SIGNAL data_in		: regfile;
	SIGNAL data_len		: NATURAL RANGE 0 to 16;
	SIGNAL i2c_busy		: STD_LOGIC;
	SIGNAL i			: INTEGER;
	
BEGIN
	i2c_m : I2C_Master PORT MAP(clk			=> clk,
								reset		=> rst,
								start		=> i2c_start,
								wr 			=> start_wr,
								data		=> data_in,
								data_len	=> data_len,
								scl			=> scl,
								sda			=> sda,
								busy		=> i2c_busy
								);
	
	PROGRAM_EXECUTION: PROCESS IS	--contains non-synthesizable code
	BEGIN
		WAIT UNTIL rst = '1';
		i2c_start <= '0';
		data_len <= 0;
		FOR idx IN data_in'RANGE LOOP
			data_in(idx) <= "00000000";
		END LOOP;
		addr <= "ZZZZZZZZZZZZZZZZZZZZZZZ";
		d_out <= "ZZZZZZZZ";
		we <= 'Z';
		WAIT UNTIL rst = '0';	
		
		 load values into RAM
		 matrix A contains all 1's and matrix B contains all 0's
		we <= '1';
		FOR i in 0 to 1080*1920-1 LOOP
			addr <= std_logic_vector(to_unsigned(i, 23));
			d_out <= "11111111";
			WAIT UNTIL clk = '1';
		END LOOP;
		
		FOR i in 0 to 1920*3-1 LOOP
			addr <= std_logic_vector(to_unsigned(i + 2**22-1, 23));
			d_out <= "00000000";
			WAIT UNTIL clk = '1';
		END LOOP;
		we <= '0';
			
		
		
		--load data into data input for i2c master
		data_len <= 4;
		WAIT UNTIL clk = '1';
		data_in(0) <= "00000000";	-- address of A
		WAIT UNTIL clk = '1'; 	
		data_in(1) <= "01000000";	-- address of B
		WAIT UNTIL clk = '1';
		data_in(2) <= "10000000"; 	-- address of R
		WAIT UNTIL clk = '1';
		data_in(3) <= "00000011"; 	-- value of P
		WAIT UNTIL clk = '1';
		
		--start i2c master
		i2c_start <= '1';
		start_wr <= '1';
		WAIT UNTIL i2c_busy = '1';	--i2c las left IDLE state and is now writing
		i2c_start <= '0';
		start_wr <= '0';
		WAIT UNTIL i2c_busy = '0';	--i2c finished writing
		
		WAIT FOR 1 us;
		stop(1);	--this stops the testbench here
		
	END PROCESS;
END test;
