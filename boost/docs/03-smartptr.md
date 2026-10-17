# 03 · 所有权革命：smart_ptr

> 对应示例：`examples/03_smartptr/`（2 个例程：smart_ptr.cpp 四类指针合同 / sp_patterns.cpp 应用模式全家）

## 3.1 Boost 给 C++ 上的第一课

1999 年，`boost::smart_ptr` 进入 Boost。彼时 C++98 刚定型，堆对象的生死全靠 `new`/`delete` 手工配对，泄漏、悬垂、双删三大事故是每个 C++ 程序的日常。`smart_ptr` 的答案后来成了整个现代 C++ 的第一原则：

> **每个堆对象在同一时刻恰好有一个明确的所有者；所有权可以转移、可以共享，但从不模糊。**

这个库是 TR1 收编的第一批（`shared_ptr`/`weak_ptr` 2005 年进 TR1，2011 年进 C++11），也是"Boost 是标准库预备队"这个命题最响亮的证据。

所有智能指针对元素类型 `T` 只有一个共同要求：**析构函数不能抛异常**。它们都是轻量级对象，速度与原始指针相差无几，且异常安全——离开作用域（无论正常还是异常）都能正确释放。

## 3.2 族谱总览

Boost.SmartPtr 在 1.92 里的完整名单：

| 成员 | 语义 | std 对应 | 状态 |
|---|---|---|---|
| `scoped_ptr<T>` | 独占、不可拷贝**不可移动** | `unique_ptr<T>` | ✅ 已毕业，新代码用 std |
| `scoped_array<T>` | 同上，数组版 | `unique_ptr<T[]>` | ✅ 已毕业 |
| `shared_ptr<T>` | 引用计数共享 | `shared_ptr<T>` | ✅ 已毕业 |
| `shared_array<T>` | 共享数组 | `shared_ptr<T[]>`（C++17 起） | ✅ 已毕业 |
| `weak_ptr<T>` | 观察、不拥有 | `weak_ptr<T>` | ✅ 已毕业 |
| `intrusive_ptr<T>` | 计数长在对象里 | **无 std 对应** | ⭐ Boost 独有价值 |
| `make_shared` / `allocate_shared` | 一次分配构造 | `std::make_shared` | ✅ 已毕业 |
| `boost::make_unique` | 单独头文件，C++14 补课前身 | `std::make_unique` | ✅ 已毕业 |
| `enable_shared_from_this` | 对象内取自身 shared | 同名 | ✅ 已毕业 |
| `static/dynamic/const/reinterpret_pointer_cast` | 智能指针版转型 | C++17 起有 | ✅ 已毕业 |
| `intrusive_ref_counter` | 现成的侵入式计数基类 | 无 | ⭐ |
| `owner_less` | 按所有权比较（关联容器键） | `std::owner_less` | ✅ 已毕业 |
| `boost::atomic_shared_ptr` | 原子共享指针 | `std::atomic<shared_ptr>`（C++20） | ✅ 已毕业 |

**结论先行**：这个库 90% 的面积已经毕业，新代码的默认答案是 std。剩下 10% 的独有价值在 `intrusive_ptr`——以及"理解 `shared_ptr` 是怎么工作"这件事本身。

## 3.3 scoped_ptr：unique_ptr 的直系祖先

```cpp
boost::scoped_ptr<Sensor> s{new Sensor("scoped")};
// boost::scoped_ptr<Sensor> s2 = s;   // 编译错误：不可拷贝
```

`scoped_ptr` 用"不可拷贝"表达独占——这是 C++03 没有移动语义时代的杰作：既然不能转移，所有权就永远清晰。C++11 的 `unique_ptr` 在同样语义上增加了**可移动**（所有权可以交接），并加入了数组特化、自定义删除器、零开销抽象（就是裸指针大小）。

它的接口合同值得逐条过一遍（这些约定后来都被 unique_ptr 继承）：

- `operator*` / `operator->` 模仿裸指针；保存空指针时解引用是未定义行为；
- **显式 bool 转型**：`if (s)` 可用，但做函数返回值/实参必须 `static_cast<bool>(s)`（这是 C++11 给标准库定的规矩，boost 版与之一致）；
- `get()` 取原始指针给 C 接口用——但指针从此"脱离管理"，**绝不能对它 delete**，否则 scoped_ptr 析构时二次删除；
- `reset(p)` 删旧存新、`reset()` 置空；`swap()` 高效互换；
- 比较操作只有与 `nullptr` 的一种（两个 scoped_ptr 之间不可比）；
- 没有指针算术（`s++`/`std::prev(s)` 编译不过）；
- **传染性**：持有 `scoped_ptr` 成员的类自动不可拷贝。

```cpp
// scoped_ptr 片段（对应示例 smart_ptr.cpp 第 1 节）
boost::scoped_ptr<Sensor> s{new Sensor("scoped")};
if (s) std::cout << "bool 语境测试有效\n";
std::cout << (s != nullptr) << '\n';
```

运行输出（`smart_ptr.cpp`）：

```text
== 1. scoped_ptr：独占、不可拷贝（unique_ptr 的直系祖先）==
  Sensor(scoped) 构造
  name=scoped
  bool 语境测试有效
  与 nullptr 比较 = 1
  Sensor(scoped) 析构
  离开作用域后自动释放
自检通过
```

顺带一提 `make_unique` 的历史：C++11 定了 `unique_ptr` 却忘了配工厂函数，`boost::make_unique`（在**单独的头文件** `<boost/smart_ptr/make_unique.hpp>` 里，不在 `smart_ptr.hpp` 总头中）先补的课，C++14 `std::make_unique` 才跟上——同一份补课的两个学籍。

## 3.4 shared_ptr：引用计数与控制块

```cpp
boost::shared_ptr<Sensor> a = boost::make_shared<Sensor>("shared");
{
    boost::shared_ptr<Sensor> b = a;   // 计数 +1
}                                      // 计数 -1，对象还活着
```

运行输出（`smart_ptr.cpp`）：

```text
== 3. shared_ptr：引用计数共享 ==
  Sensor(shared) 构造
  a 引用计数 = 1
  拷贝后 use_count = 2
  a.unique() = 0
  b 析构后 use_count = 1
  static_cast<bool>(a) = 1
  reset 后 a 空? 1 c 仍活(计数=1)
自检通过
```

值得刻进脑子的细节：

1. **`make_shared` 把对象和控制块一次分配**。直接 `shared_ptr<T>(new T)` 是两次分配（对象一次、控制块一次），且 `f(shared_ptr<T>(new T), g())` 在实参求值顺序未指定时可能泄漏（C++17 前的著名坑）。`make_shared` 两个问题一起解决。
2. **控制块永不搬家**：拷贝/移动 `shared_ptr` 只动指针和计数，析构时最后一个持有者负责释放。
3. **计数操作是原子的**，跨线程拷贝同一个 `shared_ptr` 是安全的（`atomic_shared_ptr`/C++20 `std::atomic<shared_ptr>` 解决的是另一件事：多线程改**同一个** shared_ptr 变量）。
4. **`unique()` 比 `use_count() == 1` 更快更可靠**；`use_count()` 官方态度是"仅供调试"（个别实现里可能拿不到准确值）。
5. **`reset()` 的语义是"减计数"**：只有减到 0 才析构对象；带参版本先减后接管新指针。
6. shared_ptr 有**基本的线程安全保证**：多线程同时**读**同一个 shared_ptr 是安全的；同时写（拷贝赋值给同一个对象）需要外部同步。

## 3.5 weak_ptr：观察者模式的所有权版

`weak_ptr` 指向 `shared_ptr` 管的对象但不增加计数——两大用途：**打破循环引用**（3.8 的对照实验）与**缓存**（缓存持有 weak，对象没人用时自动失效）。

`weak_ptr` 的接口是四种指针里最小的，而且**没有** `operator*`/`operator->`——它不拥有资源，所以不给你解引用的机会。用法只有一条正路：**先 `lock()` 提升回 shared_ptr，判空，再用**。

```cpp
boost::weak_ptr<Sensor> w = a;          // 不增加计数
if (boost::shared_ptr<Sensor> locked = w.lock()) { ... }
```

运行输出（`smart_ptr.cpp`）：

```text
== 4. weak_ptr：观察不拥有（打破循环/缓存）==
  expired() = false empty() = false
  lock 成功: shared
  Sensor(shared) 析构
  释放最后一个 shared 后 expired() = true lock 得空指针 = true
自检通过
```

`expired()` 等价于 `use_count() == 0` 但更快；`empty()` 判断的是"weak_ptr 自己是否指着某个控制块"（boost 特有，std 版没有）。`enable_shared_from_this` 的实现原理正是它：基类里存一个 `weak_ptr<T>`，`shared_from_this()` 就是它的 `lock()`——所以对象没被 shared_ptr 管理过时（栈对象、构造函数里）调用是未定义行为。

## 3.6 自定义删除器：管一切资源

```cpp
boost::shared_ptr<Conn> conn(new Conn{7}, [](Conn* p) {
    delete p;
    std::cout << "  连接已由删除器关闭\n";
});
```

`shared_ptr<T>` 的类型**不含删除器**（删除器存在控制块里，类型擦除）——这让它可以 heterogeneous 地装进同一个容器。删除器的要求：可拷贝、行为像 `delete`（对同一指针只调用一次）、不抛异常。把 `delete p` 换成 `fclose`、`CloseHandle`、`sqlite3_close`，就是文件/句柄/数据库连接的 RAII 管理（`sp_patterns.cpp` 里用真 `FILE*` + `fclose` 走了一遍全流程）。

删除器家族里还有两个进阶玩法（`sp_patterns.cpp` 第 3、4 节）：

- **`get_deleter<D>(sp)`**：从控制块里取出删除器（类型对得上才有），可以检查/触摸它；
- **`shared_ptr<void>` + 删除器**：`shared_ptr<void> guard(nullptr, any_func)` ——存的是空指针、善后是任意函数，析构时 `any_func` 被调用。这是"退出作用域执行任意代码"的最小 RAII 件（std::17 之前没有 `scope_exit` 时的惯用法）。`shared_ptr<void>` 本身也是个"泛型指针容器"——什么都能装，取出时用 `static_pointer_cast<T>` 转回来。

## 3.7 intrusive_ptr：Boost 的独有答案

`shared_ptr` 的计数在**控制块**里（对象外）；`intrusive_ptr` 的计数**长在对象身上**，你提供两个钩子：

```cpp
struct Node {
    std::string tag;
    int refs = 0;
};
inline void intrusive_ptr_add_ref(Node* p) { ++p->refs; }
inline void intrusive_ptr_release(Node* p) { if (--p->refs == 0) delete p; }
```

运行输出（`smart_ptr.cpp`）：

```text
== 6. intrusive_ptr：计数长在对象身上（零控制块开销）==
  refs = 1
  拷贝后 refs = 2
  add_ref=false 观察（refs 仍 = 2）
  detach 后 n2 空? true raw 仍受 n 管
  intrusive_ref_counter: x = 42 use_count = 1
自检通过
```

上面四行输出对应四个进阶点：构造函数的第二个参数 `add_ref=false` 给出**不增加计数的弱观察**（intrusive 世界的 weak_ptr 近似）；`detach()` 交出指针并放弃管理（`unique_ptr::release` 的同族，shared_ptr **没有**这个操作——控制块不撒手）；手写 `intrusive_ptr_release` 里必须检查"减到 0 就 delete"，这件事 intrusive_ptr 不替你做。

不想手写钩子就继承 `intrusive_ref_counter<T>`（默认线程安全计数策略，可换 `thread_unsafe_counter`）：

```cpp
struct Counted : boost::intrusive_ref_counter<Counted> { int x = 0; };
boost::intrusive_ptr<Counted> c{new Counted};   // 钩子由基类的 friend 提供
```

什么时候它比 `shared_ptr` 强：

| 场景 | 为什么 |
|---|---|
| 性能敏感路径 | 单次分配（无控制块）、计数更新缓存更友好 |
| 对象已自带引用计数 | COM 的 `AddRef`/`Release`、WebKit 的 `ref`/`deref`——包一层钩子就能用 intrusive_ptr，包 shared_ptr 反而要自定义删除器+额外分配 |
| 内存极度受限的嵌入式 | 控制块那几十字节也要省 |

代价：没有 weak_ptr 等价物（weak 需要独立于对象的"存活性"信息，intrusive 做不到）、类型必须配合改造。**std 没收它，是刻意的**——标准委员会认为绝大多数场景 `shared_ptr` 够用，特殊场景留给专门设计。

## 3.8 shared_ptr 应用模式全家（sp_patterns.cpp）

书里给 shared_ptr 配了一整节"应用模式"，这些模式在今天依然是 shared_ptr 的正确用法——单独成例程 `sp_patterns.cpp`：

**模式一：pimpl（桥接模式）**。头文件里只声明 `class impl;` 和 `shared_ptr<impl> p;`，实现细节全部藏在 cpp——改实现不重编用户代码，还能减少头文件依赖。`shared_ptr` 支持不完整类型，是三个桥接候选（scoped/shared/unique）里最省心的（unique_ptr 作成员时析构函数必须放 cpp 里）。

```cpp
class sample {
public:
    sample();
    void print() const;
private:
    class impl;                    // 不完整声明：外界不知道实现细节
    boost::shared_ptr<impl> p;     // 桥
};
```

**模式二：工厂 + 保护析构**。接口类的析构函数设为 `protected`——外界连 `delete p.get()` 的权利都没有（编译错误），对象只能从工厂函数出来、由 shared_ptr 接管：

```cpp
class abstract {
public:
    virtual void f() = 0;
protected:
    virtual ~abstract() = default; // protected：delete q 编译不过
};
boost::shared_ptr<abstract> create() { return boost::make_shared<impl_final>(); }
```

**模式三：转型三件套**。`static_pointer_cast`/`dynamic_pointer_cast`/`const_pointer_cast` 返回**转型后的 shared_ptr**（共享同一控制块）——对 shared_ptr 用裸的 `static_cast<T*>(p.get())` 会造出脱离管理的指针，是经典错误：

```cpp
shared_ptr<std::exception> se(new std::bad_exception);
auto be = boost::dynamic_pointer_cast<std::bad_exception>(se);   // 下行转型
auto back = boost::static_pointer_cast<std::exception>(be);      // 上行回来
back == se;                                                        // true：同源
```

**模式四：别名构造（aliasing constructor）**。`shared_ptr<int> second(whole, &whole->second)`——共享 `whole` 的引用计数，但 `get()` 指向它的 `second` 成员。"保持整体活着、暴露部分视图"就是这个构造的用途。

**模式五：owner_less 与"所有权序"**。别名构造让"指针值"与"所有权"分家，比较 shared_ptr 要按所有权来。这里有一个**对第 5 版书的实测勘误**：书说"默认 set 按指针值比较，要 owner_less 才按所有权去重"——实测 1.92 里 `shared_ptr` 的 `operator<` **本来就是所有权序**（std 标准也这么规定），所以默认 set 与 owner_less set 大小相同（都是 1）；owner_less 的真正用途是显式表达意图、以及比较器要单独声明的场合。

**模式六：容器里的 shared_ptr**。`vector<shared_ptr<T>>` 是"STL 存多态对象"的标准答案：迭代器要解两次引用（`**pos`），range-for 直接拿到 shared_ptr；`operator<`（所有权序）让它能做 `map` 的键——但注意键的相等是"同源"，两次 `make_shared<string>("one")` 是**不同的键**（实测查不到）。

**模式七：循环引用对照实验**。shared 成环（A↔B 互持）计数都是 2，作用域结束降到 1，**无人析构——这就是泄漏**，且不报错；把一边换成 `weak_ptr`，环照样能搭（`lock()` 提升），但计数都是 1，作用域结束**正常析构**。析构打印是唯一的目击证据：

运行输出（`sp_patterns.cpp`）：

```text
== 1. pimpl（桥接模式）==
  pimpl: impl print（实现细节被桥接隐藏）
== 2. 工厂模式 + 保护析构 ==
  工厂: impl f
  工厂: impl g
== 3. 定制删除器：FILE 一样能 RAII ==
  FILE 打开? 1
  首字符 = h
== 4. shared_ptr<void>：任意类型的容器 + 任意善后 ==
  box 存了 int? 1
  void 技巧: 退出作用域时执行了任意函数
== 5. 转型三件套（返回转型后的 shared_ptr）==
  dynamic 成功? 1 回转同源? 1
== 6. 别名构造 + owner_less ==
  use_count 同源? 1 指向不同? 1 *second = 1
  p1 与别名 p2 等价（不小于互不成立）? 1
  默认 set 大小 = 1 owner_less set 大小 = 1
== 7. 容器里的 shared_ptr ==
  迭代器双解引用 = 10  range-for = 30
  二次 make_shared 查不到（每次都是新对象）? 1
== 8. 循环引用：shared 成环泄漏 vs weak 解环 ==
  shared 成环 use_count=2? 1
  （上面没有出现 A/B 析构——这就是泄漏）
  weak 成环 use_count=1? 1
  lock 拿到 B? 1
    B(weak) 析构
    A(weak) 析构
自检通过
```

## 3.9 enable_shared_from_this：对象内拿自己的 shared_ptr

回调场景的经典需求："对象成员函数里把自己塞进异步队列"。直接 `shared_ptr<Task>(this)` 是灾难（会造出第二个控制块，双删）；正解是继承 `enable_shared_from_this`：

```cpp
struct Task : boost::enable_shared_from_this<Task> {
    boost::shared_ptr<Task> self() { return shared_from_this(); }
};
```

运行输出（`smart_ptr.cpp`）：

```text
== 7. enable_shared_from_this：对象内部拿到自己的 shared_ptr ==
  self() 拿到同一对象, use_count = 2
自检通过
```

**头号陷阱**：构造函数里调 `shared_from_this()` 是未定义行为——控制块要等 `shared_ptr` 构造完成才挂钩。boost 版在调试模式会断言报错，std 版 C++17 起会 `throw bad_weak_ptr`。同一族陷阱：**栈对象**调用 `shared_from_this()` 也是 UB（析构时会去 delete 栈地址）——这两条都无法安全演示，只能以注释存档（`smart_ptr.cpp` 第 7 节注释）。

## 3.10 毕业档案

| | |
|---|---|
| **std 对应** | `<memory>`：`unique_ptr`、`shared_ptr`、`weak_ptr`、`make_shared`、`enable_shared_from_this`、`std::atomic<std::shared_ptr>`（C++20） |
| **血缘** | 直系（TR1 → C++11） |
| **std 没收的** | `intrusive_ptr`（无对应物）；`intrusive_ref_counter` |
| **迁移注意** | boost 与 std 的 `shared_ptr` **不能混用**（控制块不兼容）；跨 ABI 边界传指针的库若接口规定 boost 版，那就得用 boost 版 |

## 3.11 选型建议

```text
独占？──── 是 → std::unique_ptr（默认选择，95% 场景）
   │
共享？──── 是 → 对象能改造 + 性能敏感/已有计数？ → boost::intrusive_ptr
   │         否 → std::shared_ptr + std::weak_ptr（循环处用 weak）
   │
观察？──── std::weak_ptr
```

一句话：**smart_ptr 的用法该全部用 std 学一遍；Boost 版只在两种情况出现——维护老代码、intrusive_ptr 的独有价值。**（`sp_patterns.cpp` 里的七种模式全部同样适用于 `std::shared_ptr`。）

---


> 上一章：[02 · 环境与构建](02-setup.md) ｜ 下一章：[04 · 函数即对象](04-function.md) ｜ 返回：[README](../README.md)
