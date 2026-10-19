import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 02 monotone-class")

# 第 02 章：σ / 单调 / λ 三种闭包的有限模型（与 Julia 对拍，
# 算法独立实现：递归不动点而非 while 循环）。

UNIV = frozenset({1, 2, 3, 4})

def sigma_closure(C):
    S = set(C)
    while True:
        new = set(S)
        for u in S:
            new.add(UNIV - u)
        for u in S:
            for v in S:
                new.add(u | v)
        if new == S:
            return S
        S = new

def monotone_closure(C):
    S = set(C)
    while True:
        new = set(S)
        for u in S:
            for v in S:
                if u <= v or v <= u:  # 可比对
                    new.add(u | v)
                    new.add(u & v)
        if new == S:
            return S
        S = new

def lambda_closure(C):
    S = set(C) | {UNIV}
    while True:
        new = set(S)
        for u in S:
            for v in S:
                if v <= u:
                    new.add(u - v)          # 真差
                if u.isdisjoint(v):
                    new.add(u | v)          # 不交并
        if new == S:
            return S
        S = new

# 实验一：π-系 {∅, 单点×4}：λ = σ = 全幂集；单调闭包原地不动
gen1 = [frozenset({k}) for k in (1, 2, 3, 4)] + [frozenset()]
S_sigma = sigma_closure(gen1)
S_lambda = lambda_closure(gen1)
S_mono = monotone_closure(gen1)
print(f"π-系 {{∅,单点×4}}：σ = {len(S_sigma)}，λ = {len(S_lambda)}，单调 = {len(S_mono)}")
assert S_sigma == S_lambda, "π-系上 λ = σ（π-λ 定理）"
assert len(S_mono) == 5, "单调闭包不动（有限退化）"

# 实验二：非 π-系 {{1,2},{2,3}}：λ 严格小于 σ
gen2 = [frozenset({1, 2}), frozenset({2, 3})]
S2_sigma = sigma_closure(gen2)
S2_lambda = lambda_closure(gen2)
print(f"非 π-系 {{1,2}},{{2,3}}：σ = {len(S2_sigma)}，λ = {len(S2_lambda)}")
assert S2_lambda < S2_sigma, "π 条件不可去"

# 实验三：代数 {∅,{1,2},{3,4},Ω}：σ = 单调 = 自身
gen3 = [frozenset(), frozenset({1, 2}), frozenset({3, 4}), UNIV]
assert sigma_closure(gen3) == monotone_closure(gen3) == set(gen3)
print("代数 {∅,{1,2},{3,4},Ω}：σ = 单调 = 自身（有限代数即 σ-代数）")

# 实验四：嵌套链（π-系）
gen4 = [frozenset({1}), frozenset({1, 2}), frozenset({1, 2, 3})]
assert sigma_closure(gen4) == lambda_closure(gen4)
print(f"嵌套链：σ = λ = {len(sigma_closure(gen4))}")

print("END ====")
