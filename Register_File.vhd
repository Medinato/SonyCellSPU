--Register File
--David Gash
--Register File for Cell SPU
--Register file does two thing it fetches the data for processing by the execute unit 
--It also writes back data from the execute unit
--It also handles getting data for fowardings (the issue stage tells the register file where to grab the data from)


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity registerfile is
port(
    clk: in std_logic; --clock input
    enable: in std_logic; --block enable
	branchflag: in std_logic; -- branch flag needed to clear inputs if 


	
	-- EVEN INPUTS REGISTER READ
	evenaddrA: in std_logic_vector(0 to 6); --input A
	evenaddrB: in std_logic_vector(0 to 6); --input B
	evenaddrC: in std_logic_vector(0 to 6); --input C 
	evenopcode: in std_logic_vector(0 to 10);  --opcode input
	evenrt : in std_logic_vector(0 to 6);-- destination register
	evenPCin: in std_logic_vector(0 to 31); --program counter in
	evenimmediate: in std_logic_vector(0 to 15); -- immediate 16 bit input
	eventimestamp : in std_logic_vector(0 to 3); --time stamp to determine execution order
	evendatafowardA: in std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	evendatafowardB: in std_logic_vector(0 to 4); 
	evendatafowardC: in std_logic_vector(0 to 4);
	evendatafoward: in std_logic_vector(0 to 767); --data ffrom execute unit to be used for fowarding
	
	--EVEN OUTPUTS REGISTER READ
	evenopcodeout: out std_logic_vector(0 to 10);  --opcode input
	evenrtout : out std_logic_vector(0 to 6);-- destination register
	evenPCout: out std_logic_vector(0 to 31); --program counter in
	evenimmediateout: out std_logic_vector(0 to 15); -- immediate 16 bit input
	eventimestampout : out std_logic_vector(0 to 3); --time stamp to determine execution order
	evendataA: out std_logic_vector(0 to 127); --data out A
	evendataB: out std_logic_vector(0 to 127); --data out B
	evendataC: out std_logic_vector(0 to 127); --data out C
	
	-- ODD INPUTS REGISTER READ
	oddaddrA: in std_logic_vector(0 to 6); --input A
	oddaddrB: in std_logic_vector(0 to 6); --input B
	oddaddrC: in std_logic_vector(0 to 6); --input C 
	oddopcode: in std_logic_vector(0 to 10);  --opcode input
	oddrt : in std_logic_vector(0 to 6);-- destination register
	oddPCin: in std_logic_vector(0 to 31); --program counter in
	oddimmediate: in std_logic_vector(0 to 15); -- immediate 16 bit input
	oddtimestamp : in std_logic_vector(0 to 3); --time stamp to determine execution order
	odddatafowardA: in std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	odddatafowardB: in std_logic_vector(0 to 4); 
	odddatafowardC: in std_logic_vector(0 to 4);
	odddatafoward: in std_logic_vector(0 to 767); --data ffrom execute unit to be used for fowarding
	--ODD OUTPUTS REGISTER READ
	oddopcodeout: out std_logic_vector(0 to 10);  --opcode input
	oddrtout : out std_logic_vector(0 to 6);-- destination register
	oddPCout: out std_logic_vector(0 to 31); --program counter in
	oddimmediateout: out std_logic_vector(0 to 15); -- immediate 16 bit input
	oddtimestampout : out std_logic_vector(0 to 3); --time stamp to determine execution order
	odddataA: out std_logic_vector(0 to 127); --data out A
	odddataB: out std_logic_vector(0 to 127); --data out B
	odddataC: out std_logic_vector(0 to 127); --data out C
	
	--Even Register Writback
	evenrtwriteback: in std_logic_vector(0 to 6); --address to writeback
	evenregwrite: in std_logic; -- bit to determine to write reg file
	evendatawrite: in std_logic_vector(0 to 127); --data to write to reg file
	
	--ODD Register Writback
	oddrtwriteback: in std_logic_vector(0 to 6); --address to writeback
	oddregwrite: in std_logic; -- bit to determine to write reg file
	odddatawrite: in std_logic_vector(0 to 127) --data to write to reg file
	
    );
end registerfile;

architecture behavioral of registerfile is		  

subtype regaddress is std_logic_vector(0 to 127);
type regarray is array(0 to 127) of regaddress;
signal regfile: regarray;

begin
	process(enable, clk)  

	begin
		if rising_edge(clk) and enable = '1' then
		-- REGISTER READ PORTION----------------------------------------------------------------------------------------------------------------------------------	
			if branchflag /= '1' then -- if branch flag is not set do what you want to do
				-- EVEN LOOP
				evenopcodeout <= evenopcode; -- assign pass through variables
				evenrtout <= evenrt;
				evenPCout <= evenPCin;
				evenimmediateout <= evenimmediate;
				eventimestampout <= eventimestamp;
				
					--Even A Data
				if evendatafowardA(0) = '0' and evendatafowardA(1) = '0' and evendatafowardA(2 to 4) /= "000" then --data fowarding from even pipe
					evendataA <= evendatafoward(((128 * to_integer(unsigned(evendatafowardA(2 to 4))))-128) to ((128 * to_integer(unsigned(evendatafowardA(2 to 4))))-1));	
					
				elsif evendatafowardA(0) = '0' and evendatafowardA(1) = '1' and evendatafowardA(2 to 4) /= "000" then --datafowarding from odd pipe
					evendataA <= odddatafoward(((128 * to_integer(unsigned(evendatafowardA(2 to 4))))-128) to ((128 * to_integer(unsigned(evendatafowardA(2 to 4))))-1));
					
				elsif evendatafowardA = "10000" then --grab from write odd
						evendataA <= odddatawrite;
				
				elsif evendatafowardA = "10001" then-- grab from write even
						evendataA <= evendatawrite;
						
				else 
					evendataA <= regfile(to_integer(unsigned(evenaddrA))); -- normal case
				end if;
				
					--Even B Data
				if evendatafowardB(0) = '0' and evendatafowardB(1) = '0' and evendatafowardB(2 to 4) /= "000" then --data fowarding from even pipe
					evendataB <= evendatafoward(((128 * to_integer(unsigned(evendatafowardB(2 to 4))))-128) to ((128 * to_integer(unsigned(evendatafowardB(2 to 4))))-1));	
					
				elsif evendatafowardB(0) = '0' and evendatafowardB(1) = '1' and evendatafowardB(2 to 4) /= "000" then --datafowarding from odd pipe
					evendataB <= odddatafoward(((128 * to_integer(unsigned(evendatafowardB(2 to 4))))-128) to ((128 * to_integer(unsigned(evendatafowardB(2 to 4))))-1));
					
				elsif evendatafowardB = "10000" then --grab from write odd
						evendataA <= odddatawrite;
				
				elsif evendatafowardB = "10001" then-- grab from write even
						evendataB <= evendatawrite;
						
				else 
					evendataB <= regfile(to_integer(unsigned(evenaddrB))); --normal case
				end if;
				
				--Even c Data
				if evendatafowardC(0) = '0' and evendatafowardC(1) = '0' and evendatafowardC(2 to 4) /= "000" then --data fowarding from even pipe
					evendataC <= evendatafoward(((128 * to_integer(unsigned(evendatafowardC(2 to 4))))-128) to ((128 * to_integer(unsigned(evendatafowardC(2 to 4))))-1));	
					
				elsif evendatafowardC(0) = '0' and evendatafowardC(1) = '1' and evendatafowardC(2 to 4) /= "000" then --datafowarding from odd pipe
					evendataC <= odddatafoward(((128 * to_integer(unsigned(evendatafowardC(2 to 4))))-128) to ((128 * to_integer(unsigned(evendatafowardC(2 to 4))))-1));
					
				elsif evendatafowardC = "10000" then --grab from write odd
						evendataC <= odddatawrite;
				
				elsif evendatafowardC = "10001" then-- grab from write even
						evendataC <= evendatawrite;
						
				else 
					evendataC <= regfile(to_integer(unsigned(evenaddrC))); --normal case
				end if;
				
				
					
					
					
				

				--END EVEN LOOP
				--ODD LOOP
				oddopcodeout <= oddopcode; -- assign pass through variables
				oddrtout <= oddrt;
				oddPCout <= oddPCin;
				oddimmediateout <= oddimmediate;
				oddtimestampout <= oddtimestamp;
				
				--ODD A Data
				if odddatafowardA(0) = '0' and odddatafowardA(1) = '0' and odddatafowardA(2 to 4) /= "000" then --data fowarding from even pipe
					odddataA <= evendatafoward(((128 * to_integer(unsigned(odddatafowardA(2 to 4))))-128) to ((128 * to_integer(unsigned(odddatafowardA(2 to 4))))-1));	
					
				elsif odddatafowardA(0) = '0' and odddatafowardA(1) = '1' and odddatafowardA(2 to 4) /= "000" then --datafowarding from odd pipe
					odddataA <= odddatafoward(((128 * to_integer(unsigned(odddatafowardA(2 to 4))))-128) to ((128 * to_integer(unsigned(odddatafowardA(2 to 4))))-1));
					
				elsif odddatafowardA = "10000" then --grab from write odd
						odddataA <= odddatawrite;
				
				elsif odddatafowardA = "10001" then-- grab from write even
						odddataA <= evendatawrite;
				else 
					odddataA <= regfile(to_integer(unsigned(oddaddrA))); --normal case
				end if;
				
					--Even B Data
				if odddatafowardB(0) = '0' and odddatafowardB(1) = '0' and odddatafowardB(2 to 4) /= "000" then --data fowarding from even pipe
					odddataB <= evendatafoward(((128 * to_integer(unsigned(odddatafowardB(2 to 4))))-128) to ((128 * to_integer(unsigned(odddatafowardB(2 to 4))))-1));	
					
				elsif odddatafowardB(0) = '0' and odddatafowardB(1) = '1' and odddatafowardB(2 to 4) /= "000" then --datafowarding from odd pipe
					odddataB <= odddatafoward(((128 * to_integer(unsigned(odddatafowardB(2 to 4))))-128) to ((128 * to_integer(unsigned(odddatafowardB(2 to 4))))-1));
					
				elsif odddatafowardB = "10000" then --grab from write odd
						odddataA <= odddatawrite;
				
				elsif odddatafowardB = "10001" then-- grab from write even
						odddataB <= evendatawrite;
						
				else 
					odddataB <= regfile(to_integer(unsigned(oddaddrB))); --normal case
				end if;
				
				--Even c Data
				if odddatafowardC(0) = '0' and odddatafowardC(1) = '0' and odddatafowardC(2 to 4) /= "000" then --data fowarding from even pipe
					odddataC <= evendatafoward(((128 * to_integer(unsigned(odddatafowardC(2 to 4))))-128) to ((128 * to_integer(unsigned(odddatafowardC(2 to 4))))-1));	
					
				elsif odddatafowardC(0) = '0' and odddatafowardC(1) = '1' and odddatafowardC(2 to 4) /= "000" then --datafowarding from odd pipe
					odddataC <= odddatafoward(((128 * to_integer(unsigned(odddatafowardC(2 to 4))))-128) to ((128 * to_integer(unsigned(odddatafowardC(2 to 4))))-1));
					
				elsif odddatafowardC = "10000" then --grab from write odd
						odddataC <= odddatawrite;
				
				elsif odddatafowardC = "10001" then-- grab from write even
						odddataC <= evendatawrite;
						
				else 
					odddataC <= regfile(to_integer(unsigned(oddaddrC))); --normal case
				end if;
				--END ODD LOOP
				
			elsif branchflag = '1' then --if branch occurs need to erase the current command being processed
				oddopcodeout <= "01000000001";
				oddrtout <= "0000000";
				oddPCout <= oddPCin;
				oddimmediateout <= x"0000";
				oddtimestampout <= oddtimestamp;
				odddataA <= x"00000000000000000000000000000000";
				odddataB <= x"00000000000000000000000000000000";
				odddataC <= x"00000000000000000000000000000000";
				
				evenopcodeout <= "01000000001";
				evenrtout <= "0000000";
				evenPCout <= evenPCin;
				evenimmediateout <= x"0000";
				eventimestampout <= eventimestamp;
				evendataA <= x"00000000000000000000000000000000";
				evendataB <= x"00000000000000000000000000000000";
				evendataC <= x"00000000000000000000000000000000";
			
			end if;
------------ END REGISTER READ PORTION----------------------------------------------------------------------------------------------------------------------------------	
------------  REGISTER Write Back PORTION----------------------------------------------------------------------------------------------------------------------------------	
		-- EVEN PIPE
			if evenregwrite = '1' then -- check flag for write
				regfile(to_integer(unsigned(evenrtwriteback))) <= evendatawrite; --wirte data if flag 1
			end if;
			--END EVEN PIPE
			
			--ODD PIPE
			if oddregwrite = '1' then --check flag for write
				regfile(to_integer(unsigned(oddrtwriteback))) <= odddatawrite; --write data if flag 1
			end if;
			-- END ODD PIPE


------------  ENG REGISTER Write Back PORTION----------------------------------------------------------------------------------------------------------------------------------	
		end if;
	
	end process;
end behavioral;