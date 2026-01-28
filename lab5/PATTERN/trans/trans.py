def read_hex_file_to_image_list(file_path, row_size=32):
    with open(file_path, "r") as f:
        hex_values = [line.strip() for line in f if line.strip()]

    # 轉成十進位整數
    dec_values = [int(h, 16) for h in hex_values]

    # 每 row_size 個數字分一列
    image_list = []
    for i in range(0, len(dec_values), row_size):
        image_list.append(dec_values[i:i + row_size])

    return image_list


if __name__ == "__main__":
    input_path = "Input.txt"   # 輸入檔案
    output_path = "output.txt" # 輸出檔案

    input_image_list = read_hex_file_to_image_list(input_path)

    with open(output_path, "w") as f:
        f.write("input_image_list = [\n")
        for row in input_image_list:
            f.write("    " + str(row) + ",\n")
        f.write("]\n")

    print(f"已寫入 {output_path}")
