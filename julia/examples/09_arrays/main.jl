# 09 数组 ⭐：Array{T,N}、构造族、索引/切片/视图、列主序、增删、LinearAlgebra
# 运行：julia --startup-file=no main.jl

# ═══ 09.1 构造族：字面量、zeros/ones/fill/undef/range
v = [10, 20, 30]                       # Vector{Int} = Array{Int,1}
m = [1 2 3; 4 5 6]                     # Matrix{Int} = Array{Int,2}（分号换行、空格并排）
@assert v isa Vector{Int} && m == [1 2 3; 4 5 6]
@assert size(m) == (2, 3) && length(m) == 6
@assert zeros(Int, 2) == [0, 0] && ones(2, 2) == [1.0 1.0; 1.0 1.0]
@assert fill("x", 3) == ["x", "x", "x"]
u = Vector{Float64}(undef, 3)          # 未初始化：内容是"垃圾"，必须先写再读
u .= 0.0                               # 用广播整体填 0（.= 见 10 章）
@assert u == [0.0, 0.0, 0.0]
@assert collect(0:0.5:2) == [0.0, 0.5, 1.0, 1.5, 2.0]
@assert collect(range(0, 1; length = 5)) == [0, 0.25, 0.5, 0.75, 1]

# ═══ 09.2 索引：从 1 开始；end 是最后一个下标；花式索引与逻辑索引
a = [5, 6, 7, 8]
@assert a[1] == 5 && a[end] == 8 && a[end-1] == 7
@assert a[[1, 3]] == [5, 7]            # 花式索引：拷贝
@assert a[a .> 6] == [7, 8]            # 逻辑索引：掩码
@assert a[1:2] == [5, 6]               # 范围切片：视图语义（copies? 范围切片返回 copy）
b = a[1:2]; b[1] = 99
@assert a[1] == 5                      # 改 b 不影响 a——切片是拷贝

# 矩阵索引：m[i, j]、线性索引按列、 cartesian
@assert m[2, 3] == 6
@assert m[6] == 6                      # 列主序线性索引：6 = 第 6 个（按列数）
@assert m[:] == [1, 4, 2, 5, 3, 6]     # 按列展开
@assert m[1, :] == [1, 2, 3]           # 第 1 行（注意：行取出是 Vector）
@assert m[:, 1] == [1, 4]              # 第 1 列

# ═══ 09.3 列主序（column-major）：按列遍历快，按行遍历慢
# 与 C/NumPy（行主序）相反！nested for 的正确顺序是"列在外层"
function sum_cols(mat)                 # 快版：外层列 j，内层行 i
    s = 0.0
    for j in axes(mat, 2), i in axes(mat, 1)
        s += mat[i, j]
    end
    s
end
@assert sum_cols(m) == 21.0
@assert eachcol(m) |> length == 3      # eachrow/eachcol：行列视图迭代器
@assert collect(eachrow(m))[1] == [1, 2, 3]   # 行取出是一维 Vector 视图（不是 1×N 矩阵！）

# ═══ 09.4 视图 @view：不拷贝的切片（性能与原地修改）
@views begin
    col1 = m[:, 1]                     # @views 让块内切片全变视图
end
col1[2] = 40                           # 视图：改它就是改 m
@assert m[2, 1] == 40
@assert @view(a[2:3]) isa SubArray     # 单个视图用 @view
m[2, 1] = 4                            # 恢复

# ═══ 09.5 增删改：push!/pop!/insert!/deleteat!——叹号后缀=就地修改约定
xs = [1]
push!(xs, 2, 3)                        # 尾部追加
pushfirst!(xs, 0)                      # 头部插入
@assert xs == [0, 1, 2, 3]
@assert pop!(xs) == 3 && xs == [0, 1, 2]
@assert popfirst!(xs) == 0 && xs == [1, 2]
insert!(xs, 2, 99)
@assert xs == [1, 99, 2]
deleteat!(xs, 2)
@assert xs == [1, 2]
append!(xs, [7, 8])
@assert xs == [1, 2, 7, 8]
# 拼接与 reshape
@assert vcat([1, 2], [3]) == [1, 2, 3]
@assert hcat([1 2], [3 4]) == [1 2 3 4]
@assert reshape(1:6, 2, 3) == [1 3 5; 2 4 6]

# ═══ 09.6 LinearAlgebra：矩阵运算是标准库（不是语言核心，但总在身边）
using LinearAlgebra
A = [2.0 1.0; 1.0 3.0]
y = A * [1.0, 1.0]                     # 矩阵 × 向量
@assert y == [3.0, 4.0]
x = A \ [3.0, 4.0]                     # 反斜杠：解线性方程组 Ax = b
@assert A * x ≈ [3.0, 4.0]
@assert det(A) ≈ 5.0 && tr(A) ≈ 5.0
@assert A' == [2.0 1.0; 1.0 3.0]       # ' 共轭转置（实数即转置）
vals = eigen([2.0 0.0; 0.0 5.0]).values
@assert vals ≈ [2.0, 5.0]
@assert norm([3.0, 4.0]) == 5.0
@assert dot([1, 2], [3, 4]) == 11
# 注意：A*B 是矩阵乘，A .* B 才是对应元素乘（10 章）——新手的头号混淆点

println("m = ", m, "；sum_cols = ", sum_cols(m), "；eigen values = ", vals)
println("==== 09 结束 ====")
