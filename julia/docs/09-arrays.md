# 09 · 数组 ⭐

> 对应示例：`examples/09_arrays/`
>
> 数组是 Julia 的心脏：列主序、参数化、可视图。科学计算的手感全在这章。

## 9.1 构造族

```julia
v = [10, 20, 30]              # Vector{Int}（= Array{Int,1}）
m = [1 2 3; 4 5 6]            # Matrix{Int}（= Array{Int,2}）：空格并排、分号换行
zeros(Int, 2)                 # [0, 0]
ones(2, 2)                    # 2×2 Float64
fill("x", 3)                  # 同值填充
Vector{Float64}(undef, 3)     # 未初始化（垃圾值）——必须先写再读
collect(0:0.5:2)              # range 落实为数组
range(0, 1; length = 5)       # 等距采样（比手算步长稳）
```

字面量的类型推断规则：`[1, 2]` → Vector{Int}，`[1, 2.0]` → Vector{Float64}（promote 汇合）；混不进一个 Number 的就退化 `Any`——异构数据想清楚（16 章）。

## 9.2 索引：1 起、end、花式与掩码

```julia
a = [5, 6, 7, 8]
a[1] == 5 && a[end] == 8 && a[end-1] == 7
a[[1, 3]]          # [5, 7]——花式索引（拷贝，可重排）
a[a .> 6]          # [7, 8]——逻辑掩码（.> 是广播比较，10 章）
b = a[1:2]; b[1] = 99
a[1] == 5          # true——切片是拷贝（视图见 9.4）
```

矩阵索引 `m[i, j]`；**线性索引按列**：

```julia
m = [1 2 3; 4 5 6]
m[2, 3] == 6
m[6] == 6          # 线性下标 6 = 按列数第 6 个
m[:]               # [1, 4, 2, 5, 3, 6]——按列展开
m[1, :]            # [1, 2, 3]——行取出是一维 Vector
m[:, 1]            # [1, 4]
```

越界抛 `BoundsError`（本教程 build.ps1 强制 `--check-bounds=yes` 验证）。

## 9.3 列主序：遍历顺序决定快慢

与 C/NumPy（行主序）**相反**，Julia/Fortran/MATLAB 按列存——第 1 列在内存里连续。嵌套循环"列在外层"才顺缓存：

```julia
function sum_cols(mat)        # ✅ 快：外层 j（列）、内层 i（行）
    s = 0.0
    for j in axes(mat, 2), i in axes(mat, 1)
        s += mat[i, j]
    end
    s
end
```

`axes(m, 1)` 给该维合法下标范围（比 `1:size(m,1)` 更通用）；行列视图迭代器：

```julia
eachcol(m) |> length      # 3
collect(eachrow(m))[1]    # [1, 2, 3]——行视图是一维 Vector（不是 1×N 矩阵！实测坑）
```

## 9.4 视图 @view：切片不拷贝

```julia
col1 = @view m[:, 1]      # SubArray：引用母数组
@views begin              # 块内所有切片变视图
    col1 = m[:, 1]
end
col1[2] = 40              # 改视图 = 改母数组
m[2, 1] == 40
```

`m[:, 1]` 拷贝一整列、`@view m[:, 1]` 零拷贝——大数组热循环里视图省一大笔分配（16 章实测对比）。

## 9.5 增删改：`!` 后缀家族

```julia
push!(xs, 2, 3)      # 尾部追加（多个）
pushfirst!(xs, 0)    # 头部插入
pop!(xs)             # 尾部取走并返回
popfirst!(xs)        # 头部取走
insert!(xs, 2, 99)   # 指定位置插入
deleteat!(xs, 2)     # 按下标删
append!(xs, [7, 8])  # 拼接另一个数组到尾部
vcat([1, 2], [3])    # [1, 2, 3]（纵向连接，返回新数组）
hcat([1 2], [3 4])   # 横向连接
reshape(1:6, 2, 3)   # 重排形状（列主序：[1 3 5; 2 4 6]）
```

命名约定：**带 `!` 改原数组、不带返回新数组**（`sort!` vs `sort`，11 章）。

## 9.6 LinearAlgebra：矩阵运算是标准库

```julia
using LinearAlgebra
A = [2.0 1.0; 1.0 3.0]
A * [1.0, 1.0]          # 矩阵 × 向量 → [3, 4]
A \ [3.0, 4.0]          # 反斜杠：解 Ax = b（LU 分解）
det(A) ≈ 5.0 && tr(A) ≈ 5.0
A'                      # 共轭转置（实数即转置）
eigen([2 0; 0 5]).values     # [2.0, 5.0]
norm([3, 4]) == 5.0
dot([1, 2], [3, 4]) == 11
Matrix{Float64}(I, 2, 2)     # 单位阵（I 是 UniformScaling）
```

`A \ b`（左除）是 Julia 的招牌——比 `inv(A) * b` 快且稳，永远用它解方程。分解族复用（lu/qr/cholesky）、最小二乘、SVD/条件数与稀疏矩阵见 **13 章**。

## 9.7 坑位清单

1. **`*` 是矩阵乘、`.*` 才是对应元素乘**：`A * A` ≠ `A .* A`——NumPy 用户头号混淆（10 章细讲）。
2. **线性索引按列**：`m[6]` 是第 6 个"按列数"的元素，不是第 6 个按行数的（9.2）。
3. **eachrow 取出是一维 Vector**：不是 1×N 矩阵——形状敏感的代码注意（9.3，实测坑）。
4. **切片拷贝、@view 引用**：`b = a[1:2]` 后改 b 不影响 a；要共享用 `@view`（9.4）。
5. **`undef` 数组是垃圾值**：`Vector{Int}(undef, 3)` 内容未定义——先填再用；读未初始化内存是未定义行为（`--check-bounds` 也查不到）。
6. **`A \ b` 优先于 `inv(A) * b`**：速度与数值稳定性双杀（9.6）。
