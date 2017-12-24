--ALU Execution Unit
--David Gash
--Executes SPU instructions


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity ALUodd is
port(
     -- clk: in std_logic; --clock input
    enable: in std_logic; --block enable
    opcode: in std_logic_vector (0 to 10); -- op code input
    indataA: in std_logic_vector (0 to 127); -- input register 1
    indataB: in std_logic_vector (0 to 127); -- input register 2
	indataC: in std_logic_vector(0 to 127); --Input Register 3
	indataI: in std_logic_vector(0 to 15); --input for I16 Immediate Values
	pccurrent: in std_logic_vector(0 to 31); --Input PC for Branches
	timestamp: in std_logic_vector(0 to 3);-- time stamp to decide which command odd or even is first
	timestampout: out std_logic_vector( 0 to 3); --Output of timestamo
	branchflag: out std_logic; --bit that signals a branch output
	pcnext: out std_logic_vector(0 to 31); --pcnext when branch this will be different from pccurrent
    outdata: out std_logic_vector (0 to 127); --single register output
	depth: out std_logic_vector(0 to 2); --depth item to determine when data becomes available
	unit: out std_logic_vector(0 to 2); --Tells what unit executed function
	readmem: out std_logic; --Falg for load commands
	writemem: out std_logic; --flag for store commands
	writereg: out std_logic; --flag to indicate write to reg file
	storevalue: out std_logic_vector(0 to 127); --value to store for store commands
	halt: out std_logic --flag to tell processor to halt execution (halt commands)
    );
end ALUodd;

architecture behavioral of ALUodd is

signal immediate32: std_logic_vector(0 to 31);
signal immediate16: std_logic_vector(0 to 15);	 
signal immediate25: std_logic_vector(0 to 24); 
signal immediate9: std_logic_vector(0 to 8);   



signal LSLR: std_logic_vector(0 to 31) := x"0003FFFF"; --LSLR register value (constant, 256Kb??)



begin
    process( enable, opcode, indataA, indataB, indataI)
	-- Variables to hold temp outputs for word instructions
	variable tempoutword0: std_logic_vector(0 to 31); --Temp value to hold the output
	variable tempoutword1: std_logic_vector(0 to 31); --Temp value to hold the output
	variable tempoutword2: std_logic_vector(0 to 31); --Temp value to hold the output
	variable tempoutword3: std_logic_vector(0 to 31); --Temp value to hold the output
	
	--Variables to Hold Temp Outputs for Halfword Instructions
	variable tempouthf0: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf1: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf2: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf3: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf4: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf5: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf6: std_logic_vector(0 to 15); --Temp value to hold the output
	variable tempouthf7: std_logic_vector(0 to 15); --Temp value to hold the output
	variable mantissa0shift: unsigned(0 to 23);--value to hold mantissa 
	variable mantissa1shift: unsigned(0 to 23); -- variable to hold mantissa
	variable tempbytecount: signed(0 to 7) := "00000000"; --temp byte variable
	variable byteprocess: std_logic_vector(0 to 7);
	variable byteprocess1: std_logic_vector(0 to 7);
	variable tempout: std_logic_vector(0 to 127);
	
	--Variables for Floating Point Math
	variable exponent0: unsigned(0 to 7);
	variable exponent1: unsigned(0 to 7);
	variable exponent2: unsigned(0 to 7);
	variable mantissa0: unsigned(0 to 23);--value to hold mantissa 
	variable mantissa1: unsigned(0 to 23); -- variable to hold mantissa	
	variable mantissa2: unsigned(0 to 23);
	variable resultmantissa: std_logic_vector(0 to 23); --variable to hold mantissa math result
	variable floatresult: unsigned(0 to 24); --variable to hold mantissa math +sign
	variable exponentresult: unsigned(0 to 8);
	variable exponentsub: unsigned(0 to 8);
	variable sign0: std_logic;
	variable sign1: std_logic;
	variable signout: std_logic;
	variable mantissashift: unsigned(0 to 23);
--Floating Point multiplcation
	variable exp0: signed (0 to 7); --signed variable for exponent for multiplication
	variable exp1: signed (0 to 7); --signed variable for exponent for multiplication
	variable floatmult: unsigned (0 to 47); -- variable to hold mantiss amultiplication
	variable exponentemp: signed(0 to 8);
	
variable indataI10: std_logic_vector(0 to 9) := indataI(6 to 15);
variable indataI7: std_logic_vector(0 to 6) :=  indataI(9 to 15);
variable indataI16: std_logic_vector(0 to 15) := indataI(0 to 15);

	
    begin
        if  enable = '1' then --ensure enabled
            case opcode(0 to 10) is -- check opcode to figure out what code to execute


				
------------------NOP(Load) ------------------------------------------------------------------------

                when "00000000001" =>
				
				outdata <= x"00000000000000000000000000000000";
				depth <= "111";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
				halt <= '0';
				storevalue <= x"00000000000000000000000000000000";

--------------end NOP (Load)-------------------------------------------------------------------

------------------NOP(Execture) ------------------------------------------------------------------------

                when "01000000001" =>
				
				outdata <= x"00000000000000000000000000000000";
				depth <= "111";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
				halt <= '0';
				storevalue <= x"00000000000000000000000000000000";


--------------end NOP (Load)-------------------------------------------------------------------				



----------------Branch Absolute----------------------------------------------------------------------

                 when "00110000000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 pcnext <= (std_logic_vector(resize(signed(indataI16 & "00"), immediate32'length))) and LSLR; -- resize to 32 bits
				 branchflag <= '1'; -- set branch
				 unit <= "111";
				 depth <= "011";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				 outdata <= x"00000000000000000000000000000000"; --deosnt really matter
				 timestampout <= timestamp;
				 	halt <= '0';
					storevalue <= x"00000000000000000000000000000000";

				 
			
--------------end Branch Absolute-------------------------------------------------------------------

----------------Branch Relative----------------------------------------------------------------------

                 when "00110010000" =>
				 
				 
				 indataI16 := indataI(0 to 15);
				 
				 pcnext <= std_logic_vector(signed(pccurrent) + signed(resize(signed(indataI16 & "00"), immediate32'length))) and LSLR; -- resize to 32 bits
				 branchflag <= '1'; -- set branch
				 unit <= "111";
				 depth <= "011";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				outdata <= x"00000000000000000000000000000000"; --deosnt really matter
				timestampout <= timestamp;
				 	halt <= '0';		
					storevalue <= x"00000000000000000000000000000000";

--------------end Branch Relative-------------------------------------------------------------------

----------------Branch Indirect----------------------------------------------------------------------

                 when "00110101000" =>
				 
				 pcnext <= indataA(0 to 31) and LSLR and x"FFFFFFFC"; -- resize to 32 bits
				 branchflag <= '1'; -- set branch
				 unit <= "111";
				 depth <= "011";
				 readmem <= '0';
				writemem <= '0';
				writereg <= '0';		
				 outdata <= x"00000000000000000000000000000000"; --deosnt really matter
				 timestampout <= timestamp;
				halt <= '0';	 
				storevalue <= x"00000000000000000000000000000000";
				
--------------end Branch Indirect-------------------------------------------------------------------

----------------Branch If Not Zero Word----------------------------------------------------------------------

                 when "00100001000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 if not(indataA(0 to 31) = x"00000000") then 
					pcnext <= std_logic_vector(signed(pccurrent) + signed(resize(signed(indataI16 & "00"), immediate32'length))) and (LSLR and x"FFFFFFFC"); -- resize to 32 bits
					branchflag <= '1';-- set branch
					unit <= "111";
					depth <= "011";
					readmem <= '0';
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
					halt <= '0'; 
					storevalue <= x"00000000000000000000000000000000";

				 else
					depth <= "111";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "011";
					readmem <= '0';
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
					halt <= '0'; 
					storevalue <= x"00000000000000000000000000000000";

				 end if;
				 		
--------------end Branch if Not Zero Word-------------------------------------------------------------------

----------------Branch If Zero Word----------------------------------------------------------------------

                 when "00100000000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 if indataA(0 to 31) = x"00000000" then 
					pcnext <= std_logic_vector(signed(pccurrent) + signed(resize(signed(indataI16 & "00"), immediate32'length))) and (LSLR and x"FFFFFFFC"); -- resize to 32 bits
					branchflag <= '1';-- set branch
					unit <= "111";
					depth <= "011";
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
					halt <= '0'; 
					storevalue <= x"00000000000000000000000000000000";

				 else
					depth <= "111";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "011";
					readmem <= '0';
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
				 	halt <= '0';
					storevalue <= x"00000000000000000000000000000000";

				 end if;
				 		
--------------end Branch if Zero Word-------------------------------------------------------------------

----------------Branch If Not Zero HalfWord----------------------------------------------------------------------

                 when "00100011000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 if not(indataA(16 to 31) = x"0000") then 
					pcnext <= std_logic_vector(signed(pccurrent) + signed(resize(signed(indataI16 & "00"), immediate32'length))) and (LSLR and x"FFFFFFFC"); -- resize to 32 bits
					branchflag <= '1';-- set branch
					unit <= "111";
					depth <= "011";
					readmem <= '0';
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
					halt <= '0'; 
					storevalue <= x"00000000000000000000000000000000";

				 else
					depth <= "111";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "011";
					readmem <= '0';
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
					halt <= '0'; 
					storevalue <= x"00000000000000000000000000000000";

				 end if;
				 		
--------------end Branch if Not Zero HalfWord-------------------------------------------------------------------

----------------Branch If Zero HalfWord----------------------------------------------------------------------

                 when "00100010000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 if indataA(16 to 31) = x"0000" then 
					pcnext <= std_logic_vector(signed(pccurrent) + signed(resize(signed(indataI16 & "00"), immediate32'length))) and (LSLR and x"FFFFFFFC"); -- resize to 32 bits
					branchflag <= '1';-- set branch
					unit <= "111";
					depth <= "011";
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
					halt <= '0'; 
					storevalue <= x"00000000000000000000000000000000";

				 else
					depth <= "111";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "011";
					readmem <= '0';
					writemem <= '0';
					writereg <= '0';
					timestampout <= timestamp;
					outdata <= x"00000000000000000000000000000000"; --deosnt really matter
				 	halt <= '0';
					storevalue <= x"00000000000000000000000000000000";

				 end if;
				 		
--------------end Branch if Zero Half Word-------------------------------------------------------------------


----------------Branch Relative and Set Link----------------------------------------------------------------------

                 when "00110011000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 pcnext <= std_logic_vector(signed(pccurrent) + signed(resize(signed(indataI16 & "00"), immediate32'length))) and LSLR; -- resize to 32 bits
				 branchflag <= '1'; -- set branch
				 unit <= "111";
				 depth <= "011";
				 readmem <= '0';
				 writemem <= '0';
				 writereg <= '0';
				timestampout <= timestamp;
				outdata <= (std_logic_vector((signed(pccurrent) + 4 )) and LSLR) & x"000000000000000000000000"; --link address
				halt <= '0'; 	
				storevalue <= x"00000000000000000000000000000000";
					
--------------end Branch Relative and Set Link-------------------------------------------------------------------

----------------Branch Absolute and Set Link----------------------------------------------------------------------

                 when "00110001000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 pcnext <= (std_logic_vector(resize(signed(indataI16 & "00"), immediate32'length))) and LSLR; -- resize to 32 bits
				 branchflag <= '1'; -- set branch
				 unit <= "111";
				 depth <= "011";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				 outdata <= (std_logic_vector((signed(pccurrent) + 4 )) and LSLR) & x"000000000000000000000000"; --link address
				 timestampout <= timestamp;
					halt <= '0'; 
				storevalue <= x"00000000000000000000000000000000";

--------------end Branch Absolute and set link-------------------------------------------------------------------

----------------Load Quadword (d-form)----------------------------------------------------------------------

                 when "00110100000" =>
				 
				 indataI10 := indataI(6 to 15);
				 
				 outdata <= (std_logic_vector((signed(indataA(0 to 31)) + resize(signed(indataI10 & "0000"), immediate32'length))) and x"FFFFFFF0" and LSLR) & x"000000000000000000000000"; -- preffered slot of outdata is address
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "110";
				 readmem <= '1';
				 writemem <= '0';
				 writereg <= '1';
				timestampout <= timestamp;
				 pcnext <= pccurrent;
					halt <= '0'; 	
				storevalue <= x"00000000000000000000000000000000";
					
--------------end Load Quadword (d-form)-------------------------------------------------------------------

----------------Load Quadword (x-form)----------------------------------------------------------------------

                 when "00111000100" =>
				 
				 outdata <= (std_logic_vector(signed(indataA(0 to 31)) + signed(indataB(0 to 31))) and x"FFFFFFF0" and LSLR) & x"000000000000000000000000";
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "110";
				 readmem <= '1';
				 writemem <= '0';
				 writereg <= '1';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 halt <= '0'; 	
				 storevalue <= x"00000000000000000000000000000000";

--------------end Load Quadword (x-form)-------------------------------------------------------------------

----------------Load Quadword (a-form)----------------------------------------------------------------------

                 when "00110000100" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 outdata <= (std_logic_vector(resize(signed(indataI16 & "00"), immediate32'length)) and x"FFFFFFF0" and LSLR) & x"000000000000000000000000";
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "110";
				 readmem <= '1';
				 writemem <= '0';
				 writereg <= '1';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 halt <= '0';		
				storevalue <= x"00000000000000000000000000000000";
					
--------------end Load Quadword (a-form)-------------------------------------------------------------------

----------------Immediate Load Word----------------------------------------------------------------------

                 when "01000000100" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 outdata <= std_logic_vector(resize(signed(indataI16), immediate32'length)) & std_logic_vector(resize(signed(indataI16), immediate32'length)) & std_logic_vector(resize(signed(indataI16), immediate32'length)) & std_logic_vector(resize(signed(indataI16), immediate32'length));
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "010";
				 readmem <= '0';
				 writemem <= '0';
				 writereg <= '1';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 	halt <= '0';	
				storevalue <= x"00000000000000000000000000000000";
					
--------------end Immediate Load WOrd-------------------------------------------------------------------

----------------Immediate Load Half Word----------------------------------------------------------------------

                 when "01000001100" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 tempoutword0 := indataI16 & indataI16;
				 
				 outdata <=  tempoutword0 & tempoutword0 & tempoutword0 & tempoutword0;
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "011";
				 readmem <= '0';
				 writemem <= '0';
				 writereg <= '1';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 halt <= '0';		
				storevalue <= x"00000000000000000000000000000000";
					
--------------end Immediate Load Half Word-------------------------------------------------------------------

----------------Immediate Load Half Word Upper----------------------------------------------------------------------

                 when "01000001000" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 tempoutword0 :=  indataI16 & x"0000" ;
				 
				 outdata <=  tempoutword0 & tempoutword0 & tempoutword0 & tempoutword0;
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "011";
				 readmem <= '0';
				 writemem <= '0';
				 writereg <= '1';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 	halt <= '0';		
				storevalue <= x"00000000000000000000000000000000";
					
--------------end Immediate Load Half Word Upper-------------------------------------------------------------------

----------------Store Quadword(d-form)----------------------------------------------------------------------

                 when "00100100000" =>
				 
				 indataI10 := indataI(6 to 15);
				 
				 outdata <=  (std_logic_vector((signed(indataA(0 to 31)) + resize(signed(indataI10 & "0000"), immediate32'length))) and x"FFFFFFF0" and LSLR) & x"000000000000000000000000"; -- preffered slot of outdata is address	
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "110";
				 readmem <= '0';
				 writemem <= '1';
				 writereg <= '0';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 halt <= '0';			
				 storevalue <= indataC;

--------------end Store Quadword(d-form)-------------------------------------------------------------------

----------------Store Quadword (x-form)----------------------------------------------------------------------

                 when "00101000100" =>
				 
				 outdata <= (std_logic_vector(signed(indataA(0 to 31)) + signed(indataB(0 to 31))) and x"FFFFFFF0" and LSLR) & x"000000000000000000000000";
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "110";
				 readmem <= '0';
				 writemem <= '1';
				 writereg <= '0';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 	halt <= '0';	
				storevalue <= indataC;
--------------end Store Quadword (x-form)-------------------------------------------------------------------

----------------Store Quadword (a-form)----------------------------------------------------------------------

                 when "00100000100" =>
				 
				 indataI16 := indataI(0 to 15);
				 
				 outdata <= (std_logic_vector(resize(signed(indataI16 & "00"), immediate32'length)) and x"FFFFFFF0" and LSLR) & x"000000000000000000000000";
				 branchflag <= '0'; 
				 unit <= "110";
				 depth <= "110";
				 readmem <= '0';
				 writemem <= '1';
				 writereg <= '0';
				 pcnext <= pccurrent;
				 timestampout <= timestamp;
				 halt <= '0';			
				 storevalue <= indataC;
--------------end Store Quadword (a-form)-------------------------------------------------------------------

------------------Rotate quadwOrd by bytes-------------------------------------------------------------------------

                when "00111011100" =>
				
					
					outdata <= std_logic_vector(unsigned(indataA) rol (to_integer(unsigned(indataB(28 to 31))) * 8));
			
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "101";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
					halt <= '0';
				storevalue <= x"00000000000000000000000000000000";


--------------end Rotate quadword by bytes-------------------------------------------------------------------

------------------Rotate quadwOrd by bytes Immediate-------------------------------------------------------------------------

                when "00111111100" =>
				
				indataI7 := indataI(9 to 15);
					
					outdata <= std_logic_vector(unsigned(indataA) rol (to_integer(unsigned(indatai7(3 to 6))) * 8));
			
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "101";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
				halt <= '0';
				storevalue <= x"00000000000000000000000000000000";


--------------end Rotate quadword by bytes Immediate-------------------------------------------------------------------

------------------Rotate quadwOrd by bit shift count-------------------------------------------------------------------------

                when "00111001100" =>
				
					
					outdata <= std_logic_vector(unsigned(indataA) rol (to_integer(unsigned(indataB(25 to 28))) * 8));
			
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "101";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
					halt <= '0';
					storevalue <= x"00000000000000000000000000000000";

--------------end Rotate quadword by bit shift count-------------------------------------------------------------------

------------------Rotate quadwOrd by bits-------------------------------------------------------------------------

                when "00111011000" =>
				
					
					outdata <= std_logic_vector(unsigned(indataA) rol to_integer(unsigned(indataB(29 to 31))));
			
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "101";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
					halt <= '0';
					storevalue <= x"00000000000000000000000000000000";

--------------end Rotate quadword by bits-------------------------------------------------------------------

------------------Rotate quadwOrd by bits immediate-------------------------------------------------------------------------

                when "00111111000" =>
				
					indataI7 := indataI(9 to 15);
					
					outdata <= std_logic_vector(unsigned(indataA) rol to_integer(unsigned(indatai7(4 to 6))));
			
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "101";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
					halt <= '0';
					storevalue <= x"00000000000000000000000000000000";

--------------end Rotate quadword by bits immediate-------------------------------------------------------------------

----------------Halt if Equal----------------------------------------------------------------------

                 when "01111011000" =>
				 
				 if indataA(0 to 31) = indataB(0 to 31) then
					halt <= '1';
				 
				 else
					halt <= '0';
				 end if;
				 
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "111";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
				storevalue <= x"00000000000000000000000000000000";

				 		
--------------end Halt if Equal-------------------------------------------------------------------

----------------Halt if Equal Immediate----------------------------------------------------------------------

                 when "01111111000" =>
				 
				 indataI10 := indataI(6 to 15);
				 
				 if indataA(0 to 31) = std_logic_vector(resize(signed(indataI10), immediate32'length)) then
					halt <= '1';
				 
				 else
					halt <= '0';
				 end if;
				 
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "111";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
				storevalue <= x"00000000000000000000000000000000";

				 		
--------------end Halt if Equal Immediate-------------------------------------------------------------------

----------------Halt if Greater Than----------------------------------------------------------------------

                 when "01001011000" =>
				 
				 if indataA(0 to 31) > indataB(0 to 31) then
					halt <= '1';
				 
				 else
					halt <= '0';
				 end if;
				 
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "111";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
				storevalue <= x"00000000000000000000000000000000";

				 		
--------------end Halt if Greater Than-------------------------------------------------------------------

----------------Halt if Greater Than Immediate----------------------------------------------------------------------

                 when "01001111000" =>
				 
				 indataI10 := indataI(6 to 15);
				 
				 if indataA(0 to 31) > std_logic_vector(resize(signed(indataI10), immediate32'length)) then
					halt <= '1';
				 
				 else
					halt <= '0';
				 end if;
				 
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "111";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
				storevalue <= x"00000000000000000000000000000000";

				 		
--------------end Halt if Greater Than Immediate-------------------------------------------------------------------
                when others=>
                null;

            end case;
        end if;
    end process;
    
end behavioral;
