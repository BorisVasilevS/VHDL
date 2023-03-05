library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity LCD is
port(
	CLK 				: in std_logic;
	RST 				: in std_logic;
	RS, RW, EN 		: out std_logic;	--RS = 0 - comands, RS = 1 - data
	LCD_ON, BLON 	: out std_logic := '1';
	Switch			: in std_logic;			
	DATA				: inout std_logic_vector(7 downto 0)
	
);
end entity;


architecture LCD_RTL of LCD is


signal Start, Ready, Tover, RS_HL, RW_HL, OE : std_logic; --OE = output enable
signal Tmax: integer range 0 to 1023 := 0;
signal CNT: integer range 0 to 1023 := 0;

type StateLL is (IDLE, SET_RSRW, SET_E_DATA, CLR_E, SET_RSRW_BUSY, SET_E_BUSY, READ_BUSY, LLREADY); --LL = low level
signal StLL : StateLL := IDLE;

type StateHL is (Timer, SEND, WAIT_READY, Shift, Switch_Lanes);
signal StHL: StateHL := SEND;

signal send_ready	:	std_logic	:=	'0';
constant Timer_max : integer range 0 to 25_000_000 := 25_000_000;
signal Timer_counter : integer range 0 to Timer_max := 0;


signal DATA_IN, DATA_OUT : std_logic_vector(7 downto 0);

constant MAX_BYTE : integer := 17;
type Buf is array (0 to MAX_BYTE - 1) of std_logic_vector(7 downto 0);
constant DATA_BUF_top: Buf := (X"30", X"0E", X"07", X"01", X"17", X"48", X"65", X"6C", X"6C", X"6F", X"20", X"57", X"6F", X"27", X"6C", X"64", X"21");
constant DATA_BUF_bottom: Buf := (X"30", X"0E", X"07", X"01", X"17", X"48", X"65", X"6C", X"6C", X"6F", X"20", X"57", X"6F", X"27", X"6C", X"64", X"21");

--type Word is array (0 to 11) of std_logic_vector(7 downto 0);
--constant Word := (X"48", X"65", X"6C", X"6C", X"6F", X"20", X"57", X"6F", X"27", X"6C", X"64", X"21"); --Hello World!


begin

DATA <= DATA_OUT when OE = '0' else "ZZZZZZZZ";
DATA_IN <= DATA; 
LCD_ON<= '1';
RW <= OE;

process(clk)
begin
	if(RST = '0') then
		CNT <= 0;
		Tover <= '0';
	elsif(rising_edge(clk)) then 
		if(CNT >= Tmax) then 
			CNT <= 0;
			Tover <= '1';
		else 
			CNT <= CNT + 1;
			Tover <= '0';
		end if;
	end if;
end process;

SM_LL: process(clk)
begin 
	if(RST = '0') then
		StLL <= IDLE;
		RS <= '1';
		OE <= '1';
		EN <= '0';
		Ready <= '0';
	elsif(rising_edge(clk))	then 
		case(StLL) is
			when IDLE =>				
					RS <= '1';
					OE <= '1';
					EN <= '0';
					Ready <= '1';
					Tmax <= 30;
				if(start = '1') then 
					StLL <= SET_RSRW;
					ready <= '0';
				else
					StLL <= IDLE;
					ready <= '1';
				end if;
			
			when SET_RSRW =>
				
					RS <= RS_HL;
					OE <= RW_HL;
					EN <= '0';
					Ready <= '0';
					Tmax <= 30;
				if(Tover = '1') then 
					StLL <= SET_E_DATA;
				else
					StLL <= SET_RSRW;
				end if;
			
			when SET_E_DATA => 
				
					RS <= RS_HL;
					OE <= RW_HL;
					EN <= '1';
					Ready <= '0';
					Tmax <= 30;
				if(Tover = '1') then 
					StLL <= CLR_E;
				else
					StLL <= SET_E_DATA;
				end if;
				
			when CLR_E =>
				
					RS <= RS_HL;
					OE <= RW_HL;
					EN <= '0';
					Ready <= '0';
					Tmax <= 30;
				if(Tover = '1') then 
					StLL <= SET_RSRW_BUSY;
				else
					StLL <= CLR_E;
				end if;
				
			when SET_RSRW_BUSY => 
				
					RS <= '0';
					OE <= '1';
					EN <= '0';
					Ready <= '0';
					Tmax <= 30;
				if(Tover = '1') then 
					StLL <= SET_E_BUSY;
				else
					StLL <= SET_RSRW_BUSY;

				end if;
			when SET_E_BUSY =>
				
					RS <= '0';
					OE <= '1';
					EN <= '1';
					Ready <= '0';
					Tmax <= 30;
				if(Tover = '1') then 
					StLL <= READ_BUSY;
				else
					StLL <= SET_E_BUSY;
				end if;
				
			when READ_BUSY =>
				
					RS <= '0';
					OE <= '0';
					EN <= '0';
					Ready <= '0';
					Tmax <= 30;
				if(DATA_IN(7) = '0') then
					StLL <= LLREADY;
				else
					if(Tover = '1') then
						StLL <= SET_E_BUSY;
					else
						StLL <= READ_BUSY;
					end if;
				end if;
		
			when LLREADY =>
				
					RS <= '1';
					OE <= '1';
					EN <= '0';
					Ready <= '0';
					Tmax <= 30;
				if(Tover = '1') then 
					StLL <= IDLE;
					Ready <= '1';
				else
					StLL <= LLREADY;
				end if;
				
		end case;
	end if;
end process SM_LL;


SM_HL: process(CLK, Switch)
variable byte_cnt : integer range 0 to 255 := 0;
variable Switch_pos : std_logic;
begin
	if(RST = '0') then
		StHL <= SEND;
		byte_cnt := 0;
		Start <= '0';
		Switch_pos := Switch;
	elsif(rising_edge(CLK)) then
		case StHL is
			when SEND =>
				Start <= '1';
				Switch_pos := Switch;
				if(Switch = '1') then
					DATA_OUT <= DATA_BUF_top(byte_cnt);
				else
					DATA_OUT <= DATA_BUF_bottom(byte_cnt);
				end if;
				RW_HL <= '0';
				if(byte_cnt > 4) then
					RS_HL <= '1';
				else
					RS_HL <= '0';
				end if;
				StHL <= WAIT_READY;
				Byte_cnt := Byte_cnt + 1;
			when WAIT_READY =>
				Switch_pos := Switch;
				if(ready = '0') then 
					StHL <= WAIT_READY;
					Start <= '1';
				else
					if(Byte_cnt = MAX_BYTE) then 
						StHL <= Timer;
						Start <= '0';
					else
						StHL <= SEND;
						Start <= '1';
					end if;
				end if;
			when Timer =>
				Start <= '0';
				RW_HL <= '0';
				if(Switch_pos = not Switch) then
					StHL <= Switch_Lanes;
					RW_HL <= '0';
					Start <= '1';
					RW_HL <= '0';
					RS_HL <= '0';
					Switch_pos := Switch;
					if(Switch = '1') then --top lanes
						DATA_OUT <= X"30";
					else --bottom lane
						DATA_OUT <= X"38"; --switch lanes
					end if;
				end if;
				if(Timer_counter = Timer_max) then
					StHL <= Shift;
					RW_HL <= '0';
					Start <= '1';
					RW_HL <= '0';
					RS_HL <= '0';
					DATA_OUT <= X"17";
					Timer_counter <= 0;
				else 
					Timer_counter <= Timer_counter + 1;
					StHL <= Timer;
				end if;
			when Switch_Lanes =>
				RW_HL <= '0';
				Start <= '1';
				RW_HL <= '0';
				RS_HL <= '0';
				Switch_pos := Switch;
				if(Switch = '1') then --top lanes
					DATA_OUT <= X"30";
				else --bottom lane
					DATA_OUT <= X"38"; --switch lanes
				end if;
				if(ready = '0') then 
					StHL <= Switch_Lanes;
					Start <= '1';
				else
					StHL <= Timer;
					Start <= '0';
				end if;
			when Shift =>
				RW_HL <= '0';
				Start <= '1';
				RW_HL <= '0';
				RS_HL <= '0';
				DATA_OUT <= X"17"; --shift display left
				Timer_counter <= 0;
				if(ready = '0') then 
					StHL <= Shift;
					Start <= '1';
				else
					StHL <= Timer;
					Start <= '0';
				end if;
		end case;
	end if;
end process SM_HL;


end architecture;
--------------------------------------------------------------
---------  ----------       ------  ---- ---------------------
-------  --  --------  ---  -------  --  ---------------------
-----  -----  -------  ---  --------   -----------------------
----  -------  ------  ---  --------   -----------------------
---  ---------  -----  ---  -------  -  ----------------------
--  -----------  ----       ------  ---  ---------------------
--------------------------------------------------------------
	