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
				scl		: OUT STD_LOGIC;
				sda		: INOUT STD_LOGIC
			);
	END COMPONENT I2C_Master;
	
	TYPE regfile IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0); 
	--SIGNAL clk : STD_LOGIC := '1';
	--SIGNAL img : STD_LOGIC_VECTOR := "00000000";
	--SIGNAL dis : STD_LOGIC_VECTOR := "00000000";
	SIGNAL i2c_reg		: regfile;
	SIGNAL i2c_start	: STD_LOGIC := '0';
	SIGNAL start_wr		: STD_LOGIC := '0';
	SIGNAL data_in		: regfile;
	
BEGIN
	i2c_master : I2C_Master PORT MAP(	clk		=> clk,
										reset	=> rst,
										start	=> i2c_start,
										wr 		=> start_wr,
										data	=> data_in,
										scl		=> scl,
										sda		=> sda
									);

	--PROCESS BEGIN
    --    wait for 100 ns;
    --    clk <= not clk;
    --END PROCESS;
	
	PROGRAM_ECEXUTION: PROCESS IS
	BEGIN
		WAIT UNTIL rst = '1';
		i2c_start = '0';
		FOR idx IN i2c_reg'RANGE LOOP
			i2c_reg(idx) <= "00000000";
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
		data_in(0) <= ram(0);
		WAIT UNTIL clk = '1'; 
		data_in(1) <= ram(1);
		WAIT UNTIL clk = '1';
		data_in(2) <= ram(2);
		WAIT UNTIL clk = '1';
		data_in(3) <= ram(3);
		WAIT UNTIL clk = '1';
		
		--start i2c master
		i2c_start = '1';
		start_wr = '1';
		--handle i2c sending of all data
		--look for done condition
		
		
	END PROCESS;
END test;
