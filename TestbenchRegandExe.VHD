

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
------------------------------------------------------------

------------------------------------------------------------
entity testregandexe is
end testregandexe;
------------------------------------------------------------

------------------------------------------------------------
architecture tb_architecture of testregandexe is

             component cellSPU
                       port(
						clk : in std_logic;	
						bootload_en: in std_logic;
						bootloader : in std_logic_vector(0 to 31)
    );
				   
              end component;
    -- stimulus signals			 
	signal clk : std_logic;	
	signal bootload_en: std_logic;
	signal bootloader: std_logic_vector(0 to 31);

    signal end_sim : boolean := false;
    constant period : time := 40 ns;
 begin
     -- Unit Under Test port map
    UUT: cellSPU
    port map(
    clk	=> clk,   
	bootload_en => bootload_en,
	bootloader => bootloader
	);
	
	clock_gen : process
    begin
        clk <= '0';
        loop
            wait for period/2;
            clk <= not clk;
            exit when end_sim = true;
        end loop;
        wait;
    end process;  
-- COPY CODE FROM PARSER BELOW
bootloader <= "01000000100000000000001110000001","01000000100000000000011110000110" after 2 *period,"01000000100000000000011110000000" after 3 *period,"01000000100000000000000000000101" after 4 *period,"01000000100000000000000001010000" after 5 *period,"01000000100000000000000000000111" after 6 *period,"01000000100000000000000000001000" after 7 *period,"01000000100000000000000000001001" after 8 *period,"01000000100000000000000000001010" after 9 *period,"00011000000000011000000010000010" after 10 *period,"01000000100000000000000000001011" after 11 *period,"01000000100000000000000000001100" after 12 *period,"01000000100000000000000000001101" after 13 *period,"00110010011111111111100110000000" after 14 *period;
bootload_en <= '1' after 1 * period, '0' after 15* period;

-- COPY CODE FROM PARSER ABOVE















    end_sim <= true after 1000 * period;



end tb_architecture;




























