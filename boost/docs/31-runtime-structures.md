# 31 · 运行时结构与散珠：signals2 / statechart / msm / openmethod / type_erasure / scope / conversion

> 对应示例：`examples/31_runtime_structures/`（7 个例程）

"运行期才定形状"的程序结构：事件广播（signals2）、状态机双雄（statechart/msm）、多分派（openmethod）、概念多态（type_erasure）、作用域守卫（scope）与转型三兄弟（conversion）。

## 31.1 Boost.Signals2（2007）：信号-槽

类型安全的观察者模式库化——Qt 信号槽的 Boost 形态：

```cpp
sig::signal<void(const std::string&)> on_message;
on_message.connect(slot);              // 多订阅
on_message("hello");                   // 触发：全部按连接序执行
c.disconnect();                        // 精确断开
auto ans = ask();                      // 返回值聚合（combiner 可定制）
```

运行输出（`signals2.cpp`）：

```text
触发 1:
  [控制台] hello
  [日志] 收到 "hello"
触发 2（带优先槽）:
  [优先槽] world
  [控制台] world
  [日志] 收到 "world"
触发 3（已断开）:
  [控制台] again
  [日志] 收到 "again"
聚合返回 = 42（默认取最后）
自检通过
```

"2"的全部意义是**线程安全**：连接管理的竞态、槽里断开自己、发出信号时订阅者析构——全部由库处理（`track_foreign`/`scoped_connection`）。⭐ GUI 框架、事件总线的标准件。std 无对应（`std::function` 只能一 对一）。

## 31.2 Boost.Statechart（2003）与 31.3 Boost.MSM（2010）：状态机双雄

```cpp
// statechart：UML 语义完整（层次/正交/历史），每事件一次查表
struct Idle : sc::simple_state<Idle, Active> {
    using reactions = sc::transition<EvStart, Running>;
};
// msm：迁移表元编程展开成跳转表，快一个数量级
struct transition_table : boost::mpl::vector<
    _row<Stopped, play,   Playing>,
    _row<Playing, pause_evt,  Paused>> {};   // 事件名不能叫 pause：POSIX 有 pause()
```

运行输出（`statechart.cpp`；macOS 侧末尾那行是**状态机析构**打的，Windows 上不出现）：

```text
  进入 Idle
发 EvStart:
  离开 Idle
  进入 Running
再发 EvStart（无迁移）:
发 EvStop:
  离开 Running
  进入 Idle
状态机工作正常
自检通过
  离开 Idle
```

运行输出（`msm.cpp`）：

```text
  [进入初始态]
play:
pause:
play:
stop:
状态机全链路走完
自检通过
```

**选型**：语义复杂（嵌套态、正交区、延迟事件、历史）用 statechart；追求极致吞吐（网络协议栈、游戏 AI）用 msm。⭐ 两者都无 std 对应——C++ 状态机就是 Boost 的地盘。

> 实测坑：msm 的 `on_entry` 钩子签名必须是 `(Event const&, FSM&)` 二参模板；迁移表行类型 `_row` 是 state_machine_def 的**继承成员**，表内不限定直接写。

## 31.4 Boost.OpenMethod（1.89 新库）：多动态类型分派

虚函数只看 `this` 一个动态类型；多方法按**参数组合**分派——访问者模式的现代解药：

```cpp
BOOST_OPENMETHOD_CLASSES(Animal, Cat, Dog);
BOOST_OPENMETHOD(interact, (virtual_<Animal&>, virtual_<Animal&>), const char*);
BOOST_OPENMETHOD_OVERRIDE(interact, (Cat&, Cat&), const char*) { return "舔毛"; }
interact(cat, dog);      // 运行期按 (Cat, Dog) 组合选实现
```

运行输出（`openmethod.cpp`）：

```text
猫咪互相舔毛
猫挑衅狗
狗友好打招呼
自检通过
```

`(Dog, Dog)` 没有精确匹配时回落到 `(Dog, Animal&)`——多方法的"泛化重载"语义。碰撞检测、操作分派（AST 节点 × 访问者）、多协议版本协商这类"双维度动态"问题，它是正解。⭐

> 实测坑：`std::string` 作返回型触发 MSVC 19.51 ICE（内部编译器错误）——返回 `const char*` 绕开；CLASSES 宏后要分号。

## 31.5 Boost.TypeErasure（2011）：概念级 any

`std::any` 装任何类型但**没有统一调用接口**；type_erasure 声明"概念"，按概念调用：

```cpp
BOOST_TYPE_ERASURE_MEMBER((has_name), name, 0)
using AnyShape = te::any<mpl::vector<copy_constructible<>, relaxed,
                                     has_name<std::string()>, has_area<double()>>>;
AnyShape s = Circle{};       // Circle 没有基类！
s.name();  s.area();         // 概念调用
```

运行输出（`type_erasure.cpp`）：

```text
  圆 面积 = 3.14159
  方 面积 = 4
自检通过
```

**零侵入多态**：不动已有类（无基类、无宏注册）就能统一调用——与继承多态、openmethod 三足鼎立（侵入式/零侵入单分派/零侵入多分派）。⭐

## 31.6 Boost.Scope（1.84）：作用域守卫全家福

```cpp
boost::scope::scope_exit  finally{cleanup};     // 无论成败
boost::scope::scope_fail  rollback{undo};       // 仅异常路径
boost::scope::scope_success commit{flush};      // 仅成功路径
auto file = boost::scope::make_unique_resource_checked(std::fopen(...), nullptr, &std::fclose);
guard.set_active(false);                        // 主动解除
```

运行输出（`scope.cpp`）：

```text
工作 1
  [退出清理]
工作 2（不抛，不触发回滚）
  [失败回滚触发了]
捕获后继续
工作 3
  [成功提交]
文件句柄有效，离开作用域自动 fclose
（上一行没有触发清理——解除成功）
自检通过
```

事务型代码（"失败就回滚、成功才提交"）的三件套 + `unique_resource`（带判空的 RAII 工厂）。C++ 标准的 `std::unique_resource`（Library Fundamentals TS）至今未转正——**事务安全目前靠它**。⭐

> 实测坑：`unique_resource` 直接构造对模板参数推导挑剔，**工厂函数**（`make_unique_resource_checked`）才是规范入口。

## 31.7 Boost.Conversion：转型三兄弟

```cpp
boost::polymorphic_cast<Left*>(p);      // dynamic_cast 的异常版（失败抛）
boost::polymorphic_downcast<Left*>(p);  // 确信下行：debug 校验 + release 零成本
boost::numeric_cast<int>(x);            // 数值范围检查（24 章）
```

运行输出（`conversion.cpp`）：

```text
转 Left 成功: Left
转 Right 抛 bad_cast（不是返空）
downcast: Left
自检通过
```

> 实测坑：模板参数是**指针类型**（`<Left*>` 不是 `<Left>`）——与 `dynamic_cast<Left*>` 对齐。

---


> 上一章：[30 · 序列化与配置](30-serialization.md) ｜ 下一章：[32 · 工程质量](32-quality.md) ｜ 返回：[README](../README.md)
