# 27 · 模板方法

行为型篇前六章全是对象行为型，本章回到**类行为型**——唯一通过继承实现行为复用而常被推荐的场合。GoF 5.10 节的定义：**定义一个操作中的算法的骨架，而将一些步骤延迟到子类中。模板方法使得子类可以不改变一个算法的结构即可重定义该算法的某些特定步骤**。"骨架在父类、步骤在子类"十个字就是全部——剩下的工程问题只有一个：调用方向。骨架**调用**步骤（父类代码调子类实现），控制流反转——好莱坞原则"别调用我们，我们会调用你"。

## 意图与动机

游戏流程的公共剧本：初始化 → 三回合 → 收尾。棋类游戏（象棋、围棋）剧本一致、每步内容不同。朴素写法是每盘棋自己写一遍 `init(); for(3) turn(); end();`——**剧本知识被抄了 N 份**，后来要给所有游戏加"回合间存档"，得改 N 个类。模板方法把剧本写死在基类的一个方法里：

```cpp
std::string run() const {
    std::string out = initialize();
    for (int i = 1; i <= 3; ++i) out += take_turn(i);
    out += end();
    return out;
}
```

子类只实现 `initialize/take_turn/end` 三个步骤——剧本的**结构**锁死在父类，步骤的**内容**下放给子类。之禅 10 章的悍马模型是同一个故事：车模的发动→行驶→鸣笛流程一致，具体车型各自填内容。

## 经典写法：游戏骨架

示例 `template_method.hpp`：

```cpp
// AbstractClass：run() 是模板方法——步骤顺序写死在父类，子类不可改剧本。
class Game {
public:
    virtual ~Game() = default;

    [[nodiscard]] std::string run() const {
        std::string out = initialize();
        for (int i = 1; i <= 3; ++i) out += take_turn(i);
        out += hook();                    // 钩子：默认空实现，子类可选择性插入
        out += end();
        return out;
    }

protected:
    [[nodiscard]] virtual std::string initialize() const = 0;
    [[nodiscard]] virtual std::string take_turn(int i) const = 0;
    [[nodiscard]] virtual std::string end() const = 0;
    [[nodiscard]] virtual std::string hook() const { return ""; }   // 钩子默认实现
};

struct Chess final : Game {
private:
    [[nodiscard]] std::string initialize() const override { return "init chess;"; }
    [[nodiscard]] std::string take_turn(int i) const override {
        return "turn " + std::to_string(i) + ";";
    }
    [[nodiscard]] std::string end() const override { return "end;"; }
    [[nodiscard]] std::string hook() const override { return "check;"; }   // 棋类加"将军"检查
};

struct Go final : Game {
private:
    [[nodiscard]] std::string initialize() const override { return "init go;"; }
    [[nodiscard]] std::string take_turn(int i) const override {
        return "turn " + std::to_string(i) + ";";
    }
    [[nodiscard]] std::string end() const override { return "end;"; }
    // hook() 不给：Go 不必都写——hook 吃默认空实现
};
```

三个设计要点。**步骤全放 protected**：它们是骨架的内部零件，客户不该直接调 `take_turn`——public 的只有 `run()`。**钩子（hook）是步骤的弱化形态**：纯虚步骤强迫子类实现；钩子给默认实现，子类"想插就插"（Chess 插了 `check;`，Go 没插）——这是模板方法区分"必须变"与"可选变"的工具。**`Chess` 覆盖 hook、`Go` 不覆盖**，两盘棋的剧本在结构上完全一致。运行侧（`main.cpp`）：

```cpp
assert(chess.run() == "init chess;turn 1;turn 2;turn 3;check;end;");
assert(go.run() == "init go;turn 1;turn 2;turn 3;end;");
```

运行输出：

```text
模板: Chess::run 剧本 = init->turn1..3->check(hook)->end
模板: Go::run 钩子默认空，剧本其余与 Chess 同构
CRTP: 两盘棋输出与虚函数版逐字节一致（无虚表）
```

断言钉死两点：Chess 的三段固定文本按剧本顺序拼接（含钩子位置——在回合后、收尾前）；Go 钩子缺席但剧本骨架一字不差。

## 模式结构（ASCII 调用序）

```text
   客户 ──run()──> Game::run()                （模板方法：public、非虚、final 语义）
                     │
                     ├─> this->initialize() ══虚══> Chess::initialize
                     ├─> this->take_turn(1..3) ══虚══> Chess::take_turn
                     ├─> this->hook() ══虚══> Chess::hook / Go::hook(默认 "")
                     └─> this->end() ══虚══> Chess::end

   控制流：客户 → 父类骨架 → （被骨架调用的）子类步骤
           ——方向反着的继承调用，即好莱坞原则
```

GoF 两角色：AbstractClass（Game——定义骨架 + 原语操作）、ConcreteClass（Chess/Go——实现原语）。**run() 必须非虚**：它是结构承诺，被子类覆盖等于子类重写剧本，模板方法就不成立了（Java 世界给模板方法标 final，C++ 的惯例是文档 + 命名约定）。

## 现代写法：CRTP 静态分发

虚表版本每次调用一跳虚表；骨架在编译期就锁定的场景，CRTP 把"父类调子类"改写为编译期转换（`crtp_method.hpp`）：

```cpp
template <class D>
class GameCRTP {
public:
    [[nodiscard]] std::string run() const {
        const D& self = static_cast<const D&>(*this);   // 静态下转：编译期确定 D
        std::string out = self.initialize();
        for (int i = 1; i <= 3; ++i) out += self.take_turn(i);
        out += self.hook();
        out += self.end();
        return out;
    }

protected:
    GameCRTP() = default;

    // 静态钩子默认实现：派生类没写 hook() 时，self.hook() 名字查找落到这里
    [[nodiscard]] std::string hook() const { return ""; }
};

struct ChessCRTP final : GameCRTP<ChessCRTP> {
    [[nodiscard]] std::string initialize() const { return "init chess;"; }
    // take_turn / end / hook 略，同虚函数版
};

struct GoCRTP final : GameCRTP<GoCRTP> {
    // initialize / take_turn / end 略
    // hook() 不写：吃基类默认空实现——与虚函数版 Go 同构
};
```

三个 C++ 特性各就各位：`static_cast<const D&>(*this)` 是 CRTP 的核心一跳（基类模板知道 D，向下转型安全）；派生类**不写 override**（没有虚函数可覆盖，纯粹的名字隐藏与查找）；**静态钩子**靠名字隐藏实现——`GoCRTP` 不定义 `hook()`，`self.hook()` 找到基类默认版；`ChessCRTP` 定义了，找到派生类版。运行输出第三行钉死 CRTP 版与虚函数版逐字节一致。取舍：

| | 虚函数版 | CRTP 版 |
|---|---|---|
| 分派 | 运行期（虚表一跳） | 编译期（可内联） |
| 运行期多态 | 支持（Chess/Go 混存容器） | 不支持（类型在编译期定死） |
| 骨架代码膨胀 | 无（一份 run） | 每实例化一份 run（通常被内联消化） |
| 钩子默认值 | 虚函数默认实现 | 基类非虚函数（名字隐藏） |
| 典型场景 | 框架扩展点 | `enable_shared_from_this`、表达式模板、标准库 `std::iterator` 旧风格 |

判定与第 26 章 concepts 版同构：**需要运行期多态用虚表，编译期可定用 CRTP**。标准库的选择可作旁证：`std::enable_shared_from_this` 是 CRTP（编译期已知的单继承注入），而 iostream 的 streambuf 体系是虚函数（运行期可换缓冲实现）——两种形态在同一个标准库里各守其位。

## 钩子的光谱：从纯虚到参数注入

模板方法的"变化点"其实是一条光谱，本例演示了三个档位：

1. **纯虚步骤**（initialize/end）——必须变，不实现编不过。适合"每个子类必然不同"的步骤。
2. **虚函数默认实现**（Go 的 end 走自己的、hook 吃默认）——可选变。注意钩子的默认实现要写成**空操作而非隐含行为**，让"没写钩子"与"没钩子"语义一致。
3. **参数注入**——骨架不变、步骤不变，只有数值不同。若 Chess 与 Go 的差异只是回合数 3 和 5，那根本不是模板方法的活：`Game(int turns)` 一个构造参数解决。判断顺序从 3 往 1 走：能参数注入就不上钩子，能钩子就不上纯虚——**变化点越少，继承树越稳**。

## 与其他模式的边界

模板方法是所有"父类固定流程"模式的地基，三处高频混淆值得分别说破：与**策略**（第 26 章）——模板方法用继承复用整个流程、变化点在子类内部；策略用组合替换整个算法、变化点在对象外部；流程本身是资产用模板方法，流程黑箱算法多变用策略。与**工厂方法**（第 6 章）——工厂方法常常就是模板方法里的一个钩子步骤（骨架调用 `create_part()`，子类决定造什么），两者是包含关系而非竞争关系。与**访问者**（第 28 章）——模板方法固定"遍历顺序"这一个维度；访问者固定"被操作的结构"、开放"操作"维度，两者可叠加（visitor 里用模板方法编排多趟访问）。

## 标准库里的模板方法

模板方法在标准库与工业框架里的存在感远超 GoF 清单，认得出这形状，读库的能力就上一层：

- **`std::enable_shared_from_this<T>`**——CRTP 版模板方法的近亲：基类注入 `shared_from_this()` 能力，派生类"实现"只有一个自己。它没有流程骨架，但 CRTP 静态注入的机制一致。
- **`std::streambuf` 体系**——虚函数版模板方法的教科书实现：`sputn()` 是模板方法（写缓冲的骨架），`xsputn/overflow` 是步骤（默认实现可覆盖）——iostream 换文件缓冲/字符串缓冲全靠子类填步骤。
- **容器适配器的排序钩子**——`std::sort` 的 Compare 参数不是继承钩子，但"骨架（快排变体）固定、比较策略注入"的思想同源；到 concepts 版 Compare 就是第 26 章讲的概念约束。
- **GUI 框架的窗口过程**——Win32 的 `DefWindowProc` 调用链：框架固定消息循环骨架，子类（窗口过程）只填感兴趣的消息分支——好莱坞原则在系统编程里的现身。

读库判据一句话：**看到"public 非虚入口 + protected 虚步骤"的组合，模板方法认领**；看到 `enable_xxx`/CRTP 基类，静态版认领。

## 测试法

模板方法的测试分层：

- **骨架测试**（测基类）：用一个测试专用子类实现全部步骤返回哨兵值，断言 `run()` 的拼接顺序——骨架逻辑只测一次，所有子类共享这份保证（本例 Chess/Go 的两个断言就是两份骨架回归）。
- **步骤测试**（测子类）：每个步骤独立可测（`take_turn(1)` 直接可调——protected 挡住客户不挡测试，测试代码放子类/友元即可）。
- **钩子两态**：覆盖钩子与不覆盖钩子的子类各测一条（Chess/Go 正好一对）——默认实现的存在性本身是被测行为。

## 陷阱清单

1. **run() 被子类覆盖**（现象：某子类重写了 run 省掉一个步骤；原因：run 没锁死；后果：剧本失控，模板方法名存实亡。对策：run 非虚 + 文档声明"骨架不可变"；要求更强的仓库可加编译期检查（CRTP 版天然免疫——run 在模板基类里，派生类无法隐藏它而不告警））。
2. **步骤被外部调用**（现象：客户直接调 `chess.take_turn(2)` 绕过剧本；原因：步骤放 public；后果：流程约束失效。对策：全部步骤 protected（本例如此），public 只留 run）。
3. **钩子默认值带副作用**（现象：默认 hook() 里写了"清缓存"；原因：把隐含行为塞进默认实现；后果：不写钩子的子类被悄悄动了状态，排查极难。对策：钩子默认 = 纯空操作；有公共副作用就提升为步骤写进骨架）。
4. **步骤间通过成员变量隐式通信**（现象：initialize 写成员、take_turn 读成员，步骤耦合在基类的私有字段上；原因：把模板方法写成了基类的"过程式程序"；后果：子类改动一个步骤全局崩塌。对策：步骤间用返回值显式传递（本例 run 用 `out` 串接各步返回值），基类字段只放真正的共享配置）。
5. **CRTP 派生类用基类指针持有**（现象：`GameCRTP<Chess>* p = &chess;` 期望多态；原因：CRTP 不是运行期多态；后果：通过基类指针调不到派生类步骤。对策：CRTP 版不设基类指针接口；需要运行期多态就回到虚函数版——两种形态别混搭）。

## 三书对应

- 之禅：第 10 章"模板方法模式"（10.1 辉煌工程——悍马 H1/H2 车模的发动→行驶→鸣笛剧本、10.2 定义、10.3 应用、10.4 扩展——钩子方法的正式登场：悍马"是否要鸣笛"由钩子控制，正是本章 Chess/Go 钩子的原形）。
- 刘伟：第 26 章"模板方法模式"（26.1 动机与定义、26.2 结构与分析、26.3 实例——银行业务办理流程（26.3.1）/数据库操作模板（26.3.2）、26.4 效果与应用、26.5 扩展——钩子方法的使用与模板方法在框架中的应用）。
- GoF：第 5 章 5.10 节 Template Method——Application/Document 例（绘图应用/电子表格应用继承 OpenDocument 的打开→读入→处理流程），"实现"节讨论"使用 C++ 访问控制（原语操作定义为保护成员、模板方法定义为非虚成员函数——本章 run() 非虚 + 步骤 protected 的出处）、尽量减少原语操作的个数、命名约定（应重定义的操作加前缀 DoXxx 的惯例）"。

*可选延伸：可运行示例见 examples/27_templatemethod/。*
