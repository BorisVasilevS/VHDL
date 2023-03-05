library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity UART_RX is
generic
(
	baud_clk : integer := 2 --clk / baudRate
);
port(
	CLOCK_50 : in 	std_logic							;
	RX 		: in 	std_logic							;
	RX_Data : out std_logic_vector(7 downto 0)	;
	RX_Done	: out std_logic
);
end entity;

architecture rtl of UART_RX is

signal cnt 	: 	integer range 0 to baud_clk-1 := 0;
signal i		:	integer range 0 to 7 := 0;
--signal stop_b : std_logic;
type SM_UART_RX is (IDLE, start_bit, recieve, stop_bit);
signal state : SM_UART_RX := IDLE;
--signal RX_Data	: std_logic_vector(7 downto 0)	;


signal DATA	: std_logic_vector(7 downto 0);
begin


process(CLOCK_50)
begin
if(rising_edge(CLOCK_50)) then

	case state is
		when IDLE =>
			RX_Done <= '0';
			cnt <= 0;
			if(RX = '0') then
				state <= start_bit;
			else
				state <= IDLE;
			end if;
		when start_bit =>
			if (cnt = baud_clk/2) then
					state <= recieve;
			else
				cnt <= cnt + 1;
				state <= start_bit;
			end if;	
			
			
		when recieve =>
			if(cnt < baud_clk - 1) then
				cnt <= cnt + 1;
				state <= recieve;
			else
				cnt <= 0;
				DATA(i) <= RX;
				
				if(i < 7) then 
					state <= recieve;
					i <= i + 1;
				else
					state <= stop_bit;
					i <= 0;
				end if;
			end if;
		when stop_bit =>
			if(cnt < baud_clk - 1) then
				cnt <= cnt + 1;				
				state <= stop_bit;
			else
				RX_Data <= DATA;
				RX_Done <= RX;
				state <= IDLE;
			end if;
	end case;
end if;
end process;

end architecture;
				
			
			
	