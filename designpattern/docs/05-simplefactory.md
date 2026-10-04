# 05 · 简单工厂

GoF 的 23 个模式里没有它，但没有它你很难顺畅地讲清工厂方法——刘伟书干脆给了它独立一章（第 4 章）。本章用它开创建型篇：先解决"创建逻辑该放哪"这个最原始的问题，再让它的两个缺陷自然引出第 6 章。

## 意图与动机

写代码时最常出现的重复之一：**按某种输入造出不同类型的对象**。解析器按扩展名选实现，绘图库按文件格式造 reader，游戏按怪物 ID 生成怪物。朴素写法把构造逻辑直接写在调用点：

```cpp
std::unique_ptr<Shape> s;
if (kind == "circle")      s = std::make_unique<Circle>();
else if (kind == "square") s = std::make_unique<Square>();
else throw std::invalid_argument("未知形状");
```

一行看不出问题，十行就是灾难：每个调用点都抄一遍 if-else；新形状出现时要改 N 处；`Circle`、`Square` 这些具体类名渗透到业务代码的每个角落——调用方与"怎么构造"强耦合。简单工厂的意图就一句话：**把构造逻辑收拢到一个专门的地方，调用方只负责"消费"对象**（刘伟 4.5.1 节称之为"责任的分割"）。

## 经典写法：一个函数一个 if 链

示例 `simple_factory.hpp` 的完整实现：

```cpp
struct Shape {
    virtual ~Shape() = default;
    [[nodiscard]] virtual std::string name() const = 0;
};

struct Circle final : Shape {
    [[nodiscard]] std::string name() const override { return "circle"; }
};

struct Square final : Shape {
    [[nodiscard]] std::string name() const override { return "square"; }
};

// 工厂本体：if-else 串。加一种形状 = 改一处 + 重新编译，这正是第 6 章要治的病。
inline std::expected<std::unique_ptr<Shape>, std::string> create_shape(
    std::string_view kind) {
    if (kind == "circle") return std::make_unique<Circle>();
    if (kind == "square") return std::make_unique<Square>();
    return std::unexpected(std::format("未知形状: {}", kind));
}
```

三个设计决定逐个说明：

1. **返回 `unique_ptr<Shape>` 而不是 `Shape*` 或 `Shape&`**。工厂造的对象生命周期归调用方，`unique_ptr` 把这份所有权写进类型签名——拿到手就是你的，用完自动析构。GoF 1995 年的 C++ 伪码在这一点上全都付了学费（`delete` 散落各处）。
2. **失败返回 `std::expected<unique_ptr<Shape>, std::string>`**。传入不认识的名字是"可预期的失败"（用户输入、配置文件都可能给错），按本书第 1 章立的约定走 expected 而不是异常。调用方对成功与失败两条路径的处理在类型上就分开了：`has_value()` 判断、`error()` 取原因。Java 版简单工厂通常 throw 或返回 null，null 在 C++ 里意味着 `unique_ptr` 可空 + 调用方解引用前判空——错误信息全丢了，`expected` 显式携带原因，这是 C++23 的后发优势。
3. **函数标记 `inline` 放头文件**。简单工厂小到不值得开一个 `.cpp`，头文件内联即可；等它长出状态（下一节的注册表），再考虑拆分。

运行输出前两行：

```text
简单工厂: circle ok, hex -> 未知形状: hex
```

成功路径拿到 `name()=="circle"` 的对象，失败路径拿到 `"未知形状: hex"` 的错误串——两个分支都过断言，说明 `expected` 的双路径都真实工作。

## 经典写法的两个缺陷

刘伟 4.5.1 节列了四条缺点，落到 C++ 上最疼的两条：

1. **违反开闭原则**。加三角形要打开 `create_shape` 改 if 链，所有包含这个头文件的编译单元重编。产品越多，这根 if 链越长——刘伟称之为"工厂逻辑过于复杂，不利于系统的扩展和维护"。
2. **静态工厂无法继承扩展**（Java 语境下尤其明显，刘伟用 `SuperClass/SubClass` 的静态方法示例证明：静态方法不是虚方法，子类覆盖无效）。C++ 的对应版本是：自由函数没有多态，想给工厂换行为只能改函数本身或再加一层参数。

## 现代写法：注册表工厂

治"加产品要改工厂"的药方是**注册表**：工厂从 if 链变成一张"名字 → 构造器"的表，加产品 = 注册一行，工厂代码零修改。示例 `registry_factory.hpp`：

```cpp
using ShapeMaker = std::function<std::unique_ptr<Shape>()>;

class ShapeRegistry {
public:
    static ShapeRegistry& instance() {
        static ShapeRegistry inst;   // magic static：线程安全的一次初始化（见第 8 章）
        return inst;
    }

    bool add(std::string kind, ShapeMaker maker) {
        return makers_.emplace(std::move(kind), std::move(maker)).second;
    }

    std::expected<std::unique_ptr<Shape>, std::string> make(std::string_view kind) {
        auto it = makers_.find(std::string{kind});
        if (it == makers_.end())
            return std::unexpected(std::format("未注册形状: {}", kind));
        return it->second();   // 调用注册时存下的构造器
    }

    [[nodiscard]] size_t size() const { return makers_.size(); }

private:
    ShapeRegistry() = default;
    std::map<std::string, ShapeMaker> makers_;
};
```

四步拆解：

1. **`ShapeMaker` 是构造器的类型化身**。`std::function<std::unique_ptr<Shape>()>` 表示"任何无参、能产出 Shape 的可调用体"——lambda、函数指针、仿函数都行。注册的不再是"名字"，而是"名字 + 怎么造"这对组合。
2. **`instance()` 用 magic static**：C++11 起局部 static 的初始化由标准保证"只执行一次、并发安全"，这是第 8 章单例模式在 C++ 的标准答案，此处先行借用。
3. **`add` 返回 bool**：`emplace` 的 second 告诉你名字是否新注册——重复注册被静默拒绝并返回 false，调用方能感知；选 `map` 而不是 `unordered_map` 是为了让遍历顺序稳定（确定性输出原则）。
4. **`make` 的错误路径与简单工厂版同形**：未注册名返回 `expected` 错误，两版工厂在调用方看来接口一致——迁移成本只有"注册"这一步。

使用端（示例 `main.cpp`）：

```cpp
auto& reg = ShapeRegistry::instance();
reg.add("circle", [] { return std::make_unique<Circle>(); });
reg.add("square", [] { return std::make_unique<Square>(); });
assert(reg.size() == 2);
```

lambda 一行完成注册。更进一步（第 35 章插件框架会展开）：每个产品在自己 `.cpp` 里放一个静态注册对象，程序启动时自动完成注册，连 main 都不用改——那时"加产品"等于"加一个文件"。输出第二段：

```text
注册表: size=2, hex -> 未注册形状: hex
```

错误信息从"未知形状"（工厂不认识）变成"未注册形状"（表里没有），措辞变化对应责任转移：工厂不再"知道"所有产品，只"记住"被注册的产品。

## 两版取舍

| 维度 | if-else 简单工厂 | 注册表工厂 |
|---|---|---|
| 加一种产品 | 改工厂代码 + 重编 | 注册一行（或一个文件） |
| 工厂代码复杂度 | 随产品数线性增长 | 恒定 |
| 可读性 | 一眼看清全部产品 | 要查注册点才知道有哪些 |
| 调试 | 断点打在工厂即可看全貌 | 注册时机分散，启动顺序要留意 |
| 适用规模 | 产品 ≤5 且稳定 | 产品多、插件化、第三方扩展 |

注册表不是免费的：初始化顺序、注册失败的处理、名字冲突，都是 if-else 版没有的问题。**产品少而稳定时，简单工厂的直白就是优点**——刘伟 4.5.2 节"适用环境"第一条正是"工厂类负责创建的对象比较少"。第 6 章的工厂方法从另一个方向（继承）解决同一问题，两种修法在第 6 章末尾正面对比。

## 模式结构（ASCII 类图）

```text
   调用方 ──传 kind──> ┌───────────────┐
                       │ create_shape  │  if "circle"  → make_unique<Circle>()
                       │  (自由函数)    │  if "square"  → make_unique<Square>()
                       └──────┬────────┘  else        → unexpected("未知形状")
                              │ 返回 unique_ptr<Shape>
                              ▼
                       ┌──────────────┐
                       │    Shape     │  抽象产品
                       │ + name() = 0 │
                       └──────┬───────┘
                    ┌─────────┴─────────┐
             ┌──────┴──────┐     ┌──────┴──────┐
             │   Circle    │     │   Square    │  具体产品
             └─────────────┘     └─────────────┘
```

三个角色：工厂（一个函数或一个静态方法，认识所有具体产品）、抽象产品（Shape）、具体产品（Circle/Square）。依赖方向值得看一眼：**调用方只依赖工厂和抽象产品**，但工厂自己依赖全部具体产品——这就是简单工厂的一切优缺点的根源。它把"认识具体类"的责任从 N 个调用点集中到 1 个工厂里（依赖集中了，好管理了），但没消灭这份依赖（加产品仍要改工厂）。第 6 章的工厂方法才真正把工厂对具体产品的依赖也拆掉——每个 Creator 子类只认识自己的产品。

## GoF 为什么不收编它

GoF 原书没有简单工厂——它只是工厂方法的退化形（工厂类不可变、产品选择写死），GoF 直接讲了更一般的工厂方法。但工程里它出现频率极高，所以刘伟给它独立成章、之禅把它作为工厂方法的引子。学完本章记住一句定位：**简单工厂是"把构造逻辑收拢"的第一步，注册表是"收拢后不再改"的第二步，工厂方法是"让子类决定造什么"的第三步**——三步在第 6 章汇合。

## C++ 特有形态：编译期简单工厂

字符串查表是运行期选择；如果产品集合编译期就定死，C++ 还有第三种形态——**模板重载分派**：

```cpp
template <typename T>
std::unique_ptr<Shape> create_typed() requires std::derived_from<T, Shape> {
    return std::make_unique<T>();
}

auto c = create_typed<Circle>();   // 调用点指名道姓，零查表零字符串
```

`requires std::derived_from<T, Shape>` 让"乱传类型"在实例化点报错。它与 if-else 版分工：**类型选择编译期可知用模板版（类型安全、零开销），名字来自运行期数据（配置、网络、用户输入）才需要字符串工厂**。三形态总结：if-else（教学起点）、注册表（运行期扩展）、模板（编译期分派）——第 6/7 章的工厂方法/抽象工厂分别是后两者的继承化包装。

## std::expected 速览

本章首次正式使用 `std::expected`，把用法定格在这，全书后 30 章复用：

- `std::expected<T, E>`：要么装成功值 `T`，要么装错误 `E`，二选一。`has_value()` 判别，`value()`/`operator*` 取成功值（错误态下取值是未定义行为，先判再用），`error()` 取错误。
- `std::unexpected(e)` 是构造错误分支的字面量：`return std::unexpected("原因");`。
- 与 `std::optional` 的分界：optional 只说"没有"，expected 还说"为什么没有"。工厂的"未知名"需要原因回传给日志/UI，选 expected。
- 与异常的分界：异常适合"不该发生"（编程错误、构造失败无处安放返回值）；expected 适合"调用方必须处理"（解析失败、未注册）。本章工厂两种都没有用异常——构造失败在这里是业务分支，不是事故。

## 陷阱清单

1. **工厂返回裸指针**（现象：`Shape* create_shape(...)`；原因：从 GoF 原书直接抄签名；后果：谁 delete？悬垂？双重释放。对策：返回 `unique_ptr`，共享需求升格 `shared_ptr`）。
2. **参数歧义**（现象：`create(0)` 不知道 0 是圆是方；原因：用裸数字/布尔当产品选择参数；后果：调用点可读性为零。对策：`string_view` 名字或 `enum class`，示例用的是名字）。
3. **expected 被忽略**（现象：拿到 `expected` 不判 `has_value()` 直接 `*`；原因：当 optional 用；后果：对错误状态解引用是未定义行为。对策：`assert` + 结构上区分成功/失败分支，或用 `and_then`/`transform` 链式处理）。
4. **注册表静默吞掉重名**（现象：两次 `add("circle", ...)` 第二次丢了但没人发现；原因：emplace 的拒绝语义被当成功；后果：跑起来用的是旧构造器，排查半天。对策：`assert(add(...))` 或记日志，测试覆盖注册数）。
5. **把注册表当垃圾桶**（现象：注册的 lambda 里塞初始化逻辑、全局状态；原因：注册表入口太方便；后果：隐藏副作用，测试无法隔离。对策：注册的构造器只做构造，初始化交给使用方）。

## 三书对应

- 之禅：无独立章；工厂方法章（第 8 章）开篇以"女娲造人"引出简单工厂的局限。
- 刘伟：第 4 章"简单工厂模式"（4.2 动机与定义、4.3 结构与分析、4.5 效果与应用——优缺点四条与适用环境两条本章已引）。
- GoF：无独立章；第 3 章 3.3 节 Factory Method 的讨论覆盖其退化形；Abstract Factory 的实现要点里也谈到了用简单工厂造工厂。

*可选延伸：可运行示例见 examples/05_simplefactory/。*
