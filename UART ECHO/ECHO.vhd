library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ECHO is
generic(
	baud_clk_global : integer := 2
);
port(
	CLOCK_50 : in std_logic;
	data_in 	: in std_logic;
	data_out : out std_logic
);
end entity ECHO;

architecture RTL of ECHO is

component UART_RX
generic(
	baud_clk : integer := baud_clk_global); --clk / baudRate
port(
	CLOCK_50 : in 	std_logic							;
	RX 		: in 	std_logic							;
	RX_Data 	: out std_logic_vector(7 downto 0)	;
	RX_Done	: out std_logic
);
end component UART_RX;

component UART_Tx
generic( Baud_clk: integer := baud_clk_global ); -- clk/baud_rate (50 000 000 / 9600 = 5208.333)
port(
	  clk					: in  std_logic;
	  reset_n			: in  std_logic;
	  tx_start_en		: in  std_logic;
	  tx_data_in		: in  std_logic_vector (7 downto 0);
	  tx_data_out		: out std_logic
	  );
end component UART_Tx;

signal rx_Done : std_logic := '0';
signal buf		: std_logic_vector(7 downto 0);

begin

reciever : UART_RX 
generic map(baud_clk => baud_clk_global)
port map(CLOCK_50 => CLOCK_50, RX => data_in, rx_Done => rx_Done, RX_Data => buf);

transmitter : UART_Tx
generic map(baud_clk => baud_clk_global)
port map(clk => CLOCK_50, reset_n => '1', tx_start_en => rx_Done, tx_data_in => buf, tx_data_out => data_out);

end architecture RTL;
