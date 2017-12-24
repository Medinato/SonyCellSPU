--Decode Stage
--David Gash
--Decode Stage
-- Each cycle takes two instructions as inputs from the program counter/instruction fetch stage
-- and decodes them and assigns them to pipes for processing
--also checks for structural hazards (pipes) and some data hazards
--Passes outputs to issue stage for more complex data hazard check.


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity decode is
port(
    clk: in std_logic; --clock input
    enable: in std_logic; --block enable
    branchflag: in std_logic; -- branch flag needed to clear inputs if 
    stoppc: out std_logic; -- stop pc if structural hazard
    datahazard: in std_logic; -- flag to 
    -- Inputs
    instr1: in std_logic_vector(0 to 31);
    PCin1: in std_logic_vector(0 to 31);
    timestampin1: in std_logic_vector( 0 to 3);
    
    instr2: in std_logic_vector(0 to 31);
    PCin2: in std_logic_vector(0 to 31);
    timestampin2: in std_logic_vector( 0 to 3);
    
    -- EVEN INPUTS REGISTER READ
    evenaddrA: out std_logic_vector(0 to 6); --input A
    evenaddrB: out std_logic_vector(0 to 6); --input B
    evenaddrC: out std_logic_vector(0 to 6); --input C 
    evenopcode: out std_logic_vector(0 to 10);  --opcode input
    evenrt : out std_logic_vector(0 to 6);-- destination register
    evenPCout: out std_logic_vector(0 to 31); --program counter in
    evenimmediate: out std_logic_vector(0 to 15); -- immediate 16 bit input
    eventimestampout : out std_logic_vector(0 to 3); --time stamp to determine execution order
    
    -- Odd INPUTS REGISTER READ
    oddaddrA: out std_logic_vector(0 to 6); --input A
    oddaddrB: out std_logic_vector(0 to 6); --input B
    oddaddrC: out std_logic_vector(0 to 6); --input C 
    oddopcode: out std_logic_vector(0 to 10);  --opcode input
    oddrt : out std_logic_vector(0 to 6);-- destination register
    oddPCout: out std_logic_vector(0 to 31); --program counter in
    oddimmediate: out std_logic_vector(0 to 15); -- immediate 16 bit input
    oddtimestampout : out std_logic_vector(0 to 3) --time stamp to determine execution order    
    );
end decode;

architecture behavioral of decode is          
signal test :std_logic;
signal rttest :std_logic_vector(0 to 6);

begin
    process(enable, clk, branchflag,datahazard)  
    variable instr1pipe: std_logic; --0 = even pipe, 1 = odd pipe
    variable instr2pipe: std_logic; 
    -- temp variables to hold decoded instructions before assignment to pipes
    variable addrA1: std_logic_vector(0 to 6);
    variable addrB1: std_logic_vector(0 to 6);
    variable addrC1: std_logic_vector(0 to 6);
    variable rt1: std_logic_vector(0 to 6);
    variable opcode1: std_logic_vector(0 to 10);
    variable immediate1: std_logic_vector(0 to 15);
    variable PC1: std_logic_vector(0 to 31);
    variable timestamp1: std_logic_vector(0 to 3);
    
    variable addrA2: std_logic_vector(0 to 6);
    variable addrB2: std_logic_vector(0 to 6);
    variable addrC2: std_logic_vector(0 to 6);
    variable rt2: std_logic_vector(0 to 6);
    variable opcode2: std_logic_vector(0 to 10);
    variable immediate2: std_logic_vector(0 to 15);
    variable PC2: std_logic_vector(0 to 31);
    variable timestamp2: std_logic_vector(0 to 3);
    
    variable hazard: std_logic;
	variable hazardcheck: std_logic;

    begin
    if datahazard = '1' then -- If issue stage detects hazard do not continue output do nothings
        if branchflag /= '1' then
            stoppc <= '1'; -- stop the program counter and don't send any more data
			hazardcheck := '1';
        elsif branchflag = '1' then -- if branch occurs do not decode instruction on input output do nothings
            evenaddrA <= "0000000";
            evenaddrB <= "0000000";
            evenaddrC <= "0000000";
            evenopcode <= "00000000001";
            evenrt  <= "0000000";
            evenPCout <= x"00000000";
            evenimmediate <= x"0000";
            eventimestampout <= "0000";
                    
                        -- odd pipe assignment
            oddaddrA <= "0000000";
            oddaddrB <= "0000000";
            oddaddrC <= "0000000";
            oddopcode <= "00000000001";
            oddrt  <= "0000000";
            oddPCout <= x"00000000";
            oddimmediate <= x"0000";
            oddtimestampout <= "0000";
                        
            hazard := '0';
            stoppc <= '0'; -- stop the program counter for 1 cycle 
        end if;
	elsif datahazard = '0' and hazardcheck = '1' and hazard = '1' then
		stoppc <= '0';
		hazardcheck := '0';
    
    elsif rising_edge(clk) and enable = '1' and datahazard = '0' then
		hazardcheck := '0';
            if hazard = '1'  and branchflag /= '1'then -- if internal hazard was dectected last cycle this cycle output the instruction held back
                if instr2pipe = '0' then 
                    --even pipe assignment
                    evenaddrA <= addrA2;
                    evenaddrB <= addrB2;
                    evenaddrC <= addrC2;
                    evenopcode <= opcode2;
                    evenrt  <= rt2;
                    evenPCout <= PC2;
                    evenimmediate <= immediate2;
                    eventimestampout <= timestamp2;
                        
                    oddaddrA <= "0000000";
                    oddaddrB <= "0000000";
                    oddaddrC <= "0000000";
                    oddopcode <= "00000000001";
                    oddrt  <= "0000000";
                    oddPCout <= x"00000000";
                    oddimmediate <= x"0000";
                    oddtimestampout <= "0000";
                    test <= '0'; 
                    stoppc <= '0'; -- stop the program counter for 1 cycle 
                    hazard := '0';
                    
                elsif instr2pipe = '1' then
                -- odd pipe assignement
                    oddaddrA <= addrA2;
                    oddaddrB <= addrB2;
                    oddaddrC <= addrC2;
                    oddopcode <= opcode2;
                    oddrt  <= rt2;
                    oddPCout <= PC2;
                    oddimmediate <= immediate2;
                    oddtimestampout <= timestamp2;
                    
                    evenaddrA <= "0000000";
                    evenaddrB <= "0000000";
                    evenaddrC <= "0000000";
                    evenopcode <= "00000000001"; --NOP
                    evenrt  <= "0000000";
                    evenPCout <= x"00000000";
                    evenimmediate <= x"0000";
                    eventimestampout <= "0000";
                     test <= '0';   
                    stoppc <= '0'; -- stop the program counter for 1 cycle 
                    hazard := '0';
                
                end if;
        
            else
        -- Instrution1 Decode-------------------------------------------------------------------------------------------
            --Instruction Fetch from Memory
                if instr1 (0 to 3) = "1111" then
                    instr1pipe := '0';-- even pipe
                    PC1 := instr1(4 to 31) & "0000";
                    timestamp1 := timestampin1;
                    opcode1 := "1111" & "0000000";  
                    
                -- RRR FORMAT   
                elsif instr1(0) = '1' then
                    instr1pipe := '0'; -- even pipe
                    addrA1 := instr1(18 to 24);
                    addrB1 := instr1(11 to 17);
                    addrC1 := instr1(25 to 31);
                    rt1 := instr1(4 to 10);
                    opcode1 := instr1(0 to 3) & "0000000";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := x"0000";
                
                --RR format decode even pipe
                elsif instr1(0 to 10) = "00011001000" or instr1(0 to 10) = "00011000000" or instr1(0 to 10) = "00001001000" or instr1(0 to 10) = "00001000000" or instr1(0 to 10) = "01111000100" or instr1(0 to 10) = "01111001100" or instr1(0 to 10) = "00011000001" or instr1(0 to 10) = "00001000001" or instr1(0 to 10) = "01001000001" or instr1(0 to 10) = "00011001001" or instr1(0 to 10) = "00001001001" or instr1(0 to 10) = "01001001001" or instr1(0 to 10) = "00001011000" or instr1(0 to 10) = "00001011100" or instr1(0 to 10) = "00001011111" or instr1(0 to 10) = "00001011011" or instr1(0 to 10) = "01111001000" or instr1(0 to 10) = "01111010000" or instr1(0 to 10) = "01001001000" or instr1(0 to 10) = "01001010000" or instr1(0 to 10) = "01111000000" or instr1(0 to 10) = "01001000000" or instr1(0 to 10) = "00000000001" or instr1(0 to 10) = "01000000001" or instr1(0 to 10) = "01011000100" or instr1(0 to 10) = "01011000101" or instr1(0 to 10) = "01011000110" or instr1(0 to 10) = "01111000010" or instr1(0 to 10) = "01011000010" or instr1(0 to 10) = "01110111010" or instr1(0 to 10) = "01110011000" or instr1(0 to 10) = "01010110100" or instr1(0 to 10) = "01010100101" or instr1(0 to 10) = "00011010011" or instr1(0 to 10) = "00001010011" or instr1(0 to 10) = "01111000101" or instr1(0 to 10) = "01011001001" or instr1(0 to 10) = "00111110000" or instr1(0 to 10) = "01111001010" then
                    instr1pipe := '0'; -- even pipe
                    addrA1 := instr1(18 to 24);
                    addrB1 := instr1(11 to 17);
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 10);
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := x"0000";
					
               -- false target instructions    
               elsif instr1(0 to 10) = "01000000001" then
					instr1pipe := '0'; -- even pipe
					addrA1 := instr1(18 to 24);
					addrB1 := instr1(11 to 17);
					rt1 := "0000000";
					opcode1 := instr1(0 to 10);
					PC1 := PCin1;
					timestamp1 := timestampin1;
					immediate1 := x"0000";
					
					
					
				elsif instr1(0 to 10) = "00000000001" then
					instr1pipe := '1'; -- odd pipe
					addrA1 := instr1(18 to 24);
					addrB1 := instr1(11 to 17);
					rt1 := "0000001";
					opcode1 := instr1(0 to 10);
					PC1 := PCin1;
					timestamp1 := timestampin1;
					immediate1 := x"0000";
                    
                    
                -- --RR format decode odd pipe
                elsif instr1(0 to 10) = "00111000100" or instr1(0 to 10) = "01111011000" or instr1(0 to 10) = "01001011000" or instr1(0 to 10) = "00111011100"  or instr1(0 to 10) = "00111001100" or instr1(0 to 10) = "00111011000" or instr1(0 to 10) = "00000000001"  then
                    instr1pipe := '1'; -- odd pipe
                    addrA1 := instr1(18 to 24);
                    addrB1 := instr1(11 to 17);
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 10);
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := x"0000";
                    
                --RI7 format decode even pipe
                elsif instr1(0 to 10) = "00001111111" or instr1(0 to 10) = "00001111011" then
                    instr1pipe := '0'; -- even pipe
                    addrA1 := instr1(18 to 24);
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 10);
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := "000000000" & instr1(11 to 17);
                    
                --RI7 format decode odd pipe
                elsif instr1(0 to 10) = "00111111000" or instr1(0 to 10) = "00111111100" then
                    instr1pipe := '1'; -- odd pipe
                    addrA1 := instr1(18 to 24);
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 10);
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := "000000000" & instr1(11 to 17);       

                -- --RI10 format decode even pipe
                elsif instr1(0 to 7) = "00011101" or instr1(0 to 7) = "00011100" or instr1(0 to 7) = "00001101" or instr1(0 to 7) = "00001100" or instr1(0 to 7) = "01110100" or instr1(0 to 7) = "00010100" or instr1(0 to 7) = "00000100" or instr1(0 to 7) = "01000100" or instr1(0 to 7) = "01111100" or instr1(0 to 7) = "01111101" or instr1(0 to 7) = "01111110" or instr1(0 to 7) = "01001100" or instr1(0 to 7) = "01001101" or instr1(0 to 7) = "01001110" or instr1(0 to 7) = "00010110" or instr1(0 to 7) = "00010101" or instr1(0 to 7) = "00000101" or instr1(0 to 7) = "00000110" or instr1(0 to 7) = "01000101" or instr1(0 to 7) = "01000110" then
                    instr1pipe := '0'; -- even pipe
                    addrA1 := instr1(18 to 24);
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 7) & "000";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := "000000" & instr1(8 to 17);   
                    
                --RI10 format decode odd pipe
                elsif instr1(0 to 7) = "01111111" or instr1(0 to 7) =  "01001111" or instr1(0 to 7) = "00110100" then
                    instr1pipe := '1'; -- odd pipe
                    addrA1 := instr1(18 to 24);
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 7) & "000";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := "000000" & instr1(8 to 17);   
                
                --RI16 format decode odd pipe for rt is a value
                elsif instr1(0 to 8) = "001100000" or instr1(0 to 8) = "001000010" or instr1(0 to 8) = "001000000" or instr1(0 to 8) = "001000100" or instr1(0 to 8) = "001000110"  then
                    instr1pipe := '1'; -- odd pipe
                    addrA1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 8) & "00";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := instr1(9 to 24);      
                    
                -- RI16 for Load/ branch set link (rt is tartget)   
                elsif instr1(0 to 8) = "010000001" or instr1(0 to 8) = "001100001" or instr1(0 to 8) = "001100100" or instr1(0 to 8) = "001100010" or instr1(0 to 8) = "001100110" or instr1(0 to 8) = "010000010" or  instr1(0 to 8) = "010000011" then
                    instr1pipe := '1'; -- odd pipe
                    rt1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 8) & "00";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := instr1(9 to 24);  
                    
                --UNIQUE CASES
                -- Store d-form
                elsif instr1(0 to 7) = ("00100100") then
                    instr1pipe := '1'; -- odd pipe
                    addrC1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 7) & "000";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := "000000" & instr1(8 to 17);   
                    
                --Store X-form
                elsif instr1(0 to 10) = "00101000100" then
                    instr1pipe := '1'; -- odd pipe
                    addrA1 := instr1(18 to 24);
                    addrB1 := instr1(11 to 17);
                    addrC1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 10);
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := x"0000";
                    
                -- Store a-form
                elsif instr1(0 to 8) = "001000001" then
                    instr1pipe := '1'; -- odd pipe
                    addrC1 := instr1(25 to 31);
                    opcode1 := instr1(0 to 8) & "00";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := instr1(9 to 24);  
                    
                -- Branch Indirect
                elsif instr1(0 to 10) = "00110101000" then
                    instr1pipe := '1'; -- odd pipe
                    addrA1 := instr1(18 to 24);
                    opcode1 := instr1(0 to 10);
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := x"0000";  
                else
                    instr1pipe := '0'; -- even pipe
                    addrA1 := instr1(18 to 24);
                    addrB1 := instr1(11 to 17);
                    rt1 := instr1(25 to 31);
                    opcode1 := "00000000001";
                    PC1 := PCin1;
                    timestamp1 := timestampin1;
                    immediate1 := x"0000";
                    
                    
                end if;
        -- END Instrution1 Decode-------------------------------------------------------------------------------------------        

        -- -- Instrution2 Decode-------------------------------------------------------------------------------------------
            -- -- RRR format Decode
                if instr2(0) = '1' and instr2(0 to 3) /= "1111" then
                    instr2pipe := '0'; -- even pipe
                    addrA2 := instr2(18 to 24);
                    addrB2 := instr2(11 to 17);
                    addrC2 := instr2(25 to 31);
                    rt2 := instr2(4 to 10);
                    opcode2 := instr2(0 to 3) & "0000000";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := x"0000";
                
                --RR format decode even pipe
                elsif instr2(0 to 10) = "00011001000" or instr2(0 to 10) = "00011000000" or instr2(0 to 10) = "00001001000" or instr2(0 to 10) = "00001000000" or instr2(0 to 10) = "01111000100" or instr2(0 to 10) = "01111001100" or instr2(0 to 10) = "00011000001" or instr2(0 to 10) = "00001000001" or instr2(0 to 10) = "01001000001" or instr2(0 to 10) = "00011001001" or instr2(0 to 10) = "00001001001" or instr2(0 to 10) = "01001001001" or instr2(0 to 10) = "00001011000" or instr2(0 to 10) = "00001011100" or instr2(0 to 10) = "00001011111" or instr2(0 to 10) = "00001011011" or instr2(0 to 10) = "01111001000" or instr2(0 to 10) = "01111010000" or instr2(0 to 10) = "01001001000" or instr2(0 to 10) = "01001010000" or instr2(0 to 10) = "01111000000" or instr2(0 to 10) = "01001000000" or instr2(0 to 10) = "01000000001" or instr2(0 to 10) = "01011000100" or instr2(0 to 10) = "01011000101" or instr2(0 to 10) = "01011000110" or instr2(0 to 10) = "01111000010" or instr2(0 to 10) = "01011000010" or instr2(0 to 10) = "01110111010" or instr2(0 to 10) = "01110011000" or instr2(0 to 10) = "01010110100" or instr2(0 to 10) = "01010100101" or instr2(0 to 10) = "00011010011" or instr2(0 to 10) = "00001010011" or instr2(0 to 10) = "01111000101" or instr2(0 to 10) = "01011001001" or instr2(0 to 10) = "00111110000" or instr2(0 to 10) = "01111001010" then
                    instr2pipe := '0'; -- even pipe
                    addrA2 := instr2(18 to 24);
                    addrB2 := instr2(11 to 17);
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 10);
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := x"0000";
                    
                -- --RR format decode odd pipe
                elsif instr2(0 to 10) = "00111000100" or instr2(0 to 10) = "01111011000" or instr2(0 to 10) = "01001011000" or instr2(0 to 10) = "00111011100"  or instr2(0 to 10) = "00111001100" or instr2(0 to 10) = "00111011000"  then
                    instr2pipe := '1'; -- odd pipe
                    addrA2 := instr2(18 to 24);
                    addrB2 := instr2(11 to 17);
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 10);
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := x"0000";
					
                -- false target instructions    
               elsif instr2(0 to 10) = "01000000001" then
					instr2pipe := '0'; -- even pipe
					addrA2 := instr2(18 to 24);
					addrB2 := instr2(11 to 17);
					rt2 := "0000000";
					opcode2 := instr2(0 to 10);
					PC2 := PCin2;
					timestamp2 := timestampin2;
					immediate2 := x"0000";
					
					
					
				elsif instr2(0 to 10) = "00000000001" then
					instr2pipe := '1'; -- odd pipe
					addrA2 := instr2(18 to 24);
					addrB2 := instr2(11 to 17);
					rt2 := "0000001";
					opcode2 := instr2(0 to 10);
					PC2 := PCin2;
					timestamp2 := timestampin2;
					immediate2 := x"0000";
                    
                    
                --RI7 format decode even pipe
                elsif instr2(0 to 10) = "00001111111" or instr2(0 to 10) = "00001111011" then
                    instr2pipe := '0'; -- even pipe
                    addrA2 := instr2(18 to 24);
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 10);
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := "000000000" & instr2(11 to 17);
                    
                --RI7 format decode odd pipe
                elsif instr2(0 to 10) = "00111111000" or instr2(0 to 10) = "00111111100" then
                    instr2pipe := '1'; -- odd pipe
                    addrA2 := instr2(18 to 24);
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 10);
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := "000000000" & instr2(11 to 17);       

                -- --RI10 format decode even pipe
                elsif instr2(0 to 7) = "00011101" or instr2(0 to 7) = "00011100" or instr2(0 to 7) = "00001101" or instr2(0 to 7) = "00001100" or instr2(0 to 7) = "01110100" or instr2(0 to 7) = "00010100" or instr2(0 to 7) = "00000100" or instr2(0 to 7) = "01000100" or instr2(0 to 7) = "01111100" or instr2(0 to 7) = "01111101" or instr2(0 to 7) = "01111110" or instr2(0 to 7) = "01001100" or instr2(0 to 7) = "01001101" or instr2(0 to 7) = "01001110" or instr2(0 to 7) = "00010110" or instr2(0 to 7) = "00010101" or instr2(0 to 7) = "00000101" or instr2(0 to 7) = "00000110" or instr2(0 to 7) = "01000101" or instr2(0 to 7) = "01000110" then
                    instr2pipe := '0'; -- even pipe
                    addrA2 := instr2(18 to 24);
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 7) & "000";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := "000000" & instr2(8 to 17);   
                    
                --RI10 format decode odd pipe
                elsif instr2(0 to 7) = "01111111" or instr2(0 to 7) =  "01001111" or instr2(0 to 7) = "00110100" then
                    instr2pipe := '1'; -- odd pipe
                    addrA2 := instr2(18 to 24);
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 7) & "000";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := "000000" & instr2(8 to 17);   
                
                --RI16 format decode odd pipe for rt is a value
                elsif instr2(0 to 8) = "001100000" or instr2(0 to 8) = "001000010" or instr2(0 to 8) = "001000000" or instr2(0 to 8) = "001000100" or instr2(0 to 8) = "001000110"  then
                    instr2pipe := '1'; -- odd pipe
                    addrA2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 8) & "00";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := instr2(9 to 24);      
                    
                -- RI16 for Load/ branch set link (rt is tartget)   
                elsif instr2(0 to 8) = "010000001" or instr2(0 to 8) = "001100001" or instr2(0 to 8) = "001100100" or instr2(0 to 8) = "001100010" or instr2(0 to 8) = "001100110" or instr2(0 to 8) = "010000010" or  instr2(0 to 8) = "010000011" then
                    instr2pipe := '1'; -- odd pipe
                    rt2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 8) & "00";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := instr2(9 to 24);      
                    
                --UNIQUE CASES
                -- Store d-form
                elsif instr2(0 to 7) = ("00100100") then
                    instr2pipe := '1'; -- odd pipe
                    addrC2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 7) & "000";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := "000000" & instr2(8 to 17);   
                    
                --Store X-form
                elsif instr2(0 to 10) = "00101000100" then
                    instr2pipe := '1'; -- odd pipe
                    addrA2 := instr2(18 to 24);
                    addrB2 := instr2(11 to 17);
                    addrC2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 10);
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := x"0000";
                    
                -- Store a-form
                elsif instr2(0 to 8) = "001000001" then
                    instr2pipe := '1'; -- odd pipe
                    addrC2 := instr2(25 to 31);
                    opcode2 := instr2(0 to 8) & "00";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := instr2(9 to 24);  
                    
                -- Branch Indirect
                elsif instr2(0 to 10) = "00110101000" then
                    instr2pipe := '1'; -- odd pipe
                    addrA2 := instr2(18 to 24);
                    opcode2 := instr2(0 to 10);
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := x"0000";  
                
                else
                    instr2pipe := '1'; -- even pipe
                    addrA2 := instr2(18 to 24);
                    addrB2 := instr2(11 to 17);
                    rt2 := instr2(25 to 31);
                    opcode2 := "00000000001";
                    PC2 := PCin2;
                    timestamp2 := timestampin2;
                    immediate2 := x"0000";
                    
                end if;
        -- END Instrution2 Decode-------------------------------------------------------------------------------------------        

        --Pipe Assignment---------------------------------------------------------------------------------------------------
                if branchflag /= '1' then -- If no branch flag to be executed assign pipes normally
					if (opcode1 = "11110000000" and opcode2 = "00000000001") or (opcode1 = "01000000001" and opcode2 = "00000000001") then
								 evenaddrA <= addrA1;
								 evenaddrB <= addrB1;
								 evenaddrC <= addrC1;
								 evenopcode <= opcode1;
								 evenrt  <= rt1;
								 evenPCout <= PC1;
								 evenimmediate <= immediate1;
								 eventimestampout <= timestamp1;
							
								-- odd pipe assignment
								oddaddrA <= addrA2;
								oddaddrB <= addrB2;
								oddaddrC  <= addrC2;
								oddopcode <= opcode2;
								oddrt <= rt2;
								oddPCout <= PC2;
								oddimmediate <= immediate2;
								oddtimestampout <= timestamp2;
								 test <= '0';
								hazard := '0';
								stoppc <= '0';
					
                    elsif instr1pipe = '0' and instr2pipe = '1' then -- instruction 1 is even and instruction 2 is odd
						
							if (((rt1 = rt2) or (rt1 = addrA2) or (rt1 = addrB2) or (rt1 = addrC2)) and ((opcode1 /= "00000000001") or (opcode1 /= "01000000001") or (opcode1 /= "11110000000") or opcode1 /= "01110111010" or opcode1 /= "00000000001" or  opcode1 /= "01000000001" or  opcode1 /= "00110010000" or opcode1 /= "00110000000" or opcode1 /= "00110010000" or opcode1 /= "00110101000" or opcode1 /= "00100001000" or opcode1 /= "00100000000" or opcode1 /= "00100100000"  or opcode1 /= "00100000100" or opcode1 /= "00000000001" or opcode1 /= "01000000001" or opcode1 /= "01111011000" or opcode1 /= "01111111000" or opcode1 /= "01001011000"  or opcode1 /= "01001111000" or opcode1 /= "00100010000" or opcode1 /= "00100011000") and ((opcode2 /= "00000000001") or (opcode2 /= "01000000001") or (opcode2 /= "11110000000") or opcode2 /= "01110111010" or opcode2 /= "00000000001" or  opcode2 /= "01000000001" or  opcode2 /= "00110010000" or opcode2 /= "00110000000" or opcode2 /= "00110010000" or opcode2 /= "00110101000" or opcode2 /= "00100001000" or opcode2 /= "00100000000" or opcode2 /= "00100100000"  or opcode2 /= "00100000100" or opcode2 /= "00000000001" or opcode2 /= "01000000001" or opcode2 /= "01111011000" or opcode2 /= "01111111000" or opcode2 /= "01001011000"  or opcode2 /= "01001111000" or opcode2 /= "00100010000" or opcode2 /= "00100011000")) then-- check for data hazards after decode, check if rt1 is equal to any values from instruction 2 if so delay
									--even pipe assignment
								evenaddrA <= addrA1;
								evenaddrB <= addrB1;
								evenaddrC <= addrC1;
								evenopcode <= opcode1;
								evenrt  <= rt1;
								evenPCout <= PC1;
								evenimmediate <= immediate1;
								eventimestampout <= timestamp1;
								
								oddaddrA <= "0000000";
								oddaddrB <= "0000000";
								oddaddrC <= "0000000";
								oddopcode <= "00000000001";
								oddrt  <= "0000000";
								oddPCout <= x"00000000";
								oddimmediate <= x"0000";
								oddtimestampout <= "0000";
								test <= '1';
								stoppc <= '1'; -- stop the program counter for 1 cycle 
								hazard := '1';
								
							else    -- Normal Case no hazards dectected
							--even pipe assignment
								evenaddrA <= addrA1;
								evenaddrB <= addrB1;
								evenaddrC <= addrC1;
								evenopcode <= opcode1;
								evenrt  <= rt1;
								evenPCout <= PC1;
								evenimmediate <= immediate1;
								eventimestampout <= timestamp1;
							
								-- odd pipe assignment
								oddaddrA <= addrA2;
								oddaddrB <= addrB2;
								oddaddrC  <= addrC2;
								oddopcode <= opcode2;
								oddrt <= rt2;
								oddPCout <= PC2;
								oddimmediate <= immediate2;
								oddtimestampout <= timestamp2;
								 test <= '0';
								hazard := '0';
								stoppc <= '0';
							end if;

                        elsif instr1pipe = '1' and instr2pipe = '0' then -- instruction 1 is odd and insruction 2 is even
                        if ((rt1 = rt2) or (rt1 = addrA2) or (rt1 = addrB2) or (rt1 = addrC2)) and (opcode1 /= "00000000001" or opcode1 /= "01000000001" or opcode1 /= "11110000000" or opcode1 /= "01110111010" or opcode1 /= "00000000001" or  opcode1 /= "01000000001" or  opcode1 /= "00110010000" or opcode1 /= "00110000000" or opcode1 /= "00110010000" or opcode1 /= "00110101000" or opcode1 /= "00100001000" or opcode1 /= "00100000000" or opcode1 /= "00100100000"  or opcode1 /= "00100000100" or opcode1 /= "00000000001" or opcode1 /= "01000000001" or opcode1 /= "01111011000" or opcode1 /= "01111111000" or opcode1 /= "01001011000"  or opcode1 /= "01001111000" or opcode1 /= "00100010000" or opcode1 /= "00100011000") and  (opcode2 /= "00000000001" or opcode2 /= "01000000001" or opcode2 /= "11110000000" or opcode2 /= "01110111010" or opcode2 /= "00000000001" or  opcode2 /= "01000000001" or  opcode2 /= "00110010000" or opcode2 /= "00110000000" or opcode2 /= "00110010000" or opcode2 /= "00110101000" or opcode2 /= "00100001000" or opcode2 /= "00100000000" or opcode2 /= "00100100000"  or opcode2 /= "00100000100" or opcode2 /= "00000000001" or opcode2 /= "01000000001" or opcode2 /= "01111011000" or opcode2 /= "01111111000" or opcode2 /= "01001011000"  or opcode2 /= "01001111000" or opcode2 /= "00100010000" or opcode2 /= "00100011000") then-- check for data hazards after decode, check if rt1 is equal to any values from instruction 2 if so delay
                            --even pipe assignment
                            oddaddrA <= addrA1;
                            oddaddrB <= addrB1;
                            oddaddrC <= addrC1;
                            oddopcode <= opcode1;
                            oddrt  <= rt1;
                            oddPCout <= PC1;
                            oddimmediate <= immediate1;
                            oddtimestampout <= timestamp1;
                            
                            evenaddrA <= "0000000";
                            evenaddrB <= "0000000";
                            evenaddrC <= "0000000";
                            evenopcode <= "00000000001"; --NOP
                            evenrt  <= "0000000";
                            evenPCout <= x"00000000";
                            evenimmediate <= x"0000";
                            eventimestampout <= "0000";
                           test <= '0';
                            stoppc <= '1'; -- stop the program counter for 1 cycle 
                            hazard := '1';
                        else     -- Normal case
                        --even pipe assignment
                            evenaddrA <= addrA2;
                            evenaddrB <= addrB2;
                            evenaddrC <= addrC2;
                            evenopcode <= opcode2;
                            evenrt  <= rt2;
                            evenPCout <= PC2;
                            evenimmediate <= immediate2;
                            eventimestampout <= timestamp2;
                        
                            -- odd pipe assignment
                            oddaddrA <= addrA1;
                            oddaddrB <= addrB1;
                            oddaddrC  <= addrC1;
                            oddopcode <= opcode1;
                            oddrt <= rt1;
                            oddPCout <= PC1;
                            oddimmediate <= immediate1;
                            oddtimestampout <= timestamp1;
                            test <= '0';
                            hazard := '0';
                            stoppc <= '0';
                        end if;
                    
                    elsif instr1pipe = '0' and  instr2pipe= '0' then -- instruction 1 and 2 areboth in the even pipe causes hazard
                    
                        --even pipe assignment
                        evenaddrA <= addrA1;
                        evenaddrB <= addrB1;
                        evenaddrC <= addrC1;
                        evenopcode <= opcode1;
                        evenrt  <= rt1;
                        evenPCout <= PC1;
                        evenimmediate <= immediate1;
                        eventimestampout <= timestamp1;
                        
                        oddaddrA <= "0000000";
                        oddaddrB <= "0000000";
                        oddaddrC <= "0000000";
                        oddopcode <= "00000000001";
                        oddrt  <= "0000000";
                        oddPCout <= x"00000000";
                        oddimmediate <= x"0000";
                        oddtimestampout <= "0000";
                        test <= '0';
                        stoppc <= '1'; -- stop the program counter for 1 cycle 
                        hazard := '1';
						rttest <= rt2;
                        
                    elsif instr1pipe = '1' and  instr2pipe= '1' then -- instruction 1 and 2 areboth in the odd pipe
                    
                        --even pipe assignment
                        oddaddrA <= addrA1;
                        oddaddrB <= addrB1;
                        oddaddrC <= addrC1;
                        oddopcode <= opcode1;
                        oddrt  <= rt1;
                        oddPCout <= PC1;
                        oddimmediate <= immediate1;
                        oddtimestampout <= timestamp1;
                        
                        evenaddrA <= "0000000";
                        evenaddrB <= "0000000";
                        evenaddrC <= "0000000";
                        evenopcode <= "00000000001"; --NOP
                        evenrt  <= "0000000";
                        evenPCout <= x"00000000";
                        evenimmediate <= x"0000";
                        eventimestampout <= "0000";
                        test <= '0';
                        stoppc <= '1'; -- stop the program counter for 1 cycle 
                        hazard := '1';
                    end if; -- end pip assignment if   
                        
                else -- branch case gets rid of any data hazards and overrides any decoding done this cycle
                        evenaddrA <= "0000000";
                        evenaddrB <= "0000000";
                        evenaddrC <= "0000000";
                        evenopcode <= "00000000001";
                        evenrt  <= "0000000";
                        evenPCout <= x"00000000";
                        evenimmediate <= x"0000";
                        eventimestampout <= "0000";
                    
                        -- odd pipe assignment
                        oddaddrA <= "0000000";
                        oddaddrB <= "0000000";
                        oddaddrC <= "0000000";
                        oddopcode <= "00000000001";
                        oddrt  <= "0000000";
                        oddPCout <= x"00000000";
                        oddimmediate <= x"0000";
                        oddtimestampout <= "0000";
                        test <= '0';
                        hazard := '0';
                        stoppc <= '0'; -- stop the program counter for 1 cycle 
                end if; --end branch if
            end if;-- end hazard if
--End Pipe Assignment---------------------------------------------------------------------------------------------------
    end if; --end clk and enable if
    end process;
end behavioral;
