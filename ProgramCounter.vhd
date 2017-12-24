--Register File
--David Gash
--Program Counter Stage
--Contains 4 bank direct map instruction cache, each cache holds 32 instructions


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity programcounter is
port(
    clk: in std_logic; --clock input
    enable: in std_logic; --block enable
	branchflag: in std_logic; -- branch flag needed to clear inputs if 
	stoppc: in std_logic; -- stop pc if structural hazard
	branchpcin: in std_logic_vector(0 to 31); -- value from branch 
	
	cacheloadin : in std_logic_vector(0 to 1049); -- data input for 
	
	instr1: out std_logic_vector(0 to 31); -- Instruction Output One
	PC1: out std_logic_vector(0 to 31); -- Program Counter Value Instruction 1
	timestamp1: out std_logic_vector( 0 to 3); -- Timestamp for instruction 1
	
	instr2: out std_logic_vector(0 to 31); -- Instruction Output Two
	PC2: out std_logic_vector(0 to 31); -- Program Counter Value for Instruction 2
	timestamp2: out std_logic_vector( 0 to 3) -- Timestamp for Instruction 2
	
	
    );
end programcounter;

architecture behavioral of programcounter is		 
 -- Define Caches
subtype instruction is std_logic_vector(0 to 31); -- 32 bits
type cachelength is array(0 to 31) of instruction; --each cache is 32 instructions
signal cache0: cachelength; --cache definitions
signal cache1: cachelength; 
signal cache2: cachelength; 
signal cache3 : cachelength;

signal waiting: std_logic; -- variable to control states if 1 then waiting for response and each pipe gets nop instructions until cache is loaded.

begin
	process(enable, clk, stoppc)  
	variable programcounter: std_logic_vector(0 to 31) := x"00000000"; -- Program counter
	-- Cache Control Variables
	variable tag0: std_logic_vector(0 to 22); -- variable to hold tag for cache block 0
	variable tag1: std_logic_vector(0 to 22);
	variable tag2: std_logic_vector(0 to 22);
	variable tag3: std_logic_vector(0 to 22);
	
	variable index0: std_logic_vector(0 to 1);
	variable index1: std_logic_vector(0 to 1);
	variable index2: std_logic_vector(0 to 1);
	variable index3: std_logic_vector(0 to 1);
	
	variable valid0: std_logic := '0';
	variable valid1: std_logic := '0';
	variable valid2: std_logic := '0';
	variable valid3: std_logic := '0';
	
	variable timestamp: unsigned(0 to 3) := "0000";
	-- Temp variables to deal with hazards (cache miss)
	variable tempinstr1: std_logic_vector(0 to 31);
	variable temptimestamp1: std_logic_vector(0 to 3);
	variable tempPC1: std_logic_vector(0 to 31);
	
	variable tempinstr2: std_logic_vector(0 to 31);
	variable temptimestamp2: std_logic_vector(0 to 3);
	variable tempPC2: std_logic_vector(0 to 31);
	
	variable tempmiss: std_logic;
	variable incomplete: std_logic;
	variable goanyway : std_logic;

	begin
	if branchflag = '1' then -- If branch set the new program counter
			programcounter := branchpcin; -- set program counter variable
			waiting <= '0';
			goanyway := '1';
	end if;	
	if rising_edge(clk) and enable = '1' then 
			
-- START INSTRUCTION FETCH--------------------------------------------------------------------------------------------------------------------------------------------------------------------		
		if (stoppc = '0' or waiting = '1') or goanyway = '1' then -- only work if program counter is not halted by a hazard
			goanyway := '0';
------------ CACHE 0 CHECK 0-------------------------------------------------------------------------------------------------------------------------------------------------------------------
			if programcounter(23 to 24) = "00" then -- check index
				if programcounter(0 to 22) = tag0 then -- check tags
					if valid0 = '1' then -- check data valid
						if incomplete /= '1' then
							if programcounter(25 to 31) = "1111100" then -- check if 2 instructions can be fetched from cache if not save one in temp memory and ititialize 
								tempinstr1 := cache0(31);
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								incomplete := '1';
								tempmiss := '1'; 
							else
								tempinstr1 := cache0(to_integer(unsigned(programcounter(25 to 29)))); -- Otherwise fetch instruction 1
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								tempinstr2 := cache0(to_integer(unsigned(programcounter(25 to 29)))+ 1); -- Fetch Instruction 2
								temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
								tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
								
								tempmiss := '0';
							end if;
						elsif incomplete = '1' then
							tempinstr2 := cache0(0);-- If only 1 needs to be fetched fetch it
							temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
							tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
							tempmiss := '0';
							incomplete := '0';
						end if;
					else 
						tempmiss := '1';
					end if;
				else 
					tempmiss := '1';
				end if;
----END CACHE 0 CHECK---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------ CACHE 1 CHECK 0-------------------------------------------------------------------------------------------------------------------------------------------------------------------
			elsif programcounter(23 to 24) = "01" then -- check index
				if programcounter(0 to 22) = tag1 then -- check tags
					if valid1 = '1' then -- check data valid
						if incomplete /= '1' then
							if programcounter(25 to 31) = "1111100" then -- check if 2 instructions can be fetched from cache if not save one in temp memory and ititialize 
								tempinstr1 := cache1(31);
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								incomplete := '1';
								tempmiss := '1'; 
							else
								tempinstr1 := cache1(to_integer(unsigned(programcounter(25 to 29))));
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								tempinstr2 := cache1(to_integer(unsigned(programcounter(25 to 29)))+ 1);
								temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
								tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
								
								tempmiss := '0';
							end if;
						elsif incomplete = '1' then
							tempinstr2 := cache1(0);
							temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
							tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
							tempmiss := '0';
							incomplete := '0';
						end if;
					else 
						tempmiss := '1';
					end if;
				else 
					tempmiss := '1';
				end if;
----END CACHE 1 CHECK---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------ CACHE 2 CHECK 0-------------------------------------------------------------------------------------------------------------------------------------------------------------------
			elsif programcounter(23 to 24) = "10" then -- check index
				if programcounter(0 to 22) = tag2 then -- check tags
					if valid2 = '1' then -- check data valid
						if incomplete /= '1' then
							if programcounter(25 to 31) = "1111100" then -- check if 2 instructions can be fetched from cache if not save one in temp memory and ititialize 
								tempinstr1 := cache2(31);
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								incomplete := '1';
								tempmiss := '1'; 
							else
								tempinstr1 := cache2(to_integer(unsigned(programcounter(25 to 29))));
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								tempinstr2 := cache2(to_integer(unsigned(programcounter(25 to 29)))+ 1);
								temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
								tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
								
								tempmiss := '0';
							end if;
						elsif incomplete = '1' then
							tempinstr2 := cache2(0);
							temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
							tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
							tempmiss := '0';
							incomplete := '0';
						end if;
					else 
						tempmiss := '1';
					end if;
				else 
					tempmiss := '1';
				end if;
----END CACHE 2 CHECK---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------ CACHE 3 CHECK 0-------------------------------------------------------------------------------------------------------------------------------------------------------------------
			elsif programcounter(23 to 24) = "11" then -- check index
				if programcounter(0 to 22) = tag3 then -- check tags
					if valid3 = '1' then -- check data valid
						if incomplete /= '1' then
							if programcounter(25 to 31) = "1111100" then -- check if 2 instructions can be fetched from cache if not save one in temp memory and ititialize 
								tempinstr1 := cache3(31);
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								incomplete := '1';
								tempmiss := '1'; 
							else
								tempinstr1 := cache3(to_integer(unsigned(programcounter(25 to 29))));
								temptimestamp1 := std_logic_vector(timestamp);
								tempPC1 := programcounter;
								
								tempinstr2 := cache3(to_integer(unsigned(programcounter(25 to 29)))+ 1);
								temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
								tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
								
								tempmiss := '0';
							end if;
						elsif incomplete = '1' then
							tempinstr2 := cache3(0);
							temptimestamp2 := std_logic_vector(unsigned(timestamp) + "0001");
							tempPC2 := std_logic_vector(unsigned(programcounter) + x"00000004");
							tempmiss := '0';
							incomplete := '0';
						end if;
					else 
						tempmiss := '1';
					end if;
				else 
					tempmiss := '1';
				end if;
----END CACHE 1 CHECK---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			end if; -- end check for data
			
--- CHECK FLAGS AND OUTPUT DATA--------------------------------------------------------------------------------------------------------------------------------------------------------------------
			if (waiting = '1') and (stoppc = '0') and (branchflag /= '1') then -- if Program counter disabled output instructions to do nothing, keep all other variables the same
				
				instr1 <= "01000000001" & "0000000" & "0000000" & "0000000";
				timestamp1 <= std_logic_vector(timestamp);
				PC1 <= programcounter;
				
				instr2 <= "00000000001" & "1111111" & "1111111" & "1111111";
				timestamp2 <= std_logic_vector(timestamp + "0001");
				PC2 <= programcounter;
				
				timestamp := timestamp + "0010";		
				
			elsif branchflag = '1' then -- if waiting for instruction to be loaded
				
				instr1 <= "01000000001" & "0000000" & "0000000" & "0000000";
				timestamp1 <= std_logic_vector(timestamp);
				PC1 <= programcounter;
				
				instr2 <= "00000000001" & "1111111" & "1111111" & "1111111";
				timestamp2 <= std_logic_vector(timestamp + "0001");
				PC2 <= programcounter;
				
				timestamp := timestamp + "0010";		
			
			
			elsif tempmiss /= '1' and incomplete /= '1'  and waiting /= '1' and (branchflag /= '1') then -- normal case output instructions and update program counter
				instr1 <= tempinstr1;
				timestamp1 <= temptimestamp1;
				PC1 <= tempPC1;
				
				instr2 <= tempinstr2;
				timestamp2 <= temptimestamp2;
				PC2 <= tempPC2;
				
				timestamp := timestamp + "0010"; -- add 2 to time stamp counter
				programcounter := std_logic_vector(unsigned(programcounter) + x"00000008"); -- add 8 (2 instruction) to the program counter
			
			elsif ((tempmiss = '1' and incomplete /= '1' and waiting /= '1') or (waiting = '1' and stoppc = '1')) and (branchflag /= '1') then -- Instruction miss send out instruction to get data from memory
				waiting <= '1'; -- declare waiting
				
				instr1 <= "1111" & programcounter(0 to 27); -- send instruction to fetch block
				timestamp1 <= std_logic_vector(timestamp);
				PC1 <= programcounter;
				
				instr2 <= "00000000001" & "1111111" & "1111111" & "1111111"; -- Other instruction is do nothing
				timestamp2 <= std_logic_vector(timestamp + "0001");
				PC2 <= programcounter;
				
				timestamp := timestamp + "0010";
			
			elsif (tempmiss = '1' and incomplete = '1' and waiting /= '1')  and (branchflag /= '1') then -- After instruction miss instruction is sent and waiting for data back from memory, send do nothing via both instructions
				waiting <= '1'; -- declare waiting
				programcounter := std_logic_vector(unsigned(programcounter) + x"00000004");
				
				instr1 <= "1111" & programcounter(0 to 27); -- send instruction to fetch block
				timestamp1 <= std_logic_vector(timestamp);
				PC1 <= programcounter;
				
				instr2 <= "00000000001" & "1111111" & "1111111" & "1111111";
				timestamp2 <= std_logic_vector(timestamp + "0001");
				PC2 <= programcounter;
				
				timestamp := timestamp + "0010";
			end if;	
			
		end if; -- end stop pc if
-- END INSTRUCTION FETCH-------------------------------------------------------------------------------------------------------------------------------------------------------		
--- LOAD CACHE BLOCKS SECTION---------------------------------------------------------------------------------------------------------------------
		if waiting = '1' then -- if waiting for data
			if cacheloadin(0) = '1' then -- if data is valid (ie ready)
				if cacheloadin(24 to 25) = "00" then -- check index
					cache0(0) <= cacheloadin(26 to 57);
					cache0(1) <= cacheloadin(58 to 89);
					cache0(2) <= cacheloadin(90 to 121);
					cache0(3) <= cacheloadin(122 to 153);
					cache0(4) <= cacheloadin(154 to 185);
					cache0(5) <= cacheloadin(186 to 217);
					cache0(6) <= cacheloadin(218 to 249);
					cache0(7) <= cacheloadin(250 to 281);
					cache0(8) <= cacheloadin(282 to 313);
					cache0(9) <= cacheloadin(314 to 345);
					cache0(10) <= cacheloadin(346 to 377);
					cache0(11) <= cacheloadin(378 to 409);
					cache0(12) <= cacheloadin(410 to 441);
					cache0(13) <= cacheloadin(442 to 473);
					cache0(14) <= cacheloadin(474 to 505);
					cache0(15) <= cacheloadin(506 to 537);
					cache0(16) <= cacheloadin(538 to 569);
					cache0(17) <= cacheloadin(570 to 601);
					cache0(18) <= cacheloadin(602 to 633);
					cache0(19) <= cacheloadin(634 to 665);
					cache0(20) <= cacheloadin(666 to 697);
					cache0(21) <= cacheloadin(698 to 729);
					cache0(22) <= cacheloadin(730 to 761);
					cache0(23) <= cacheloadin(762 to 793);
					cache0(24) <= cacheloadin(794 to 825);
					cache0(25) <= cacheloadin(826 to 857);
					cache0(26) <= cacheloadin(858 to 889);
					cache0(27) <= cacheloadin(890 to 921);
					cache0(28) <= cacheloadin(922 to 953);
					cache0(29) <= cacheloadin(954 to 985);
					cache0(30) <= cacheloadin(986 to 1017);
					cache0(31) <= cacheloadin(1018 to 1049);
					
					
					valid0 := '1';
					tag0 := cacheloadin(1 to 23);
					index0 := cacheloadin(24 to 25);
					
					waiting <= '0';
				
				elsif cacheloadin(24 to 25) = "01" then -- check index
					cache1(0) <= cacheloadin(26 to 57);
					cache1(1) <= cacheloadin(58 to 89);
					cache1(2) <= cacheloadin(90 to 121);
					cache1(3) <= cacheloadin(122 to 153);
					cache1(4) <= cacheloadin(154 to 185);
					cache1(5) <= cacheloadin(186 to 217);
					cache1(6) <= cacheloadin(218 to 249);
					cache1(7) <= cacheloadin(250 to 281);
					cache1(8) <= cacheloadin(282 to 313);
					cache1(9) <= cacheloadin(314 to 345);
					cache1(10) <= cacheloadin(346 to 377);
					cache1(11) <= cacheloadin(378 to 409);
					cache1(12) <= cacheloadin(410 to 441);
					cache1(13) <= cacheloadin(442 to 473);
					cache1(14) <= cacheloadin(474 to 505);
					cache1(15) <= cacheloadin(506 to 537);
					cache1(16) <= cacheloadin(538 to 569);
					cache1(17) <= cacheloadin(570 to 601);
					cache1(18) <= cacheloadin(602 to 633);
					cache1(19) <= cacheloadin(634 to 665);
					cache1(20) <= cacheloadin(666 to 697);
					cache1(21) <= cacheloadin(698 to 729);
					cache1(22) <= cacheloadin(730 to 761);
					cache1(23) <= cacheloadin(762 to 793);
					cache1(24) <= cacheloadin(794 to 825);
					cache1(25) <= cacheloadin(826 to 857);
					cache1(26) <= cacheloadin(858 to 889);
					cache1(27) <= cacheloadin(890 to 921);
					cache1(28) <= cacheloadin(922 to 953);
					cache1(29) <= cacheloadin(954 to 985);
					cache1(30) <= cacheloadin(986 to 1017);
					cache1(31) <= cacheloadin(1018 to 1049);
					
					
					valid1 := '1';
					tag1 := cacheloadin(1 to 23);
					index1 := cacheloadin(24 to 25);
					
					waiting <= '0';
				
				elsif cacheloadin(24 to 25) = "10" then -- check index
					cache2(0) <= cacheloadin(26 to 57);
					cache2(1) <= cacheloadin(58 to 89);
					cache2(2) <= cacheloadin(90 to 121);
					cache2(3) <= cacheloadin(122 to 153);
					cache2(4) <= cacheloadin(154 to 185);
					cache2(5) <= cacheloadin(186 to 217);
					cache2(6) <= cacheloadin(218 to 249);
					cache2(7) <= cacheloadin(250 to 281);
					cache2(8) <= cacheloadin(282 to 313);
					cache2(9) <= cacheloadin(314 to 345);
					cache2(10) <= cacheloadin(346 to 377);
					cache2(11) <= cacheloadin(378 to 409);
					cache2(12) <= cacheloadin(410 to 441);
					cache2(13) <= cacheloadin(442 to 473);
					cache2(14) <= cacheloadin(474 to 505);
					cache2(15) <= cacheloadin(506 to 537);
					cache2(16) <= cacheloadin(538 to 569);
					cache2(17) <= cacheloadin(570 to 601);
					cache2(18) <= cacheloadin(602 to 633);
					cache2(19) <= cacheloadin(634 to 665);
					cache2(20) <= cacheloadin(666 to 697);
					cache2(21) <= cacheloadin(698 to 729);
					cache2(22) <= cacheloadin(730 to 761);
					cache2(23) <= cacheloadin(762 to 793);
					cache2(24) <= cacheloadin(794 to 825);
					cache2(25) <= cacheloadin(826 to 857);
					cache2(26) <= cacheloadin(858 to 889);
					cache2(27) <= cacheloadin(890 to 921);
					cache2(28) <= cacheloadin(922 to 953);
					cache2(29) <= cacheloadin(954 to 985);
					cache2(30) <= cacheloadin(986 to 1017);
					cache2(31) <= cacheloadin(1018 to 1049);
					
					
					valid2 := '1';
					tag2 := cacheloadin(1 to 23);
					index2 := cacheloadin(24 to 25);
					
					waiting <= '0';
				
				elsif cacheloadin(24 to 25) = "11" then -- check index
					cache3(0) <= cacheloadin(26 to 57);
					cache3(1) <= cacheloadin(58 to 89);
					cache3(2) <= cacheloadin(90 to 121);
					cache3(3) <= cacheloadin(122 to 153);
					cache3(4) <= cacheloadin(154 to 185);
					cache3(5) <= cacheloadin(186 to 217);
					cache3(6) <= cacheloadin(218 to 249);
					cache3(7) <= cacheloadin(250 to 281);
					cache3(8) <= cacheloadin(282 to 313);
					cache3(9) <= cacheloadin(314 to 345);
					cache3(10) <= cacheloadin(346 to 377);
					cache3(11) <= cacheloadin(378 to 409);
					cache3(12) <= cacheloadin(410 to 441);
					cache3(13) <= cacheloadin(442 to 473);
					cache3(14) <= cacheloadin(474 to 505);
					cache3(15) <= cacheloadin(506 to 537);
					cache3(16) <= cacheloadin(538 to 569);
					cache3(17) <= cacheloadin(570 to 601);
					cache3(18) <= cacheloadin(602 to 633);
					cache3(19) <= cacheloadin(634 to 665);
					cache3(20) <= cacheloadin(666 to 697);
					cache3(21) <= cacheloadin(698 to 729);
					cache3(22) <= cacheloadin(730 to 761);
					cache3(23) <= cacheloadin(762 to 793);
					cache3(24) <= cacheloadin(794 to 825);
					cache3(25) <= cacheloadin(826 to 857);
					cache3(26) <= cacheloadin(858 to 889);
					cache3(27) <= cacheloadin(890 to 921);
					cache3(28) <= cacheloadin(922 to 953);
					cache3(29) <= cacheloadin(954 to 985);
					cache3(30) <= cacheloadin(986 to 1017);
					cache3(31) <= cacheloadin(1018 to 1049);
					
					
					valid3 := '1';
					tag3 := cacheloadin(1 to 23);
					index3 := cacheloadin(24 to 25);
					
					waiting <= '0';
				end if;
			end if;
		end if;
-- END LOAD CACHEL BLOCKS SECTION		
	end if;	--end clk and enable if
	end process;
end behavioral;