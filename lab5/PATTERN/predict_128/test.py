import numpy as np 
from math import floor

# ========== Inputs =======
I = np.array([
    [219, 107, 138, 173],
    [62, 130, 147, 179],
    [171, 149, 68, 102],
    [237, 228, 102, 203]
], dtype=object)

P = np.array([
    [128, 128, 128, 128],
    [128, 128, 128, 128],
    [128, 128, 128, 128],
    [128, 128, 128, 128]
], dtype=object)

QP = 9  # 介於 0~29

# =========================
# ========== Helpers ======
# =========================
def print_mat(name, M):
    print(f"{name} (shape {np.shape(M)}):")
    for row in M:
        print("  ", row)
    print()

def arith_right_shift(x, n):
    return x >> n

# =========================
# ========== Step 1 =======
# =========================
X = (I - P).astype(object)
print_mat("Step 1: X = I - P", X)

# =========================
# ========== Step 2 =======
# =========================
C = np.array([
    [1,  1,  1,  1],
    [1,  1, -1, -1],
    [1, -1, -1,  1],
    [1, -1,  1, -1]
], dtype=object)

print_mat("Matrix C", C)

W = (C @ X) @ C
W = W.astype(object)
print_mat("Step 2: W = C @ X @ C", W)

# =========================
# ========== Step 3 =======
# =========================
qbits = 15 + (QP // 6)
print("Step 3: qbits =", qbits)
print()

mf_table = {
    0: (13107, 5243, 8066),
    1: (11916, 4660, 7490),
    2: (10082, 4194, 6554),
    3: (9362, 3647, 5825),
    4: (8192, 3355, 5243),
    5: (7282, 2893, 4559)
}
qm6 = QP % 6
a_mf, b_mf, c_mf = mf_table[qm6]

MF = np.array([
    [a_mf, c_mf, a_mf, c_mf],
    [c_mf, b_mf, c_mf, b_mf],
    [a_mf, c_mf, a_mf, c_mf],
    [c_mf, b_mf, c_mf, b_mf]
], dtype=object)

print_mat(f"MF (QP mod 6 = {qm6} => a,b,c = {a_mf},{b_mf},{c_mf})", MF)

if 0 <= QP <= 5:
    f_val = 10922
elif 6 <= QP <= 11:
    f_val = 21845
elif 12 <= QP <= 17:
    f_val = 43690
elif 18 <= QP <= 23:
    f_val = 87381
elif 24 <= QP <= 29:
    f_val = 174762
else:
    raise ValueError("QP out of expected range 0-29")

print("Quantization offset f =", f_val)
print()

r,c = W.shape
Z = np.empty((r,c), dtype=object)
for i in range(r):
    for j in range(c):
        Wij = int(W[i,j])
        Mf  = int(MF[i,j])
        absW = abs(Wij)
        num  = absW * Mf + f_val
        val_shifted = num >> qbits
        s = 0 if Wij == 0 else (1 if Wij > 0 else -1)
        Z[i,j] = s * val_shifted

print_mat("Step 3 - Z (with sign)", Z)

# =========================
# ========== Step 4 =======
# =========================
v_table = {
    0: (10, 16, 13),
    1: (11, 18, 14),
    2: (13, 20, 16),
    3: (14, 23, 18),
    4: (16, 25, 20),
    5: (18, 29, 23),
}
a_v, b_v, c_v = v_table[qm6]

V = np.array([
    [a_v, c_v, a_v, c_v],
    [c_v, b_v, c_v, b_v],
    [a_v, c_v, a_v, c_v],
    [c_v, b_v, c_v, b_v]
], dtype=object)

print_mat(f"V (QP mod 6 = {qm6} => a,b,c = {a_v},{b_v},{c_v})", V)

shift_pow = QP // 6
mult_factor = 1 << shift_pow
print("Step 4: shift_pow = floor(QP/6) =", shift_pow)
print("Step 4: mult_factor = 2^shift_pow =", mult_factor)
print()

Wprime = np.empty((r,c), dtype=object)
for i in range(r):
    for j in range(c):
        Wij = int(Z[i,j])
        Vij = int(V[i,j])
        Wprime[i,j] = Wij * Vij * mult_factor

print_mat("Step 4 - W' (before Step 5)", Wprime)

# =========================
# ========== Step 5 =======
# =========================
# 先做矩陣乘法 C @ W' @ C.T
W_tmp = (C @ Wprime) @ C.T
W_tmp = W_tmp.astype(object)

# 再對整個矩陣做 >>6
W_final = np.empty((r,c), dtype=object)
for i in range(r):
    for j in range(c):
        W_final[i,j] = arith_right_shift(int(W_tmp[i,j]), 6)

print_mat("Step 5 - W_tmp = C @ W' @ C.T (before >>6)", W_tmp)
print_mat("Step 5 - Final W (after >>6)", W_final)

# =========================
# ========== Step 6 =======
# =========================
W_step6 = np.empty((r,c), dtype=object)
for i in range(r):
    for j in range(c):
        W_step6[i,j] = W_final[i,j] + P[i,j]

print_mat("Step 6 - W + P", W_step6)

print("===== All steps finished. =====")
