# 05 函数：定义形式、参数族（位置/关键字/可选/变长）、匿名函数、do 块、函数是值
# 运行：julia --startup-file=no main.jl

# ═══ 05.1 三种定义形式：完整式、赋值式、匿名式
function add(a, b)             # 完整式：多行函数体
    a + b                      # 末尾表达式即返回值（也可显式 return）
end
square(x) = x^2                # 赋值式：单行惯用法
cube = x -> x^3                # 匿名函数绑到变量（更常见的是就地传入）

@assert add(1, 2) == 3 && square(5) == 25 && cube(2) == 8

# ═══ 05.2 返回值：末表达式、return、多返回值其实是元组
function minmax(a, b)
    a < b ? (a, b) : (b, a)    # 返回元组
end
lo, hi = minmax(3, 1)          # 解构赋值
@assert (lo, hi) == (1, 3)

# 返回类型注解：收窄为 Int（convert 兜底，转不动抛 InexactError）
toint(x)::Int = round(Int, x)
@assert toint(3.6) == 4

# ═══ 05.3 位置默认值与关键字参数（分号之后是关键字，调用时名字可省——默认按位置？不：必须带名）
function charge(amount; tax = 0.13, discount = 0.0)
    amount * (1 - discount) * (1 + tax)
end
@assert charge(100) ≈ 113.0
@assert charge(100; tax = 0, discount = 0.5) ≈ 50.0
@assert charge(100, discount = 0.5) ≈ 56.5     # 关键字参数顺序随意

function powsum(base, exponent = 2)             # 位置参数可以有默认值（按位置省略）
    base + exponent
end
@assert powsum(10) == 12 && powsum(10, 5) == 15

# ═══ 05.4 变长参数：定义端收集（slurp）、调用端展开（splat）
function varsum(args...)
    sum(args; init = 0)         # 空集合 reduce 必须给 init——sum(()) 直接抛 ArgumentError
end
@assert varsum(1, 2, 3) == 6
nums = [1, 2, 3, 4]
@assert varsum(nums...) == 10                   # ... 在调用端把数组"摊开"

# 命名元组展开成关键字参数
opts = (tax = 0.2, discount = 0.1)
@assert charge(100; opts...) ≈ 108.0

# ═══ 05.5 匿名函数与高阶函数
squares = map(x -> x^2, 1:5)
@assert squares == [1, 4, 9, 16, 25]
bigones = filter(x -> x > 10, squares)
@assert bigones == [16, 25]
@assert reduce(+, 1:5) == 15
@assert reduce((a, b) -> a * b, 1:5) == 120      # 二元 op 用匿名函数

# ═══ 05.6 操作符也是函数：+、*、∈ 都可以当值传
@assert +(1, 2) == 3                            # 前缀调用操作符
ops = [+, -, *, ÷]
@assert [op(6, 3) for op in ops] == [9, 3, 18, 2]
@assert map(sqrt, [4.0, 9.0]) == [2.0, 3.0]

# ═══ 05.7 管道 |> 与复合 ∘
@assert (1:10 |> sum |> sqrt |> round) == 7.0   # 从左到右流动：sum=55 → sqrt≈7.42 → round=7
normalize(v) = v ./ maximum(v)
@assert normalize([2, 4]) == [0.5, 1.0]
f = exp ∘ log                                  # (f ∘ g)(x) = f(g(x))；∘ 输入 \circ
@assert f(7.0) ≈ 7.0                           # 浮点往返用 ≈，别用 ==

# ═══ 05.8 do 块：把"最后一个函数参数"写成块（语法糖）
total = sum(1:10) do x                          # 等价 sum(x -> x, 1:10)
    x
end
@assert total == 55
opened = open(tempname(), "w") do io            # do 块自动 close——资源管理惯用法
    println(io, "自动关闭")
    true
end
@assert opened == true

# 注意：sort 不接受 do 块（无 sort(f, v) 方法）——自定义排序用 by=/lt= 关键字
sorted = sort(["banana", "apple", "cherry"]; by = length)
@assert sorted == ["apple", "banana", "cherry"]

println("minmax(3,1) = ", minmax(3, 1), "；charge(100) ≈ ", round(charge(100); digits = 1))
println("ops 结果 = ", [op(6, 3) for op in ops], "；sorted = ", sorted)
println("==== 05 结束 ====")
