# 13 · AST → IR：表达式、if 与 for 的代码生成

> 对应示例：`examples/13_minilang_ir/`（minilang.cpp v0.2 + test.mini）

前端就绪，现在给每个 AST 节点装 `codegen()`——第 8 章的 IRBuilder 技能全部上场。本章的精华在两处：**if 的 phi 合流**和 **for 的 phi 循环**——你会亲眼看到第 4 章手写的 IR 结构被自己的编译器生产出来。

## 13.1 代码生成的全局设施

```cpp
static std::unique_ptr<LLVMContext> TheContext;
static std::unique_ptr<IRBuilder<>> Builder;
static std::unique_ptr<Module> TheModule;
static std::map<std::string, Value *> NamedValues;   // 当前函数内的名字表
```

`NamedValues` 是**作用域的物化**：函数参数进去、函数返回清空。查无此名 = "unknown variable name"——这就是 MiniLang 的"未定义变量检查"。

## 13.2 五个基础节点的 codegen

```cpp
// 数字：常量即值
Value *NumberExprAST::codegen() {
  return ConstantFP::get(Type::getDoubleTy(*TheContext), Val);
}
// 变量：查名字表
Value *VariableExprAST::codegen() {
  auto It = NamedValues.find(Name);
  if (It == NamedValues.end()) return logErrorV("unknown variable name");
  return It->second;
}
// 二元：先编两边再按 op 发射（'<' 要经 fcmp i1 → uitofp double）
// 调用：查函数 → 参数逐个编 → CreateCall
```

`'<'` 的处理揭示了纯 double 语言的内部管道：`fcmp olt` 产出 `i1`，`uitofp` 转回 `double`——布尔就是 0.0/1.0。

**print 内置函数的降级**：`print(x)` 不进符号表，直接翻译成 `printf("%f\n", x)`：

```cpp
if (Callee == "print") {
  ...
  return X;   // print 的值 = 被打印的值（printf 的 i32 不外泄）
}
```

> **实测坑**：最初版本 `return CreateCall(printf...)` 把 i32 当 double 返回，`verifyFunction` 报 `Function return type does not match operand type of return inst!`。**内置函数的返回类型也要守"万物皆 double"的约定**。

## 13.3 if：手写 phi 合流

```cpp
Value *IfExprAST::codegen() {
  Value *CondV = ...;                       // fcmp one != 0.0 得 i1
  BasicBlock *ThenBB = BasicBlock::Create(ctx, "then", F);   // 创建时挂进函数
  BasicBlock *ElseBB = BasicBlock::Create(ctx, "else", F);
  BasicBlock *MergeBB = BasicBlock::Create(ctx, "ifcont", F);
  Builder->CreateCondBr(CondV, ThenBB, ElseBB);

  Builder->SetInsertPoint(ThenBB);
  Value *ThenV = Then->codegen();
  Builder->CreateBr(MergeBB);
  ThenBB = Builder->GetInsertBlock();       // then 体内可能开新块，phi 用"真末块"

  ... ElseBB 同构 ...

  Builder->SetInsertPoint(MergeBB);
  PHINode *PN = Builder->CreatePHI(DoubleTy, 2, "iftmp");
  PN->addIncoming(ThenV, ThenBB);
  PN->addIncoming(ElseV, ElseBB);
  return PN;
}
```

对照第 4 章 4.3 节的 `clamp`——一模一样的套路，只是这次是机器生成。

> **实测坑（两个 22 版 API 变化）**：① `GetInsertPoint()` 现在返回**迭代器**，块指针要用 `GetInsertBlock()`；② 老教程"先 Create 块再 `F->getBasicBlockList().push_back(BB)`"——22 里 `getBasicBlockList()` 是**私有**的，块必须在 `BasicBlock::Create(ctx, name, F)` 创建时就挂进函数（或用 `BB->insertInto(F)`），否则 verify 报 `Global is referenced by parentless instruction!` / `Referring to a basic block in another function!`。

## 13.4 for：守卫在前的 phi 循环

MiniLang 的 `for i = start, end, step in body` 编成第 4 章 `phi.ll` 同款结构（守卫在循环头）：

```llvm
loop.head:
  %i   = phi double [ %start, %entry ], [ %next, %loop.body ]   ; 循环变量
  %res = phi double [ 0.0,    %entry ], [ %bodyV, %loop.body ]  ; for 的值
  %cond = fcmp ole double %i, %end
  br i1 %cond, label %loop.body, label %loop.exit
```

两个 phi：`%i` 是循环变量（每圈 `%next = fadd %i, step` 回流），`%res` 累积"最后一圈的 body 值"（一圈不进则 0.0——和第 4 章 `sum_to(0)=0` 语义完全一致）。

**循环变量遮蔽**：进循环体前 `NamedValues[VarName] = phi值`，备份旧绑定；出循环恢复。这样外层同名变量不受污染——作用域规则的一行实现。

## 13.5 函数与合成 main

```cpp
Function *FunctionAST::codegen() {
  Function *F = TheModule->getFunction(Proto->Name);   // 已有声明则认领
  ...
  NamedValues.clear();
  for (auto &Arg : F->args()) NamedValues[Arg.getName()] = &Arg;
  Builder->CreateRet(Body->codegen());
  verifyFunction(*F, &errs());                          // 每函数即编即验
}
```

`--ir` 模式的整文件流程：extern → `declare`；def → `define`；顶层表达式 → `__anonN` 函数，最后合成 `main` 依次调用（保证顺序与副作用）。

## 13.6 实测

```powershell
& minilang --ir test.mini test.ll
& lli test.ll
```

（实测输出）：

```text
wrote test.ll
==== 13 ok ====
55.000000        # fib(10)——递归 if/phi 版
5050.000000      # sum_to(100)——递归版（v0.2 还没有变量，累加只能递归）
7.000000         # (1+2)*3 - 4/2
10.000000        # if 1<2 then 10 else 20
25.000000        # for i=1,5 in i*i → 最后一圈 5*5
0.000000         # sin(0)——extern 声明由 lli 从 C 库解析
```

注意 `for` 的值 = 最后一圈 body 值（25 而不是 55）——设计如此，文档化优于魔法。

## 13.7 本章小结

- codegen = 树遍历 + IRBuilder 发射；NamedValues 就是作用域。
- if/for 的 phi 套路与第 4 章手写版逐行对应——**前端不必怕 phi，但也可以不怕 alloca**（第 15 章的另一条路线）。
- 每函数 verify、失败回滚（eraseFromParent）；`--ast`/`--ir` 双模式让前端可独立调试。

| 坑 | 解法 |
|---|---|
| parentless instruction / 另一函数的块 | 22：块创建时就传 F，getBasicBlockList 已私有 |
| GetInsertPoint() 编不过 | 22 返回迭代器；块指针用 GetInsertBlock() |
| 内置函数返回 i32 | print 返回被打印值，守 double 约定 |
| for 语义误解 | 值=最后一圈 body 值；写成文档 |

下一章把执行引擎从 lli 换成内嵌 JIT——编译器变解释器。
