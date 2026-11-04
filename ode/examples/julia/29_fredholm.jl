println("==== 29 fredholm")

# 第 29 章：积分方程——Neumann 级数、Volterra、差核 Laplace。

# --- (a) 退化核 Fredholm：K = 1，y = f + λ∫₀¹ y ⟹ y = f/(1-λ) ---
f0 = 1.0
lam = 0.5
yexact = f0 / (1 - lam * 1.0)     # 2.0
y = f0
for n in 1:40
    global y = f0 + lam * y       # ∫₀¹ (1)·y dt = y·1（退化核逐次逼近是标量递推）
end
@assert abs(y - yexact) < 1e-10 "Neumann 级数 → 精确解"
# 收敛率：|λ(b−a)| = 0.5 几何
@assert abs(y - 2.0) < 1e-10
println("退化核 Fredholm（λ=0.5）：迭代 40 轮 → y = 2.0（几何收敛 |λ(b−a)| = 0.5）")

# --- (b) 发散演示：λ(b−a) = 2 时迭代发散 ---
y2 = 1.0
diverged = false
for n in 1:60
    global y2 = 1.0 + 2.0 * y2
    abs(y2) > 1e10 && (global diverged = true; break)
end
@assert diverged "λ(b−a)=2 ⟹ Neumann 级数发散（特征值共振）"
println("共振演示：λ(b−a) = 2 ⟹ 迭代发散（Neumann 级数在特征值处失效）")

# --- (c) Volterra：y = 1 + ∫₀ˣ (x−t)y dt ⟹ y″ = y + ... 实为 y = e^x ---
# 逐次逼近（梯形积分）
function volterra_iter(N)
    ngrid = 400
    xs = range(0, 1; length = ngrid + 1)
    h = 1 / ngrid
    y = ones(ngrid + 1)            # y0 = f = 1
    for _ in 1:N
        ynew = ones(ngrid + 1)
        for i in 2:(ngrid + 1)
            x = xs[i]
            # ∫₀ˣ (x−t)y(t)dt 梯形
            s = 0.0
            for j in 1:(i - 1)
                t = xs[j]
                s += (x - t) * y[j]
            end
            inner = 2 * (s * h)  # 占位修正——直接重算
            s2 = 0.0
            for j in 1:i
                t = xs[j]
                w = (j == 1 || j == i) ? 0.5 : 1.0
                s2 += w * (x - t) * y[j]
            end
            ynew[i] = 1.0 + s2 * h
        end
        y = ynew
    end
    y[end]
end
yv = volterra_iter(30)
# 真解：y = 1 + ∫(x−t)e^t → y″ = y？验证 y = e^x 是解：∫₀ˣ(x−t)e^t dt = e^x − 1 − x
# ⟹ 1 + (e^x − 1 − x) = e^x − x ≠ e^x。真解满足 y = 1 + ∫(x−t)y ⟹ y″ = y, y(0)=1, y'(0)=0
# ⟹ y = cosh x
@assert abs(yv - cosh(1.0)) < 1e-4 "Volterra 真解 cosh x"
println("Volterra（K = x−t，λ=1）：迭代 30 轮 → y(1) = ", round(yv; digits=6), " vs cosh(1) = ", round(cosh(1.0); digits=6))

# --- (d) 差核 Laplace：y = 1 + ∫₀ˣ e^{−(x−t)}y(t)dt ⟹ Y = 1/[s(1−1/(s+1))] ---
# = (s+1)/s² ⟹ y = 1 + x（核对：y′′−y′ = 0? 直接验证）
ysol(t) = 1 + t
for t in [0.5, 1.3, 2.0]
    # ∫₀ᵗ e^{-(t-τ)}(1+τ)dτ = [(1+τ)e^{-(t-τ)} + ...] 手算 = 1 + t − e^{−t}
    # ⟹ 1 + (1 + t − e^{−t}) = 2 + t − e^{−t} ≠ 1+t？
    # 重算：y = 1 + K*y 取变换 Y = 1/s + (1/(s+1))Y ⟹ Y(1 − 1/(s+1)) = 1/s
    # Y·s/(s+1) = 1/s ⟹ Y = (s+1)/s² = 1/s² + 1/s ⟹ y = x + 1 ✓
    nothing
end
# 数值迭代验证 y = x + 1
function diffkernel_iter(N)
    ngrid = 400
    xs = range(0, 2; length = ngrid + 1)
    h = 2 / ngrid
    y = ones(ngrid + 1)
    for _ in 1:N
        ynew = ones(ngrid + 1)
        for i in 2:(ngrid + 1)
            x = xs[i]
            s2 = 0.0
            for j in 1:i
                t = xs[j]
                w = (j == 1 || j == i) ? 0.5 : 1.0
                s2 += w * exp(-(x - t)) * y[j]
            end
            ynew[i] = 1.0 + s2 * h
        end
        y = ynew
    end
    (y, xs)
end
y3, xs3 = diffkernel_iter(40)
for i in [100, 200, 401]
    @assert abs(y3[i] - (1 + xs3[i])) < 2e-3 "差核解 y = 1+x"
end
println("差核 Laplace：y = 1 + x（变换解 (s+1)/s² 反变换）与迭代一致 ✓")

println("END ====")
