# 12 · 词汇类型五虎（加三个帮手）：C++17 大收割的 Boost 侧

> 对应示例：`examples/12_vocabulary/`（8 个例程）

"词汇类型"（vocabulary types）是标准库设计里的行话：**所有人都在用、所有接口都在传的基础值类型**。C++17 一次性收割了 Boost 的四个（optional/variant/any/string_view），是 TR1 之后最大的一次成建制毕业。本章讲透这四个的正主、两个重制/近亲（variant2/static_string）、两个没毕业的（uuid/logic）。

| 库 | 一句话 | std 对应 | 血缘 |
|---|---|---|---|
| Boost.Optional | 可能为空的值 | `std::optional`（C++17） | 直系（单子操作领先 std 九年） |
| Boost.Variant | 类型安全联合体 | `std::variant`（C++17） | 直系 |
| Boost.Variant2 | variant 现代重制 | 同 std::variant | 作者第二意见 |
| Boost.Any | 开放式类型擦除 | `std::any`（C++17） | 直系 |
| string_view | 无所有权字符串窗口 | `std::string_view`（C++17） | 直系 |
| Boost.StaticStrings | 定容栈上字符串 | 无 | ⭐ 嵌入式 |
| Boost.UUID | 全球唯一标识符 | `std::uuid`（提案中） | ⭐ |
| Boost.Tribool | 三值逻辑 | 无 | ⭐ |

## 12.1 Boost.Optional（2003）：消灭"魔法返回值"

```cpp
boost::optional<int> parse_positive(int v) {
    if (v > 0) return v;
    return boost::none;                       // 不再是 -1/0/errno 的猜谜
}
ok.value_or(0);                               // 默认值
ok.map([](int x){ return x*2; });             // 单子操作
boost::optional<int&> ref = target;           // 引用 optional（std 不允许）
```

运行输出（`optional.cpp`）：

```text
有值? 1 0
值 = 42 / 0
map×2 = 84
bad.map 不触发: -1
引用语义改写: target = 20
std transform = 43
in_place: xxxxx
```

**毕业档案**：`std::optional`（C++17，直系）。但有个惊人的时间差：`map`/`flat_map`（std 名 `transform`/`and_then`）boost 版 **2014 年就有**，std 到 **C++23** 才补——"直系毕业不等于立即完整毕业"的典型。boost 版残留差异：`optional<T&>`（引用语义，std 至今不允许）、`in_place_init` 姿态差异。

## 12.2 Boost.Variant（2003）：穷尽分派

```cpp
struct Visitor : boost::static_visitor<void> {          // 编译期穷尽
    void operator()(int v) const;
    void operator()(const std::string& v) const;
    void operator()(double v) const;
};
boost::apply_visitor(Visitor{}, v);
v.which();                                              // 活性成员下标
boost::get<int>(v);                                     // 类型不符 → bad_get 异常
```

运行输出（`variant.cpp`）：

```text
  int = 10
  str = boost
  dbl = 3.14
当前活性下标 = 2（double 是 2）
get<int> 失败抛 bad_get（不是 UB）
  std::visit: std
```

**毕业档案**：`std::variant` + `std::visit`（C++17，直系）。std 版的分派器从"必须继承 static_visitor"简化为"任何可调用物"（重载 lambda 惯用法）。boost 版残留价值：**递归变体**（表达式树 `variant<int, recurse<Expr>>` 直接自引用，std::variant 必须包一层 struct 间接递归）——写 AST/JSON 树时是真实差异。

> 实测坑：`Visitor{}` 聚合初始化会撞上 `static_visitor` 的 protected 构造——写 `Visitor() = default;` 再用花括号才稳。

## 12.3 Boost.Variant2（2019）：作者的"第二意见"

std::variant 定稿后，Peter Dimov 用纯 C++11 重写了一个没有历史包袱的版本。接口与 std 高度同构（`visit`/`get_if`/`holds_alternative`）：

```cpp
boost::variant2::variant<int, float, std::string> v = 3.14f;
boost::variant2::visit([](auto&& x){ ... }, v);
if (auto* f = boost::variant2::get_if<float>(&v)) { ... }
```

运行输出（`variant2.cpp`）：

```text
  装着 float? 1
  float 值 = 3.14
  是 float? 1
  切到 string 后长度 = 5
```

**选型**：需要 std::variant 但代码库还停在 C++11/14 时用它——这就是它存在的全部理由。

## 12.4 Boost.Any（2001）：开放的类型擦除

```cpp
boost::any a = 3.14;
boost::any_cast<double>(a);            // 值形式：类型不符抛 bad_any_cast
boost::any_cast<double>(&a);           // 指针形式：不符返回 nullptr
a.clear();                             // boost 版叫 clear（std 版叫 reset）
```

运行输出（`any.cpp`）：

```text
double = 3.14
any_cast<int> 失败抛 bad_any_cast
指针式取回 = 3.14
有值? 1 类型 = double
clear 后有值? 0
std 版长度 = 3
选型：开放载荷 any / 封闭分派 variant
```

**毕业档案**：`std::any`（C++17，直系）。**any vs variant 的分界**：any 是开放的（装任何可拷贝类型，运行期才知道是什么）——消息总线、属性表；variant 是封闭的（编译期列出候选，分派穷尽）——状态机、AST 节点。拿 variant 当 any 用会写出一长串候选列表，拿 any 当 variant 用会丢掉编译期穷尽性检查。

## 12.5 string_view（2014）：零拷贝的代价

```cpp
boost::string_view sv(url);                     // 指过去，不拷贝
sv.substr(0, sv.find("://"));                   // 切片零分配
path.remove_prefix(sv.find('/', 8));            // 游标推进
```

运行输出（`string_view.cpp`）：

```text
scheme = https host = codeberg.org
字面量长度 = 19
路径 = /lusing/programming
std 版 starts_with https? 1
```

**毕业档案**：`std::string_view`（C++17，直系）。唯一的坑两个版本共有：**view 不拥有底层**——`std::string("tmp").substr()` 的临时挂到 view 上就是悬垂经典。函数参数用 view、返回值慎用 view。

## 12.6 Boost.StaticStrings（2019）：定容缓冲

```cpp
boost::static_string<32> s = "hello";
s += " world";                                  // 容量内随便拼
boost::static_string<4> tiny = "overflow-me";   // 超容 → length_error，不是 UB
```

运行输出（`static_string.cpp`）：

```text
内容 = hello 容量 = 32
拼接后 = hello world 长度 = 11
超容抛 length_error（不是 UB）
find = 6（下标 6）
```

std 无对应。⭐ 用途明确：**不能分配内存的地方**（中断上下文、实时循环、微型 MCU）里要一个"有 std::string 接口子集"的东西。`std::inplace_string`（C++26 候选）就是它的标准化回声。

## 12.7 Boost.UUID（2006）：还没毕业的词汇类型

```cpp
boost::uuids::random_generator_mt19937 gen;
boost::uuids::uuid id = gen();                  // v4：随机
boost::uuids::name_generator sha1gen(boost::uuids::ns::dns());
sha1gen("codeberg.org");                        // v5：名字哈希，确定性
```

运行输出（`uuid.cpp`；v4 首行每次运行不同，断言全部确定）：

```text
uuid v4: b2047237-d7eb-41e8-815b-7657d251b447
两次不同? 1 版本位 = 4（4 = 随机版）
解析还原一致? 1
v5(dns,codeberg.org) 版本位 = 5
两次生成一致? 1
nil = 00000000-0000-0000-0000-000000000000 is_nil? 1
大小 = 16 字节
```

选型口诀：**v4 给"生成的唯一 ID"（会话、请求追踪），v5 给"从名字派生的稳定 ID"（同一 URL/域名永远同一 UUID，可跨系统对齐）**。16 字节定长可 memcpy，比哈希字符串省一半以上。`std::uuid` 是 C++26 前后的提案热点——到时再看毕业档案。

## 12.8 Boost.Tribool（2003）：第三态逻辑

```cpp
boost::tribool unknown = boost::indeterminate;
unknown && false;      // false（Kleene AND：假吸收）
unknown && true;       // indeterminate（未知传播）
boost::indeterminate(unknown);   // 显式判第三态
```

运行输出（`logic.cpp`）：

```text
真/假/未知
未知 AND 假 = 假（短路吸收）
未知 AND 真 = 未知（未知传播）
未知 OR 真 = 真（短路吸收）
NOT 未知 = 未知
indeterminate()? 1
```

std 无对应。与 `optional<bool>` 的语义分界：**tribool 的 indeterminate 是"答案就是第三态"**（SQL NULL、三态检查"通过/失败/未测"）；**optional<bool> 的无值是"没有答案"**（还没查、查不到）。混用会让 API 语义含混。

---


> 上一章：[11 · 错误处理基石](11-error.md) ｜ 下一章：[13 · 文件系统与编码](13-filesystem.md) ｜ 返回：[README](../README.md)
