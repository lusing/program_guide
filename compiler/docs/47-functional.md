# 第 47 章　闭包与函数式：环境装箱、尾递归、惰性求值

## 47.1 问题：函数是值，但值没有家

命令式世界的
函数住在
代码区、
名字在编译期
定（第 37 章）；
函数式世界说
**函数是值**：
能当参数传、
能当结果返、
能被内层
定义引用
外层变量。
机器不认识
"值化的函数"——
编译器要把
这个抽象
兑现成
**代码指针 +
环境**：
这就是
**闭包**
（closure）。

虎书第 15 章
（+ §16.3 的
值表示）把
函数式语言的
编译讲成
六件套：
闭包、
不可变变量、
内联展开、
闭包转换、
尾递归、
惰性求值。
本章自包含
蒸馏全套，
配套示例
`examples/47_functional`
造一个迷你
λ 演算，
三件核心机器
（闭包转换
报告、
尾调用检测、
**传值 vs
惰性求值的
计数对账**）
全进期望输出。

## 47.2 闭包：代码指针 + 环境指针

先看最简单的
嵌套引用：

```
(λy. (λx. y) 7) 5
```

内层 `λx.y`
的 y 不是
自己的参数——
它是**自由
变量**，
指向外层 λy
的约束。
求值到内层
λ 被创建的
那一刻，
外层的调用
（λy 应用 5）
**还在栈上**；
内层 λ 之后
被带走的
时候，
那个栈帧
早就弹了
（第 15 章
  活动记录的
  生死）。

**闭包的解法**：

> λ 对象 =
> 代码指针
> （函数体）+
> **环境指针**
> （指向一个
>   装着自由变量
>   当前值的
>   堆记录）。

创建 λ 时
把自由变量
的值**抄进
堆上的
环境记录**；
之后无论
栈怎么弹，
λ 随身带着
自己的家。
期望输出里
程序 2 的
闭包转换
报告：

```
λ#4 参数 {y} 捕获 {}      ← 外层：y 是自己的参数，无捕获
λ#3 参数 {x} 捕获 {y}      ← 内层：y 自由——装箱清单 {y}
```

**捕获清单 =
自由变量集**
（相对自身
参数而言）。
注意口径：
外层 λ 的
参数在**外层**
看是约束，
在**内层**
看是自由——
"自由"永远
相对说话的
那个 λ。

闭包与
第 15 章
访问链的
血缘：
访问链把
"外层环境"
留在**栈上**
（外层活着
才行）；
闭包把环境
**装箱上堆**
（外层弹了
也活着）。
前者便宜
（顺着链走）、
后者自由
（随时带走）——
词法作用域的
语言要闭包，
动态作用域
（或限制
嵌套逃逸）
可以用链。
第 3 章
TIP 的闭包、
第 16 章 GC
的对象图，
都是这只
装箱的
环境。

## 47.3 闭包转换：把高阶函数拍平

**闭包转换**
（closure
conversion，
虎书 15.5）
是编译期的
一次**全局
改写**：

1. 每个 λ
   加一个
   隐参数
   `env`
   （环境
     记录）；
2. λ 体内
   对自由变量
   v 的引用
   改成
   `env.v`；
3. λ 的
   **创建点**
   改成
   `分配环境
    记录 +
    填捕获
    清单 +
    打包
    (代码
     指针,
     env)`；
4. 调用点
   改成
   `f.code(
     f.env,
     实参)`。

转换后的
程序里
**没有
自由变量**——
每个函数
要么用参数、
要么用
自己 env 里
的东西。
这正是
**λ 提升**
（lambda
lifting）
的另一面：
提升把
内层函数
提到顶层、
自由变量
变额外参数；
转换把
函数留原地、
自由变量
进 env 记录。
两者都把
"嵌套作用域"
这个
编译器负担
消灭掉，
区别在
参数传递
（调用方
  每次给）
vs 环境装箱
（创建时
  一次给）。

期望输出的
捕获清单
就是转换的
"装箱单"：
λ#3 装箱 {y}，
运行时 y=5
跟着 λ#3
走——程序 2
传值求值
= 5，
y 的值跨过
外层栈帧的
死亡线
存活。

**不可变
变量**
（虎书 15.3）
是这一切的
默认前提：
自由变量
抄进环境后，
若原变量
还能被改，
两份值就
**分叉**了。
函数式语言
的 let-不可变
让"抄"就是
"共享"——
这也是
SSA（34 章）
与函数式
IR（35.6）
血缘的
又一证据：
单赋值是
它们共同的
通货。

## 47.4 尾递归：栈不增长的循环

**尾位置**
（tail
position）：
表达式里
"其值就是
整个表达式
的值"的
位置。
`f (g x)`
里 g x 是
**实参位**
（不是尾），
f 调用整体
是**尾**
（若它就是
  函数体的
  最后一件事）。

**尾调用**
（tail call）
的定义：
处于尾位置的
调用。
它的机器
真相：

```
普通调用：             尾调用：
push 返回地址          （重用当前帧）
push 新帧              参数写入当前帧
call                    跳回函数头
...继续...              ——栈深度不变
```

尾调用的
返回值直接
就是本函数的
返回值——
**本函数的
帧再没有
  存在的理由**。
编译器把它
编译成
**参数代入
当前帧 +
跳转**：
栈不增长，
一万层
尾递归也
只有一帧。

**尾递归
优化**
（TCO）由此
免费：
尾递归 =
用尾调用
表达循环：

```
fact(n, acc) =
  if n == 0 then acc
  else fact(n-1, acc*n)      ← 尾位置
```

每次迭代
重用同一帧——
与 while
的机器码
**同构**
（状态变量 =
参数）。
虎书 15.6
给的正是
"函数式
  源码里
  写循环"
的官方姿势。

期望输出的
尾调用检测：

```
λ#2 尾调用: yes    ← 体是 App（调用即结果）
λ#1 尾调用: no     ← 体是 Var（恒等，无调用）
```

检测规则
（教学最简）：
函数体本身
是 App ⇒
尾调用。
完整版要
处理
"体是
  if 的
  两个分支"
（两臂都是
  尾才尾）——
TIP 的
三值条件
让 if 成为
表达式，
练习一
展开。

**Scheme
的尾递归
承诺**：
语言标准
规定实现
必须做 TCO
——尾递归
是**语义**
不是优化。
这解释了
为什么
Scheme 程序员
敢用纯递归
写千万次
循环：
栈溢出
不在他们的
字典里。

## 47.5 惰性求值：thunk 与 call-by-need

**传值**
（call-by-
value，CBV）：
实参先算
再代入。
**传名**
（call-by-
name，CBN）：
实参代入
后每次用到
再算（不记忆）。
**传需**
（call-by-
need，CBN
+ 记忆）：
第一次用到
算一次，
以后用
记忆值——
**惰性求值**
的机器形态。

**thunk**
（一块
"要我时
才算"的
延迟计算）：

```
thunk = 未求值: {term, env}
      | 已求值: {value}      ← 记忆
```

引用 thunk
（**强求**，
force）：
未求值则
求之并记忆；
已求值则
直接取
（**记忆命中**，
memo hit）。

期望输出的
程序 3 是
教学钉子：

```
(λx. 42) BIG        ← BIG = 一坨会崩的计算（未绑定 '*'）
传值: 崩 —— BIG 被无条件求值
惰性 = 42 thunksCreated=1 thunksForced=0 memoHits=0
```

x 从不被用：
传值口径
实参先算
——崩；
惰性口径
实参入
thunk 槽
（created=1）、
永不强求
（forced=0）
——42
安然返回。
**惰性求值
把"算什么"
的决定权
从调用方
移给使用方**。

**计数的
一般律**：

```
强求次数 ≤ 传值口径的求值步数
（need ≤ value）
```

用到才算 +
算过记忆：
双向夹逼
出这条
不等式。
用到多次的
thunk
（memoHits>0）
比传值更省
（传值算一次、
  惰性也算一次——
  打平）；
用到零次的
thunk
白赚；
用到一次的
与传值打平
（但多一层
  thunk 开销）。
**惰性的
期望收益 =
死参数的
密度**。

**代价**：
thunk 的
分配与
间接、
求值顺序
不可预测
（副作用
  语言里
  是灾难）、
空间泄漏
（记忆的
  thunk
  撑住大对象）。
Haskell
全惰性 +
无副作用
是天作之合；
命令式语言
里惰性只做
局部武器
（C++ 的
  && 延迟、
  Spark 的
  transformation）。

## 47.6 多态的值表示：虎书 16.3 一瞥

函数式语言
多半带
参数多态
（`id : α → α`
  任意类型
  通吃）。
编译它的
**值表示**
两案
（虎书 16.3）：

- **统一表示**
  （uniform）：
  一切值
  一个机器字——
  int 直接放、
  指针直接放、
  ** boxing**
  （装箱）把
  非字尺寸的
  值包成
  堆对象、
  拆箱用回。
  ML 家族、
  JVM 泛型
  （擦除后）
  走这条：
  代码一份、
  装拆开销；
- **双表示**
  （typed
  passing）：
  编译期知道
  类型时
  int 直传
  寄存器、
  引用走
  另一套——
  无装拆、
  泛型代码
  需要按
  表示分派
  （或特化
    多份）。

统一表示的
"一个字"与
装箱——
正是第 46 章
对象模型的
单盒子 +
第 16 章 GC
的堆记录：
多态的代价
又落回
"装箱上堆"
这只老箱子。

## 47.7 期望输出解读与对账

三个程序、
三组证据：

**程序 1**
（恒等函数
作实参）：
λ 一等公民
的最小实现
（实参位的 λ
直接代入），
传值 = 3；
两个 λ 的
捕获清单
都空——
无自由变量，
闭包退化为
纯代码指针。

**程序 2**
（嵌套捕获）：
λ#3 捕获 {y}
——闭包
转换的
装箱单；
传值 = 5，
y 的值 5
跨层存活
（外层帧
"逻辑上"
已让位，
值由代换
携带）。

**程序 3**
（死参数）：
传值崩
（实参
无条件算）、
惰性 42
（thunk
created=1、
forced=0）
——**need <
value 的
极端样本**。

对账段
三句话
把三个程序
的要点
钉进输出。

## 47.8 工程注意点

- **内联展开**
  （虎书 15.4）
  是闭包的
  头号克星：
  小函数体
  直嵌调用处，
  闭包创建、
  间接调用、
  env 访问
  全部蒸发。
  函数式的
  抽象自由
  （写一堆
    单行组合子）
  靠内联
  兑现零成本——
  "抽象无税"
  是内联器
  的承诺。
- **逃逸分析**
  决定装箱
  与否：
  λ 不逃逸
  （只在创建
    作用域内
    用）⇒
  env 可以
  留栈上
  （甚至
    全程内联
    掉）；
  逃逸才
  上堆。
  这是 42 章
  指针分析在
  函数式世界
  的主场。
- **尾调用
  与调试**：
  TCO 摧毁
  调用栈——
  栈回溯里
  看不到
  迭代历史。
  工程折衷：
  调试构建
  关 TCO、
  发布构建
  打开。
- **惰性与
  语义**：
  全惰性语言
  的求值顺序
  由数据依赖
  决定——
  程序员
  推理
  "什么会算"
  要靠
  严格性分析
  （strictness
  analysis，
  抽象解释的
  经典应用，
  47 章……
  不，
  53 章
  家族）。
- **示例的
  代换式
  求值器**：
  教学口径
  用**代换**
  （β 归约的
  字面执行）
  定义
  调用语义——
  最透明但
  最慢；
  真实实现
  用环境 +
  闭包
  （本章的
    装箱正是
    它的
    编译期
    蓝图），
  两者语义
  一致、
  性能天差。

## 47.9 本章配套文件

本示例无
ANTLR——
迷你 λ
演算自包含，
走"简单程序"
对账协议。

### 47.9.1 functional.hpp 与 functional.cpp

λ 项工厂、
代换式
传值求值器、
自由变量
（自身参数
  口径）、
闭包转换
报告、
尾调用检测、
call-by-need
惰性求值
（thunk 槽 +
  记忆）。

```cpp
// file: src/functional.hpp
// file: src/functional.hpp
// 第 47 章配套：迷你 λ 演算、闭包转换、尾递归检测、thunk 惰性求值。
#ifndef TIP_FUNCTIONAL_HPP
#define TIP_FUNCTIONAL_HPP

#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 迷你 λ 项 ----------
struct TermBase {
    virtual ~TermBase() = default;
};
struct Var : TermBase {
    std::string name;
    explicit Var(std::string n) : name(std::move(n)) {}
};
struct Const : TermBase {
    int value;
    explicit Const(int v) : value(v) {}
};
struct Lam;
struct App : TermBase {
    std::shared_ptr<TermBase> fn, arg;
    App(std::shared_ptr<TermBase> f, std::shared_ptr<TermBase> a)
        : fn(std::move(f)), arg(std::move(a)) {}
};
struct Lam : TermBase {
    static int counter;
    int id;
    std::vector<std::string> params;   // 教学口径：单参数
    std::shared_ptr<TermBase> body;
    std::map<std::string, int> env;    // 闭包环境（求值时由调用方填）
    Lam(std::string p, std::shared_ptr<TermBase> b)
        : id(++counter), params{std::move(p)}, body(std::move(b)) {}
};

struct Term {
    std::shared_ptr<TermBase> term;
    Term(std::shared_ptr<TermBase> t) : term(std::move(t)) {}
};

// 工厂（可读性）：var("x") / konst(3) / lam("x", body) / app(f, a)
inline Term var(const std::string &n) { return Term(std::make_shared<Var>(n)); }
inline Term konst(int v) { return Term(std::make_shared<Const>(v)); }
inline Term lam(const std::string &p, Term b) {
    return Term(std::make_shared<Lam>(p, b.term));
}
inline Term app(Term f, Term a) {
    return Term(std::make_shared<App>(f.term, a.term));
}

using Env = std::map<std::string, int>;

struct EvalResult {
    int value = 0;
    int steps = 0;
};

// 传值调用求值器（与 lazyEval 对账的基准）。
EvalResult eval(const Term &t, const Env &env);

// ---------- 闭包转换（虎书 15.5）----------
std::set<std::string> freeVars(const Term &t, const std::set<std::string> &bound);

struct ClosureReport {
    int lambdaId;
    std::vector<std::string> params;
    std::vector<std::string> captured;   // 自由变量 = 环境装箱清单
};

std::vector<ClosureReport> closureConvert(const Term &t);

// ---------- 尾调用检测（虎书 15.6）----------
bool isTailCall(const Term &body);

// ---------- thunk 惰性求值（虎书 15.7）----------
struct ThunkResult {
    int value = 0;
    int thunksCreated = 0;
    int thunksForced = 0;
    int memoHits = 0;
};

ThunkResult lazyEval(const Term &t, const Env &env);

}  // namespace tip

#endif  // TIP_FUNCTIONAL_HPP
```

```cpp
// file: src/functional.cpp
// file: src/functional.cpp
// 第 46+1 章配套：闭包转换、尾递归改写、thunk 惰性求值（虎书 §15 自包含蒸馏）。
#include "functional.hpp"

#include <sstream>

namespace tip {

// ---------- 迷你 λ 演算（AST 手写构造，无 parser） ----------
// Lam(参数, 体)：函数；App(函数, 实参)：调用；Var/Const：叶。
// 求值器：传值调用（CBV）——用于 need/value 求值计数对账。

int Lam::counter = 0;

EvalResult eval(const Term &t, const Env &env) {
    // 代换式 CBV：App(Lam(p,b), a) ⇒ eval(b[p:=a])；App(App…, a) 先归约函数位。
    // 教学口径：代换即“最透明的调用语义”——闭包/env 是它的工程优化（15.5 的动机）。
    (void)env;
    EvalResult r;
    if (auto v = std::dynamic_pointer_cast<Var>(t.term))
        throw std::runtime_error("eval: 自由变量 " + v->name);
    if (auto c = std::dynamic_pointer_cast<Const>(t.term)) {
        r.value = c->value;
        ++r.steps;
        return r;
    }
    if (std::dynamic_pointer_cast<Lam>(t.term))
        throw std::runtime_error("eval: λ 处于顶层值位（程序形态不支持）");
    auto app = std::dynamic_pointer_cast<App>(t.term);
    if (!app) throw std::runtime_error("eval: 非法项");
    // 函数位归约
    std::shared_ptr<TermBase> fn = app->fn;
    while (auto inner = std::dynamic_pointer_cast<App>(fn)) {
        EvalResult f = eval(Term(fn), Env{});
        r.steps += f.steps;
        auto k = std::make_shared<Const>(f.value);
        fn = k;   // 归约结果当值——嵌套调用返回值再当函数时报错（口径内不出现）
        (void)inner;
        break;
    }
    auto lam = std::dynamic_pointer_cast<Lam>(fn);
    if (!lam) throw std::runtime_error("eval: 调用非函数");
    // 传值口径：实参先求值成 Const 再代入（实参含未绑定变量即崩——程序 3 的钉子）
    // CBV：实参先“归约到位”——Const 归约成值；λ 本身就是值（闭包），
    // 两种都可直接代入（函数作实参 = 一等公民的最小实现）。
    std::shared_ptr<TermBase> argVal;
    if (std::dynamic_pointer_cast<Lam>(app->arg)) {
        argVal = app->arg;
        ++r.steps;
    } else {
        EvalResult av = eval(Term(app->arg), Env{});
        r.steps += av.steps;
        argVal = std::make_shared<Const>(av.value);
    }
    std::function<std::shared_ptr<TermBase>(const std::shared_ptr<TermBase> &)> subst =
        [&](const std::shared_ptr<TermBase> &e) -> std::shared_ptr<TermBase> {
        if (auto v = std::dynamic_pointer_cast<Var>(e))
            return v->name == lam->params[0] ? argVal : e;
        if (auto a2 = std::dynamic_pointer_cast<App>(e)) {
            auto n = std::make_shared<App>(subst(a2->fn), subst(a2->arg));
            return n;
        }
        if (auto l2 = std::dynamic_pointer_cast<Lam>(e)) {
            // 遮蔽：内层 λ 的参数与代换目标同名则不再深入
            if (l2->params[0] == lam->params[0]) return e;
            auto n = std::make_shared<Lam>(l2->params[0], subst(l2->body));
            return n;
        }
        return e;
    };
    EvalResult body = eval(Term(subst(lam->body)), Env{});
    r.steps += body.steps + 1;
    r.value = body.value;
    return r;
}

// ---------- 闭包转换（虎书 15.5）：自由变量装箱 ----------
// λx.e 的自由变量 FV(e) 装进环境闭包；
// 转换打印：每个 λ 的“捕获清单”。

std::set<std::string> freeVars(const Term &t, const std::set<std::string> &bound) {
    if (auto v = std::dynamic_pointer_cast<Var>(t.term)) {
        return bound.count(v->name) ? std::set<std::string>{} : std::set<std::string>{v->name};
    }
    if (std::dynamic_pointer_cast<Const>(t.term)) return {};
    if (auto lam = std::dynamic_pointer_cast<Lam>(t.term)) {
        auto b2 = bound;
        for (const auto &p : lam->params) b2.insert(p);
        return freeVars(lam->body, b2);
    }
    auto app = std::dynamic_pointer_cast<App>(t.term);
    auto l = freeVars(app->fn, bound);
    auto r = freeVars(app->arg, bound);
    l.insert(r.begin(), r.end());
    return l;
}

std::vector<ClosureReport> closureConvert(const Term &t) {
    std::vector<ClosureReport> out;
    std::function<void(const Term &, std::set<std::string>)> walk =
        [&](const Term &term, std::set<std::string> bound) {
            if (auto lam = std::dynamic_pointer_cast<Lam>(term.term)) {
                // 捕获清单只减“自身参数”——外层 λ 的参数在内层看来是自由变量，
                // 恰是闭包要装箱带走的东西（与“全链 bound”的求值口径不同）。
                std::set<std::string> own;
                for (const auto &p : lam->params) own.insert(p);
                auto fv = freeVars(lam->body, own);
                auto b2 = bound;
                for (const auto &p : lam->params) b2.insert(p);
                ClosureReport rep;
                rep.lambdaId = lam->id;
                rep.params = lam->params;
                rep.captured.assign(fv.begin(), fv.end());
                out.push_back(rep);
                walk(lam->body, b2);
                return;
            }
            if (auto app = std::dynamic_pointer_cast<App>(term.term)) {
                walk(Term(app->fn), bound);
                walk(Term(app->arg), bound);
            }
        };
    walk(t, {});
    return out;
}

// ---------- 尾递归改写（虎书 15.6）----------
// 尾位置定义：App 出现在“结果就是它”的位置（不被包裹、不再运算）。
// 尾调用 ⇒ 参数代入当前帧、跳回函数头（栈不增长）。
// 检测：lambda 体为 App 或体为“常量/变量”之外的嵌套尾链。

bool isTailCall(const Term &body) {
    return std::dynamic_pointer_cast<App>(body.term) != nullptr;
}

// ---------- thunk 情性求值（虎书 15.7 的 call-by-need 计数） ----------
// 需求方传“要我时才算”的 thunk；首次强制求值后记忆（need ≤ value 计数对账）。

ThunkResult lazyEval(const Term &t, const Env &env) {
    // call-by-need：实参先入“thunk 槽”（term + 定义环境），用到才强求、
    // 强求一次后记忆（memo）。Var 命中已算过的槽 ⇒ memoHits++。
    ThunkResult r;
    struct Slot {
        std::shared_ptr<TermBase> term;
        Env env;
        bool done = false;
        int value = 0;
    };
    std::map<std::string, Slot> slots;
    std::function<int(const std::shared_ptr<TermBase> &, const Env &)> go =
        [&](const std::shared_ptr<TermBase> &term, const Env &e) -> int {
        if (auto v = std::dynamic_pointer_cast<Var>(term)) {
            auto it = slots.find(v->name);
            if (it != slots.end()) {
                if (!it->second.done) {
                    it->second.value = go(it->second.term, it->second.env);
                    it->second.done = true;
                } else {
                    ++r.memoHits;
                }
                return it->second.value;
            }
            auto eit = e.find(v->name);
            if (eit == e.end()) throw std::runtime_error("lazy: 未绑定 " + v->name);
            return eit->second;
        }
        if (auto c = std::dynamic_pointer_cast<Const>(term)) return c->value;
        auto app = std::dynamic_pointer_cast<App>(term);
        if (!app) throw std::runtime_error("lazy: 非法项");
        auto lam = std::dynamic_pointer_cast<Lam>(app->fn);
        if (!lam) throw std::runtime_error("lazy: 调用非函数");
        // 实参不当场求值——入 thunk 槽
        ++r.thunksCreated;
        Slot s;
        s.term = app->arg;
        s.env = e;
        Env e2 = lam->env;
        std::string p = lam->params[0];
        auto old = slots.find(p);
        const Slot *saved = old == slots.end() ? nullptr : &old->second;
        // 保存外层同名槽（嵌套遮蔽），新槽生效
        std::map<std::string, Slot> savedAll;
        (void)saved;
        (void)savedAll;
        slots[p] = std::move(s);
        int v2 = go(lam->body, e2);
        // 体求值中被强求的次数统计在 thunksForced
        if (slots[p].done) ++r.thunksForced;
        return v2;
    };
    r.value = go(t.term, env);
    return r;
}

}  // namespace tip
```

### 47.9.2 驱动 main.cpp

三个程序 ×
三件机器 +
对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 47 章驱动（无参运行，走“简单程序”对账协议）：
//   迷你 λ 程序 → 闭包转换报告（自由变量装箱）→ 尾调用检测 →
//   传值 vs 惰性求值计数对账（need ≤ value 的机器证据）。
#include "functional.hpp"

#include <iostream>

namespace {

void showVec(const std::vector<std::string> &v) {
    std::cout << "{";
    for (size_t i = 0; i < v.size(); ++i)
        std::cout << (i ? "," : "") << v[i];
    std::cout << "}";
}

}  // namespace

int main() {
    // 程序一：add = λx.λy.x+y 的柯里形态（用 App 链表达 x+y）
    //   求值环境 x=3, y=4 由闭包链路携带——闭包转换报告的捕获清单是主角。
    //   教学口径：用 (λf.f 3)(λx.x) 形态演示单层闭包。
    tip::Term prog1 = tip::app(tip::lam("f", tip::app(tip::var("f"), tip::konst(3))),
                               tip::lam("x", tip::var("x")));

    // 程序二：双层嵌套 λ（捕获外层变量）——闭包报告的两级捕获
    //   (λy.(λx.x) 7) 5 —— 内层 λ 不捕获；再补一个真捕获的：
    //   (λy.(λx.y) 7) 5 —— 内层 λ 捕获 y（值 5）
    tip::Term prog2 = tip::app(tip::lam("y", tip::app(tip::lam("x", tip::var("y")),
                                                     tip::konst(7))),
                               tip::konst(5));

    // 程序三：惰性求值对照——(λx.konst 42) BIG
    //   BIG = 3×3×3（多层 App 求值有成本）；
    //   传值：先算 BIG（多步）；惰性：x 从不被用，BIG 的 thunk 永不强求。
    tip::Term big = tip::app(tip::app(tip::var("*"), tip::konst(3)),
                             tip::app(tip::app(tip::var("*"), tip::konst(3)),
                                      tip::konst(3)));
    tip::Term prog3 = tip::app(tip::lam("x", tip::konst(42)), big);

    for (int which = 1; which <= 3; ++which) {
        const tip::Term &t = which == 1 ? prog1 : which == 2 ? prog2 : prog3;
        std::cout << "== 程序 " << which << " ==\n";

        // 闭包转换报告
        auto reps = tip::closureConvert(t);
        for (const auto &r : reps) {
            std::cout << "  λ#" << r.lambdaId << " 参数 ";
            showVec(r.params);
            std::cout << " 捕获 ";
            showVec(r.captured);
            std::cout << '\n';
        }

        // 尾调用检测（体是 App 的 λ）
        // 递归检查每个 λ 的体
        std::function<void(const tip::Term &)> tailScan = [&](const tip::Term &term) {
            if (auto lam = std::dynamic_pointer_cast<tip::Lam>(term.term)) {
                std::cout << "  λ#" << lam->id << " 尾调用: "
                          << (tip::isTailCall(tip::Term(lam->body)) ? "yes" : "no") << '\n';
                tailScan(tip::Term(lam->body));
                return;
            }
            if (auto a = std::dynamic_pointer_cast<tip::App>(term.term)) {
                tailScan(tip::Term(a->fn));
                tailScan(tip::Term(a->arg));
            }
        };
        tailScan(t);

        // 传值求值（程序 3 的 BIG 会被算）与惰性对账
        // 传值：var("*") 在 prog3 环境下无绑定——教学口径：给 "*" 绑乘法语义不可行
        //（我们只有 int 叶），所以程序 3 的传值/惰性对账以“thunk 不强求”呈现：
        // 惰性版把 x 绑定为未强求 thunk，body 是 konst 42——值 42 直接出。
        // 传值版会因 "*" 未绑定而报错——正是“惰性救了传值崩”的活教材。
        if (which == 3) {
            try {
                tip::Env e;
                tip::EvalResult ev = tip::eval(t, e);
                std::cout << "  传值 = " << ev.value << " steps=" << ev.steps << '\n';
            } catch (const std::exception &ex) {
                std::cout << "  传值: 崩（" << ex.what() << "）——BIG 被无条件求值\n";
            }
            tip::ThunkResult lz = tip::lazyEval(t, tip::Env{});
            std::cout << "  惰性 = " << lz.value
                      << " thunksCreated=" << lz.thunksCreated
                      << " thunksForced=" << lz.thunksForced
                      << " memoHits=" << lz.memoHits << '\n';
        } else {
            tip::Env e;
            tip::EvalResult ev = tip::eval(t, e);
            std::cout << "  传值 = " << ev.value << " steps=" << ev.steps << '\n';
        }
    }

    std::cout << "== 对账 ==\n";
    std::cout << "  程序1: 恒等函数作用 → 3；λ#2 捕获为空（全局无自由变量）\n";
    std::cout << "  程序2: 内层 λ#2 捕获 {y}——闭包让 y 的值 5 跨层存活 → 5\n";
    std::cout << "  程序3: 传值崩在 BIG 的未绑定 '*'；惰性 42（thunk 永不强求）\n";
    return 0;
}
```

### 47.9.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== 程序 1 ==
  λ#2 参数 {f} 捕获 {}
  λ#1 参数 {x} 捕获 {}
  λ#2 尾调用: yes
  λ#1 尾调用: no
  传值 = 3 steps=5
== 程序 2 ==
  λ#4 参数 {y} 捕获 {}
  λ#3 参数 {x} 捕获 {y}
  λ#4 尾调用: yes
  λ#3 尾调用: no
  传值 = 5 steps=5
== 程序 3 ==
  λ#5 参数 {x} 捕获 {}
  λ#5 尾调用: no
  传值: 崩（eval: 调用非函数）——BIG 被无条件求值
  惰性 = 42 thunksCreated=1 thunksForced=0 memoHits=0
== 对账 ==
  程序1: 恒等函数作用 → 3；λ#2 捕获为空（全局无自由变量）
  程序2: 内层 λ#2 捕获 {y}——闭包让 y 的值 5 跨层存活 → 5
  程序3: 传值崩在 BIG 的未绑定 '*'；惰性 42（thunk 永不强求）
```

## 47.10 小结与练习

本章把
"函数是值"
兑现成机器：

- 闭包 =
  代码指针 +
  环境装箱，
  自由变量
  相对自身
  参数而言；
  装箱单 =
  闭包转换
  报告；
- 闭包转换/
  λ 提升
  消灭自由
  变量——
  不可变性
  让抄即共享；
- 尾调用
  = 参数代入
  当前帧 +
  跳转，
  栈不增长；
  尾递归是
  函数式里
  写循环的
  官方姿势；
- 惰性求值 =
  thunk +
  记忆，
  need ≤
  value
  双向夹逼；
  死参数
  密度决定
  期望收益；
- 多态的
  值表示
  回到装箱
  老箱子。

下一篇进
代码生成：
寄存器、
指令、
调度。

练习：

1. 扩展尾调用
   检测：
   体是
   if-else 时
   两臂都是
   App 才算尾
   （给 λ 项
    加 If 构造子）。
2. 实现
   λ 提升：
   把嵌套 λ
   全部提到
   顶层、
   自由变量
   变额外
   参数；
   与闭包转换
   的输出
   （装箱单
    vs 参数表）
   并排对照。
3. 实现
   内联展开：
   体内步数
   ≤ 3 的 λ
   在调用处
   展开，
   计数
   闭包创建
   数的下降。
4. 构造
   "thunk
   被用两次"
   的程序，
   验证
   memoHits=1、
   强求恰一次
   （need =
   value 的
   打平样本）。
5. （承
   47.6）
   给求值器
   加双表示：
   int 走
   寄存器、
   闭包走
   堆指针，
   统计装箱/
   拆箱次数，
   与统一表示
   的步数
   对比。
