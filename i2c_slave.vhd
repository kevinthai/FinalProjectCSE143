LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

LIBRARY work;
use work.reg.ALL;

ENTITY I2C_Slave IS
	--GENERIC (
	--		clkFreq: POSITIVE := 50_000;	-- Frequency of system clock in kHz
	--		data_rate: POSITIVE := 100;		-- Desired I2C bus speed in kbps
	--		write_time: POSITIVE := 5		-- max write time in ms
	--		);
	PORT (	scl		: IN STD_LOGIC;
			clk		: IN STD_LOGIC;
			reset	: IN STD_LOGIC;
			rd		: IN STD_LOGIC;
			sda		: INOUT STD_LOGIC;
			data	: OUT regfile;
			busy	: OUT STD_LOGIC
			);
END I2C_Slave;

ARCHITECTURE I2C_S_behav OF I2C_Slave IS
	--General constants and signals:
	--CONSTANT divider: INTEGER := (clkFreq/8)/data_rate;
	CONSTANT divider: INTEGER := 31;
	--CONSTANT delay: INTEGER := write_time*data_rate;
	CONSTANT delay: INTEGER := 7;
	SIGNAL aux_clk, bus_clk, data_clk: STD_LOGIC;
	SIGNAL timer: NATURAL RANGE 0 TO delay + 1;
	SIGNAL data_in: regfile;
	SIGNAL r: NATURAL RANGE 0 to reg_depth;
	SIGNAL i: NATURAL RANGE 0 TO delay;
	
	--scl signals delayed by 1 clock cycle and 2 clock cycles
	SIGNAL scl_reg: STD_LOGIC := '1';
	SIGNAL scl_prev_reg: STD_LOGIC := '1';
	--sda signals delayed by 1 clock cycle and 2 clock cycles
	SIGNAL sda_reg: STD_LOGIC := '1';
	SIGNAL sda_prev_reg: STD_LOGIC := '1';
	
	--State machine signals:
	TYPE state IS (IDLE, ACK1, RECEIVE_DATA);
	SIGNAL p_state, n_state: state; --present/next states

BEGIN
	data <= data_in;
	----------------Auxiliary clock:----------------
	ACLK: PROCESS (clk)
		VARIABLE count: INTEGER RANGE 0 TO divider;
	BEGIN
		IF (reset = '1') THEN
			aux_clk <= '0';
			count := 0;
		ELSIF (clk'EVENT AND clk='1') THEN
			count := count + 1;
			IF(count = divider) THEN
				aux_clk <= NOT aux_clk;
				count := 0;
			END IF;
		END IF;
	END PROCESS;
	
	----------------Bus and Data clocks:----------------
	D_B_CLKS: PROCESS (aux_clk)
		VARIABLE count: INTEGER RANGE 0 TO 3;
	BEGIN
		IF (reset = '1') THEN
			count := 0;
			bus_clk <= '0';
			data_clk <= '0';
		ELSIF (aux_clk'EVENT AND aux_clk='1') THEN
			IF (count = 0) THEN
				bus_clk <= '0';
				count := count + 1;
			ELSIF (count = 1) THEN
				data_clk <= '1';
				count := count + 1;
			ELSIF (count = 2) THEN
				bus_clk <= '1';
				count := count + 1;
			ELSE
				data_clk <= '0';
				count := 0;
			END IF;
		END IF;
	END PROCESS;
	
	----------------Sequential section of FSM----------------
	PROCESS (data_clk, bus_clk, reset)
	BEGIN
		IF (reset = '1') THEN
			--Initial state is idle
			p_state <= IDLE;
			i <= 0;
			r <= 0;
		ELSIF (data_clk'EVENT AND data_clk='1') THEN
			IF (i = timer - 1) THEN
				p_state <= n_state;
				i <= 0;
				IF (p_state = ACK1) THEN
					r <= r + 1; --read the next byte
				ELSIF (p_state = IDLE) THEN
					r <= 0;
				END IF;
			ELSE
				i <= i + 1;
			END IF;
		--sample scl or sda to detect start or stop signal
		ELSIF (bus_clk'EVENT AND bus_clk='1') THEN
			scl_prev_reg <= scl;
			sda_prev_reg <= sda;
		ELSIF (bus_clk'EVENT AND bus_clk='0') THEN
			scl_reg <= scl;
			sda_reg <= sda;
		END IF;
	END PROCESS;
	
	----------------Combinational section of FSM----------------
	PROCESS (p_state, sda, scl_prev_reg, scl_reg, sda_prev_reg, sda_reg)
	BEGIN
		CASE p_state IS
			WHEN IDLE =>
				sda <= 'Z';
				timer <= 1; 
				busy <= '0'; --i2c is not busy
				IF ((scl_prev_reg = 'H') AND (scl_reg = 'H') AND 
				(sda_prev_reg = '1') AND (sda_reg = '0')) THEN
					n_state <= RECEIVE_DATA;	--start condition detected
				ELSE
					n_state <= IDLE;
				END IF;
			WHEN RECEIVE_DATA =>
				IF ((scl_prev_reg = 'H') AND (scl_reg = 'H') AND 
				(sda_prev_reg = '0') AND (sda_reg = '1')) THEN
					n_state <= IDLE;	--stop condition detected
					timer <= 1;
				ELSE
					timer <= 8;
					IF (r < reg_depth) THEN	--prevent array index out of bounds exception
						data_in(r)(7-i) <= sda;
					END IF;
					n_state <= ACK1;
				END IF;
				busy <= '1'; --i2c is busy
			WHEN ACK1 =>
				sda <= '0'; --send acknowledgement to master
				timer <= 1; 
				busy <= '1'; --i2c is busy
				n_state <= RECEIVE_DATA;
		END CASE;
		
	END PROCESS;
END I2C_S_behav;

-- data_out may change depending on how the images will be sent.
-- data_in may change depending on how the displacement will be
-- returned.
-- data_in/out sizes is arbitrary set for now