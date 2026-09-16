# 13 · 模板基础：把类型当参数

> 对应示例：`examples/13_templates/`

## 13.1 函数模板：T 代替具体类型

为 int 和 double 各写一个 max？在拷贝代码之前，先想想两个版本**除了类型名还有什么不同**——没有，就该模板化：

```cpp
template <typename T>
T max_of(const T& a, const T& b) {
    return (a < b) ? b : a;
}
// ……
std::println("{} {}", max_of(3, 9), max_of(2.5, 1.5));  // 9 2.5
std::println("{}", max_of<double>(3, 2.5));             // 混合类型要显式指定
```

`template <typename T>` 声明"这里有个类型参数 T"，函数体里 T 当普通类型用。调用时通常不用写 `<int>`——**实参推导**从 3 和 9 推出 T=int。混合类型（`max_of(3, 2.5)`）推导不出唯一 T，编译错——显式写 `max_of<double>(3, 2.5)`（3 被转为 double）。

**模板不是函数，是生成函数的图纸**。编译器在每个用到的类型上**实例化**出一份真代码：`max_of<int>` 和 `max_of<double>` 是两个毫不相关的函数，各有各的机器码。这个认知带出模板的全部性格：

- **编译期多态**：分派发生在编译期（对比虚函数的运行期，第 16 章对照）；
- **零开销**：实例化出的代码和你手写的一样快，还常常更快（内联友好）；
- **代码膨胀**：用 20 种类型就实例化 20 份；
- **报错长**：错误在实例化时才浮出——见 13.5。

## 13.2 类模板：类型参数化的容器

```cpp
template <typename T>
class Stack {
public:
    void push(T value) {
        items_.push_back(std::move(value));
    }
    T pop() {
        if (items_.empty()) {
            throw std::out_of_range("stack is empty");
        }
        T top = std::move(items_.back());
        items_.pop_back();
        return top;
    }
    [[nodiscard]] bool empty() const { return items_.empty(); }
    [[nodiscard]] std::size_t size() const { return items_.size(); }

private:
    std::vector<T> items_;
};
// ……
Stack<int> ints;           // 装整数的栈
Stack<std::string> words;  // 同一套代码，第二种类型
```

vector 本尊就是这个形状——`std::vector<int>` 即"vector 模板在 int 上的实例化"。自己写一遍 Stack 是理解容器的最短路径：成员是 `vector<T>`（rule of zero，栈本身不管资源）、push/pop 用 std::move 转移（第 15 章解释为什么值得）、`[[nodiscard]]` 标记 size/empty 不许扔返回值。

类模板**成员函数随用随实例化**：`Stack<SomeType>` 只要不调 pop，pop 就不会被实例化——哪怕 pop 的代码对 SomeType 编译不过。这是模板的懒加载特性，也是玄学报错的来源之一。

## 13.3 非类型模板参数与 CTAD

```cpp
template <typename T, std::size_t N>
double average(const std::array<T, N>& arr) {
    double sum = 0;
    for (const T& v : arr) {
        sum += v;
    }
    return sum / static_cast<double>(N);
}
// ……
std::array<int, 4> nums{2, 4, 6, 8};
std::println("平均 = {}", average(nums));  // 5：N=4 自动推导

Stack copied{ints};  // CTAD：从拷贝构造推导出 Stack<int>
```

模板参数不只能是类型，还能是**编译期常量值**（非类型参数）：`std::array<T, N>` 的 N、`std::span<T, N>` 的长度都是——这就是"数组长度为什么进类型"的答案。`average(nums)` 连 N 都不用写，实参推导全包。

**CTAD**（类模板实参推导，C++17）：构造时从初始化表达式反推模板参数，`Stack copied{ints};` 推出 `Stack<int>`（`std::vector v{1,2,3}` 推出 `vector<int>` 同理）。尖括号能省则省，推导不出的（如空容器 `Stack<>`）再显式写。

## 13.4 编译期多态 vs 运行期多态

两种"同一接口、多种实现"，选型是架构级决定：

| | 模板（静态） | 虚函数（动态，第 16 章） |
|---|---|---|
| 分派时机 | 编译期 | 运行期（虚表跳转） |
| 开销 | 零（常被内联优化掉） | 一次间接跳转，难内联 |
| 类型约束 | 任意（鸭子类型：能用就行） | 必须继承同一基类 |
| 代码形态 | 每类型一份实例 | 一份代码 |
| 异质容器 | ❌（类型不同=实例不同） | ✅ `vector<unique_ptr<Base>>` |

**默认用模板**（标准库的算法、整个 ranges 都是模板写的）；确需"运行期才知道具体类型"（插件、异质集合、跨模块边界）才上虚函数。第 14 章的概念，就是给模板的"鸭子类型"装上安检门。

## 13.5 读模板报错：一门手艺

```cpp
std::vector<int> v{1, 2};
auto r = std::accumulate(v.begin(), v.end(), std::string{"x"});  // 编不过
```

模板错误信息动辄几十行，因为错误在**实例化深处**才爆：编译器已经展开了三层模板，才发现你给的类型对不上。读法心法：

1. **从最里层的人话开始**：找第一行提到**你的文件名和行号**的 note——那是实例化链条的起点；
2. 错误通常就一句（"no operator+ for these types"），其余都是"我怎么走到这里的"；
3. 看到 `could not deduce template argument` / `no matching overloaded function`：先检查传的**类型**是不是你想的类型（`auto` 接了个意外类型是常见源头）。

C++20 的概念（第 14 章）把大半模板报错从"模板内部惨案现场"提前到"调用点一句人话"——这就是它被评为 C++20 最重要特性的原因。

## 13.6 坑位清单

1. **模板定义要可见**：另一个 .cpp 里调用模板时，编译器必须看得见完整定义（否则只能实例化声明）——模板放头文件，原因见第 18 章。
2. **`Stack<int>` 与 `Stack<double>` 是两个类型**：不能互相赋值、不能混装。想"一个栈装多种类型"要 variant（进阶）或继承体系。
3. **实例化代码膨胀**：模板滥用在 20 种类型上、每个函数 500 行→二进制暴涨。收敛泛型面，只在真重复处模板化。
4. **依赖类型成员要 typename**：`T::value_type x;` 要写 `typename T::value_type x;`（编译器不知道 value_type 是类型还是静态成员）。认识它即可，报错能看懂。
5. **成员函数懒实例化的幻觉**：`Stack<X>` 能编译通过不代表所有成员都能用——用到 pop 那天才报错。测试要覆盖实际调用的成员。
6. **浮点/字符串当非类型参数**：C++20 前 NTTP 只能整数/指针/枚举/引用，`std::string` 模板参数（类类型 NTTP）是 C++20 新能力且限制多——常量用 constexpr 变量传递更省心。
