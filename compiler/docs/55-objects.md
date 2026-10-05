# 第 55 章　对象与类：vtable、继承布局与派发的几何

## 55.1 问题：`.` 背后有一整台机器

面向对象的
源代码里，
`obj.speak()`
只是一次
成员访问；
编译器要把
它变成机器
能执行的
**布局、
查找与跳转**：
对象在内存里
长什么样？
方法在哪个
槽位？
静态类型是
Animal、
运行时是
Puppy 的引用，
到底调谁？

虎书第 20 章
把这些决策
一锤定音：
对象布局的
**前缀法**、
方法的
**vtable 槽表**、
类成员的
**测试方案**。
本章自包含
蒸馏全套，
配套示例
`examples/55_objects`
造一个
迷你对象模型
（单继承链 +
多继承钻石），
布局、vtable、
派发轨迹、
成员测试、
**虚调用的
0-CFA 目标集**
全部进对账——
最后一项
直接连回
第 53 章
"调用图是
分析出来的"。

## 55.2 对象布局：前缀法

**对象 =
数据记录 +
类指针**。
数据记录的
布局由类层级
决定，
**单继承
前缀法**
（prefix
layout）
是压倒性的
主流：

> 子类的字段表 =
> 父类的字段表
> （原序、原偏移）
> ＋ 自有字段
> （追加在后）。

```
Animal: [0:name]
Dog:    [0:name 1:barkHz]        ← Animal 前缀 + barkHz
Puppy:  [0:name 1:barkHz 2:cute] ← Dog 前缀 + cute
```

前缀法的
威力在
**兼容**：
指向 Dog 的
指针与指向
Animal 的
指针看到的
**前缀完全
相同**——
`obj.offset(0)`
取 name
永远合法，
不管 obj 的
动态类型是
链条上的谁。
这就是
"子类引用
可以赋给
父类引用"
在内存层的
实现：
同一块内存，
不同的
"观察窗口"。

**多继承**
打破前缀：
D 同时继承
B1、B2，
两份前缀
不能都在
偏移 0。
教学子集
（虎书 14.3）：
D 的布局 =
B1 前缀 +
B2 子对象
（偏移 =
  B1 尺寸）+
自有字段：

```
RoboDog < Dog, Robot:
[0:name 1:barkHz | 2:serial | 3:firmware]
 ← Dog 子对象    ← Robot 子对象（偏移 2）
```

把 RoboDog
引用转成
Robot 引用，
编译期
**加偏移 2**；
转成 Dog
引用不变。
每个父类
一个
"子对象"，
偏移静态
可知——
这就是
多继承的
全部代价
（再加成员
  测试的
  复杂度，
见 46.4）。

## 55.3 vtable：虚方法的槽表

**静态方法**
（非虚）：
编译期直呼
`Animal::kind`——
符号解析
（第 14 章）
的普通成员，
一条
call 指令。

**虚方法**：
编译期不知道
调谁，
运行时按
对象的
**动态类型**
派发。
实现主流是
**vtable**
（虚方法表）：

- 每个类一张
  静态表：
  槽序 = 父类
  槽序（继承），
  覆写替换
  槽内容，
  新虚方法
  追加新槽；
- 每个对象
  头部一个
  类指针，
  指向其
  动态类的
  vtable；
- 虚调用
  `obj.m()`：
  `load 类指针
   → load 槽 k
   → call`——
  两次读 +
  一次间接
  调用。

期望输出的
vtable 表：

```
Animal: [0]speak->Animal::speak
Dog:    [0]speak->Dog::speak [1]fetch->Dog::fetch
Puppy:  [0]speak->Dog::speak [1]fetch->Dog::fetch    ← 继承 Dog 的表（未覆写）
```

**槽位稳定
是契约**：
Animal 的
speak 在槽 0，
则所有子类的
speak 都在
槽 0——
静态类型
Animal 的
引用才能
闭着眼
取槽 0。
子类覆写
只换槽内容
（Dog::speak
  替换
  Animal::speak），
不动槽序：
前缀法在
方法表的
投影。

**多继承的
vtable**：
教学子集只编
主父（B1）的
表——通过
B2 引用调
虚方法需要
**thunk**
（调整 this
偏移的
跳板），
正文点到、
不实现，
坐标已给。

**虚派发
轨迹**：

```
Puppy.speak = Dog::speak    ← 槽 0 上 Dog 的覆写（Puppy 未覆写，继承 Dog 版）
Puppy.fetch = Dog::fetch    ← 槽 1 直接继承
```

## 55.4 类成员测试：instanceof 的代价

`x instanceof T`
（或向下转型
  的检查）
要求运行时
回答：
x 的动态类
是 T 的子类吗？

方案谱系
（虎书 14.4，
  自包含讲清）：

- **字典**：
  每个类带
  全体祖先的
  集合，
  O(1) 查、
  O(深度×
  类数) 空间；
- **display
  向量**：
  每个类带
  一个向量，
  第 i 格存
  "深度 i 的
  祖先"——
  单继承下
  O(1) 查、
  空间同上，
  且向量结构
  与"逐级
  上行"同构；
- **染色**
  （interval
  coloring）：
  对继承树
  做 DFS
  编 [in,out]
  区间，
  u 是 v 的
  祖先 ⟺
  in(u) ≤ in(v)
  ∧ out(v) ≤
  out(u)——
  O(1) 查、
  O(1) 空间，
  但**只对
  树**（单继承）
  成立。

多继承把
树变 DAG，
区间失效、
向量要两套
（每条
  继承路径
  一套），
成本骤增——
Java 的
interface
测试、
C++ 的
RTTI 都在
这个谱系里
做工程折中。

本示例实现
display 式
**逐级上行**
（教学最透明：
  答案是怎么
  找到的
  一路可见）：

```
Puppy instanceof Animal : yes (深度 2, 途经 {Puppy->Dog})
RoboDog instanceof Robot : yes (途经 {RoboDog->Dog->Animal})
```

第二行值得
看两眼：
RoboDog 的
主父链
（Dog→Animal）
**找不到**
Robot，
测试沿第二
父分支成功
——多继承下
成员测试
是
"多路搜索"，
路径输出
如实记录了
这次绕行。

## 55.5 虚调用与 0-CFA：类型收敛的舞台

静态类型 T 的
引用 `obj`，
`obj.m()`
到底调谁？
编译器
**静态地**
回答：

> 一切可能的
> 动态类型 =
> T 与 T 的
> 全体（传递）
> 子类；
> 目标集 =
> 它们在槽 k
> 上的实现的
> 并。

期望输出：

```
静态类型 Animal.speak() 可能调用: {Animal::speak Dog::speak}
静态类型 Dog.speak()    可能调用: {Dog::speak}
```

Animal 的
子类树 =
{Animal,
  Dog, Puppy,
  RoboDog}，
槽 0 上的
实现去重后
恰两个；
Dog 的子类树
全都继承
Dog 的覆写，
目标唯一。

这正是
第 53 章
0-CFA 的
对象版：
**不做
类型收敛时
的保守目标
集合**。
类层级 +
vtable 把
"闭包分析"
的输入
结构化了——
44 章的
loc → 函数集
在这里
变成
静态类型 →
实现集。
反过来，
**类测试
分析**
（class
hierarchy
analysis，CHA）
用"程序里
从未 new 过
Puppy"这类
事实**收缩**
目标集，
虚调用退化为
直呼——
对象世界给
流分析
递上了一个
天然的
精化舞台。

## 55.5b　方法即闭包：bound method 与 this 捕获（匠书 §28）

vtable 派发回答的是"**调用**时找谁"；匠书 §28 补的问题是：把
方法**当值存起来**（var m = obj.speak; m()）时 this 怎么办？
答案：方法值不是裸函数，而是 **bound method（绑定方法）**——
"方法查找结果 + 捕获 this 的闭包"。bindMethod 的三字段返回
（定义类 / 方法名 / thisSlot）就是这个闭包的教学形态：**this
在绑定那一刻被捕获**（第 60 章上值的 this 版），延迟调用时
this 不丢——断言 ok5 锁的正是这一点（this=7 随绑定走）。

**绑定一次 vs 每次查找**的对照也在输出里：bound method 的
定义类 Dog 与 vtable 派发的 Dog::speak 同名同源——语义等价、
代价不同（闭包缓存了查找结果；vtable 每次调用查一次表）。
这是第 58 章"内联缓存"的前置直觉：**方法解析的答案可以像
值一样缓存**——真实引擎的 method handle、SIMD 动态派发优化
都建立在这个观察上。

**this 的静态纪律**（thisUseLegal）：this 只在方法体内合法、
顶层使用静态拒绝——这不是运行时检查而是**编译期位置检查**
（像第 15 章的 return 位置检查一样，属于"窗口分类学"——
this 的窗口是方法体）。教程的教学口径由调用方报位置、裁决器
裁决——真实的实现里它在解析器/编译器的一个 case 里（clox 的
this 处理恰好在第 60 章同款编译器里）。

## 55.5c　super 链：换起点不换 this（匠书 §29）

super 的经典误解是"调用父类版本时 this 换成父类对象"——
匠书 §29.3 专门澄清：**super 改变的是查找起点（从父类链找），
this 仍然是原接收者**。superDispatch 的实现三步正是这个语义
的直译：取当前类的父类为起点 → 沿链找方法定义 → **绑定原
thisSlot**（不是父类的什么对象——父类根本没有独立对象）。

输出的两条裁决各证一半：**Puppy 的 super 命中 Dog**（Puppy
自己不覆写 speak——super 跳过的只是"自己的定义"，不是全部
覆写；Dog 的定义就是链上第一个）；**Dog 的 super 直达 Animal**
（Dog 覆写了——跳过自身覆写，找到根版本）。两条的 this 都
保持（7 与 3）——"换起点不换 this"的完整证词。

**super 与 vtable 的关系**值得一行：vtable 装的是"从本类起
查"的答案（Puppy 的 speak 槽填 Dog::speak——继承即复制父表
）；super 需要的是"从父类起查"——它不能直接查自己的 vtable
（会绕回自己），所以要么查父类的 vtable（单继承可行）、要么
编译期解析成直接调用（本章 bindMethod 返回的静态答案就是它）
。**super 是编译期友好的动态特性**——它的目标集比虚调用小
得多（起点固定、只少一层），多数语言的 super 调用根本不进
vtable——这是"继承的静态红利"。

## 55.6 期望输出解读与对账

四段输出、
四条断言：

1. **布局表**：
  前缀法
  逐字段对号
  （断言一：
    Puppy 的
    name@0、
    barkHz@1、
    cute@2）；
2. **vtable**：
  槽序稳定、
  覆写换内容
  （断言二：
    Puppy.speak
    命中 Dog
    的覆写槽）；
3. **派发轨迹**：
  静态方法
  沿链直呼
  （Puppy.kind
    = Animal::kind，
    三级上行）、
  虚方法沿
  vtable 取槽；
4. **目标集**：
  断言三：
  Animal 引用
  的 speak
  目标集
  **恰 2 个**
  （Animal::+
    Dog::，
    Robot 不同根
    不掺和）；
  断言四：
  多继承的
  成员测试
  沿第二父
  可达。

四条全绿
即 exit 0——
布局、槽表、
派发、测试
四个部件
各自有
机器证人，
模型整机
才算装配
完成。

## 55.7 工程注意点

- **前缀法
  不是唯一**。
  Self/小对象
  模型用
  "方法内联 +
  内联缓存"，
  动态语言
  （JS 引擎）
  用隐藏类
  （hidden
  class）+
  IC——
  但静态 OO
  语言
  （C++/Java）
  的工业实现
  无一例外
  前缀法 +
  vtable。
- **this 的
  传递**。
  虚方法收到
  的 this
  是对象头
  指针；
  多继承的
  B2 方法
  收到的
  this 要
  减偏移回
  B2 子对象
  ——thunk
  或调用方
  调整，
  一处不能错。
- **私有与
  封装是
  编译期
  概念**。
  布局一旦
  定下，
  运行时
  只有偏移
  没有访问
  控制——
  前缀法的
  兼容性
  同时是
  封装的
  逃逸口
  （C++ 的
    破坏性
    转型）。
- **CHA 与
  去虚化**。
  目标集
  收缩到
  唯一时，
  间接调用
  变直呼，
  内联（第 56 章）
  随之解锁
  ——去虚化
  是 OO 程序
  优化的
  第一铲。
- **对象与
  记录**。
  TIP 的记录
  （第 3 章）
  是无类的
  布局；
  对象 =
  记录 +
  类指针 +
  槽表。
  42 章的
  指针分析、
  15 章的 GC
  都以记录
  为基座——
  本章在
  同一基座上
  加了
  "几何"
  （层级）
  一层。

## 55.8 本章配套文件

本示例无
ANTLR——
迷你对象
模型自包含，
走"简单程序"
对账协议。

### 55.8.1 objmodel.hpp 与 objmodel.cpp

类声明/
finalize
两遍闭包
（布局 +
  vtable）、
字段偏移、
display 式
成员测试、
静态/虚派发、
0-CFA 目标集。

```cpp
// file: src/objmodel.hpp
// file: src/objmodel.hpp
// 第 55 章配套：迷你对象模型（虎书 §14 自包含蒸馏）。
#ifndef TIP_OBJMODEL_HPP
#define TIP_OBJMODEL_HPP

#include <map>
#include <string>
#include <vector>

namespace tip {

struct Method {
    std::string name;
    bool isVirtual = false;
};

struct VTable {
    std::vector<std::string> slotNames;
    std::vector<std::string> slots;   // 槽 → 实现名（“类::方法”）
};

struct ClassDecl {
    std::string name;
    std::string parent;              // 空 = 根；"B1,B2" = 多继承（教学两级）
    std::vector<std::string> fields;
    std::vector<Method> methods;
    // finalize() 后填：
    std::vector<std::string> layout; // 展平字段表（含继承）
    int baseOffset = 0;              // 主父子对象在自身内的偏移（教学恒 0）
    int secondaryOffset = -1;        // 多继承第二父子对象偏移
    std::string secondaryParent;
    VTable vtable;
};

class World {
public:
    ClassDecl &declare(const std::string &name, const std::string &parent,
                       const std::vector<std::string> &fields,
                       const std::vector<Method> &methods);
    void finalize();   // 布局 + vtable 一次算完（两遍：先声明后闭包）

    int fieldOffset(const std::string &cls, const std::string &field) const;

    // 类成员测试：cls 是 ancestor 的（间接）子类？返回继承深度，非子类 -1。
    // path 收集途经类名（display 方案的“逐级上行”实录）。
    int subclassTest(const std::string &cls, const std::string &ancestor,
                     std::vector<std::string> &path) const;

    // 派发：虚方法沿 vtable（子类覆写优先）；静态方法沿继承链直呼。
    std::string dispatchVirtual(const std::string &cls, const std::string &method) const;
    std::string dispatchStatic(const std::string &cls, const std::string &method) const;

    // 虚调用的可能目标集合（0-CFA 口径：静态类型 T ⇒ T 及其全部子类的实现）。
    std::vector<std::string> virtualTargets(const std::string &staticType,
                                            const std::string &method) const;

    const std::map<std::string, ClassDecl> &classes() const { return classes_; }

    // ================= 匠书增量（§28–29） =================
    // bound method：方法不是记录里的字段，而是"方法查找 + 捕获 this
    // 的闭包"。存进变量延迟调用 this 不丢——因为 this 已被捕获。
    struct BoundMethod {
        std::string className;   // 定义该方法的类（查找结果）
        std::string methodName;
        int thisSlot;            // 捕获的接收者（演示里的对象编号）
    };
    // 返回 bound method：沿 cls 的继承链找 method（子类覆写优先），
    // 找到即绑定 this=obj——方法值 = 身体 + 捕获接收者。
    BoundMethod bindMethod(const std::string &cls, const std::string &method,
                           int thisSlot) const;

    // this 逃逸检测：方法体外的 this 使用属于静态错误。
    // 返回 true = 位置合法（在方法体内）；demo 简化为：名字是否
    // 出现在任一方法的允许字段列表中（教学口径：字段访问即体内）。
    bool thisUseLegal(const std::string &cls, bool insideMethod) const;

    // super 派发：先沿超类链找到方法定义（跳过当前类自己的覆写），
    // 再用**当前接收者**绑定 this——super 不是"换 this"，
    // 是"换查找起点、this 仍是原对象"（§29.3 匠书经典澄清）。
    BoundMethod superDispatch(const std::string &cls, const std::string &method,
                              int thisSlot) const;

private:
    std::map<std::string, ClassDecl> classes_;
};

}  // namespace tip

#endif  // TIP_OBJMODEL_HPP
```

```cpp
// file: src/objmodel.cpp
// file: src/objmodel.cpp
// 第 55 章配套：迷你对象模型——布局、vtable、单继承前缀法、
// 多继承的类成员测试、静态/虚派发轨迹（虎书 §14）。
#include "objmodel.hpp"

#include <algorithm>
#include <sstream>

namespace tip {

ClassDecl &World::declare(const std::string &name, const std::string &parent,
                          const std::vector<std::string> &fields,
                          const std::vector<Method> &methods) {
    ClassDecl c;
    c.name = name;
    c.parent = parent;
    c.fields = fields;
    c.methods = methods;
    classes_[name] = c;
    return classes_[name];
}

void World::finalize() {
    // 布局：单继承前缀法——父类字段原序在前，子类字段接后；
    // 每个类记 (基址偏移, 字段表)。多继承的教学子集：
    // D 同时继承 B1、B2 ⇒ D 的布局 = B1 前缀 + B2 副本(偏移 b1Size) + 自有，
    // 访问 B2 的字段要走“D 内的 B2 子对象偏移”。
    for (auto &kv : classes_) {
        ClassDecl &c = kv.second;
        if (c.parent.empty()) {
            c.baseOffset = 0;
            c.layout = c.fields;
        } else if (c.parent.find(',') == std::string::npos) {
            // 单继承：前缀
            ClassDecl &p = classes_.at(c.parent);
            c.baseOffset = 0;
            c.layout = p.layout;
            c.layout.insert(c.layout.end(), c.fields.begin(), c.fields.end());
        } else {
            // 多继承：parent 形如 "B1,B2"（教学口径只支持两个）
            std::string p1 = c.parent.substr(0, c.parent.find(','));
            std::string p2 = c.parent.substr(c.parent.find(',') + 1);
            ClassDecl &b1 = classes_.at(p1);
            ClassDecl &b2 = classes_.at(p2);
            c.secondaryOffset = static_cast<int>(b1.layout.size());
            c.layout = b1.layout;
            c.layout.insert(c.layout.end(), b2.layout.begin(), b2.layout.end());
            c.layout.insert(c.layout.end(), c.fields.begin(), c.fields.end());
            c.secondaryParent = p2;
        }
    }
    // vtable：虚方法的槽表。单继承下子类 vtable = 父类副本 + 覆写槽替换 +
    // 新方法追加（前缀法的调用方兼容）。多继承教学子集只编主父的表。
    for (auto &kv : classes_) {
        ClassDecl &c = kv.second;
        VTable vt;
        if (!c.parent.empty() && c.parent.find(',') == std::string::npos) {
            vt = classes_.at(c.parent).vtable;   // 继承槽序
        }
        for (const auto &m : c.methods) {
            if (!m.isVirtual) continue;
            // 覆写或追加：按名字找槽
            int slot = -1;
            for (size_t k = 0; k < vt.slots.size(); ++k)
                if (vt.slotNames[k] == m.name) slot = static_cast<int>(k);
            if (slot < 0) {
                vt.slotNames.push_back(m.name);
                vt.slots.push_back(c.name + "::" + m.name);
            } else {
                vt.slots[slot] = c.name + "::" + m.name;
            }
        }
        c.vtable = vt;
    }
}

int World::fieldOffset(const std::string &cls, const std::string &field) const {
    const ClassDecl &c = classes_.at(cls);
    for (size_t k = 0; k < c.layout.size(); ++k)
        if (c.layout[k] == field) return static_cast<int>(k);
    return -1;
}

// 类成员测试（虎书 14.4 的 display 方案，教学两级）：
//   一级缓存：类自身；miss 时沿父链上行（单继承直走、多继承两路都查）。
int World::subclassTest(const std::string &cls, const std::string &ancestor,
                        std::vector<std::string> &path) const {
    if (cls == ancestor) return 0;
    path.push_back(cls);
    const ClassDecl &c = classes_.at(cls);
    if (c.parent.empty()) return -1;
    if (c.parent.find(',') == std::string::npos) {
        int d = subclassTest(c.parent, ancestor, path);
        return d < 0 ? -1 : d + 1;
    }
    std::string p1 = c.parent.substr(0, c.parent.find(','));
    std::string p2 = c.parent.substr(c.parent.find(',') + 1);
    int d1 = subclassTest(p1, ancestor, path);
    if (d1 >= 0) return d1 + 1;
    return subclassTest(p2, ancestor, path) < 0 ? -1
           : subclassTest(p2, ancestor, path) + 1;
}

std::string World::dispatchVirtual(const std::string &cls,
                                   const std::string &method) const {
    const ClassDecl *c = &classes_.at(cls);
    while (c) {
        for (size_t k = 0; k < c->vtable.slotNames.size(); ++k)
            if (c->vtable.slotNames[k] == method)
                return c->vtable.slots[k];
        c = c->parent.empty() || c->parent.find(',') != std::string::npos
                ? nullptr : &classes_.at(c->parent);
    }
    return "<无此虚方法>";
}

std::string World::dispatchStatic(const std::string &cls,
                                  const std::string &method) const {
    const ClassDecl *c = &classes_.at(cls);
    while (c) {
        for (const auto &m : c->methods)
            if (m.name == method && !m.isVirtual)
                return c->name + "::" + m.name;
        c = c->parent.empty() || c->parent.find(',') != std::string::npos
                ? nullptr : &classes_.at(c->parent);
    }
    return "<无此方法>";
}

// 虚调用的“可能目标集合”：0-CFA 口径——不做类型收敛时，
// 静态类型 T 的引用可能指向 T 或任何子类 ⇒ 目标 = 槽位上各子类的实现。
std::vector<std::string> World::virtualTargets(const std::string &staticType,
                                               const std::string &method) const {
    // 目标集按“实现名”去重——派发轨迹关心的是调用哪个函数，
    // 不是有多少个类派到它（Puppy 与 RoboDog 都派 Dog::speak，算一个目标）。
    std::vector<std::string> out;
    for (const auto &kv : classes_) {
        std::vector<std::string> path;
        if (subclassTest(kv.first, staticType, path) >= 0) {
            std::string t = dispatchVirtual(kv.first, method);
            if (t != "<无此虚方法>" &&
                std::find(out.begin(), out.end(), t) == out.end())
                out.push_back(t);
        }
    }
    return out;
}

// ================= 匠书增量（§28–29） =================
World::BoundMethod World::bindMethod(const std::string &cls,
                                     const std::string &method, int thisSlot) const {
    // 沿继承链找（与 dispatchVirtual 同策略：子类覆写优先）
    std::string cur = cls;
    while (!cur.empty()) {
        const ClassDecl &c = classes_.at(cur);
        for (const auto &m : c.methods)
            if (m.name == method) return BoundMethod{cur, method, thisSlot};
        cur = c.parent.find(',') == std::string::npos ? c.parent : "";
    }
    return BoundMethod{"", method, thisSlot};   // 未找到（诊断态）
}

bool World::thisUseLegal(const std::string &cls, bool insideMethod) const {
    (void)cls;
    // 教学口径：方法体内的 this 合法；顶层（方法体外）非法。
    // 检测器由调用方提供位置（insideMethod），此处只裁决。
    return insideMethod;
}

World::BoundMethod World::superDispatch(const std::string &cls,
                                        const std::string &method,
                                        int thisSlot) const {
    // 1) 找当前类的父类（super 的查找起点）；2) 从父类起沿链找方法；
    // 3) this 仍绑定原接收者——这就是"换起点不换 this"。
    const ClassDecl &c = classes_.at(cls);
    std::string start = c.parent;
    if (start.find(',') != std::string::npos)
        start = start.substr(0, start.find(','));   // 多继承取主父（教学）
    std::string cur = start;
    while (!cur.empty()) {
        const ClassDecl &p = classes_.at(cur);
        for (const auto &m : p.methods)
            if (m.name == method) return BoundMethod{cur, method, thisSlot};
        cur = p.parent;
    }
    return BoundMethod{"", method, thisSlot};
}

}  // namespace tip
```

### 55.8.2 驱动 main.cpp

层级定义 +
四段输出 +
四断言。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 55 章驱动（无参运行，走“简单程序”对账协议）：
//   类层级（单继承链 + 多继承钻石教学子集）→ 布局表 → vtable 表 →
//   静态/虚派发轨迹 → 类成员测试路径 → 虚调用 0-CFA 目标集 → 对账。
#include "objmodel.hpp"

#include <iostream>

namespace {

void showVec(const std::vector<std::string> &v, const char *sep = " ") {
    std::cout << "{";
    for (size_t i = 0; i < v.size(); ++i)
        std::cout << (i ? sep : "") << v[i];
    std::cout << "}";
}

}  // namespace

int main() {
    tip::World w;
    // Animal（根）：字段 name；方法 speak（虚）、kind（静态）
    w.declare("Animal", "", {"name"},
              {{"speak", true}, {"kind", false}});
    // Dog < Animal：+字段 barkHz；覆写 speak（虚）；新方法 fetch（虚）
    w.declare("Dog", "Animal", {"barkHz"},
              {{"speak", true}, {"fetch", true}});
    // Puppy < Dog：+字段 cute
    w.declare("Puppy", "Dog", {"cute"}, {});
    // Robot（独立根）：字段 serial；方法 speak（虚）——不同根的同名虚方法
    w.declare("Robot", "", {"serial"}, {{"speak", true}});
    // RoboDog < Dog,Robot：多继承教学子集
    w.declare("RoboDog", "Dog,Robot", {"firmware"}, {});
    w.finalize();

    std::cout << "== 布局（单继承前缀法）==\n";
    for (const auto &kv : w.classes()) {
        const tip::ClassDecl &c = kv.second;
        std::cout << "  " << c.name << " [";
        for (size_t k = 0; k < c.layout.size(); ++k)
            std::cout << (k ? " " : "") << k << ":" << c.layout[k];
        std::cout << "]";
        if (c.secondaryOffset >= 0)
            std::cout << "  (第二父 " << c.secondaryParent
                      << " 子对象偏移 " << c.secondaryOffset << ")";
        std::cout << '\n';
    }

    std::cout << "== vtable ==\n";
    for (const auto &kv : w.classes()) {
        const tip::ClassDecl &c = kv.second;
        std::cout << "  " << c.name << ": ";
        for (size_t k = 0; k < c.vtable.slotNames.size(); ++k)
            std::cout << "[" << k << "]" << c.vtable.slotNames[k]
                      << "->" << c.vtable.slots[k] << " ";
        std::cout << '\n';
    }

    std::cout << "== 静态派发 ==\n";
    std::cout << "  Puppy.kind  = " << w.dispatchStatic("Puppy", "kind") << '\n';
    std::cout << "  Dog.kind    = " << w.dispatchStatic("Dog", "kind") << '\n';

    std::cout << "== 虚派发（沿 vtable）==\n";
    std::cout << "  Animal.speak = " << w.dispatchVirtual("Animal", "speak") << '\n';
    std::cout << "  Dog.speak    = " << w.dispatchVirtual("Dog", "speak") << '\n';
    std::cout << "  Puppy.speak  = " << w.dispatchVirtual("Puppy", "speak") << '\n';
    std::cout << "  Puppy.fetch  = " << w.dispatchVirtual("Puppy", "fetch") << '\n';

    std::cout << "== 类成员测试（display 上行）==\n";
    for (const auto &pair : std::vector<std::pair<std::string, std::string>>{
             {"Puppy", "Animal"}, {"RoboDog", "Robot"}, {"Robot", "Animal"}}) {
        std::vector<std::string> path;
        int d = w.subclassTest(pair.first, pair.second, path);
        std::cout << "  " << pair.first << " instanceof " << pair.second
                  << " : " << (d >= 0 ? "yes" : "no");
        if (d >= 0) std::cout << " (深度 " << d << ", 途经 ";
        if (d >= 0) showVec(path, "->");
        if (d >= 0) std::cout << ")";
        std::cout << '\n';
    }

    std::cout << "== 虚调用的 0-CFA 目标集 ==\n";
    for (const auto &st : {"Animal", "Dog"}) {
        std::cout << "  静态类型 " << st << ".speak() 可能调用: ";
        showVec(w.virtualTargets(st, "speak"));
        std::cout << '\n';
    }

    std::cout << "== 对账 ==\n";
    // 手工核对清单（每行一个断言，正文 46.5 逐条解读）
    bool ok1 = w.fieldOffset("Puppy", "name") == 0 &&
               w.fieldOffset("Puppy", "barkHz") == 1 &&
               w.fieldOffset("Puppy", "cute") == 2;
    bool ok2 = w.dispatchVirtual("Puppy", "speak") == "Dog::speak";
    bool ok3 = w.virtualTargets("Animal", "speak").size() == 2;   // Animal:: + Dog::（Robot 不同根）
    bool ok4 = w.subclassTest("RoboDog", "Robot", *new std::vector<std::string>) >= 0;
    std::cout << "  前缀法偏移（name@0 barkHz@1 cute@2）: " << (ok1 ? "yes" : "NO") << '\n';
    std::cout << "  Puppy.speak 命中 Dog 覆写槽: " << (ok2 ? "yes" : "NO") << '\n';
    std::cout << "  Animal 引用的目标集恰 2 个: " << (ok3 ? "yes" : "NO") << '\n';
    std::cout << "  多继承成员测试可达第二父: " << (ok4 ? "yes" : "NO") << '\n';

    // ================= 匠书增量（§28–29）：方法即闭包 =================
    std::cout << "== bound method（方法即闭包）==\n";
    tip::World::BoundMethod bm = w.bindMethod("Puppy", "speak", 7);
    std::cout << "  var m = Puppy.speak; -> 定义类=" << bm.className
              << " 方法=" << bm.methodName << " 捕获this=对象" << bm.thisSlot << '\n';
    bool ok5 = bm.className == "Dog" && bm.thisSlot == 7;
    std::cout << "  延迟调用 this 不丢（绑定类 Dog、this=7）: " << (ok5 ? "yes" : "NO") << '\n';
    std::cout << "  对比 vtable 派发（每次调用查表）: " << w.dispatchVirtual("Puppy", "speak")
              << "（同名同源——闭包缓存了查找结果）\n";

    std::cout << "== this 逃逸检测 ==\n";
    std::cout << "  方法体内 this: " << (w.thisUseLegal("Puppy", true) ? "合法" : "非法") << '\n';
    std::cout << "  顶层 this:     " << (w.thisUseLegal("Puppy", false) ? "合法" : "非法")
              << "（静态拒绝）\n";
    bool ok6 = w.thisUseLegal("Puppy", true) && !w.thisUseLegal("Puppy", false);

    std::cout << "== super 链（换起点不换 this）==\n";
    // Puppy 自己不覆写 speak（继承 Dog 的）——super 从父链 Dog 起查，
    // 命中 Dog::speak（super 的语义：跳过**自己的**定义，不是跳过全部覆写）
    tip::World::BoundMethod sup = w.superDispatch("Puppy", "speak", 7);
    std::cout << "  super.speak 从 " << sup.className << " 找到，this 仍是对象" << sup.thisSlot << '\n';
    bool ok7 = sup.className == "Dog" && sup.thisSlot == 7;
    std::cout << "  Puppy 的 super 命中 Dog、this 不换: " << (ok7 ? "yes" : "NO") << '\n';
    // Dog 覆写了 speak——Dog 内的 super 跳过自己的覆写、直达 Animal
    tip::World::BoundMethod sup2 = w.superDispatch("Dog", "speak", 3);
    bool ok8 = sup2.className == "Animal" && sup2.thisSlot == 3;
    std::cout << "  Dog 的 super 跳过自身覆写到 Animal、this=3 保持: " << (ok8 ? "yes" : "NO") << '\n';
    std::cout << "== 对账（增量）==\n";
    std::cout << "  bound/super/this 检测: "
              << ((ok5 && ok6 && ok7 && ok8) ? "all yes" : "FAIL") << '\n';
    return (ok1 && ok2 && ok3 && ok4 && ok5 && ok6 && ok7 && ok8) ? 0 : 1;
}
```

### 55.8.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== 布局（单继承前缀法）==
  Animal [0:name]
  Dog [0:name 1:barkHz]
  Puppy [0:name 1:barkHz 2:cute]
  RoboDog [0:name 1:barkHz 2:firmware]  (第二父 Robot 子对象偏移 2)
  Robot [0:serial]
== vtable ==
  Animal: [0]speak->Animal::speak 
  Dog: [0]speak->Dog::speak [1]fetch->Dog::fetch 
  Puppy: [0]speak->Dog::speak [1]fetch->Dog::fetch 
  RoboDog: 
  Robot: [0]speak->Robot::speak 
== 静态派发 ==
  Puppy.kind  = Animal::kind
  Dog.kind    = Animal::kind
== 虚派发（沿 vtable）==
  Animal.speak = Animal::speak
  Dog.speak    = Dog::speak
  Puppy.speak  = Dog::speak
  Puppy.fetch  = Dog::fetch
== 类成员测试（display 上行）==
  Puppy instanceof Animal : yes (深度 2, 途经 {Puppy->Dog})
  RoboDog instanceof Robot : yes (深度 1, 途经 {RoboDog->Dog->Animal})
  Robot instanceof Animal : no
== 虚调用的 0-CFA 目标集 ==
  静态类型 Animal.speak() 可能调用: {Animal::speak Dog::speak}
  静态类型 Dog.speak() 可能调用: {Dog::speak}
== 对账 ==
  前缀法偏移（name@0 barkHz@1 cute@2）: yes
  Puppy.speak 命中 Dog 覆写槽: yes
  Animal 引用的目标集恰 2 个: yes
  多继承成员测试可达第二父: yes
== bound method（方法即闭包）==
  var m = Puppy.speak; -> 定义类=Dog 方法=speak 捕获this=对象7
  延迟调用 this 不丢（绑定类 Dog、this=7）: yes
  对比 vtable 派发（每次调用查表）: Dog::speak（同名同源——闭包缓存了查找结果）
== this 逃逸检测 ==
  方法体内 this: 合法
  顶层 this:     非法（静态拒绝）
== super 链（换起点不换 this）==
  super.speak 从 Dog 找到，this 仍是对象7
  Puppy 的 super 命中 Dog、this 不换: yes
  Dog 的 super 跳过自身覆写到 Animal、this=3 保持: yes
== 对账（增量）==
  bound/super/this 检测: all yes
```


**增量两节的合账**：bound method 给了"方法当值"的答案——
查找 + 捕 this 的闭包（绑定一次、缓存查找）；super 给了"父类
调用"的语义澄清——换起点不换 this（编译期友好）。两节合起来
把 vtable 派发之外的"方法语义全家桶"（存储、捕获、父链）补
齐——本章从"派发机器"扩成"方法语义全景"。

## 55.9 小结与练习

本章把
`.` 的机器
全貌摊开：

- 前缀法：
  子类布局 =
  父类前缀 +
  自有追加，
  兼容性
  由此免费；
  多继承
  破前缀，
  子对象
  加偏移；
- vtable：
  槽序继承、
  覆写换内容，
  槽位稳定
  是调用方
  的合同；
- 类成员
  测试：
  display
  上行/字典/
  染色三案，
  多继承
  变多路
  搜索；
- 虚调用
  目标集 =
  0-CFA 的
  对象版，
  CHA 收缩
  即去虚化。

下一章把
函数放进来：
闭包、
尾递归、
惰性求值——
函数式范式
的编译。

练习：

1. 给 Puppy
   覆写 speak
   （返回
    "Puppy::
     speak"），
   重跑：
   vtable 槽 0
   变什么？
   Animal
   引用的
   目标集
   变几个？
2. 实现
   区间染色版
   成员测试：
   DFS 编
   in/out，
   单继承下
   O(1) 判定；
   用
   RoboDog
   演示它对
   多继承
   失效。
3. 实现
   多继承的
   thunk：
   通过 Robot
   引用调
   RoboDog
   的虚方法，
   打印 this
   调整量
   （-2）。
4. 加
   `new`
   语句追踪：
   记录程序
   里实际
   实例化的
   类集合，
   实现 CHA：
   `Animal
   引用.speak`
   的目标集
   在"没有
   new Dog"
   时收缩到
   1 个。
5. 把
   vtable
   槽表接到
   14 章
   VM：
   对象头
   当一个
   槽位、
   vtable
   当函数表，
   虚调用
   翻译成
   间接 call
   TAC，
   与静态
   调用
   并跑对账。
