# 19 · 写一个解析器

> 对应示例：[`examples/19_parser/19_parser.pl`](../examples/19_parser/19_parser.pl)

## 19.1 目标与流水线

这一章用前面 18 章的工具，端到端走完一个**算术表达式求值器**：

> **词法分析 → 语法分析出 AST → 求值 → 再打印回文本。**

```text
"1 + 2 * 3"   AST = add(num(1),mul(num(2),num(3)))
               打印回文本 = (1 + (2 * 3))  值 = 7
"(1 + 2) * 3" AST = mul(add(num(1),num(2)),num(3))
               打印回文本 = ((1 + 2) * 3)  值 = 9
```

分成四步不是形式主义，而是**四份各自独立的关注点**：字符怎么切、语法怎么组、树怎么算、
文本怎么反着生成。每一层只跟下一层打交道。

## 19.2 第一步：词法分析

把字符码列表切成 token 列表。**逐字符扫描 + 分派**：

```prolog
lex([], []).
lex([C | Cs], Ts) :-
    (   C =:= 32                       % 空格：跳过
    ->  lex(Cs, Ts)
    ;   C >= 48, C =< 57               % 数字：连续吃
    ->  take_digits([C | Cs], Digits, Rest),
        number_codes(N, Digits),
        Ts = [num(N) | Ts1],
        lex(Rest, Ts1)
    ;   op_token(C, Op)                % 运算符
    ->  Ts = [Op | Ts1],
        lex(Cs, Ts1)
    ;   Ts = [bad(C) | Ts1],           % 不认识的字符
        lex(Cs, Ts1)
    ).

take_digits([C | Cs], [C | Ds], Rest) :-
    C >= 48, C =< 57, !, take_digits(Cs, Ds, Rest).
take_digits(Rest, [], Rest).

op_token(43, '+').  op_token(45, '-').
op_token(42, '*').  op_token(47, '/').
op_token(40, '(').  op_token(41, ')').
```

```text
"1 + 2 * 3"     -> [num(1),+,num(2),*,num(3)]
"12*(3+4)"      -> [num(12),*,(,num(3),+,num(4),)]
"8 / 4"         -> [num(8),/,num(4)]
"x + 1"         -> [bad(120),+,num(1)]（x 变成 bad(120)）
```

三个设计决策，每个都值得学：

**① 空格在这里吃掉，不在语法层。** 于是语法规则完全不用考虑空格 —— 词法层的存在意义
就是**让语法层面对一个干净的 token 流**。

**② 多位数合成一个 token。** `take_digits` 一次吃光连续数字，`number_codes` 合成整数。
如果用 18 章的 DCG 一个字符一个字符地解析，`12` 会被拆成 `1`、`2` 两个终结符，
语法规则得自己去拼 —— 这就是 **19.5 说的「为什么词法和语法要分开」**。

**③ 认不出的字符不做异常，包成 `bad(C)`。** 这是**「词法错误局部化」**：

> 解析器可以继续往下走，**把同一个输入里的所有问题一次报出来**，而不是遇到第一个
> 就中断。这是所有生产级编译器/解释器的做法。

检查也简单：`member(bad(C), Tokens)` 就能发现。

## 19.3 第二步：语法分析出 AST

**优先级：`expr`（`+ -`）< `term`（`* /`）< `factor`（数字或括号）。**
用 DCG 一层一个非终结符地描出这个层级：

```prolog
parse_expr(AST) -->
    parse_term(T),
    parse_expr_rest(T, AST).

parse_expr_rest(Acc, AST) --> ['+'], parse_term(T), {A1 = add(Acc,T)}, parse_expr_rest(A1, AST).
parse_expr_rest(Acc, AST) --> ['-'], parse_term(T), {A1 = sub(Acc,T)}, parse_expr_rest(A1, AST).
parse_expr_rest(AST, AST) --> [].

parse_term(AST) -->
    parse_factor(F),
    parse_term_rest(F, AST).

parse_term_rest(Acc, AST) --> ['*'], parse_factor(F), {A1 = mul(Acc,F)}, parse_term_rest(A1, AST).
parse_term_rest(Acc, AST) --> ['/'], parse_factor(F), {A1 = div(Acc,F)}, parse_term_rest(A1, AST).
parse_term_rest(AST, AST) --> [].

parse_factor(num(N)) --> [num(N)].
parse_factor(AST) --> ['('], parse_expr(AST), [')'].
```

```text
"1 + 2 * 3"   AST = add(num(1),mul(num(2),num(3)))     值 = 7
"(1 + 2) * 3" AST = mul(add(num(1),num(2)),num(3))     值 = 9
```

> **注意 AST 里乘法的左参数已经是加法** —— **优先级在语法树形状里定死了。**
> 之后求值只看树，**完全不需要再考虑优先级**。这就是「分离关注点」的实际收益。

`parse_factor` 处理括号的方式值得注意：**括号里的东西递归回到 `parse_expr`** ——
这就是 18.5 说的「嵌套」能力，DCG 免费给。

## 19.4 左结合：为什么累加器版是必须的

这是本章最重要的技术点。**`10 - 3 - 2` 必须读成 `(10-3)-2` = 5**，不是 `10-(3-2)` = 9。

```text
"10 - 3 - 2"   AST = sub(sub(num(10),num(3)),num(2))
               打印回文本 = ((10 - 3) - 2)  值 = 5
再来一个：(((100 - 10) - 5) - 2)  ->  83
```

**如果按最自然的方式写 DCG：**

```prolog
%% 错误的写法！这会给出右结合
bad_expr(A + B) --> parse_term(A), ['+'], bad_expr(B).
```

那么 `10 - 3 - 2` 会读成 `sub(10, sub(3, 2))` —— **值算出来是 9，静默错误**。
这类 bug 最讨厌的地方是它**不报错**，只是答案不对。

**正确做法是「累加器 + 尾递归」**：

```prolog
parse_expr_rest(Acc, AST) --> ['+'], parse_term(T), {A1 = add(Acc,T)}, parse_expr_rest(A1, AST).
parse_expr_rest(AST, AST) --> [].       % 没有更多运算符了 → 收工
```

每一轮**把已经读到的部分当作左操作数传下去**（`Acc`），于是结合方向天然是左的。

> **这个「累加器 + 尾递归」的模式在 Prolog 里到处都是** —— 求列表长度、求和、反转列表
> （09 章），还有这里的运算符左结合。**看到「左结合/从左往右累积」就该想到它。**
>
> 尾递归还有个附带好处：**不消耗栈**。深度嵌套的表达式不会把栈撑爆。

## 19.5 第三步：求值

```prolog
eval(num(N), N) :- !.
eval(add(A,B), V) :- !, eval(A,VA), eval(B,VB), V is VA + VB.
eval(sub(A,B), V) :- !, eval(A,VA), eval(B,VB), V is VA - VB.
eval(mul(A,B), V) :- !, eval(A,VA), eval(B,VB), V is VA * VB.
eval(div(A,B), V) :- !, eval(A,VA), eval(B,VB), V is VA / VB.
```

五行，一个函子一个子句 —— 因为**优先级已经在 19.3 解决了**，这里只是递归求值。
每行开头的 `!` 是**必要的**（10 章）：不加的话 `eval(num(N), N)` 和后面的子句可能互相干扰，
而且会留下无谓的选择点。

```text
1 + 2   =  3
2 * 3 + 4 * 5   =  26
((1 + 2) * (3 + 4))   =  21
10 / 4   =  2.5
7 - 2 * 3   =  1
2 * (3 + 4) - 5   =  9
```

> **只有 `10 / 4` 是浮点 `2.5`，其余都是整数** —— 这也是演示刻意的选择：
> **整除（如 `8/4`）两套引擎给的类型不同（整数 vs 浮点），不能用于跨引擎比对。**
>
> 这与 24 章的解释器为什么用 `//`（整除）是同一个原因。**凡是结果要逐字节比对的场合，
> 就绕开所有「类型可能不一致」的运算。**

## 19.6 第四步：把 AST 打印回文本（DCG 的「生成」方向）

**同一套 DCG 既能「识别」也能「生成」** —— 这一半威力在 18 章只是提了一句，这里用上了：

```prolog
ast_text(num(N))   --> {number_codes(N, Cs)}, codes_term(Cs).
ast_text(add(A,B)) --> "(", ast_text(A), " + ", ast_text(B), ")".
ast_text(sub(A,B)) --> "(", ast_text(A), " - ", ast_text(B), ")".
ast_text(mul(A,B)) --> "(", ast_text(A), " * ", ast_text(B), ")".
ast_text(div(A,B)) --> "(", ast_text(A), " / ", ast_text(B), ")".
```

用法是**反过来**：给 `ast_text` 一个 AST，让它**吐出**一串字符码：

```prolog
phrase(ast_text(AST), Text).       % Text 是输出，不是输入！
```

**这里藏着一个 DCG 的经典陷阱**：

```prolog
ast_text(num(N)) --> {number_codes(N, Cs)}, Cs.       % ✗ 错的！
```

**`Cs` 不能直接写在 DCG 体里** —— 因为 DCG 会把 `Cs` 当成一个**非终结符**去 `call`，
于是变成调用 `call(Cs, S0, S)`，报 `existence_error`。

**必须把码列表「展开成逐个终结符」**：

```prolog
codes_term([]) --> [].
codes_term([C | Cs]) --> [C], codes_term(Cs).
```

> **这是写 DCG 时最容易撞的一脚：想在 DCG 里「塞一段现成的列表」，只能一个个 `[C]` 吐出去，
> 不能把整个列表当一个目标写。**

**打印结果**：

```text
"1 + 2 * 3"  打印回文本 = (1 + (2 * 3))
"(1 + 2) * 3" 打印回文本 = ((1 + 2) * 3)
"10 - 3 - 2"  打印回文本 = ((10 - 3) - 2)
```

注意打印出来是**全括号**形式 —— 因为 `ast_text` 每个子句都无脑加括号。
**这恰好是最忠实的输出**：它把 AST 的形状直接暴露出来，不会因为优先级还原而引入歧义。
要做「漂亮打印」（去掉多余括号），就再加一个优先级感知的打印器 —— 本章练习。

## 19.7 串起来

```prolog
calc(Chars, Value) :-
    tokenize(Chars, Tokens),
    once(phrase(parse_expr(AST), Tokens)),      % once：计算器不需要歧义
    eval(AST, Value).
```

`once/1` 是必要的：**DCG 解析会留下选择点**（万一后面还有别的解析路径），
算完值之后回溯进去再解一遍纯属浪费。

**错误处理**：`"1 +"`、`"(1 + 2"` 这类输入**直接解析失败**。

```text
"1 +"         -> 解析失败（表达式不完整）
"(1 + 2"       -> 解析失败（缺右括号）
失败就是失败 —— 没有异常、没有 null。想给用户友好提示，
就再写一个「错误报告」谓词，把位置信息一起带出来（本章练习）。
```

> **失败就是失败 —— 没有异常、没有 `null`。** 这是 Prolog 的性格，也正是 20 章的主题：
> **异常用于「编程错误与环境问题」，不用来表达「没找到」。**

## 19.8 坑位清单

1. **写右结合版 `parse_expr(A+B) --> term(A),['+'],parse_expr(B).`** → `10-3-2` 算成 9，静默错误。
2. **DCG 里直接写 `Cs`（列表变量）** → 被当非终结符 `call`，报 `existence_error`。
3. **词法层不吃空格** → 语法规则里到处要处理空格，很快就乱。
4. **`take_digits` 忘了尾子句** → 数字后面没字符时不终止。
5. **`lex` 的分支顺序写反** → 「数字」分支必须排在「不认识的字符」之前。
6. **`eval` 子句不加 `!`** → 留下无谓选择点，还可能匹配错子句。
7. **`calc/2` 不加 `once`** → 求完值还会回溯重解，白费时间。
8. **用 `/` 做跨引擎比对的除法** → `8/4` 的类型两套引擎不同（整数 vs 浮点）。
9. **认不出的字符直接 `throw`** → 只能报第一个错。包成 `bad(C)` 能一次报全。
10. **`parse_factor` 处理括号时不递归回 `parse_expr`** → 括号里不能有表达式，嵌套失效。

---

上一章：[18 · 定子句文法](18-dcg.md) · 下一章：[20 · 异常处理](20-exceptions.md)
