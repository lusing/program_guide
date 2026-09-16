# 15 · 移动语义：别拷贝，搬走它

> 对应示例：`examples/15_moves/`

## 15.1 值类别：lvalue 与 rvalue

移动语义的全部前提，是分清"什么东西能被搬"。C++ 把表达式分成两大阵营：

| | lvalue（左值） | rvalue（右值） |
|---|---|---|
| 直觉 | **有名字、能再见到** | **临时的、用过即弃** |
| 例子 | 变量 `a`、`v[i]`、`*p` | 字面量 `42`、`a + b` 的结果、`Tracer{"x"}` |
| 能取地址吗 | ✅ | ❌ |
| 谁敢动它 | 谁也不能（别人还要用） | **随便搬**（反正要死了） |

口诀：**能放在赋值号左边的是 lvalue**（名字不精确但直觉够用）。关键认知：**同一类型既能是 lvalue 也能是 rvalue**——`Tracer a` 是 lvalue，`Tracer{"x"}` 是 rvalue，类型一模一样，区别只在"还可不可见"。拷贝对两者都安全；**移动只许对 rvalue 做**（搬一个还要用的对象等于制造悬垂）。

## 15.2 拷贝 vs 移动：Tracer 实验台

```cpp
class Tracer {
public:
    explicit Tracer(std::string name) : name_{std::move(name)} { … }
    Tracer(const Tracer& other) : name_{other.name_} {    ++copies_; … }  // 拷贝构造
    Tracer(Tracer&& other) noexcept : name_{std::move(other.name_)} { ++moves_; … }  // 移动构造
    // ……
};
// ……
std::println("-- 拷贝 --");
Tracer a{"原件"};
Tracer b = a;             // 拷贝构造：string 内容完整复制一份
std::println("-- 移动 --");
Tracer c = std::move(a);  // 移动构造：把 a 的 string "搬"给 c
```

拷贝 = 复印（原件新件各自完整）；**移动 = 过户**（资源的所有权从源转到目标，源变成"有效但未定"的空壳——还是个合法对象，可以析构、可以重新赋值，但**内容别指望**）。对 Tracer 的 string 成员，拷贝要分配内存复制字符，移动只是把 string 内部的指针改了名——O(n) 变 O(1)。

**`std::move` 不移动任何东西**——它只是把 lvalue 强转成 rvalue 引用的类型转换（"贴上'可搬'标签"），真正的搬发生在移动构造函数里。这是本章最反直觉的一句，值得抄在显示器边上。

`noexcept` 在移动构造上不是装饰：**vector 扩容时只有 noexcept 的移动才敢用**（搬一半抛了就丢数据，拷贝则可回退）——没标 noexcept 的移动，容器退回复制行为，性能白白损失。

## 15.3 容器操作：move 让插入便宜

```cpp
std::vector<Tracer> box;
box.reserve(2);                 // 预留容量：排除扩容干扰
box.push_back(Tracer{"临时"});  // 纯右值经 push_back(T&&)：一次移动落位
Tracer named{"具名"};
box.push_back(std::move(named));  // 具名对象要显式 move
```

实测输出与统计（示例真实运行结果）：

```text
-- vector 插入 --
  构造 临时
  移动 临时        ← 纯右值经 && 形参落位：一次移动
  构造 具名
  移动 具名        ← 显式 std::move：一次移动
统计：拷贝 1 次，移动 3 次
```

两条实操结论：**匿名临时直接传**（`push_back(Tracer{...})`，语言自动按右值走）；**具名对象想转移必须写 `std::move`**——不写就是拷贝，编译器不猜你"其实不想用了"。被 move 走的 `named` 此后内容未定，别再用（或给它赋新值后再用）。

## 15.4 RVO：返回值连移动都省

```cpp
auto make = []() -> Tracer { return Tracer{"返回值"}; };
Tracer r = make();  // C++17 保证消除：0 次拷贝 0 次移动
```

**返回值优化（RVO）**：按值返回纯右值时，C++17 **语言保证**对象直接在被调方构造、原地成为接收变量——0 拷贝 0 移动，统计里那行 `构造 返回值` 就是全部痕迹。由此得出两个纪律：

- **放心按值返回**大对象（vector、string）——现代 C++ 这么写不亏；
- **别写 `return std::move(local);`**——返回具名局部（NRVO）时加 move 反而**关闭**优化路径，多付一次移动。这是高频反模式，面试常客。

## 15.5 完美转发：值类别穿越模板

```cpp
void process(const Tracer&) { std::println("  process 收到左值"); }
void process(Tracer&&) { std::println("  process 收到右值"); }

template <typename T>
void relay(T&& arg) {
    process(std::forward<T>(arg));
}
// ……
Tracer x{"左值源"};
relay(x);                 // 左值 → process(const Tracer&)
relay(Tracer{"右值源"});  // 右值 → process(Tracer&&)
```

中间层函数的烦恼：收到左值要按左值转交、收到右值要按右值转交——但**形参本身有名字，永远是左值**（哪怕类型是 `T&&`），直接转发会把右值降级成左值（多付拷贝）。解法是组合拳：

- `T&&` 在模板推导语境是**转发引用**（lvalue 传进来 T 推成 `Tracer&`，rvalue 传进来 T 推成 `Tracer`——同一个 `T&&` 两副面孔）；
- `std::forward<T>(arg)` 按推导出的原貌还原值类别再转交。

什么时候需要它：**写"包装/转发"型代码时**（工厂函数、回调封装、make_ 系列）。日常业务代码用不到，但读懂标准库源码、面试推导题必考。注意：转发引用只在 `T&&` 且 T 待推导时成立；`void f(Tracer&&)` 这种具体类型的右值引用**不是**转发引用，就是普通右值引用。

## 15.6 rule of five 收官

第 08 章埋的"五件套"至此集齐：析构、拷贝构造、拷贝赋值、移动构造、移动赋值（本例未写移动赋值，编译器按 rule of zero/默认规则处理）。抉择树定案：

- 成员全是 RAII 类型（string/vector/智能指针）→ **rule of zero**，五个全不写（教程 95% 的类）；
- 真持有裸资源 → 五件套全写或全 default/delete，移动构造/移动赋值**记得 noexcept**。

## 15.7 坑位清单

1. **move 后继续用源对象**：`std::move(a)` 之后 `a` 内容未定（通常是空，但别赌）。转移后要么弃用、要么重新赋值。
2. **`return std::move(local)`**：亲手关掉 NRVO，多一次移动。返回局部直接 `return local;`。
3. **成员初始化忘 move**：`explicit Tracer(std::string name) : name_{std::move(name)} {}`——按值收的参数在初始化成员时 move 走是标准姿势（参数反正要死了）；写 `name_{name}` 就是白白拷贝。
4. **移动构造忘 noexcept**：容器扩容不敢用你的移动，静默回退拷贝——性能 bug 无告警。
5. **对 const 对象 move**：`const Tracer a` 被 std::move 后仍走拷贝（const 挡住了移动）——"我想移动却拷贝了"的老大难，检查源是否 const。
6. **转发引用与重载混用**：`f(T&&)` 会精确匹配一切参数，把旁边的重载全部饿死（"最贪婪的重载"）。转发引用版本单独成模板、别与具体重载同住。
