--Execute Unit
--David Gash
--Executes SPU instructions


--Library Declartion usage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity execute is
port(
--universal sginals
    clk: in std_logic; --clock input
    enable: in std_logic; --block enable
	halt: out std_logic; --halt signal
	branchflagout: out std_logic;
	
	datacleared: out std_logic;
	pcbranch: out std_logic_vector(0 to 31);
	--signals for odd pipe
    oddinputA: in std_logic_vector(0 to 127); --input A
	oddinputB: in std_logic_vector(0 to 127); --input B
	oddinputC: in std_logic_vector(0 to 127); --input C 
	oddopcode: in std_logic_vector(0 to 10);  --opcode input
	oddrt : in std_logic_vector(0 to 6); --destination register
	oddPCin: in std_logic_vector(0 to 31); --program counter in
	oddimmediate: in std_logic_vector(0 to 15); -- immediate 16 bit input
	oddtimestamp: in std_logic_vector(0 to 3); -- time stamp to determine exectution order
	oddout: out std_logic_vector(0 to 308); -- output to register file stage
	oddfoward: out std_logic_vector(0 to 767); --data for fowarding
	odddataavail: out std_logic_vector(0 to 6); --data in pipe available;
	
	-- signal for even pipe
	
	eveninputA: in std_logic_vector(0 to 127); --input A
	eveninputB: in std_logic_vector(0 to 127); --input B
	eveninputC: in std_logic_vector(0 to 127); --input C 
	evenopcode: in std_logic_vector(0 to 10);  --opcode input
	evenrt : in std_logic_vector(0 to 6);-- destination register
	evenPCin: in std_logic_vector(0 to 31); --program counter in
	evenimmediate: in std_logic_vector(0 to 15); -- immediate 16 bit input
	eventimestamp : in std_logic_vector(0 to 3); --time stamp to determine execution order
	evenfoward: out std_logic_vector(0 to 767); -- output to file stage
	evendataavail: out std_logic_vector(0 to 6); --data in pipe slot is available
	evenout: out std_logic_vector(0 to 308); -- output to register file stage
	
	cacheloadout: out std_logic_vector(0 to 1049); -- output for cahce loading
	
	bootloaden: in std_logic;
	bootloader: in std_logic_vector(0 to 31)
	
    );
end execute;

architecture behavioral of execute is
--Signals to define portmap to aluodd unit
	signal oddenablealu: std_logic := '0'; --block enable
    signal oddopcodealu: std_logic_vector (0 to 10); -- op code input
    signal oddindataAalu: std_logic_vector (0 to 127); -- input register 1
    signal oddindataBalu: std_logic_vector (0 to 127); -- input register 2
	signal oddindataCalu: std_logic_vector(0 to 127); --input register 3
	signal oddindataIalu: std_logic_vector(0 to 15); --input for I16 Immediate Values
	signal oddpccurrentalu: std_logic_vector(0 to 31);
	signal oddbranchflagalu: std_logic; --bit that signals a branch output
	signal oddpcnextalu: std_logic_vector(0 to 31);  -- output for branch instructions IS THIS needd??
    signal oddoutdataalu: std_logic_vector (0 to 127); --single register output
	signal odddepthalu: std_logic_vector(0 to 2);
	signal oddunitalu: std_logic_vector(0 to 2);
	signal oddreadmemalu: std_logic;
	signal oddwritememalu: std_logic;
	signal oddwriteregalu: std_logic;
	signal oddtimestampalu: std_logic_vector(0 to 3);
	signal oddhaltalu: std_logic;
	signal storevaluealu: std_logic_vector(0 to 127);
	
	--Signals to define portmap to aluodd unit
	signal evenenablealu: std_logic := '0'; --block enable
    signal evenopcodealu: std_logic_vector (0 to 10); -- op code input
    signal evenindataAalu: std_logic_vector (0 to 127); -- input register 1
    signal evenindataBalu: std_logic_vector (0 to 127); -- input register 2
	signal evenindataCalu: std_logic_vector(0 to 127); --input register 3
	signal evenindataIalu: std_logic_vector(0 to 15); --input for I16 Immediate Values
	signal evenpccurrentalu: std_logic_vector(0 to 31);
	signal evenbranchflagalu: std_logic; --bit that signals a branch output
	signal evenpcnextalu: std_logic_vector(0 to 31);  -- output for branch instructions IS THIS needd??
    signal evenoutdataalu: std_logic_vector (0 to 127); --single register output
	signal evendepthalu: std_logic_vector(0 to 2);
	signal evenunitalu: std_logic_vector(0 to 2);
	signal evenreadmemalu: std_logic;
	signal evenwritememalu: std_logic;
	signal evenwriteregalu: std_logic;
	signal eventimestampalu: std_logic_vector(0 to 3);	 
	signal oddrtalu: std_logic_vector(0 to 6);
	signal evenrtalu: std_logic_vector(0 to 6);
	
	signal ishalt: std_logic_vector(0 to 1);   
	signal test: std_logic;
	
	type outq is array (0 to 5) of std_logic_vector(0 to 308);
	signal oddoutq: outq; --output queue structure for the pipeline
	signal evenoutq: outq; --output queue structure for even pipline
	--Load Store Memory Declartion 
	subtype memline is std_logic_vector(0 to 127);
	type memarray is array(0 to 2048) of memline;
	signal loadstore: memarray;
	-- output queue for cahce instructions
	type cacheq is array (0 to 5) of std_logic_vector(0 to 1049);
	signal cachequeue: cacheq;

begin
--port map the alu unit
	aluodd : entity work.aluodd port map(
		enable => oddenablealu,
		opcode => oddopcodealu,
		indataA => oddindataAalu,
		indataB => oddindataBalu,
		indataC => oddindataCalu,
		indataI => oddindataIalu,
		pccurrent => oddpccurrentalu,
		branchflag => oddbranchflagalu,
		pcnext => oddpcnextalu,
		outdata => oddoutdataalu,
		depth => odddepthalu,
		unit => oddunitalu,
		readmem => oddreadmemalu,
		writemem => oddwritememalu,
		writereg => oddwriteregalu,
		timestamp => oddtimestampalu,
		halt => oddhaltalu,
		storevalue => storevaluealu
   );
   --send data to alu unit to execute
	oddopcodealu <= oddopcode;
	oddenablealu <= enable;
	oddindataAalu <= oddinputA;
	oddindataBalu <= oddinputB;
	oddindataCalu <= oddinputC;
	oddindataIalu <= oddimmediate;
	oddpccurrentalu <= oddPCin;
	oddtimestampalu <= oddtimestamp;  
	oddrtalu <= oddrt;
	--process data

	
	--port map the alu unit
	alueven : entity work.alueven port map(
		enable => evenenablealu,
		opcode => evenopcodealu,
		indataA => evenindataAalu,
		indataB => evenindataBalu,
		indataC => evenindataCalu,
		indataI => evenindataIalu,
		pccurrent => evenpccurrentalu,
		branchflag => evenbranchflagalu,
		pcnext => evenpcnextalu,
		outdata => evenoutdataalu,
		depth => evendepthalu,
		unit => evenunitalu,
		readmem => evenreadmemalu,
		writemem => evenwritememalu,
		writereg => evenwriteregalu,
		timestamp => eventimestampalu
   );
   --send data to alu unit to execute
	evenopcodealu <= evenopcode;
	evenenablealu <= enable;
	evenindataAalu <= eveninputA;
	evenindataBalu <= eveninputB;
	evenindataCalu <= eveninputC;
	evenindataIalu <= evenimmediate;
	evenpccurrentalu <= evenPCin;
	eventimestampalu <= eventimestamp;	  
	evenrtalu <= evenrt;
	--process data
process (clk, enable)
--variables for cache control
variable tag: std_logic_vector(0 to 22);
variable index: std_logic_vector(0 to 1);
variable data: std_logic_vector(0 to 1023);
variable valid : std_logic;

variable branchalertodd: std_logic;
variable branchalerteven: std_logic;

variable memaddress: std_logic_vector(0 to 10) := "00000000000"; -- variable to control address written to memory
variable linectrl: std_logic_vector(0 to 1) := "00";

begin
	if rising_edge(clk) and enable = '1' then --if rising edge  and enable = 1 ie valid opcode in the pipeodd
	
		if evenopcode = "11110000000" then -- check if load cache instruction if so process it
			tag := evenPCin(0 to 22);
			index := evenPCin(23 to 24);
			data(0 to 127) := loadstore(to_integer(unsigned(tag & index) & "000"));
			data(128 to 255) := loadstore(to_integer(unsigned(tag & index) & "001"));
			data(256 to 383) := loadstore(to_integer(unsigned(tag & index) & "010"));
			data(384 to 511) := loadstore(to_integer(unsigned(tag & index) & "011"));
			data(512 to 639) := loadstore(to_integer(unsigned(tag & index) & "100"));
			data(640 to 767) := loadstore(to_integer(unsigned(tag & index) & "101"));
			data(768 to 895) := loadstore(to_integer(unsigned(tag & index) & "110"));
			data(896 to 1023) := loadstore(to_integer(unsigned(tag & index) & "111"));
			
			valid := '1';
		else
			tag := "00000000000000000000000"; --otherwise zero out cache q
			index := "00" ;
			data := (others => '0');
			valid := '0';
		
		end if;
-------------ODD PIPE-------------------------------------------------------------------------------------------------------------------------------------------	
		
		-- OUPUT DATAT after 7 cyctles
		oddout <= oddoutq(5); -- output data
		oddfoward <= oddoutq(0)(13 to 140) & oddoutq(1)(13 to 140) & oddoutq(2)(13 to 140) & oddoutq(3)(13 to 140) & oddoutq(4)(13 to 140) & oddoutq(5)(13 to 140); --data for fowarding pruposes
		
		for I in 0 to 3 loop -- figure out if data is available odd 
			if oddoutq(I)(4) = '0' and oddoutq(I)(5) = '0' and oddoutq(I)(6) = '0' and oddoutq(I)(174) = '0' then --check if no flags are set (ie no op)
				odddataavail(I + 2) <= '0';	
			elsif to_integer(unsigned(oddoutq(I)(306 to 308))) <=  I + 3 then--check for data available
				odddataavail(I + 2) <= '1';
			else
				odddataavail(I + 2) <= '0';
							
			end if;
		end loop;  
		
		if odddepthalu = "010" then
			odddataavail(1) <= '1';
		else	
			odddataavail(1) <= '0';
		end if;	
		
		odddataavail(0) <= '0';  
		odddataavail(6) <= '1';
			
		if oddoutq(2)(173) = '1' then --if branch flag in the 3rd slot has branch flag set clear the the first 3 in the q
			oddoutq(5) <= oddoutq(4);  
			oddoutq(4) <= oddoutq(3);  
			oddoutq(3) <= oddoutq(2);
			oddoutq(2) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & oddpcnextalu & "0" & oddtimestampalu & x"00000000000000000000000000000000" & odddepthalu;
			oddoutq(1) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & oddpcnextalu & "0" & oddtimestampalu & x"00000000000000000000000000000000" & odddepthalu;
			oddoutq(0) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & oddpcnextalu & "0" & oddtimestampalu & x"00000000000000000000000000000000" & odddepthalu;   
			
			pcbranch <= oddoutq(2)(141 to 172); -- set branch target address
			halt<= '0'; --
			branchflagout <= '1';
			branchalertodd := '1';
			
		elsif branchalertodd = '1' then
			oddoutq(5) <= oddoutq(4);  
			oddoutq(4) <= oddoutq(3);  
			oddoutq(3) <= oddoutq(2);
			oddoutq(2) <= oddoutq(1);
			oddoutq(1) <= oddoutq(0);
			oddoutq(0) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & oddpcnextalu & "0" & oddtimestampalu & x"00000000000000000000000000000000" & odddepthalu; 
			
			branchalertodd := '0';
			branchflagout <= '0';
			
		else -- normal case update queue
			oddoutq(5) <= oddoutq(4);  
			oddoutq(4) <= oddoutq(3);  
			oddoutq(3) <= oddoutq(2);
			oddoutq(2) <= oddoutq(1);
			oddoutq(1) <= oddoutq(0);
			oddoutq(0) <= oddunitalu & oddreadmemalu & oddwritememalu & oddwriteregalu & oddrtalu & oddoutdataalu & oddpcnextalu & oddbranchflagalu & oddtimestampalu & storevaluealu & odddepthalu;
			
			
			ishalt(1) <= ishalt(0);
			ishalt(0) <= oddhaltalu;	
			branchflagout <= '0';	
	
		end if;
		
	
		-- Mem Write Stuff
		if oddoutq(4)(4) = '1' then --Check mem write flag if 1 write data
		
			loadstore(to_integer(unsigned(oddoutq(4)(13 to 44))))(0 to 127) <= oddoutq(4)(178 to 305);-- Store Command writes to Memory
			test <= '1';
		elsif oddoutq(4)(3) = '1' then --Check readmem flag if 1 loead memory
		
			oddoutq(5)(0 to 12) <= oddoutq(4)(0 to 12);
			oddoutq(5)(13 to 140) <= loadstore(to_integer(unsigned(oddoutq(4)(13 to 44))));
			oddoutq(5)(141 to 308) <= oddoutq(4)(141 to 308);
		end if;	
		
		if ishalt(1) = '1' then
			halt <= '1';
		end if;	
		
--------- END ODD PIPE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	
-------------EVEN PIPE-------------------------------------------------------------------------------------------------------------------------------------------
	--see comments on odd pipe for even pipe
		evenout <= evenoutq(5);
		evenfoward <= evenoutq(0)(13 to 140) & evenoutq(1)(13 to 140) & evenoutq(2)(13 to 140) & evenoutq(3)(13 to 140) & evenoutq(4)(13 to 140) & evenoutq(5)(13 to 140); --data for fowarding pruposes
		
		for I in 0 to 3 loop -- figure out if data is available odd 
			if evenoutq(I)(4) = '0' and evenoutq(I)(5) = '0' and evenoutq(I)(6) = '0' and evenoutq(I)(174) = '0' then --check if no flags are set (ie no op)
				evendataavail(I + 2) <= '0';	
			elsif to_integer(unsigned(evenoutq(I)(306 to 308))) <=  I + 3 then--check for data available
				evendataavail(I + 2) <= '1';
			else
				evendataavail(I + 2) <= '0';
							
			end if;
		end loop;  
		
		if evendepthalu = "010" then
			evendataavail(1) <= '1';
		else	
			evendataavail(1) <= '0';
		end if;	
		
		evendataavail(0) <= '0';  
		evendataavail(6) <= '1';
	
		if oddoutq(2)(173) = '1' then --if branch flag in the 3rd s;ot has branch flag set clear the the first 3 in the q
			if unsigned(evenoutq(2)(174 to 177)) < unsigned(oddoutq(2)(174 to 177)) then --check timestamp on command if even came before execute it otherwise discard result.
				evenoutq(5) <= evenoutq(4);  
				evenoutq(4) <= evenoutq(3);  
				evenoutq(3) <= evenoutq(2);
				evenoutq(2) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu;
				evenoutq(1) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu;
				evenoutq(0) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu; 
				datacleared <= '0';
			else 
				evenoutq(5) <= evenoutq(4);  
				evenoutq(4) <= evenoutq(3);  
				evenoutq(3) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu;
				evenoutq(2) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu;
				evenoutq(1) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu;
				evenoutq(0) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu;
				datacleared <= '1';
				
			end if;
			branchalerteven := '1';
			
		elsif branchalerteven = '1' then
			evenoutq(5) <= evenoutq(4);  
			evenoutq(4) <= evenoutq(3);  
			evenoutq(3) <= evenoutq(2);
			evenoutq(2) <= evenoutq(1);
			evenoutq(1) <= evenoutq(0);
			evenoutq(0) <= "000" & "0" & "0" & "0" & "0000000" & x"00000000000000000000000000000000" & evenpcnextalu & "0" & eventimestampalu &  x"00000000000000000000000000000000" & evendepthalu; 
			
			branchalerteven := '0';
		
		else -- normal case
			evenoutq(5) <= evenoutq(4);  
			evenoutq(4) <= evenoutq(3);  
			evenoutq(3) <= evenoutq(2);
			evenoutq(2) <= evenoutq(1);
			evenoutq(1) <= evenoutq(0);
			evenoutq(0) <= evenunitalu & evenreadmemalu & evenwritememalu & evenwriteregalu & evenrtalu & evenoutdataalu & evenpcnextalu & evenbranchflagalu & eventimestampalu & x"00000000000000000000000000000000" & evendepthalu;
		end if;
	-- END EVEN PIPE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
		--update cache q 
		cacheloadout <= cachequeue(5);
		cachequeue(5) <= cachequeue(4);
		cachequeue(4) <= cachequeue(3);
		cachequeue(3) <= cachequeue(2);
		cachequeue(2) <= cachequeue(1);
		cachequeue(1) <= cachequeue(0);
		cachequeue(0) <= valid & tag & index & data;
	end if;		 
	
	--Bootloader Section writes instructions to memory starting at address 0
	  if (enable = '0' and bootloaden = '1' and rising_edge(clk)) then	  
				
		if linectrl = "00" then
			loadstore(to_integer(unsigned(memaddress)))(0 to 31) <= bootloader;
		elsif linectrl = "01" then
			loadstore(to_integer(unsigned(memaddress)))(32 to 63) <= bootloader;
		elsif linectrl = "10" then
			loadstore(to_integer(unsigned(memaddress)))(64 to 95) <= bootloader;
		elsif linectrl = "11" then
			loadstore(to_integer(unsigned(memaddress)))(96 to 127) <= bootloader;
		end if;
		
		if linectrl = "11" then
			linectrl := "00";
			memaddress := std_logic_vector(unsigned(memaddress) + "00000000001");
		else
			linectrl := std_logic_vector(unsigned(linectrl) + "01");
		end if;	 
	end if;
		
		
		


end process;



end behavioral;