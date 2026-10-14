# 第 60 章：计数的机器化（Makinson Ch5）
# 四式选取 + 排列组合 + 重排（书本字母账审计）+ 容斥
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import permutations, product
from math import factorial, comb

print("==== 60")

# ---------- 一、四式选取：5 选 2 ----------
pairs = list(product(range(5), repeat=2))
print("  5 选 2 四模式：",
      f"O+R+ {len(pairs)}，O+R- {sum(a!=b for a,b in pairs)}，",
      f"O-R+ {sum(a<=b for a,b in pairs)}，O-R- {sum(a<b for a,b in pairs)}")
assert (len(pairs), sum(a != b for a, b in pairs),
        sum(a <= b for a, b in pairs), sum(a < b for a, b in pairs)) == (25, 20, 15, 10)

# ---------- 二、公式表 ----------
P = lambda n, k: factorial(n) // factorial(n - k)
print("  P(6,0..6) =", [P(6, k) for k in range(7)])
print("  C(6,0..6) =", [comb(6, k) for k in range(7)], "（杨辉第 6 行）")
print("  P(10,6) =", P(10, 6), " C(10,6) =", comb(10, 6))
print("  15 领带：", P(15, 5), "周 ≈", P(15, 5) // 52, "年")
print("  隔板法：10 人 6 任务 = C(15,6) =", comb(15, 6))
print("  冰淇淋：有序", sum(5**k for k in (1,2,3)), "vs 无序",
      sum(comb(5 + k - 1, k) for k in (1,2,3)))

# ---------- 三、重排：书本字母账审计 ----------
def rearrangements(word):
    num = factorial(len(word))
    den = 1
    for c in set(word):
        den *= factorial(word.count(c))
    return num // den
for w in ("banana", "Turramurra", "Mississippi", "Ouagadougou", "Woolloomooloo"):
    print(f"    {w:14s} 重排数 = {rearrangements(w)}")
print("    书本账：Mississippi 34650 ✓；Ouagadougou 554400 ✗（真实 831600）；")
print("    Woolloomooloo 4324320 ✗（真实 25740）——机器修正后假期去 Ouagadougou")
# banana 枚举复核
anagrams = {"".join(p) for p in permutations("banana")}
print("  banana 枚举复核：", len(anagrams), "= 6!/3!2! ✓")
assert len(anagrams) == 60 == rearrangements("banana")

# ---------- 四、容斥 ----------
print("  三人电话：5+10+7−3−2−2+1 =", 5 + 10 + 7 - 3 - 2 - 2 + 1)

print("END ====")
