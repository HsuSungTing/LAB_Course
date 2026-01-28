import matplotlib.pyplot as plt

# 定義點資料
test_points = [
    (701, 434), (732, 403), (807, 734), (701, 434),
    (732, 403), (807, 734), (838, 72), (732, 403),
    (701, 434), (838, 72), (807, 734), (807, 322),
    (807, 322), (701, 434), (838, 72), (807, 734),
    (837, 696), (701, 434), (838, 72), (837, 696),
    (807, 734)
]

# 拆分成 x 和 y 座標
x_vals, y_vals = zip(*test_points)

# 畫點
plt.figure(figsize=(10, 10))
plt.scatter(x_vals, y_vals, color='blue', s=100)  # 點變大

# 標上點的編號，字體變大
for i, (x, y) in enumerate(test_points):
    plt.text(x + 5, y + 5, f"{i}", fontsize=12, fontweight='bold', color='red')

plt.title("Test Points", fontsize=16)
plt.xlabel("X", fontsize=14)
plt.ylabel("Y", fontsize=14)

# 格線加粗
plt.grid(True, linewidth=1.2)
plt.gca().set_aspect('equal', adjustable='box')
plt.show()
