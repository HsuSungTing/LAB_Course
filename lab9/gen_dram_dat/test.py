import random

# ========== 參數 ==========
PLAYER_COUNT = 256        # 玩家數量 (可修改)
BASE_ADDR = 0x10000     # 起始位址 (範例使用 0x10000)
BYTES_PER_PLAYER = 12   # 每位玩家佔 12 bytes

random.seed(42)         # 可移除以取得非重現亂數

# ========== 產生檔案 ==========
with open("DRAM_data.dat", "w") as f:
    for i in range(PLAYER_COUNT):
        addr = BASE_ADDR + i * BYTES_PER_PLAYER

        # 產生資料
        mp    = random.randint(0, 0xFFFF)   # 16-bit
        exp   = random.randint(0, 0xFFFF)   # 16-bit
        atk   = random.randint(0, 0xFFFF)   # 16-bit
        dff   = random.randint(0, 0xFFFF)   # 16-bit (def)
        hp    = random.randint(0, 0xFFFF)   # 16-bit
        month = random.randint(1, 12)       # 8-bit, 1..12
        day   = random.randint(0, 28)       # 8-bit, 0..28

        # 組成每 4 bytes (小端，每個 16-bit 先 low byte 再 high byte)
        # 第一行: MP (16) low/high, EXP (16) low/high
        line1 = [mp & 0xFF, (mp >> 8) & 0xFF,
                 exp & 0xFF, (exp >> 8) & 0xFF]

        # 第二行: ATK (16) low/high, DEF (16) low/high
        line2 = [atk & 0xFF, (atk >> 8) & 0xFF,
                 dff & 0xFF, (dff >> 8) & 0xFF]

        # 第三行: DAY (8), MONTH (8), HP low, HP high
        line3 = [day & 0xFF, month & 0xFF,
                 hp & 0xFF, (hp >> 8) & 0xFF]

        # 寫入：address 與 data 分行
        f.write(f"@{addr:05X}\n")
        f.write(" ".join(f"{b:02X}" for b in line1) + "\n")
        f.write(f"@{addr+4:05X}\n")
        f.write(" ".join(f"{b:02X}" for b in line2) + "\n")
        f.write(f"@{addr+8:05X}\n")
        f.write(" ".join(f"{b:02X}" for b in line3) + "\n")

print("✅ DRAM_data.dat 已產生（第三行順序：day, month, HP_low, HP_high）")
