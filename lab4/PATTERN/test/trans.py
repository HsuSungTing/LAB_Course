# -*- coding: utf-8 -*-
# 將 input.txt 的所有 16 進位數字轉成 32 位元 2 進位，保留原本格式與換行
# 不加入任何額外符號或分隔符，結果輸出到 output.txt

input_file = "input.txt"
output_file = "output.txt"

def hex_to_bin(h):
    """將單一十六進位字串轉為 32-bit 二進位字串"""
    return format(int(h, 16), '032b')

def main():
    with open(input_file, "r", encoding="utf-8") as f:
        content = f.readlines()

    output_lines = []
    for line in content:
        # 以空白切割這行的所有 hex
        parts = line.strip().split()
        # 轉換成二進位
        bins = [hex_to_bin(p) for p in parts if p != ""]
        # 用單一空白連回同行
        output_lines.append(" ".join(bins))

    # 寫入 output.txt
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(output_lines))

    print(f"✅ 已完成轉換，輸出在 {output_file}")

if __name__ == "__main__":
    main()