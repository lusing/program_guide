# 29 · 数学计算：math / cmplx / rand/v2 / big

> 对应示例：`examples/29_math/`。float64 精度、随机数、大数——三块常被低估的地基。

## 29.1 math：常量与常用函数

```go
math.Pi / math.E
math.MaxFloat64 / SmallestNonzeroFloat64 / MaxInt64（Int 也有系列常量）

math.Sqrt(2) / Cbrt(27) / Pow(2, 10) / Hypot(3, 4)   // 5，直角边斜边
math.Log(x) / Log2(x) / Log10(x) / Log1p(x) / Exp(x)
math.Trunc(3.9) / Floor(3.9) / Ceil(3.1)             // 3 / 3 / 4
math.Round(2.5)          // 3：四舍五入（远离零）
math.RoundToEven(2.5)    // 2：银行家舍入（.5 取偶，统计里防偏差）
math.Mod(-7.0, 3)        // -1：浮点取模，结果跟被除数同号（同 C 的 fmod）
-7 % 3                   // -1：整数 % 同样跟被除数同号
// Go 的两种取模都跟被除数同号——想要 Python/JS 那种"非负模"自己包一层：
m := ((a % b) + b) % b   // 负数也落回 [0,b)
math.Abs / Signbit / Copysign / Dim(x-y, 0) / Max(x,y) / Min(x,y)
```

整数溢出不报警：`math.MaxInt64 + 1` 静默回绕。要检测就用 `int64` 前置判界，或上 `math/big`。

## 29.2 NaN 与 Inf：浮点的两个异类

```go
math.NaN()                  // 0/0 之类"没有结果"的占位
math.Inf(1) / math.Inf(-1) // ±∞
math.IsNaN(x) / IsInf(x, 1)
```

**NaN 与任何值比较都是 false**——包括 `NaN == NaN`。切片里找 NaN 不能 `==`，得 `math.IsNaN`；排序时 NaN 会把 `slices.Sort` 的有序性破坏掉（Less 不再传递），**先洗掉 NaN 再排**。Inf 参与比较是正常的（`Inf > 1e308` 为 true）。

## 29.3 math/cmplx：复数

```go
var z complex128 = complex(3, 4)   // 3+4i
cmplx.Abs(z)                       // 5
cmplx.Phase(z)                     // atan2(4,3)：辐角
r, θ := cmplx.Polar(z)             // 极坐标拆开
w := cmplx.Exp(complex(0, math.Pi)) // e^{iπ} = -1 + 1.2e-16i（浮点误差现身）
cmplx.Sqrt(-4)                     // 2i——实数域报错的它都接
```

复数是内建类型（complex64/128），运算符直接用（`z*w`、`z+w`）；cmplx 包只提供超越函数。数字信号处理、FFT、电路计算才碰它——日常写业务基本用不到，认识门牌即可。

## 29.4 math/rand/v2：现代随机数（1.22+）

```go
rand.IntN(100)              // [0,100) 整数
rand.Float64()              // [0,1)
rand.N(10 * time.Second)    // 任意数值类型：Duration 也行
rand.Perm(5)                // [0 3 1 4 2]：0..4 的随机排列
rand.Shuffle(len(sl), func(i, j int) { sl[i], sl[j] = sl[j], sl[i] })

r := rand.New(rand.NewPCG(seed1, seed2))   // 可复现流：种子固定 → 序列固定
r.IntN(100)
r2 := rand.New(rand.NewChaCha8(seed))      // 密码学强度的流（crypto/rand 取种）
```

与老的 `math/rand` 的三大差别：**没有 `rand.Seed`**（全局源自动随机化，老代码 `Seed(time.Now())` 刻意复现的写法移到 `rand.New` 上）；**没有 `Read`**（要随机字节去 `crypto/rand`）；命名统一成 `IntN/Int32N/UintN`。**全局函数是并发安全的**，每个 `rand.New` 的实例自己用自己（跨 goroutine 共享一个 `*rand.Rand` 不是线程安全的）。

需要**可复现**（测试、回放、仿真）就 `NewPCG`；需要**不可预测**（token、密钥）上 `crypto/rand`——`math/rand` 是统计随机，不是安全随机。

## 29.5 math/big：任意精度

```go
var x big.Int
x.SetString("123456789012345678901234567890", 10)   // 十进制串进

// 风格：方法改的是接收者并返回它自己，链式写
var f big.Int
f.MulRange(1, 30)                                   // 30! —— int64 早爆了

a := new(big.Int).SetUint64(math.MaxUint64)
b := new(big.Int).SetUint64(2)
sum := new(big.Int).Add(a, b)                       // a+b，装进 sum
sum.Cmp(a)                                          // +1：sum > a

q := new(big.Rat).SetFrac(big.NewInt(1), big.NewInt(3)) // 精确的 1/3
f64, _ := q.Float64()                               // 0.333...（转 float 才丢精度）

f := new(big.Float).SetPrec(200)                    // 200 位二进制精度
f.SetString("3.141592653589793238462643383")        // 转回来仍是 (*Float, bool)
```

`big.Int` **零值可用**（new 出来直接算）；四则方法是 `Add(x, y)` 而不是 `x.Add(y)`——结果装接收者，操作数不动。**不要把同一个变量同时当接收者和操作数**以外的地方复用——表达式树复用有讲究，结果先落新变量再复用最稳。

## 29.6 速查

| 需求 | 用 |
|---|---|
| 四舍五入 / 银行家 | `math.Round` / `RoundToEven` |
| 负数取模 | Go 两种模都跟被除数同号；非负模 `((a%b)+b)%b` |
| 判 NaN | `math.IsNaN`（== 永远 false） |
| 模拟随机 | `math/rand/v2` 全局函数 |
| 可复现随机 | `rand.New(rand.NewPCG(...))` |
| 安全随机 | `crypto/rand`（不是 math/rand） |
| 超过 int64 | `math/big`（SetString 进、Cmp 比） |

## 29.7 坑位清单

1. **`x == math.NaN()`**：恒 false——用 `math.IsNaN`。
2. **NaN 混进 slices.Sort**：Less 不传递，有序性被破坏——排序前清除。
3. **`-7 % 3` 期待 2**：Python/JS 惯性——Go 的 `%` 和 `math.Mod` 都**跟被除数同号**得 -1；要非负模 `((a%b)+b)%b`。
4. **`Round(2.5)=3` 但 `Round(-2.5)=-3`**：远离零不是"进到正无穷"；财务舍入要 `RoundToEven`。
5. **rand.Seed / rand.Read**：rand/v2 里都没了——老代码迁移第一站。
6. **共享一个 `*rand.Rand` 跨 goroutine**：不安全——要么用全局函数，要么每 goroutine 一个。
7. **int64 溢出**：静默回绕——阶乘第 21 项就爆，`big.Int` 没有心理负担。
8. **`big.Int` 当 `int` 用**：它不实现这些运算符——全是方法调用，注意结果落接收者的约定。

---
