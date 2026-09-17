# 13 · 线性代数与稀疏矩阵 ⭐

> 对应示例：`examples/13_linalg/`
>
> 这是 Julia 的主场之一：`LinearAlgebra` + `SparseArrays` 全是标准库，底层接 BLAS/LAPACK/ SuiteSparse——解方程、做分解、碰大规模稀疏问题不用离开语言。09 章讲了 `*`、`\`、det/eigen 的入门；本章深入**分解复用、最小二乘、条件数、稀疏求解与 BLAS 线程**。

## 13.1 分解（factorization）：一次分解、多次求解

```julia
F = lu(A)              # LU 分解（部分选主元）——O(n³) 的活只干一次
F \ b1                 # 第一次求解：与 A \ b1 结果一致
F \ b2                 # 第二次求解：只做 O(n²) 回代——这就是分解复用
```

同一矩阵解多个右端项时，`A \ b` 每次都重新分解；`F = lu(A)` 后 `F \ b` 复用——批量求解的标准姿势。其他分解同型：`qr(A)`、`svd(A)`、`eigen(A)` 都返回可反复使用的分解对象。

**对称正定 → Cholesky**（约 2 倍速、无选主元、内存减半）：

```julia
C = [4.0 2.0; 2.0 3.0]        # SPD
Lc = cholesky(C).L            # C ≈ L·Lᵀ
cholesky(C) \ [2.0, 5.0]
isposdef(C) && !isposdef([1.0 2.0; 2.0 1.0])
cholesky([1.0 2.0; 2.0 1.0])  # PosDefException——不定矩阵直接拒绝（异常族见 22 章）
```

## 13.2 特征值、奇异值与条件数

```julia
E = eigen([2.0 0.0; 0.0 5.0])
E.values                      # [2.0, 5.0]
E.vectors' * A * E.vectors ≈ Diagonal(E.values)   # 对称矩阵：正交对角化
U, S, V = svd(M)              # 任何矩阵：M = U·Σ·Vᵀ
U * Diagonal(S) * V' ≈ M      # SVD 重建（低秩逼近、伪逆、PCA 的底座）
rank(M) == 2 && cond(M) > 1   # 条件数：解对扰动的放大倍数——越大越病态
```

`cond` 是数值线性代数的"体检指标"：cond ~ 10ᵏ 意味着结果可能丢 k 位有效数字（03 章的稳定性直觉在矩阵世界的化身）。

## 13.3 最小二乘：矩形 `A \ b` 与正规方程的几何

```julia
V = [x^d for x in xs, d in 0:1]   # Vandermonde 设计矩阵（11×2）：拟合 y = a + b·x
coef = V \ ys                     # 矩形超定系统：内部走 QR，返回最小二乘解
resid = V * coef - ys
V' * resid ≈ zeros(2)             # Aᵀ(Ax−b) = 0：残差正交于列空间——LS 的定义本身
```

实测：带噪声数据拟合出 `coef ≈ [0.507, 1.198]`（真值 [0.5, 1.2]）。**用 `A \ b`，别手写正规方程 `A'A \ A'b`**——后者条件数平方（cond(A)²），噪声被放大两次。

## 13.4 稀疏矩阵：SparseArrays 与 CSC

```julia
using SparseArrays
S = sprand(rng, n, n, 2e-4)                        # 随机稀疏（平均每行 2 个非零）
S = S + sparse(1:n, 1:n, fill(3.0, n), n, n)       # COO 三元组构造对角项（保证非奇异）
nnz(S) / n^2                                       # 稠密度：1 万阶仅 ~3e-4
S \ rhs                                            # 稀疏直接法（SuiteSparse/UMFPACK）
S2 = sparse([1, 3], [2, 3], [5.0, 7.0], 3, 3)      # (行, 列, 值) 三元组构造
Matrix(S2); sparse(Matrix(S2))                     # 稠密 ↔ 稀疏互转
spzeros(3, 3)                                      # 稀疏零矩阵
```

存储是 **CSC**（压缩稀疏列：按列存非零值+行索引）——与 MATLAB 一致；`SparseMatrixCSC` 支持索引、`*`、`\`、 Kron 等。规模直觉（实测 1 万阶）：稀疏部分 nnz≈2 万，加对角≈3 万——**稠密存要 800 MB 且分解 O(n³)，稀疏只存非零、求解按 nnz 量级走**。偏微分方程离散出来的就是这类矩阵（五点差分 → 每行 5 个非零）。

## 13.5 BLAS/LAPACK：隐形引擎与线程

```julia
B * Cm                          # 600×600 实测 ~3 ms——走 OpenBLAS，自带多线程
BLAS.get_num_threads()          # 10（本机）——独立于 Julia 的 -t 线程池！
BLAS.set_num_threads(k)         # 可调（与 @threads 争核时要有意识地分配）
```

经验法则：**中等规模以上（~100×100 起）的矩阵运算交给 BLAS**——十年调优的缓存分块不是手写循环能追的；小内核/元素级变换才值得手写+广播融合（16 章的分界线）。注意 BLAS 线程与 `Threads` 池（20 章）是两套，混用时别把两层都拉满。

## 13.6 坑位清单

1. **`A \ b` 每次都分解**：同矩阵多次求解要 `F = lu(A)`（或 qr/cholesky）复用——O(n³) 变 O(n²)（13.1）。
2. **正规方程平方条件数**：最小二乘直接 `A \ b`（内部 QR），别 `A'A \ A'b`（13.3）。
3. **`sprand` 可能奇异**：随机稀疏平均每行 2 个非零时约 13% 的行是空的（泊松分布）——教学/测试用"加对角占优项"保证非奇异（13.4 实测）。
4. **Cholesky 只吃正定**：对称不够——`isposdef` 先查，否则 PosDefException（13.1）。
5. **BLAS 线程独立于 `-t`**：`BLAS.get_num_threads()` 另算一份核——与 Julia 线程混跑要显式调配（13.5）。
6. **稀疏矩阵切西瓜要小心**：`S[i, :]` 取行比取列贵（CSC 按列存）——热路径取列视图/转置布局。
