library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity UART_Tx is

    generic( Baud_clk: integer := 2 ); -- clk/baud_rate (50 000 000 / 9600 = 5208.333)

    port(
        clk					: in  std_logic;
        reset_n			: in  std_logic;
        tx_start_en		: in  std_logic;
        tx_data_in		: in  std_logic_vector (7 downto 0);
        tx_data_out		: out std_logic
        );
end UART_Tx;


architecture Transmit of UART_tx is

    type tx_states is (IDLE, START, DATA, STOP);
    signal state : tx_states	:= IDLE;
    signal baud_rate_clk		: std_logic:= '0';
    signal bit_index				: integer range 0 to 7 := 0;
    signal tx_data				: std_logic_vector(7 downto 0) := (others=>'0');
	 
begin

    baud_rate: process(clk)
    variable baud_count: integer range 0 to (Baud_clk - 1) := 0;
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                baud_rate_clk <= '0';
                baud_count := 0;
            else
                if (baud_count = (Baud_clk - 1)) then
                    baud_rate_clk <= '1';
                    baud_count := 0;
                else
                    baud_rate_clk <= '0';
                    baud_count := baud_count + 1;
                end if;
            end if;
        end if;
    end process baud_rate;


    UART_SM_TX: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                state <= IDLE;
                bit_index <= 0;                   
                tx_data_out <= '1';       
            else
                if (baud_rate_clk = '1') then   
                    case state is
						  
                        when IDLE =>

                            bit_index <= 0;                          
                            tx_data_out <= '1';        

                            if (tx_start_en = '1') then
                                state <= START;
                            end if;

                        when START =>

                            bit_index <= 0;  
                            tx_data_out <= '0';        

                            state <= DATA;

                        when DATA =>

                            tx_data_out <= tx_data_in(bit_index);   
							
                            if (bit_index = 7) then
                                bit_index <= 0;             
                                state <= STOP;
										  
									 else bit_index <= bit_index + 1;
									 
                            end if;

                        when STOP =>

                            tx_data_out <= '1';                          
                            state <= IDLE;

                        when others =>
                            state <= IDLE;
                    end case;
                end if;
            end if;
        end if;
    end process UART_SM_TX;
end Transmit;