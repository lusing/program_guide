# 09 · 动态内存与智能指针：所有权说话

> 对应示例：`examples/09_smartptr/`

## 9.1 为什么还要 new/delete

栈变量的生死跟着作用域走（第 03 章），但有些对象必须**活得比创建它的作用域久**：一次请求里创建的连接要活到响应发完、容器要能在运行期长到任意大。C++ 的答案是把对象放进**堆**（动态内存），代价是生死要有人管。

裸指针管理堆的三大经典事故，每一个都在真实项目里烧过钱：

| 事故 | 代码长相 | 后果 |
|---|---|---|
| **泄漏** | `Task* t = new Task();` 忘了 delete | 内存缓慢流失，跑一周OOM |
| **悬垂** | delete 后继续用 | 未定义行为，读垃圾/崩溃 |
| **双删** | 两个地方都 delete 同一指针 | 堆结构破坏，随机崩 |

老 C++ 靠程序员纪律对抗这三件事；现代 C++ 的答案是把堆对象的生死**也交给 RAII**（第 08 章的心法直接迁移）：智能指针就是"持有指针的 RAII 壳"。

## 9.2 所有权：现代 C++ 的第一原则

本章只有一条核心思想：**每个堆对象在同一时刻恰好有一个明确的所有者（owner）**。所有者 = 负责释放它的那个变量/容器。所有权可以**转移**（给你了就是你的），可以**共享**（计数托管），但从不模糊。

三种智能指针就是三种所有权策略：

| 指针 | 所有权 | 拷贝 | 开销 | 默认选择 |
|---|---|---|---|---|
| `unique_ptr<T>` | 独占 | ❌（只能 move） | **零**（就是裸指针大小） | ✅ **95% 场景** |
| `shared_ptr<T>` | 共享（引用计数） | ✅（计数+1） | 计数维护+控制块 | 确需多方共持 |
| `weak_ptr<T>` | 观察（不拥有） | ✅ | 同上但不算数 | 打破循环、缓存 |

## 9.3 unique_ptr：独占所有权

```cpp
std::unique_ptr<Task> make_task(std::string name) {
    return std::make_unique<Task>(std::move(name));  // 工厂惯用法
}
// ……
auto t1 = make_task("调研");
// auto t2 = t1;         // 编译错误：unique_ptr 不可拷贝
auto t2 = std::move(t1); // 只能转移；t1 变空
std::println("t1 空了吗？{}", t1 == nullptr);  // true
std::println("t2 持有 {}", t2->name);
```

`std::make_unique<T>(args)`（C++14）一步完成"分配+构造+包装"，**新代码不写裸 new**。独占语义由类型系统强制：拷贝直接编译错误（所有权不能凭空复制），`std::move` 转移后源指针变空——被搬空状态可判空、不可再用（第 15 章的规则）。

用法：`t2->name`（等价裸指针的 `->`）、`*t2` 解引用、`t2 == nullptr` 判空。**按值返回 unique_ptr 是转移**（工厂惯用法），零拷贝零泄漏——这就是"所有权沿调用链流动"的样子。

```cpp
{
    auto t3 = make_task("原型");
}  // t3 在此自动析构——RAII 管理堆内存
```

作用域结束，析构自动 delete——**泄漏在结构上不可能发生**（忘写 delete 这个动作本身不存在了）。

## 9.4 shared_ptr：共享与引用计数

```cpp
auto shared1 = std::make_shared<Task>("发布");
{
    auto shared2 = shared1;  // 拷贝：计数 +1
    std::println("引用计数 = {}", shared1.use_count());  // 2
}  // shared2 析构：计数 -1
std::println("引用计数 = {}", shared1.use_count());  // 1
```

`shared_ptr` 让多个持有者共存：**计数归零的那一刻对象析构**。`use_count()` 观察计数（调试用，别写依赖它的逻辑）。`std::make_shared` 优于 `shared_ptr<T>(new T)`：对象与控制块一次分配。

它不是"更高级"的指针，是**更贵**的指针：每次拷贝/析构都要原子地增减计数（多线程安全的代价），且控制块占额外内存。**能用 unique 就别用 shared**——不是因为 shared 难，而是"谁拥有"含糊本身会传染设计。先问"真的需要多方共持吗"，多数时候答案是否（改传引用、改 move）。

## 9.5 weak_ptr：观察但不拥有

```cpp
std::weak_ptr<Task> observer = shared1;
if (auto locked = observer.lock()) {  // 尝试升级成 shared_ptr
    std::println("观察到 {}", locked->name);
}
shared1.reset();  // 释放最后一个强引用 → Task 立即析构
std::println("对象还活着吗？{}", !observer.expired());  // false
```

`weak_ptr` 指着对象但**不续命**：`lock()` 尝试升级（对象已死返回空 shared_ptr），`expired()` 问"还活着吗"。两大用途：

1. **打破循环引用**：A、B 互持 shared_ptr 时计数永不归零（你等我放，我等你放）→ 泄漏。把"回指"方向改 weak_ptr（parent 用 shared 拥有 child，child 用 weak 回望 parent），环就断了。
2. **缓存/观察者**：持有"如果还活着就能用"的引用，不阻止对象退休。

## 9.6 容器持有：vector<unique_ptr>

```cpp
std::vector<std::unique_ptr<Task>> backlog;
backlog.push_back(make_task("收尾"));
backlog.push_back(make_task("复盘"));
std::println("待办 {} 项", backlog.size());
while (!backlog.empty()) {
    backlog.pop_back();  // 顺序确定：后进先出
}
}  // 剩下的局部对象在此析构
```

`vector<unique_ptr<T>>` 是"一堆动态对象"的标准姿势：容器是所有者，元素随容器消亡。跑一下示例看析构输出顺序——它同时也是**多态容器**的地基（`vector<unique_ptr<Shape>>`，第 16 章见）。

> **为什么这里显式 `pop_back` 而不等容器析构**：容器析构时**元素按什么顺序销毁，标准没有规定**——实测 libc++ 逆序（`复盘` 先走）、libstdc++ 正序（`收尾` 先走），MSVC 又是另一种。教学示例的输出应当人人可复现，所以自己弹空；真实代码里若顺序重要（比如要按依赖关系释放），同样要显式控制，别指望容器。

## 9.7 性能与迁移

- **unique_ptr 零开销**：与裸指针同大小、同解引用成本，release 后的机器码一样——"安全"在这里不要钱。
- 老代码迁移次序：新代码一律 make_unique/make_shared → 旧代码里 `new` 的返回值直接包进 unique_ptr（行为不变）→ 删掉配对的 delete → 有真正共持才升级 shared。
- `get()` 拿裸指针**只为了传给老 API**，不许存下来（存了就绕过所有权，悬垂回来了）。

## 9.8 坑位清单

1. **两个 shared_ptr 从同一裸指针构造**：`shared_ptr<T> a{p}; shared_ptr<T> b{p};` 两套计数互不知晓→双删。共享要经拷贝：`auto b = a;`。
2. **循环引用**：互持 shared 的对象永不析构。回指方向换 weak_ptr。
3. **shared_ptr 按值传参不必要地 +1 计数**：只读参数传 `const shared_ptr<T>&`，所有权转出才按值。函数要不要接管的意图直接写在签名里。
4. **get() 的裸指针存成成员/全局**：所有权被绕过，指针悬垂。
5. **make_shared 与自定义删除器**：需要自定义删除（fclose 而非 delete）时 `unique_ptr<T, Deleter>`，删除器进类型——shared_ptr 则可运行期换删除器，两者分工。
6. **对数组用错指针**：`unique_ptr<T[]>` 才是数组版（`make_unique<T[]>(n)`）；但**要数组先想 vector**（第 10 章），裸数组 new 是最后手段。
