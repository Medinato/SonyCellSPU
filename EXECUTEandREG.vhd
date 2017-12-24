

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
------------------------------------------------------------

entity cellSPU is
port(
	clk : in std_logic;	
--Bootloader to load instructions to memory
	bootload_en: in std_logic;
	bootloader : in std_logic_vector(0 to 31)
	
    );
end cellSPU;

architecture behavioral of cellSPU is

--Signals to define portmap to register file
--Program Counter Signals
	signal clkPC: std_logic;
    signal enablePC: std_logic := '0'; --block enable
	signal branchflagPC: std_logic; -- branch flag needed to clear inputs if 
	signal stoppcPC: std_logic; -- stop pc if structural hazard
	signal branchpcinPC: std_logic_vector(0 to 31); -- value from branch 
	signal cacheloadinPC: std_logic_vector(0 to 1049); -- data input for 
	signal instr1PC: std_logic_vector(0 to 31);
	signal PC1PC: std_logic_vector(0 to 31);
	signal timestamp1PC: std_logic_vector( 0 to 3);
	signal instr2PC: std_logic_vector(0 to 31);
	signal PC2PC: std_logic_vector(0 to 31);
	signal timestamp2PC: std_logic_vector( 0 to 3);

-- Decode Signals  
	signal clkd: std_logic; --clock input
    signal enabled: std_logic := '0'; --block enable
	signal branchflagd: std_logic; -- branch flag needed to clear inputs if 
	signal stoppcd: std_logic; -- stop pc if structural hazard
	signal datahazardd: std_logic; -- flag to 
	signal instr1d: std_logic_vector(0 to 31);
	signal PCin1d: std_logic_vector(0 to 31);
	signal timestampin1d: std_logic_vector( 0 to 3);
	signal instr2d: std_logic_vector(0 to 31);
	signal PCin2d: std_logic_vector(0 to 31);
	signal timestampin2d: std_logic_vector( 0 to 3);
	signal evenaddrAd: std_logic_vector(0 to 6); --input A
	signal evenaddrBd: std_logic_vector(0 to 6); --input B
	signal evenaddrCd: std_logic_vector(0 to 6); --input C 
	signal evenopcoded: std_logic_vector(0 to 10);  --opcode input
	signal evenrtd: std_logic_vector(0 to 6);-- destination register
	signal evenPCoutd: std_logic_vector(0 to 31); --program counter in
	signal evenimmediated: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal eventimestampoutd: std_logic_vector(0 to 3); --time stamp to determine execution orde
	signal oddaddrAd: std_logic_vector(0 to 6); --input A
	signal oddaddrBd: std_logic_vector(0 to 6); --input B
	signal oddaddrCd: std_logic_vector(0 to 6); --input C 
	signal oddopcoded: std_logic_vector(0 to 10);  --opcode input
	signal oddrtd: std_logic_vector(0 to 6);-- destination register
	signal oddPCoutd: std_logic_vector(0 to 31); --program counter in
	signal oddimmediated: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal oddtimestampoutd: std_logic_vector(0 to 3); --time stamp to determine execution order	
	
--Issue Signals
	signal clki: std_logic; --clock input
    signal enablei: std_logic := '0'; --block enable
	signal branchflagi: std_logic; -- branch flag needed to clear inputs if 
	signal cleareveni: std_logic; --1 means extra data was cleared during even branch
	signal hazardi: std_logic; -- signal to stop decode and pc stage from processing if hazard occurs
	signal evenaddrAini: std_logic_vector(0 to 6); --input A
	signal evenaddrBini: std_logic_vector(0 to 6); --input B
	signal evenaddrCini: std_logic_vector(0 to 6); --input C 
	signal evenopcodeini: std_logic_vector(0 to 10);  --opcode input
	signal evenrtini: std_logic_vector(0 to 6);-- destination register
	signal evenPCini: std_logic_vector(0 to 31); --program counter in
	signal evenimmediateini: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal eventimestampoutini: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal evendataavailini: std_logic_vector(0 to 6);
	signal oddaddrAini: std_logic_vector(0 to 6); --input A
	signal oddaddrBini: std_logic_vector(0 to 6); --input B
	signal oddaddrCini: std_logic_vector(0 to 6); --input C 
	signal oddopcodeini: std_logic_vector(0 to 10);  --opcode input
	signal oddrtini: std_logic_vector(0 to 6);-- destination register
	signal oddPCini: std_logic_vector(0 to 31); --program counter in
	signal oddimmediateini: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal oddtimestampoutini: std_logic_vector(0 to 3); --time stamp to determine execution order	
	signal odddataavailini: std_logic_vector(0 to 6);
	signal evenaddrAouti: std_logic_vector(0 to 6); --input A
	signal evenaddrBouti: std_logic_vector(0 to 6); --input B
	signal evenaddrCouti: std_logic_vector(0 to 6); --input C 
	signal evenopcodeouti: std_logic_vector(0 to 10);  --opcode input
	signal evenrtouti: std_logic_vector(0 to 6);-- destination register
	signal evenPCouti: std_logic_vector(0 to 31); --program counter in
	signal evenimmediateouti: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal eventimestampouti: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal evendatafowardAouti: std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	signal evendatafowardBouti: std_logic_vector(0 to 4); 
	signal evendatafowardCouti: std_logic_vector(0 to 4);
	signal oddaddrAouti: std_logic_vector(0 to 6); --input A
	signal oddaddrBouti: std_logic_vector(0 to 6); --input B
	signal oddaddrCouti: std_logic_vector(0 to 6); --input C 
	signal oddopcodeouti: std_logic_vector(0 to 10);  --opcode input
	signal oddrtouti: std_logic_vector(0 to 6);-- destination register
	signal oddPCouti: std_logic_vector(0 to 31); --program counter in
	signal oddimmediateouti: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal oddtimestampouti: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal odddatafowardAouti: std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	signal odddatafowardBouti: std_logic_vector(0 to 4); 
	signal odddatafowardCouti: std_logic_vector(0 to 4);

-- Register File Signals
	signal clkrf: std_logic; --clock input
    signal enablerf: std_logic := '0'; --block enable
	signal branchflagrf: std_logic; -- branch flag needed to clear inputs if 
	signal grabfromwriteevenCinrf: std_logic_vector(0 to 1);
	signal grabfromwriteevenAinrf: std_logic_vector(0 to 1);
	signal grabfromwriteevenBinrf: std_logic_vector(0 to 1);
	signal grabfromwriteoddCinrf: std_logic_vector(0 to 1);
	signal grabfromwriteoddAinrf: std_logic_vector(0 to 1);
	signal grabfromwriteoddBinrf: std_logic_vector(0 to 1);
	signal evenaddrArf: std_logic_vector(0 to 6); --input A
	signal evenaddrBrf: std_logic_vector(0 to 6); --input B
	signal evenaddrCrf: std_logic_vector(0 to 6); --input C 
	signal evenopcoderf: std_logic_vector(0 to 10);  --opcode input
	signal evenrtrf: std_logic_vector(0 to 6);-- destination register
	signal evenPCinrf: std_logic_vector(0 to 31); --program counter in
	signal evenimmediaterf: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal eventimestamprf: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal evendatafowardArf: std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	signal evendatafowardBrf: std_logic_vector(0 to 4); 
	signal evendatafowardCrf: std_logic_vector(0 to 4);
	signal evendatafowardrf: std_logic_vector(0 to 767); --data ffrom execute unit to be used for fowarding
	signal evenopcodeoutrf: std_logic_vector(0 to 10);  --opcode input
	signal evenrtoutrf: std_logic_vector(0 to 6);-- destination register
	signal evenPCoutrf: std_logic_vector(0 to 31); --program counter in
	signal evenimmediateoutrf: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal eventimestampoutrf:std_logic_vector(0 to 3); --time stamp to determine execution order
	signal evendataArf: std_logic_vector(0 to 127); --data out A
	signal evendataBrf: std_logic_vector(0 to 127); --data out B
	signal evendataCrf: std_logic_vector(0 to 127); --data out 
	signal oddaddrArf: std_logic_vector(0 to 6); --input A
	signal oddaddrBrf: std_logic_vector(0 to 6); --input B
	signal oddaddrCrf: std_logic_vector(0 to 6); --input C 
	signal oddopcoderf: std_logic_vector(0 to 10);  --opcode input
	signal oddrtrf: std_logic_vector(0 to 6);-- destination register
	signal oddPCinrf: std_logic_vector(0 to 31); --program counter in
	signal oddimmediaterf: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal oddtimestamprf: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal odddatafowardArf: std_logic_vector(0 to 4); --data to foward if 0 no fowarding
	signal odddatafowardBrf: std_logic_vector(0 to 4); 
	signal odddatafowardCrf: std_logic_vector(0 to 4);
	signal odddatafowardrf: std_logic_vector(0 to 767); --data ffrom execute unit to be used for fowarding
	signal oddopcodeoutrf: std_logic_vector(0 to 10);  --opcode input
	signal oddrtoutrf: std_logic_vector(0 to 6);-- destination register
	signal oddPCoutrf: std_logic_vector(0 to 31); --program counter in
	signal oddimmediateoutrf: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal oddtimestampoutrf: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal odddataArf: std_logic_vector(0 to 127); --data out A
	signal odddataBrf: std_logic_vector(0 to 127); --data out B
	signal odddataCrf: std_logic_vector(0 to 127); --data out C
	signal evenrtwritebackrf: std_logic_vector(0 to 6); --address to writeback
	signal evenregwriterf: std_logic; -- bit to determine to write reg file
	signal evendatawriterf: std_logic_vector(0 to 127); --data to write to reg file
	signal oddrtwritebackrf: std_logic_vector(0 to 6); --address to writeback
	signal oddregwriterf: std_logic; -- bit to determine to write reg file
	signal odddatawriterf: std_logic_vector(0 to 127); --data to write to reg file

-- Execute Signals
    signal clkexe: std_logic; --clock input
    signal enableexe: std_logic := '0'; --block enable
	signal haltexe: std_logic; --halt signal
	signal dataclearedexe: std_logic;
	signal pcbranchexe: std_logic_vector(0 to 31);
    signal oddinputAexe: std_logic_vector(0 to 127); --input A
	signal oddinputBexe: std_logic_vector(0 to 127); --input B
	signal oddinputCexe: std_logic_vector(0 to 127); --input C 
	signal oddopcodeexe: std_logic_vector(0 to 10);  --opcode input
	signal oddrtexe: std_logic_vector(0 to 6); --destination register
	signal oddPCinexe: std_logic_vector(0 to 31); --program counter in
	signal oddimmediateexe: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal oddtimestampexe: std_logic_vector(0 to 3); -- time stamp to determine exectution order
	signal oddoutexe: std_logic_vector(0 to 308); -- output to register file stage
	signal oddfowardexe: std_logic_vector(0 to 767); --data for fowarding
	signal odddataavailexe: std_logic_vector(0 to 6); --data in pipe available;
	signal eveninputAexe: std_logic_vector(0 to 127); --input A
	signal eveninputBexe: std_logic_vector(0 to 127); --input B
	signal eveninputCexe: std_logic_vector(0 to 127); --input C 
	signal evenopcodeexe: std_logic_vector(0 to 10);  --opcode input
	signal evenrtexe: std_logic_vector(0 to 6);-- destination register
	signal evenPCinexe: std_logic_vector(0 to 31); --program counter in
	signal evenimmediateexe: std_logic_vector(0 to 15); -- immediate 16 bit input
	signal eventimestampexe: std_logic_vector(0 to 3); --time stamp to determine execution order
	signal evenfowardexe: std_logic_vector(0 to 767); -- output to file stage
	signal evendataavailexe: std_logic_vector(0 to 6); --data in pipe slot is available
	signal evenoutexe: std_logic_vector(0 to 308); -- output to register file stage
	signal cacheloadoutexe: std_logic_vector(0 to 1049); -- output for cahce loading
	signal bootloadenexe: std_logic;
	signal bootloaderexe: std_logic_vector(0 to 31);
	signal branchflagoutexe: std_logic;
	
begin
-- Port Map For Program Counter
ProgramCounter : entity work.programcounter port map(
	clk => clkPC,
    enable => enablePC,
	branchflag => branchflagPC, 
	stoppc => stoppcPC,
	branchpcin => branchpcinPC,
	cacheloadin => cacheloadinPC,
	instr1 => instr1PC,
	PC1 => PC1PC,
	timestamp1 => timestamp1PC,
	instr2 => instr2PC,
	PC2 => PC2PC,
	timestamp2 => timestamp2PC
   );

--Decode Port Map   
decode : entity work.decode port map(
	clk => clkd,
    enable => enabled,
	branchflag => branchflagd,
	stoppc => stoppcd,
	datahazard => datahazardd,
	instr1 => instr1d,
	PCin1 => PCin1d,
	timestampin1 => timestampin1d,
	instr2 => instr2d,
	PCin2 => PCin2d,
	timestampin2 => timestampin2d,
	evenaddrA => evenaddrAd,
	evenaddrB => evenaddrBd,
	evenaddrC => evenaddrCd,
	evenopcode => evenopcoded,
	evenrt => evenrtd,
	evenPCout => evenPCoutd,
	evenimmediate => evenimmediated,
	eventimestampout => eventimestampoutd,
	oddaddrA => oddaddrAd,
	oddaddrB => oddaddrBd,
	oddaddrC => oddaddrCd,
	oddopcode => oddopcoded,
	oddrt => oddrtd,
	oddPCout => oddPCoutd,
	oddimmediate => oddimmediated,
	oddtimestampout => oddtimestampoutd
   );
 
-- Issue Stage Port Map 
issue : entity work.issue port map(
	clk => clki,
    enable => enablei,
	branchflag => branchflagi,
	cleareven => cleareveni,
	hazard => hazardi,
	evenaddrAin => evenaddrAini,
	evenaddrBin => evenaddrBini,
	evenaddrCin => evenaddrCini,
	evenopcodein => evenopcodeini,
	evenrtin => evenrtini,
	evenPCin => evenPCini,
	evenimmediatein => evenimmediateini,
	eventimestampoutin => eventimestampoutini,
	evendataavailin => evendataavailini,
	oddaddrAin => oddaddrAini,
	oddaddrBin => oddaddrBini,
	oddaddrCin => oddaddrCini,
	oddopcodein => oddopcodeini,
	oddrtin => oddrtini,
	oddPCin => oddPCini,
	oddimmediatein => oddimmediateini,
	oddtimestampoutin => oddtimestampoutini,
	odddataavailin => odddataavailini,
	evenaddrAout => evenaddrAouti,
	evenaddrBout => evenaddrBouti,
	evenaddrCout => evenaddrCouti,
	evenopcodeout => evenopcodeouti,
	evenrtout => evenrtouti,
	evenPCout => evenPCouti,
	evenimmediateout => evenimmediateouti,
	eventimestampout => eventimestampouti,
	evendatafowardAout => evendatafowardAouti,
	evendatafowardBout => evendatafowardBouti,
	evendatafowardCout => evendatafowardCouti,
	oddaddrAout => oddaddrAouti,
	oddaddrBout => oddaddrBouti,
	oddaddrCout => oddaddrCouti,
	oddopcodeout => oddopcodeouti,
	oddrtout => oddrtouti,
	oddPCout => oddPCouti,
	oddimmediateout => oddimmediateouti,
	oddtimestampout => oddtimestampouti,
	odddatafowardAout => odddatafowardAouti,
	odddatafowardBout => odddatafowardBouti,
	odddatafowardCout => odddatafowardCouti
   );
   

--Register File Port Map
registerfile : entity work.registerfile port map(
	clk => clkrf,
    enable => enablerf,
	branchflag => branchflagrf,
	evenaddrA => evenaddrArf,
	evenaddrB => evenaddrBrf,
	evenaddrC => evenaddrCrf,
	evenopcode => evenopcoderf,
	evenrt => evenrtrf,
	evenPCin => evenPCinrf,
	evenimmediate => evenimmediaterf,
	eventimestamp => eventimestamprf,
	evendatafowardA => evendatafowardArf,
	evendatafowardB => evendatafowardBrf,
	evendatafowardC => evendatafowardCrf,
	evendatafoward => evendatafowardrf,
	evenopcodeout => evenopcodeoutrf,
	evenrtout => evenrtoutrf,
	evenPCout => evenPCoutrf,
	evenimmediateout => evenimmediateoutrf,
	eventimestampout => eventimestampoutrf,
	evendataA => evendataArf,
	evendataB => evendataBrf,
	evendataC => evendataCrf,
	oddaddrA => oddaddrArf,
	oddaddrB => oddaddrBrf,
	oddaddrC => oddaddrCrf,
	oddopcode => oddopcoderf,
	oddrt => oddrtrf,
	oddPCin => oddPCinrf,
	oddimmediate => oddimmediaterf,
	oddtimestamp => oddtimestamprf,
	odddatafowardA => odddatafowardArf,
	odddatafowardB => odddatafowardBrf,
	odddatafowardC => odddatafowardCrf,
	odddatafoward => odddatafowardrf,
	oddopcodeout => oddopcodeoutrf,
	oddrtout => oddrtoutrf,
	oddPCout => oddPCoutrf,
	oddimmediateout => oddimmediateoutrf,
	oddtimestampout => oddtimestampoutrf,
	odddataA => odddataArf,
	odddataB => odddataBrf,
	odddataC => odddataCrf,
	evenrtwriteback => evenrtwritebackrf,
	evenregwrite => evenregwriterf,
	evendatawrite => evendatawriterf,
	oddrtwriteback => oddrtwritebackrf,
	oddregwrite => oddregwriterf,
	odddatawrite => odddatawriterf
   );
	
--port map the alu unit
execute : entity work.execute port map(
	clk => clkexe,
    enable => enableexe,
	halt => haltexe,
	datacleared => dataclearedexe,
	pcbranch => pcbranchexe,
    oddinputA => oddinputAexe,
	oddinputB => oddinputBexe,
	oddinputC => oddinputCexe,
	oddopcode => oddopcodeexe,
	oddrt => oddrtexe,
	oddPCin => oddPCinexe,
	oddimmediate => oddimmediateexe,
	oddtimestamp => oddtimestampexe,
	oddout => oddoutexe,
	oddfoward => oddfowardexe,
	odddataavail => odddataavailexe,
	eveninputA => eveninputAexe,
	eveninputB => eveninputBexe,
	eveninputC => eveninputCexe,
	evenopcode => evenopcodeexe,
	evenrt => evenrtexe,
	evenPCin => evenPCinexe,
	evenimmediate => evenimmediateexe,
	eventimestamp => eventimestampexe,
	evenfoward => evenfowardexe,
	evendataavail => evendataavailexe,
	evenout => evenoutexe,
	cacheloadout => cacheloadoutexe,
	bootloaden => bootloadenexe,
	bootloader => bootloaderexe,
	branchflagout => branchflagoutexe
   );	   
   
--Program Counter Inputs
	clkPC <= clk;
	branchflagPC <= branchflagoutexe;
	stoppcPC <= stoppcd;
	branchpcinPC <= pcbranchexe;
	cacheloadinPC <= cacheloadoutexe; 
 
-- Decode Inputs
	clkd <= clk;
	branchflagd <= branchflagoutexe;
	datahazardd <= hazardi;
	instr1d <= instr1PC;
	PCin1d <= PC1PC;
	timestampin1d <= timestamp1PC;
	instr2d <= instr2PC;
	PCin2d <= PC2PC;
	timestampin2d <= timestamp2PC;

-- Issue Stage Inputs
	clki <= clk;
	branchflagi <= branchflagoutexe;
	cleareveni <= dataclearedexe;
	evenaddrAini <= evenaddrAd;
	evenaddrBini <= evenaddrBd;
	evenaddrCini <= evenaddrCd;
	evenopcodeini <= evenopcoded;
	evenrtini <= evenrtd;
	evenPCini <= evenPCoutd;
	evenimmediateini <= evenimmediated;
	eventimestampoutini <= eventimestampoutd;
	evendataavailini <= evendataavailexe;
	oddaddrAini <= oddaddrAd;
	oddaddrBini <= oddaddrBd;
	oddaddrCini <= oddaddrCd;
	oddopcodeini <= oddopcoded;
	oddrtini <= oddrtd;
	oddPCini <= oddPCoutd;
	oddimmediateini <= oddimmediated;
	oddtimestampoutini <= oddtimestampoutd;
	odddataavailini <= odddataavailexe;

-- Register File Inputs
	clkrf <= clk;
	branchflagrf <= branchflagoutexe;
	evenaddrArf <= evenaddrAouti;
	evenaddrBrf <= evenaddrBouti;
	evenaddrCrf <= evenaddrCouti;
	evenopcoderf <= evenopcodeouti;
	evenrtrf <= evenrtouti;
	evenPCinrf <= evenPCouti;
	evenimmediaterf <= evenimmediateouti;
	eventimestamprf <= eventimestampouti;
	evendatafowardArf <= evendatafowardAouti;
	evendatafowardBrf <= evendatafowardBouti;
	evendatafowardCrf <= evendatafowardCouti;
	evendatafowardrf <= evenfowardexe;
	oddaddrArf <= oddaddrAouti;
	oddaddrBrf <= oddaddrBouti;
	oddaddrCrf <= oddaddrCouti;
	oddopcoderf <= oddopcodeouti;
	oddrtrf <= oddrtouti;
	oddPCinrf <= oddPCouti;
	oddimmediaterf <= oddimmediateouti;
	oddtimestamprf <= oddtimestampouti;
	odddatafowardArf <= odddatafowardAouti;
	odddatafowardBrf <= odddatafowardBouti;
	odddatafowardCrf <= odddatafowardCouti;
	odddatafowardrf <= oddfowardexe;
	evenrtwritebackrf <= evenoutexe(6 to 12);
	evenregwriterf <= evenoutexe(5);
	evendatawriterf <= evenoutexe(13 to 140);
	oddrtwritebackrf <= oddoutexe(6 to 12);
	oddregwriterf <= oddoutexe(5);
	odddatawriterf <= oddoutexe(13 to 140);

-- Execute Unit Port Map
	clkexe <= clk;
    oddinputAexe <= odddataArf;
	oddinputBexe <= odddataBrf;
	oddinputCexe <= odddataCrf;
	oddopcodeexe <= oddopcodeoutrf;
	oddrtexe <= oddrtoutrf;
	oddPCinexe <= oddPCoutrf;
	oddimmediateexe <= oddimmediateoutrf;
	oddtimestampexe <= oddtimestampoutrf;
	eveninputAexe <= evendataArf;
	eveninputBexe <= evendataBrf;
	eveninputCexe <= evendataCrf;
	evenopcodeexe <= evenopcodeoutrf;
	evenrtexe <= evenrtoutrf;
	evenPCinexe <= evenPCoutrf;
	evenimmediateexe <= evenimmediateoutrf;
	eventimestampexe <= eventimestampoutrf;
	bootloadenexe <= bootload_en;
	bootloaderexe <= bootloader;
	

--bootloader process
process(clk, bootload_en, haltexe)
begin
	if bootload_en = '1' or haltexe = '1' then
		enablePC <= '0';
		enabled <= '0';
		enablei <= '0';
		enablerf <= '0';
		enableexe <= '0'; 
	elsif bootload_en = '0' then
		enablePC <= '1';
		enabled <= '1';
		enablei <= '1';
		enablerf <= '1';
		enableexe <= '1'; 
	end if;
end process;
	
end behavioral;
























