import io
import sys
import random
from fractions import Fraction

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 04 extension")

# 第 04 章：外测度数值构造（与 Julia 对拍：用精确分数 + 游程覆盖）。

d = 6  # 深度 6：64 个网格点
N = 2 ** d
CELL = Fraction(1, N)

def outer_measure(cells):
    """cells: 0/1 列表。最小覆盖 = 连续 1 游程（区间）长度和。"""
    total = Fraction(0)
    i = 0
    while i < len(cells):
        if cells[i]:
            j = i
            while j < len(cells) and cells[j]:
                j += 1
            total += (j - i) * CELL
            i = j
        else:
            i += 1
    return total

random.seed(11)

# 单调性
def mono_experiment():
    for _ in range(300):
        A = [1 if random.random() < 0.4 else 0 for _ in range(N)]
        B = [max(a, 1 if random.random() < 0.4 else 0) for a in A]
        if outer_measure(A) > outer_measure(B):
            return False
    return True

assert mono_experiment(), "外测度单调性"
print("单调性：300 次随机实验全过（精确分数）")

# 次可加性
def subadd_experiment():
    for _ in range(300):
        A = [1 if random.random() < 0.3 else 0 for _ in range(N)]
        B = [1 if random.random() < 0.3 else 0 for _ in range(N)]
        U = [max(A[i], B[i]) for i in range(N)]
        if outer_measure(U) > outer_measure(A) + outer_measure(B):
            return False
    return True

assert subadd_experiment(), "外测度次可加性"
print("次可加性：300 次随机实验全过（精确分数）")

# Cantor 集深度 3 的覆盖（精确 (2/3)^3）
cantor_blocks = []
def cantor_cells(depth):
    """深度 d 的 Cantor 集：保留块在网格上占据的格子。"""
    kept = [(0, 1)]  # 分数区间
    for _ in range(depth):
        kept = [(a, a + (b - a) / 3) for (a, b) in kept] + [
            (a + 2 * (b - a) / 3, b) for (a, b) in kept
        ]
    cells = [0] * N
    for (a, b) in kept:
        lo = int(a * N)
        hi = -(-int(b * N + 1e-9) // 1)  # ceil
        for g in range(max(lo, 0), min(hi, N)):
            cells[g] = 1
    return cells

cells = cantor_cells(3)
m_star = outer_measure(cells)
true_m = Fraction(8, 27)
print(f"Cantor 深度 3：格点外测度 = {float(m_star):.4f}，真值 8/27 = {float(true_m):.4f}")
assert abs(m_star - true_m) <= Fraction(1, N) * 8, "覆盖误差 ≤ 每块一个网格"

# Carathéodory 可测性：网格集合全体可测（有限影子的完备性）
def caratheodory_experiment():
    for _ in range(200):
        A = [1 if random.random() < 0.5 else 0 for _ in range(N)]
        T = [1 if random.random() < 0.5 else 0 for _ in range(N)]
        TA = [T[i] * A[i] for i in range(N)]
        TcA = [T[i] * (1 - A[i]) for i in range(N)]
        if outer_measure(T) != outer_measure(TA) + outer_measure(TcA):
            return False
    return True

assert caratheodory_experiment(), "有限网格上 Carathéodory 可加"
print("Carathéodory 判据：200 次随机 (A,T) 全部精确可加（有限影子完备）")

print("END ====")
