# 24 · 综合项目：一个解释器

> 对应示例：[`examples/24_capstone/24_capstone.pl`](../examples/24_capstone/24_capstone.pl)

## 24.1 项目：四步流水线

**目标：读一段源码文本，算出结果。**

```text
① 词法  lex/2         字符码列表 → token 列表     第 15 章
② 语法  parse_prog/2  token 列表 → 语句列表(AST)  第 18、19 章
③ 语义  exec/3        在环境里求值 → 值 + 绑定表  第 05、08、09 章
④ 测试  run_suite/2   验语义与错误路径            第 23 章
```

**另外还用到了**：

```text
错误用 throw/catch 报（第 20 章）、「找不到变量」用 some/none（第 20 章）、
环境用关联表 + member/2 查找（第 08 章）、
一元负号与优先级靠运算符/分层写（第 16 章）、
整个求值是纯的，所以能直接塞进 findall 做断言（第 11、13 章）。
```

**语言语法（很小，但该有的都有）**：

```text
语句     let 名字 = 表达式 ;      表达式 ;
表达式   整数 名字 ( … ) 一元-   + - * /
          < >（结果 1 或 0）  if 条件 then 甲 else 乙
```

**两处设计是被「可移植性」逼出来的**（24.5 末尾专讲）。

## 24.2 第一步：词法

```text
let a = 3;      → [t_let,t_id(a),t_eq,t_num(3),t_semi]
1 + 2 * (3 - 4); → [t_num(1),t_plus,t_num(2),t_star,t_lparen,t_num(3),t_minus,t_num(4),t_rparen,t_semi]
if x > 5 then 1 else 0; → [t_if,t_id(x),t_gt,t_num(5),t_then,t_num(1),t_else,t_num(0),t_semi]
```

**实现上的两个细节**：

```text
· 数字和名字都是「先收集字符、再一次性成值」的循环（take_digits / take_name），
  这种「收集到分隔符为止」的写法在第 15 章整理过。
· 数值是自己累加的（Acc * 10 + (C - 48)），没用 number_codes/2 ——
  少依赖一个引擎可能实现不一致的谓词，成本只是三行。
```

```prolog
take_digits([C|Cs], [C|Ds], Rest) :- digit_code(C), !, take_digits(Cs, Ds, Rest).
take_digits(Rest, [], Rest).

take_name([C|Cs], [C|Ns], Rest) :- name_code(C), !, take_name(Cs, Ns, Rest).
take_name(Rest, [], Rest).

%% 自己累加，不依赖 number_codes/2
digits_value(Ds, N) :- dv(Ds, 0, N).
dv([], Acc, Acc).
dv([C|Cs], Acc, N) :- A1 is Acc * 10 + (C - 48), dv(Cs, A1, N).
```

**按字符分派**（`lex/2`）—— 和 19 章同构，但这次**用 `throw` 报词法错误**：

```text
遇到不认识的字符直接 throw lex_error(C)，不返回「带错误标记的 token」：
错误早发现比晚发现好，而且 token 列表保持「全是合法的」这个不变量，
后面的语法阶段就不用再检查了。
```

> **这是一个明确的「不变量」设计**：19 章的 `bad(C)` 方案（继续走、一次报全）适合
> **交互式**解析器；本章的 `throw` 方案（立刻停）适合**编译一次就完**的场景。
> **两种都对，取决于你要什么。** 关键是**保持一致** —— 别一半 `bad` 一半 `throw`。

## 24.3 第二步：语法（DCG 递归下降）

**表达式的分层写法让优先级体现在结构里，不需要优先级表**：

```text
expr → cmp → add → mul → unary → primary
```

```prolog
cmp(E) --> add(A), cmp_rest(A, E).
cmp_rest(A, lt(A, B)) --> [t_lt], add(B).
cmp_rest(A, gt(A, B)) --> [t_gt], add(B).
cmp_rest(A, A)        --> [].

add(E) --> mul(A), add_loop(A, E).
add_loop(A, E) --> [t_plus],  mul(B), add_loop(plus(A, B), E).
add_loop(A, E) --> [t_minus], mul(B), add_loop(minus(A, B), E).
add_loop(A, A) --> [].

mul(E) --> unary(A), mul_loop(A, E).
mul_loop(A, E) --> [t_star],  unary(B), mul_loop(times(A, B), E).
mul_loop(A, E) --> [t_slash], unary(B), mul_loop(divide(A, B), E).
mul_loop(A, A) --> [].

unary(neg(A)) --> [t_minus], unary(A).
unary(A)      --> primary(A).

primary(num(N))   --> [t_num(N)].
primary(ident(X)) --> [t_id(X)].
primary(E)        --> [t_lparen], expr(E), [t_rparen].
primary(ifthenelse(C, T, E)) -->
    [t_if], expr(C), [t_then], expr(T), [t_else], expr(E).
```

```text
1 + 2 * 3;      emit(plus(num(1),times(num(2),num(3))))
1 * 2 + 3;      emit(plus(times(num(1),num(2)),num(3)))
(1 + 2) * 3;    emit(times(plus(num(1),num(2)),num(3)))
1 - 2 - 3;      emit(minus(minus(num(1),num(2)),num(3)))
let k = -8 + 10;   let(k,plus(neg(num(8)),num(10)))
if 1 < 2 then 3 else 4;  emit(ifthenelse(lt(num(1),num(2)),num(3),num(4)))
```

**三个值得单独说的设计点**：

**① 左结合用「尾循环 + 累加器」** —— 和 19 章的 `parse_expr_rest` 同一个模式，
`add_loop/2` 把左边已经算好的结果一路带下去。**这是 Prolog 里实现左结合的标准手法。**

**② 比较是非结合的**：

```text
a < b < c 会直接语法错，必须写成 (a < b) < c。
这一条是故意的：让「链式比较」这种歧义在语法层就消失。
```

`cmp_rest` 只有两条「吃一个比较运算符」的子句，**没有循环** —— 所以最多比一次。
**这也是 16 章讲的 `xfx`（非结合）在语法层的等价物。**

**③ 悬空 else（经典坑）**：

```text
if 甲 then if 乙 then 1 else 2 else 3 里，那个 else 归谁？
本实现的规则是「先满足内层」，于是内层吃掉 else 之后
外层再找不到自己的 else，整个式子语法错。想看嵌套 if 就加括号：
  if 1 < 2 then (if 3 > 4 then 1 else 2) else 3;
```

对照输出：

```text
emit(ifthenelse(lt(num(1),num(2)),ifthenelse(gt(num(3),num(4)),num(1),num(2)),num(3)))
```

> **「先满足内层」是 BNFC/C 系语言也都采用的规则。** 本实现没有做「自动配对」的补救，
> 而是**要求加括号** —— 因为解释器的目标读者不是别人，是你自己。

## 24.4 第三步：语义（环境 + 求值）

**环境就是关联表 `[名字-值, ...]`，最新的绑定放在最前面。**

```prolog
%% 「找不到」是一个正常结果，不该用异常表达（第 20 章）
lookup(X, Env, Result) :-
    (   find_binding(X, Env, V) -> Result = some(V) ; Result = none ).

find_binding(X, [X2-V|_], V) :- X == X2, !.
find_binding(X, [_|Rest], V) :- find_binding(X, Rest, V).
```

> **注意 `find_binding` 用的是 `==`（不绑定变量）而不是 `=`。** 环境里存的名字是原子，
> 用来比较的名字也应该是原子 —— 用 `=` 会把查询变量悄悄绑到某个环境键上，是个隐蔽的 bug。
>
> **「最新的绑定放最前面」直接实现了变量遮蔽** —— 查找是线性的、从头开始的，
> 所以后来的绑定自然先被找到（24.4[b] 有实证）。

### `eval/3`：纯求值

```prolog
%% 对表达式求值。环境是只读的，所以整个求值是纯的 ——
%% 这一点很重要：纯谓词可以随便回溯、随便放进 findall。
eval(num(N), _Env, N) :- !.
eval(ident(X), Env, V) :-
    !,
    (   lookup(X, Env, some(V0)) -> V = V0 ; throw(undefined_variable(X)) ).
eval(neg(A), Env, V) :- !, eval(A, Env, VA), V is -VA.
eval(plus(A, B),  Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), V is VA + VB.
eval(minus(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), V is VA - VB.
eval(times(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), V is VA * VB.
eval(divide(A, B), Env, V) :-
    !,
    eval(A, Env, VA), eval(B, Env, VB),
    (   VB =:= 0 -> throw(division_by_zero(VA, VB))
    ;   V is VA // VB                    % 整除，理由见文件头
    ).
eval(lt(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), truth(VA < VB, V).
eval(gt(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), truth(VA > VB, V).
eval(ifthenelse(C, T, E), Env, V) :-
    !,
    eval(C, Env, VC),
    (   VC =:= 0 -> eval(E, Env, V)      % 0 为假
    ;   eval(T, Env, V)                  % 非 0 为真
    ).
```

**一个函子一个子句，每句开头 `!`** —— 和 19 章的 `eval/2` 同一个形状，只是多了环境参数。

### `truth/2`：本章最容易踩的一脚

```prolog
%% 把「成立 / 不成立」变成整数 1 / 0。
%% 注意参数收的是【目标】而不是布尔项：Prolog 里 VA > VB 只在被调用时才求值，
%% 写成 truth(VA > VB, V) 传进来的是项 >(VA,VB)，它既不是 true 也不是 false，
%% 所以下面必须用 call/1 去调它。
truth(Goal, 1) :- call(Goal), !.
truth(_Goal, 0).
```

> **这是从别的语言过来最容易踩的一脚。** 直觉上会写：
>
> ```prolog
> truth(true, 1) :- !.        % ✗
> truth(false, 0).            % ✗
> ```
>
> 然后 `truth(VA > VB, V)` —— **`VA > VB` 传进来的是「项」`>(VA, VB)`**，
> 它**既不是 `true` 也不是 `false`**，两个子句都不匹配，整个 `eval` 失败。
>
> **在 Prolog 里「比较表达式」不是一个「值」，是一个「目标」。** 要拿它的真假，
> 只能 `call` 它。**写这个示例时真的被它挂住过一次**，所以专门写进注释。

### `exec/3`：跑语句列表

```prolog
exec(Stmts, Env, Values) :- exec_loop(Stmts, [], Env, [], Acc), reverse(Acc, Values).

exec_loop([], Env, Env, Acc, Acc).
exec_loop([let(X, E)|Rest], Env0, Env, Acc, Values) :-
    eval(E, Env0, V),
    exec_loop(Rest, [X-V|Env0], Env, Acc, Values).
exec_loop([emit(E)|Rest], Env0, Env, Acc, Values) :-
    eval(E, Env0, V),
    exec_loop(Rest, Env0, Env, [V|Acc], Values).
```

**两个「累加器参数」**：环境 `Env` 和输出值 `Acc`。`Acc` 是**倒着攒的**，
所以最后 `reverse/2` 一次（08 章）—— 这是 Prolog 里最经典的写法：**倒着 push，最后一次反转**。

`exec_loop/5` 有 5 个参数，看起来多，但每个都在干实事：

| 参数 | 含义 |
|---|---|
| `Stmts` | 还没跑的语句 |
| `Env0` | 进来时的环境 |
| `Env` | 跑完后**出去**的环境 |
| `Acc` | 倒序攒的输出值 |
| `Values` | 最终输出（只在 `[]` 子句里跟 `Acc` 合一） |

### 演示

```text
[a] 算术与优先级：
  源码：let a = 3; let b = 4; let c = a * a + b * b; c;
    绑定表（按声明顺序）：a = 3 / b = 4 / c = 25
    输出值（按出现顺序）：25

[b] 变量遮蔽：
  源码：let a = 1; let a = 2; a;
    绑定表：a = 1 / a = 2
    输出值：2                ← 后来的生效

[c] 括号、整除、一元负号：
  let r = (2 + 3) * (4 + 1); r;        → r = 25
  let d = 17; let q = d / 4; q;        → q = 4      ← 整除
  let m = 8; let k = -m + 10; k;       → k = 2

[d] 条件：比较表达式返回 1 / 0，0 为假、非 0 为真：
  if 5 > 3 then 100 else 200;   → 100
  if 5 > 7 then 100 else 200;   → 200
  5 > 3;                        → 1

[e] 一个程序可以有多条输出：
  源码：let n = 10; n; n * n; if n > 5 then n * 2 else n;
    输出值：10 / 100 / 20
```

**`[b]` 的变量遮蔽是「关联表 + 前插」的直接副产物** —— 不需要额外代码。

## 24.5 两处设计是被可移植性逼出来的

```text
① 除法取整除（//）。因为浮点打印位数两套引擎不一致：
   SWI 打最短表示（3.14），GNU 打 17 位（3.1400000000000001）。
   语言里只要出现浮点，三通道输出就不可能逐字节一致。
② 比较返回 1 / 0 而不是 true / false。
   统一成整数后，if 的语义只有一条规则：0 为假、非 0 为真，
   不必在「布尔类型」和「整数类型」之间来回转换。
这两条都是设计决定，也都能换个做法 —— 代价是放弃跨引擎一致。
```

> **这两条是整章的题眼：一行「可移植性纪律」直接改变了语言的语义设计。**
>
> 在真实项目里你未必需要这样妥协 —— 但**知道「哪些设计会踩到跨实现差异」是有价值的**：
> 一旦你要写一个多后端的东西（多实现、多数据库、多编译器），这些经验就用得上。

## 24.6 错误路径：四类错误，四种 functor

**解释器用 `throw/1` 报错，错误项统一是「名字 + 字段」的形状**（20 章）：

```prolog
lex_error(C)                     % 输入里有非法字符
parse_error(Tokens)              % 语法不对（字段里带剩余 token）
undefined_variable(X)            % 名字没绑定
division_by_zero(VA, VB)         % 除数为 0
```

```text
[a] 非法字符（词法阶段）：      "let a = 1 & 2;"     → 抓到 lex_error/1
[b] 语法错（语法阶段）：        "let a = ;"          → 抓到 parse_error/1
                               "let a = 1 +;"       → 抓到 parse_error/1
[c] 未定义变量（语义阶段）：    "x + 1;"             → 抓到 undefined_variable(x)
                               "let a = b;"         → 抓到 undefined_variable(b)
[d] 除零（语义阶段）：          "let a = 7 / 0;"     → 抓到 division_by_zero/2
```

**四种错误的 functor 各不相同，所以调用方可以精确地分类。** 这是「用错误项的 functor
做契约」的直接好处。

> **错误项的内容是「引擎自由」的，所以打印时绝不解析。** 本章的 `show_error/1` 只对
> `undefined_variable/1` 打印完整内容（那是自己造的、字段可控），其它一律只打 `functor`。
> 这是 20 章的纪律在实战里的落地。

### 一个「不该用异常」的地方

```text
还有一个「不该用异常」的地方：查一个没绑定的变量。
等等 —— 那不就是 undefined_variable 吗？区别在于【谁的责任】：
  用户写的源码里引用了未绑定的名字 → 是程序错误 → 抛异常；
  解释器内部去查一个环境 → 查不到是正常结果 → 返回 none。
同样一件事，在语言边界内是错误，在实现内部是返回值。
```

**这是本章最值得反复读的一段设计说明**：

```prolog
lookup(X, Env, Result) :-                 % 内部：返回 some/none
    ( find_binding(X, Env, V) -> Result = some(V) ; Result = none ).

eval(ident(X), Env, V) :-                 % 边界：升级成异常
    !,
    (   lookup(X, Env, some(V0)) -> V = V0 ; throw(undefined_variable(X)) ).
```

> **同一件事，在语言边界内是错误，在实现内部是返回值。**
> **「这一层翻译发生在哪里，就是模块设计的分界线。」**
>
> 换句话说：**`some`/`none` 不是「异常的反面」，而是「还没决定是不是错误」的中间状态。**
> 决定责任归属的那个人（这里是 `eval`）才有权把 `none` 升级成异常。

## 24.7 第四步：给解释器写测试

**流水线三步都是纯谓词，所以测试特别省事**：

```prolog
%% 给测试用：只要最后一个 emit 的值
value_of(Src, V) :-
    lex(Src, Toks),
    parse_prog(Toks, Stmts),
    exec(Stmts, _Env, Values),
    last(Values, V).
```

```text
套件：核心语义
  小结：共 14 例，通过 14，不通过 0

套件：错误路径（每种错误都该抛出，functor 固定）
  小结：共 6 例，通过 6，不通过 0
```

**核心语义的用例覆盖**（14 条）：算术与优先级、变量遮蔽、括号、整除、一元负号、
条件真假、嵌套 `if` 加括号、`if 0 then 1 else 2`（0 为假）、多 `emit`。

**错误路径的用例**（6 条）：

```prolog
name(err_lex_char,   expect_throw(value_of("let a = 1 & 2;", _), lex_error)),
name(err_parse_stmt, expect_throw(value_of("let a = ;", _), parse_error)),
name(err_parse_expr, expect_throw(value_of("1 +;", _), parse_error)),
name(err_undef_var,  expect_throw(value_of("x + 1;", _), undefined_variable)),
name(err_undef_rhs,  expect_throw(value_of("let a = b;", _), undefined_variable)),
name(err_div_zero,   expect_throw(value_of("7 / 0;", _), division_by_zero))
```

**两条原则**：

```text
① 断言只比【值】（expect_set 比项本身），不比打印出来的文本；
   否则浮点位数、变量重命名这些差异会把测试弄成假绿或假红。
② 错误路径也有契约。既然 functor 是承诺的一部分，就写进测试；
   哪天有人把 division_by_zero 改名成 div0，测试立刻报警。
```

> **「错误路径也有契约」** —— 这一条把「异常」和「测试」连起来了：
> **异常的 functor 是 API 的一部分**，改名就是破坏性变更，测试会立刻抓到。
>
> **`value_of/2` 是纯的**，所以将来要换成性质测试（23 章）也行：
> 比如「对任意两组整数，加法满足交换律」—— 撒样本撞就行。

## 24.8 收尾：那些「可移植性纪律」变成了工程红利

**这个项目一共四百来行，把前面 22 章的手法都用上了**：

```text
词法    字符码、atom_codes、累加（第 15 章）
语法    DCG、分层优先、尾循环左结合（第 18、19 章）
语义    关联表、some/none、纯求值（第 08、20 章）
错误    throw/catch、自己的错误项、不解析引擎错误项（第 20 章）
测试    迷你框架、断言比项、错误路径也测（第 23 章）
展示    format 排版、~q 看 AST（第 14、16 章）
约束    三通道逐字节一致，逼出了「整除」与「1/0 当布尔」（第 07、21 章）
```

**最后一个问题：这个解释器在两边跑出来一样吗？**

```text
一样。它的每一条判定都只用公共子集，而且刻意避开了：
  · 浮点（打印位数不同）
  · CLP(FD)（两套实现，第 21 章）
  · 模块系统（GNU 没有，第 22 章）
  · 打印未绑定的变量（编号不同）
  · 解析引擎给的错误项（形状不同）
```

> **这就是 24 章下来沉淀出的那份「安全子集」—— 它不华丽，但两边都认。**

### 想继续往下走

```text
· 给语言加函数定义与递归调用 —— 会碰上闭包与作用域，这里正好练手；
· 把 AST 反向打印回源码（第 19 章做过一半：DCG 生成）；
· 加类型检查，把 undefined_variable 从运行时错误提前到静态错误；
· 把环境换成持久化数据结构，体会一下纯函数的代价与好处；
· 想做「约束求解器」这种更大件的东西，回头看第 21 章的 CLP(FD)。
```

### 最后一句话

> **Prolog 的长处不在「写得快」，而在「改得准」。**
>
> **声明式的部分越纯粹**（像这里的词法、语法、求值），
> **能被测试、能被复用、能跨实现的面积就越大。**
>
> **前面 23 章里那些看起来琐碎的「可移植性纪律」，到这里就变成了工程红利。**

## 24.9 坑位清单

1. **`truth(true, 1).` 这种写法** → 传进来的是项 `>(VA,VB)`，两个子句都不匹配。要 `call/1`。
2. **环境查找用 `=` 而不是 `==`** → 查询变量被静默绑到环境键上，隐蔽 bug。
3. **左结合写成递归下落** → `1-2-3` 变成右结合，值算错且不报错（19 章）。
4. **比较运算符写成可链式** → `a < b < c` 有歧义，本章故意让它语法错。
5. **悬空 `else` 不处理** → 嵌套 `if` 直接语法错，要加括号。
6. **用 `/` 而不是 `//`** → 浮点打印位数因引擎而异，三通道比对失败。
7. **比较返回 `true`/`false`** → 还得在布尔与整数之间转换；本章统一用 1/0。
8. **在实现内部把「找不到」升级成异常** → 责任归属错了；边界层（`eval`）才该做这件事。
9. **打印引擎给的错误项内容** → 形状因引擎而异，破坏字节级比对，只打 functor。
10. **错误路径不测** → 错误项的 functor 是 API 契约，改名却不报警。

---

上一章：[23 · 测试](23-testing.md) · 回到 [教程总览](01-overview.md)
