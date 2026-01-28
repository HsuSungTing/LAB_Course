# -*- coding: utf-8 -*-
"""
H.2C4 Lite Prediction and Transform Engine (HLPTE) - Final Corrected Version with Debug Output

This version handles both Intra 4x4 and Intra 16x16 macroblock modes and
prints the detailed debug trace for ALL processed 4x4 blocks.
"""
import numpy as np

# ==============================================================================
#  常數與查找表
# ==============================================================================

# -- 整數轉換矩陣 (最終正確版本) --
C_f = np.array([
    [ 1,  1,  1,  1],
    [ 1,  1, -1, -1],
    [ 1, -1, -1,  1],
    [ 1, -1,  1, -1]
], dtype=np.int32)
C_i = C_f

# -- 量化表 --
MF_TABLE = {
    0: [13107, 5243, 8066], 1: [11916, 4660, 7490], 2: [10082, 4194, 6554],
    3: [9362, 3647, 5825],  4: [8192, 3355, 5243], 5: [7282, 2893, 4559]
}
F_TABLE = [(0, 5, 10922), (6, 11, 21845), (12, 17, 43690),
           (18, 23, 87381), (24, 29, 174762)]

# -- 反量化表 --
V_TABLE = {
    0: [10, 16, 13], 1: [11, 18, 14], 2: [13, 20, 16],
    3: [14, 23, 18], 4: [16, 25, 20], 5: [18, 29, 23]
}

# ==============================================================================
#  預測階段函數
# ==============================================================================
def calculate_sad(original, predicted):
    return np.sum(np.abs(original.astype(np.int32) - predicted.astype(np.int32)))

def predict_dc_4x4(T, L):
    """
    DC 預測函數 (已修正為 floor/truncation)
    """
    pred = np.zeros((4, 4), dtype=np.int32)
    T_available, L_available = T is not None, L is not None
    if T_available and L_available:
        dc = (np.sum(T) + np.sum(L)) // 8
    elif T_available:
        dc = np.sum(T) // 4
    elif L_available:
        dc = np.sum(L) // 4
    else:
        dc = 128
    pred.fill(dc)
    return pred

def predict_horizontal_4x4(L):
    pred = np.zeros((4, 4), dtype=np.int32)
    if L is not None:
        for i in range(4): pred[i, :] = L[i]
    return pred

def predict_vertical_4x4(T):
    pred = np.zeros((4, 4), dtype=np.int32)
    if T is not None:
        for j in range(4): pred[:, j] = T[j]
    return pred

def predict_dc_16x16(T, L):
    """
    16x16 DC 預測函數 (已修正為 floor/truncation)
    """
    pred = np.zeros((16, 16), dtype=np.int32)
    T_available, L_available = T is not None, L is not None
    if T_available and L_available:
        dc = (np.sum(T) + np.sum(L)) // 32
    elif T_available:
        dc = np.sum(T) // 16
    elif L_available:
        dc = np.sum(L) // 16
    else:
        dc = 128
    pred.fill(dc)
    return pred

def predict_horizontal_16x16(L):
    pred = np.zeros((16, 16), dtype=np.int32)
    if L is not None:
        for i in range(16): pred[i, :] = L[i]
    return pred

def predict_vertical_16x16(T):
    pred = np.zeros((16, 16), dtype=np.int32)
    if T is not None:
        for j in range(16): pred[:, j] = T[j]
    return pred


def find_best_mode_4x4(original_block, T, L):
    sads = {}
    predictions = {}
    T_available, L_available = T is not None, L is not None

    predictions[0] = predict_dc_4x4(T, L)
    sads[0] = calculate_sad(original_block, predictions[0])
    
    if L_available:
        predictions[1] = predict_horizontal_4x4(L)
        sads[1] = calculate_sad(original_block, predictions[1])
    
    if T_available:
        predictions[2] = predict_vertical_4x4(T)
        sads[2] = calculate_sad(original_block, predictions[2])

    min_sad_val = min(sads.values())
    
    # 根據優先序 DC > H > V 找出最佳模式
    if sads.get(0) == min_sad_val:
        best_mode = 0
    elif sads.get(1) == min_sad_val:
        best_mode = 1
    elif sads.get(2) == min_sad_val:
        best_mode = 2
    else: # 備用，理論上不會發生
        best_mode = 0

    return best_mode, predictions[best_mode]

def find_best_mode_16x16(original_mb, T, L):
    sads = {}
    predictions = {}
    T_available, L_available = T is not None, L is not None

    predictions[0] = predict_dc_16x16(T, L)
    sads[0] = calculate_sad(original_mb, predictions[0])
    
    if L_available:
        predictions[1] = predict_horizontal_16x16(L)
        sads[1] = calculate_sad(original_mb, predictions[1])
    
    if T_available:
        predictions[2] = predict_vertical_16x16(T)
        sads[2] = calculate_sad(original_mb, predictions[2])
    
    min_sad_val = min(sads.values())

    if sads.get(0) == min_sad_val:
        best_mode = 0
    elif sads.get(1) == min_sad_val:
        best_mode = 1
    elif sads.get(2) == min_sad_val:
        best_mode = 2
    else:
        best_mode = 0
        
    return best_mode, predictions[best_mode]


# ==============================================================================
#  轉換階段函數
# ==============================================================================

def integer_transform_4x4(block_x):
    return C_f @ block_x @ C_f.T

def quantize_4x4(block_w, qp):
    qbits = 15 + (qp // 6)
    a, b, c = MF_TABLE[qp % 6]
    mf = np.array([[a, c, a, c], [c, b, c, b], [a, c, a, c], [c, b, c, b]], dtype=np.int64)
    f = next(val for low, high, val in F_TABLE if low <= qp <= high)
    
    sign_w = np.sign(block_w)
    abs_w = np.abs(block_w)
    
    mult_result = abs_w * mf
    add_result = mult_result + f
    block_z_abs = add_result >> qbits

    return (block_z_abs * sign_w).astype(np.int32)

def dequantize_4x4(block_z, qp):
    a, b, c = V_TABLE[qp % 6]
    v = np.array([[a, c, a, c], [c, b, c, b], [a, c, a, c], [c, b, c, b]], dtype=np.int32)
    scale_factor = 1 << (qp // 6)
    return block_z * v * scale_factor

# ==============================================================================
#  主 HLPTE 編碼器函數
# ==============================================================================

def hlpte_encoder(original_frame, mb_modes, qp):
    frame_size = original_frame.shape[0]
    mb_size = 16
    block_size = 4

    pre_entropy_frame_Z = np.zeros_like(original_frame, dtype=np.int32)
    reconstructed_frame_R = np.zeros_like(original_frame, dtype=np.int32)
    residual_frame_X = np.zeros_like(original_frame, dtype=np.int32)

    mb_idx = 0
    for mb_r in range(0, frame_size, mb_size):
        for mb_c in range(0, frame_size, mb_size):
            mode_16x16_or_4x4 = mb_modes[mb_idx]
            original_mb = original_frame[mb_r:mb_r+mb_size, mb_c:mb_c+mb_size]

            # 步驟 1: 如果是 16x16 模式，先計算整個宏區塊的預測
            predicted_mb_P = None
            best_mode_16x16 = None
            if mode_16x16_or_4x4 == 0:
                T = reconstructed_frame_R[mb_r-1, mb_c:mb_c+mb_size] if mb_r > 0 else None
                L = reconstructed_frame_R[mb_r:mb_r+mb_size, mb_c-1] if mb_c > 0 else None
                best_mode_16x16, predicted_mb_P = find_best_mode_16x16(original_mb, T, L)

            # 步驟 2: 遍歷宏區塊內部所有的 4x4 區塊
            for r_off in range(0, mb_size, block_size):
                for c_off in range(0, mb_size, block_size):
                    r, c = mb_r + r_off, mb_c + c_off
                    block_I = original_frame[r:r+block_size, c:c+block_size]

                    # 步驟 3: 確定當前 4x4 區塊的預測塊 P
                    best_mode_4x4 = None
                    if mode_16x16_or_4x4 == 1: # 如果是 4x4 模式，獨立計算預測
                        T = reconstructed_frame_R[r-1, c:c+block_size] if r > 0 else None
                        L = reconstructed_frame_R[r:r+block_size, c-1] if c > 0 else None
                        best_mode_4x4, block_P = find_best_mode_4x4(block_I, T, L)
                    else: # 如果是 16x16 模式，直接取對應部分
                        block_P = predicted_mb_P[r_off:r_off+block_size, c_off:c_off+block_size]

                    # 步驟 4: 執行轉換、量化、重建的循環 (對所有 4x4 區塊都一樣)
                    block_X = block_I.astype(np.int32) - block_P
                    residual_frame_X[r:r+block_size, c:c+block_size] = block_X
                    
                    block_W = integer_transform_4x4(block_X)
                    block_Z = quantize_4x4(block_W, qp)
                    pre_entropy_frame_Z[r:r+block_size, c:c+block_size] = block_Z

                    block_W_prime = dequantize_4x4(block_Z, qp)
                    
                    y = C_i.T @ block_W_prime @ C_i
                    block_X_prime = y >> 6
                    
                    block_R = block_X_prime + block_P
                    
                    # --- 除錯打印區塊 (現在對所有區塊生效) ---
                    mode_map = {0: "DC", 1: "Horizontal", 2: "Vertical"}
                    current_mode_num = best_mode_16x16 if mode_16x16_or_4x4 == 0 else best_mode_4x4
                    mode_prefix = "MB " if mode_16x16_or_4x4 == 0 else ""

                    print(f"\n--- [除錯] 詳細步驟 for Block ({r//4}, {c//4}) ---")
                    print(f"Chosen Prediction Mode: {mode_prefix}{current_mode_num} ({mode_map.get(current_mode_num, 'Unknown')})")
                    print("Predicted Block (P):\n", block_P)
                    print("Residual (X):\n", block_X)
                    print("W (輸入轉換後矩陣):\n", block_W)
                    print("Quantized Block (Z):\n", block_Z)
                    print("Dequantized Block (W'):\n", block_W_prime)
                    print("Inverse Transform (Y = Ci.T * W' * Ci):\n", y)
                    print("Inverse Transform Result (X' = Y >> 6):\n", block_X_prime)
                    print("Reconstruction (R = X' + P):\n", block_R)
                    print("Final Clipped Reconstruction Block:\n", np.clip(block_R, 0, 255))
                    print("-------------------------------------------------------\n")
                    # --- 除錯結束 ---
                    
                    reconstructed_frame_R[r:r+block_size, c:c+block_size] = np.clip(block_R, 0, 255)

            mb_idx += 1

    return pre_entropy_frame_Z, reconstructed_frame_R.astype(np.uint8), residual_frame_X

# ==============================================================================
#  執行與結果顯示
# ==============================================================================
if __name__ == '__main__':
    input_image_list = [
        [11, 5, 2, 5, 10, 7, 2, 7, 4, 5, 1, 12, 10, 4, 0, 8, 9, 3, 0, 8, 8, 12, 1, 9, 13, 5, 15, 3, 10, 1, 13, 12],
        [6, 9, 0, 11, 5, 6, 2, 13, 8, 10, 7, 9, 15, 14, 13, 7, 15, 12, 0, 7, 15, 0, 3, 0, 10, 7, 10, 8, 1, 12, 13, 5],
        [7, 3, 3, 2, 5, 3, 11, 12, 3, 0, 3, 6, 5, 11, 12, 7, 2, 12, 6, 6, 15, 11, 1, 8, 6, 13, 1, 6, 7, 10, 3, 6],
        [8, 3, 3, 15, 10, 11, 9, 6, 11, 15, 11, 12, 11, 4, 2, 14, 9, 12, 2, 4, 15, 5, 1, 11, 0, 3, 1, 2, 15, 14, 2, 4],
        [0, 0, 2, 2, 5, 12, 0, 9, 8, 0, 14, 10, 7, 9, 0, 11, 9, 4, 12, 6, 9, 12, 4, 3, 13, 2, 13, 12, 6, 10, 11, 15],
        [9, 12, 6, 13, 14, 11, 12, 15, 14, 13, 2, 2, 13, 1, 0, 2, 5, 2, 7, 15, 11, 3, 14, 10, 12, 13, 2, 8, 3, 3, 13, 10],
        [14, 6, 7, 5, 3, 4, 12, 12, 4, 1, 3, 4, 6, 3, 8, 11, 10, 5, 11, 3, 7, 9, 5, 7, 9, 14, 12, 15, 14, 14, 3, 1],
        [13, 0, 3, 2, 0, 3, 13, 14, 11, 12, 1, 11, 2, 0, 0, 2, 7, 0, 2, 5, 4, 10, 1, 11, 7, 1, 7, 8, 14, 2, 7, 4],
        [0, 0, 5, 12, 1, 1, 14, 5, 13, 9, 11, 9, 1, 7, 15, 6, 8, 13, 11, 5, 12, 14, 15, 10, 14, 9, 4, 8, 10, 15, 0, 0],
        [11, 15, 9, 9, 11, 14, 8, 8, 6, 1, 11, 13, 9, 6, 12, 10, 6, 5, 7, 11, 4, 9, 5, 0, 0, 4, 4, 5, 0, 3, 2, 3],
        [4, 10, 15, 5, 4, 5, 7, 14, 3, 6, 2, 8, 5, 3, 8, 14, 11, 5, 12, 7, 9, 3, 10, 7, 10, 3, 12, 15, 4, 5, 9, 4],
        [12, 7, 15, 14, 12, 12, 3, 5, 5, 6, 3, 4, 0, 13, 6, 14, 1, 11, 9, 12, 13, 4, 0, 14, 5, 12, 9, 7, 0, 9, 11, 4],
        [6, 3, 3, 10, 10, 4, 12, 5, 1, 5, 4, 9, 9, 15, 14, 1, 15, 15, 15, 15, 7, 2, 15, 1, 6, 8, 1, 4, 8, 13, 4, 13],
        [3, 4, 5, 11, 6, 0, 6, 5, 14, 7, 15, 7, 8, 6, 3, 10, 4, 1, 15, 7, 13, 5, 15, 3, 13, 7, 10, 12, 1, 3, 3, 4],
        [9, 12, 10, 9, 10, 6, 4, 3, 3, 13, 0, 8, 2, 1, 0, 1, 6, 14, 11, 5, 13, 15, 14, 0, 11, 7, 11, 0, 11, 14, 11, 4],
        [14, 10, 13, 0, 15, 14, 3, 7, 0, 14, 13, 13, 2, 14, 13, 6, 8, 0, 14, 4, 14, 3, 4, 9, 2, 1, 11, 15, 4, 11, 13, 15],
        [3, 13, 12, 3, 7, 8, 9, 13, 14, 14, 12, 9, 14, 0, 4, 13, 1, 14, 7, 15, 7, 7, 8, 7, 9, 13, 2, 10, 1, 6, 0, 10],
        [6, 6, 9, 14, 11, 13, 9, 4, 13, 12, 5, 11, 12, 0, 12, 5, 11, 5, 13, 6, 11, 6, 15, 7, 5, 9, 5, 0, 11, 4, 1, 2],
        [11, 13, 13, 9, 6, 15, 10, 15, 5, 3, 7, 2, 4, 8, 15, 8, 2, 2, 13, 0, 2, 12, 7, 13, 8, 4, 7, 8, 10, 13, 7, 8],
        [9, 4, 9, 11, 13, 6, 12, 5, 0, 8, 2, 1, 8, 14, 4, 11, 13, 11, 7, 11, 4, 11, 15, 12, 10, 1, 0, 14, 11, 13, 2, 7],
        [11, 6, 9, 1, 15, 8, 0, 2, 9, 6, 3, 8, 6, 13, 6, 15, 10, 4, 6, 0, 11, 1, 4, 2, 8, 8, 6, 14, 3, 4, 9, 7],
        [2, 7, 8, 1, 9, 8, 4, 7, 10, 14, 5, 2, 2, 14, 7, 14, 11, 12, 4, 9, 9, 6, 14, 0, 7, 3, 10, 12, 5, 0, 10, 8],
        [10, 15, 7, 0, 12, 11, 8, 6, 6, 2, 6, 0, 1, 15, 13, 13, 13, 13, 3, 11, 2, 11, 4, 10, 4, 6, 14, 15, 12, 11, 2, 6],
        [4, 11, 1, 9, 6, 9, 3, 12, 2, 0, 5, 3, 13, 5, 15, 0, 11, 12, 1, 0, 6, 12, 8, 13, 3, 5, 4, 3, 3, 11, 10, 9],
        [13, 14, 7, 13, 0, 10, 7, 6, 5, 12, 0, 10, 2, 0, 14, 1, 14, 12, 8, 10, 8, 9, 4, 14, 2, 7, 1, 12, 14, 15, 5, 8],
        [4, 13, 4, 5, 2, 9, 14, 14, 11, 12, 2, 11, 4, 15, 6, 8, 15, 5, 15, 3, 6, 1, 1, 2, 9, 5, 15, 11, 1, 15, 3, 3],
        [4, 1, 5, 11, 10, 4, 9, 11, 9, 13, 10, 2, 13, 15, 3, 6, 13, 11, 7, 1, 3, 2, 15, 14, 9, 11, 6, 3, 0, 6, 15, 11],
        [0, 7, 4, 4, 2, 5, 15, 5, 11, 7, 3, 11, 6, 14, 4, 15, 11, 9, 3, 4, 1, 1, 1, 12, 10, 12, 3, 10, 10, 11, 7, 1],
        [12, 14, 2, 15, 9, 2, 12, 0, 11, 13, 7, 3, 11, 11, 7, 3, 1, 4, 4, 4, 4, 8, 1, 2, 11, 7, 4, 9, 6, 10, 5, 0],
        [4, 6, 3, 2, 0, 3, 14, 12, 12, 8, 15, 1, 7, 1, 14, 14, 4, 0, 6, 3, 13, 15, 5, 13, 9, 7, 5, 3, 13, 8, 5, 12],
        [2, 15, 9, 5, 3, 4, 14, 8, 10, 7, 1, 13, 2, 12, 11, 3, 7, 13, 4, 15, 9, 5, 11, 2, 12, 6, 10, 0, 9, 4, 3, 12],
        [8, 1, 15, 11, 10, 15, 3, 14, 11, 6, 7, 8, 6, 3, 7, 11, 8, 10, 8, 0, 10, 15, 1, 4, 9, 11, 8, 11, 6, 6, 9, 15],
    ]


    original_frame = np.array(input_image_list, dtype=np.uint8)
    mb_modes = [0, 1, 0, 1] 
    QP = 21

    # --- 執行完整的 HLPTE 編碼器 ---
    final_Z, final_R, final_X = hlpte_encoder(original_frame, mb_modes, QP)

    # --- 顯示最終結果 ---
    print("\n\n" + "="*25 + " FINAL RESULTS " + "="*25)
    print(f"輸入 QP: {QP}\n")

    # 配置 numpy 以打印完整的矩陣而不換行
    np.set_printoptions(linewidth=200, threshold=np.inf, suppress=True)

    print(">> 最終輸出: Residual Frame (X)")
    print(final_X)
    print("\n" + "="*60 + "\n")

    print(">> 最終輸出: Pre-Entropy Frame (Z)")
    print(final_Z)
    print("\n" + "="*60 + "\n")

    print(">> 最終輸出: Reconstructed Frame (R)")
    print(final_R)

