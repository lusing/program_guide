# 15 · 外观

迪米特法则（第 4 章）说"只和直接朋友说话"。可现实里一个功能往往要跟五六个零件说话——外观模式就是给迪米特法则补的台阶：**把"跟一堆零件说话"封装成"跟一个门面说话"**。GoF 4.5 节的定义：**为子系统中的一组接口提供一个一致的界面，定义一个高层接口，这个接口使得这一子系统更加容易使用**。

## 意图与动机

编译器是最经典的例子：词法分析器、语法分析器、代码生成器，三个零件每个都自成一体。调用方想做一次编译，得自己懂"先词法后语法再生成"的顺序、零件间怎么传数据、哪个先构造——**调用方被迫成了子系统的专家**。每多一个调用方，这套流程知识就多一份拷贝；子系统内部重排零件（比如加一个优化器插在中间），所有调用方跟着改。

外观的解法：一个 `Compiler` 类，把三个零件装进去，暴露一个 `compile(src)`。调用方只见门面；零件间的顺序、装配、传递全部内化。

## 经典写法：编译器门面

示例 `facade.hpp`。子系统三零件——它们各自能独立用，互相知之甚少：

```cpp
// ---- 子系统三零件：各自能独立用，彼此知之甚少 ----
struct Lexer {
    // 按空格切词（教学简化）：tokens 个数决定了后续的 parse/emit 行为
    [[nodiscard]] std::vector<std::string> tokenize(std::string_view src) const {
        std::vector<std::string> out;
        /* 逐词切分…… */
        return out;
    }
};

struct Parser {
    // 教学版：节点数 = 语句数（以 ';' 计）
    [[nodiscard]] size_t parse(std::span<const std::string> tokens) const { /*…*/ }
};

struct CodeGen {
    [[nodiscard]] std::string emit(size_t nodes) const {
        return std::format("code for {} nodes", nodes);
    }
};
```

门面本体：

```cpp
class Compiler {
public:
    [[nodiscard]] std::string compile(std::string_view src) const {
        auto tokens = lex_.tokenize(src);          // 第 1 步
        size_t nodes = par_.parse(tokens);         // 第 2 步
        return std::format("tokens:{} nodes:{} {}", tokens.size(), nodes,
                           gen_.emit(nodes));      // 第 3 步 + 汇总
    }
private:
    Lexer lex_;
    Parser par_;
    CodeGen gen_;
};
```

三个要点：

1. **门面"有一个"零件而不是"是一个"零件**——纯组合，`private` 成员。子系统对外完全隐藏：外界连 `Lexer` 的头文件都可以不碰（真实工程里门面 .cpp 里 include 零件头，门面 .h 只暴露自己）。
2. **门面知道流程，零件不知道门面**。依赖方向是单向的：`Compiler` 认识三个零件，零件互不认识、更不认识 Compiler——子系统保持"可以脱离门面独立使用"的尊严（GoF 强调这一点：Facade 不封死子系统）。
3. **`compile` 是 const 的**：门面无状态（或者只有缓存类状态），流程知识全在代码结构里。这让门面天然线程安全（无共享可变状态）。

运行输出——先独立用零件，再走门面：

```text
零件: Lexer 独立产出 5 个词
零件: Parser 独立解析出 1 个节点
零件: CodeGen 独立产出 "code for 1 nodes"
门面: compile -> tokens:5 nodes:1 code for 1 nodes
门面: compile -> tokens:10 nodes:2 code for 2 nodes
```

断言验证 `"int x = 1 ;"` 切出 5 个词、解析出 1 个节点，门面输出含 `"tokens:5"` 与 `"nodes:1"`——零件行为与门面串联结果一致，说明门面只是"接线"，没有偷偷改行为。最后一行：换个输入（两句代码），同一个门面直接工作——**流程知识写一次，处处复用**。

## 模式结构（ASCII 类图）

```text
   调用方 ──compile(src)──> ┌────────────┐
                            │  Compiler  │  Facade
                            └─┬────┬────┬┘
                          ┌───┘    │    └───┐
                          ▼        ▼        ▼
                      ┌───────┐ ┌───────┐ ┌────────┐
                      │ Lexer │ │Parser │ │ CodeGen│   子系统零件
                      └───────┘ └───────┘ └────────┘
                        （零件之间不互知，也可被高级用户直用）
```

GoF 的参与者表简单到只有两个角色：Facade、子系统类（subsystem classes）。它是 23 个模式里结构最简单的一个——简单到有人不承认它是"模式"，只是"好品味"。但 GoF 收编它有两个理由：**降复杂度的方向是普遍的**（任何超过三个零件的子系统都需要门面），以及**门面与适配器/代理/中介者的边界需要认真划**（见下）。

## 现代视角：门面的三种 C++ 形态

GoF 时代门面是一个类；C++ 里"一个统一入口"至少有三种载体，按场景选：

```cpp
// ① 类门面（本章示例）：有状态/有生命周期时首选
Compiler compiler;
auto r = compiler.compile(src);

// ② 函数门面：流程固定、零件无状态时最轻
inline std::string compile(std::string_view src) {
    auto tokens = Lexer{}.tokenize(src);
    return std::format("tokens:{} nodes:{}", tokens.size(),
                       Parser{}.parse(tokens));
}

// ③ namespace 门面：一组相关操作共用一套子系统零件
namespace compile_facade {
    std::string to_bytecode(std::string_view src);   // 内部共用 Compiler
    size_t count_nodes(std::string_view src);
}
```

①→②→③ 是"门面重量"的递减：类门面可以持有可配置的零件（`Compiler` 构造时注入不同的 CodeGen），函数门面零状态零配置，namespace 门面是一组共享后端的入口集合。判据：**子系统需要配置/状态 → 类；流程固定无状态 → 函数；多个入口共享子系统 → namespace**。多数真实代码的"模块公共头文件"其实就是 namespace 门面——这个模式大到架构（分层 API）、小到一个头文件。

## 外观与近亲模式的边界

四个模式都"包一层"，分界靠两个问题：包的是**谁**、为的是**什么**：

| 模式 | 内层是什么 | 目的 | 内层知道外层吗 |
|---|---|---|---|
| 外观 | 一堆**零件**（不同类型） | 简化使用、收拢流程 | 不知道 |
| 适配器 | **一个**已存在的类 | 接口转换 | 不知道 |
| 代理 | **一个**同接口本体 | 控制访问 | 概念上同接口 |
| 中介者（第 22 章） | 一堆**互相要通信**的同事 | 网状通信改星型 | 同事**认识**中介者 |

外观与中介者的区分最值钱：外观是**单向广播**（调用方→子系统，子系统不知道自己被谁包着），中介者是**双向枢纽**（同事之间通过中介者互发消息，中介者是系统里的活跃成员）。子系统的零件"只是干活"用外观；零件们"需要协作"才轮到中介者。之禅 33.2 节专门 PK 过这对。

## 刘伟 14.3 的文件加密模块：门面的标准姿势

刘伟给外观配的实例是"文件加密模块"——把它按 C++ 形态重画，结构非常典型：

```text
子系统三零件：
  FileReader    ::read(path) -> vector<char>     （读原始文件）
  CipherMachine ::encrypt(span<const char>) -> vector<char>  （加密变换）
  FileWriter    ::write(path, span<const char>)  （写目标文件）

Facade（EncryptFacade）：
  encrypt_file(src, dst) {
      auto raw    = reader_.read(src);      // 1 读
      auto cipher = cipher_.encrypt(raw);   // 2 加密
      writer_.write(dst, cipher);           // 3 写
  }
```

这个例子的教学价值在于它显示了门面最典型的诞生方式：**零件是既有代码**（FileReader 可能来自旧系统，CipherMachine 可能是算法组给的库），新需求（"给一批文件加密"）按理说写三行调用就行——但当十几个调用方都要重复这三行时，"流程知识"就该收拢了。门面不是把三行代码藏起来的花招，是**把三行代码的知识从 N 个调用点集中到 1 个装配点**。与第 5 章简单工厂对比：简单工厂收拢的是"构造知识"，门面收拢的是"流程知识"——两者常常出现在同一个模块里（门面的构造函数里就住着一个简单工厂）。

## 分层 API：门面在架构里的放大形态

把"门面只暴露高频入口、子系统保留直通"这条纪律放大到架构级，就是**分层 API** 的原型：

```text
应用代码 ──────────── 只 include  "lib/public_api.hpp"        （门面层）
                         │
高级用户/框架代码 ────── 也可 include "lib/detail/lexer.hpp" 等   （直通层）
```

规则三条：门面层稳定（对外承诺 ABI 与语义）、detail 层变动自由（版本升级随便重构）、跨层 include 允许但要写进文档。C++ 生态里的现成例子：`std::filesystem` 是对平台 API 的门面；`std::format` 是对一整套格式化解析零件的门面；任何 SDK 的 "core header + detail/ 目录" 都是这个结构。GoF 在"实现"节末尾说的"公共与私有子系统的划分"，1985 年到今天没有变过——变的只是 C++ 用 `impl/` 目录、`detail` 命名空间和 pImpl（第 12 章）把这些边界工程化得越来越硬。

## 门面的错误策略：谁向调用方交账

三个零件都可能失败（文件读不到、词法非法、生成失败），门面必须决定错误通道——这是 GoF 没细讲、C++ 里必须回答的问题。本章示例全部走"不会失败"的教学假设，真实设计按第 1 章约定拆两条：

```cpp
// 门面的错误策略：零件的可预期失败 → 汇总成 expected；编程错误 → throw
std::expected<std::string, std::string> compile_checked(std::string_view src) const {
    if (src.empty())
        return std::unexpected("空源码");           // 门面级前置校验
    auto tokens = lex_.tokenize(src);
    if (tokens.empty())
        return std::unexpected("无有效词法单元");    // 零件失败上浮
    size_t nodes = par_.parse(tokens);
    return std::format("tokens:{} nodes:{}", tokens.size(), nodes);
}
```

两条纪律：**错误在门面处统一换算**——零件抛的异常、返回的错误码，门面把它们翻译成调用方视角的 `expected`，调用方只学一种错误处理（这正是"简化使用"在错误维度的延续）；**零件间失败的中间清理由门面负责**——第 2 步失败时第 1 步可能已产生临时资源，RAII 让这条纪律基本免费（零件都持智能指针就自动成立）。反模式是让零件的错误直接穿透到调用方：调用方被迫理解三个零件各自的错误语义——门面白做了。

## 陷阱清单

1. **门面变成上帝类**（现象：Compiler 里长出 parse_statement、optimize_loop 等几十个方法；原因：所有新需求都往门面上加；后果：门面重新变成"必须理解的复杂系统"。对策：门面只放"高频简单入口"；复杂操作走直通接口——门面与子系统并存，GoF 原话"不需要把子系统所有功能都通过门面"）。
2. **门面里塞业务逻辑**（现象：`compile` 里做了"源码去注释"的业务换算；原因：门面是最顺手的地方；后果：零件单独使用时行为不一致，门面成为唯一"知道真相"的地方。对策：门面只做装配与转发；业务逻辑下沉到零件或独立类）。
3. **完全屏蔽子系统**（现象：为"干净"把零件全设 private，连头文件都不发布；原因：洁癖；后果：高级用户要的能力给不出来，被迫 hack。对策：发布门面 + 保留子系统公共接口（分头文件或 internal 目录），GoF 明确支持这个做法）。
4. **门面持有全局可变状态**（现象：Compiler 里 static 统计全局编译次数并影响行为；原因：图方便；后果：测试串扰、并发受限。对策：门面尽量无状态；确需缓存放实例成员并文档化）。
5. **一层门面套一层门面**（现象：FacadeA 包 FacadeB 包 FacadeC；原因：分层分过头；后果：一次调用穿透 N 层转发，调试深洞。对策：每个门面对应一个**子系统边界**，不是每个模块都得有门面）。

## 收尾定位：门面是"复杂度的搬运工"

本章结构最简单、也最容易被低估。把定位说透：门面**不消除复杂度**——词法、语法、生成的复杂度原样存在——它把复杂度**从每个调用方搬运到一个地方**。搬运本身有收益（N 份流程知识变 1 份）也有成本（多一层间接、多一个类）；判据是搬运比例：调用方 ≥3、流程 ≥2 步，搬运稳赚；一个调用方一步流程，门面就是空转。这个视角也解释了为什么"好品味"的代码里门面无处不在——它们不是模式爱好者画上去的，是重复出现的流程知识自己"长"出来的：第三个人第三次抄那三行编译调用时，Compiler 类就该诞生了。

## 三书对应

- 之禅：第 23 章"门面模式"（23.2 定义、23.3 应用——基金与股票的例子：买基金=把选股交给基金经理，23.4 注意事项、23.5 最佳实践），另第 5 章迪米特法则与第 33 章 33.2 节"门面 VS 中介者"联动阅读。
- 刘伟：第 14 章"外观模式"（14.1 动机与定义、14.2 结构与分析、14.3 实例——文件加密模块、14.4 效果与应用、14.5 扩展——抽象外观类/多外观粒度）。
- GoF：第 4 章 4.5 节 Facade——Compiler 例（本章同款），"实现"节讨论"降低客户-子系统耦合（抽象外观类）、公共与私有子系统的划分"，GoF 明确写了"Facade 类往往需要成为 public 类，而子系统类保持 internal"——正是现代分层 API 的原型。

*可选延伸：可运行示例见 examples/15_facade/。*

---

上一章：[14 装饰器](14-decorator.md) · 下一章：[16 享元](16-flyweight.md)
