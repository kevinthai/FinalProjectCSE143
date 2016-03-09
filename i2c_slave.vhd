LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY I2C_Slave IS
	GENERIC (
			clkFreq: POSITIVE := 50_000;	-- Frequency of system clock in kHz
			data_rate: POSITIVE := 100;		-- Desired I2C bus speed in kbps
			write_time: POSITIVE := 5		-- max write time in ms
			);
	PORT (	scl		: IN STD_LOGIC;
			clk		: IN STD_LOGIC;
			reset	: IN STD_LOGIC
			rd		: IN STD_LOGIC;
			sda		: INOUT STD_LOGIC;
			data	: OUT STD_LOGIC_VECTOR (7 downto 0)
			);
END I2C_Slave;

ARCHITECTURE I2C_S_behav OF I2C_Slave IS
	--General constants and signals:
	CONSTANT divider: INTEGER := (clkFreq/8)/data_rate;
	CONSTANT delay: INTEGER := write_time*data_rate;
	SIGNAL aux_clk, bus_clk, data_clk: STD_LOGIC;
	SIGNAL timer: NATURAL RANGE 0 TO delay;
	SIGNAL data_in: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL start: STD_LOGIC := '0';	--indicates i2c start condition
	SIGNAL stop: STD_LOGIC := '0';	--indicates i2c stop condition
	
	--scl signals delayed by 1 clock cycle and 2 clock cycles
	SIGNAL scl_reg: STD_LOGIC := '1';
	SIGNAL scl_prev_reg: STD_LOGIC := '1';
	
	--sda signals delayed by 1 clock cycle and 2 clock cycles
	SIGNAL sda_reg: STD_LOGIC := '1';
	SIGNAL sda_prev_reg: STD_LOGIC := '1';
	
	SIGNAL i: NATURAL RANGE 0 TO delay;
	--State machine signals:
	TYPE state IS (IDLE, ACK, RECEIVE_DATA);
	SIGNAL p_state, n_state: state; --present/next states

BEGIN
	data <= data_in;
	----------------Auxiliary clock:----------------
	PROCESS (clk)
		VARIABLE count: INTEGER RANGE 0 TO divider;
	BEGIN
		IF (clk'EVENT AND clk='1') THEN
			count := count + 1;
			IF(count = divider) THEN
				aux_clk <= NOT aux_clk;
				count := 0;
			END IF;
		END IF;
	END PROCESS;
	
	----------------Bus and Data clocks:----------------
	PROCESS (aux_clk)
		VARIABLE count: INTEGER RANGE 0 TO 3;
	BEGIN
		IF (aux_clk'EVENT AND aux_clk='1') THEN
			count := count + 1;
			IF (count = 0) THEN
				bus_clk <= '0';
			ELSIF (count = 1) THEN
				data_clk <= '1';
			ELSIF (count = 2) THEN
				bus_clk <= '1';
			ELSE
				data_clk <= '0';
			END IF;
		END IF;
	END PROCESS;
	
	----------------Sequential section of FSM----------------
	PROCESS (data_clk, reset)
	BEGIN
		IF (reset = '1') THEN
			p_state <= IDLE;
			i <= 0;
		ELSIF (data_clk'EVENT AND data_clk='1') THEN
			IF (i=timer-1) THEN
				p_state <= n_state;
				i <= 0;
			ELSE
				i <= i + 1;
			END IF;
			
			--See how scl changes within the past 2 clock cycles
			scl_reg <= scl;
			scl_prev_reg <= scl_reg;
			
			--See how sda changes within the past 2 clock cycles
			sda_reg <= sda;
			sda_prev_reg <= sda_reg;
			
			--Look for i2c start condition
			start <= '0';
			stop <= '0';
			IF ((scl_prev_reg = '1') AND (scl_reg = '1') AND 
				(sda_prev_reg = '1') AND (sda_reg = '0')) THEN
				start <= '1';
				stop <= '0';
			END IF;
			
			--Look for i2c stop condition
			IF ((scl_prev_reg = '1') AND (scl_reg = '1') AND 
				(sda_prev_reg = '0') AND (sda_reg = '1')) THEN
				start <= '0';
				stop <= '1';
			END IF;
			
		END IF;
	END PROCESS;
	
	----------------Combinational section of FSM----------------
	PROCESS (p_state, start, stop, sda)
	BEGIN
		CASE p_state IS
			WHEN IDLE =>
				sda <= 'Z';
				timer <= delay;
				IF (start = '1') THEN
					n_state <= RECEIVE_DATA;	--start condition detected
				ELSE
					n_state <= IDLE;
				END IF;
			WHEN RECEIVE_DATA =>
				timer <= 8;
				data_in(7-i) <= sda;
				sda <= 'Z';
				n_state <= ACK;
			WHEN ACK =>
				sda <= '0';
				timer <= 1;
				IF (stop = '1') THEN
					n_state <= IDLE;	--stop condition detected
				ELSE
					n_state <= RECEIVE_DATA;
				END IF;
		END CASE;
		
	END PROCESS;
END I2C_S_behav;

-- data_out may change depending on how the images will be sent.
-- data_in may change depending on how the displacement will be
-- returned.
-- data_in/out sizes is arbitrary set for now