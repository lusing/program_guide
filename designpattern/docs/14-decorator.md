# 14 · 装饰

装饰模式回答的问题：**怎么给一个对象加功能，又不把每一种功能组合都写成子类**。GoF 4.4 节的定义：**动态地给一个对象添加一些额外的职责。就增加功能来说，装饰模式比生成子类更为灵活**。

## 意图与动机

继承加功能的算术题：文本流要"转大写"、"加时间戳"、"加校验和"三种可选功能，两两组合是 2³=8 种子类（再加一种功能翻倍到 16）。这是组合爆炸的第二种形态（桥接解决的是"两维正交"，装饰解决的是"多层可叠"）。更麻烦的是**运行期**需求：日志处理器按配置决定"要不要大写、要不要时间戳"，继承版在编译期就焊死了组合，配置一变就得改代码。

装饰的解法：**每一层装饰是一个"实现了同一接口、内持一个同接口对象"的包装**。请求从最外层进，每层做完自己的事转发给内层——像洋葱，也像函数组合。功能是"层"，不是"子类"；层可以运行期随意叠、随意换。

## 经典写法：文本流洋葱

示例 `decorator.hpp`。原件与装饰骨架：

```cpp
// Component：被装饰对象的统一接口。
struct Stream {
    virtual ~Stream() = default;
    [[nodiscard]] virtual std::string write(std::string_view s) const = 0;
};

// ConcreteComponent：没有任何装饰的原件。
struct PlainStream final : Stream {
    [[nodiscard]] std::string write(std::string_view s) const override {
        return std::string{s};
    }
};

// 装饰层：转发内层 + 附加职责。
class UpperDecorator final : public Stream {
public:
    explicit UpperDecorator(const Stream& inner) : inner_(&inner) {}
    [[nodiscard]] std::string write(std::string_view s) const override {
        std::string in = inner_->write(s);    // 装饰 = 先转发内层，再附加职责
        std::string out;
        out.reserve(in.size());
        for (char c : in) out += static_cast<char>(c >= 'a' && c <= 'z' ? c - 32 : c);
        return out;
    }
private:
    const Stream* inner_;
};

class TimestampDecorator final : public Stream {
public:
    explicit TimestampDecorator(const Stream& inner) : inner_(&inner) {}
    // 静态递增计数代替 chrono：输出确定性（本书约定）
    [[nodiscard]] std::string write(std::string_view s) const override {
        return std::format("[T{}]{}", seq_++, inner_->write(s));
    }
private:
    const Stream* inner_;
    inline static int seq_ = 0;
};
```

三个要点：

1. **装饰器"是一个 Stream"且"有一个 Stream"**——两个关系同时成立。`is-a`（继承 Stream）让它能与原件互换、能套在别的装饰外面；`has-a`（持 inner_）让它把工作下推。这两个关系的组合正是装饰的全部结构，GoF 称 Decorator 为"包装结构"的样板。
2. **"转发内层 + 附加职责"的顺序决定语义**。`UpperDecorator` 先转发再变换（作用在最终文本上），`TimestampDecorator` 先加时间戳再转发（时间戳在最前面，不会被内层动过）。写装饰层时必须想清楚自己是"前置加工"还是"后置加工"——这是装饰链语义的核心。
3. **`inline static int seq_` 换掉 chrono**：教学示例要输出可预测（本书第 1 章约定），`[T0]`、`[T1]` 递增计数器代替真实时间戳。真实工程里这里是时间或计数 ID，模式结构不变。

组装与运行：

```cpp
PlainStream plain;
UpperDecorator upper(plain);
TimestampDecorator ts(upper);       // 洋葱：最外层 Timestamp，向内 Upper、Plain
ts.write("hi");                     // -> "[T0]HI"
```

运行输出：

```text
装饰: Upper("hi") -> HI
装饰: [T0]HI 然后 [T1]HI
顺序: Timestamp(Upper(x))=[T3]DONE 与 Upper(Timestamp(x)) 不同链不同果
多态: Stream& 不区分原件与三层装饰
```

第二行验证计数确定递增（两次调用 T0、T1）；第三行验证**顺序敏感性**——`Timestamp(Upper(x))` 与 `Upper(Timestamp(x))` 产出不同的时间戳位置，洋葱从外到内的每一层都真实起作用；第四行验证多态消费：`Stream&` 拿到手分不清是原件还是三层洋葱——**这正是"对单个对象和装饰后对象使用一致"的含义**。

## 模式结构（ASCII 类图）

```text
        Stream（Component 接口）
        ├── PlainStream          （原件）
        ├── UpperDecorator ──inner_──> Stream（指向任意内层）
        └── TimestampDecorator ──inner_──> Stream

  装饰链：Timestamp(Upper(Plain))  ——请求从外向内穿过每层
  新功能 = 新装饰类；组合 = 叠层；数量 O(功能数)，不是 O(2^功能数)。
```

## 现代写法：模板 policy 链

运行期洋葱换来的是每次调用一层虚跳转。如果装饰组合**编译期已知**，C++ 模板能把洋葱压成零开销（`decorator.hpp` 未收录、正文讲解用）：

```cpp
// policy 链：T 依次包装，编译期展开成嵌套调用——无虚表、可内联
template <typename... Policies>
struct DecoratorChain;

template <typename Head, typename... Tail>
struct DecoratorChain<Head, Tail...> {
    template <typename Inner>
    static std::string apply(const Inner& inner, std::string_view s) {
        return Head::process(DecoratorChain<Tail...>::apply(inner, s), ...);
    }
};
```

这个方向的完整形态是第 24 章策略模式的模板版——装饰的 policy 链本质是**编译期策略组合**。更常用、更简单的一招：**自由函数组合**。装饰要的只是"变换"，多数文本加工直接写函数：

```cpp
auto upper  = [](std::string s) { for (auto& c : s) c = toupper((unsigned char)c); return s; };
auto stamp  = [n = 0](std::string s) mutable { return std::format("[T{}]{}", n++, s); };

auto processed = stamp(upper(plain.write("hi")));   // 函数洋葱，效果相同
```

lambda 嵌套调用与装饰器结构同构——**装饰模式是"函数组合"的 OOP 化身**。什么时候仍要装饰类？当"层"有**状态**（计数、缓存、限流器）且要**以接口身份**塞进只认 `Stream` 的框架扩展点时。lambda 组合管不到框架边界。

## 两版取舍

| 维度 | 装饰类（运行期洋葱） | lambda/模板组合（编译期） |
|---|---|---|
| 组合时机 | 运行期（读配置拼链） | 编译期（写死在代码里） |
| 有状态的层 | 天然（成员变量） | lambda 捕获（生命周期要小心） |
| 开销 | N 次虚调用 | 零（可内联） |
| 框架接口适配 | 天然（is-a Component） | 不行（没有共同接口） |
| 调试 | 断点逐层清晰 | 调用栈折叠 |

## 代理与装饰：一层之隔

之禅 31.1 节专门 PK 这两个模式——结构图几乎一样（都"实现接口 + 持有同接口内层"），差别在**意图**：

| | 装饰 | 代理（第 17 章） |
|---|---|---|
| 内层怎么来 | 调用方**递进来**的（装配时决定） | 代理**自己管**的（惰性加载/远程） |
| 加的东西 | 新职责（变换、染色、加密） | 访问控制（懒、权限、引用计数） |
| 层数 | 随意叠 | 通常一层 |
| 对外承诺 | "我能做得更多" | "我和本体一样，只是隔了一道" |

同一份代码，"内层是别人给我的"就是装饰，"内层是我按需创建的"就是代理。记住这句，第 17 章回来对照。

## 完整示例：加密装饰层

把装饰用到"真业务"上——给任何 Stream 加一层加密（教学版用确定性 XOR）：

```cpp
class XorDecorator final : public Stream {
public:
    explicit XorDecorator(const Stream& inner, char key) : inner_(&inner), key_(key) {}
    [[nodiscard]] std::string write(std::string_view s) const override {
        std::string raw = inner_->write(s);           // 先拿内层结果
        std::string out;
        out.reserve(raw.size());
        for (char c : raw) out += static_cast<char>(c ^ key_);   // 再加密
        return out;
    }
private:
    const Stream* inner_;
    char key_;
};

// 组合：加密放在时间戳之后（时间戳内容不加密）
XorDecorator secure(ts, 'k');
secure.write("hi");    // -> [T0]HI 各字节 ^ 'k'
```

这段代码展示装饰在真实系统里的标准位置：**横切关注点**（加密、压缩、日志、限流）做成装饰层，业务流（PlainStream）保持纯净。加密/压缩/日志都是"对通过内容做加工"，与 Stream 的语义完全同构——装饰模式的甜点区。标准库的 `std::iostream` 是这层思想的最大用户：`fstream` 套 `buffered stream` 套 `codecvt`，层层包装的就是这个结构（虽然实现细节不同）。

## 装饰与责任链：都"层层传递"，方向相反

结构相似的另一个近亲是第 19 章责任链：请求都从链头进、逐级传递。三点分界：

1. **方向**：装饰是"从外向内穿、再从内向外返"（每层都处理、结果回传组装）；责任链是"从前往后找、找到就停"（每层决定处理或甩锅，通常不回传）。
2. **契约**：装饰的每一层**必须**转发（不转发就是陷阱 1）；责任链的每一层**可以**不转发（"我不处理"是合法行为）。
3. **结构保证**：装饰层的类型系统保证接口一致（都是 Stream）；责任链靠链表/数组组织，顺序与终止条件是运行期约定。

选型判据：请求要**经过每个人的加工**（文本变换、加密压缩）用装饰；请求要**被其中一个人处理**（审批、日志分级分发）用责任链。之禅 31 节的 PK 里没提责任链，但这三个分界把三个"包装类"模式（装饰/代理/责任链）一次分清。

## 陷阱清单

1. **装饰层吞掉请求**（现象：某层 `write` 忘了转发内层；原因：复制粘贴装饰骨架；后果：链后面的所有功能失效，输出看起来"正常"但少了处理。对策：每个装饰类的 write 必须出现 `inner_->`，review 时专查这一行）。
2. **顺序想当然**（现象：以为 `Upper(Timestamp(x))` 和 `Timestamp(Upper(x))` 等价；原因：把装饰当加法；后果：时间戳被大写化、编码后的内容被再编码——功能错乱。对策：装饰链是**从外到内的管道**，文档里画出顺序）。
3. **装饰持有原件值拷贝**（现象：`PlainStream inner_` 而不是引用/指针；原因：所有权想省事；后果：原件状态被复制，装饰后的行为与原件当前状态脱节。对策：装饰持引用（不拥有，装配点管生命周期）或 `shared_ptr`（共享）——**值拷贝在两种情况外都意味着 bug**）。
4. **静态计数/共享状态跨测试泄漏**（现象：`inline static int seq_` 在两个测试间不归零，T5、T6 跑出意料外值；原因：static 生命周期全局；后果：测试顺序敏感。对策：计数器做成实例成员或提供 reset 钩子；教学示例为了确定性才用 static，真实代码慎用）。
5. **为单一功能上装饰**（现象：只有一个装饰类、永远一层；原因：模式先行；后果：三层结构（Component/Decorator/Concrete）服务一个 if 能解决的问题。对策：一个附加功能，直接写成"包装函数"或子类即可，装饰的价值在**多功能的自由组合**）。

## 动态装配：洋葱在运行期怎么拼

本章示例的洋葱是代码写死的（`TimestampDecorator ts(upper)`）。装饰的"运行期灵活性"体现在**按配置拼链**：

```cpp
// 按配置组装装饰链：配置说开哪几层就套哪几层
const Stream* make_chain(const PlainStream& plain, bool want_upper, bool want_ts) {
    const Stream* head = &plain;
    if (want_upper) head = &uppers_.emplace_back(*head);   // 存进成员容器保命
    if (want_ts)    head = &tss_.emplace_back(*head);
    return head;
}
```

这段代码藏着动态装配的最大坑——**生命周期**：装饰持内层引用，装配链上的中间层必须有归宿（示例把它们塞进成员容器），放局部变量就是悬垂。这正是"装饰链由装配点统一管理生命周期"约定的由来，也是为什么多数框架（日志库的 filter 链、网络库的中间件）用**值语义或所有权链**（每层 `unique_ptr<Inner>`）而不是裸引用——装配自由度上去了，内存模型交给智能指针。

## 三书对应

- 之禅：第 17 章"装饰模式"（17.2 定义、17.3 应用——成绩单排名的例子、17.4 最佳实践），第 31 章 31.1 节"代理 VS 装饰"与 31.2 节"装饰 VS 适配器"是全书最清晰的三模式辨析。
- 刘伟：第 13 章"装饰模式"（13.1 动机与定义——变形金刚的引入、13.2 结构与分析——含抽象装饰类与具体装饰类的层次讨论、13.3 实例——加密/过滤的图形界面构件、13.4 效果与应用、13.5 扩展——透明装饰与半透明装饰）。
- GoF：第 4 章 4.4 节 Decorator——VisualComponent/Border/ScrollDecorator 例（窗口滚动+边框的叠加演示），"实现"节讨论"接口一致性、省略抽象装饰类、Component 该多轻"。

*可选延伸：可运行示例见 examples/14_decorator/。*
