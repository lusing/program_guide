# 23 · Fiddle C 互操作

> 对应示例：`examples/23_ffi/`

标准库 `fiddle` 让 Ruby 直接调 C 函数：不写扩展、不编译、不装 gem。这章的主线是「签名表」——`Fiddle::Function.new(函数指针, 参数类型表, 返回类型)` 三个参数构成 Ruby 与 C 之间的唯一契约，签对了畅通无阻，签错了段错误。所以本章一半篇幅在讲正确用法，另一半在讲**边界纪律**：FFI 没有护栏，查原型、数参数、对类型这三件事没人替你做。

## 23.1 最小调用：sqrt

第一步是拿库句柄。坑位先说：**别硬编码系统库路径**（各平台差异巨大），`Fiddle.dlopen(nil)` 拿「当前进程」的句柄——macOS 的 libSystem（含 libc/libm 常用函数）早已随进程加载，`sqrt`/`pow`/`strlen`/`qsort` 全能解析：

```ruby
require "fiddle"
LIBC = Fiddle.dlopen(nil)
sqrt = Fiddle::Function.new(LIBC["sqrt"],
  [Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
sqrt.call(2.0)   # => 1.4142135623730951
```

实测输出：

```text
---- 23.1 最小调用：sqrt ----
sqrt(2.0) = 1.4142135623730951（确定性小数，Fiddle::TYPE_DOUBLE 签名）
```

签名必须与 C 原型一字不差：`double sqrt(double)` → 一个 `TYPE_DOUBLE` 进、一个 `TYPE_DOUBLE` 出。`LIBC["sqrt"]` 按符号名查函数指针，查不到返回 nil，调用时才炸——绑定阶段就先确认非 nil。

- 示例顶部 `require "fiddle/import"` 是给 23.5 的 `Fiddle::Importer` 准备的，最小调用只要 `require "fiddle"`。
- `dlopen(nil)` 与 23.5 的 `dlload nil` 是同一件事的两种写法：Importer 层用 `dlload`，裸 Fiddle 层用 `dlopen`。

## 23.2 类型映射：INT / DOUBLE / VOIDP

最常用的三个类型标签：`TYPE_INT`（C int）、`TYPE_DOUBLE`（C double）、`TYPE_VOIDP`（任意指针）。Ruby 值按签名表自动转换：

```ruby
c_abs = Fiddle::Function.new(LIBC["abs"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
c_pow = Fiddle::Function.new(LIBC["pow"],
  [Fiddle::TYPE_DOUBLE, Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
c_abs.call(-42)      # => 42
c_pow.call(2, 10)    # => 1024.0（整数字面量自动转 double，可表示范围内安全）
```

实测输出：

```text
---- 23.2 类型映射：INT / DOUBLE / VOIDP ----
abs(-42) = 42；pow(2,10) = 1024.0 —— Ruby 值按签名表自动转换
```

「自动转换」是便利也是陷阱：Ruby 的 Integer 精度无限，C 的 double/int 都有限。小数字面量转来转去没事；超出范围的值按 C 规则截断/溢出，Ruby 不报错——大数过 FFI 前自己先验范围。

三个类型标签的适用面先背下来，够覆盖大半 libc 绑定：

| 标签 | C 类型 | Ruby 侧进出 |
|---|---|---|
| `TYPE_INT` | `int` | Integer（超范围按 C 截断） |
| `TYPE_DOUBLE` | `double` | Float / Integer（自动转） |
| `TYPE_VOIDP` | 任意指针 | String / Pointer / 整数地址 |

其余常用标签还有 `TYPE_VOID`（只做返回类型，表示无返回值）、`TYPE_SIZE_T`（`size_t`，23.4 的 strlen 用它）、`TYPE_CHAR`、`TYPE_LONG` 等。拿不准某个 C 原型对应哪个标签时，回 `man 函数名` 看原型，一个类型一个标签地对。

## 23.3 malloc/free 与 Pointer

C 的内存块在 Ruby 侧的化身是 `Fiddle::Pointer`。**优先用 `Fiddle::Pointer.malloc`** 而不是裸调 libc 的 malloc——Ruby 侧分配并托管，GC 时自动 free，不用手写 free：

```ruby
buf = Fiddle::Pointer.malloc(16)
buf.size            # => 16
buf[0, 5] = "hello" # 按字节写入 C 内存
buf[0, 5]           # => "hello"
addr = buf.to_i     # 地址本身是个整数，可传给需要指针的 C 函数
```

实测输出：

```text
---- 23.3 malloc/free 与 Pointer ----
分配 16 字节、写入读回 hello/HELLO；地址只做断言（addr > 0 = true），不打印裸地址
```

`buf[起点, 长度]` 的切片语义读写 C 内存；裸地址（`to_i` 的整数）只该作为参数传给 C 函数，**别打印**——每次运行都不同，且把地址当数据展示是调试噪音。教程纪律：地址只做断言（`addr > 0`）。

「GC 托管」值得展开一句：`Pointer.malloc` 的内存挂着 Ruby 对象的生死——对象被 GC 回收时内存随之 free。平时这是省心，但**把地址传给 C 侧长期持有**的场景要小心：C 侧存的裸地址不会让 Ruby 对象保持存活，Ruby 对象一回收，C 侧手里的就是悬空指针。对策是把 Pointer 对象存在 Ruby 侧变量里，保证它活得比 C 侧的使用期长。

## 23.4 字符串传递

`TYPE_VOIDP` 参数可以直接吃 Ruby String——自动转成 C 字符串指针。用 `strlen` 感受两个世界对「字符串」的不同定义：

```ruby
c_strlen = Fiddle::Function.new(LIBC["strlen"],
  [Fiddle::TYPE_VOIDP], Fiddle::TYPE_SIZE_T)
c_strlen.call("hello")   # => 5
c_strlen.call("你好")    # => 6（UTF-8 下 = 2 字符 × 3 字节）
c_strlen.call("你好") == "你好".bytesize   # => true
```

实测输出：

```text
---- 23.4 字符串传递 ----
strlen("你好") = 6 == bytesize（length 是 2）—— C 世界没有字符，只有字节
```

反向走（C 内存 → Ruby 字符串）有个编码坑：**`Pointer#to_s` 读回的是 `ASCII-8BIT`（BINARY）编码**——C 世界只有字节，没有「编码」概念：

```ruby
sp = Fiddle::Pointer["指针也能包字符串"]     # 包装已有字符串
sp.to_s.bytesize == "指针也能包字符串".bytesize   # => true
sp.to_s.force_encoding(Encoding::UTF_8) == "指针也能包字符串"   # => true
```

从 C 内存读回的 String 一律 `force_encoding(Encoding::UTF_8)`（前提是你知道它确实是 UTF-8 字节），否则打印、正则、比较全会在编码不匹配上翻车。

## 23.5 结构体：Importer#struct

`Fiddle::Importer` 把一组 C 声明挂到一个模块上。示例的写法里有个 `const_set` 的讲究：

```ruby
Geom = Module.new do
  extend Fiddle::Importer
  dlload nil                                  # 同样用当前进程，不写死路径
  const_set(:Point, struct("point { double x; double y; }"))
end
p1 = Geom::Point.malloc      # malloc 出实例（GC 托管）
p1.x = 3.5; p1.y = -2.0
Geom::Point.size             # => 16（2 × double）
```

实测输出：

```text
---- 23.5 结构体：Importer#struct ----
自定义 struct point{x,y}：p1 = (3.5, -2.0)，sizeof = 16 字节
```

为什么用 `const_set` 而不是直接写 `Point = struct(...)`：**在 `Module.new do ... end` 块里写 `Point = ...` 会撞外层作用域的常量名**，Ruby 视作「重复初始化常量」往 stderr 打 warning——而本教程 stderr 必须为空。块内的常量赋值绑定的是词法外层作用域，`const_set` 把定义稳稳挂在这个模块命名空间下，一石二鸟。`dlload nil` 与 23.1 的 `dlopen(nil)` 是同一招：当前进程句柄。

## 23.6 回调：Closure 包 qsort

C 函数指针要求「可调用的 C 地址」——Ruby 块不是，要包成 `Fiddle::Closure`（生成 C 兼容回调）。经典场景：给 libc 的 `qsort` 传比较函数：

```ruby
Compare = Class.new(Fiddle::Closure) do
  def call(a, b)    # a、b 是指向两个 int 的指针
    Fiddle::Pointer.new(a)[0, 4].unpack1("l<") <=>
      Fiddle::Pointer.new(b)[0, 4].unpack1("l<")
  end
end
cmp = Compare.new(Fiddle::TYPE_INT, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP])
c_qsort = Fiddle::Function.new(LIBC["qsort"],
  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_VOIDP],
  Fiddle::TYPE_VOID)
```

数据侧：Ruby 数组 `pack("l<*")` 成二进制，灌进 malloc 出来的内存，C 侧原地排序，再 `to_s(长度).unpack("l<*")` 读回：

```text
---- 23.6 回调：Closure 包 qsort ----
qsort 原地排 Ruby 传入的 int 数组，结果 = [1, 2, 3, 4, 5]（回调在 Ruby 里比较）
BlockCaller 版回调：double_cb(21) = 42
```

注意回调内 `call(a, b)` 收到的不是整数，是**指向 int 的指针地址**——要 `Pointer.new(a)[0, 4].unpack1("l<")` 手工解引用。简单回调有糖：`Fiddle::Closure::BlockCaller.new(返回类型, 参数表) { |x| ... }` 块一包了事，语义同 Closure。

回调的生命周期也归 GC 管：`cmp` 这个 Closure 对象必须活在 C 侧调用它的时间窗内——示例里 `c_qsort.call` 同步执行完才返回，`cmp` 是局部变量天然够用；若把回调交给 C 侧异步持有（注册后长期调用），就要在 Ruby 侧留住引用，否则 GC 一回收，C 侧调用的是野指针。`Compare.new(返回类型, 参数类型表)` 的签名与 `Fiddle::Function` 同构——「查原型、数参数、对类型」的纪律在这里同样适用。

## 23.7 FFI 的边界纪律

本节没有危险演示（段错误没法 rescue，进程直接拖死），纪律全在注释里，抄录如下：

- **FFI 没有护栏**：把 double 签名传成 int、少传一个参数、给 strlen 传空指针——编译器不会救你，运行时直接 SIGSEGV，Ruby 异常救援不了段错误。
- **绑定前三查**：查 C 原型（`man sqrt`）、数清参数个数与类型、确认返回类型。签名表就是唯一契约。
- **指针安全**：`Pointer.malloc` 的内存由 GC 托管；裸 `to_i` 地址要在使用期间保证原对象存活——对象被 GC 了，地址就成了悬空指针。

实测输出（全程只用签名正确的调用，所以进程平安）：

```text
---- 23.7 FFI 的边界纪律 ----
本节所有调用签名正确 —— 进程无段错误、输出确定；签名纪律：查原型、数参数、对类型
```

调试段错误的实用姿势：先怀疑最近改的签名；把参数类型逐个换成 `TYPE_VOIDP` + `Pointer` 显式传，缩小是哪个参数的类型错位。

## 23.8 坑位清单

1. **别硬编码系统库路径**：`Fiddle.dlopen(nil)`（或 `dlload nil`）拿当前进程句柄，macOS 的 libSystem 函数全能解析（23.1、23.5）。
2. **签名必须与 C 原型一字不差**：签名表是唯一契约，错一个类型就是运行时段错误，Ruby 异常救不了（23.1、23.7）。
3. **`Pointer#to_s` 是 BINARY 编码**：从 C 内存读回的 String 要 `force_encoding(Encoding::UTF_8)` 才能正常比较/打印（23.4）。
4. **`strlen` 算的是字节不是字符**：中文 `"你好"` 是 6 不是 2——C 世界没有字符，只有字节（23.4）。
5. **`Module.new` 块里写 `Point = struct(...)` 撞外层常量名**：往 stderr 打 already initialized 告警，用 `const_set` 挂进命名空间（23.5）。
6. **裸调 libc `malloc` 要自己 free**：一律 `Fiddle::Pointer.malloc`，GC 托管免手洗（23.3）。
7. **裸地址（`to_i`）不打印、不当数据用**：每次运行都不同；且要保证原对象在使用期间存活，否则悬空指针（23.3、23.7）。
8. **Closure 的 `call(a, b)` 收到的是指针不是整数**：要 `Pointer.new(a)[0, 4].unpack1("l<")` 手工解引用（23.6）。
9. **Ruby 大整数过 FFI 按 C 规则截断/溢出，不报错**：超出 int/double 范围的值自己先验（23.2）。
10. **`LIBC["名字"]` 查不到符号返回 nil**：绑定阶段就确认非 nil，别拖到 call 才炸（23.1）。
11. **段错误无法 rescue**：FFI 调试别在关键进程里试错，先在一次性脚本里把签名验对（23.7）。
12. **`pack("l<*")` 的端序要和 C 平台对齐**：跨平台传二进制结构时，`l<`（little-endian）写死了就要知道自己在赌什么（23.6）。

---

[上一章](22-fibers.md) | [下一章](24-capstone.md)
