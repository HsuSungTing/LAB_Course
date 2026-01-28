import random
from bitstring import Bits

# ==================================================
f_DRAM_data = open('./DRAM_data.dat', 'r')
f_DRAM_inst = open('./DRAM_inst.dat', 'r')
f_new_DRAM_inst = open('./new_DRAM_inst.dat', 'w')

kPATNUM = 1000
kAddrMin = 0x1000
kAddrMax = 0x1fff
kFunction = ['ADD', 'SUB', 'SetLessThan', 'Mult', 'Load', 'Store', 'BranchOnEqual', 'Jump']
kOffset = 0x1000

core_reg = [0 for _ in range(16)]
DRAM_data = {}
DRAM_inst = {}
operation_cnt = {'ADD': 0, 'SUB': 0, 'SetLessThan': 0, 'Mult': 0, 'Load': 0,
                 'Store': 0, 'BranchOnEqual': 0, 'Jump': 0}

# ------------------- Helpers -------------------
def char2int(c):
    if '0' <= c <= '9':
        return ord(c) - ord('0')
    elif c == 'a':
        return 10
    elif c == 'b':
        return 11
    elif c == 'c':
        return 12
    elif c == 'd':
        return 13
    elif c == 'e':
        return 14
    elif c == 'f':
        return 15

def read_DRAM(f, DRAM):
    lines = [line.rstrip() for line in f]
    for i in range(0, len(lines), 2):
        addr = lines[i].replace('@', '')
        value = char2int(lines[i+1][3])*16*16*16 + char2int(lines[i+1][4])*16*16 + char2int(lines[i+1][0])*16 + char2int(lines[i+1][1])
        DRAM[addr] = value

# ------------------- Instruction Generator -------------------
def create_inst(pc):
    func = random.choice(kFunction)
    rs = '{:0>4b}'.format(random.randint(0, 15), 'x')
    rt = '{:0>4b}'.format(random.randint(0, 15), 'x')
    rd = '{:0>4b}'.format(random.randint(0, 15), 'x')
    immediate = '{:0>5b}'.format(random.randint(0, 31), 'x')

    if func == 'ADD':
        inst = '000' + rs + rt + rd + '1'  # ADD func bit = 1
    elif func == 'SUB':
        inst = '000' + rs + rt + rd + '0'  # SUB func bit = 0
    elif func == 'SetLessThan':
        inst = '001' + rs + rt + rd + '1'  # SLT func bit = 1
    elif func == 'Mult':
        inst = '001' + rs + rt + rd + '0'  # Mult func bit = 0
    elif func == 'Load':
        inst = '011' + rs + rt + immediate  # Load opcode = 011
    elif func == 'Store':
        inst = '010' + rs + rt + immediate  # Store opcode = 010
    elif func == 'BranchOnEqual':
        immediate = '{:0>5b}'.format(random.randint(0, 15), 'x')
        inst = '101' + rs + rt + immediate  # Branch opcode = 101
    elif func == 'Jump':
        a = max(kAddrMin, pc - 64 + 1)
        b = min(kAddrMax, pc + 64)
        a = a + 64
        b = b + 2000
        a = max(kAddrMin, a)
        b = min(kAddrMax, b)
        addr_int = random.randint(a, b)
        if addr_int % 2 == 1:
            addr_int -= 1
        addr = '{:0>13b}'.format(addr_int, 'x')
        inst = '100' + addr  # Jump opcode = 100

    return Bits(bin=inst).uint

# ------------------- Simulator -------------------
def simulate(pc):
    patcnt = 0
    recreate_cnt = 0
    while True:
        # reset guard variables each loop
        new_flag = 0
        new_pc = None

        inst = '{:0>16b}'.format(DRAM_inst['{:0>4x}'.format(pc, 'x')])
        opcode = inst[0:3]
        rs = inst[3:7]
        rt = inst[7:11]
        rd = inst[11:15]
        rs_int = int(inst[3:7], 2)
        rt_int = int(inst[7:11], 2)
        rd_int = int(inst[11:15], 2)
        func = inst[15]
        imm = inst[11:16]
        imm_int = Bits(bin=imm).int
        addr = inst[3:16]

        # 16-bits integer range : -32,768 to 32,767
        is_legal = 0
        if opcode == '000' and func == '1':  # ADD
            print('ADD')
            temp = core_reg[rs_int] + core_reg[rt_int]
            if -32768 <= temp <= 32767:
                operation_cnt['ADD'] += 1
                core_reg[rd_int] = temp
                is_legal = True
        elif opcode == '000' and func == '0':  # SUB
            print('SUB')
            temp = core_reg[rs_int] - core_reg[rt_int]
            if -32768 <= temp <= 32767:
                operation_cnt['SUB'] += 1
                core_reg[rd_int] = temp
                is_legal = True
        elif opcode == '001' and func == '1':  # SetLessThan
            print('SetLessThan')
            if core_reg[rs_int] < core_reg[rt_int]:
                core_reg[rd_int] = 1
            else:
                core_reg[rd_int] = 0
            operation_cnt['SetLessThan'] += 1
            is_legal = True
        elif opcode == '001' and func == '0':  # Mult
            print('Mult')
            temp = core_reg[rs_int] * core_reg[rt_int]
            if -32768 <= temp <= 32767:
                operation_cnt['Mult'] += 1
                core_reg[rd_int] = temp
                is_legal = True
        elif opcode == '011':  # Load
            print('Load')
            temp = (core_reg[rs_int] + imm_int) * 2 + kOffset
            if kAddrMin <= temp <= kAddrMax:
                operation_cnt['Load'] += 1
                core_reg[rt_int] = DRAM_data['{:0>4x}'.format(temp, 'x')]
                is_legal = True
        elif opcode == '010':  # Store
            print('Store')
            temp = (core_reg[rs_int] + imm_int) * 2 + kOffset
            if kAddrMin <= temp <= kAddrMax:
                operation_cnt['Store'] += 1
                DRAM_data['{:0>4x}'.format(temp, 'x')] = core_reg[rt_int]
                is_legal = True
        elif opcode == '101':  # BranchOnEqual
            print('BranchOnEqual')
            temp = pc + 2 + imm_int * 2
            if kAddrMin <= temp <= kAddrMax and temp % 2 == 0:
                operation_cnt['BranchOnEqual'] += 1
                if core_reg[rs_int] == core_reg[rt_int]:
                    print("yes")
                    new_pc = temp
                    new_flag = 1
                else:
                    new_flag = 0
                is_legal = True
        elif opcode == '100':  # Jump
            print('Jump')
            temp_ = '000' + addr
            temp = Bits(bin=temp_).int
            print(temp_ + ' : ' + str(temp))
            if kAddrMin <= temp <= kAddrMax and temp % 2 == 0:
                print('from '+str(pc)+' to '+str(temp))
                operation_cnt['Jump'] += 1
                new_pc = temp
                is_legal = True
        else:
            print('Error: wrong instruction ' + inst)
            exit(-1)

        # --------- Update PC ---------
        if is_legal == True:
            patcnt += 1
            # Jump (opcode '100') -> unconditional jump to new_pc (if set)
            if opcode == '100' and new_pc is not None:
                pc = new_pc
            # Branch (opcode '101') -> only change PC if branch taken (new_flag == 1)
            elif opcode == '101' and new_flag == 1 and new_pc is not None:
                pc = new_pc
            else:
                pc = pc + 2

            if patcnt == kPATNUM:
                break
            print('\n')
        else:
            recreate_cnt += 1
            new_inst = create_inst(pc)
            print('{:0>4x}'.format(pc, 'x') + ' : ' + 'recreate instruction')
            print('old : ' + '{:0>16b}'.format(DRAM_inst['{:0>4x}'.format(pc, 'x')], 'x') + '\tnew : ' + '{:0>16b}'.format(new_inst, 'x'))
            DRAM_inst['{:0>4x}'.format(pc, 'x')] = new_inst

        if patcnt % 100 == 0:
            print_core_reg()

    return recreate_cnt

# ------------------- DRAM Write -------------------
def write_DRAM(DRAM):
    for i in range(kAddrMin, kAddrMax, 2):
        addr_str = '{:0>4x}'.format(i)
        f_new_DRAM_inst.write('@' + addr_str + '\n')
        temp = '{:0>4x}'.format(DRAM[addr_str], 'x')  # 用 addr_str 取值
        f_new_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')

# ------------------- Utilities -------------------
def print_summary(recreate_cnt):
    print('Total operation count:')
    for op in operation_cnt:
        print(f"{op} = {operation_cnt[op]}")
    print('Recreate count =', recreate_cnt)

def print_core_reg():
    for i in range(16):
        print(f"{i} : {core_reg[i]}", end='\t')
        if i % 8 == 7:
            print()

# ------------------- Main -------------------
if __name__ == '__main__':
    read_DRAM(f_DRAM_data, DRAM_data)
    read_DRAM(f_DRAM_inst, DRAM_inst)

    recreate_cnt = simulate(0x1000)
    write_DRAM(DRAM_inst)

    print('----------------------------------------------')
    print_summary(recreate_cnt)
    print_core_reg()
    print('----------------------------------------------')

f_DRAM_data.close()
f_DRAM_inst.close()
f_new_DRAM_inst.close()