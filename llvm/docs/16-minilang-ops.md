# 16 · 运算符扩展：表驱动与用户自定义

> 对应示例：`examples/16_minilang_ops/`（minilang.cpp v0.5 + test.mini）

一门语言的"手感"大半来自运算符。本章把 MiniLang 的运算符体系开放给用户：`def binary| 5 (l r) ...` 定义二元运算符（带优先级）、`def unary! (x) ...` 定义一元运算符。实现全部建立在第 12 章的**优先级表**之上——你会看到"语言特性"如何被降维成"数据结构里的一行登记"。

## 16.1 设计：命名约定即协议

```text
def binary| 5 (l r) if l < r then r else l     # "|" = 取大，优先级 5（比 + 还松）
def binary~ 60 (l r) if l < r then l else r    # "~" = 取小，优先级 60（比 * 还紧）
def unary! (x) if x < 1 then 1 else x * !(x - 1)   # "!" = 阶乘（可递归）
def unary- (v) 0 - v                           # 连负号都要用户"装出来"
```

内部机制纯粹是命名约定：`binary|` / `unary!` **就是普通函数**，函数名分别是字符串 `"binary|"`、`"unary!"`。三处协作：

1. **解析器**：优先级表登记 `'|' → 5`，此后 `1 + 2 | 3` 按表爬升；
2. **parseUnary**：运算符出现在"该有操作数"的位置 → 构造一元节点；
3. **codegen**：`BinaryExprAST` 不认识的运算符 → 调用函数 `"binary"+op`。

没有 AST 新类型、没有 codegen 特例——**约定优于机制**的教学范本。

## 16.2 原型解析的扩展

`parsePrototype` 开头加一个分派：

```cpp
switch (CurTok) {
  case Tok::Ident:  FnName = IdentifierStr; ...              // 普通函数
  case Tok::Unary:  // "unary" 后跟一个运算符字符
    FnName = "unary"; FnName += (char)CurTok; Kind = 1; ...
  case Tok::Binary: // "binary" 后跟运算符，可再跟优先级数字
    FnName = "binary"; FnName += (char)CurTok; Kind = 2;
    if (CurTok == Tok::Number) { BinaryPrecedence = NumVal; ... }
}
// 收尾时校验：一元必须 1 参，二元必须 2 参
```

`PrototypeAST` 相应长出 `IsUnary/IsBinary/BinaryPrecedence` 字段。**解析 def 成功后**把优先级写进全局表：

```cpp
if (F->Proto->IsBinary)
  BinopPrecedence[F->Proto->Name.back()] = F->Proto->BinaryPrecedence;
```

从这一刻起，这门语言的语法被用户改写了——REPL 语言"语法可增长"的内核就这一行。

## 16.3 parseUnary：一元运算符的位置感

```cpp
static std::unique_ptr<ExprAST> parseUnary() {
  if (!isascii(CurTok) || CurTok == '(' || CurTok == ')' || CurTok == ',')
    return parsePrimary();          // 正常 primary 位置
  int Opc = CurTok; advance();      // 运算符打头：吃掉，递归解析操作数
  if (auto Operand = parseUnary())  // 递归 → 支持 !!x、-!x
    return std::make_unique<UnaryExprAST>((char)Opc, std::move(Operand));
  return nullptr;
}
```

`parseExpression` 与 `parseBinOpRHS` 的 RHS 位置都改走 `parseUnary`——**每个"该有操作数"的位置都允许一元运算符打头**，漏改一处就有 `2 | -3` 解析失败（实测踩过）。

`UnaryExprAST::codegen` 把 `"unary"+op` 当普通函数调用（复用第 14 章的元数记账，跨模块照常工作）。

## 16.4 实测

```text
print(!(6))          → 720.000000      # 6!
print(1 + 2 | 3 + 4) → 7.000000        # 优先级 5：(1+2)|(3+4) = 3|7
print(4 ~ 3 * 2)     → 6.000000        # 优先级 60：(4~3)*2 = 3*2
print(-!(4))         → -24.000000      # 负号+阶乘套娃
print(fib(10))       → 55.000000       # 常规函数不受影响
==== 16 ok ====
```

优先级 5 与 60 的两极对照，证明表驱动名副其实。

## 16.5 本章小结

- 用户运算符 = 命名约定（binary@/unary@ 函数）+ 优先级表登记 + 调用式 codegen。
- 一元运算符要挂到**所有**操作数位置（parseExpression/RHS 双入口）。
- `PrototypeAST` 携带 Kind/Precedence——语法信息进了 AST。

| 坑 | 解法 |
|---|---|
| `2 | -3` 报错 | parseBinOpRHS 的 RHS 也用 parseUnary |
| 优先级数字不合法 | 限定 1..100，解析期报错 |
| 一元/二元参数个数错 | 解析收尾时校验 |

下一章给 JIT 装上优化层——让编译器自己变快。
