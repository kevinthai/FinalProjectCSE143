--
-- Sandro Yu	A10812022
-- Kevin Thai	A10716130
-- 
-- 			Final Hardware Design Project
-- 
-- File Name: top.vhd
-- Description:	The following program contains the whole system, 
-- 		which is made up of two processors, an I2C bus,
-- 		and a shared memory (ram). These are the hardware 
--		components needed to perform matrix multiplication
--		The system is run through this file, which acts 
--		like a testbench.
-- 

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

library work;
use work.reg.ALL;

ENTITY top IS
END ENTITY;

ARCHITECTURE testbench of top IS

	COMPONENT co_proc IS
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
	END COMPONENT co_proc;

	COMPONENT micro_ctrl IS
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
	END COMPONENT micro_ctrl;
	
	COMPONENT ram IS
		PORT (	CLK     : IN  std_logic;
				RST     : IN  std_logic;
				WE      : IN  std_logic;
				ADDR    : IN  std_logic_vector(22 DOWNTO 0);
				D_IN    : IN  std_logic_vector(7 DOWNTO 0);
				D_OUT   : OUT std_logic_vector(7 DOWNTO 0)
			);
	END COMPONENT ram;
	
	SIGNAL SCL_TOP, SDA_TOP, CLK_TOP, RESET_TOP, WE_TOP: STD_LOGIC;
	SIGNAL interrupt: STD_LOGIC;
	SIGNAL ADDR_TOP: STD_LOGIC_VECTOR(22 DOWNTO 0);
	SIGNAL D_IN_TOP, D_OUT_TOP: STD_LOGIC_VECTOR(7 DOWNTO 0);
	
BEGIN

	--Attach SCL and SDA to pullup resistors; 'H' synthesizes to '1'
	SCL_TOP <= 'H';
	SDA_TOP <= 'H';
	
	--------1 GHz Clock to drive micro_ctrl and co_proc--------
	clock: PROCESS BEGIN
		CLK_TOP <= '0';
		WAIT FOR 0.5 ns;
		CLK_TOP <= '1';
		WAIT FOR 0.5 ns;
	END PROCESS;
	
	uc0: micro_ctrl PORT MAP(	clk	=> CLK_TOP,
								rst	=> RESET_TOP,
								int	=> interrupt,
								we	=> WE_TOP,
								addr => ADDR_TOP,
								d_in => D_OUT_TOP,
								d_out => D_IN_TOP,
								sda	=> SDA_TOP,
								scl	=> SCL_TOP
								);
								
	cp0: co_proc PORT MAP(		clk	=> CLK_TOP,
								rst	=> RESET_TOP,
								scl	=> SCL_TOP,
								we	=> WE_TOP,
								addr => ADDR_TOP,
								d_in => D_OUT_TOP,
								d_out => D_IN_TOP,
								sda	=> SDA_TOP,
								int	=> interrupt
								);
	
	ram0: ram PORT MAP(			CLK		=> CLK_TOP,
								RST		=> RESET_TOP,
								WE		=> WE_TOP,
								ADDR	=> ADDR_TOP,
								D_IN	=> D_IN_TOP,
								D_OUT	=> D_OUT_TOP
								);
	----------------Program Initialization----------------
	PROGRAM_INIT: PROCESS IS	--contains non-synthesizable code
	BEGIN
		--System reset
		RESET_TOP <= '1';
		WAIT FOR 100 ns;
		RESET_TOP <= '0';
		
		
		
		WAIT; --end of test; suspend process
	END PROCESS;
	
END testbench;
