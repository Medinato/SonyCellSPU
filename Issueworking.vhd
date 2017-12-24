--Issue Stage
--David Gash
-- Issue Stage for Cell SPU
-- This stage accepts two instructions each cycle and checks for data hazards
--If data hazard detected it delays both instructions until the instructions can be processed properly
--Calculates datafowarding values which are passed to register file in order to improve preformance


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity issue is
port(
	-- General Inputs
    clk: in std_logic; --clock input
    enable: in std_logic; --block enable
	branchflag: in std_logic; -- branch flag needed to clear inputs if 
	cleareven: in std_logic; --1 means extra data was cleared during even branch
	hazard: out std_logic; -- signal to stop decode and pc stage from processing if hazard occurs
	
	
	-- EVEN INPUTS 
	evenaddrAin: in std_logic_vector(0 to 6); --input A
	evenaddrBin: in std_logic_vector(0 to 6); --input B
	evenaddrCin: in std_logic_vector(0 to 6); --input C 
	evenopcodein: in std_logic_vector(0 to 10);  --opcode input
	evenrtin: in std_logic_vector(0 to 6);-- destination register
	evenPCin: in std_logic_vector(0 to 31); --program counter in
	evenimmediatein: in std_logic_vector(0 to 15); -- immediate 16 bit input
	eventimestampoutin : in std_logic_vector(0 to 3); --time stamp to determine execution order
	evendataavailin : in std_logic_vector(0 to 6);
	

	-- Odd INPUTS 
	oddaddrAin: in std_logic_vector(0 to 6); --input A
	oddaddrBin: in std_logic_vector(0 to 6); --input B
	oddaddrCin: in std_logic_vector(0 to 6); --input C 
	oddopcodein: in std_logic_vector(0 to 10);  --opcode input
	oddrtin: in std_logic_vector(0 to 6);-- destination register
	oddPCin: in std_logic_vector(0 to 31); --program counter in
	oddimmediatein: in std_logic_vector(0 to 15); -- immediate 16 bit input
	oddtimestampoutin: in std_logic_vector(0 to 3); --time stamp to determine execution order	
	odddataavailin : in std_logic_vector(0 to 6);
	
	--Even Outputs
	evenaddrAout: out std_logic_vector(0 to 6); --input A
	evenaddrBout: out std_logic_vector(0 to 6); --input B
	evenaddrCout: out std_logic_vector(0 to 6); --input C 
	evenopcodeout: out std_logic_vector(0 to 10);  --opcode input
	evenrtout: out std_logic_vector(0 to 6);-- destination register
	evenPCout: out std_logic_vector(0 to 31); --program counter in
	evenimmediateout: out std_logic_vector(0 to 15); -- immediate 16 bit input
	eventimestampout: out std_logic_vector(0 to 3); --time stamp to determine execution order
	evendatafowardAout: out std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	evendatafowardBout: out std_logic_vector(0 to 4); 
	evendatafowardCout: out std_logic_vector(0 to 4);

	--Odd Outputs
	oddaddrAout: out std_logic_vector(0 to 6); --input A
	oddaddrBout: out std_logic_vector(0 to 6); --input B
	oddaddrCout: out std_logic_vector(0 to 6); --input C 
	oddopcodeout: out std_logic_vector(0 to 10);  --opcode input
	oddrtout: out std_logic_vector(0 to 6);-- destination register
	oddPCout: out std_logic_vector(0 to 31); --program counter in
	oddimmediateout: out std_logic_vector(0 to 15); -- immediate 16 bit input
	oddtimestampout: out std_logic_vector(0 to 3); --time stamp to determine execution order
	odddatafowardAout: out std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	odddatafowardBout: out std_logic_vector(0 to 4); 
	odddatafowardCout: out std_logic_vector(0 to 4)
    );

end issue;


architecture behavioral of issue is		  

subtype target is std_logic_vector(0 to 7);

type issuetrack is array(0 to 9) of target;
signal targetsinflightodd : issuetrack; --array to place the target registers (rt) of instructions in flight to use to see if data can be fowarded
signal targetsinflighteven : issuetrack; --array to place the target registers (rt) of instructions in flight to use to see if data can be fowarded

signal test: std_logic := '0'; -- test signal for debugging

begin
	process(enable, clk)  
	--variables to hold in work values for fowarding (000) means no fowarding
		variable fowardoddA: std_logic_vector(0 to 4);
		variable fowardoddB: std_logic_vector(0 to 4);
		variable fowardoddC: std_logic_vector(0 to 4);
		
		variable fowardevenA: std_logic_vector(0 to 4);
		variable fowardevenB: std_logic_vector(0 to 4);
		variable fowardevenC: std_logic_vector(0 to 4);
	--variables to signal that a delay is needed 
		variable delayoddA: std_logic;
		variable delayoddB: std_logic;
		variable delayoddC: std_logic;
		variable delayevenA: std_logic;
		variable delayevenB: std_logic;
		variable delayevenC: std_logic;
		variable delay: std_logic;
		
		variable evenaddrAinv: std_logic_vector(0 to 6); --input A
		variable evenaddrBinv: std_logic_vector(0 to 6); --input B
		variable evenaddrCinv: std_logic_vector(0 to 6); --input C 
		variable evenopcodeinv: std_logic_vector(0 to 10);  --opcode input
		variable evenrtinv: std_logic_vector(0 to 6);-- destination register
		variable evenPCinv: std_logic_vector(0 to 31); --program counter in
		variable evenimmediateinv: std_logic_vector(0 to 15); -- immediate 16 bit input
		variable eventimestampoutinv : std_logic_vector(0 to 3); --time stamp to determine execution order
		variable evendataavailinv : std_logic_vector(0 to 6);
		

		-- Odd INPUTS 
		variable oddaddrAinv: std_logic_vector(0 to 6); --input A
		variable oddaddrBinv: std_logic_vector(0 to 6); --input B
		variable oddaddrCinv: std_logic_vector(0 to 6); --input C 
		variable oddopcodeinv: std_logic_vector(0 to 10);  --opcode input
		variable oddrtinv: std_logic_vector(0 to 6);-- destination register
		variable oddPCinv: std_logic_vector(0 to 31); --program counter in
		variable oddimmediateinv: std_logic_vector(0 to 15); -- immediate 16 bit input
		variable oddtimestampoutinv: std_logic_vector(0 to 3); --time stamp to determine execution order	
		variable odddataavailinv : std_logic_vector(0 to 6);
		
	begin
	
		if rising_edge(clk) and enable = '1' then
			delayoddA := '0';
			delayoddB := '0';
			delayoddC := '0';
			delayevenA := '0'; -- clear flags
			delayevenB := '0'; -- clear flags
			delayevenC := '0'; -- clear flags
			
			-- if no delay ingest the next instructions assigns to variables to isolate calcuations from input which may change during the course of processing
			if delay = '0' then
				
		
				evenaddrAinv := evenaddrAin;
				evenaddrBinv := evenaddrBin;
				evenaddrCinv := evenaddrCin;
				evenopcodeinv := evenopcodein;
				evenrtinv := evenrtin;
				evenPCinv := evenPCin;
				evenimmediateinv := evenimmediatein;
				eventimestampoutinv := eventimestampoutin;
				evendataavailinv := evendataavailin;
					

					-- Odd INPUTS 
				oddaddrAinv := oddaddrAin;
				oddaddrBinv := oddaddrBin;
				oddaddrCinv := oddaddrCin;
				oddopcodeinv := oddopcodein;
				oddrtinv := oddrtin;
				oddPCinv := oddPCin;
				oddimmediateinv := oddimmediatein;
				oddtimestampoutinv := oddtimestampoutin;
				odddataavailinv := odddataavailin;

			
			end if;
				
			if branchflag /= '1' then -- if not branch
			
			--check for fowarding required A
	-------EVEN HAZARD CHECK-----------------------------------------------------------------------------------------------------
				if evenopcodeinv = "00000000001" or evenopcodeinv = "01000000001" or evenopcodeinv = "11110000000" then --if instruction has no target and no inputs no data hazard can occur
					delayevenA := '0';
					delayevenB := '0';
					delayevenC := '0';
				else
				--CHECK A
					evenAcheck: for I in 0 to 8 loop --data hazard no fowarding available
					--check most recent introductions to the pipeline first
						--if targetsinflightodd(I)(0) /= '0' and targetsinflighteven(I)(0) /= '1' then
							if I = 0 or I = 1 then -- this checks data in register file or first cycle inside of execute
								if ((evenaddrAinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) or ((evenaddrAinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									delayevenA := '1';
									fowardevenA := "00000"; -- no fowarding
									exit evenAcheck;
								end if;
						--Go in order break out at most recent match			
							elsif (I >= 2) and (I <= 7) then	-- This stage checks data currently in the execute stage (data can be avail)
							-- Check odd data
								if ((evenaddrAinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
									if odddataavailin(I-1) = '1' then --check if data is valid and avaialable 
										if I = 2 then
											fowardevenA := "01001";
										elsif I = 3 then
											fowardevenA := "01010";
										elsif I = 4 then
											fowardevenA := "01011";
										elsif I = 5 then
											fowardevenA := "01100";
										elsif I = 6 then
											fowardevenA := "01101";
										elsif I = 7 then
											fowardevenA := "01110";
										
										end if;
									
										exit evenAcheck;
									elsif odddataavailin(I-1) = '0' then -- if data not valid delay
										delayevenA := '1';
										fowardevenA := "00000";	  

										exit evenAcheck;
									end if;
									
								elsif ((evenaddrAinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
								--Check even data
									if evendataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardevenA := "00001";
										elsif I = 3 then
											fowardevenA := "00010";
										elsif I = 4 then
											fowardevenA := "00011";
										elsif I = 5 then
											fowardevenA := "00100";
										elsif I = 6 then
											fowardevenA := "00101";
										elsif I = 7 then
											fowardevenA := "00110";
										
										end if;
								
										exit evenAcheck;
										
									elsif evendataavailin(I-1) = '0' then -- if data not valid delay
										delayevenA := '1';
										fowardevenA := "00000";
										exit evenAcheck;
									end if;
								end if;	
							elsif I = 8 then --last data bit is always avail for fowarding (from the register file writeback)
								if ((evenaddrAinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
								
									fowardevenA := "10000";		
									exit evenAcheck;
								
								elsif ((evenaddrAinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
								
									fowardevenA := "10001";
									exit evenAcheck;
									
								else --no fowarding required
									
									fowardevenA := "00000";
								end if;
							end if;
						--end if;
					end loop;
				-- End Check A
					--CHECK B
					evenBcheck: for I in 0 to 8 loop --data hazard no fowarding available
					--check most recent introductions to the pipeline first
						--if targetsinflightodd(I)(0) /= '0' and targetsinflighteven(I)(0) /= '1' then
							if I = 0 or I = 1 then
								if ((evenaddrBinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) or ((evenaddrBinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									delayevenB := '1';
									fowardevenB := "00000"; -- no fowarding

								
									exit evenBcheck;
								end if;
						--Go in order break out at most recent match			
							elsif (I >= 2) and (I <= 7) then	
								if ((evenaddrBinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
									if odddataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardevenB := "01001";
										elsif I = 3 then
											fowardevenB := "01010";
										elsif I = 4 then
											fowardevenB := "01011";
										elsif I = 5 then
											fowardevenB := "01100";
										elsif I = 6 then
											fowardevenB := "01101";
										elsif I = 7 then
											fowardevenB := "01110";
										
										end if;
									
										exit evenBcheck;
									elsif odddataavailin(I-1) = '0' then -- if data not valid delay
										delayevenB := '1';										
										fowardevenB := "00000";	  

										exit evenBcheck;
									end if;
									
								elsif ((evenaddrBinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									if evendataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardevenB := "00001";
										elsif I = 3 then
											fowardevenB := "00010";
										elsif I = 4 then
											fowardevenB := "00011";
										elsif I = 5 then
											fowardevenB := "00100";
										elsif I = 6 then
											fowardevenB := "00101";
										elsif I = 7 then
											fowardevenB := "00110";
										
										end if;
								
										exit evenBcheck;
										
									elsif evendataavailin(I-1) = '0' then -- if data not valid delay
										delayevenB := '1';
										fowardevenB := "00000";
										exit evenBcheck;
									end if;
								end if;	
							elsif I = 8 then --last data bit is always avail for fowarding
								if ((evenaddrBinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
								
									fowardevenB := "10000";		
									exit evenBcheck;
								
								elsif ((evenaddrBinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
								
									fowardevenB := "10001";
									exit evenBcheck;
									
								else --no fowarding required
									
									fowardevenB := "00000";
								end if;
							end if;
						--end if;
					end loop;
					
					
				-- End Check B
					
				--CHECK C
					if evenopcodeinv = "11100000000" or evenopcodeinv = "11000000000" then
						evenCcheck: for I in 0 to 8 loop --data hazard no fowarding available
						--check most recent introductions to the pipeline first
							--if targetsinflightodd(I)(0) /= '0' and targetsinflighteven(I)(0) /= '1' then
								if I = 0 or I = 1 then
									if ((evenaddrCinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) or ((evenaddrCinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
										delayevenC := '1';
										fowardevenC := "00000"; -- no fowarding
										test <= '1';
										exit evenCcheck;
									end if;
							--Go in order break out at most recent match			
								elsif (I >= 2) and (I <= 7) then	
									if ((evenaddrCinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
										if odddataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
											if I = 2 then
												fowardevenC := "01001";
											elsif I = 3 then
												fowardevenC := "01010";
											elsif I = 4 then
												fowardevenC := "01011";
											elsif I = 5 then
												fowardevenC := "01100";
											elsif I = 6 then
												fowardevenC := "01101";
											elsif I = 7 then
												fowardevenC := "01110";
											
											end if;
										
											exit evenCcheck;
										elsif odddataavailin(I-1) = '0' then -- if data not valid delay
											delayevenC := '1';
											fowardevenC := "00000";	  

											exit evenCcheck;
										end if;
										
									elsif ((evenaddrCinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
										if evendataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
											if I = 2 then
												fowardevenC := "00001";
											elsif I = 3 then
												fowardevenC := "00010";
											elsif I = 4 then
												fowardevenC := "00011";
											elsif I = 5 then
												fowardevenC := "00100";
											elsif I = 6 then
												fowardevenC := "00101";
											elsif I = 7 then
												fowardevenC := "00110";
											
											end if;
									
											exit evenCcheck;
											
										elsif evendataavailin(I-1) = '0' then -- if data not valid delay
											delayevenC := '1';
											fowardevenC := "00000";
											exit evenCcheck;
										end if;
									end if;	
								elsif I = 8 then --last data bit is always avail for fowarding
									if ((evenaddrCinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
									
										fowardevenC := "10000";		
										exit evenCcheck;
									
									elsif ((evenaddrCinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									
										fowardevenC := "10001";
										exit evenCcheck;
										
									else --no fowarding required
										
										fowardevenC := "00000";
									end if;
								end if;
							--end if;
						end loop;
					end if;
				end if;
				-- End Check B
------ END EVEN HAZARD CHECK---------------------------------------------------------------------------------------		

---------odd HAZARD CHECK-----------------------------------------------------------------------------------------------------
--CHECK A
				if oddopcodeinv = "00000000001" or oddopcodeinv = "01000000001" or oddopcodeinv = "11110000000" or  oddopcodeinv = "01000000100" or oddopcodeinv = "01000001000" or oddopcodeinv = "01000001100" then --IF instruction has no inputs(other than oimmediate) no hazards possible
					delayoddA := '0';
					delayoddB := '0';
					delayoddC := '0';
				
				else
				
					oddAcheck: for I in 0 to 8 loop --data hazard no fowarding available
					--check most recent introductions to the pipeline first
					--if targetsinflightodd(I)(0) /= '0' and targetsinflighteven(I)(0) /= '1' then
						
							if I = 0 or I = 1 then
								if ((oddaddrAinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) or ((oddaddrAinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									delayoddA := '1';
									fowardoddA := "00000"; -- no fowarding
					
									exit oddAcheck;
								end if;
						--Go in order break out at most recent match			
							elsif (I >= 2) and (I <= 7) then	
								if ((oddaddrAinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
									if odddataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardoddA := "01001";
										elsif I = 3 then
											fowardoddA := "01010";
										elsif I = 4 then
											fowardoddA := "01011";
										elsif I = 5 then
											fowardoddA := "01100";
										elsif I = 6 then
											fowardoddA := "01101";
										elsif I = 7 then
											fowardoddA := "01110";
										
										
										end if;
										exit oddAcheck;
									elsif odddataavailin(I-1) = '0' then -- if data not valid delay
										delayoddA := '1';
										fowardoddA := "00000";	  
										
										exit oddAcheck;
									end if;
									
								elsif ((oddaddrAinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									if evendataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardoddA := "00001";
										elsif I = 3 then
											fowardoddA := "00010";
										elsif I = 4 then
											fowardoddA := "00011";
										elsif I = 5 then
											fowardoddA := "00100";
										elsif I = 6 then
											fowardoddA := "00101";
										elsif I = 7 then
											fowardoddA := "00110";
										
										end if;
								
										exit oddAcheck;
										
									elsif evendataavailin(I-1) = '0' then -- if data not valid delay
										delayoddA := '1';
										fowardoddA := "00000";
										exit oddAcheck;
									end if;
								end if;	
							elsif I = 8 then --last data bit is always avail for fowarding
								if ((oddaddrAinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
								
									fowardoddA := "10000";		
									exit oddAcheck;
								
								elsif ((oddaddrAinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
								
									fowardoddA := "10001";
									exit oddAcheck;
									
								else --no fowarding required
									
									fowardoddA := "00000";
								end if;
							end if;
						--end if;
					end loop;
				-- End Check A
				--CHECK B
					oddBcheck: for I in 0 to 8 loop --data hazard no fowarding available
					--check most recent introductions to the pipeline first
						--if targetsinflightodd(I)(0) /= '0' and targetsinflighteven(I)(0) /= '1' then
							if I = 0 or I = 1 then
								if ((oddaddrBinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) or ((oddaddrBinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									delayoddB := '1';
									fowardoddB := "00000"; -- no fowarding
									
									exit oddBcheck;
								end if;
						--Go in order break out at most recent match			
							elsif (I >= 2) and (I <= 7) then	
								if ((oddaddrBinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
									if odddataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardoddB := "01001";
										elsif I = 3 then
											fowardoddB := "01010";
										elsif I = 4 then
											fowardoddB := "01011";
										elsif I = 5 then
											fowardoddB := "01100";
										elsif I = 6 then
											fowardoddB := "01101";
										elsif I = 7 then
											fowardoddB := "01110";
										
										end if;
									
										exit oddBcheck;
									elsif odddataavailin(I-1) = '0' then -- if data not valid delay
										delayoddB := '1';
										fowardoddB := "00000";	  
										
										exit oddBcheck;
									end if;
									
								elsif ((oddaddrBinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
									if evendataavailin(I-1) = '1' then -- check for valid data if so set fowarding up
										if I = 2 then
											fowardoddB := "00001";
										elsif I = 3 then
											fowardoddB := "00010";
										elsif I = 4 then
											fowardoddB := "00011";
										elsif I = 5 then
											fowardoddB := "00100";
										elsif I = 6 then
											fowardoddB := "00101";
										elsif I = 7 then
											fowardoddB := "00110";
										
										end if;
								
										exit oddBcheck;
										
									elsif evendataavailin(I-1) = '0' then -- if data not valid delay
										delayoddB := '1';
										fowardoddB := "00000";
										exit oddBcheck;
									end if;
								end if;	
							elsif I = 8 then --last data bit is always avail for fowarding
								if ((oddaddrBinv = targetsinflightodd(I)(1 to 7)) and (targetsinflightodd(I)(0) = '1')) then
								
									fowardoddB := "10000";		
									exit oddBcheck;
								
								elsif ((oddaddrBinv = targetsinflighteven(I)(1 to 7)) and (targetsinflighteven(I)(0) = '1' )) then
								
									fowardoddB := "10001";
									exit oddBcheck;
									
								else --no fowarding required
									
									fowardoddB := "00000";
								end if;
							end if;
						--end if;
					end loop;
				-- End Check B
				
				

------ END ODD HAZARD CHECK--------------------------------------------------		
				end if;
			
				if delayoddA = '1' or delayoddB = '1' or delayoddC = '1' or delayevenA = '1' or delayevenB = '1' or delayevenC = '1' then -- if any function needs delay set delay flag
					delay := '1';
				else
					delay := '0'; -- otherwise do not set delay flag
				end if;

			--Data Output	
				if delay = '1' then -- if data fowarding cant solve problem delay both instructions and send nops for now.
				
					evenaddrAout <= "0000000"; --input A
					evenaddrBout <= "0000000"; --input B
					evenaddrCout <= "0000000"; --input C 
					evenopcodeout <= "00000000001";  --opcode input
					evenrtout <= "0000000";-- destination register
					evenPCout <= x"00000000"; --program counter in
					evenimmediateout <= x"0000"; -- immediate 16 bit input
					eventimestampout <= "0000"; --time stamp to determine execution order
					evendatafowardAout <= "00000"; --data to foward if 0 no fowarding
					evendatafowardBout <= "00000"; 
					evendatafowardCout <= "00000";
					--Odd Outputs
					oddaddrAout <= "0000000"; --input A
					oddaddrBout <= "0000000"; --input B
					oddaddrCout <= "0000000"; --input C 
					oddopcodeout <= "00000000001";  --opcode input
					oddrtout <= "0000000";-- destination register
					oddPCout <= x"00000000"; --program counter in
					oddimmediateout <= x"0000"; -- immediate 16 bit input
					oddtimestampout <= "0000"; --time stamp to determine execution order
					odddatafowardAout <= "00000"; --data to foward if 0 no fowarding
					odddatafowardBout <= "00000"; 
					odddatafowardCout <= "00000";
					
					hazard <= '1'; -- set hazard to 1 to stop Program counter and decode
					-- Updatdate fowarding tables
					--if opcode does not valid data for fowarding
					if oddopcodeinv = "00000000001" or  oddopcodeinv = "01000000001" or  oddopcodeinv = "00110010000" or oddopcodeinv = "00110000000" or oddopcodeinv = "00110010000" or oddopcodeinv = "00110101000" or oddopcodeinv = "00100001000" or oddopcodeinv = "00100000000" or oddopcodeinv = "00100100000"  or oddopcodeinv = "00101000100" or oddopcodeinv = "00100000100" or oddopcodeinv = "00000000001" or oddopcodeinv = "01000000001" or oddopcodeinv = "01111011000" or oddopcodeinv = "01111111000" or oddopcodeinv = "01001011000"  or oddopcodeinv = "01001111000" or oddopcodeinv = "00100010000" or oddopcodeinv = "00100011000" then
						targetsinflightodd(9) <= targetsinflightodd(8);
						targetsinflightodd(8) <= targetsinflightodd(7);
						targetsinflightodd(7) <= targetsinflightodd(6);
						targetsinflightodd(6) <= targetsinflightodd(5);
						targetsinflightodd(5) <= targetsinflightodd(4);
						targetsinflightodd(4) <= targetsinflightodd(3);
						targetsinflightodd(3) <= targetsinflightodd(2);
						targetsinflightodd(2) <= targetsinflightodd(1);
						targetsinflightodd(1) <= targetsinflightodd(0);
						targetsinflightodd(0) <= '0' & "0000000"; -- data not valid this cycle
					-- if opcode does output valid data for fowarding
					else
						targetsinflightodd(9) <= targetsinflightodd(8);
						targetsinflightodd(8) <= targetsinflightodd(7);
						targetsinflightodd(7) <= targetsinflightodd(6);
						targetsinflightodd(6) <= targetsinflightodd(5);
						targetsinflightodd(5) <= targetsinflightodd(4);
						targetsinflightodd(4) <= targetsinflightodd(3);
						targetsinflightodd(3) <= targetsinflightodd(2);
						targetsinflightodd(2) <= targetsinflightodd(1);
						targetsinflightodd(1) <= targetsinflightodd(0);
						targetsinflightodd(0) <= '0' & "0000000"; -- data not valid
					end if;
						
					if evenopcodeinv = "00000000001" or evenopcodeinv = "01000000001" or evenopcodeinv = "11110000000" or evenopcodeinv = "01110111010" then 	
						targetsinflighteven(9) <= targetsinflighteven(8);
						targetsinflighteven(8) <= targetsinflighteven(7);
						targetsinflighteven(7) <= targetsinflighteven(6);
						targetsinflighteven(6) <= targetsinflighteven(5);
						targetsinflighteven(5) <= targetsinflighteven(4);
						targetsinflighteven(4) <= targetsinflighteven(3);
						targetsinflighteven(3) <= targetsinflighteven(2);
						targetsinflighteven(2) <= targetsinflighteven(1);
						targetsinflighteven(1) <= targetsinflighteven(0);
						targetsinflighteven(0) <= '0' & "0000000";
					else
						targetsinflighteven(9) <= targetsinflighteven(8);
						targetsinflighteven(8) <= targetsinflighteven(7);
						targetsinflighteven(7) <= targetsinflighteven(6);
						targetsinflighteven(6) <= targetsinflighteven(5);
						targetsinflighteven(5) <= targetsinflighteven(4);
						targetsinflighteven(4) <= targetsinflighteven(3);
						targetsinflighteven(3) <= targetsinflighteven(2);
						targetsinflighteven(2) <= targetsinflighteven(1);
						targetsinflighteven(1) <= targetsinflighteven(0);
						targetsinflighteven(0) <= '0' & "0000000";
					end if;
									
				
				elsif delay = '0' then -- if no delay needed output data as normal
					--Odd Outputs
					oddaddrAout <= oddaddrAinv; --input A
					oddaddrBout <= oddaddrBinv; --input B
					oddaddrCout <= oddaddrCinv; --input C 
					oddopcodeout <= oddopcodeinv;  --opcode input
					oddrtout <= oddrtinv;-- destination register
					oddPCout <= oddPCinv; --program counter in
					oddimmediateout <= oddimmediateinv; -- immediate 16 bit input
					oddtimestampout <= oddtimestampoutinv; --time stamp to determine execution order
					odddatafowardAout <= fowardoddA; --data to foward if 0 no fowarding
					odddatafowardBout <= fowardoddB; 
					odddatafowardCout <= fowardoddC;
					
					--even Outputs
					evenaddrAout <= evenaddrAinv; --input A
					evenaddrBout <= evenaddrBinv; --input B
					evenaddrCout <= evenaddrCinv; --input C 
					evenopcodeout <= evenopcodeinv;  --opcode input
					evenrtout <= evenrtinv;-- destination register
					evenPCout <= evenPCinv; --program counter in
					evenimmediateout <= evenimmediateinv; -- immediate 16 bit input
					eventimestampout <= eventimestampoutinv; --time stamp to determine execution order
					evendatafowardAout <= fowardevenA; --data to foward if 0 no fowarding
					evendatafowardBout <= fowardevenB; 
					evendatafowardCout <= fowardevenC;
					
					hazard <= '0';
					
					-- Updatdate fowarding tables
					--if opcode does not valid data for fowarding
					if oddopcodeinv = "00000000001" or  oddopcodeinv = "01000000001" or  oddopcodeinv = "00110010000" or oddopcodeinv = "00110000000" or oddopcodeinv = "00110010000" or oddopcodeinv = "00110101000" or oddopcodeinv = "00100001000" or oddopcodeinv = "00100000000" or oddopcodeinv = "00100100000"  or oddopcodeinv = "00101000100" or oddopcodeinv = "00100000100" or oddopcodeinv = "00000000001" or oddopcodeinv = "01000000001" or oddopcodeinv = "01111011000" or oddopcodeinv = "01111111000" or oddopcodeinv = "01001011000"  or oddopcodeinv = "01001111000" or oddopcodeinv = "00100010000" or oddopcodeinv = "00100011000" then
						targetsinflightodd(9) <= targetsinflightodd(8);
						targetsinflightodd(8) <= targetsinflightodd(7);
						targetsinflightodd(7) <= targetsinflightodd(6);
						targetsinflightodd(6) <= targetsinflightodd(5);
						targetsinflightodd(5) <= targetsinflightodd(4);
						targetsinflightodd(4) <= targetsinflightodd(3);
						targetsinflightodd(3) <= targetsinflightodd(2);
						targetsinflightodd(2) <= targetsinflightodd(1);
						targetsinflightodd(1) <= targetsinflightodd(0);
						targetsinflightodd(0) <= '0' & oddrtinv; --nops do not have valid output registers
					-- if opcode does output valid data for fowarding
					else
						targetsinflightodd(9) <= targetsinflightodd(8);
						targetsinflightodd(8) <= targetsinflightodd(7);
						targetsinflightodd(7) <= targetsinflightodd(6);
						targetsinflightodd(6) <= targetsinflightodd(5);
						targetsinflightodd(5) <= targetsinflightodd(4);
						targetsinflightodd(4) <= targetsinflightodd(3);
						targetsinflightodd(3) <= targetsinflightodd(2);
						targetsinflightodd(2) <= targetsinflightodd(1);
						targetsinflightodd(1) <= targetsinflightodd(0);
						targetsinflightodd(0) <= '1' & oddrtinv; --output register assigned is valid
					end if;
						
					if evenopcodeinv = "00000000001" or evenopcodeinv = "01000000001" or evenopcodeinv = "11110000000" or evenopcodeinv = "01110111010" then 	
						targetsinflighteven(9) <= targetsinflighteven(8);
						targetsinflighteven(8) <= targetsinflighteven(7);
						targetsinflighteven(7) <= targetsinflighteven(6);
						targetsinflighteven(6) <= targetsinflighteven(5);
						targetsinflighteven(5) <= targetsinflighteven(4);
						targetsinflighteven(4) <= targetsinflighteven(3);
						targetsinflighteven(3) <= targetsinflighteven(2);
						targetsinflighteven(2) <= targetsinflighteven(1);
						targetsinflighteven(1) <= targetsinflighteven(0);
						targetsinflighteven(0) <= '0' & evenrtinv;
					else
						targetsinflighteven(9) <= targetsinflighteven(8);
						targetsinflighteven(8) <= targetsinflighteven(7);
						targetsinflighteven(7) <= targetsinflighteven(6);
						targetsinflighteven(6) <= targetsinflighteven(5);
						targetsinflighteven(5) <= targetsinflighteven(4);
						targetsinflighteven(4) <= targetsinflighteven(3);
						targetsinflighteven(3) <= targetsinflighteven(2);
						targetsinflighteven(2) <= targetsinflighteven(1);
						targetsinflighteven(1) <= targetsinflighteven(0);
						targetsinflighteven(0) <= '1' & evenrtinv; --output data register valid
						
					end if;
				end if;
					
			
			elsif branchflag = '1' then
			
				evenaddrAout <= "0000000"; --input A
				evenaddrBout <= "0000000"; --input B
				evenaddrCout <= "0000000"; --input C 
				evenopcodeout <= "00000000001";  --opcode input
				evenrtout <= "0000000";-- destination register
				evenPCout <= x"00000000"; --program counter in
				evenimmediateout <= x"0000"; -- immediate 16 bit input
				eventimestampout <= "0000"; --time stamp to determine execution order
				evendatafowardAout <= "00000"; --data to foward if 0 no fowarding
				evendatafowardBout <= "00000"; 
				evendatafowardCout <= "00000";
			--Odd Outputs
				oddaddrAout <= "0000000"; --input A
				oddaddrBout <= "0000000"; --input B
				oddaddrCout <= "0000000"; --input C 
				oddopcodeout <= "00000000001";  --opcode input
				oddrtout <= "0000000";-- destination register
				oddPCout <= x"00000000"; --program counter in
				oddimmediateout <= x"0000"; -- immediate 16 bit input
				oddtimestampout <= "0000"; --time stamp to determine execution order
				odddatafowardAout <= "00000"; --data to foward if 0 no fowarding
				odddatafowardBout <= "00000"; 
				odddatafowardCout <= "00000";
					
				hazard <= '0';
				delay := '0';
				
				
				--when branch need to invalidate data which is erased.
				targetsinflightodd(9) <= targetsinflightodd(8);
				targetsinflightodd(8) <= targetsinflightodd(7);
				targetsinflightodd(7) <= targetsinflightodd(6);
				targetsinflightodd(6) <= targetsinflightodd(5);
				targetsinflightodd(5) <= targetsinflightodd(4)and  "01111111";
				targetsinflightodd(4) <= targetsinflightodd(3) and  "01111111";
				targetsinflightodd(3) <= targetsinflightodd(2) and  "01111111";
				targetsinflightodd(2) <= targetsinflightodd(1) and  "01111111";
				targetsinflightodd(1) <= targetsinflightodd(0) and  "01111111";
				targetsinflightodd(0) <= '0' & oddrtinv;
						
					
					
				if cleareven = '1' then 
				--invalidate data on branch as needed (even pipe depends which instuction cae first)
					targetsinflighteven(9) <= targetsinflighteven(8);
					targetsinflighteven(8) <= targetsinflighteven(7);
					targetsinflighteven(7) <= targetsinflighteven(6);
					targetsinflighteven(6) <= targetsinflighteven(5)and  "01111111";
					targetsinflighteven(5) <= targetsinflighteven(4)and  "01111111";
					targetsinflighteven(4) <= targetsinflighteven(3) and  "01111111";
					targetsinflighteven(3) <= targetsinflighteven(2) and  "01111111";
					targetsinflighteven(2) <= targetsinflighteven(1) and  "01111111";
					targetsinflighteven(1) <= targetsinflighteven(0) and  "01111111";
					targetsinflighteven(0) <= '0' & evenrtinv;
					
					
				else 
					targetsinflighteven(9) <= targetsinflighteven(8);
					targetsinflighteven(8) <= targetsinflighteven(7);
					targetsinflighteven(7) <= targetsinflighteven(6);
					targetsinflighteven(6) <= targetsinflighteven(5);
					targetsinflighteven(5) <= targetsinflighteven(4) and  "01111111";
					targetsinflighteven(4) <= targetsinflighteven(3)and  "01111111";
					targetsinflighteven(3) <= targetsinflighteven(2) and  "01111111";
					targetsinflighteven(2) <= targetsinflighteven(1) and  "01111111";
					targetsinflighteven(1) <= targetsinflighteven(0) and  "01111111";
					targetsinflighteven(0) <= '0' & evenrtinv;
				
					
				end if;
			end if; -- end branch if
		end if; -- end main if;
	end process;
end behavioral;