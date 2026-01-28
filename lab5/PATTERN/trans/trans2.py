input_file = "in.txt"   # 原始數字檔
output_file = "out.txt"    # 轉換後輸出的檔案

numbers = []
# 讀檔並擷取所有數字
with open(input_file, 'r') as f:
    for line in f:
        nums = line.split()               # 依空白拆開
        numbers.extend(int(n) for n in nums)

# 分組，每 32 個數字一 row
input_image_list = []
row_size = 32
for i in range(0, len(numbers), row_size):
    input_image_list.append(numbers[i:i + row_size])

# 寫入 out.txt
with open(output_file, 'w') as f:
    f.write("input_image_list = [\n")
    for row in input_image_list:
        f.write("    " + str(row) + ",\n")
    f.write("]\n")

print(f"已完成，結果寫入 {output_file}")
