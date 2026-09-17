# 16 · 性能 ⭐

> 对应示例：`examples/16_performance/`
>
> Julia 的性能不靠祈祷，靠四条纪律：**函数化、类型稳定、避开全局、控分配**。

## 16.1 @time 三段论：先预热再下结论

```julia
@time work(100_000)     # 第一次：编译 + 运行（大头是编译）
@time work(100_000)     # 第二次：纯运行——比较用这个
```

任何计时结论都要**预热后**取第二次（20 章的并发演示同理，`@elapsed` 前先空跑一遍）。

## 16.2 类型稳定性：本Tutorial最重要的一节

函数**返回类型只由实参类型决定**（与值无关）→ 编译器生成无分支机器码：

```julia
stable(x::Float64)   = x > 0 ? x : 0.0      # 两分支同类型 → Float64 ✅
unstable(x::Float64) = x > 0 ? x : 0        # Float64 | Int → Union{Float64, Int64} ❌
```

机器可查（脚本模式先 `using InteractiveUtils`——实测坑，REPL 才自动加载）：

```julia
Base.return_types(stable, (Float64,))     # [Float64]
Base.return_types(unstable, (Float64,))   # [Union{Float64, Int64}]
@code_warntype unstable(1.0)              # REPL 里黄色高亮警告类型
```

修法廉价：统一分支类型（`x > 0 ? x : 0.0`）、或显式 `convert`/返回注解。**小 Union（≤3 候选）编译器能拆分支优化**，但 `Union{..., AbstractString}` 这种"八竿子打不着"的必然装箱变慢。

## 16.3 全局变量：性能第一杀手（实测 130×）

```julia
global G = 100
sum_global(n) = (s = 0.0; for i in 1:n; s += i + G; end; s)   # 每次访问 G 都动态查类型

const CONST_G = 100
sum_const(n) = (s = 0.0; for i in 1:n; s += i + CONST_G; end; s)
```

本机实测（1.13，10 万次循环）：

```text
sum_global: 0.0057 s（299k 次分配，4.5 MiB）
sum_const : 0.000043 s（零分配）        ← 130 倍
```

三条出路：全局加 `const`、当参数传进函数、或塞进 `let`/struct。**顺带：全局非 const 还是 soft scope 坑的源头（04 章）——函数化一石二鸟。**

## 16.4 计时与配额：@elapsed / @allocated

```julia
t = @elapsed work(1_000_000)         # 返回秒数（浮点）
bytes = @allocated work(...)         # 返回分配字节数
```

确定性配额断言示例（generator vs comprehension，实测）：

```julia
alloc_bad()  = sum([i^2 for i in 1:1000])   # 中间数组
alloc_good() = sum(i^2 for i in 1:1000)     # generator：零中间数组
alloc_bad(); alloc_good()                   # 预热（把编译分配排除）
@allocated alloc_bad()    # 8,087 B > 0
@allocated alloc_good()   # 0 B ✅ 可安全断言
```

两个纪律：**@allocated 测量前先预热**；**参数在测量外构造**（`@allocated f(rand(100))` 会把 rand 的分配算进去——23 章实测）。

精确基准用 BenchmarkTools 的 `@btime`（第三方，17 章装）；`@elapsed` 粗测够用。

## 16.5 @inbounds 与 @simd：先写对，再加速

```julia
function sum_inbounds(xs)
    s = 0.0
    @inbounds @simd for i in eachindex(xs)   # 关越界检查 + 允许 SIMD 向量化
        s += xs[i]
    end
    s
end
```

`@inbounds` 关闭边界检查（你自己保证不越界）、`@simd` 允许编译器重排浮点归约（改变舍入次序！）。**结果正确性必须另行验证**（本教程 build.ps1 带 `--check-bounds=yes` 强制恢复检查——就算写了 @inbounds 也有安全网验证一遍）。

## 16.6 视图 vs 拷贝

```julia
colsums_copy(m)  = ... sum(m[:, j]) ...      # 每列切片拷贝
colsums_view(m)  = ... @views sum(m[:, j])   # 零拷贝视图
```

实测两者结果一致（`isapprox` 验证）；大数组热循环一律 `@views`（09 章）。

## 16.7 容器元素类型：Any 是性能黑洞

```julia
v_any  = Any[1, 2.5, 3]       # 每次访问动态派发 + 装箱
v_real = Real[1, 2.5, 3]      # 抽象元素：同样装箱
v_f    = [1.0, 2.5, 3.0]      # 具体：编译器全速
isconcretetype(eltype(v_f))   # true——这是想要的
```

异构数据的正解：分开的具体类型数组、struct + 小 Union、或表格化（DataFrame 式列存思想）。

## 16.8 性能工作流清单

1. 写对（测试过）→ 2. `@time` 预热后看分配 → 3. 分配多：找 `Union`/`Any`/临时数组（`--track-allocation=user` 逐行定位，23 章）→ 4. 稳妥后 `@inbounds`/`@simd` → 5. 还要快：BenchmarkTools 精测 + Profile 看热点。

## 16.9 坑位清单

1. **`@code_warntype` 脚本里不可用**：`using InteractiveUtils` 先行（REPL 自动加载、脚本不自动——1.13 实测，错误提示只给个 Hint）（16.2）。
2. **非 const 全局在热循环**：实测 130× 慢 + 每圈分配——const/传参/函数化（16.3）。
3. **`@allocated` 首测含编译分配**：预热后再测，否则数字没意义（16.4 实测）。
4. **`@simd` 改浮点舍入**：归约结果可能与朴素版差最后几位——断言用 `isapprox` 不用 `==`（16.5）。
5. **抽象元素类型容器 = 装箱**：`Real[...]` 和 `Any[...]` 一样慢——容器要具体类型（16.7）。
6. **类型不稳定 ≠ 慢到不可用**：小 Union 有优化；先测再改，别为纯审美重写代码。
