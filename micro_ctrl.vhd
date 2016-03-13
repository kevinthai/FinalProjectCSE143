LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.ALL;
use std.env.ALL;

LIBRARY work;
use work.ram.ALL;
use work.reg.ALL;

ENTITY micro_ctrl IS
	PORT(	clk: IN STD_LOGIC;
			rst: IN STD_LOGIC;
			int: IN STD_LOGIC; --interrupt line; is high when matrix mult is done
			ram: INOUT ram_type;
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
		WAIT UNTIL rst = '0';
		
		--load ram
		ram(0) <= "00110100";
		WAIT UNTIL clk = '1';
		ram(1) <= "10011010";
		WAIT UNTIL clk = '1';
		ram(2) <= "00010011";
		WAIT UNTIL clk = '1';
		ram(3) <= "11100010";
		WAIT UNTIL clk = '1';
		
		--load ram data into data input for i2c master
		data_len <= 4;
		WAIT UNTIL clk = '1';
		--data_in(0) <= ram(0);
		data_in(0) <= "00110100";
		WAIT UNTIL clk = '1'; 
		--data_in(1) <= ram(1);
		data_in(1) <= "10011010";
		WAIT UNTIL clk = '1';
		--data_in(2) <= ram(2);
		data_in(2) <= "00010011";
		WAIT UNTIL clk = '1';
		--data_in(3) <= ram(3);
		data_in(3) <= "11100010";
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
