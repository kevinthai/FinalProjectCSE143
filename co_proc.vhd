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
	SIGNAL start_mult	: STD_LOGIC; --Signal is high when slave has received all data
	-- storage for matrix A, B, and R. capable of storing up to 1080x1920 matrices
	type matrix is array (0 to 2**21) of std_logic_vector(7 downto 0);
	SIGNAL 	matrixA,
			matrixB,
			matrixC		: matrix;		
	TYPE state IS (IDLE, LOADA, LOADB, CALC1, CALC2, STORER, DONE);
	SIGNAL 	p_state,
			n_state		: state;
	SIGNAL 	addrA		: STD_LOGIC_VECTOR(22 downto 0);
	SIGNAL	addrB		: STD_LOGIC_VECTOR(22 downto 0);
	SIGNAL	addrR		: STD_LOGIC_VECTOR(22 downto 0);
	SIGNAL	p			: STD_LOGIC_VECTOR(7 downto 0);
	-- matrix dimension counters, max value for i, j, k are 1080, 1920, p
	-- x and y are for loading/storing matrix where max value is number of elements
	SIGNAL	i, 
			j,
			k,
			x,
			y			: integer;
			
BEGIN
	
	slave: I2C_Slave PORT MAP (	scl		=> scl,
								clk		=> clk,
								reset	=> rst,
								rd		=> start_rd,
								sda		=> sda,
								data	=> data_out,
								busy	=> i2c_busy
								); 
	
	-- arguements for multiplier
	addrA <= data_out(0) & "000000000000000";	-- address of matrix A
	addrB <= data_out(1) & "000000000000000";	-- address of matrix B
	addrR <= data_out(2) & "000000000000000";	-- address to store resulting matrix
	p <= data_out(3);		-- p value of matrix B
	
	-- SEQUENTIAL section of FSM
	CO_PROC_CNTRL: PROCESS(clk, rst) IS
	BEGIN
		p_state <= n_state;
		--resets the multiplier
		IF rst'EVENT and rst='1' THEN
		  addr <= "ZZZZZZZZZZZZZZZZZZZZZZZ";
		  d_out <= "ZZZZZZZZ";
		  we <= 'Z';
		  i <= 0;
		  j <= 0;
		  k <= 0;
		  we <= '0';
		  -- switches to idle state
		  n_state <= IDLE;
		ELSIF clk'EVENT and clk='1' THEN
			-- dectects when i2c has finished transfering data and starts multiplier
			IF i2c_busy'EVENT and i2c_busy='0' THEN
				n_state <= LOADA;
				x <= 0;
				we <= '0';
				addr <= addrA;
			-- loads matrix A
			ELSIF p_state=LOADA THEN
				-- start loading matrix B
				IF x=(1080*1920 - 1) THEN
					x <= 0;
					n_state <= LOADB;
					addr <= addrB;
				ELSE
					addr <= std_logic_vector( unsigned(addrA) + x + 1);
					x <= x + 1;
				END IF;
			-- loads matrix B
			ELSIF p_state=LOADB THEN
				-- start calculation process
				IF x=(1920*to_integer(unsigned(p))-1) THEN
					x <= 0;
					n_state <= CALC1;
				ELSE
					addr <= std_logic_vector( unsigned(addrB) + x + 1);
					x <= x + 1; 
				END IF;
			-- calculates column k of matrix R
			ELSIF p_state=CALC1 THEN
				n_state <= STORER;
			ELSIF p_state=STORER THEN
				addr <= std_logic_vector( unsigned(addrR) + x);
				IF x=(1080*to_integer(unsigned(p))-1) THEN
					x <= 0;
					n_state <= CALC1;
				ELSE
					x <= x + 1;
				END IF;
			ELSIF p_state <= DONE THEN
				n_state <= IDLE;
			END IF;
		END IF;
		
	END PROCESS;
	
	-- COMBINATIONAL section of FSM
	PROCESS(p_state, d_in) 
	BEGIN
		CASE p_state IS
			WHEN IDLE =>
				int <= '0';
				xy <= 0;
			WHEN LOADA =>
				matrixA(y) <= d_in;
				IF y=1080*1920 - 1 THEN
					y <= 0;
				ELSE 
					y <= y + 1;
				END IF;
			WHEN LOADB =>
				matrixB(y) <= d_in;
				IF y=1920*to_integer(unsigned(p))-1 THEN
					y <= 0;
				ELSE
					y <= y + 1;
				END IF;
			WHEN CALC1 =>
				FOR 
			WHEN CALC2 =>
				int <= '0';
			WHEN STORER =>
				d_out <= matrixR(x)
			WHEN DONE =>
				int <= '1';
		END CASE;
	END PROCESS;

END co_proc_behav;
