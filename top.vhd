library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

library work;
use work.ram.all;
use work.reg.ALL;

ENTITY top IS
END ENTITY;

ARCHITECTURE testbench of top IS

	COMPONENT co_proc IS
		PORT (	clk	: IN STD_LOGIC;
				rst	: IN STD_LOGIC;
				scl	: IN STD_LOGIC;
				ram	: INOUT ram_type;
				sda	: INOUT STD_LOGIC;
				int	: OUT STD_LOGIC	--interrupt line; is high when matrix mult is done
				);
	END COMPONENT co_proc;

	COMPONENT micro_ctrl IS
		PORT(	clk: IN STD_LOGIC;
				rst: IN STD_LOGIC;
				int: IN STD_LOGIC; --interrupt line; is high when matrix mult is done
				ram: INOUT ram_type;
				sda: INOUT std_logic;
				scl: OUT STD_LOGIC
			);
	END COMPONENT micro_ctrl;
	
	SIGNAL SCL_TOP, SDA_TOP, CLK_TOP, RESET_TOP: STD_LOGIC;
	SIGNAL interrupt: STD_LOGIC;
	SIGNAl RAM_TOP: ram_type; --This will have to be changed to a module
	
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
								ram	=> RAM_TOP,
								sda	=> SDA_TOP,
								scl	=> SCL_TOP
								);
								
	cp0: co_proc PORT MAP(		clk	=> CLK_TOP,
								rst	=> RESET_TOP,
								scl	=> SCL_TOP,
								ram	=> RAM_TOP,
								sda	=> SDA_TOP,
								int	=> interrupt
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