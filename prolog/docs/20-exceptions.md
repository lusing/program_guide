# 20 · 异常处理

> 对应示例：[`examples/20_exceptions/20_exceptions.pl`](../examples/20_exceptions/20_exceptions.pl)

## 20.1 一句话原则

> **异常用于「编程错误与环境问题」，不用来表达「没找到」。**

这条原则贯穿全章。它决定了 `throw`/`catch` 在什么场合该出现，
也决定了你会写出好维护的 Prolog 还是难懂的 Prolog。

## 20.2 最基本的一对：`throw` / `catch`

```prolog
risky(0) :- throw(zero).
risky(N) :- N > 0, R is 100 / N, format("  risky(~w) = ~w~n", [N, R]).

catch(risky(0), zero, say("  捕到 zero：risky(0) 抛了 zero")).
```

`catch(Goal, Catcher, Recovery)`：执行 `Goal`；如果它抛出**与 `Catcher` 合一**的异常项，
就执行 `Recovery`（并在 `Recovery` 成功后，`catch` 整体成功）。

```text
risky(8) = 12.5
catch(risky(8), zero, ...) 整体成功
risky(8) 没抛异常，所以 Recovery 没执行 —— 上面这行只是说明它成功了。
捕到 zero：risky(0) 抛了 zero
```

**这里有一个非常反直觉的地方**：

> **`catch/3` 本身永远是「成功」的**（只要 `Recovery` 成功）。
> **所以判断有没有出错不能看 `catch` 的成败，要看它做了什么。**

上面第一行 `catch(risky(8), zero, ...)` 是成功的 —— 但**这跟 `zero` 没关系**，
只是因为 `risky(8)` 自己成功了。

### 捕不中时会「重抛」，不是「失败」

这是本章**最重要的一个坑**：

```prolog
%% 不匹配的异常不会变成失败，而是原样再抛出去 —— 靠嵌套 catch 才看得见
catch(catch(risky(0), other_error, say("  内层捕到 other_error")),
      zero,
      say("  内层用 other_error 没捕到 → 原样重抛 → 外层用 zero 捕到了")).
```

```text
内层用 other_error 没捕到 → 原样重抛 → 外层用 zero 捕到了
关键区别：catch 捕不中时是【重抛】，不是【失败】——
所以别把 catch 放进 if-then-else 的失败分支去判「有没有异常」。
```

**实践含义**：想用 `( catch(...) -> 有异常 ; 没异常 )` 这种写法判「有没有抛异常」是**错的** ——
异常不匹配时会穿出去，`;` 分支根本不会执行。

> **正确写法**是让 `Recovery` 显式记录「捕到了什么」，然后看那个值 ——
> 见下面 20.4 的 `validate_age` 例子。

## 20.3 `throw` 会把异常项**复制**一份

```prolog
Ball = tagged(1),
catch(throw(Ball), tagged(X), true).        % X = 1，但 Ball 不受影响
```

```text
捕到 tagged(1)
抛出的项与接收到的变量之间【没有共享】：catch 内外的变量不会互相绑定。
```

**验证**（这个证据很直观）：

```prolog
Payload = payload(Inside),
catch(throw(Payload), payload(_), true),
var(Inside).        % 成立 —— 抛出项里的变量在外面仍然是空的
```

**原因**：`throw` 在抛出前做了 `copy_term`（12 章），避免「异常把调用者的变量绑了」。
这是**特性不是 bug** —— 如果异常能让调用者的变量被绑定，回溯行为会变得无法推理。

> **实践含义：别指望用异常回传变量绑定。** 要回传数据就**在异常项里带上** ——
> 比如 `throw(div_by_zero(Left, Right))` 而不是指望 `Right` 能绑出来。

## 20.4 只捕你要捕的：分类与穿透

**自定义异常用「名字 + 字段」表达错误的种类**：

```prolog
validate_age(A, ok) :-
    integer(A), A >= 0, A =< 150, !.
validate_age(A, _) :-
    \+ integer(A), !,
    throw(bad_input(age, not_an_integer(A))).
validate_age(A, _) :-
    throw(out_of_range(A, 0, 150)).
```

```prolog
forall(member(A, [30, -5, 200, foo]),
       (   % 外层兜住「没人接」的异常，才能把它打印出来
           catch(catch(validate_age(A, R),
                       out_of_range(V, Lo, Hi),
                       R = rejected(range(V, Lo, Hi))),
                 Escaped,
                 R = escaped(Escaped))
       ->  format("  validate_age(~w) -> ~w~n", [A, R])
       ;   format("  validate_age(~w) -> 无解~n", [A])
       )).
```

```text
validate_age(30) -> ok
validate_age(-5) -> rejected(range(-5,0,150))
validate_age(200) -> rejected(range(200,0,150))
validate_age(foo) -> escaped(bad_input(age,not_an_integer(foo)))
```

**双层 `catch` 的结构是刻意的**：

- **内层**只捕 `out_of_range`，把异常「翻译」成一个普通返回值 `rejected(range(...))`。
- **外层**兜住「没人接」的异常（`Escaped`），转成 `escaped(...)`。

```text
注意 foo 那条：它抛的是 bad_input(...)，与 out_of_range 不匹配，
于是原样重抛，被最外层兜住 —— 这就是「不吞异常」的写法。
工程准则：catch 只捕你明确知道怎么处理的异常，其它一律放行。
```

> **「不吞异常」是异常处理的头号准则。** `catch(G, _, true)` 这种「全捕」写法会把
> 拼写错误、`instantiation_error`、栈溢出统统吞掉，让 bug 变成静默错误。
>
> **想全兜住，就用 `error/2` 的形状判断**（下一节）或者明确地用变量接住再打印出来。

## 20.5 ISO 运行时错误的形状

```text
1 + a      -> 错误名 error
空变量参与 -> 错误名 error
call(空变量) -> 错误名 error
这些错误项都是 error(Formal, Context) 的形状，functor 一律是 error。
```

`1 + a` 抛 `error(type_error(evaluable, a/0), Context)`，
`X is Y + 1` 抛 `error(instantiation_error, Context)` —— **形状都是 `error/2`**。

> **但 `Formal` 与 `Context` 的具体内容是引擎自由的** —— 两套引擎填的东西不一定一样。
>
> **所以可移植代码只能靠「自己 `throw` 的项」来区分，不要解析引擎给的结构。**
>
> **唯一稳妥的例外**：捕 `error(_, _)`，然后一律转成自己的错误处理。
>
> ```prolog
> catch(Goal, error(Formal, _Ctx),
>       ( functor(Formal, F, _), format("  内部错误：~w~n", [F]) )).
> ```
>
> 本教程的 24 章解释器就是这么做的：**打印时只打印 `functor` 名**，绝不打印完整结构 ——
> 因为完整结构因引擎而异，会破坏字节级比对。

## 20.6 `some` / `none`：把「可能没有」变成值

这是**「不用异常表达没找到」**的正面样板：

```prolog
find_user(1, some(user(alice, 30))).
find_user(9, none).
```

```text
find_user(1) -> some(user(alice,30))
find_user(9) -> none
```

**好处**：调用方拿到的一定是一个值 —— 可以继续用 `~w` 打印、塞进列表、
用 if-then-else 分支，**不会因为「空而失败」把控制流打散**。

**坏处**：多一次显式拆包。所以两种风格要**按场景选**：

| 风格 | 适用场景 |
|---|---|
| **靠失败** | 「搜索 / 遍历」这类**天然可回溯**的场景（`member/2`、`select/3`） |
| **`some`/`none`** | 「查表 / 解析」这类**调用者需要明确知道结果有无**的场景 |

```text
拆包 some：alice 岁 30
拆包 none：没有这个用户（这就是 none 的意义）
```

> **本教程第 24 章的解释器对「变量未定义」就用 `none` 表达** ——
> 因为「查环境表找变量」正是那种「调用者必须知道结果有无」的场景。

## 20.7 别用异常做正常控制流

```text
Prolog 里「找不到」的标准表达是【失败】，不是抛异常：
  member(c,[a,b]) 失败 —— 这就是它的正常语义，不需要异常

什么时候该 throw：
  · 输入违反了接口约定（类型错、范围错）—— 这是「编程错误」
  · 环境不允许继续（文件打不开、资源耗尽）

什么时候不该 throw：
  · 搜索没找到解（用失败）
  · 用来跳出循环（用 ! 或递归）
```

**用异常做控制流的代价**（这是最实在的理由）：

1. **`catch` 会把中间的选择点砍掉** —— 回溯行为变得难以推理。你在 `catch` 里造的选择点
   **不会**被外面的回溯重新访问。
2. **两套引擎对错误项的填充不一致** —— 靠异常类型分派逻辑不可移植。
3. **性能** —— 抛异常比「失败」贵得多。

> **最后一条**：**没有 `catch` 的异常会打到顶层并把程序终止**。
> 所以本教程所有示例的 `main/0` 都把 `run/0` 包在 `catch` 里（02 章）：
>
> ```prolog
> main :-
>     (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
>     ->  halt(0)
>     ;   format(user_error, "*** run/0 失败~n", []), halt(1)
>     ).
> ```
>
> **诊断信息走 stderr，退出码区分成败** —— 这样正常输出能被脚本逐字节比对。

## 20.8 坑位清单

1. **`( catch(G, _, fail) -> ... ; ... )` 判有没有异常** → 不匹配时是**重抛**，不是失败。
2. **看 `catch/3` 的成败判断「出没出错」** → `catch` 永远是成功的（只要 Recovery 成功）。
3. **`catch(G, _, true)` 全捕** → 把 bug 吞成静默错误。只捕你懂的。
4. **指望异常回传变量绑定** → `throw` 前 `copy_term` 过，绑定不出来，数据要放进异常项。
5. **解析引擎给的 `error(Formal, Context)`** → 具体内容是引擎自由的，不可移植。
6. **用异常表达「没找到」** → 该用失败（或 `some`/`none`）。`catch` 会砍掉选择点。
7. **用异常跳循环** → 用 `!` 或递归。
8. **`throw` 一个含自由变量的项再指望它被绑** → 同上，复制过了。
9. **`main/0` 不包 `catch`** → 异常打到顶层终止程序，输出脏、退出码也不对。
10. **诊断信息写 stdout** → 会污染正常输出，破坏按字节比对（15 章、14 章）。

---

上一章：[19 · 写一个解析器](19-parser.md) · 下一章：[21 · 约束求解](21-constraints.md)
