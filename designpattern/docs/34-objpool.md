# 34 · 对象池实战：借出、归还、上限

第 16 章享元解决"对象太多"的办法是**共享不可变**——内部状态一致的对象共用一份。对象池处理另一半问题：**可变但昂贵**的对象（数据库连接、线程、大缓冲）不能共享，但可以**复用**——用完还回来，下一个使用者拿同一份。池的核心业务只有三件事：借出（acquire）、归还（release）、上限（拒绝还是排队）。本章把这三件事写全，再把 RAII 守卫加上——**池负责复用，守卫负责归还**，两件事分给两个角色，异常路径才不会漏。

## 意图与动机

一个进程要频繁连数据库：TCP 握手 + 认证几十毫秒，业务逻辑只用几毫秒——每次新建连接就是把 99% 的时间花在建设上。对象池的思路朴素：**建一次，反复借**。但朴素思路藏着三个必须显式决定的合同：借出去的对象怎么保证"还回来"（忘了还 = 池枯竭）；池满了怎么办（新建无上限池就白建了）；**复用的对象带不带上一个使用者的残留**（连接上的事务没回滚，下一个借主就遭殃）。本章示例把三个决定都做成可断言的行为：RAII 守卫保证归还、上限 4 触发异常、reset 归还合同写明。

## 经典写法：单例池 + RAII 守卫

示例 `pool.hpp`。池中对象与池：

```cpp
// 池中对象：id 唯一且永不变（创建序号），used_ 只有 Pool 能碰。
class Conn {
public:
    explicit Conn(int id) : id_(id) {}
    int id() const { return id_; }
    bool in_use() const { return used_; }
private:
    friend class Pool;               // 池是唯一有权改 used_ 的角色
    void acquire() { used_ = true; }
    void release() { used_ = false; }
    int id_;
    bool used_ = false;
};

class Pool {
public:
    static Pool& instance() { static Pool p; return p; }   // Meyers 单例：首次调用即构造

    Conn& acquire() {
        for (auto& c : pool_)
            if (!c.used_) { c.acquire(); return c; }      // 复用空闲：created 不涨
        if (pool_.size() >= kLimit) throw std::runtime_error("pool exhausted");
        pool_.emplace_back(static_cast<int>(created_));
        Conn& c = pool_.back();
        c.acquire();
        ++created_;                                        // 只有新建才涨 created
        return c;
    }

    void release(Conn& c) { c.release(); }
    std::size_t created() const { return created_; }
    std::size_t in_use_count() const { /* 数 used_ */ }
private:
    Pool() { pool_.reserve(kLimit); }   // 上限预留：acquire 返回的引用不会因扩容失效
    static constexpr std::size_t kLimit = 4;
    std::vector<Conn> pool_;
    std::size_t created_ = 0;
};
```

三个实现决定各有一条踩坑史。**friend class Pool**：used_ 是池的私有账本，客户只能读不能改——若把 acquire/release 公开，客户可以绕过池直接改状态，账本就废了。**reserve(kLimit)**：acquire 返回 `Conn&`，vector 扩容会搬家、引用全悬空——池有固定上限，构造时一次预留到位，引用稳定性靠"容量永不增长"保证（这是池相对通用容器的特权）。**created 与 in_use 分离**：created 记"历史上建了几个"（复用不涨），in_use_count 记"现在借出去几个"——两个数一混，"复用是否生效"就测不出来了。RAII 守卫：

```cpp
// RAII 守卫：构造即借、析构即还——异常路径也归还，与第 32 章订阅句柄同一手法。
class Connection {
public:
    explicit Connection(Pool& p) : pool_(p), conn_(p.acquire()) {}
    ~Connection() { pool_.release(conn_); }
    Connection(const Connection&) = delete;             // 一借一还，拷贝即双重归还
    Connection& operator=(const Connection&) = delete;
    Conn& get() { return conn_; }
private:
    Pool& pool_;
    Conn& conn_;
};
```

运行侧（`main.cpp`）四段断言：

```cpp
Conn& a = pool.acquire();
Conn& b = pool.acquire();
assert(a.id() != b.id());             // 不同借主不同 id
assert(pool.created() == 2);

pool.release(a);
Conn& c = pool.acquire();
assert(c.id() == a.id());             // 复用：同一 id 回来了
assert(pool.created() == 2);          // created 不虚增

int caught = 0;
try { pool.acquire(); }               // 池满 4 个：抛
catch (const std::runtime_error&) { ++caught; }
assert(caught == 1);

{   Connection g(pool);
    assert(pool.in_use_count() == 1); }   // 作用域结束自动归还
assert(pool.in_use_count() == 0);
```

异常路径的守卫测试（main 后段）：作用域里 throw，catch 后 `in_use_count() == 0`——**栈展开执行守卫析构**，归还义务被 RAII 从"程序员的记性"移交给了"语言的作用域规则"。运行输出：

```text
借出线: 两次 acquire 得两个不同 id，created=2
复用线: 归还后 acquire 拿回同一 id，created 仍为 2
上限线: 第 5 个 acquire 抛 runtime_error，caught=1
RAII 线: 正常与异常两条路径 in_use 都归零
自检通过
```

## 模式结构（借还生命周期）

```text
   客户 ──acquire()──> Pool ──复用空闲 / 超限抛 / 新建──> Conn&（used_=true）
   客户 ──Connection 守卫构造──借──┐
   ...使用...                      │
   作用域结束/异常 ──~Connection──> Pool.release(conn)（used_=false）

   created（历史新建数）≠ in_use_count（当前借出数）
   复用生效 = release 后 acquire 拿回同 id 且 created 不变
```

## 现代讨论：池满了之后——拒绝、等待还是排队

本例池满**抛异常**，是三种策略里最激进的一种，选它是因为合同最清晰：调用方被迫立刻面对"池资源耗尽"。另外两种各有位置：**阻塞等待**（借不到就等别人还）把背压交给池，调用方代码干净，但要处理超时与虚假唤醒（条件变量 + 仿函数谓词），并且死锁风险上升（两个线程各持一半等待对方归还）；**返回空/optional** 把决定权推回调用方，测试友好但调用方处处要判空。判据看**耗尽是异常还是常态**：突发流量下耗尽是常态 → 排队；耗尽意味着 bug（泄漏了连接）→ 抛异常让它在第一次发生时炸响——本例的定位正是后者，池耗尽在健康的系统里就该是异常事件。

## 什么时候别用对象池

池本身有成本，三种情况不值得：**对象不贵**——new 一个 int 或小结构纳秒级，池的加锁/查找/归还开销可能比省下的还多；**复用带语义风险**——对象有复杂内部状态（缓存、游标、事务），每个借主都要"猜"上一个借主留了什么，reset 义务收不拢时，池从优化变成 bug 温床；**单线程小规模**——池的价值在"昂贵 + 高频"，两个条件缺一个，直接 new 就是正解。另一个常见误区：**池不是缓存**——池里的对象无差别（借哪个都行），缓存按 key 存有差别的内容；把池写成 map<key, 对象> 的那一刻，需求其实已经变成了缓存。

## 守卫手法的谱系：从订阅句柄到连接守卫

第 32 章的 Subscription 句柄与本章的 Connection 守卫是同一手法的两个应用，值得并排看清"骨架不变、义务可换"：构造函数里做**借出**（subscribe / acquire）、析构函数里做**归还**（unsubscribe / release）、拷贝一律删除（id 唯一 / 一借一还）、可移动与否看资源语义（订阅句柄可移动、连接守卫本例不可移——移动连接会引入"两个守卫还同一个连接"的歧义）。这对手法可推广到一切"成对义务"：锁的 lock_guard、文件的打开关闭、事务的 begin/commit——RAII 的本质是把**配对义务折叠进作用域**。写新守卫时的三件套检查：析构只做归还不做其他（异常路径上析构必须安全）；拷贝语义想清楚（禁拷贝最省心）；异常构造（acquire 抛出时守卫没出生，析构不会跑——正确，因为没借到就不用还）。第三条常被忽略：守卫的构造函数若在 acquire 之后、赋成员之前抛出，C++ 保证已构造成员的析构会执行——成员声明顺序决定清理顺序，守卫类里成员越少越安全。

## 本章示例的断言面

main.cpp 四段断言对应的合同条款：

- 不同借主不同 id（比较不相等，不打印值）+ created 精确计数——"新建"的定义；
- release 后 acquire 拿回同一 id 且 created 不变——复用的定义；
- 第 5 次 acquire 抛 runtime_error 且 in_use 不受影响——拒绝合同；
- 正常作用域与 throw 两条路径之后 in_use_count() 都归零——RAII 合同的正反两面。

四个合同合起来正好是池的全部承诺：复用、记账、拒绝、归还。任何一项被实现变更打破，main 都会变红。

## 池的四个参数化旋钮

生产级池在"借/还/上限"之外还有四个可调维度，设计时显式决定比事后翻新便宜：

- **预热**：构造时预建 N 个对象（首个借主不等首次握手）——本例 reserve 只留内存不留对象，预热是把"建"也提前；
- **上限语义**：抛（本例）/阻塞/返空——耗尽三态，"现代讨论"一节已展开；
- **健康检查**：借出前 ping 一下（连接断了重建），把"复用"从"拿回来"升级为"拿回来还能用"；
- **最大空闲**：空闲超过阈值的对象销毁收缩——池的内存占用跟负载走，跟峰值走。

四个旋钮全部不动"借出/归还"的骨架（RAII 守卫照旧），这印证了池设计的分层：**合同层（借还语义）先稳，策略层（四旋钮）后调**。教学版四旋钮全取最省档（不预热、抛、不检查、不收缩），正是"合同完备、策略从简"的样本。

## 复用手段对照：池、缓存、享元、记忆化

"重复利用"有四个长相接近的手段，选错一个就等于把需求做歪：

| 手段 | 复用什么 | 有差别吗 | 典型对象 |
|---|---|---|---|
| 对象池（本章） | 对象壳 | 无差别，借哪个都行 | 连接、线程、大缓冲 |
| 缓存 | 按 key 的计算结果 | 有 key，命中即取 | DNS、页面、查询结果 |
| 享元（16 章） | 内部状态共享 | 共享后仍要传外部状态 | 字形、树节点 |
| 记忆化（36 章） | 纯函数的计算结果 | 有 key（参数集） | 递归、查表 |

判别口诀只有一句：**借主在乎"是哪个对象"吗？**不在乎（要的是"随便一个能用的连接"）→ 池；在乎（要的是"这个 key 的结果"）→ 缓存或记忆化；在乎但要省内存（一堆相似对象）→ 享元。四个手段的混淆是代码评审里的高频话题，表放这里备查。

适合进池的对象，四条特征自查：

- **创建贵**：握手、认证、分配大块内存——省下来的比池开销多；
- **可复位**：release 时能干净地回到初始状态（或 acquire 时能重置）；
- **无差别**：任何一个实例对任何借主都等效（有身份偏好的需求是缓存）；
- **借期短**：使用窗口远短于生命周期，池的周转才有意义。

四条里缺两条以上，直接 new 更诚实——池不是默认优化，是有准入条件的复用合同。

## 陷阱清单

1. **忘记归还（泄漏式借出）**（现象：池慢慢枯竭，第 N 次抛 exhausted，但谁没还查不出来；原因：acquire/release 手动配对，异常或早退路径漏 release；后果：慢性资源死亡。对策：RAII 守卫成为唯一借出方式（本例），池直接借出裸 acquire 的用法在 code review 里禁掉）。
2. **扩容悬空引用**（现象：借出的 Conn& 在池扩容后指向搬家前的内存；原因：vector 增长重分配；后果：UB。对策：上限预留（本例 reserve(kLimit)）或换 deque/list——池的引用稳定性必须是设计决定不是运气）。
3. **复用对象残留状态**（现象：上个借主的缓冲区数据、事务、游标出现在下个借主面前；原因：release 只还了"使用权"没还"干净状态"；后果：数据串号，最难查的一类 bug。对策：release 里做 reset（合同写明"归还即复位"）或 acquire 时重置；状态重不动的对象别进池）。
4. **双重归还**（现象：两个守卫包住同一个 Conn，或手动 release 后守卫又 release 一次；原因：归还入口不唯一；后果：一个对象同时"空闲"，两个借主同时用它。对策：归还只走守卫析构一条路（本例守卫禁拷贝、一借一还），in_use 断言兜底）。
5. **单例池的测试污染**（现象：两个测试都用 Pool::instance()，前一个测试的借出残留改变后一个的行为；原因：进程级单例状态跨测试存活；后果：测试顺序依赖。对策：测试里先清场（全部 release）或给 Pool 加 reset 接口；更彻底的是 Pool 构造函数化、instance() 只是默认入口——依赖注入（第 39 章反模式专题细讲单例之害））。

## 测试法

- **created 不虚增**：归还后复用，created 计数不变——"池在复用"这一核心价值的直接断言。
- **id 回归断言**：release(a) 后 acquire 拿回 a.id()——复用的是同一个对象不是"随便一个空闲"（顺序敏感的池可能有不同合同，但本例合同要钉死）。
- **上限抛错**：try/catch 计数——拒绝合同的可观察面。
- **双路径归零**：正常作用域结束、作用域内 throw，两条路径后 in_use_count() 都为 0——RAII 合同的正反两面各测一次。
- **异常后池可用**：抛过一次 exhausted 之后，release 一个连接再 acquire 成功——拒绝不是"坏了"，池的后续行为不受影响（负例之后的状态恢复断言）。
- **created 单调性**：全程 created 只增不减、精确等于新建次数——与 in_use_count 分离，两把尺子各量各的。

## 三书对应

- 之禅：第 16 章"享元模式"（16.x 享元与对象池的关系——共享不可变 vs 复用可变，之禅在享元扩展节讨论了"连接池"正是本章形态）；另见第 8 章"单例模式"关于单例适用边界的警告（本章陷阱 5 的理论来源）。
- 刘伟：第 21 章"享元模式"21.4 节"享元模式与对象池"——明确指出对象池是享元思想在可变对象上的应用变体，并讨论了池的复用与享元的共享之别；第 22 章"外观模式"对本章"Connection 守卫 + Pool 门面"的分层有参照意义。
- GoF：第 3 章"创建型模式"讨论部分（Creational Patterns 的引言提到"对象池在某些系统中是重要的创建手段"）；5.6 Flyweight"实现"小节对"管理共享对象的生命周期"（FlyweightFactory 的池语义）——本章把"池"从享元工厂的附注升级成了主角，并把归还义务交给 RAII（GoF 时代尚无此语言设施，守卫是 C++ 的贡献）。

*可选延伸：可运行示例见 examples/34_objpool/。*

---

上一章：[33 状态机实战：一张表，两种执行](33-statemachine.md) · 下一章：[35 自注册插件框架](35-plugins.md)
