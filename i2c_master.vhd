LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

LIBRARY work;
use work.reg.ALL;

ENTITY I2C_Master IS
	GENERIC (
			clkFreq: POSITIVE := 50_000;	-- Frequency of system clock in kHz
			data_rate: POSITIVE := 100;		-- Desired I2C bus speed in kbps
			write_time: POSITIVE := 5		-- max write time in ms
			);
	PORT (	clk		: IN STD_LOGIC;
			reset	: IN STD_LOGIC;
			start	: IN STD_LOGIC;
			wr		: IN STD_LOGIC; 
			data	: IN regfile;
			data_len: IN NATURAL RANGE 0 to 16;
			scl		: OUT STD_LOGIC;
			sda		: INOUT STD_LOGIC;
			busy	: OUT STD_LOGIC 
			);
END I2C_Master;

ARCHITECTURE I2C_M_behav OF I2C_Master IS
	--General constants and signals:
		--CONSTANT divider: INTEGER := (clkFreq/8)/data_rate;
	CONSTANT divider: INTEGER := 31;
		--CONSTANT delay: INTEGER := write_time*data_rate;
	CONSTANT delay: INTEGER := 7;
	SIGNAL aux_clk, bus_clk, data_clk: STD_LOGIC;
	SIGNAL timer: NATURAL RANGE 0 TO delay + 1;
	SIGNAL data_out: regfile;
	SIGNAL r: NATURAL RANGE 0 to reg_depth-1;
	SIGNAL ack: STD_LOGIC;
	SIGNAL i: NATURAL RANGE 0 TO delay;
	--State machine signals:
	TYPE state IS (IDLE, ACK1, START_WRITE, WRITE_DATA, STOP);
	SIGNAL p_state, n_state: state; --present/next states
BEGIN
	data_out <= data;
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
			count := count + 1;
			IF (count = 0) THEN
				bus_clk <= '0';
			ELSIF (count = 1) THEN
				data_clk <= '1';
			ELSIF (count = 2) THEN
				bus_clk <= '1';
			ELSE
				data_clk <= '0';
				count := 0;
			END IF;
		END IF;
	END PROCESS;
	
	----------------Sequential section of FSM----------------
	PROCESS (data_clk, reset)
	BEGIN
		IF (reset = '1') THEN
			--Initial state is IDLE
			p_state <= IDLE;
			i <= 0;
			r <= 0;
		ELSIF (data_clk'EVENT AND data_clk='1') THEN
			--Jump to next state after number of cycles specified by timer
			IF (i = timer - 1) THEN
				p_state <= n_state;
				i <= 0;
				IF (p_state = ACK1) THEN
					r <= r + 1; --write the next byte
				ELSIF (p_state = IDLE) THEN
					r <= 0;
				END IF;
			ELSE
				i <= i + 1;
			END IF;
		ELSIF (data_clk'EVENT AND data_clk='0') THEN
			--Store ACK signal during writing
			IF (p_state = ACK1) THEN
				ack <= sda;
			END IF;
		END IF;
	END PROCESS;
	
	----------------Combinational section of FSM----------------
	PROCESS (p_state, bus_clk, data_clk, wr, data_out, sda)
	BEGIN
		CASE p_state IS
			WHEN IDLE =>
				scl <= 'Z';
				sda <= 'Z';
				timer <= 1; 
				busy <= '0'; --i2c is not busy
				IF ((start = '1') AND (wr = '1')) THEN
					n_state <= START_WRITE;
				ELSE
					n_state <= IDLE;
				END IF;
			WHEN START_WRITE =>
				scl <= 'Z';
				sda <= data_clk;	--start sequence
				timer <= 1;
				busy <= '1'; --i2c is busy
				n_state <= WRITE_DATA;
			WHEN WRITE_DATA =>
				scl <= bus_clk;
				IF (data_out(r)(7-i) = '1') THEN
					sda <= 'Z';
				ELSE
					sda <= '0';
				END IF;
				busy <= '1';
				timer <= 8;
				n_state <= ACK1;
			WHEN ACK1 =>
				scl <= bus_clk;
				sda <= 'Z';
				timer <= 1;
				busy <= '1';
				IF (r = (data_len - 1)) THEN
					n_state <= STOP;	--all bytes have been written
				ELSE
					n_state <= WRITE_DATA;	--not all bytes have been written, continue writing
				END IF;
			WHEN STOP =>
				scl <= 'Z';
				sda <= NOT data_clk;	--stop sequence
				timer <= 1;
				busy <= '1';
				n_state <= IDLE;
		END CASE;
	END PROCESS;
END I2C_M_behav;

-- data_in may change depending on how the images will be sent.
-- data_out may change depending on how the displacement will be
-- returned.
-- data/out sizes is arbitrary set for now

--count may need to be % 4 instead of +1
