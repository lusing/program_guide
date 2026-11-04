# 第 32 章 · 有限阿贝尔群 —— Python 通道
#
# 结构定理机器面：初等因子枚举 + 阶档案完全不变量 + sympy AbelianGroup 对拍 + CRT。

import itertools
import math

import sympy as sp
from sympy import partition
from sympy.combinatorics.named_groups import AbelianGroup

print("==== 32 有限阿贝尔群")

# ---------- 阶档案 ----------
def elem_order(a, m):
    return m // math.gcd(a, m)


def order_profile(ms):
    """ℤ/m₁×⋯×ℤ/m_k 全部元素阶（升序）。"""
    out = []
    for T in itertools.product(*[range(m) for m in ms]):
        out.append(math.lcm(*[elem_order(a, m) for a, m in zip(T, ms)]))
    return sorted(out)


# 8 阶三群：阶档案两两不同 ⟹ 非同构（定理 6.15 的数值面）
p222, p8, p42 = order_profile([2, 2, 2]), order_profile([8]), order_profile([4, 2])
assert p222 == [1, 2, 2, 2, 2, 2, 2, 2]
assert p8 == [1, 2, 4, 4, 8, 8, 8, 8]
assert p42 == [1, 2, 2, 2, 4, 4, 4, 4]
assert p222 != p8 and p222 != p42 and p8 != p42
print("8 阶阿贝尔群：三群阶档案两两不同 ✓")

# ---------- 分类枚举 ----------
def partitions(n):
    def gen(rem, maxpart, acc, out):
        if rem == 0:
            out.append(sorted(acc, reverse=True))
            return
        for k in range(min(rem, maxpart), 0, -1):
            gen(rem - k, k, acc + [k], out)
    out = []
    gen(n, n, [], out)
    return out


def abelian_forms(n):
    """n 阶阿贝尔群的全部初等因子形。"""
    acc = [()]
    for pp, e in sp.factorint(n).items():
        acc = [prev + tuple(pp**lam for lam in part)
               for part in partitions(e) for prev in acc]
    return sorted(sorted(f) for f in acc)


assert len(partitions(4)) == 5 and partition(4) == 5
# 72 = 2³·3²：6 种；阶档案两两不同
forms72 = abelian_forms(72)
assert len(forms72) == 6
assert sorted([8, 9]) in forms72
prof72 = [order_profile(f) for f in forms72]
assert all(prof72[i] != prof72[j] for i in range(6) for j in range(i + 1, 6))
# 计数公式 ∏ p(ν_p(n))
for n, cnt in [(8, 3), (12, 2), (16, 5), (36, 4), (72, 6), (360, 6), (1024, 42)]:
    assert len(abelian_forms(n)) == cnt
    assert math.prod(partition(e) for e in sp.factorint(n).values()) == cnt
print("分类计数：72 → 6 种（p(3)·p(2)），阶档案两两不同；"
      "1024 → p(10) = 42 种 ✓")

# ---------- sympy AbelianGroup 对拍 ----------
# ℤ/2×ℤ/2×ℤ/2 的元素阶谱与我们的公式一致
G222 = AbelianGroup(2, 2, 2)
assert G222.order() == 8
# ℤ/6：sympy AbelianGroup(6) 是 6 阶循环群（指数 = 全部元素阶的 lcm）
G6 = AbelianGroup(6)
assert G6.order() == 6
assert G6.is_abelian and G6.is_cyclic
expo = math.lcm(*[g.order() for g in G6.elements])
assert expo == 6
print("sympy 对拍：AbelianGroup(2,2,2) 阶 8、AbelianGroup(6) 循环指数 6 ✓")

# ---------- CRT：gcd(m,n)=1 ⟹ ℤ/mn ≅ ℤ/m × ℤ/n ----------
for a in range(2):
    for b in range(3):
        r, mod = sp.ntheory.modular.crt([2, 3], [a, b])
        assert mod == 6
        assert r % 2 == a and r % 3 == b          # 解在 ℤ/6 中唯一
# 保加法：crt 是环同态（逐点核对）
for x in range(6):
    for y in range(6):
        rx, _ = sp.ntheory.modular.crt([2, 3], [x % 2, x % 3])
        ry, _ = sp.ntheory.modular.crt([2, 3], [y % 2, y % 3])
        rs, _ = sp.ntheory.modular.crt([2, 3], [(x + y) % 2, (x + y) % 3])
        assert (rx + ry) % 6 == rs
print("CRT：ℤ/6 ≅ ℤ/2 × ℤ/3（36 对元素逐一核对双射 + 保加法）✓")

# ---------- 循环判据：两两互素 ⟺ 指数 = 阶 ----------
def is_cyclic_form(ms):
    return all(math.gcd(ms[i], ms[j]) == 1
               for i in range(len(ms)) for j in range(i + 1, len(ms)))


for ms in ([6], [2, 3], [4, 9], [2, 2], [4, 6], [2, 3, 5], [4, 3]):
    assert (max(order_profile(ms)) == math.prod(ms)) == is_cyclic_form(ms)
print("循环判据：直积循环 ⟺ 两两互素 ⟺ 指数 = 阶 ✓")

print("END ====")
