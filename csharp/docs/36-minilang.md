# 36 · 综合实战：MiniLang 表达式解释器

> 对应示例：`examples/36_minilang`（Lexer → Parser → Evaluator 三段管线 + REPL）

> **本章你将学会**：解释器的三段管线、词法分析、递归下降与优先级爬升、AST 求值、错误报告设计——以及全书知识在一个真项目里的落位。

## 1. 我们要造什么

一门能跑的迷你语言：

```text
» let width = 3
» let height = 4
» width * height          ← 裸表达式：求值打印
12
» width == 3              ← 比较运算（布尔用 1/0 表示）
1
» width = 10              ← 重新赋值
```

支持：let 声明/赋值/裸表达式三种语句；`+ - * / %`、比较六件套、一元负号、括号、变量。麻雀虽小，**五脏正是每个解释器/规则引擎/公式系统的五脏**——Excel 公式、配置模板、工作流条件，全是这个骨架的放大版。

## 2. 三段管线：字符 → 记号 → 树 → 值

```text
源码 "width * height"
   │ Lexer（词法分析）
   ▼ 记号流 [名(width), Op(*), 名(height)]
   │ Parser（语法分析）
   ▼ AST    BinaryExpr(*, VarExpr(width), VarExpr(height))
   │ Evaluator（求值）
   ▼ 值      12
```

**每段只认下一段的语言**：Lexer 认字符、Parser 记号、Evaluator 树——三段独立可测（第 35 章分层原则的落地）。这个架构是编译器前端的科普版：真正的编译器在此之后还有优化/代码生成，解释器到求值为止。

## 3. Lexer：字符流 → 记号流

```csharp
public readonly record struct Token(TokenKind Kind, string Text, int Pos);   // 记号 = 种类+原文+位置

if (char.IsDigit(ch)) { /* 连读数字 → Number 记号 */ }
if (char.IsLetter(ch)) { /* 连读标识符；"let" 升级为关键字记号 */ }
if (pair is "==" or "!=" or "<=" or ">=") { /* 双字符运算符优先探测 */ }
```

要点三则：

- **跳过空白**（不产生记号）；每个记号带**位置 Pos**——错误消息能指到列（`位置 12: 无法识别的字符 '%'`）
- **双字符运算符先探**：`==` 要先于两个 `=` 被识别——贪心匹配
- 记号是 `record struct`（第 11 章）：值语义、无分配负担、ToString 调试友好

## 4. Parser：递归下降 + 优先级爬升

语法规则写成互相调用的方法（**递归下降**）：

```text
语句  ::= "let" 标识符 "=" 表达式 | 标识符 "=" 表达式 | 表达式
表达式 ::= 一元 (运算符 一元)*      ← 优先级爬升在这
一元  ::= "-" 一元 | 原子
原子  ::= 数字 | 标识符 | "(" 表达式 ")"
```

**优先级爬升**（precedence climbing）用一张表 + 一个参数解决结合性：

```csharp
private static int Precedence(string op) => op switch
{
    "==" or "!=" or "<" or "<=" or ">" or ">=" => 1,    // 比较最松
    "+" or "-"                                  => 2,
    "*" or "/" or "%"                           => 3,    // 乘除最紧
};

public Expr ParseExpr(int minPrecedence = 1)
{
    var left = ParseUnary();
    while (/* 下一个运算符优先级 ≥ minPrecedence */)
    {
        Advance();
        var right = ParseExpr(prec + 1);     // ★ 左结合：右边的门槛高一级
        left = new BinaryExpr(op, left, right);
    }
    return left;
}
```

`2+3*4` 为什么自动算对？`+`(2) 之后进入 `ParseExpr(3)`——`*`(3) 够格继续、`+`(2) 不够——乘法先结合。**左结合由 `prec + 1` 表达**；要右结合（如幂运算）传 `prec` 即可——一行之差。这是手写解析器的核心技巧，一通百通。

**双记号缓冲**解决"看穿赋值"：`width = 10` 要看到**第二个**记号是 `=` 才知道这是赋值不是表达式——`_lookahead` + `_peek` 双缓冲偷看一眼，不消费。

AST 节点全是 record（第 11 章）：`BinaryExpr(string Op, Expr Left, Expr Right)`——**不可变、结构相等、模式匹配友好**。

## 5. Evaluator：遍历树求值

```csharp
private double Eval(Expr expr) => expr switch
{
    NumberExpr n => n.Value,
    VarExpr v => _vars.TryGetValue(v.Name, out var val)
        ? val : throw new MiniLangException(v.Pos, $"变量 {v.Name} 未定义"),
    BinaryExpr(var op, var l, var r) => op switch
    {
        "+" => Eval(l) + Eval(r),
        ...
    },
};
```

- **switch 表达式对树分派**（第 19 章）：每个节点类型一个 arm，读作求值规则表
- **变量环境**是 `Dictionary<string, double>`——let 声明（已存在报错）/ `=` 赋值（不存在报错）语义分明
- **除零显式报错**：double 的 `1/0` 本是 ∞ 不抛异常（第 03 章的坑）——解释器按用户直觉包成错误
- 布尔用 1/0 表示（取舍：省一个类型系统，教学聚焦管线）

## 6. 错误设计：位置 + 人话

```text
» let x = 1 / 0        →  位置 10: 除数为零
» let x = nosuch + 1   →  位置 8: 变量 nosuch 未定义
» let width = 5        →  位置 0: 变量 width 已存在（let 只能声明一次，重新赋值直接写 width = …）
```

错误三要素：**位置**（记号从 Lexer 带来，一路透传）、**人话**（告诉用户怎么改，第 22 章"写怎么改不写什么错了"）、**类型化异常**（MiniLangException 让驱动层统一接——管线各层只管抛）。演示脚本故意跑三种错误看输出形态。

## 7. 全书知识的落位表

| 章节 | 在 MiniLang 里 |
|---|---|
| 07 枚举 / 11 record | TokenKind、Token/全部 AST 节点 |
| 12 泛型字典 | 变量环境 Dictionary<string,double> |
| 19 模式匹配 | Evaluator 的树分派、Parser 的 Precedence |
| 16 LINQ | REPL 参数解析、演示脚本组织 |
| 22 异常 | MiniLangException 与三层错误演示 |
| 35 可测性 | 三段零 UI 依赖——每段可独立单测 |

**练习路径**（按难度递增）：

1. 加 `^` 幂运算（提示：右结合，`ParseExpr(prec)` 不加一）与一元 `+`
2. 加 `let` 常量语义或 `del x` 删除变量
3. 加布尔类型与 `and/or/not`（短路求值：左操作数先算）
4. 加函数定义与调用（`let f = x => x*2`——环境里存参数表+AST，调用时新开作用域）
5. 加字符串类型（Lexer 认引号、值从 double 变 object + 模式匹配分派）
6. 打印 AST：给 Expr 写 ToString 递归（或引入 Visitor），可视化解析结果

## 8. 为什么以解释器收官

它强迫你**同时使用**全书的一切：类型系统建模（数据形态选 record）、模式匹配做分派、异常做错误通道、LINQ 组织流程——而且产出物是"活的"：改一行优先级表，语言行为立刻变。**能独立改出第 7 节的任意一个练习，这门语言的机制你就真的掌握了**——比任何"总结章"都实在。

---
上一章：[35 单元测试](35-testing.md) ｜ 返回：[README](../README.md)
