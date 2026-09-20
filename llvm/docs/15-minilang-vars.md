# 15 · 变量与可变状态：alloca 模式

> 对应示例：`examples/15_minilang_vars/`（minilang.cpp v0.4 + test.mini）

SSA 语言的经典难题：**用户眼里的"变量"（可重复赋值）和 IR 眼里的"值"（一次定义）根本不是一回事**。本章落地第 4 章预告的前端策略——可变变量 = 栈槽，然后让 mem2reg 把它变回 phi。这是 clang、rustc 共同的架构选择，MiniLang 到 v0.4 与工业前端完成合流。

## 15.1 var 与赋值：语法层

```text
def sum_to(n) var acc = 0 in (for i = 1, n, 1 in acc = acc + i) * 0 + acc
#               ^引入栈槽      ^循环里赋值累积            ^丢弃 for 值 ^取 acc
var x = 1 in var x = x + 1 in x        # 内层遮蔽外层 → 2
def bump(p) (p = p + 1) * 0 + p        # 参数也可变 → 42
```

- `var a = e1, b = e2 in body`：一次引入一组槽，作用域到 body 结束；
- `x = expr` 是**表达式**（值 = 右侧的值），优先级最低、右结合；
- 迭代 fibi 不再递归——`(t = a + b) * 0 + (a = b) * 0 + (b = t)` 用 `*0` 丢弃中间值串行执行。丑，但诚实（表达式语言没有语句，顺序靠数据依赖）。

## 15.2 前端的统一 alloca 策略

三处改动，全部指向同一条不变式：**NamedValues 里存的都是栈槽指针**。

```cpp
// ① 入口 alloca 工具：插在函数入口块最前（循环内申请也安全）
static AllocaInst *CreateEntryBlockAlloca(Function *F, const std::string &Name) {
  BasicBlock &Entry = F->getEntryBlock();
  IRBuilder<> TmpB(&Entry, Entry.begin());
  return TmpB.CreateAlloca(DoubleTy, nullptr, Name);
}

// ② 参数入槽：F->args() 每个都 alloca + store
// ③ 变量读改 load：
Value *VariableExprAST::codegen() {
  return Builder->CreateLoad(DoubleTy, NamedValues[Name], Name.c_str());
}

// ④ 赋值表达式：
if (Op == '=') {
  Value *Val = RHS->codegen();
  Builder->CreateStore(Val, NamedValues[LHSE->Name]);
  return Val;                        // 值 = 右侧
}
```

for 循环变量也改走 alloca（v0.2 的 phi 版退役——**前端统一 alloca，phi 统一交给 mem2reg**，分工明确）。唯一保留手写 phi 的是 for 的"结果值"——它不被赋值，phi 是最自然形态。

## 15.3 遮蔽与恢复

`var x = 1 in var x = x+1 in x` 的实现 = **备份-遮蔽-恢复**三拍子：

```cpp
OldBindings[i] = NamedValues.count(Name) ? NamedValues[Name] : nullptr;
NamedValues[Name] = Alloca;      // 遮蔽
... body ...
NamedValues[Name] = OldBindings[i];  // 恢复（或 erase）
```

一套栈式作用域，`var`/`for`/函数参数三个入口共用。

## 15.4 实测：mem2reg 的回报

（`--jit test.mini` 实测输出）：

```text
=> 2.000000e+00      # var 遮蔽
=> 5.050000e+03      # sum_to(100) 迭代版
=> 8.320400e+05      # fibi(30) = fib(30) ✓
=> 4.200000e+01      # bump(41)
==== 15 ok ====
```

对自产 IR 跑 mem2reg 的量化对比（build 脚本自动验证）：

```text
原始 .ll：alloca 11 行
opt -passes=mem2reg 后：alloca 0 行，phi 7 行
```

前端"偷懒"的成本被优化器全额收回——**alloca 是前端的诚实，phi 是优化器的日常**。clang -O0 与 -O2 输出的差异本质就是这一层有没有跑。

## 15.5 赋值解析的右结合特判

`=` 进优先级表（级别 2，最低），但要在爬升循环里特判：

```cpp
if (BinOp == '=')
  RHS = parseExpression();    // a = b = c → a = (b = c)
else
  RHS = parseUnary();
...
if (BinOp != '=' && Prec < NextPrec) { ... }  // '=' 不参与"先结合右边"
```

漏掉第二个条件，`a = b + c` 会被解析成 `(a = b) + c`——赋值结合律的经典坑。

## 15.6 本章小结

- 可变变量 = alloca+load+store；读恒 load、写恒 store、参数入槽——前端无特例。
- 作用域 = NamedValues 的备份-遮蔽-恢复；入口块集中 alloca。
- mem2reg 把 11 个 alloca 洗成 7 个 phi：前端 alloca、优化器 phi 的分层协作。

| 坑 | 解法 |
|---|---|
| 循环内 alloca 爆栈 | CreateEntryBlockAlloca 集中在入口块 |
| `a = b = c` 解析成左结合 | '=' 右结合特判 + 禁止参与右结合递归 |
| 赋值目标不是变量 | dynamic_cast<VariableExprAST*> 检查后报错 |

下一章开放语言的扩展性：让用户自己定义运算符。
