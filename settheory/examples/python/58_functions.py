# 第 58 章：函数的机器化（Makinson Ch3）
# 平方函数域依赖矩阵 + AC 三版本的有限实验 + 鸽笼确定性验证
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product

print("==== 58")

# ---------- 一、平方函数：六域单/满射矩阵（书本 3.3.2） ----------
def square_status(dom, rng):
    vals = {n*n for n in dom}
    inj = len(vals) == len(dom)
    surj = vals == set(rng)
    return inj, surj

domains = {
    "ℕ 段 0..9":    (range(0, 10),  {n*n for n in range(0, 10)}),
    "ℕ₊ 段 1..9":   (range(1, 10),  {n*n for n in range(1, 10)}),
    "ℤ 段 -9..9":   (range(-9, 10), {n*n for n in range(-9, 10)}),
}
print("  平方函数的域依赖：")
for name, (dom, rng) in domains.items():
    inj, surj = square_status(dom, rng)
    print(f"    {name}：单射={'✓' if inj else '✗'}  满射(到平方集)={'✓' if surj else '✗'}")
    if not inj:
        witness = next((a, b) for a in dom for b in dom if a != b and a*a == b*b)
        print(f"      单射见证：{witness[0]}² = {witness[1]}² = {witness[0]**2}")

# ---------- 二、鸽笼原理确定性验证（广义版） ----------
def pigeon_bound(n_items, n_holes, k):
    # #A = n, #B = m：若 n > k·m 则有洞承装 ≥ k+1
    return n_items > k * n_holes

print("  400 村民生日：", pigeon_bound(400, 366, 1), "（两人同天）")
print("  400 村民月份：", pigeon_bound(400, 12, 33), "（≥34 人同月）")
print("  677 会员缩写：", pigeon_bound(677, 26*26, 1))
print("  97 学生答题：", pigeon_bound(97, 2**5, 3), "（≥4 人同卷）")

# 广义鸽笼的直接构造验证：最均匀的装法
def min_max_occupancy(n, m):
    q, r = divmod(n, m)
    return q + (1 if r else 0)
for (n, m) in [(400, 12), (97, 32), (10, 9)]:
    print(f"    {n} 物 {m} 洞：最均匀装法的最大洞装 = {min_max_occupancy(n, m)}")

# ---------- 三、AC 三版本的有限实验 ----------
# (1) 有限族的选择函数：first 即可（构造性）
fam = [[1, 2], [2, 3], [1, 3], [7]]
choice = {tuple(s): s[0] for s in fam}
print("  有限族的选择函数（首元素）：", {k: v for k, v in choice.items()})

# (2) 三角族无穿越集：{1,2},{2,3},{1,3} 两两相交——穷举子集
tri = [frozenset({1,2}), frozenset({2,3}), frozenset({1,3})]
has_transversal = any(
    all(len(C & S) == 1 for S in tri)
    for bits in product([0,1], repeat=3)
    for C in [frozenset(i+1 for i in range(3) if bits[i])]
)
print("  三角族 {{1,2},{2,3},{1,3}} 有穿越集？", has_transversal, "（不交性必要）")

# (3) 函数版：∀x∃y R(x,y) 压缩成 f ⊆ R——有限时构造 witness 函数
R = {(x, y) for x in range(3) for y in range(4) if y >= x}
witness = {x: min(y for (xx, y) in R if xx == x) for x in range(3)}
print("  函数版 AC（有限构造）：witness =", witness, "⊆ R:",
      all((x, witness[x]) in R for x in witness))

# ---------- 四、复合不交换（书本例） ----------
f = {1: 1, 2: 1}      # f(1)=f(2)=1
g = {1: 2, 2: 1}      # g 交换 1↔2
gf = lambda a: g[f[a]]
fg = lambda a: f[g[a]]
print("  g∘f(1) =", gf(1), " f∘g(1) =", fg(1), "（复合不交换）")

# ---------- 五、五域平方矩阵的"满射到自身"版本 ----------
print("  平方于 ℝ₊ 段（取正数近似）：双射 =",
      square_status([x/2 for x in range(1, 11)], {n*n for n in [x/2 for x in range(1,11)]})[0])

print("END ====")
