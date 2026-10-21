# -*- coding: utf-8 -*-
print("==== 01 russell")
# 第 01 章 Python：哥德尔编码——公式如何成为自然数。
# 书 1.2 的方案：初始符号配自然数，公式是符号码的有穷序列
# (n1,...,nm)，令 p1..pm 为前 m 个素数，则 p1^n1 * ... * pm^nm
# 由公式唯一决定。本单元实现编码/解码并审计唯一性（纯标准库）。
import itertools

# 符号码表（书只示范了 1=左括号、5=否定词，其余为教程约定；
# 变元 v_i 的码取 12+i，全部 ≥ 1——指数非零是唯一性的关键）
FIXED = {'(': 1, ')': 2, 'in': 3, '=': 4, 'not': 5, 'and': 6,
         'or': 7, 'imp': 8, 'iff': 9, 'all': 10, 'ex': 11}


def nth_prime(k):
    """第 k 个素数（k 很小，试除法足够）。"""
    n, found = 1, 0
    while found < k:
        n += 1
        if all(n % d for d in range(2, int(n ** 0.5) + 1)):
            found += 1
    return n


def factorize(m):
    """m 的素因子分解（试除法，m 在本单元规模下很小）。"""
    f = {}
    d = 2
    while d * d <= m:
        while m % d == 0:
            f[d] = f.get(d, 0) + 1
            m //= d
        d += 1
    if m > 1:
        f[m] = f.get(m, 0) + 1
    return f


def code(tok):
    if tok in FIXED:
        return FIXED[tok]
    assert tok.startswith('v')
    return 12 + int(tok[1:])


def encode(seq):
    """公式（符号串）→ 素数幂乘积 p_i^{n_i}。"""
    out = 1
    for i, tok in enumerate(seq, start=1):
        out *= nth_prime(i) ** code(tok)
    return out


def primes_up_to(m):
    return [n for n in range(2, m + 1)
            if all(n % d for d in range(2, int(n ** 0.5) + 1))]


def decode(n):
    """素数幂乘积 → 符号码序列。唯一分解保证良定。"""
    f = factorize(n)
    assert f, "编码必须 ≥ 2"
    m = max(f)
    out = []
    for p in primes_up_to(m):
        e = f.get(p, 0)
        assert e >= 1, "素数缺位：非法编码"
        out.append(e)
    return out


# 往返测试：∀v0 ∃v1 ¬(v0 ∈ v1) 的逐步编码
phi = ['all', 'v0', 'ex', 'v1', 'not', '(', 'v0', 'in', 'v1', ')']
n_phi = encode(phi)
assert decode(n_phi) == [code(t) for t in phi]
print("code of 'ALL v0 EX v1 NOT (v0 IN v1)' =", n_phi)

# 唯一性审计 1：同长的不同公式编码必不同（素数幂互异）
short = []
for L in (1, 2, 3):
    for combo in itertools.product(['in', '=', 'not', 'and'], repeat=L):
        short.append(list(combo))
codes = [encode(s) for s in short]
assert len(set(codes)) == len(codes) == len(short)
print("injectivity: all %d short formulas get distinct codes: OK" % len(short))

# 唯一性审计 2：长度由分解中素数的个数读出（指数全 ≥ 1）
for s, c in zip(short, codes):
    assert len(factorize(c)) == len(s)
print("length readable: number of distinct prime factors = formula length: OK")

# 证明是公式的序列：序列的序列——再编码一层即成单个自然数。
# （真实公式码的二次幂指数超过 10^87，演示用玩具规模的码。）
def encode_nums(nums):
    """数列 → 素数幂乘积 p_i^{nums[i]}（第二层编码）。"""
    out = 1
    for i, v in enumerate(nums, start=1):
        out *= nth_prime(i) ** v
    return out


proof = [encode(['in']), encode(['not'])]            # 玩具"证明"：两个单符号公式
n_proof = encode_nums(proof)
assert n_proof == 2 ** 8 * 3 ** 32                   # 手算复核：p1^8 * p2^32
print("proofs are finite sequences of formulas -> codeable as one number: OK")
print("END ====")
