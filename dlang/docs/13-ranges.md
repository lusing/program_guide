# 13 · 区间（Range）

> 对应示例：`examples/13_ranges/`

## 13.1 D 代替迭代器的统一抽象

一个类型只要有三个成员，它就是**输入区间**（鸭子类型，不用继承任何东西）：

```d
struct Countdown {
    long current;
    bool empty() const { return current <= 0; }   // 还有元素吗
    long front() const { return current; }        // 当前元素（只看不弹）
    void popFront() { current--; }                // 弹掉当前
}

foreach (n; Countdown(3)) write(n, "… ");         // 3… 2… 1… —— foreach 直接吃
Countdown(5).equal([5, 4, 3, 2, 1]);              // 所有算法直接吃
```

更强的区间加更多成员：

| 区间种类 | 额外要求 | 解锁 |
|---|---|---|
| InputRange | `empty / front / popFront` | foreach、equal、find |
| ForwardRange | `.save`（可复制游标） | 多遍算法 |
| BidirectionalRange | `back / popBack` | retro |
| RandomAccessRange | `opIndex` + 长度/无限 | 索引、切分 |
| OutputRange | `put(value)` | 拷贝输出目标 |

`isInputRange!T` 等模板在编译期验证——**注意写括号**：`isForwardRange!(int[])`（`!int[]` 会被解析成"bool 数组"，编译错）。

## 13.2 标准区间工厂

```d
iota(1, 6)                       // [1, 2, 3, 4, 5]
iota(0, 10, 3)                   // [0, 3, 6, 9]（步长）
chain([1, 2], [3, 4])            // 串联两段
cycle([1, 2]).take(5)            // [1, 2, 1, 2, 1]：无限循环
recurrence!("a[n-1] + a[n-2]")(1, 1)   // 无限斐波那契！
```

**无限区间**：`empty` 是编译期 `false`。配合 `take`/`until` 之类的"限定器"才能安全消费——惰性算法（14 章）对无限流只算需要的部分。

## 13.3 视图适配器：不拷贝数据

```d
auto data = [1, 2, 3, 4, 5, 6];
data.take(3)         // 前 3 个（视图）
data.drop(2)         // 跳过前 2 个
data.retro           // 反向
data.stride(2)       // 每隔一个
zip(iota(1, 4), ["一", "二", "三"])     // 并行打包，短的截断
```

## 13.4 自定义更强的区间

```d
struct Palindrome(R) {              // 双向区间：包装另一个区间
    R source;
    bool empty() { return source.empty; }
    auto front() { return source.front; }
    auto back()  { return source.back; }
    void popFront() { source.popFront(); }
    void popBack()  { source.popBack(); }
}

equal(Palindrome!(int[])([1, 2, 3, 2, 1]), [1, 2, 3, 2, 1].retro);   // 回文判断
```

## 13.5 字符串的区间身份

```d
static assert( isInputRange!string);            // 是输入区间（元素=char 码元）
static assert(!isRandomAccessRange!string);     // 但不是随机访问——UTF-8 变长编码！
```

`"héllo"[2]` 拿的是字节不是字符——语言层面拒绝把它当 RA 区间是对的。按码点处理：`.byDchar`。

## 13.6 和 Go/Zig/C++ 的对照

| | 抽象 | 评价 |
|---|---|---|
| Go | for-range + channel | 只有语法，没有可组合协议 |
| C++20 | ranges（迭代器对封装） | 强但复杂（sentinel/projection 概念多） |
| Zig | anytype 鸭子（无正式协议） | 每个容器自己发明 empty/next |
| **D** | **5 级 range 协议 + 惰性算法** | 2010 年就落地，std.algorithm 全员兼容 |

## 13.7 坑位清单

1. **`iota(0)` 是空区间**：单参数是"stop"（[0, 0)），不是"从 0 开始的无限流"！无限自然数用 `sequence!"n"(0)`（`static assert(isInfinite!(typeof(sequence!"n"(0))))`）。本章实测：拿 `iota(1)` 配 zip"看着能跑"——实际 zip 被截成 1 个元素，静默错误。
2. **模板实参数组要括号**：`isForwardRange!int[]` 解析成 `(isForwardRange!int)[]`（bool 数组声明）——必须 `!(int[])`。
3. **区间是单遍消耗品**（输入区间级别）：`auto r = 5.iota; r.array; r.array;` 第二次拿到空——要多次遍历先 `.array` 或要求 forward（`.save`）。
4. `foreach` 对数组给索引，对普通区间**没有免费索引**——要 `(i, x)` 就 `zip(iota, xs)` 或 `.enumerate`。
5. 自定义区间的 `empty/front/popFront` 名字必须精确（front 不是 head/popFront 不是 next）——协议靠约定，拼错编译器不会提示"你想实现 range"。

---
