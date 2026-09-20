# 12 · MiniLang 前端：词法与递归下降解析

> 对应示例：`examples/12_minilang_front/`（minilang.cpp v0.1 + test.mini）

从这章起，九进制连载开始：**MiniLang**——一个能长成完整编译器的玩具语言。本章目标：词法器 + 递归下降解析器 + AST，纯 C++ 无 LLVM 依赖（`g++ minilang.cpp` 即可构建）。别小看这 400 行——它和 rustc、clang 前端是同构的，只是没有类型检查和错误恢复。

## 12.1 语言设计速览

MiniLang 是**纯 double 的表达式语言**（Kaleidoscope 血统，刻意为之——类型系统会喧宾夺主）：

```text
# 注释行
extern sin(x)                          # 声明外部函数（C 库）
def fib(n) if n < 2 then n else fib(n-1) + fib(n-2)   # 一切皆表达式
def sum_to(n) ...                      # 函数即顶层单元
print(fib(10))                         # 顶层表达式逐条执行
```

设计要点：

| 决策 | 理由 |
|---|---|
| 万物皆 double | 类型系统是另一门课；先把"语言→IR"通道打通 |
| 一切皆表达式 | if/for/var 都有值——AST 均匀，代码生成无特例 |
| 关键字 if/then/else/for/in/var/def/extern | 全部保留字，不用符号 |
| `#` 注释到行尾 | 简单 |

## 12.2 词法器：字符流 → token 流

```cpp
enum class Tok { Eof, Def, Extern, If, Then, Else, For, In, Ident, Number, ... };
static std::string IdentifierStr;   // Ident 的载荷
static double NumVal;               // Number 的载荷

static int getTok(std::istream &In) {
  static int Last = ' ';
  while (isspace(Last)) Last = In.get();          // 跳空白
  if (isalpha(Last) || Last == '_') { ... }        // 标识符/关键字
  if (isdigit(Last) || Last == '.') { ... }        // 数字
  if (Last == '#') { ... }                         // 注释：跳到行尾再递归
  int This = Last; Last = In.get(); return This;   // 其余单字符原样
}
```

三个要点：

- **载荷用全局变量**——工业级会打包成 struct/token 流，教学版够用且诚实；
- 关键字 = 标识符查表（`IdentifierStr == "def"`）；
- **单字符运算符直接返回 ASCII**——运算符就是 token，不需要查表。

> **实测坑（标识符下划线）**：第一版词法只认 `isalpha` 打头、`isalnum` 续接——`sum_to` 被切成 `sum` + `_` + `to`，解析器在 `def sum_to(n)` 处报 `expected '('`。**标识符字符集必须包含 `_`**。这个 bug 的隐蔽性在于：只要测试文件全是单字母名就永远不炸。

## 12.3 AST：一个节点类型一个类

```cpp
struct ExprAST {
  virtual ~ExprAST() = default;
  virtual void dump(std::ostream &O) const = 0;   // S-表达式打印
  // 第 13 章会加：virtual Value *codegen() = 0;
};
struct NumberExprAST : ExprAST { double Val; ... };
struct VariableExprAST : ExprAST { std::string Name; ... };
struct BinaryExprAST : ExprAST { char Op; unique_ptr<ExprAST> LHS, RHS; ... };
struct CallExprAST : ExprAST { std::string Callee; vector<...> Args; ... };
struct IfExprAST / ForExprAST ...                  // 也都是表达式
struct PrototypeAST { std::string Name; std::vector<std::string> Args; };
struct FunctionAST { unique_ptr<PrototypeAST> Proto; unique_ptr<ExprAST> Body; };
```

和第 9 章 IR 的对象模型一个思路：**数据在树上，行为用虚函数挂**。`dump()` 打印成 S-表达式，是前端最便宜的自检手段。

## 12.4 递归下降 + 优先级爬升

解析器骨架（每个产生式一个函数）：

```text
parseDefinition   ::= 'def' parsePrototype parseExpression
parseExtern       ::= 'extern' parsePrototype
parseTopLevel     ::= parseExpression （包成匿名函数 __anonN）
parseExpression   ::= parsePrimary parseBinOpRHS(0)
parsePrimary      ::= Ident | Number | '(' expr ')' | if | for | var...
parseBinOpRHS     ::= 优先级爬升（见下）
```

**优先级爬升（precedence climbing）** 是教科书外的实用技巧，30 行搞定所有二元运算符：

```cpp
// 表：数字越大绑得越紧
static std::map<char, int> BinopPrecedence = {{'<',10}, {'+',20}, {'-',20}, {'*',40}, {'/',40}};

static unique_ptr<ExprAST> parseBinOpRHS(int MinPrec, unique_ptr<ExprAST> LHS) {
  while (true) {
    int Prec = getTokPrecedence();
    if (Prec < MinPrec) return LHS;              // 太松，还给调用者
    int BinOp = CurTok; advance();
    auto RHS = parsePrimary();
    int NextPrec = getTokPrecedence();
    if (Prec < NextPrec)                          // 右边更紧：先结合右边
      RHS = parseBinOpRHS(Prec + 1, std::move(RHS));
    LHS = make_unique<BinaryExprAST>((char)BinOp, std::move(LHS), std::move(RHS));
  }
}
```

读法：`1 + 2 * 3`——`+`(20) 拿到 RHS=2 后看见 `*`(40) 更紧，把"从 40 起"的子表达式递归收编成 RHS，再组合。

实测（`minilang --ast test.mini`）：

```text
(print x)
(def (fib n) (if (binary < n 2) n (binary + (call fib (binary - n 1)) (call fib (binary - n 2)))))
(def (sum_to n) (if (binary < n 1) 0 (binary + n (call sum_to (binary - n 1)))))
(binary - (binary + 1 (binary * 2 3)) (binary / 4 2))
(call fib 10)
(binary * (binary + 1 2) 3)
(if (binary < 1 2) 10 20)
(for i = 1, 5 in (binary * i i))
==== 12 ok ====
```

注意 `1 + 2 * 3 - 4 / 2` 的树形：`(- (+ 1 (* 2 3)) (/ 4 2))`——优先级完全正确，且 `+`/`-` 同级左结合。

## 12.5 错误处理的两条通路

- `logErrorE`/`logErrorP` 返回 `nullptr`——上层逐级短路。粗但有效；
- 打印 token 帮助定位：`(tok=%d)`。工业级要行列号+恢复策略，教学版选择"快死快改"。

## 12.6 本章小结

- 前端 = 词法（字符→token）+ 解析（token→AST）；载荷走全局、单字符 token 走 ASCII 是最简装备。
- 递归下降一个产生式一个函数；二元运算符交给优先级爬升统一处理。
- `--ast` 的 S-表达式 dump 是前端的"单元测试"。

| 坑 | 解法 |
|---|---|
| `sum_to` 解析失败 | 词法加 `_` 进标识符字符集 |
| 优先级表查不到返回 0 | 约定返回 -1 表示"不是运算符" |
| AST 打印看不出结合性 | dump 用全括号 S-表达式 |

下一章给每个 AST 节点装上 `codegen()`——树变成 IR。
