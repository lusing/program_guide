# 第 20 章 总结：Python 通道。
# 5 后面有 6；|3+(-1)| 不超过 3+1；两半加回 1。
# 并集的补集等于补集的交集。公比 1/2 的和是 2。
# 运行：python -I 20_summary.py

from fractions import Fraction

print("==== 20 review ====")

assert 6 > 5
print("6 is past 5")

assert abs(3 + -1) <= abs(3) + abs(-1)
print("|3 + (-1)| does not exceed |3| + |-1|")

assert Fraction(1, 2) + Fraction(1, 2) == 1
print("two halves add back to 1")

U = {1, 2, 3}
A = {1}
B = {2}
assert U - (A | B) == (U - A) & (U - B)
print("the complement of a union is the intersection of the complements")

assert 1 / (1 - Fraction(1, 2)) == 2
print("1 / (1 - 1/2) equals 2")

print("END ====")
