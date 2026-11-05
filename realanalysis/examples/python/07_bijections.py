# 第 07 章 双射：Python 通道。
# 有限集合上核对像、原像、单射/满射/双射、可逆与复合。
# 运行：python -I 07_bijections.py

print("==== 07 bijections ====")


def image(f, A):
    return {f(x) for x in A}


def preimage(f, A, G):
    return {x for x in A if f(x) in G}


A = {1, 2, 3}
assert image(lambda x: 1, A) == {1}
print("const image of {1,2,3} = {1}")

Z = set(range(-5, 6))
assert preimage(lambda x: x * x, Z, {16}) == {4, -4}
print("preimage of {16} under sq = {4,-4}")


def is_injective(f, A):
    return all(f(x) != f(y) for x in A for y in A if x != y)


def is_surjective(f, A, B):
    return image(f, A) == set(B)


def is_bijective(f, A, B):
    return is_injective(f, A) and is_surjective(f, A, B)


S = {-2.0, -1.0, 0.0, 1.0, 2.0}
T = {-4.0, -2.0, 0.0, 2.0, 4.0}
assert is_injective(lambda x: 2 * x, S)
assert is_bijective(lambda x: 2 * x, S, T)
print("mul2 bijective on sample")

R = {-2.0, -1.0, 0.0, 1.0, 2.0}
assert not is_injective(lambda x: x ** 2, R)
print("square not injective")

A12, B1 = {1, 2}, {1}
assert is_surjective(lambda _: 1, A12, B1) and not is_injective(lambda _: 1, A12)
print("{1,2}->{1} surjective not injective")

A1, B12 = {1}, {1, 2}
assert is_injective(lambda _: 1, A1) and not is_surjective(lambda _: 1, A1, B12)
print("{1}->{1,2} injective not surjective")

f = lambda x: 2 * x
g = lambda y: y / 2
assert all(g(f(x)) == x for x in S)
assert all(f(g(y)) == y for y in T)
print("f and g are two-sided inverses")


def compose(g, f):
    return lambda x: g(f(x))


assert all(compose(lambda x: x ** 2, lambda x: 2 * x)(x) == 4 * x ** 2 for x in S)
assert all(compose(g, f)(x) == x for x in S)
assert all(compose(f, g)(y) == y for y in T)
print("composition: (sq o double)(x)=4x^2; inv o f = id")

print("END ====")
