# CELL SPU ASSEMBLY LANGUAGE PARSER
# BY DAVID GASH
# 106564738
# Uses Python 2.7
## File takes parse file written in assembly code in location C:\user\dgash\desktop\parse.txt
## and writes code to copy and paste into test bench for the Cell SPU in file named
# C:\users\dgash\desktop\TB.txt
###########################################################################################################
## FUNCTION TO DECODE RR Type Instructions
def RRdecode(instruction):
    split1 = instruction.split()
    split2 = split1[1].split(',')

    tempa = split2[1][1:]
    tempb = split2[2][1:]
    tempt = split2[0][1:]

    registerA = bin(int(tempa))[2:].zfill(7)
    registerB = bin(int(tempb))[2:].zfill(7)
    registerT = bin(int(tempt))[2:].zfill(7)

    return [registerB, registerA, registerT]


##End Function to decode RR Functions
##################################################################################################

###########################################################################################################
## FUNCTION TO DECODE RRR Type Instructions
def RRRdecode(instruction):
    split1 = instruction.split()
    split2 = split1[1].split(',')

    tempa = split2[1][1:]
    tempb = split2[2][1:]
    tempc = split2[3][1:]
    tempt = split2[0][1:]

    registerA = bin(int(tempa))[2:].zfill(7)
    registerB = bin(int(tempb))[2:].zfill(7)
    registerC = bin(int(tempa))[2:].zfill(7)
    registerT = bin(int(tempt))[2:].zfill(7)

    return [registerT, registerB, registerA, registerC]


##End Function to decode RRR Functions
##################################################################################################

###########################################################################################################
## FUNCTION TO DECODE RI10 Type Instructions
def RI10decode(instruction):
    split1 = instruction.split()
    split2 = split1[1].split(',')

    tempa = split2[1][1:]
    tempI = split2[2]
    tempt = split2[0][1:]

    registerA = bin(int(tempa))[2:].zfill(7)
    if tempI[0] == '-':
        immediate = bin(int(tempI) & 0b1111111111)[2:]
    else:
        immediate = bin(int(tempI))[2:].zfill(10)
    registerT = bin(int(tempt))[2:].zfill(7)

    return [immediate, registerA, registerT]


##End Function to decode RI10 Functions
##################################################################################################

###########################################################################################################
## FUNCTION TO DECODE RI16 Type Instructions
def RI16decode(instruction):
    split1 = instruction.split()
    split2 = split1[1].split(',')

    tempI = split2[1]
    tempt = split2[0][1:]

    if tempI[0] == '-':
        immediate = bin(int(tempI) & 0b1111111111111111)[2:]
    else:
        immediate = bin(int(tempI))[2:].zfill(16)

    registerT = bin(int(tempt))[2:].zfill(7)

    return [immediate, registerT]


##End Function to decode RI16 Functions
##################################################################################################

###########################################################################################################
## FUNCTION TO DECODE RI7 Type Instructions
def RI7decode(instruction):
    split1 = instruction.split()
    split2 = split1[1].split(',')

    tempa = split2[1][1:]
    tempI = split2[2]
    tempt = split2[0][1:]

    registerA = bin(int(tempa))[2:].zfill(7)
    if tempI[0] == '-':
        immediate = bin(int(tempI) & 0b1111111)[2:]
    else:
        immediate = bin(int(tempI))[2:].zfill(7)
    registerT = bin(int(tempt))[2:].zfill(7)

    return [immediate, registerA, registerT]


##End Function to decode RI7 Functions
##################################################################################################

###########################################################################################################
## FUNCTION TO DECODE Branch Compares Type Instructions
def branchcomp(instruction):
    split1 = instruction.split()
    split2 = split1[1].split(',')

    branchloc = split2[1]

    # get program counter value for final PC to be issues
    for i in range(len(labels)):
        if labels[i] == branchloc:
            PCfinal = 4 * int(indexlabels[i])

    difference = (PCfinal - 4 * index) / 4  ## get difference for the math to make into I16 value

    if difference < 0:
        immediate = bin(difference & 0b1111111111111111)[2:]
    else:
        immediate = bin(difference)[2:].zfill(16)

    tempt = split2[0][1:]
    registerT = bin(int(tempt))[2:].zfill(7)

    return [immediate, registerT]


##End Function to decode RR Functions
##################################################################################################

EOF = False

instr = []  # list to hold instructions parsed
labels = []  # list to hold labels for branch statements
indexlabels = []  # list to hold index values for each label
index = 0  # list to hold the current program counter value (index *4)

with open('C:\\Users\\dgash\\Desktop\\parse.txt') as file:
    while EOF == False:
        dataraw = file.readline()
        if dataraw is "":
            EOF = True

        else:

            seperate = dataraw.split(':')  # seperate label

            if len(seperate) == 1:
                instruction = seperate[0]  # set instrcution for decode
                index = index + 1
            else:
                instruction = seperate[1]
                labels.append(seperate[0])  ## append the label to the list holding the labels
                indexlabels.append(index)
                index += 1

    EOF = False
    index = 0
with open('C:\\Users\\dgash\\Desktop\\parse.txt') as file:
    while EOF == False:
        # Reset and Get next line of Data
        dataraw = file.readline()
        if dataraw is "":
            EOF = True
        else:
            seperate = dataraw.split(':')  # seperate label

            if len(seperate) == 1:
                instruction = seperate[0]  # set instrcution for decode
            else:
                instruction = seperate[1]

            test = instruction.split()  # seperate nemonic out for decode

            ############################################################################################################
            ## Add Halfword
            if test[0] == "ah":
                opcode = "00011001000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################
                ############################################################################################################
                ## Add Word
            if test[0] == "a":
                opcode = "00011000000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Subtract From Halfword
            if test[0] == "sfh":
                opcode = "00001001000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Subtract From Word
            if test[0] == "sf":
                opcode = "00001000000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Multiply
            if test[0] == "mpy":
                opcode = "01111000100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Multiply Unsigned
            if test[0] == "mpyu":
                opcode = "01111001100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## And
            if test[0] == "and":
                opcode = "00011000001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Or
            if test[0] == "or":
                opcode = "00001000001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Xor
            if test[0] == "xor":
                opcode = "01001000001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Nand
            if test[0] == "nand":
                opcode = "00011001001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Nor
            if test[0] == "nor":
                opcode = "00001001001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Equvialent
            if test[0] == "eqv":
                opcode = "01001001001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Rotate Word
            if test[0] == "rot":
                opcode = "00001011000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Rotate Halfword
            if test[0] == "roth":
                opcode = "00001011100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Shift Left Halfword
            if test[0] == "shlh":
                opcode = "00001011111"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Shift Left Word
            if test[0] == "shl":
                opcode = "00001011011"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Halfword
            if test[0] == "ceqh":
                opcode = "01111001000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Byte
            if test[0] == "ceqb":
                opcode = "01111010000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Byte
            if test[0] == "ceqb":
                opcode = "01111010000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Greater Than Halfword
            if test[0] == "cgth":
                opcode = "01001001000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Greater Than Byte
            if test[0] == "cgtb":
                opcode = "01001010000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Word
            if test[0] == "ceq":
                opcode = "01111000000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Greater Than Word
            if test[0] == "cgt":
                opcode = "01001000000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Add
            if test[0] == "fa":
                opcode = "01011000100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Subtract
            if test[0] == "fs":
                opcode = "01011000101"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Multiply
            if test[0] == "fm":
                opcode = "01011000110"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Compare Equal
            if test[0] == "fceq":
                opcode = "01111000010"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Compare Equal
            if test[0] == "fceq":
                opcode = "01111000010"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Compare Greater THan
            if test[0] == "fcgt":
                opcode = "01011000010"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Average Bytes
            if test[0] == "avgb":
                opcode = "00011010011"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Absolute Difference of Bytes
            if test[0] == "absdb":
                opcode = "00001010011"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Rotate Quadword By bytes
            if test[0] == "rotqby":
                opcode = "00111011100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Rotate Quadword By Bit Shift Count
            if test[0] == "rotqbybi":
                opcode = "00111001100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Rotate Quadword By Bits
            if test[0] == "rotqbi":
                opcode = "00111011000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Multiply High
            if test[0] == "mpyh":
                opcode = "01111000101"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Or With Complement
            if test[0] == "orc":
                opcode = "01011001001"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Or Accross
            if test[0] == "orx":
                opcode = "00111110000"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Floating Compare Magnitude Equal
            if test[0] == "fcmeq":
                opcode = "01111001010"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Load Quadword (x-form)
            if test[0] == "lqx":
                opcode = "00111000100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Store Quadword (x-form)
            if test[0] == "stqx":
                opcode = "00101000100"
                tempRR = RRdecode(instruction)
                instr.append(opcode + tempRR[0] + tempRR[1] + tempRR[2])
                ############################################################################################################

                ############################################################################################################
                ## Add halfword Immediate
            if test[0] == "ahi":
                opcode = "00011101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Add Word Immediate
            if test[0] == "ai":
                opcode = "00011100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Subtract From Halfword Immediate
            if test[0] == "sfhi":
                opcode = "00001101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Subtract From Word Immediate
            if test[0] == "sfi":
                opcode = "00001100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Multiply Immediate
            if test[0] == "mpyi":
                opcode = "01110100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## And Immediate
            if test[0] == "andi":
                opcode = "00010100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## And Word Immediate
            if test[0] == "andi":
                opcode = "00010100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Or Word Immediate
            if test[0] == "ori":
                opcode = "00000100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Xor Word Immediate
            if test[0] == "xori":
                opcode = "01000100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Word Immediate
            if test[0] == "ceqi":
                opcode = "01111100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Halfword Immediate
            if test[0] == "ceqhi":
                opcode = "01111101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Equal Byte Immediate
            if test[0] == "ceqbi":
                opcode = "01111110"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## And Byte Immediate
            if test[0] == "andbi":
                opcode = "00010110"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## And Halfword Immediate
            if test[0] == "andhi":
                opcode = "00010101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Or Halfword Immediate
            if test[0] == "orhi":
                opcode = "00000101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Or Byte Immediate
            if test[0] == "orbi":
                opcode = "00000110"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Xor Halfword Immediate
            if test[0] == "xorhi":
                opcode = "01000101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Xor Byte Immediate
            if test[0] == "xorbi":
                opcode = "01000110"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Greater Than Word Immediate
            if test[0] == "cgti":
                opcode = "01001100"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Greater Than Halfword Immediate
            if test[0] == "cgthi":
                opcode = "01001101"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Compare Greater Than Byte Immediate
            if test[0] == "cgtbi":
                opcode = "01001110"
                tempRI10 = RI10decode(instruction)
                instr.append(opcode + tempRI10[0] + tempRI10[1] + tempRI10[2])
                ############################################################################################################

                ############################################################################################################
                ## Immediate Load Word
            if test[0] == "il":
                opcode = "010000001"
                tempRI16 = RI16decode(instruction)
                instr.append(opcode + tempRI16[0] + tempRI16[1])
                ############################################################################################################

                ############################################################################################################
                ## Immediate Load Halfword Upper
            if test[0] == "ilhu":
                opcode = "010000010"
                tempRI16 = RI16decode(instruction)
                instr.append(opcode + tempRI16[0] + tempRI16[1])
                ############################################################################################################

                ############################################################################################################
                ## Immediate Load Halfword
            if test[0] == "ilh":
                opcode = "010000011"
                tempRI16 = RI16decode(instruction)
                instr.append(opcode + tempRI16[0] + tempRI16[1])
                ############################################################################################################

                ############################################################################################################
                ## Shift Left Halfword Immediate
            if test[0] == "shlhi":
                opcode = "00001111111"
                tempRI7 = RI7decode(instruction)
                instr.append(opcode + tempRI7[0] + tempRI7[1] + tempRI7[2])
                ############################################################################################################

                ############################################################################################################
                ## Shift Left Word Immediate
            if test[0] == "shli":
                opcode = "00001111011"
                tempRI7 = RI7decode(instruction)
                instr.append(opcode + tempRI7[0] + tempRI7[1] + tempRI7[2])
                ############################################################################################################

                ############################################################################################################
                ##  Rotate Quadword by Bits Immediate
            if test[0] == "rotqbii":
                opcode = "00111111000"
                tempRI7 = RI7decode(instruction)
                instr.append(opcode + tempRI7[0] + tempRI7[1] + tempRI7[2])
                ############################################################################################################

                ############################################################################################################
                ##  Rotate Quadword by Bytes Immediate
            if test[0] == "rotqbyi":
                opcode = "00111111100"
                tempRI7 = RI7decode(instruction)
                instr.append(opcode + tempRI7[0] + tempRI7[1] + tempRI7[2])
                ############################################################################################################

                ############################################################################################################
                ##  Branch Relative
            if test[0] == "br":
                opcode = "001100100"

                split = instruction.split()
                branchloc = split[1]

                # get program counter value for final PC to be issues
                for i in range(len(labels)):
                    if labels[i] == branchloc:
                        PCfinal = 4 * int(indexlabels[i])

                difference = (PCfinal - 4 * index) / 4  ## get difference for the math to make into I16 value

                if difference < 0:
                    immediate = bin(difference & 0b1111111111111111)[2:]
                else:
                    immediate = bin(difference)[2:].zfill(16)

                instr.append(opcode + immediate + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Branch Absolute
            if test[0] == "bra":
                opcode = "001100000"

                split = instruction.split()
                branchloc = split[1]

                # get program counter value for final PC to be issues
                for i in range(len(labels)):
                    if labels[i] == branchloc:
                        PCfinal = int(indexlabels[i])

                        immediate = bin(PCfinal)[2:].zfill(16)

                instr.append(opcode + immediate + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Branch If Not Zero Word
            if test[0] == "brnz":
                opcode = "001000010"
                tempbranch = branchcomp(instruction)
                instr.append(opcode + tempbranch[0] + tempbranch[1])
                ############################################################################################################

                ############################################################################################################
                ##  Branch If Zero Word
            if test[0] == "brz":
                opcode = "001000000"
                tempbranch = branchcomp(instruction)
                instr.append(opcode + tempbranch[0] + tempbranch[1])
                ############################################################################################################

                ############################################################################################################
                ##  Branch If Not Zero Halfword
            if test[0] == "brhnz":
                opcode = "001000110"
                tempbranch = branchcomp(instruction)
                instr.append(opcode + tempbranch[0] + tempbranch[1])
                ############################################################################################################

                ############################################################################################################
                ##  Branch If Zero Halfword
            if test[0] == "brhz":
                opcode = "001000100"
                tempbranch = branchcomp(instruction)
                instr.append(opcode + tempbranch[0] + tempbranch[1])
                ############################################################################################################

                ############################################################################################################
                ##  Branch Relative and Set Link
            if test[0] == "brsl":
                opcode = "001100110"
                tempbranch = branchcomp(instruction)
                instr.append(opcode + tempbranch[0] + tempbranch[1])
                ############################################################################################################

                ############################################################################################################
                ##  Branch Absolute and Set Link
            if test[0] == "brasl":
                opcode = "001100010"

                split1 = instruction.split()
                split2 = split1[1].split(',')
                branchloc = split2[1]

                # get program counter value for final PC to be issues
                for i in range(len(labels)):
                    if labels[i] == branchloc:
                        PCfinal = int(indexlabels[i])

                        immediate = bin(PCfinal)[2:].zfill(16)

                tempt = split2[0][1:]
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + immediate + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Nop(execute)
            if test[0] == "nop":
                opcode = "01000000001"
                instr.append(opcode + "000000000000000000000")
                ############################################################################################################

                ############################################################################################################
                ##  Nop(load)
            if test[0] == "lnop":
                opcode = "00000000001"
                instr.append(opcode + "000000000000000000000")
                ############################################################################################################

                ############################################################################################################
                ##  Count Ones in Bytes
            if test[0] == "cntb":
                opcode = "01010110100"
                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempa = split2[0][1:]
                tempt = split2[1][1:]

                registerA = bin(int(tempa))[2:].zfill(7)
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + "0000000" + registerA + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Count Ones in Bytes
            if test[0] == "clz":
                opcode = "01010100101"
                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempa = split2[0][1:]
                tempt = split2[1][1:]

                registerA = bin(int(tempa))[2:].zfill(7)
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + "0000000" + registerA + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Load Quardword (d-form)
            if test[0] == "lqd":
                opcode = "00110100"
                split1 = instruction.split()
                split2 = split1[1].split(',')
                split3 = split2[1].split("(")
                split4 = split3[1].split(')')

                tempt = split2[0][1:]
                tempI = int(split3[0]) / 16
                tempa = split4[0][1:]

                registerA = bin(int(tempa))[2:].zfill(7)
                if tempI < 0:
                    immediate = bin(int(tempI) & 0b1111111111)[2:]
                else:
                    immediate = bin(int(tempI))[2:].zfill(10)
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + immediate + registerA + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Load Quardword (a-form)
            if test[0] == "lqa":
                opcode = "001100001"

                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempt = split2[0][1:]
                tempI = int(split2[1]) / 4

                if tempI < 0:
                    immediate = bin(int(tempI) & 0b1111111111111111)[2:]
                else:
                    immediate = bin(int(tempI))[2:].zfill(16)
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + immediate + registerT)
                ############################################################################################################


                ############################################################################################################
                ##  Store Quardword (d-form)
            if test[0] == "stqd":
                opcode = "00100100"
                split1 = instruction.split()
                split2 = split1[1].split(',')
                split3 = split2[1].split("(")
                split4 = split3[1].split(')')

                tempt = split2[0][1:]
                tempI = int(split3[0]) / 16
                tempa = split4[0][1:]

                registerA = bin(int(tempa))[2:].zfill(7)
                immediate = bin(int(tempI))[2:].zfill(10)
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + immediate + registerA + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Store Quardword (a-form)
            if test[0] == "stqa":
                opcode = "001000001"

                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempt = split2[0][1:]
                tempI = int(split2[1]) / 4

                if tempI < 0:
                    immediate = bin(int(tempI) & 0b1111111111111111)[2:]
                else:
                    immediate = bin(int(tempI))[2:].zfill(16)
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + immediate + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Mutliply and Add
            if test[0] == "mpya":
                opcode = "1100"
                tempRRR = RRRdecode(instruction)
                instr.append(opcode + tempRRR[0] + tempRRR[1] + tempRRR[2] + tempRRR[3])
                ############################################################################################################

                ############################################################################################################
                ##  Mutliply and Add
            if test[0] == "fma":
                opcode = "1110"
                tempRRR = RRRdecode(instruction)
                instr.append(opcode + tempRRR[0] + tempRRR[1] + tempRRR[2] + tempRRR[3])
                ############################################################################################################

                ############################################################################################################
                ##  Floating Point Status and Control Register Write
            if test[0] == "fscrwr":
                opcode = "01110111010"

                split1 = instruction.split()

                tempa = split1[1][1:]
                registerA = bin(int(tempa))[2:].zfill(7)

                instr.append(opcode + "0000000" + registerA + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Floating Point Status and Control Register Read
            if test[0] == "fscrrd":
                opcode = "01110011000"

                split1 = instruction.split()

                tempt = split1[1][1:]
                registerT = bin(int(tempt))[2:].zfill(7)

                instr.append(opcode + "0000000" + "0000000" + registerT)
                ############################################################################################################

                ############################################################################################################
                ##  Branch Indirect
            if test[0] == "bi":
                opcode = "00110101000"

                split1 = instruction.split()

                tempa = split1[1][1:]
                registerA = bin(int(tempa))[2:].zfill(7)

                instr.append(opcode + "0000000" + registerA + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Halt if Equal
            if test[0] == "heq":
                opcode = "01111011000"

                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempa = split2[0][1:]
                tempb = split2[1][1:]
                registerA = bin(int(tempa))[2:].zfill(7)
                registerB = bin(int(tempb))[2:].zfill(7)

                instr.append(opcode + registerB + registerA + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Halt if Greater Than
            if test[0] == "hgt":
                opcode = "01001011000"

                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempa = split2[0][1:]
                tempb = split2[1][1:]
                registerA = bin(int(tempa))[2:].zfill(7)
                registerB = bin(int(tempb))[2:].zfill(7)

                instr.append(opcode + registerB + registerA + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Halt if Equal Immediate
            if test[0] == "heqi":
                opcode = "01111111"

                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempa = split2[0][1:]
                tempI = split2[1]

                registerA = bin(int(tempa))[2:].zfill(7)
                if tempI[0] == '-':
                    immediate = bin(int(tempI) & 0b1111111111)[2:]
                else:
                    immediate = bin(int(tempI))[2:].zfill(10)

                instr.append(opcode + immediate + registerA + "0000000")
                ############################################################################################################

                ############################################################################################################
                ##  Halt if Greater Than Immediate
            if test[0] == "hgti":
                opcode = "01001111"

                split1 = instruction.split()
                split2 = split1[1].split(',')

                tempa = split2[0][1:]
                tempI = split2[1]

                registerA = bin(int(tempa))[2:].zfill(7)
                if tempI[0] == '-':
                    immediate = bin(int(tempI) & 0b1111111111)[2:]
                else:
                    immediate = bin(int(tempI))[2:].zfill(10)

                instr.append(opcode + immediate + registerA + "0000000")
                ############################################################################################################
            index = index + 1
# end Parse section






#################################################################################################################
# Write File Portion#
st1 = ""
firstflag = False
for i in range(len(instr)):
    if firstflag == False:
        st1 = "bootloader <= " + '"' + instr[0] + '"' + ','
        firstflag = True
    elif i == len(instr) - 1:
        st1 = st1 + '"' + instr[i] + '"' + " after %d *period;\n" % (i + 1,)
    else:
        st1 = st1 + '"' + instr[i] + '"' + " after %d *period," % (i + 1,)

st2 = "bootload_en <= '1' after 1 * period, '0' after %d* period;\n" % (len(instr) + 1,)

with open('C:\\Users\\dgash\\Desktop\\TB.txt', "w") as TBfile:
    TBfile.truncate

    TBfile.write(st1)
    TBfile.write(st2)

print("File Parsed")
