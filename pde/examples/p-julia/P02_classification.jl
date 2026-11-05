# P02 习题篇 III：分类、特征与适定性（书第 2 章）
#
# 精选：2.1-2.4（化标准形）、2.5-2.7（特征曲线/曲面）、
# 2.14-2.15（分类判别）、2.17-2.23（适定性：Hadamard 例变体）。

using Printf

println("==== P02")

# ---- (a) 2.1 型：特征方程 a11(dy)² − 2a12 dxdy + a22(dx)² = 0 ----
# 例：u_xx + 2u_xy + u_yy？D = a12²−a11a22 = 1−1 = 0 抛物
for (a11, a12, a22, tag) in [(1.0, 0.0, 1.0, "elliptic (Laplace)"),
                              (1.0, 0.0, -1.0, "hyperbolic (wave)"),
                              (1.0, 1.0, 1.0, "parabolic (D=0)"),
                              (4.0, 3.0, 1.0, "? D=9-4=5>0 hyperbolic")]
    D = a12^2 - a11 * a22
    @printf("(a) a=(%.0f,%.0f,%.0f): D = %+.1f → %s\n", a11, a12, a22, D, tag)
end
@assert (1.0^2 - 1.0 * 1.0) == 0.0 "D=0 抛物"

# ---- (b) 2.5：求 u_xx − 2u_xy 特征曲线族 ----
# a11=1, a12=−1, a22=0：(dy)² + 2 dxdy = 0 ⟹ dy(dy + 2dx) = 0
# ⟹ 特征族 y = C₁ 与 y + 2x = C₂
# 数值验证特征方向：沿 y=const，法向 (0,1)：a11·0 + 2a12·0·1 + a22·1 = 0 ✓
for (nx, ny, tag) in [(0.0, 1.0, "y=const"), (2.0, 1.0, "y+2x=const（法向 (2,1)）")]
    # 特征条件：a11 nx² + 2a12 nx ny + a22 ny² = 0（a12 = −1）
    val = 1.0 * nx^2 + 2 * (-1.0) * nx * ny + 0.0 * ny^2
    @printf("(b) 2.5 normal (%.1f,%.1f) [%s]: char eq = %.6f (=0 ✓)\n", nx, ny, tag, val)
    @assert abs(val) < 1e-12 "特征方向满足二次型为零"
end

# ---- (c) 2.7：u_xx + y u_yy = 0（Tricomi）的混合型特征 ----
# y<0 双曲：特征 dy/dx = ±(−y)^{−1/2}·? a11=1,a12=0,a22=y：
# (dy)² + y(dx)² = 0 ⟹ y<0 时 dy/dx = ±1/√(−y)
# 积分：2(−y)^{1/2} = ±x + C ⟹ 特征 x ± 2√(−y) = C
for y0 in [-1.0, -4.0]
    c1 = 1.0 + 2 * sqrt(-y0)   # 过 (1, y0) 的两族特征常数
    @printf("(c) Tricomi y=%.0f: chars through (1,%.0f): x+2√(−y)=%.4f, x−2√(−y)=%.4f\n",
            y0, y0, c1, 1 - 2 * sqrt(-y0))
end
# 数值验证：沿 x + 2√(−y) = C，方向导数核对
x0, y0 = 1.0, -1.0
C = x0 + 2 * sqrt(-y0)
# 曲线参数化 x = C − 2√(−y)：dx/dy = 1/√(−y)·? d/dy[C−2(−y)^{1/2}] = (−y)^{-1/2}
slope = (-y0)^(-0.5)
val = 1.0 * 1.0 + y0 * slope^2   # a11 (dx)² + a22 (dy)² with dy=1
@printf("    char verification: (dx)² + y(dy)² with dx/dy=%.4f: %.6f (=0 ✓)\n", slope, val)
@assert abs(val) < 1e-12

# ---- (d) 2.17-2.23 适定性面：连续依赖的数值核（01 章方法的习题版）----
# Hadamard 型：Laplace Cauchy 问题 u_n = sin(nx)sinh(ny)/n^k 的边值
# → 0 速率取决于 k；适定 ⟺ 解连续依赖。打印 1/n^k 与内部值
for k in [1.0, 2.0]
    n = 10.0
    bnd = 1 / n^k
    inner = sinh(n * 1.0) / n^k
    @printf("(d) k=%.0f: boundary sup 1/n^k = %.1e, u_n(π/2,1) = sinh(10)/n^k = %.1e\n",
            k, bnd, inner)
end
@printf("    无论 k 多大内部都爆炸：Laplace Cauchy 不适定（对一切范数）\n")
@assert sinh(10) > 1000

println("END ====")


