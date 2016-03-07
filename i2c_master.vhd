LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY I2C_Master IS
	GENERIC (
			clkFreq: POSITIVE := 50_000;	-- Frequency of system clock in kHz
			data_rate: POSITIVE := 100;		-- Desired I2C bus speed in kbps
			write_time: POSITIVE := 5		-- max write time in ms
			);
	PORT (	clk, reset	: IN STD_LOGIC;
			wr			: IN STD_LOGIC; 
			data		: IN STD_LOGIC_VECTOR (7 downto 0);
			scl			: OUT STD_LOGIC;
			sda			: INOUT STD_LOGIC
			);
END I2C_Master;

ARCHITECTURE I2C_M_behav OF I2C_Master IS
	--General constants and signals:
	CONSTANT divider: INTEGER := (clkFreq/8)/data_rate;
	CONSTANT delay: INTEGER := write_time*data_rate;
	CONSTANT device_addr_write: STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";
	SIGNAL aux_clk, bus_clk, data_clk: STD_LOGIC;
	SIGNAL timer: NATURAL RANGE 0 TO delay;
	SIGNAL data_out: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL write_flag: STD_LOGIC;
	SIGNAL ack: STD_LOGIC;
	SHARED VARIABLE i: NATURAL RANGE 0 TO delay;
	--State machine signals:
	TYPE state IS (IDLE, ACK1, ACK2, START_WRITE, WRITE_DATA, DEV_ADDR_WR, STOP);
	SIGNAL p_state, n_state: state; --present/next states
BEGIN
	
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
				bus_clk <= '1'
			ELSE
				data_clk <= '0'
			END IF;
		END IF;
	END PROCESS;
	
	----------------Sequential section of FSM----------------
	PROCESS (data_clk, reset)
	BEGIN
		IF (reset = '1') THEN
			p_state <= IDLE;
			i := 0;
		ELSIF (data_clk'EVENT AND data_clk='1') THEN
			IF (i=timer-1) THEN
				p_state <= n_state;
				i := 0;
			ELSE
				i := i + 1;
			END IF;
		ELSIF (data_clk'EVENT AND data_clk='0') THEN
			--Store write flags;
			write_flag <= wr;
			--Store ACK signal during writing
			IF (p_state = ACK1) THEN
				ack <= sda;
			END IF;
		END IF;
	END PROCESS;
	
	----------------Combinational section of FSM----------------
	PROCESS (p_state, bus_clk, data_clk, write_flag, data_out, sda)
	BEGIN
		CASE p_state IS
			WHEN IDLE =>
				scl <= '1';
				sda <= '1';
				timer <= delay; --max write time=5ms
				IF (write_flag='1' OR read_flag='1') THEN
					n_state <= START_WRITE;
				ELSE
					n_state <= IDLE;
				END IF;
			WHEN START_WRITE =>
				scl <= '1'
				sda <= data_clk;	--start sequence
				timer <= 1;
				n_state <= DEV_ADDR_WR;
			WHEN DEV_ADDR_WR =>
				scl <= bus_clk;
				sda <= device_addr_write(7-i);
				timer <= 8;
				n_state <= ACK1;
			WHEN ACK1 =>
				scl <= bus_clk;
				sda <= 'Z';
				timer <= 1;
				IF (write_flag = '1') THEN
					n_state <= WRITE_DATA;
				ELSE
					n_state <= START_READ;
				END IF;
			WHEN WRITE_DATA =>
				scl <= bus_clk;
				sda <=data_out(7-i);
				timer <= 8;
				n_state <= ACK2;
			WHEN ACK2 =>
				scl <= bus_clk;
				sda <= 'Z';
				timer <= 1;
				IF (write_flag = '1') THEN
					n_state <= WRITE_DATA;
				ELSE
					n_state <= STOP;
				END IF;
			WHEN STOP =>
				scl <= '1';
				sda <= NOT data_clk;	--stop sequence
				timer <= 1;
				nx_state <= idle;
		END CASE;
				
	END PROCESS;
END I2C_M_behav;

-- data_in may change depending on how the images will be sent.
-- data_out may change depending on how the displacement will be
-- returned.
-- data/out sizes is arbitrary set for now