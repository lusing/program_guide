# 18 · 测试

> 对应示例：`examples/18_testing/`

## 18.1 @test 与 @testset：骨架

```julia
using Test

@testset "分词器" begin               # 命名块：汇总表、隔离失败
    @test tokenize("Hello World") == ["hello", "world"]
    @test wordcount("") == 0
end
```

`@testset` 可任意嵌套（子集独立汇总）；**顶层 @testset 有失败 → 脚本 exit 1**（本教程两个入口的测试层就靠它）；测试失败信息带表达式、求值值与源码行。

## 18.2 断言族速查

```julia
@test x == y                    # 布尔
@test sqrt(2)^2 ≈ 2             # 近似（\approx）；≈ y atol=1e-12 rtol=...
@test 0.1 + 0.2 != 0.3          # 也可以断"不"
@test 0.1 + 0.2 ≉ 0.3 atol = 0 rtol = 0   # 零容差才"不近似"（默认 rtol 下它≈！）
@test_throws DomainError sqrt(-1)          # 必须抛指定类型
@test_throws "n 必须为正" must_positive(-1)  # 按消息子串匹配（1.7+）
@test_throws MethodError "a" + 1
@test_broken tokenize("A") == ["A"]        # 已知问题：断言当前为假
@test_skip 计划中的测试()                   # 跳过（灰色记录）
@test_nowarn tokenize("clean")             # 无警告
@test_logs (:warn, "丢弃一行") warn_once() # 匹配日志
@test x === nothing                          # 身份/类型严格断言
```

`≈` 的默认 rtol=√eps——`0.1 + 0.2 ≈ 0.3` **为 true**（与 `==` 相反）；要精确否定给 `atol = 0 rtol = 0`（实测坑，别想当然）。

## 18.3 随机数据测试：固定 seed

```julia
using Random, Statistics
Random.seed!(20260918)
xs = randn(1000)
@test abs(mean(xs)) < 0.1        # 性质测试：大数定律
@test std(xs) ≈ 1 rtol = 0.1
```

同 seed 同序列（可复现）；1.13 在测试失败时还打印 **"RNG of the outermost testset"** ——失败时能精确重放随机状态。

## 18.4 测试组织：runtests.jl 惯例

- 目录级：`runtests.jl`（本教程每示例一个，`include("main.jl")` 后套 @testset）；
- 包级：`test/runtests.jl`，`Pkg.test()` 自动跑（17 章 MathTools 有完整示例）；测试依赖声明在包 Project.toml 的 `[extras]` + `[targets]`。

结构建议：**一个顶层 @testset 命名 = 被测模块**，嵌套子集 = 功能面；断言消息留给"为什么"（`@test f(x) == y "边界：空输入"`）。

## 18.5 性质与表驱动

```julia
@testset "movavg 性质" begin
    for v in ([1.0, 2.0, 3.0], rand(17), fill(π, 5))
        @test average(v) ≈ mean(v)            # 与 Statistics 交叉验证
    end
    @test movavg(v, 1) == v                   # 窗口 1 = 恒等
    @test length(movavg(rand(100), 10)) == 91 # 长度守恒
end
```

比逐例断言强：**不变式 + 交叉验证 + 随机输入**三件套（17 章 MathTools 的 runtests 即此风格）。

## 18.6 覆盖率与 CI 一瞥

- 行覆盖：`julia --code-coverage=user runtests.jl`（22 章）→ `.cov` 文件与源码同行；
- CI：GitHub Actions 装 `julia-actions/julia-runtest`；文档 doctest 用 Documenter.jl。

## 18.7 坑位清单

1. **`≈` 默认就通过 0.1+0.2 vs 0.3**：想断"精确不等"用 `!=`；断"不近似"要 `atol=0 rtol=0`（18.2 实测）。
2. **`@test_broken` 反向断言**：表达式**为真**时它报错（"test passed unexpectedly"）——删除已修复项，别让 broken 变绿（18.2）。
3. **嵌套 @testset 失败不立即抛**：子集失败记入父集、末尾统一抛 TestSetException——想当场断言失败形态需读 Test API（本教程 runtests 实测过嵌套语义）。
4. **函数先定义后测试**：顶层逐句执行，测试块里用到还没定义的函数是 UndefVarError（04 章坑位在测试文件的化身——18 章示例实测踩过两次）。
5. **`@test_logs` 匹配日志要精确**：级别与消息（可子串）都要给——`@test_logs (:warn, "丢弃一行") f()` 期望恰好一条。
