# NTT with Montgomery multiplication (R = 2^16)
# Python 3.10 compatible

Q = 12289              # modulus
N = 128
R = 2 ** 16            # 65536
Q0I = 12287            # as specified in your PDF / assignment

# GMb array (GMb[0]..GMb[127]) exactly as you provided
GMb = [
4091,7888,11060,11208,6960,4342,6275,9759,1591,6399,9477,5266,586,5825,7538,9710,
1134,6407,1711,965,7099,7674,3743,6442,10414,8100,1885,1688,1364,10329,10164,9180,
12210,6240,997,117,4783,4407,1549,7072,2829,6458,4431,8877,7144,2564,5664,4042,12189,
432,10751,1237,7610,1534,3983,7863,2181,6308,8720,6570,4843,1690,14,3872,5569,9368,
12163,2019,7543,2315,4673,7340,1553,1156,8401,11389,1020,2967,10772,7045,3316,11236,
5285,11578,10637,10086,9493,6180,9277,6130,3323,883,10469,489,1502,2851,11061,9729,
2742,12241,4970,10481,10078,1195,730,1762,3854,2030,5892,10922,9020,5274,9179,3604,
3782,10206,3180,3467,4668,2446,7613,9386,834,7703,6836,3403,5351,12276
]

# === 讀取 input.txt 中的資料 ===
x = []
with open("input.txt", "r") as f:
    lines = [line.strip() for line in f.readlines() if line.strip() != ""]

# 每一行是 8 個 hex 字元 (32-bit)
# 從右到左解析，每個 nibble 對應一個 x
for line_idx, line in enumerate(lines):
    if len(line) != 8:
        raise ValueError(f"Line {line_idx+1} must have 8 hex characters (got {len(line)})")
    for ch in reversed(line):
        val = int(ch, 16)
        x.append(val)

if len(x) != 128:
    raise ValueError(f"Total elements should be 128, got {len(x)}")

print("Input data loaded from input.txt:")
print(x)
print("-" * 60)

# Montgomery modular multiplication using R = 2^16 and Q0I
def modq_mul(a: int, b: int) -> int:
    # inputs a,b assumed in [0, Q-1]
    x_prod = a * b                       # integer product
    y = (x_prod * Q0I) & (R - 1)         # (x * Q0I) mod R
    z = (x_prod + y * Q) >> 16           # (x + y*Q) / R
    if z >= Q:
        return z - Q
    else:
        return z

# conditional subtraction for (u - v)
def sub_mod_cond(a: int, b: int) -> int:
    # return a-b if a>=b else a-b+Q
    if a >= b:
        return a - b
    else:
        return a - b + Q

# === NTT iterative radix-2 ===
t = N
stages = [1,2,4,8,16,32,64]   # m values
for m in stages:
    ht = t // 2
    for i in range(m):
        j1 = i * t
        s = GMb[m + i]        # twiddle from GMb[m+i]
        j2 = j1 + ht
        for j in range(j1, j2):
            u = x[j]
            v = modq_mul(x[j + ht], s)
            # update x in-place with conditional rules
            uv = u + v
            if uv >= Q:
                uv = uv - Q
            x[j] = uv
            x[j + ht] = sub_mod_cond(u, v)
            
            if(1):
                print(f"stage m={m}, i={i}, j={j}, j1={j1}, j2={j2}, ht={ht}, s={s}")
                print(f"  u = {u}")
                print(f"  v = {v}")
                print(f"  x[{j}] (new) = {x[j]}")
                print(f"  x[{j + ht}] (new) = {x[j + ht]}")
                print("-" * 60)
    t = ht

print("\nNTT finished. Final x array:")
print(x)
