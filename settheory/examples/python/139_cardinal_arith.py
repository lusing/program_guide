# -*- coding: utf-8 -*-
print("==== 139 cardinal arith")
# 第 139 章 Python：基数算术的符号计算器（书 5.2）。
# 基数表示：('fin', n) 或 ('aleph0',)；运算按定义与无穷吸收律
# （κ⊞λ = κ⊙λ = max），幂走 Cantor 梯（2^ℵ₀ = c，CH 的问号保留）。

FIN = lambda n: ('fin', n)
A0 = ('aleph0',)
INF = {A0, }

def kmax(k1, k2):
    if k1 == k2:
        return k1
    if k1 in INF:
        return k1 if k2 not in INF or False else k2 if False else k1
    if k2 in INF:
        return k2
    return FIN(max(k1[1], k2[1]))

def kadd(k1, k2):
    """κ⊞λ = |A∪B|：有限算术；无穷吸收（max）。"""
    if k1 in INF or k2 in INF:
        return kmax(k1, k2)
    return FIN(k1[1] + k2[1])

def kmul(k1, k2):
    """κ⊙λ = |A×B|：有限算术；无穷吸收（定理 5.2.5/5.2.6）。"""
    if k1 in INF or k2 in INF:
        return kmax(k1, k2)
    return FIN(k1[1] * k2[1])

def kpow(base, exp):
    """κ^λ：有限情形算术；ℵ₀ 的有限次幂吸收；2^ℵ₀ = c（记号保留，
    CH 问 c =? ℵ₁——第 141 章讨论其独立性）。"""
    if exp == FIN(0):
        return FIN(1)
    if base == FIN(0):
        return FIN(0)
    if base in INF:
        if exp in INF:
            return ('pow', base, exp)       # ℵ₀^ℵ₀ = 2^ℵ₀ = c（定理）
        return A0 if exp[1] >= 1 else FIN(1)
    if base == FIN(1):
        return FIN(1)
    if exp in INF:
        return ('c',)                        # n^ℵ₀ = c（n ≥ 2）
    return FIN(base[1] ** exp[1])

# 书 5.2 全部定律的审计
assert kadd(FIN(3), FIN(4)) == FIN(7)
assert kadd(A0, A0) == A0                    # ℵ₀ ⊞ ℵ₀ = ℵ₀（3.3.7）
assert kadd(A0, FIN(5)) == A0
assert kmul(A0, A0) == A0                    # 5.2.5
assert kmul(A0, FIN(7)) == A0
assert kmul(FIN(3), FIN(4)) == FIN(12)
assert kadd(A0, A0) == kmul(A0, A0) == kmax(A0, A0)   # 5.2.6
# κ² = κ⊞κ（书 5.2.4 的 {0,1}×A 分解）：κ⊙2 = κ⊞κ = κ
assert kmul(A0, FIN(2)) == kadd(A0, A0) == A0
# 幂：有限对照
assert kpow(FIN(2), FIN(3)) == FIN(8)
assert kpow(FIN(3), FIN(0)) == FIN(1)
# 幂：无穷哨兵
assert kpow(FIN(2), A0) == ('c',)            # 2^ℵ₀ = c（Cantor）
assert kpow(A0, FIN(1)) == A0
assert kpow(A0, FIN(3)) == A0                # ℵ₀³ = ℵ₀
assert kpow(A0, A0) == ('pow', A0, A0)       # ℵ₀^ℵ₀（= c，见 17 章）
print("cardinal arithmetic: all book laws 5.2 audited symbolically: OK")

# 有限审计的镜像：n+n ≠ n、n·n ≠ n——吸收律是无穷专利
for n in (2, 3, 5):
    assert kadd(FIN(n), FIN(n)) != FIN(n)
    assert kmul(FIN(n), FIN(n)) != FIN(n)
print("finite contrast: no absorption below aleph0: OK")

# 层计数（与 Julia 通道互证 5.2.5 的骨架）：shell k 有 2k+1 个元素
for k in range(9):
    layer = [(a, k) for a in range(k)] + [(k, b) for b in range(k + 1)]
    assert len(layer) == 2 * k + 1
print("layer sizes 2k+1: the standard-order skeleton of k*k=k: OK")
print("END ====")
