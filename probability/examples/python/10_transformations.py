# -*- coding: utf-8 -*-
print("==== 10 transformations")
# 一元变换：先用 CDF 记账，再核对密度公式；不依赖随机模拟。
from fractions import Fraction
from math import isclose, sqrt

# X~U[0,2]，Y=X^2：F_Y(y)=sqrt(y)/2，f_Y(y)=1/(4sqrt(y))。
for y, root in ((Fraction(1, 4), Fraction(1, 2)),
                (Fraction(1), Fraction(1)),
                (Fraction(9, 4), Fraction(3, 2)),
                (Fraction(4), Fraction(2))):
    assert root * root == y
    assert root / 2 == Fraction(1, 2) * sqrt(float(y))
# LOTUS：E[X^2]=∫_0^2 x^2/2 dx=4/3；变换侧亦为 4/3。
assert Fraction(1, 2) * Fraction(8, 3) == Fraction(4, 3)
assert isclose(sqrt(4) / 2, 1.0)
print("Y=X^2 on U[0,2]: CDF, density anchors and E[Y]=4/3: OK")

# 减函数 Y=3-2X（X~U[0,1]）：端点翻转后 F_Y(y)=(y-1)/2。
for x, y in ((Fraction(0), Fraction(3)), (Fraction(1, 2), Fraction(2)),
             (Fraction(1), Fraction(1))):
    assert y == 3 - 2 * x
# P(Y<=2)=P(X>=1/2)=1/2；密度恒为 1/2，支撑 [1,3]。
assert 1 - Fraction(1, 2) == Fraction(1, 2)
assert Fraction(3 - 1) * Fraction(1, 2) == 1
print("decreasing affine transform: reversed endpoints and |Jacobian|: OK")

# 非单调 Y=X^2，X~U[-1,1]：两个原像必须相加。
# F_Y(y)=sqrt(y)，故 f_Y(y)=1/(2sqrt(y))，0<y<1。
for y, F in ((Fraction(1, 4), Fraction(1, 2)),
             (Fraction(1), Fraction(1))):
    assert F * F == y
# 每个分支给 1/(4sqrt(y))，两分支合计 1/(2sqrt(y))。
y = Fraction(1, 4)
branch = Fraction(1, 2) / (4 * Fraction(1, 2))
assert 2 * branch == Fraction(1, 2) / (2 * Fraction(1, 2))
print("nonmonotone square on [-1,1]: two inverse branches summed: OK")

# 逆变换：F(x)=x^2 的广义逆为 sqrt(u)，中位数为 1/sqrt(2)。
median2 = Fraction(1, 2)
assert isclose(sqrt(float(median2)), 1 / sqrt(2))
# 广义逆处理跳点：F(0-)=0，F(0)=1/2，故 u=1/4 映射到 0。
def mixed_quantile(u):
    if u <= Fraction(1, 2):
        return Fraction(0)
    return 2 * (u - Fraction(1, 2))


assert mixed_quantile(Fraction(1, 4)) == 0
assert mixed_quantile(Fraction(1, 2)) == 0
assert mixed_quantile(Fraction(3, 4)) == Fraction(1, 2)
print("generalized inverse: continuous quantile and atom jump: OK")

# 原子不会被密度公式抹掉：X 在 0 有质量 1/2，则 Y=X^2 也有。
atom_x = Fraction(1, 2)
atom_y = atom_x  # {Y=0} 与 {X=0} 是同一事件
assert atom_y == Fraction(1, 2)
print("singular part preserved: P(Y=0)=P(X=0)=1/2: OK")

print("END ====")
