# 05 · 函数

> 对应示例：`examples/05_functions/`

## 5.1 三种定义形式

```julia
function add(a, b)      # 完整式：多行
    a + b               # 末表达式即返回值（显式 return 可选）
end
square(x) = x^2         # 赋值式：单行惯用法
cube = x -> x^3         # 匿名函数绑名（通常就地传入，见 5.5）
```

惯例：**改参数的函数名尾加 `!`**（`push!`、`sort!`）——不是语法强制，是生态铁律。

## 5.2 返回值：元组即多返回值

```julia
function minmax(a, b)
    a < b ? (a, b) : (b, a)   # 返回元组
end
lo, hi = minmax(3, 1)         # 解构赋值 → (1, 3)
```

"多返回值"就是元组，没有 C++ 的 out 参数、没有 Go 的多值返回关键字。返回类型注解收窄类型（convert 兜底）：

```julia
toint(x)::Int = round(Int, x)   # 返回前自动 convert(Int, ·)，转不动抛 InexactError
```

## 5.3 参数族：位置默认、关键字、变长

```julia
# 分号之后是关键字参数：调用时必须带名（顺序随意）
charge(amount; tax = 0.13, discount = 0.0) = amount * (1 - discount) * (1 + tax)
charge(100)                        # 113.0
charge(100; tax = 0, discount = 0.5)   # 50.0
charge(100, discount = 0.5)        # 56.5——关键字顺序无关

# 位置参数也能有默认值：按位置省略
powsum(base, exponent = 2) = base + exponent
powsum(10) == 12 && powsum(10, 5) == 15
```

变长参数两端摊开：

```julia
varsum(args...) = sum(args; init = 0)   # 定义端收集（slurp）
varsum(1, 2, 3)             # 6
nums = [1, 2, 3, 4]
varsum(nums...)             # 10——调用端展开（splat）
opts = (tax = 0.2, discount = 0.1)
charge(100; opts...)        # 108.0——命名元组摊成关键字
```

`init = 0` 不是装饰：**空集合 reduce 不给 init 会抛 ArgumentError**（`sum(())` 实测如此）。

## 5.4 匿名函数与高阶函数

```julia
map(x -> x^2, 1:5)              # [1, 4, 9, 16, 25]
filter(x -> x > 10, squares)    # [16, 25]
reduce(+, 1:5)                  # 15
reduce((a, b) -> a * b, 1:5)    # 120——二元 op 用匿名函数
```

## 5.5 操作符也是函数

```julia
+(1, 2) == 3                    # 前缀调用
ops = [+, -, *, ÷]
[op(6, 3) for op in ops]        # [9, 3, 18, 2]——操作符装进数组当值传
map(sqrt, [4.0, 9.0])           # [2.0, 3.0]
```

`+`、`*`、`∈` 全是普通函数名（可重载、可传递）——这是多重派发统一的根基（06 章给自己的类型定义 `+`）。

## 5.6 管道 |> 与复合 ∘

```julia
1:10 |> sum |> sqrt |> round     # 7.0——从左到右流动
normalize(v) = v ./ maximum(v)
f = exp ∘ log                    # (f ∘ g)(x) = f(g(x))；∘ 输入 \circ
f(7.0) ≈ 7.0                     # 浮点往返用 ≈ 不用 ==
```

## 5.7 do 块：把"最后一个函数参数"写成块

```julia
total = sum(1:10) do x       # 等价 sum(x -> x, 1:10)
    x
end
opened = open(path, "w") do io    # do 块退出自动 close——资源管理惯用法
    println(io, "自动关闭")
    true                          # do 块的值 = open 调用的返回值
end
```

**do 块把函数插到第一个参数位**——所以 `f(x) do ... end` 展开为 `f(匿名函数, x)`。实测坑：`sort` 没有 `sort(f, v)` 方法，**do 块配 sort 编译不过**——自定义排序用 `by=`/`lt=` 关键字（11 章速查）。

## 5.8 坑位清单

1. **`sort` 不吃 do 块**：`sort(v) do a,b ... end` 报 MethodError——用 `by=`/`lt=`（5.7、11 章）。
2. **空集合 `sum`/`reduce` 抛 ArgumentError**：变长参数、可能为空的折叠都要 `init`（5.3）。
3. **关键字参数必须带名调用**：`charge(100, 0.2)` 试图按位置传 `tax` → MethodError——分号之后不可按位置（5.3）。
4. **`->` 才是函数，`=>` 是 Pair**：`() => 1` 构造的是 Pair 不是匿名函数（13 章实测过）。
5. **`@assert` 不认 `≈ atol=`**：`@test x ≈ y atol=1e-12` 合法，但 `@assert` 里同写法解析成别的——断言近似用 `isapprox(x, y; atol=...)`（17 章实测）。
