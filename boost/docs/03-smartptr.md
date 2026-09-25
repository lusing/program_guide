# 03 · 所有权革命：smart_ptr

> 对应示例：`examples/03_smartptr/smart_ptr.cpp`

## 3.1 Boost 给 C++ 上的第一课

1999 年，`boost::smart_ptr` 进入 Boost。彼时 C++98 刚定型，堆对象的生死全靠 `new`/`delete` 手工配对，泄漏、悬垂、双删三大事故是每个 C++ 程序的日常。`smart_ptr` 的答案后来成了整个现代 C++ 的第一原则：

> **每个堆对象在同一时刻恰好有一个明确的所有者；所有权可以转移、可以共享，但从不模糊。**

这个库是 TR1 收编的第一批（`shared_ptr`/`weak_ptr` 2005 年进 TR1，2011 年进 C++11），也是"Boost 是标准库预备队"这个命题最响亮的证据。

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
| `enable_shared_from_this` | 对象内取自身 shared | 同名 | ✅ 已毕业 |
| `static/dynamic/const/reinterpret_pointer_cast` | 智能指针版转型 | C++17 起有 | ✅ 已毕业 |
| `boost::atomic_shared_ptr` | 原子共享指针 | `std::atomic<shared_ptr>`（C++20） | ✅ 已毕业 |

**结论先行**：这个库 90% 的面积已经毕业，新代码的默认答案是 std。剩下 10% 的独有价值在 `intrusive_ptr`——以及"理解 `shared_ptr` 是怎么工作"这件事本身。

## 3.3 scoped_ptr：unique_ptr 的直系祖先

```cpp
boost::scoped_ptr<Sensor> s{new Sensor("scoped")};
// boost::scoped_ptr<Sensor> s2 = s;   // 编译错误：不可拷贝
```

`scoped_ptr` 用"不可拷贝"表达独占——这是 C++03 没有移动语义时代的杰作：既然不能转移，所有权就永远清晰。C++11 的 `unique_ptr` 在同样语义上增加了**可移动**（所有权可以交接），并加入了数组特化、自定义删除器、零开销抽象（就是裸指针大小）。

`scoped_ptr` 与 `unique_ptr` 的实测差异（例程第 1 节）：（运行输出 `smart_ptr.cpp`）

```text
== 1. scoped_ptr：独占、不可拷贝（unique_ptr 的直系祖先）==
  Sensor(scoped) 构造
  name=scoped
  Sensor(scoped) 析构
```

作用域结束自动析构，异常安全。今天写这段代码应该直接：

```cpp
auto s = std::make_unique<Sensor>("scoped");   // C++14 起
```

## 3.4 shared_ptr：引用计数与控制块

```cpp
boost::shared_ptr<Sensor> a = boost::make_shared<Sensor>("shared");
{
    boost::shared_ptr<Sensor> b = a;   // 计数 +1
}                                      // 计数 -1，对象还活着
```

运行输出（`smart_ptr.cpp`）：

```text
== 2. shared_ptr：引用计数共享 ==
  Sensor(shared) 构造
  a 引用计数 = 1
  拷贝后 use_count = 2
  b 析构后 use_count = 1
```

三个值得刻进脑子的细节：

1. **`make_shared` 把对象和控制块一次分配**。直接 `shared_ptr<T>(new T)` 是两次分配（对象一次、控制块一次），且 `f(shared_ptr<T>(new T), g())` 在实参求值顺序未指定时可能泄漏（C++17 前的著名坑）。`make_shared` 两个问题一起解决。
2. **控制块永不搬家**：拷贝/移动 `shared_ptr` 只动指针和计数，析构时最后一个持有者负责释放。
3. **计数操作是原子的**，跨线程拷贝同一个 `shared_ptr` 是安全的（`atomic_shared_ptr`/C++20 `std::atomic<shared_ptr>` 解决的是另一件事：多线程改**同一个** shared_ptr 变量）。

## 3.5 weak_ptr：观察者模式的所有权版

`weak_ptr` 指向 `shared_ptr` 管的对象但不增加计数——两大用途：**打破循环引用**（A、B 互持 shared_ptr 就谁也死不了；一方改 weak 即解）与**缓存**（缓存持有 weak，对象没人用时自动失效）。

```cpp
boost::weak_ptr<Sensor> w = a;          // 不增加计数
if (auto locked = w.lock()) { ... }     // 使用前提升回 shared_ptr
```

运行输出（`smart_ptr.cpp`）：

```text
== 3. weak_ptr：观察不拥有（打破循环/缓存）==
  expired() = false
  lock 成功: shared
  Sensor(shared) 析构
  释放最后一个 shared 后 expired() = true
```

注意 `lock()` 的模式：它返回 `shared_ptr`，对象已死则返回空——**先 lock 再用**，绝不解引用裸的 weak。

## 3.6 自定义删除器：管一切资源

```cpp
boost::shared_ptr<Conn> conn(new Conn{7}, [](Conn* p) {
    delete p;
    std::cout << "  连接已由删除器关闭\n";
});
```

`shared_ptr<T>` 的类型**不含删除器**（删除器存在控制块里，类型擦除）——这让它可以 heterogeneous 地装进同一个容器。把 `delete p` 换成 `fclose`、`CloseHandle`、`sqlite3_close`，就是文件/句柄/数据库连接的 RAII 管理。

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
== 5. intrusive_ptr：计数长在对象身上（零控制块开销）==
  refs = 1
  拷贝后 refs = 2
```

什么时候它比 `shared_ptr` 强：

| 场景 | 为什么 |
|---|---|
| 性能敏感路径 | 单次分配（无控制块）、计数更新缓存更友好 |
| 对象已自带引用计数 | COM 的 `AddRef`/`Release`、WebKit 的 `ref`/`deref`——包一层钩子就能用 intrusive_ptr，包 shared_ptr 反而要自定义删除器+额外分配 |
| 内存极度受限的嵌入式 | 控制块那几十字节也要省 |

代价：没有 weak_ptr 等价物（weak 需要独立于对象的"存活性"信息，intrusive 做不到）、类型必须配合改造。**std 没收它，是刻意的**——标准委员会认为绝大多数场景 `shared_ptr` 够用，特殊场景留给专门设计。

## 3.8 enable_shared_from_this：对象内拿自己的 shared_ptr

回调场景的经典需求："对象成员函数里把自己塞进异步队列"。直接 `shared_ptr<Task>(this)` 是灾难（会造出第二个控制块，双删）；正解是继承 `enable_shared_from_this`：

```cpp
struct Task : boost::enable_shared_from_this<Task> {
    boost::shared_ptr<Task> self() { return shared_from_this(); }
};
```

运行输出（`smart_ptr.cpp`）：

```text
== 6. enable_shared_from_this：对象内部拿到自己的 shared_ptr ==
  self() 拿到同一对象, use_count = 2
```

**头号陷阱**：构造函数里调 `shared_from_this()` 是未定义行为——控制块要等 `shared_ptr` 构造完成才挂钩。boost 版在调试模式会断言报错，std 版 C++17 起会 `throw bad_weak_ptr`。

## 3.9 毕业档案

| | |
|---|---|
| **std 对应** | `<memory>`：`unique_ptr`、`shared_ptr`、`weak_ptr`、`make_shared`、`enable_shared_from_this`、`std::atomic<std::shared_ptr>`（C++20） |
| **血缘** | 直系（TR1 → C++11） |
| **std 没收的** | `intrusive_ptr`（无对应物）；`boost::shared_ptr` 的 `local_sp_ptr`/`owner_before` 细节差异 |
| **迁移注意** | boost 与 std 的 `shared_ptr` **不能混用**（控制块不兼容）；跨 ABI 边界传指针的库若接口规定 boost 版，那就得用 boost 版 |

## 3.10 选型建议

```text
独占？──── 是 → std::unique_ptr（默认选择，95% 场景）
   │
共享？──── 是 → 对象能改造 + 性能敏感/已有计数？ → boost::intrusive_ptr
   │         否 → std::shared_ptr + std::weak_ptr（循环处用 weak）
   │
观察？──── std::weak_ptr
```

一句话：**smart_ptr 的用法该全部用 std 学一遍；Boost 版只在两种情况出现——维护老代码、 intrusive_ptr 的独有价值。**

---


> 上一章：[02 · 环境与构建](02-setup.md) ｜ 下一章：[04 · 函数即对象](04-function.md) ｜ 返回：[README](../README.md)
