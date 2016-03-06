LIBRARY ieee;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY I2C_Master IS
	GENERIC (
			clkFreq: POSITIVE := 50_000;	-- Frequency of system clock in kHz
			data_rate: POSITIVE := 100;		-- Desired I2C bus speed in kbps
			):
	PORT (	clk		: IN STD_LOGIC;
			data_in	: IN STD_LOGIC_VECTOR (7 downto 0);
			scl		: OUT STD_LOGIC;
			sda		: INOUT STD_LOGIC;
			data_out: OUT STD_LOGIC_VECTOR (7 downto 0)
			);
END I2C_Master;

ARCHITECTURE I2C_M_behav OF I2C_Master IS
	CONSTANT divider: INTEGER := (clkFreq/8)/data_rate;
	SIGNAL aux_clk, bus_clk, data_clk: STD_LOGIC
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
	
	sda <= clk;
	
	-- temporary assignments
	sda <= 'Z';
	data_out = data_in;
	
END I2C_M_behav;

-- data_in may change depending on how the images will be sent.
-- data_out may change depending on how the displacement will be
-- returned.
-- data_in/out sizes is arbitrary set for now