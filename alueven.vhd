--ALU even Execution Unit
--David Gash
--Executes SPU instructions


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity ALUeven is
port(
     -- clk: in std_logic; --clock input
    enable: in std_logic; --block enable
    opcode: in std_logic_vector (0 to 10); -- op code input
    indataA: in std_logic_vector (0 to 127); -- input register 1
    indataB: in std_logic_vector (0 to 127); -- input register 2
	indataC: in std_logic_vector(0 to 127);
	indataI: in std_logic_vector(0 to 15); --input for I16 Immediate Values
	pccurrent: in std_logic_vector(0 to 31);
	timestamp: in std_logic_vector(0 to 3);-- time stamp to decide which command odd or even is first
	timestampout: out std_logic_vector( 0 to 3);
	branchflag: out std_logic; --bit that signals a branch output
	pcnext: out std_logic_vector(0 to 31);  -- output for branch instructions IS THIS needd??
    outdata: out std_logic_vector (0 to 127); --single register output
	depth: out std_logic_vector(0 to 2);
	unit: out std_logic_vector(0 to 2);
	readmem: out std_logic;
	writemem: out std_logic;
	writereg: out std_logic
    );
end ALUeven;

architecture behavioral of ALUeven is

signal immediate32: std_logic_vector(0 to 31);
signal immediate16: std_logic_vector(0 to 15);	 
signal immediate25: std_logic_vector(0 to 24); 
signal immediate9: std_logic_vector(0 to 8);   


signal fpscr: std_logic_vector(0 to 127) := x"00000000000000000000000000000000"; 
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

------------------Add Word Immediate--------------------------------------------------------------------------
                when "00011100000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempoutword0 := std_logic_vector(signed(indataA(0 to 31)) + resize(signed(indataI10(0 to 9)), immediate32'length)); --Sign extend immediate value and preform addition
				tempoutword1 := std_logic_vector(signed(indataA(32 to 63)) + resize(signed(indataI10(0 to 9)), immediate32'length)); --do addtition word 2
				tempoutword2 := std_logic_vector(signed(indataA(64 to 95)) + resize(signed(indataI10(0 to 9)), immediate32'length)); --do addtition word 3
				tempoutword3 := std_logic_vector(signed(indataA(96 to 127)) + resize(signed(indataI10(0 to 9)), immediate32'length)); --do addtition word 4
				
               
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Add Word Immediate---------------------------------------------------------------------

------------------Add Word-------------------------------------------------------------------------

                when "00011000000" =>
              
				tempoutword0 := std_logic_vector(signed(indataA(0 to 31)) + signed(indataB(0 to 31))); --do addtition word 1
				tempoutword1 := std_logic_vector(signed(indataA(32 to 63)) + signed(indataB(32 to 63))); --do addtition word 2
				tempoutword2 := std_logic_vector(signed(indataA(64 to 95)) + signed(indataB(64 to 95))); --do addtition word 3
				tempoutword3 := std_logic_vector(signed(indataA(96 to 127)) + signed(indataB(96 to 127))); --do addtition word 4
				
               
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Add Word---------------------------------------------------------------------

------------------Add Half Word-------------------------------------------------------------------------

                when "00011001000" =>
              
				tempouthf0 := std_logic_vector(signed(indataA(0 to 15)) + signed(indataB(0 to 15))); --do addtition halfword 1
				tempouthf1 := std_logic_vector(signed(indataA(16 to 31)) + signed(indataB(16 to 31))); --do addtition halfword 2
				tempouthf2 := std_logic_vector(signed(indataA(32 to 47)) + signed(indataB(32 to 47))); --do addtition halfword 2
				tempouthf3 := std_logic_vector(signed(indataA(48 to 63)) + signed(indataB(48 to 63))); --do addtition halfword 3
				tempouthf4 := std_logic_vector(signed(indataA(64 to 79)) + signed(indataB(64 to 79))); --do addtition halfword 4
				tempouthf5 := std_logic_vector(signed(indataA(80 to 95)) + signed(indataB(80 to 95))); --do addtition halfword 5
				tempouthf6 := std_logic_vector(signed(indataA(96 to 111)) + signed(indataB(96 to 111))); --do addtition halfword 6
				tempouthf7 := std_logic_vector(signed(indataA(112 to 127)) + signed(indataB(112 to 127))); --do addtition halfword 7
		
               
				outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Add Half Word---------------------------------------------------------------------

------------------Add Half Word Immediate-------------------------------------------------------------------------

                when "00011101000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempouthf0 := std_logic_vector(signed(indataA(0 to 15)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 1
				tempouthf1 := std_logic_vector(signed(indataA(16 to 31)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 2
				tempouthf2 := std_logic_vector(signed(indataA(32 to 47)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 2
				tempouthf3 := std_logic_vector(signed(indataA(48 to 63)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 3
				tempouthf4 := std_logic_vector(signed(indataA(64 to 79)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 4
				tempouthf5 := std_logic_vector(signed(indataA(80 to 95)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 5
				tempouthf6 := std_logic_vector(signed(indataA(96 to 111)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 6
				tempouthf7 := std_logic_vector(signed(indataA(112 to 127)) + resize(signed(indataI10(0 to 9)), immediate16'length)); --do addtition halfword 7
			
				
				outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Add Half Word Immediate---------------------------------------------------------------------

------------------Subtract From Word-------------------------------------------------------------------------

                when "00001000000" =>
              
				tempoutword0 := std_logic_vector(signed(indataB(0 to 31)) - signed(indataA(0 to 31))); --do subtraction word 1
				tempoutword1 := std_logic_vector(signed(indataB(32 to 63)) - signed(indataA(32 to 63))); --do subtraction word 2
				tempoutword2 := std_logic_vector(signed(indataB(64 to 95)) - signed(indataA(64 to 95))); --do subtraction word 3
				tempoutword3 := std_logic_vector(signed(indataB(96 to 127)) - signed(indataA(96 to 127))); --do subtraction word 4
				
				
               
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Subtract From Word---------------------------------------------------------------------

------------------Subtract From Word  Immediate-------------------------------------------------------------------------

                when "00001100000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempoutword0 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate32'length)) - signed(indataA(0 to 31))); --do subtraction word 1
				tempoutword1 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate32'length)) - signed(indataA(32 to 63))); --do subtraction word 2
				tempoutword2 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate32'length)) - signed(indataA(64 to 95))); --do subtraction word 3
				tempoutword3 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate32'length)) - signed(indataA(96 to 127))); --do subtraction word 4
				
				
               
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Subtract From Word Immediate---------------------------------------------------------------------

------------------Subtract From Half Word-------------------------------------------------------------------------

                when "00001001000" =>
              
				tempouthf0 := std_logic_vector(signed(indataB(0 to 15)) - signed(indataA(0 to 15))); --do Subtraction
				tempouthf1 := std_logic_vector(signed(indataB(16 to 31)) - signed(indataA(16 to 31))); 
				tempouthf2 := std_logic_vector(signed(indataB(32 to 47)) - signed(indataA(32 to 47)));
				tempouthf3 := std_logic_vector(signed(indataB(48 to 63)) - signed(indataA(48 to 63))); 
				tempouthf4 := std_logic_vector(signed(indataB(64 to 79)) - signed(indataA(64 to 79))); 
				tempouthf5 := std_logic_vector(signed(indataB(80 to 95)) - signed(indataA(80 to 95))); 
				tempouthf6 := std_logic_vector(signed(indataB(96 to 111)) - signed(indataA(96 to 111))); 
				tempouthf7 := std_logic_vector(signed(indataB(112 to 127)) - signed(indataA(112 to 127))); 
				
				
				outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Subtract From Half Word---------------------------------------------------------------------

------------------Subtract From Half Word Immediate-------------------------------------------------------------------------

                when "00001101000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempouthf0 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(0 to 15))); --do Subtraction
				tempouthf1 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(16 to 31))); 
				tempouthf2 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(32 to 47)));
				tempouthf3 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(48 to 63))); 
				tempouthf4 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(64 to 79))); 
				tempouthf5 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(80 to 95))); 
				tempouthf6 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(96 to 111))); 
				tempouthf7 := std_logic_vector((resize(signed(indataI10(0 to 9)), immediate16'length)) - signed(indataA(112 to 127))); 
				               
				outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Subtract From Half Word Immediate---------------------------------------------------------------------

------------------Multiply-------------------------------------------------------------------------

                when "01111000100" =>
              
				tempoutword0 := std_logic_vector(signed(indataA(16 to 31)) * signed(indataB(16 to 31))); --do multiplication
				tempoutword1 := std_logic_vector(signed(indataA(48 to 63)) * signed(indataB(48 to 63))); 
				tempoutword2 := std_logic_vector(signed(indataA(80 to 95)) * signed(indataB(80 to 95))); 
				tempoutword3 := std_logic_vector(signed(indataA(112 to 127)) * signed(indataB(112 to 127)));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "010";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Multiply--------------------------------------------------------------------

------------------Multiply High-------------------------------------------------------------------------

                when "01111000101" =>
              
				tempoutword0 := std_logic_vector(signed(indataA(0 to 15)) * signed(indataB(16 to 31))); --do multiplication
				tempoutword1 := std_logic_vector(signed(indataA(32 to 47)) * signed(indataB(48 to 63))); 
				tempoutword2 := std_logic_vector(signed(indataA(64 to 79)) * signed(indataB(80 to 95))); 
				tempoutword3 := std_logic_vector(signed(indataA(96 to 111)) * signed(indataB(112 to 127)));
		
				outdata <= (tempoutword0(16 to 31) & x"0000") & (tempoutword1(16 to 31) & x"0000") & (tempoutword2(16 to 31) & x"0000") & (tempoutword3(16 to 31) & x"0000");  --add all three togehter to get output
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "010";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Multiply High--------------------------------------------------------------------

------------------Multiply and Add-------------------------------------------------------------------------

                when "11000000000" =>
              
				tempoutword0 := std_logic_vector(signed(indataA(16 to 31)) * signed(indataB(16 to 31))); --do multiplication
				tempoutword1 := std_logic_vector(signed(indataA(48 to 63)) * signed(indataB(48 to 63))); 
				tempoutword2 := std_logic_vector(signed(indataA(80 to 95)) * signed(indataB(80 to 95))); 
				tempoutword3 := std_logic_vector(signed(indataA(112 to 127)) * signed(indataB(112 to 127)));
		
				tempoutword0 := std_logic_vector(signed(indataC(0 to 31)) + signed(tempoutword0(0 to 31))); --do addtition word 1
				tempoutword1 := std_logic_vector(signed(indataC(32 to 63)) + signed(tempoutword1(0 to 31))); --do addtition word 2
				tempoutword2 := std_logic_vector(signed(indataC(64 to 95)) + signed(tempoutword2(0 to 31))); --do addtition word 3
				tempoutword3 := std_logic_vector(signed(indataC(96 to 127)) + signed(tempoutword3(0 to 31))); --do addtition word 4
				
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "111";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "011";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Multiply and add--------------------------------------------------------------------


------------------Multiply Immediate-------------------------------------------------------------------------

                when "01110100000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempoutword0 := std_logic_vector(signed(indataA(16 to 31)) * (resize(signed(indataI10(0 to 9)), immediate16'length))); --do multiplication
				tempoutword1 := std_logic_vector(signed(indataA(48 to 63)) * (resize(signed(indataI10(0 to 9)), immediate16'length))); 
				tempoutword2 := std_logic_vector(signed(indataA(80 to 95)) * (resize(signed(indataI10(0 to 9)), immediate16'length))); 
				tempoutword3 := std_logic_vector(signed(indataA(112 to 127)) * (resize(signed(indataI10(0 to 9)), immediate16'length)));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "010";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Multiply Immediate--------------------------------------------------------------------



------------------Multiply Unsigned-------------------------------------------------------------------------

                when "01111001100" =>
              
				tempoutword0 := std_logic_vector(unsigned(indataA(16 to 31)) * unsigned(indataB(16 to 31))); --do multiplication
				tempoutword1 := std_logic_vector(unsigned(indataA(48 to 63)) * unsigned(indataB(48 to 63))); 
				tempoutword2 := std_logic_vector(unsigned(indataA(80 to 95)) * unsigned(indataB(80 to 95))); 
				tempoutword3 := std_logic_vector(unsigned(indataA(112 to 127)) * unsigned(indataB(112 to 127)));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "010";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Multiply Unsigned--------------------------------------------------------------------

------------------And-------------------------------------------------------------------------

                when "00011000001" =>
              
				tempoutword0 := indataA(0 to 31) and indataB(0 to 31); --do and operation
				tempoutword1 := indataA(32 to 63) and indataB(32 to 63);
				tempoutword2 := indataA(64 to 95) and indataB(64 to 95);
				tempoutword3 := indataA(96 to 127) and indataB(96 to 127);
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end And--------------------------------------------------------------------

------------------And Word Immediate-------------------------------------------------------------------------

                when "00010100000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempoutword0 := indataA(0 to 31) and std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length)); --do and operation
				tempoutword1 := indataA(32 to 63) and std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
				tempoutword2 := indataA(64 to 95) and std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
				tempoutword3 := indataA(96 to 127) and std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end And Word Immediate--------------------------------------------------------------------

------------------Or-------------------------------------------------------------------------

                when "00001000001" =>
              
				tempoutword0 := indataA(0 to 31) or indataB(0 to 31); --do operation
				tempoutword1 := indataA(32 to 63) or indataB(32 to 63);
				tempoutword2 := indataA(64 to 95) or indataB(64 to 95);
				tempoutword3 := indataA(96 to 127) or indataB(96 to 127);
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Or--------------------------------------------------------------------

------------------Or with Complement-------------------------------------------------------------------------

                when "01011001001" =>
              
				tempoutword0 := indataA(0 to 31) or not(indataB(0 to 31)); --do operation
				tempoutword1 := indataA(32 to 63) or not(indataB(32 to 63));
				tempoutword2 := indataA(64 to 95) or not(indataB(64 to 95));
				tempoutword3 := indataA(96 to 127) or not(indataB(96 to 127));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Or with Complement--------------------------------------------------------------------

------------------Or Across-------------------------------------------------------------------------

                when "00111110000" =>
              
				
		
				outdata <= (indataA(0 to 31) or indataA(32 to 63) or indataA(64 to 95) or indataA(96 to 127)) & x"00000000"& x"00000000"& x"00000000";
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Or Across--------------------------------------------------------------------


------------------ Or word Immediate-------------------------------------------------------------------------

                when "00000100000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempoutword0 := indataA(0 to 31) or std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length)); --do operation
				tempoutword1 := indataA(32 to 63) or std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
				tempoutword2 := indataA(64 to 95) or std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
				tempoutword3 := indataA(96 to 127) or std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
-------------- Or word Immediate--------------------------------------------------------------------

------------------Xor-------------------------------------------------------------------------

                when "01001000001" =>
              
				tempoutword0 := indataA(0 to 31) xor indataB(0 to 31); --do operation
				tempoutword1 := indataA(32 to 63) xor indataB(32 to 63);
				tempoutword2 := indataA(64 to 95) xor indataB(64 to 95);
				tempoutword3 := indataA(96 to 127) xor indataB(96 to 127);
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Xor--------------------------------------------------------------------

------------------Xor Immediate-------------------------------------------------------------------------

                when "01000100000" =>
				
				indataI10 := indataI(6 to 15);
              
				tempoutword0 := indataA(0 to 31) xor std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length)); --do operation
				tempoutword1 := indataA(32 to 63) xor std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
				tempoutword2 := indataA(64 to 95) xor std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
				tempoutword3 := indataA(96 to 127) xor std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length));
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end Xor Immediate--------------------------------------------------------------------

------------------Nand-------------------------------------------------------------------------

                when "00011001001" =>
              
				tempoutword0 := indataA(0 to 31) nand indataB(0 to 31); --do nand operation
				tempoutword1 := indataA(32 to 63) nand indataB(32 to 63);
				tempoutword2 := indataA(64 to 95) nand indataB(64 to 95);
				tempoutword3 := indataA(96 to 127) nand indataB(96 to 127);
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end nand--------------------------------------------------------------------

------------------Nor-------------------------------------------------------------------------

                when "00001001001" =>
              
				tempoutword0 := indataA(0 to 31) nor indataB(0 to 31); --do nor operation
				tempoutword1 := indataA(32 to 63) nor indataB(32 to 63);
				tempoutword2 := indataA(64 to 95) nor indataB(64 to 95);
				tempoutword3 := indataA(96 to 127) nor indataB(96 to 127);
		
				outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;  --add all three togehter to get output
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
--------------end nor--------------------------------------------------------------------

------------------Equivalent-------------------------------------------------------------------------

                when "01001001001" =>
              
				for I in 0 to 127 loop
					if indataA(I) = indataB(I) then
						outdata(I) <= '1';
					else
						outdata(I) <= '0';
					end if;
				end loop;
				
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;

--------------end Equivalent--------------------------------------------------------------------

------------------Rotate WOrd-------------------------------------------------------------------------

                when "00001011000" =>
				
				
					tempoutword0 := std_logic_vector(unsigned(indataA(0 to 31)) rol to_integer(unsigned(indataB(27 to 31))));
					tempoutword1 := std_logic_vector(unsigned(indataA(32 to 63)) rol to_integer(unsigned(indataB(59 to 63))));
					tempoutword2 := std_logic_vector(unsigned(indataA(64 to 95)) rol to_integer(unsigned(indataB(91 to 95))));
					tempoutword3 := std_logic_vector(unsigned(indataA(96 to 127)) rol to_integer(unsigned(indataB(123 to 127))));
					
					outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "001";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
			

--------------end Rotate Word--------------------------------------------------------------------

------------------Rotate Half WOrd-------------------------------------------------------------------------

                when "00001011100" =>
				
				
					tempouthf0 := std_logic_vector(unsigned(indataA(0 to 15)) rol to_integer(unsigned(indataB(12 to 15))));
					tempouthf1 := std_logic_vector(unsigned(indataA(16 to 31)) rol to_integer(unsigned(indataB(28 to 31))));
					tempouthf2 := std_logic_vector(unsigned(indataA(32 to 47)) rol to_integer(unsigned(indataB(44 to 47))));
					tempouthf3 := std_logic_vector(unsigned(indataA(48 to 63)) rol to_integer(unsigned(indataB(60 to 63))));
					tempouthf4 := std_logic_vector(unsigned(indataA(64 to 79)) rol to_integer(unsigned(indataB(76 to 79))));
					tempouthf5 := std_logic_vector(unsigned(indataA(80 to 95)) rol to_integer(unsigned(indataB(92 to 95))));
					tempouthf6 := std_logic_vector(unsigned(indataA(96 to 111)) rol to_integer(unsigned(indataB(108 to 111))));
					tempouthf7 := std_logic_vector(unsigned(indataA(112 to 127)) rol to_integer(unsigned(indataB(124 to 127))));
					
					outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "001";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
			
			

--------------end Rotate Half Word--------------------------------------------------------------------

------------------SHift Left WOrd-------------------------------------------------------------------------

                when "00001011011" =>
				
				
					tempoutword0 := std_logic_vector(unsigned(indataA(0 to 31)) sll to_integer(unsigned(indataB(26 to 31))));
					tempoutword1 := std_logic_vector(unsigned(indataA(32 to 63)) sll to_integer(unsigned(indataB(58 to 63))));
					tempoutword2 := std_logic_vector(unsigned(indataA(64 to 95)) sll to_integer(unsigned(indataB(90 to 95))));
					tempoutword3 := std_logic_vector(unsigned(indataA(96 to 127)) sll to_integer(unsigned(indataB(122 to 127))));
					
					outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "001";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
			

--------------end Shift Left Word--------------------------------------------------------------------

------------------SHift Left WOrd Immediate-------------------------------------------------------------------------

                when "00001111011" =>
				
				
					tempoutword0 := std_logic_vector(unsigned(indataA(0 to 31)) sll to_integer(unsigned(indataI(10 to 15))));
					tempoutword1 := std_logic_vector(unsigned(indataA(32 to 63)) sll to_integer(unsigned(indataI(10 to 15))));
					tempoutword2 := std_logic_vector(unsigned(indataA(64 to 95)) sll to_integer(unsigned(indataI(10 to 15))));
					tempoutword3 := std_logic_vector(unsigned(indataA(96 to 127)) sll to_integer(unsigned(indataI(10 to 15))));
					
					outdata <= tempoutword0 & tempoutword1 & tempoutword2 & tempoutword3;
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "001";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
			

--------------end Shift Left Word Immediate-------------------------------------------------------------------

------------------Shift Left Half WOrd-------------------------------------------------------------------------

                when "00001011111" =>
				
				
					tempouthf0 := std_logic_vector(unsigned(indataA(0 to 15)) sll to_integer(unsigned(indataB(11 to 15))));
					tempouthf1 := std_logic_vector(unsigned(indataA(16 to 31)) sll to_integer(unsigned(indataB(27 to 31))));
					tempouthf2 := std_logic_vector(unsigned(indataA(32 to 47)) sll to_integer(unsigned(indataB(43 to 47))));
					tempouthf3 := std_logic_vector(unsigned(indataA(48 to 63)) sll to_integer(unsigned(indataB(59 to 63))));
					tempouthf4 := std_logic_vector(unsigned(indataA(64 to 79)) sll to_integer(unsigned(indataB(75 to 79))));
					tempouthf5 := std_logic_vector(unsigned(indataA(80 to 95)) sll to_integer(unsigned(indataB(91 to 95))));
					tempouthf6 := std_logic_vector(unsigned(indataA(96 to 111)) sll to_integer(unsigned(indataB(107 to 111))));
					tempouthf7 := std_logic_vector(unsigned(indataA(112 to 127)) sll to_integer(unsigned(indataB(123 to 127))));
					
					outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "001";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
			

--------------end Shift Left Half Word--------------------------------------------------------------------

------------------Shift Left Half WOrd Immediate-------------------------------------------------------------------------

                when "00001111111" =>
				
				
					tempouthf0 := std_logic_vector(unsigned(indataA(0 to 15)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf1 := std_logic_vector(unsigned(indataA(16 to 31)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf2 := std_logic_vector(unsigned(indataA(32 to 47)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf3 := std_logic_vector(unsigned(indataA(48 to 63)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf4 := std_logic_vector(unsigned(indataA(64 to 79)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf5 := std_logic_vector(unsigned(indataA(80 to 95)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf6 := std_logic_vector(unsigned(indataA(96 to 111)) sll to_integer(unsigned(indataI(11 to 15))));
					tempouthf7 := std_logic_vector(unsigned(indataA(112 to 127)) sll to_integer(unsigned(indataI(11 to 15))));
					
					outdata <= tempouthf0 & tempouthf1 & tempouthf2 & tempouthf3 & tempouthf4 & tempouthf5 & tempouthf6 & tempouthf7;
					depth <= "011";
					pcnext <= pccurrent;
					branchflag <= '0';
					unit <= "001";
					readmem <= '0';
					writemem <= '0';
					writereg <= '1';
					timestampout <= timestamp;
			

--------------end Shift Left Half Word Immediate--------------------------------------------------------------------

------------------Compare Equal Byte------------------------------------------------------------------------

                when "01111010000" =>
				
				for I in 1 to 16 loop
					if indataA(((8*I)-8) to ((8*I)-1)) = indataB(((8*I)-8) to ((8*I)-1)) then
						outdata(((8*I)-8) to ((8*I)-1)) <= "11111111";
						else
						outdata(((8*I)-8) to ((8*I)-1))<= "00000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Compare Equal Byte-------------------------------------------------------------------

------------------And Byte Immediate------------------------------------------------------------------------

                when "00010110000" =>
				
				
				
				for I in 1 to 16 loop
					outdata(((8*I)-8) to ((8*I)-1)) <= indataA(((8*I)-8) to ((8*I)-1)) and indataI(8 to 15);
				
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end And Byte Immediate-------------------------------------------------------------------

------------------Or Byte Immediate------------------------------------------------------------------------

                when "00000110000" =>
				
				
				
				for I in 1 to 16 loop
					outdata(((8*I)-8) to ((8*I)-1)) <= indataA(((8*I)-8) to ((8*I)-1)) or indataI(8 to 15);
				
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Or Byte Immediate-------------------------------------------------------------------

------------------Xor Byte Immediate------------------------------------------------------------------------

                when "01000110000" =>
				
				
				
				for I in 1 to 16 loop
					outdata(((8*I)-8) to ((8*I)-1)) <= indataA(((8*I)-8) to ((8*I)-1)) xor indataI(8 to 15);
				
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Xor Byte Immediate-------------------------------------------------------------------

------------------And Halfword Immediate------------------------------------------------------------------------

                when "00010101000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 8 loop
					outdata(((16*I)-16) to ((16*I)-1)) <= indataA(((16*I)-16) to ((16*I)-1)) and std_logic_vector(resize(signed(indataI10(0 to 9)), immediate16'length));
				
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end And Halfword Immediate-------------------------------------------------------------------

------------------Or Halfword Immediate------------------------------------------------------------------------

                when "00000101000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 8 loop
					outdata(((16*I)-16) to ((16*I)-1)) <= indataA(((16*I)-16) to ((16*I)-1)) or std_logic_vector(resize(signed(indataI10(0 to 9)), immediate16'length));
				
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Or Halfword Immediate-------------------------------------------------------------------

------------------Xor Halfword Immediate------------------------------------------------------------------------

                when "01000101000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 8 loop
					outdata(((16*I)-16) to ((16*I)-1)) <= indataA(((16*I)-16) to ((16*I)-1)) xor std_logic_vector(resize(signed(indataI10(0 to 9)), immediate16'length));
				
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Xor Halfword Immediate-------------------------------------------------------------------
	
------------------Compare Equal Halfword------------------------------------------------------------------------

                when "01111001000" =>
				
				for I in 1 to 8 loop
					if indataA(((16*I)-16) to ((16*I)-1)) = indataB(((16*I)-16) to ((16*I)-1)) then
						outdata(((16*I)-16) to ((16*I)-1)) <= "1111111111111111";
						else
						outdata(((16*I)-16) to ((16*I)-1))<= "0000000000000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Compare Equal Halfword-------------------------------------------------------------------

------------------Compare Equal Word------------------------------------------------------------------------

                when "01111000000" =>
				
				for I in 1 to 4 loop
					if indataA(((32*I)-32) to ((32*I)-1)) = indataB(((32*I)-32) to ((32*I)-1)) then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
						else
						outdata(((32*I)-32) to ((32*I)-1))<= "00000000000000000000000000000000";
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			


--------------end Compare Equal Word-------------------------------------------------------------------

------------------Compare Equal Word Immediate------------------------------------------------------------------------

                when "01111100000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 4 loop
					if indataA(((32*I)-32) to ((32*I)-1)) = std_logic_vector(resize(signed(indataI10(0 to 9)), immediate32'length))then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
						else
						outdata(((32*I)-32) to ((32*I)-1))<= "00000000000000000000000000000000";
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Compare Equal Word Immediate-------------------------------------------------------------------

------------------Compare Equal Byte Immediate------------------------------------------------------------------------

                when "01111110000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 16 loop
					if indataA(((8*I)-8) to ((8*I)-1)) = indataI10(2 to 9)then
						outdata(((8*I)-8) to ((8*I)-1)) <= "11111111";
						else
						outdata(((8*I)-8) to ((8*I)-1))<= "00000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Compare Equal Byte Immediate-------------------------------------------------------------------

------------------Compare Equal Halfword Immediate------------------------------------------------------------------------

                when "01111101000" =>
				
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 8 loop
					if indataA(((16*I)-16) to ((16*I)-1)) = std_logic_vector(resize(signed(indataI10(0 to 9)), immediate16'length)) then
						outdata(((16*I)-16) to ((16*I)-1)) <= "1111111111111111";
						else
						outdata(((16*I)-16) to ((16*I)-1))<= "0000000000000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			


--------------end Compare Equal Halfword Immediate-------------------------------------------------------------------

------------------Compare Greater Than Word------------------------------------------------------------------------

                when "01001000000" =>
				
				for I in 1 to 4 loop
					if signed(indataA(((32*I)-32) to ((32*I)-1))) > signed(indataB(((32*I)-32) to ((32*I)-1))) then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
						else
						outdata(((32*I)-32) to ((32*I)-1))<= "00000000000000000000000000000000";
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			


--------------end Compare Greater Than Word-------------------------------------------------------------------

------------------Compare Greater Than Byte------------------------------------------------------------------------

                when "01001010000" =>
				
				for I in 1 to 16 loop
					if signed(indataA(((8*I)-8) to ((8*I)-1))) > signed(indataB(((8*I)-8) to ((8*I)-1))) then
						outdata(((8*I)-8) to ((8*I)-1)) <= "11111111";
						else
						outdata(((8*I)-8) to ((8*I)-1))<= "00000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			


--------------end Compare Greater Than Byte-------------------------------------------------------------------
	
------------------Compare Greater Than Halfword------------------------------------------------------------------------

                when "01001001000" =>
				
				for I in 1 to 8 loop
					if signed(indataA(((16*I)-16) to ((16*I)-1))) > signed(indataB(((16*I)-16) to ((16*I)-1))) then
						outdata(((16*I)-16) to ((16*I)-1)) <= "1111111111111111";
						else
						outdata(((16*I)-16) to ((16*I)-1))<= "0000000000000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Compare Greater Than Halfword-------------------------------------------------------------------

------------------Compare GReater Than Word Immediate------------------------------------------------------------------------

                when "01001100000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 4 loop
					if signed(indataA(((32*I)-32) to ((32*I)-1))) > signed(resize(signed(indataI10(0 to 9)), immediate32'length))then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
						else
						outdata(((32*I)-32) to ((32*I)-1))<= "00000000000000000000000000000000";
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			

--------------end Compare Greater Than Word Immediate-------------------------------------------------------------------

------------------Compare Greater Than Byte Immediate------------------------------------------------------------------------

                when "01001110000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 16 loop
					if signed(indataA(((8*I)-8) to ((8*I)-1))) > signed(indataI10(2 to 9))then
						outdata(((8*I)-8) to ((8*I)-1)) <= "11111111";
						else
						outdata(((8*I)-8) to ((8*I)-1))<= "00000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;

--------------end Compare Greater Than Byte Immediate-------------------------------------------------------------------

------------------Compare Greater Than Halfword Immediate------------------------------------------------------------------------

                when "01001101000" =>
				
				indataI10 := indataI(6 to 15);
				
				for I in 1 to 8 loop
					if signed(indataA(((16*I)-16) to ((16*I)-1))) > signed(resize(unsigned(indataI10(0 to 9)), immediate16'length)) then
						outdata(((16*I)-16) to ((16*I)-1)) <= "1111111111111111";
						else
						outdata(((16*I)-16) to ((16*I)-1))<= "0000000000000000" ;
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			


--------------end Compare Greater Than Halfword Immediate-------------------------------------------------------------------
				
------------------NOP(Load) ------------------------------------------------------------------------

                when "00000000001" =>
				
				outdata <= x"00000000000000000000000000000000";
				depth <= "000";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "111";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
			

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
			

--------------end NOP (Load)-------------------------------------------------------------------				

-----------------Count Ones in Bytes------------------------------------------------------------------------

                when "01010110100" =>
				
				for I in 1 to 16 loop	 
				byteprocess  := indataA(((8*I)-8) to ((8*I)-1));
					for J in 1 to 8 loop -- loop at each bit in a specific byte
						if byteprocess(J-1) = '1' then
						tempbytecount := tempbytecount + "00000001";
						end if;
					end loop;
					outdata(((8*I)-8) to ((8*I)-1)) <= std_logic_vector(tempbytecount);	  
					tempbytecount := "00000000";
				end loop;
				
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "100";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
				
--------------end Count Ones in Bytes-------------------------------------------------------------------

-----------------Count Leading Zeroes------------------------------------------------------------------------

                when "01010100101" =>
				
				for I in 1 to 4 loop	 
				tempoutword0  := indataA(((32*I)-32) to ((32*I)-1)); -- get word to work on
				tempoutword1 := x"00000000"; 
					looplook: for J in 1 to 32 loop -- loop at each bit in a specific byte
						if tempoutword0(J-1) = '0' then
						tempoutword1 := std_logic_vector(signed(tempoutword1) + "00000001");
						elsif tempoutword0(J-1) = '1' then
						exit looplook;--break look when first 1 is found
						end if;
					end loop;
					outdata(((32*I)-32) to ((32*I)-1)) <= tempoutword1;	  
					tempoutword1 := x"00000000"; -- reset count
				end loop;
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "100";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
				
--------------end Count Leading Zeroes-------------------------------------------------------------------

----------------Average Bytes------------------------------------------------------------------------

                when "00011010011" =>
				for I in 1 to 16 loop	 -- loop over bytes
				byteprocess := indataA(((8*I)-8) to ((8*I)-1)); -- Get bytes to process
				byteprocess1 := indataB(((8*I)-8) to ((8*I)-1));
				
				tempouthf0 := std_logic_vector(resize(signed(byteprocess), immediate16'length) + resize(signed(byteprocess1), immediate16'length) + x"0001"); --resize to prevent loss of prescsion.
				outdata(((8*I)-8) to ((8*I)-1))	<= tempouthf0(7 to 14);
				end loop;
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "100";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
		
				
--------------end Average Bytes-------------------------------------------------------------------

----------------Absolute Differences of Bytes------------------------------------------------------------------------

                when "00001010011" =>
				for I in 1 to 16 loop	 -- loop over bytes
					byteprocess := indataA(((8*I)-8) to ((8*I)-1)); -- Get bytes to process
					byteprocess1 := indataB(((8*I)-8) to ((8*I)-1));
				
					if signed(byteprocess1) > signed(byteprocess) then
					outdata(((8*I)-8) to ((8*I)-1)) <= std_logic_vector(unsigned(byteprocess1) - unsigned(byteprocess));
					else
					outdata(((8*I)-8) to ((8*I)-1)) <= std_logic_vector(unsigned(byteprocess) - unsigned(byteprocess1));
					end if;
				
				end loop;
				
				depth <= "011";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "100";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
		
--------------end Absolute Differences of Bytes-------------------------------------------------------------------

----------------Floating Add------------------------------------------------------------------------

                 when "01011000100" =>
					for I in 1 to 4 loop
					
						exponent0 := unsigned(indataA(((I*32)-31) to ((32*I)-24))); -- get exponent value and calculate
						exponent1 := unsigned(indataB(((I*32)-31) to ((32*I)-24))); 
					
						mantissa0 := unsigned('1' & indataA(((I*32)-23) to ((I*32)-1)));
						mantissa1 := unsigned('1' & indataB(((I*32)-23) to ((I*32)-1)));
					
						sign0 := indataA((I*32)-32);
						sign1 := indataB((I*32)-32);
						--check for zero on input
						if indataA(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
							if indataB(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
								outdata(((I*32)-32) to ((32*I)-1)) <= "00000000000000000000000000000000";
							else
								outdata(((I*32)-32) to ((32*I)-1)) <= indataB(((I*32)-32) to ((32*I)-1));	   
							end if;
						elsif indataB(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
							if indataA(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
								outdata(((I*32)-32) to ((32*I)-1)) <= "00000000000000000000000000000000";
							else
								outdata(((I*32)-32) to ((32*I)-1)) <= indataA(((I*32)-32) to ((32*I)-1));
							end if;
							--end check for zero
						else
							if exponent0 > exponent1 then
								mantissa1 := mantissa1 srl to_integer(exponent0 - exponent1); --if exponent 0 greater than 1 shift mantissa1
								exponentresult:= ('0' & exponent0);
							else
								mantissa0 := mantissa0 srl to_integer(exponent1- exponent0); --otherwise do the opisitie
								exponentresult := ('0' & exponent1);
							end if;
						
							--do math on mantissa
							if sign0 = '1' and sign1 = '1' then
								floatresult := unsigned(resize(mantissa0, immediate25'length) + resize(mantissa1, immediate25'length));
								signout := '1';
							
							elsif sign0 = '0' and sign1 = '0' then
								floatresult :=  unsigned(resize(mantissa0, immediate25'length) + resize(mantissa1, immediate25'length));
								signout := '0';
								
							elsif sign0 = '1' and sign1 = '0' then
								if mantissa0 < mantissa1 then
									floatresult := ('0' & mantissa1(0 to 23)) - ('0' & mantissa0(0 to 23));
									signout := '0';
								else
									floatresult := ('0' & mantissa0(0 to 23)) - ('0' & mantissa1(0 to 23));
									signout := '1'; 
								end if;
								
							elsif sign0 = '0' and sign1 = '1' then
								if mantissa0 > mantissa1 then
									floatresult := ('0' & mantissa0(0 to 23)) - ('0' & mantissa1(0 to 23));
									signout := '0';
								else
									floatresult := ('0' & mantissa1(0 to 23)) - ('0' & mantissa0(0 to 23));
									signout := '1';
								end if;
							end if;
							
							if floatresult(0) = '1' then
								exponentresult := exponentresult + "000000001";
								resultmantissa := std_logic_vector(floatresult(0 to 23));
							else
								resultmantissa := std_logic_vector(floatresult(1 to 24));
							end if;
							
										
							exponentsub := "000000000";
							mantissashift := "000000000000000000000000";
							looplook: for J in 1 to 24 loop -- loop at each bit in a specific byte
								if resultmantissa(J-1) = '0' then
								exponentsub := exponentsub + "000000001";
								mantissashift := mantissashift + "000000000000000000000001";
								elsif resultmantissa(J-1) = '1' then
								exit looplook;--break look when first 1 is found
								end if;
							end loop;
							
							resultmantissa := std_logic_vector(unsigned(resultmantissa) sll to_integer(mantissashift));
							exponentresult := exponentresult - exponentsub;
							if exponentresult(0) = '1' then
								if (exponent0(0) or exponent1(0)) = '1' then
									outdata(((I*32)-32) to ((32*I)-1)) <= (signout & "1111111" & x"FFFFFFFF");
									fpscr(((I*32)-3) to ((I*32)-1)) <= "100";
								else
									outdata(((I*32)-32) to ((32*I)-1)) <= x"00800000";
									fpscr(((I*32)-3) to ((I*32)-1)) <= "010";
								end if;
							
							else
							outdata(((I*32)-32) to ((32*I)-1)) <= signout & std_logic_vector(exponentresult(1 to 8)) & resultmantissa(1 to 23);
							end if;
						end if;
					end loop;
				fpscr <= x"00000000000000000000000000000000";	
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "010";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
				
		
--------------end Floating Add-------------------------------------------------------------------


----------------Floating Subtract------------------------------------------------------------------------

                 when "01011000101" =>
					for I in 1 to 4 loop
					
						exponent0 := unsigned(indataA(((I*32)-31) to ((32*I)-24))); -- get exponent value and calculate
						exponent1 := unsigned(indataB(((I*32)-31) to ((32*I)-24))); 
					
						mantissa0 := unsigned('1' & indataA(((I*32)-23) to ((I*32)-1)));
						mantissa1 := unsigned('1' & indataB(((I*32)-23) to ((I*32)-1)));
					
						sign0 := indataA((I*32)-32);
						sign1 := indataB((I*32)-32);
						--check for zero on input
						if indataA(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
							if indataB(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
								outdata(((I*32)-32) to ((32*I)-1)) <= "00000000000000000000000000000000";
							else
								outdata(((I*32)-32) to ((32*I)-1)) <= indataB(((I*32)-32) to ((32*I)-1));	   
							end if;
						elsif indataB(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
							if indataA(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
								outdata(((I*32)-32) to ((32*I)-1)) <= "00000000000000000000000000000000";
							else
								outdata(((I*32)-32) to ((32*I)-1)) <= indataA(((I*32)-32) to ((32*I)-1));
							end if;
							--end check for zero
						else
							if exponent0 > exponent1 then
								mantissa1 := mantissa1 srl to_integer(exponent0 - exponent1); --if exponent 0 greater than 1 shift mantissa1
								exponentresult:= ('0' & exponent0);
							else
								mantissa0 := mantissa0 srl to_integer(exponent1- exponent0); --otherwise do the opisitie
								exponentresult := ('0' & exponent1);
							end if;
						
							--do math on mantissa
							if sign0 = '0' and sign1 = '1' then
								floatresult := unsigned(resize(mantissa0, immediate25'length) - resize(mantissa1, immediate25'length));
								signout := '0';
							
							elsif sign0 = '1' and sign1 = '0' then
								floatresult :=  unsigned(resize(mantissa0, immediate25'length) + resize(mantissa1, immediate25'length));
								signout := '1';
								
							elsif sign0 = '1' and sign1 = '1' then
								if mantissa0 < mantissa1 then
									floatresult := ('0' & mantissa1(0 to 23)) + ('0' & mantissa0(0 to 23));
									signout := '1';
								else
									floatresult := ('0' & mantissa0(0 to 23)) + ('0' & mantissa1(0 to 23));
									signout := '0'; 
								end if;
								
							elsif sign0 = '0' and sign1 = '0' then
								if mantissa0 > mantissa1 then
									floatresult := ('0' & mantissa0(0 to 23)) - ('0' & mantissa1(0 to 23));
									signout := '0';
								else
									floatresult := ('0' & mantissa1(0 to 23)) - ('0' & mantissa0(0 to 23));
									signout := '1';
								end if;
							end if;
							
							if floatresult(0) = '1' then
								exponentresult := exponentresult + "000000001";
								resultmantissa := std_logic_vector(floatresult(0 to 23));
							else
								resultmantissa := std_logic_vector(floatresult(1 to 24));
							end if;
							
										
							exponentsub := "000000000";
							mantissashift := "000000000000000000000000";
							looplook: for J in 1 to 24 loop -- loop at each bit in a specific byte
								if resultmantissa(J-1) = '0' then
								exponentsub := exponentsub + "000000001";
								mantissashift := mantissashift + "000000000000000000000001";
								elsif resultmantissa(J-1) = '1' then
								exit looplook;--break look when first 1 is found
								end if;
							end loop;
							
							resultmantissa := std_logic_vector(unsigned(resultmantissa) sll to_integer(mantissashift));
							exponentresult := exponentresult - exponentsub;
							if exponentresult(0) = '1' then
								if (exponent0(0) or exponent1(0)) = '1' then
									outdata(((I*32)-32) to ((32*I)-1)) <= (signout & "111" & x"fffffff");
									fpscr(((I*32)-3) to ((I*32)-1)) <= "100";
								else
									outdata(((I*32)-32) to ((32*I)-1)) <= x"00800000";
									fpscr(((I*32)-3) to ((I*32)-1)) <= "010";
								end if;
							
							else
							outdata(((I*32)-32) to ((32*I)-1)) <= signout & std_logic_vector(exponentresult(1 to 8)) & resultmantissa(1 to 23);
							end if;
						end if;
					end loop;
					
				fpscr <= x"00000000000000000000000000000000";		
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "010";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
				
		
--------------end Floating Subtract-------------------------------------------------------------------


----------------Floating Multiply----------------------------------------------------------------------

                 when "01011000110" =>
					for I in 1 to 4 loop
					
						exponent0 := unsigned(indataA(((I*32)-31) to ((32*I)-24))); -- get exponent value and calculate
						exponent1 := unsigned(indataB(((I*32)-31) to ((32*I)-24))); 
					
						mantissa0 := unsigned('1' & indataA(((I*32)-23) to ((I*32)-1)));
						mantissa1 := unsigned('1' & indataB(((I*32)-23) to ((I*32)-1)));
					
						sign0 := indataA((I*32)-32);
						sign1 := indataB((I*32)-32);
						--check for zero on input
						if (indataA(((I*32)-32) to ((32*I)-1)) = x"00000000") or  (indataA(((I*32)-32) to ((32*I)-1)) = x"80000000") or (indataB(((I*32)-32) to ((32*I)-1)) = x"00000000") or  (indataB(((I*32)-32) to ((32*I)-1)) = x"80000000") then
								outdata(((I*32)-32) to ((32*I)-1)) <= x"00000000"; -- if either input is positive or negative zero set to positive 0.
							--end check for zero
						else
							
							--Figure out sign of output
							if sign0 = '0' and sign1 = '0' then-- both postive
								signout := '0';
							
							elsif sign0 = '1' and sign1 = '0' then --inputA negative input B postive
								signout := '1';
								
							elsif sign0 = '0' and sign1 = '1' then --inputA postive inputB negative
								signout := '1'; 
								
							elsif sign0 = '1' and sign1 = '1' then --both negative
								signout := '0';
							end if;
							
							floatmult := mantissa0 * mantissa1; -- do multiplication of mantissa values							
										
							exponentsub := "000000000";
							mantissashift := "000000000000000000000000";
							looplook: for J in 1 to 47 loop -- loop at each bit in a specific byte
								if floatmult(J-1) = '0' then
								exponentsub := exponentsub + "000000001";
								mantissashift := mantissashift + "000000000000000000000001";
								elsif floatmult(J-1) = '1' then
								exit looplook;--break look when first 1 is found
								end if;
							end loop;
							
							floatmult := floatmult sll to_integer(mantissashift);
							exponentresult := ('0' & exponent0) + ('0' & exponent1) - exponentsub - 126;
							--check for overflow
							if exponentresult(0) = '1' then
								if (exponent0(0) or exponent1(0)) = '1' then
									outdata(((I*32)-32) to ((32*I)-1)) <= (signout & "1111111" & x"FFFFFFFF");
									fpscr(((I*32)-3) to ((I*32)-1)) <= "100";
								else
									outdata(((I*32)-32) to ((32*I)-1)) <= x"00800000";
									fpscr(((I*32)-3) to ((I*32)-1)) <= "010";
								end if;
							
							else
							outdata(((I*32)-32) to ((32*I)-1)) <= signout & std_logic_vector(exponentresult(1 to 8)) & std_logic_vector(floatmult(1 to 23));
							end if;
						end if;
					end loop;
				
				fpscr <= x"00000000000000000000000000000000";						
				depth <= "110";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "011";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
				
--------------end Floating Multiply-------------------------------------------------------------------

----------------Floating Multiply and Add----------------------------------------------------------------------

                 when "11100000000" =>
					for I in 1 to 4 loop
					exponent0 := unsigned(indataA(((I*32)-31) to ((32*I)-24))); -- get exponent value and calculate
						exponent1 := unsigned(indataB(((I*32)-31) to ((32*I)-24))); 
					
						mantissa0 := unsigned('1' & indataA(((I*32)-23) to ((I*32)-1)));
						mantissa1 := unsigned('1' & indataB(((I*32)-23) to ((I*32)-1)));
					
						sign0 := indataA((I*32)-32);
						sign1 := indataB((I*32)-32);
						--check for zero on input
						if (indataA(((I*32)-32) to ((32*I)-1)) = x"00000000") or  (indataA(((I*32)-32) to ((32*I)-1)) = x"80000000") or (indataB(((I*32)-32) to ((32*I)-1)) = x"00000000") or  (indataB(((I*32)-32) to ((32*I)-1)) = x"80000000") then
								tempout(((1*32)-32) to ((32*1)-1)) := x"00000000"; -- if either input is positive or negative zero set to positive 0.
							--end check for zero
						else
							
							--Figure out sign of output
							if sign0 = '0' and sign1 = '0' then-- both postive
								signout := '0';
							
							elsif sign0 = '1' and sign1 = '0' then --inputA negative input B postive
								signout := '1';
								
							elsif sign0 = '0' and sign1 = '1' then --inputA postive inputB negative
								signout := '1'; 
								
							elsif sign0 = '1' and sign1 = '1' then --both negative
								signout := '0';
							end if;
							
							floatmult := mantissa0 * mantissa1; -- do multiplication of mantissa values							
										
							exponentsub := "000000000";
							mantissashift := "000000000000000000000000";
							looplook: for J in 1 to 47 loop -- loop at each bit in a specific byte
								if floatmult(J-1) = '0' then
								exponentsub := exponentsub + "000000001";
								mantissashift := mantissashift + "000000000000000000000001";
								elsif floatmult(J-1) = '1' then
								exit looplook;--break look when first 1 is found
								end if;
							end loop;
							
							floatmult := floatmult sll to_integer(mantissashift);
							exponentresult := ('0' & exponent0) + ('0' & exponent1) - exponentsub - 126;
							--check for overflow
							if exponentresult(0) = '1' then
								if (exponent0(0) or exponent1(0)) = '1' then
									tempout(((1*32)-32) to ((32*1)-1)) := (signout & "1111111" & x"FFFFFF");
								else
									tempout(((1*32)-32) to ((32*1)-1)) := x"00800000";
								end if;
							
							else
							tempout(((1*32)-32) to ((32*1)-1)) := signout & std_logic_vector(exponentresult(1 to 8)) & std_logic_vector(floatmult(1 to 23));
							end if;
						end if;

					--end multiply
						exponent0 := unsigned(tempout(((1*32)-31) to ((32*1)-24))); -- get exponent value and calculate
						exponent1 := unsigned(indataC(((I*32)-31) to ((32*I)-24))); 
					
						mantissa0 := unsigned('1' & tempout(((1*32)-23) to ((1*32)-1)));
						mantissa1 := unsigned('1' & indataC(((I*32)-23) to ((I*32)-1)));
					
						sign0 := tempout((1*32)-32);
						sign1 := indataC((I*32)-32);
						--check for zero on input
						if tempout(((1*32)-31) to ((32*1)-1)) = "0000000000000000000000000000000" then
							if indataC(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
								outdata(((I*32)-32) to ((32*I)-1)) <= "00000000000000000000000000000000";
							else
								outdata(((I*32)-32) to ((32*I)-1)) <= indataC(((I*32)-32) to ((32*I)-1));	   
							end if;
						elsif indataC(((I*32)-31) to ((32*I)-1)) = "0000000000000000000000000000000" then
							if tempout(((1*32)-31) to ((32*1)-1)) = "0000000000000000000000000000000" then
								outdata(((I*32)-32) to ((32*I)-1)) <= "00000000000000000000000000000000";
							else
								outdata(((I*32)-32) to ((32*I)-1)) <= tempout(((1*32)-32) to ((32*1)-1));
							end if;
							--end check for zero
						else
							if exponent0 > exponent1 then
								mantissa1 := mantissa1 srl to_integer(exponent0 - exponent1); --if exponent 0 greater than 1 shift mantissa1
								exponentresult:= ('0' & exponent0);
							else
								mantissa0 := mantissa0 srl to_integer(exponent1- exponent0); --otherwise do the opisitie
								exponentresult := ('0' & exponent1);
							end if;
						
							--do math on mantissa
							if sign0 = '1' and sign1 = '1' then
								floatresult := unsigned(resize(mantissa0, immediate25'length) + resize(mantissa1, immediate25'length));
								signout := '1';
							
							elsif sign0 = '0' and sign1 = '0' then
								floatresult :=  unsigned(resize(mantissa0, immediate25'length) + resize(mantissa1, immediate25'length));
								signout := '0';
								
							elsif sign0 = '1' and sign1 = '0' then
								if mantissa0 < mantissa1 then
									floatresult := ('0' & mantissa1(0 to 23)) - ('0' & mantissa0(0 to 23));
									signout := '0';
								else
									floatresult := ('0' & mantissa0(0 to 23)) - ('0' & mantissa1(0 to 23));
									signout := '1'; 
								end if;
								
							elsif sign0 = '0' and sign1 = '1' then
								if mantissa0 > mantissa1 then
									floatresult := ('0' & mantissa0(0 to 23)) - ('0' & mantissa1(0 to 23));
									signout := '0';
								else
									floatresult := ('0' & mantissa1(0 to 23)) - ('0' & mantissa0(0 to 23));
									signout := '1';
								end if;
							end if;
							
							if floatresult(0) = '1' then
								exponentresult := exponentresult + "000000001";
								resultmantissa := std_logic_vector(floatresult(0 to 23));
							else
								resultmantissa := std_logic_vector(floatresult(1 to 24));
							end if;
							
										
							exponentsub := "000000000";
							mantissashift := "000000000000000000000000";
							looplook1: for J in 1 to 24 loop -- loop at each bit in a specific byte
								if resultmantissa(J-1) = '0' then
								exponentsub := exponentsub + "000000001";
								mantissashift := mantissashift + "000000000000000000000001";
								elsif resultmantissa(J-1) = '1' then
								exit looplook1;--break look when first 1 is found
								end if;
							end loop;
							
							resultmantissa := std_logic_vector(unsigned(resultmantissa) sll to_integer(mantissashift));
							exponentresult := exponentresult - exponentsub;
							if exponentresult(0) = '1' then
								if (exponent0(0) or exponent1(0)) = '1' then
									outdata(((I*32)-32) to ((32*I)-1)) <= (signout & "1111111" & x"FFFFFFFF");
									fpscr(((I*32)-3) to ((I*32)-1)) <= "100";
								else
									outdata(((I*32)-32) to ((32*I)-1)) <= x"00800000";
									fpscr(((I*32)-3) to ((I*32)-1)) <= "010";
								end if;
							
							else
							outdata(((I*32)-32) to ((32*I)-1)) <= signout & std_logic_vector(exponentresult(1 to 8)) & resultmantissa(1 to 23);
							end if;
						end if;
				
					end loop;
					
					
					
				fpscr <= x"00000000000000000000000000000000";		
				depth <= "111";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "011";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
				
--------------end Floating Multiply and Add-------------------------------------------------------------------





------------------Floating Compare Equal------------------------------------------------------------------------

                when "01111000010" =>
				
				for I in 1 to 4 loop
					if (indataA(((32*I)-32) to ((32*I)-1)) =  x"00000000000000000000000000000000" or indataA(((32*I)-32) to ((32*I)-1)) = x"80000000000000000000000000000000") and (indataB(((32*I)-32) to ((32*I)-1)) =  x"00000000000000000000000000000000" or indataB(((32*I)-32) to ((32*I)-1)) = x"80000000000000000000000000000000") then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
					
					elsif indataA(((32*I)-32) to ((32*I)-1)) = indataB(((32*I)-32) to ((32*I)-1)) then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
						else
						outdata(((32*I)-32) to ((32*I)-1))<= "00000000000000000000000000000000";
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			
--------------end Floating Compare Equal-------------------------------------------------------------------

------------------Floating Compare Magnitude Equal------------------------------------------------------------------------

                when "01111001010" =>
				
				for I in 1 to 4 loop
					if (indataA(((32*I)-32) to ((32*I)-1)) =  x"00000000000000000000000000000000" or indataA(((32*I)-32) to ((32*I)-1)) = x"80000000000000000000000000000000") and (indataB(((32*I)-32) to ((32*I)-1)) =  x"00000000000000000000000000000000" or indataB(((32*I)-32) to ((32*I)-1)) = x"80000000000000000000000000000000") then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
					
					elsif indataA(((32*I)-31) to ((32*I)-1)) = indataB(((32*I)-31) to ((32*I)-1)) then --ignore the sign bit
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111";
						else
						outdata(((32*I)-32) to ((32*I)-1))<= "00000000000000000000000000000000";
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			
--------------end Floating Compare Magnitude Equal-------------------------------------------------------------------

------------------Floating Compare Greater Than------------------------------------------------------------------------

                when "01011000010" =>
				
				for I in 1 to 4 loop
				
				exponent0 := unsigned(indataA(((I*32)-31) to ((32*I)-24))); -- get exponent value and calculate
				exponent1 := unsigned(indataB(((I*32)-31) to ((32*I)-24))); 
					
				mantissa0 := unsigned('1' & indataA(((I*32)-23) to ((I*32)-1)));
				mantissa1 := unsigned('1' & indataB(((I*32)-23) to ((I*32)-1)));
				
				sign0 := indataA((I*32)-32);
				sign1 := indataB((I*32)-32);
					if (indataA(((32*I)-32) to ((32*I)-1)) =  x"00000000000000000000000000000000" or indataA(((32*I)-32) to ((32*I)-1)) = x"80000000000000000000000000000000") and (indataB(((32*I)-32) to ((32*I)-1)) =  x"00000000000000000000000000000000" or indataB(((32*I)-32) to ((32*I)-1)) = x"80000000000000000000000000000000") then
						outdata(((32*I)-32) to ((32*I)-1)) <= "00000000000000000000000000000000"; -- if both are zero then alwyas less than
					
					elsif sign0 = sign1 then
						if exponent0 > exponent1 then
							outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111"; -- if signs are equal and one exponent is greater than the other
						elsif exponent0 < exponent1 then
							outdata(((32*I)-32) to ((32*I)-1)) <= "00000000000000000000000000000000"; -- if signs are equal and exponentB is greater than exponentA
						else --if exponents are equal
							if mantissa0 > mantissa1 then
								outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111"; -- if signs are equal and exponents are qual compare mantissas
							else
								outdata(((32*I)-32) to ((32*I)-1)) <= "00000000000000000000000000000000"; -- if signs are equal and exponents are qual compare mantissas
							end if; 
						end if;
					elsif sign0 = '0' and sign1 = '1' then
						outdata(((32*I)-32) to ((32*I)-1)) <= "11111111111111111111111111111111"; -- if a is postive and b is negative then it is always graeter than
					else
						outdata(((32*I)-32) to ((32*I)-1)) <= "00000000000000000000000000000000"; -- if a is negative and b is postive then it is always less than	
					end if;
				end loop;
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '1';
				timestampout <= timestamp;
			
--------------end Floating Compare Greater Than-------------------------------------------------------------------

------------------Floating Compare Greater Than------------------------------------------------------------------------

                when "01110111010" =>
				
				fpscr <= indataA;
				
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
			
--------------end Floating Compare Greater Than-------------------------------------------------------------------

------------------Floating Compare Greater Than------------------------------------------------------------------------

                when "01110011000" =>
				
				outdata <=fpscr;
				
				depth <= "010";
				pcnext <= pccurrent;
				branchflag <= '0';
				unit <= "000";
				readmem <= '0';
				writemem <= '0';
				writereg <= '0';
				timestampout <= timestamp;
			
--------------end Floating Compare Greater Than-------------------------------------------------------------------




                when others=>
                null;

            end case;
        end if;
    end process;
    
end behavioral;
