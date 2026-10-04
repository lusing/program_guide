# 06 · 工厂方法

第 5 章留下了两条"加产品不用改工厂"的路线：注册表（运行期查表）和工厂方法（编译期继承）。本章讲后者——GoF 收编的正式版本，别名"虚构造器（Virtual Constructor）"，刘伟 5.1.3 节的定义：**定义一个用于创建对象的接口，让子类决定实例化哪一个类。工厂方法使一个类的实例化延迟到其子类**。

## 意图与动机

之禅第 8 章的场景：日志框架。框架作者知道"日志要有统一入口"，但不知道用户想要文件日志还是控制台日志——**框架定义流程，用户决定实现**，这是工厂方法最典型的土壤。朴素写法让框架直接 `new FileLogger()`，用户想换控制台就得改框架源码；简单工厂把选择权交给参数，但框架还是要在 if 链里认识每种产品。

工厂方法的解法是把"造什么"变成一个**虚函数**：框架持有抽象 Creator，调用其 `create()`；用户写一个 Creator 子类，覆写 `create()` 返回自己想要的 Logger。框架代码里从头到尾没有出现任何具体产品类。

## 经典写法：Logger 家族

示例 `factory_method.hpp` 的产品侧：

```cpp
struct Logger {
    virtual ~Logger() = default;
    virtual void log(std::string_view msg) = 0;
};

class FileLogger final : public Logger {
public:
    void log(std::string_view msg) override { last_ = std::format("file<{}>", msg); }
    [[nodiscard]] const std::string& last() const { return last_; }
private:
    std::string last_;
};

class ConsoleLogger final : public Logger {
public:
    void log(std::string_view msg) override { last_ = std::format("console<{}>", msg); }
    [[nodiscard]] const std::string& last() const { return last_; }
private:
    std::string last_;
};
```

产品刻意保持极简：`log` 记下最后一条消息供断言检查——教学示例不需要真的开文件，"产品行为可观察"就够。Creator 侧是本章的重点：

```cpp
// Creator：use() 是模板方法——框架定流程，子类只回答"造什么"。
class LoggerCreator {
public:
    virtual ~LoggerCreator() = default;
    virtual std::unique_ptr<Logger> create() const = 0;

    // 注意：不能在构造函数里调用 create()——那时子类部分尚未出生，虚分派
    // 还在基类（GoF 原书在工厂方法一章专门警告过的坑）。所有工厂方法调用
    // 都放在 use() 这样的普通成员函数里。
    void use() const {
        auto logger = create();      // 工厂方法：制造
        logger->log("hi");           // 使用
        report(*logger);
    }

protected:
    virtual void report(const Logger& l) const = 0;   // 钩子：子类报告用过的 logger
};

class FileLoggerCreator final : public LoggerCreator {
public:
    std::unique_ptr<Logger> create() const override { return std::make_unique<FileLogger>(); }

protected:
    void report(const Logger& l) const override {
        output_ = static_cast<const FileLogger&>(l).last();
    }

public:
    const std::string& output() const { return output_; }   // 仅供测试观察
private:
    mutable std::string output_;
};

class ConsoleLoggerCreator final : public LoggerCreator {
public:
    std::unique_ptr<Logger> create() const override { return std::make_unique<ConsoleLogger>(); }

protected:
    void report(const Logger& l) const override {
        output_ = static_cast<const ConsoleLogger&>(l).last();
    }

public:
    const std::string& output() const { return output_; }
private:
    mutable std::string output_;
};
```

五个要点：

1. **`create()` 是工厂方法本体**：纯虚、无参、返回 `unique_ptr<Logger>`。GoF 的参与者表里它是 `factoryMethod(): Product`，C++23 的现代签名把裸指针换成了智能指针。
2. **`use()` 展示了 Creator 存在的真正理由**：Creator 不只是造对象，它是"制造 + 使用"这个流程的宿主。`use()` 调 `create()` 后立刻使用产品，框架逻辑（拿到 logger、打一条日志）与产品选择解耦。这种"父类流程 + 子类决策"的写法本身就是模板方法模式（第 27 章），工厂方法几乎总是嵌在模板方法里用。
3. **构造函数陷阱**（GoF 第 3 章 Factory Method 实现要点第 2 条的原话大意：**在 Creator 的构造器中不要调用工厂方法**）：构造 `FileLoggerCreator` 时先构造基类 `LoggerCreator`，此刻动态类型还是 `LoggerCreator`，`create()` 虚分派落到基类的纯虚函数上——直接未定义行为。所以 `use()` 是普通成员函数，调用时机在对象完全构造之后。这是从 Java 学工厂方法的人最容易踩的坑（Java 的 final 字段初始化顺序不同，问题被掩盖）。
4. **`report()` 下转型**：`static_cast<const FileLogger&>` 是 Creator 子类"知道"自己造什么产品的体现——`FileLoggerCreator` 承诺只产 `FileLogger`，所以它能安全下转型。GoF 说"参数化工厂方法"可以消除这层知识，C++ 里用返回类型协变做不到（智能指针不支持协变返回，见第 9 章），这里选择让 Creator 子类保留产品知识。
5. **`mutable output_`**：`report` 是 const（`use()` 是 const 链上的一环），但它要记录结果供测试观察——`mutable` 表达"逻辑上 const、物理上写入"的缓存/日志位。

## 运行观察

```text
工厂方法: file=file<hi>, console=console<hi>
所有权: 调用方持有 console<second> 并继续使用
```

第一行：同一个 `use()` 流程，两种 Creator 产出两种 logger——`file<hi>` 与 `console<hi>`。第二行验证所有权语义：

```cpp
std::unique_ptr<Logger> owned = cc.create();
owned->log("second");
auto* as_console = static_cast<ConsoleLogger*>(owned.get());
assert(as_console->last() == "console<second>");
```

`create()` 返回的 `unique_ptr<Logger>` 所有权完全移交调用方，对象在 `unique_ptr` 离开作用域时自动析构。GoF 时代"谁 delete 工厂造的对象"是个正式讨论题，现代 C++ 里答案编码在返回类型里。

## 模式结构（ASCII 类图）

```text
      ┌────────────────────┐         ┌──────────────┐
      │  LoggerCreator     │ ──────> │   Logger     │  抽象产品
      │  + create() = 0    │ 创建    │  + log() = 0 │
      │  + use()  [模板]   │         └──────┬───────┘
      │  + report() = 0    │                │
      └─────────┬──────────┘        ┌───────┴────────┐
                │ 继承              │                │
      ┌─────────┴──────────┐  ┌─────┴──────┐  ┌──────┴───────┐
      │ FileLoggerCreator  │  │ FileLogger │  │ ConsoleLogger│  具体产品
      │ → 造 FileLogger    │  └────────────┘  └──────────────┘
      └────────────────────┘
```

四个角色：抽象产品（Logger）、具体产品（File/ConsoleLogger）、抽象 Creator（LoggerCreator，声明工厂方法）、具体 Creator（File/ConsoleLoggerCreator，实现工厂方法）。与简单工厂对比：工厂从"一个函数"长成"一个平行继承树"——**产品树每加一种，Creator 树平行加一种**，双向都不用改旧代码（OCP 双兑现），代价是类的数量翻倍。

## 现代写法：不继承的工厂方法

GoF 在"实现"节列了两个变体，先补全它们再谈 C++ 替代：

**参数化工厂方法**：`create` 收一个参数决定造什么——这正是第 5 章简单工厂的入口形态，GoF 视其为工厂方法的退化特例。C++ 现代对应：lambda 直接捕获所需信息，参数进签名。

**懒初始化（lazy initialization）**：GoF 警告"构造器里别调工厂方法"后给的替代——构造函数把产品指针置空，访问时若为空才创建：

```cpp
class LazyProduct {
public:
    Product& product() {          // 访问器兼工厂
        if (!p_) p_ = create();   // 首次访问才造
        return *p_;
    }
private:
    std::unique_ptr<Product> p_;
    std::unique_ptr<Product> create() const;   // 真正的工厂方法
};
```

这把"何时造"也延迟到了使用点，代价是 `product()` 内部有分支、返回引用的所有权藏在类里。C++ 的 `std::optional` + `emplace` 是它的现代同构。GoF 时代这招救的是"构造期虚分派失效"，今天还有第二重价值：**构造永不失败**——所有可能失败的操作挪到使用点，返回 `expected`，类的不变量更薄。

继承树是 GoF 时代的默认手段。C++23 里"延迟决策到使用点"有更轻的载体——`std::function` 成员替代虚函数：

```cpp
class FnLoggerCreator {
public:
    using Maker = std::function<std::unique_ptr<Logger>()>;

    explicit FnLoggerCreator(Maker m) : make_(std::move(m)) {}
    std::unique_ptr<Logger> create() const { return make_(); }
    void use() const { create()->log("hi"); }   // 流程与继承版一致

private:
    Maker make_;
};

// 组装点一行搞定"哪种产品"，不再需要为每种产品写一个类：
auto file_creator = FnLoggerCreator{[] { return std::make_unique<FileLogger>(); }};
auto console_creator = FnLoggerCreator{[] { return std::make_unique<ConsoleLogger>(); }};
```

`FileLoggerCreator`/`ConsoleLoggerCreator` 两个类坍缩成两个 lambda。这正是"工厂方法的现代形态"：**虚函数的位置被可调用成员占据，继承让位给组合**——回调第 4 章合成复用原则的判据："造什么"是可变策略，组合比继承轻。

还能更进一步：C++23 的 `std::move_only_function` 支持不可拷贝的可调用体（比如捕获了 `unique_ptr` 的 lambda），`std::function` 要求可拷贝，遇到 move-only 闭包换它即可。何时仍用继承版？当 Creator 子类除了 `create()` 还要携带**状态与方法**（比如 `FileLoggerCreator` 额外管理日志目录）时，类的形态更自然。

## 两版取舍

| 维度 | 继承版（GoF 经典） | function 版（现代） |
|---|---|---|
| 每种产品一个 Creator 类 | 是（类数量 2n） | 否（n 个 lambda） |
| Creator 可携带状态/方法 | 天然 | 塞捕获里，复杂状态不优雅 |
| 运行开销 | 一次虚调用 | 一次 function 调用（内部也是间接跳转） |
| 反射式发现（枚举所有 Creator） | typeid 可查 | 需要自建注册表 |
| 教科书对应 | GoF/刘伟/之禅 | 无——但这正是生产代码的常态 |

结论：**继承版用于 Creator 有身份（有状态、有方法、要被指认）的框架扩展点；function 版用于"只是一个创建回调"的场景**。两者与第 5 章的注册表也不互斥：注册表里的 `ShapeMaker` 本质上就是 function 版工厂方法的一个槽位。

## 陷阱清单

1. **构造函数里调用工厂方法**（现象：基类构造器调 `create()`，子类实现没跑；原因：构造期间动态类型是基类，虚分派不落地；后果：纯虚调用直接崩溃，或基类版本被误用。对策：工厂方法只在普通成员函数里调；确需"造好即用"用工厂函数 + `unique_ptr` 组合）。
2. **工厂方法带副作用**（现象：`create()` 里打开文件、注册全局回调；原因：工厂与初始化边界不清；后果：每次调用都重复副作用，测试难以隔离。对策：create 只管 new，副作用交给产品的构造/使用流程）。
3. **产品与 Creator 绑死**（现象：`LoggerCreator` 里出现 `dynamic_cast<FileLogger*>` 判断；原因：把产品知识上移到基类；后果：加产品要改基类，工厂方法白费。对策：产品知识只存在于对应的 Creator 子类，如本章 `report()` 的写法）。
4. **返回可空指针表示失败**（现象：`create()` 失败返回 nullptr；原因：没有错误通道；后果：调用方解引用崩溃。对策：与第 5 章一致，失败走 `std::expected` 或 `std::optional`）。
5. **为"看起来高级"上抽象工厂**（现象：只有一个产品族却写了 Creator 继承树；原因：模式先行；后果：类数量翻倍换来零收益。对策：YAGNI——第二个产品族出现前，`make_unique<T>()` 直写就是最好的工厂）。

## 三书对应

- 之禅：第 8 章"工厂方法模式"（8.2 定义、8.3 应用——女娲造人、8.4 扩展——多个工厂类/简单工厂与工厂方法的混合形态）。
- 刘伟：第 5 章"工厂方法模式"（5.1 动机与定义——含"虚拟构造器/多态工厂"别名、5.2 结构与分析、5.4 效果与应用）。
- GoF：第 3 章 3.3 节 Factory Method——**实现要点里明确警告了"构造器中不调用工厂方法"并给出 lazy initialization 替代写法**，本章陷阱 1 的原始出处；"参数化工厂方法"一节对应现代 function 版。

*可选延伸：可运行示例见 examples/06_factorymethod/。*
