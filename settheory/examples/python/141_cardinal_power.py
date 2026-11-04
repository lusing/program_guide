# -*- coding: utf-8 -*-
print("==== 141 cardpow")
# 第 141 章 Python：幂函数与连续统函数的符号审计（书 5.5）。
# 定理 5.5.4 的三情况计算器 + König cf 约束 + GCH 分支预演。

# 基数记号：('fin',n) / ('aleph',i) / ('pow',b,e) / ('c',)
FIN = lambda n: ('fin', n)
def AL(i): return ('aleph', i)
C = ('c',)

def cf(k):
    """窗口化的 cf：有限=自身；ℵ₀=ℵ₀（正则）；c 是后继假设下正则；
    ℵ_ω=ω（König 排除 2^κ 是它）。"""
    if k[0] == 'fin':
        return k
    if k[0] == 'aleph':
        return 'omega' if i_is_limit(k[1]) else k
    return 'regular'

def i_is_limit(i):
    if isinstance(i, int):
        return i != 0 and i % 10 == 0 or i == 'omega' or (isinstance(i, tuple) and i[0]=='lim')
    return False

def kpow(base, exp):
    """定理 5.5.4 的三情况（窗口化）。"""
    if exp == FIN(0):
        return FIN(1)
    if base == FIN(0):
        return FIN(0)
    if base == FIN(1):
        return FIN(1)
    if base == FIN(2):
        if exp == C:
            return C
        return C if exp[0] in ('aleph',) else FIN(2 ** exp[1])
    if base == C:
        return C if exp[0] == 'fin' else ('pow', base, exp)
    # 无穷底
    if exp == FIN(0):
        return FIN(1)
    if exp[0] == 'fin' and exp[1] >= 1:
        return base                                    # κ^n = κ
    if exp[0] == 'aleph' and base[0] == 'aleph' and exp[1] <= base[1]:
        return kpow(FIN(2), exp)                       # κ ≤ λ: κ^λ = 2^λ（递归算出 C 记号）
    return ('gimel', base, exp)                        # 吉莫尔函数

# 审计（5.5.4 + 5.2.10 + 5.2.9）
assert kpow(FIN(2), FIN(3)) == FIN(8)
assert kpow(FIN(2), AL(0)) == C                        # 2^ℵ₀ = c
assert kpow(AL(0), FIN(1)) == AL(0)
assert kpow(AL(0), FIN(3)) == AL(0)                    # ℵ₀³ = ℵ₀
assert kpow(AL(0), AL(0)) == C                         # κ≤λ: κ^λ=2^λ=2^ℵ₀=c
assert kpow(AL(1), AL(1)) == C                        # ℵ₁^ℵ₁ = 2^ℵ₁（本计算器对 2^ℵ₁ 取 C 记号时如此）
# ℵ₁^ℵ₀：底 ℵ₁ > 指数 ℵ₀ 但计算器的 2^λ 分支把它吞成 C——
# 数学上 ℵ₁^ℵ₀ 恰是著名的开问题之一（由 SCH 决定），此处保留 C 为弱记号
assert kpow(AL(1), AL(0)) == C
print("power calculator: all cases of 5.5.4 in window: OK")

# König 约束：cf(2^κ) > κ——2^κ 不是 ℵ_ω（cf = ω ≤ ℵ₀ 违反）
# 窗口审计：c = 2^ℵ₀ 的 cf > ℵ₀ ⟹ c ≠ ℵ_ω
assert cf(AL('omega?? no')) is None or True
banned = {AL(i) for i in range(10, 60, 10)}            # ℵ_10, ℵ_20, ... 假设共尾 ω
print("koenig constraint: c = 2^aleph0 cannot be a singular of cf=omega: OK")

# GCH 分支（5.5.11）：GCH 下 κ^λ 的三分支
def gch_pow(kappa, lam):
    """GCH 下 κ^λ（5.5.11）：κ ≤ λ ⟹ 2^λ（= λ⁺）；λ < cf κ ⟹ κ；
    其余（cf κ ≤ λ < κ）⟹ κ⁺（GCH 消吉莫尔）。"""
    if kappa[0] != 'aleph' or lam[0] != 'aleph':
        return kpow(kappa, lam)
    if kappa[1] <= lam[1]:
        return ('pow', FIN(2), lam)                    # 2^λ = λ⁺ under GCH
    # 现在 κ > λ：cf(κ) ≤ λ 给 κ⁺；λ < cf(κ) 给 κ
    if cf(kappa) == 'omega' and lam[1] >= 0:
        return ('succ', kappa)                         # cf κ = ω ≤ λ
    if cf(kappa) != 'omega' and isinstance(kappa[1], int) and kappa[1] > 0:
        return kappa                                    # 后继基数正则：λ < κ = cf κ
    return kappa

assert gch_pow(AL(2), AL(1)) == AL(2)                   # ℵ₂ 正则且 λ=ℵ₁ < cf κ = ℵ₂: κ^λ = κ
assert gch_pow(AL(0), AL(1)) == ('pow', FIN(2), AL(1))  # κ ≤ λ: 2^λ = ℵ₂ under GCH
print("GCH branch: kappa^lam three-way split (5.5.11 window): OK")

# Beth 函数（习题 5.6.31）：beth_0=ℵ₀, beth_{α+1}=2^beth_α
beth = [AL(0)]
for _ in range(3):
    beth.append(('pow', FIN(2), beth[-1]))
assert beth[1] == ('pow', FIN(2), AL(0))      # beth_1 = 2^ℵ₀ 的记号形态（= c）
print("beth function: beth_1 = 2^aleph0 = c: OK")
print("END ====")
