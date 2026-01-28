import random

def generate_points(n=200, xmax=1023, ymax=1023, seed=None, filename=None):
    if seed is not None:
        random.seed(seed)  # 設定隨機種子（方便重現）

    points = [(random.randint(0, xmax), random.randint(0, ymax)) for _ in range(n)]

    if filename:
        with open(filename, "w") as f:
            f.write(f"{n}\n")
            for x, y in points:
                f.write(f"{x} {y}\n")
        print(f"已將 {n} 個點輸出到 {filename}")
    else:
        print(n)
        for x, y in points:
            print(x, y)

# 範例：生成 200 個點，並輸出到 input.txt
generate_points(n=30, filename="input.txt", seed=42)
