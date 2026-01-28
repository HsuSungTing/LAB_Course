import random
from bitstring import BitArray

# ==================================================
f_DRAM_inst = open('./DRAM_inst.dat', 'w')
f_DRAM_data = open('./DRAM_data.dat', 'w')
f_inst_func = open('./inst_func.txt', 'w')

kAddrMin = 0x1000
kAddrMax = 0x1fff
kDataMin = 0
kDataMax = 100
kFunction = ['ADD', 'SUB', 'SetLessThan', 'Mult', 'Load', 'Store', 'BranchOnEqual']  # Jump handled separately
kOffset = 0x1000

# ---------------- DRAM Instruction Generator ----------------
def GenerateDRAM_inst():
    rt_int = -1
    # 初始化前 32 筆資料為 Load 指令
    for i in range(kAddrMin, kAddrMin + 32, 2):
        f_DRAM_inst.write('@' + format(i, 'x') + '\n')
        rt_int += 1
        rs = '{:0>4b}'.format(random.randint(0, 15), 'x')
        rt = '{:0>4b}'.format(rt_int, 'x')
        immediate = '{:0>5b}'.format(random.randint(0, 15), 'x')
        inst = '011' + rs + rt + immediate  # Load opcode = 011
        b = BitArray(bin=inst)
        temp = '{:0>4x}'.format(b.uint, 'x')
        f_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')
        f_inst_func.write('@' + format(i, 'x') + ' : Load\n')

    jump_flag = False
    jump_cnt = 0

    # 產生剩餘的指令
    for i in range(kAddrMin + 32, kAddrMax - 2, 2):
        f_DRAM_inst.write('@' + format(i, 'x') + '\n')
        # 決定 func
        if not jump_flag:
            func = random.choice(kFunction + ['Jump'])
        else:
            func = random.choice(kFunction)
        rs = '{:0>4b}'.format(random.randint(0, 15), 'x')
        rt = '{:0>4b}'.format(random.randint(0, 15), 'x')
        rd = '{:0>4b}'.format(random.randint(0, 15), 'x')
        immediate = '{:0>5b}'.format(random.randint(0, 31), 'x')

        # R-Type 指令
        if func == 'ADD':
            inst = '000' + rs + rt + rd + '1'  # func = 1
        elif func == 'SUB':
            inst = '000' + rs + rt + rd + '0'  # func = 0
        elif func == 'SetLessThan':
            inst = '001' + rs + rt + rd + '1'  # func = 1
        elif func == 'Mult':
            inst = '001' + rs + rt + rd + '0'  # func = 0
        # I-Type 指令
        elif func == 'Load':
            inst = '011' + rs + rt + immediate  # opcode = 011
        elif func == 'Store':
            inst = '010' + rs + rt + immediate  # opcode = 010
        elif func == 'BranchOnEqual':
            imm_val = random.randint(0, 15)
            immediate = '{:0>5b}'.format(imm_val, 'x')
            inst = '101' + rs + rt + immediate  # opcode = 101
        # Jump
        elif func == 'Jump':
            jump_flag = True
            a = max(kAddrMin, i - 64 + 1 + 64)
            b = min(kAddrMax, i + 64 + 64)
            addr_int = random.randint(a, b)
            if addr_int % 2 == 1:
                addr_int -= 1
            addr = '{:0>13b}'.format(addr_int, 'x')
            inst = '100' + addr  # opcode = 100

        # 控制 jump_flag
        if jump_flag:
            jump_cnt += 1
            if jump_cnt == 10:
                jump_flag = False
                jump_cnt = 0

        # 寫入 DRAM_inst
        b = BitArray(bin=inst)
        temp = '{:0>4x}'.format(b.uint, 'x')
        f_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')
        f_inst_func.write('@' + format(i, 'x') + ' : ' + func + '\n')

    # 最後一筆 Jump
    f_DRAM_inst.write('@' + format(0x1ffe, 'x') + '\n')
    addr_int = random.randint(kAddrMin, kAddrMin + 256)
    if addr_int % 2 == 1:
        addr_int -= 1
    addr = '{:0>13b}'.format(addr_int, 'x')
    inst = '100' + addr  # Jump opcode = 100
    b = BitArray(bin=inst)
    temp = '{:0>4x}'.format(b.uint, 'x')
    f_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')
    f_inst_func.write('@' + format(0x1ffe, 'x') + ' : Jump\n')


# ---------------- DRAM Data Generator ----------------
def GenerateDRAM_data():
    for i in range(kAddrMin, kAddrMax, 2):
        f_DRAM_data.write('@' + format(i, 'x') + '\n')
        temp = '{:0>4x}'.format(random.randint(kDataMin, kDataMax), 'x')
        f_DRAM_data.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')


# ---------------- Main ----------------
if __name__ == '__main__':
    GenerateDRAM_data()
    GenerateDRAM_inst()

f_DRAM_inst.close()
f_DRAM_data.close()
f_inst_func.close()
