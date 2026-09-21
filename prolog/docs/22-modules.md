# 22 · 模块与工程组织

> 对应示例：[`examples/22_modules/22_modules.pl`](../examples/22_modules/22_modules.pl)
> 引擎专属观察：[`observe_22_swi.pl`](../examples/22_modules/observe_22_swi.pl) · [`observe_22_gnu.pl`](../examples/22_modules/observe_22_gnu.pl)

## 22.1 一个全局命名空间的问题

**Prolog 的数据库是一个全局命名空间**：所有谓词按「名字/元数」索引，谁都能看见谁。

```prolog
%% 假装来自 unit_a.pl：add 是整数加法
assertz((add(A, B, S) :- S is A + B)).
%% 假装来自 unit_b.pl：add 是把元素加到表头
assertz(add(X, List, [X|List])).

count_clauses(add, 3, N).        % N = 2
add(3, 4, R).                    % R = 7 —— 命中的是 unit_a 的子句
catch(add([], 5, _), Err, true). % 先命中 unit_a 的子句 → 直接抛类型错
```

```text
两个互不相关的单元各自定义了自己的 add/3。
在 Prolog 里它们【不是两个谓词】—— 而是同一个名字下的两组子句：
  add/3 现有子句数 2，来自两个单元，共用一条名字
  add(3, 4, R) → 7（命中的是 unit_a 的子句，结果碰巧对）
  add([], 5, R)：先命中 unit_a 的子句，直接抛类型错
```

**关键不在「哪条子句才对」**，而在于：

> **unit_b 的用户调 `add/3` 时，命中的是 unit_a 的子句** —— 对方**根本不知道**
> 自己的名字被别人占了。子句是**先到先试**的，报错信息也**不会告诉你「撞名了」**。

**这就是模块要解决的问题：让两个单元的同名谓词互不可见。**

可惜本教程的双引擎里：

| | 模块系统 |
|---|---|
| SWI-Prolog | **完整**：`:- module(名字, [导出表])`、`use_module/1,2`、`模块:目标`、`import/1`、`reexport/2` …… 一应俱全 |
| GNU Prolog | **没有**：`:- module(...)` 会被**安静地忽略掉** —— 连一行警告都没有 |

**所以本章正文走「约定式」路线**，只讲两边都能做的那部分。

## 22.2 退一步：靠前缀把名字分开

```prolog
assertz((ma_add(A, B, S) :- S is A + B)).     % math 单元：加法
assertz(lb_add(X, List, [X|List])).           % list 单元：往表头加元素
```

```text
ma_add(3, 4, R)      → 7（math 单元的加法）
lb_add(z, [a, b], R) → [z,a,b]（list 单元往表头加元素）
```

**这是 GNU 这类没有模块系统的实现的常规做法**，也是本章正文的选择：
**前缀约定 + 一个文件当一个单元边界**。

> **代价有三条，都得认：**
>
> ① **全靠人守规矩**，编译器不检查，撞名了也没人提醒你；
> ② **名字越写越长**，跨单元调用时前缀要反复抄；
> ③ **拦不住外面去调前缀里那些本该私有的谓词**（22.4 会看到这个洞）。

## 22.3 一个文件 = 一个单元边界

把「单元文件」写到磁盘上：

```prolog
write_unit_file :-
    unit_path(F),
    open(F, write, S),
    put_line(S, "%% 单元 geo —— 对外承诺：area/3 与 perimeter/3"),
    put_line(S, "%% 内部辅助：mul/3、add2/3（本该私有，但下面你会看到它们藏不住）"),
    put_line(S, ":- op(700, xfx, '===>')."),
    put_line(S, ":- dynamic(area/3)."),
    put_line(S, ":- dynamic(perimeter/3)."),
    put_line(S, "area(W, H, A) :- mul(W, H, A)."),
    put_line(S, "perimeter(W, H, P) :- add2(W, H, T), mul(2, T, P)."),
    put_line(S, "mul(A, B, R) :- R is A * B."),
    put_line(S, "add2(A, B, R) :- R is A + B."),
    close(S).

put_line(S, Line) :- format(S, "~s~n", [Line]).
```

**它的结构就是真实项目的常见样子，只有三层**：

```text
第一层  头注释 —— 写清「对外承诺什么」。没有模块系统时，
        导出清单只能靠注释，机器不检查。
第二层  指令  —— :- op(...) 与 :- dynamic(...)，
        它们是「加载时必须执行的动作」，第 7 节会看到副作用。
第三层  实现  —— area/3、perimeter/3 是承诺，
        它们再去调下面的内部辅助 mul/3、add2/3。
```

**文件之间就靠「一个文件一个单元」这条约定分工，加载谁不加载谁，就是你的依赖声明。**

> **写文件时的一个坑（本章最实用的一条）**：**内容全都作为 `~s` 的实参传进去，
> 没有一行塞进格式串。**
>
> 因为 **`%` 在格式串里是「引擎相关」的**：
>
> | | `%%` 的输出 | 单个 `%` |
> |---|---|---|
> | **SWI** | `%%`（`%` **不是**说明符） | `%`（原样） |
> | **GNU** | `%`（`%` **是**说明符） | **去实参表里找参数** → 参数不够就 `domain_error` |
>
> **两者永远不可能一致**，所以本教程的规矩是：**内容不进格式串，一律走实参。**
>
> 这条规矩落到操作上就是：**所有「把一段文本写出去」的地方都用 `put_line(S, Line)`**，
> 而不是 `format(S, "...%...")`。

## 22.4 加载一个单元：手写加载器

**一个「加载」动作要做三件事：读项、执行指令、把子句收进数据库。**
内建的 `consult/1` 就是干这个的 —— 但它有可移植性问题（22.7 说明），所以本章自己写一个：

```prolog
load_unit(F) :- open(F, read, S), load_loop(S), close(S).

load_loop(S) :-
    read(S, T),
    (   T == end_of_file -> true ; load_one(T), load_loop(S) ).

%% 读到的东西分三类
load_one((:- Goal))      :- !, load_directive(Goal).       % 指令
load_one((Head :- Body)) :- !, assertz((Head :- Body)).    % 规则
load_one(Fact)           :- assertz(Fact).                 % 事实

%% 指令【不都是】可以当普通目标调的
load_directive(dynamic(_Spec)) :- !, true.
load_directive(Goal) :- call(Goal).
```

**`load_directive/1` 这个分类是必须的**：

> **`op/3`** 两套引擎都当谓词实现，`call/1` 直接调得通。
>
> **`dynamic/1`** —— **GNU 只认它的「指令」形式，根本没有 `dynamic/1` 这个谓词**，
> 一个 `call/1` 打过去就是 `existence_error`。所以加载器必须把 `dynamic/1` 单独接住。
>
> 顺带说明：`dynamic/1` 本来也只是条**声明**，不是必须执行的动作 ——
> 后面往未定义的谓词上 `assertz` 时，两套引擎都会自动把它建成可改的谓词。

加载效果：

```text
加载完毕。先试「对外承诺」的那两个：
  area(3, 4, A)      → 12
  perimeter(3, 4, P) → 14
再试本该「私有」的内部辅助谓词 mul/3：
  current_predicate(mul/3) → 真。它在外面【也看得见】。
  而且直接调也能跑：mul(6, 7, R) → 42
```

> **这就是「没有模块系统」的真实后果：加载 = 把子句倒进同一个全局数据库，
> 根本没有边界。导出清单只能写在注释里，靠人守。**
>
> SWI 的 `module/2` 能真的把 `mul/3` 藏起来（见 `observe_22_swi.pl`），
> GNU 连 `module/2` 都不认，上面这个「看得见」就是它的极限。

## 22.5 静态编译与运行时加载是冲突的

**这一节是第三通道 `gplc` 逼出来的。**

`gplc` 把源码编译成本地二进制，**所有谓词调用都在「链接期」解析成符号地址**。

```prolog
%% 如果正文里直接写这一句：
area(3, 4, A).       % ← 链接器去找 area/3 的符号
```

**但 `area/3` 是程序跑起来之后才加载进来的** —— 于是链接失败：

```text
Undefined symbols: predicate(area/3)
```

**解法：把名字当「原子」用，用 `=..` 现拼目标再 `call/1`。**

```prolog
mcall(Name, Args) :- Goal =.. [Name|Args], call(Goal).
```

```text
=.. + call/1 就能跑到：area(3, 4, A) → 12
代价：丢掉了编译期的名字检查。名字写错不会在编译时报错，
要等运行到那一句才知道（existence_error）。
```

> **更省事的做法是：把加载边界放到「程序启动之前」** ——
> 用 `:- consult(...)` 这种**指令**加载，那样谓词在**加载期**就位，
> 正常调用即可，**不必元调用**。
>
> **运行时加载只有一个场景值得付出这个代价：插件 / 配置驱动的扩展点。**

> **`=..` + `call/1` 在本教程出现过三次，都是为了同一个原因（绕过 `gplc` 的静态链接）：**
> 21 章的 `label/1`、`all_different/1`、`in/2`；本章的运行时加载谓词。**记住这个模式。**

## 22.6 重复加载：叠加还是替换

```text
第一次加载之后，area/3 的子句数：1
再加载同一个文件之后：2 —— 手写加载器是【叠加】的
先 retractall 再加载：1
```

**内建的 `consult/1` 自带「先清后加」的替换语义**，重复加载不会堆子句；
**手写加载器没有这一步，所以要自己补 `retractall`**：

```prolog
mretractall(Name, Arity) :-
    (   current_predicate(Name/Arity)
    ->  functor(Head, Name, Arity), retractall(Head)
    ;   true
    ).
```

### 【本章为什么不用 `consult/1`】

> **GNU 的 `consult` 会往 stdout 打编译进度**：
>
> ```text
> compiling /tmp/... .pl for byte code...
> /tmp/... .pl compiled, 6 lines read - 1074 bytes written, 4 ms
> ```
>
> **SWI 不打。** 这一行要是落在输出里，三通道就不一致了。

**所以只要示例里调一次 `consult`，两个引擎的输出就不可能逐字节一致。**
尝试过的缓解手段都不行：`set_prolog_flag(quiet, on)` 压不住它；
`tell('/dev/null')` 也捕获不到它（它不走流接口）。

> **真实项目里 `consult` 是标准做法** —— 只有当你要求跨引擎输出一致时，
> 才会像本章这样自己动手。

## 22.7 加载的副作用：运算符表是全局的

单元文件开头有一条指令：`:- op(700, xfx, '===>').`

```text
加载之后 current_op(_, xfx, '===>') → 真。
运算符表是【全局】的：加载一个文件，新运算符就进了整个程序。
```

**同类的「加载即改变全局状态」还有**：

| 副作用 | 影响 |
|---|---|
| `op/3` | 改**运算符表** |
| `set_prolog_flag/2` | 改**引擎标志**（本教程每个文件开头都在做这件事） |
| `dynamic/1` | 改**谓词属性** |
| `include/1` | 文本包含，**连运算符声明都会一起带进来** |

> **所以单元文件应当把副作用压到最小** —— 这也是「加载边界」的一部分。
>
> **可移植代码的额外理由**：两套引擎的运算符集、标志集本来就不一样，
> **加载进来的东西越多，两边跑出不同结果的机会就越大。**

## 22.8 `include/1` 不是 `consult/1`

**`include/1` 在运行时不可调用** —— 它只能写在**指令位置**：

```prolog
:- include('文件.pl').        % 唯一合法的位置
```

| | `consult(F)` | `:- include(F)` |
|---|---|---|
| 层级 | **逻辑级**：把 `F` 当成一个程序单元加载（读项、执行指令、收子句） | **文本级**：等价于把 `F` 的内容**原样抄**到这个位置 |
| 运算符声明 | 作为指令执行 | **立刻生效**（因为就是文本替换） |
| 行号 | 各自独立 | **两个文件混在一起算** |

```text
一句话：include 是文本级的，consult 是逻辑级的。
```

> **本教程正文一个 `include` 都没用** —— 它不可移植（上面的「运行时不可调用」
> 就是证据），而且副作用比 `consult` 更难追。

## 22.9 两个引擎的原生能力（观察通道）

### SWI：真模块系统

```text
--- 1. 加载模块：导出进来，内部藏住 ---
  它第一行就是 :- module(geo, [area/3, perimeter/3]).
  这个头【必须在第一条】—— 放到后面，use_module 会直接拒绝：
    Domain error: module_header expected, found ...
  加载后 current_predicate(area/3) → 真（导出表里的，进了 user）
  而 current_predicate(mul/3) → 假 —— mul/3 被【真的藏住了】
  current_predicate(geo:mul/3) → 真 —— 它不是不存在，是「没导出」
```

**「私有」只是不导出，限定名照样能到**：

```text
geo:mul(6, 7, R) → 42（模块限定的调用，越过了导出表）
所以 SWI 的「私有」是约定 + 导入控制的产物，不是权限墙。
```

**两个模块各自导出同名 `area/3`，互不干涉** —— 这就是 22.1 那个「撞车」问题的正规解法：

```text
geo:area(3, 4, A) → 12（geo 的 area 是面积）
alt:area(3, 4, A) → 14（alt 的 area 是周长）
```

**导出表与导入表是两回事**：

```text
use_module(文件, [foo/1]) 之后 foo/1 可见
而没写进导入表的 bar/1 不可见 —— 导入表是精确控制的
模块自己的【导出表】决定谁能拿，使用方的【导入表】决定自己拿哪些。
```

**`exported` 属性 ≠ 「能被调用」**：

```text
predicate_property(geo:area(_,_,_), exported) → 真
predicate_property(geo:mul(_,_,_), exported) → 假
exported 是【模块声明过】的属性，不是「能被调用」的属性：
geo:mul 没有 exported，可第 2 节里它照样调得通。
```

### GNU：同一份文件，结论完全相反

```text
它和 observe_22_swi.pl 写的是【同一份】内容，
第一行就是 :- module(geo, [area/3, perimeter/3]).
注意下面 consult 的输出里【没有】任何 unknown directive 警告 ——
GNU 认得 module/2 这个名字，但选择安静地忽略它。
（对照一下：写个真不认识的 :- modulex(...). 它会警告
  unknown directive modulex/2 —— 所以 module/2 是「认识但不做」。）
这种「安静地忽略」比报错更危险：你以为封装生效了，其实没有。
```

```text
current_predicate(area/3) → 真（导出表里的）
current_predicate(mul/3) → 真 —— 内部辅助谓词照样【全局可见】
而且直接调也是通的：mul(6, 7, R) → 42
```

> **「认识但假装没看见」比报错更危险** —— 报错至少你会知道。
> **GNU 静默忽略 `module/2`，意味着你以为封装生效了，其实一点都没有。**
> 这是本章最需要记住的一条。

**GNU 上做「模块」只有三条现实手段**：

```text
① consult/1（或 :- include/1）把文件加载进来，一个文件当一个单元；
② 对外名字加前缀（正文第 2 节的 ma_add / lb_add 那种做法）；
③ 导出清单写在文件头注释里，靠人守。
```

补一个实操细节：**既然藏不住，就别假装有封装** —— 把**内部谓词也起成带前缀的名字**，
至少让人一眼看出「这是别家的内部实现，不该调」。

**`GNU` 可用的加载接口就两个**：

```text
consult/1        可用（但会打编译进度）
:- include(文件). 只能写在【指令】位置，运行时 call/1 调不通。
两者之外没有第三条路：GNU 没有 ensure_loaded/1，也没有 use_module。
```

## 22.10 可移植性清单

| 特性 | SWI | GNU |
|---|---|---|
| `:- module(名, [导出])` | ✅ 且**必须是文件第一条指令** | **静默忽略**（不报错、不警告） |
| `use_module/1,2` | ✅ | 无此谓词 |
| `import/1`、`reexport/2`、`meta_predicate/1` | ✅ | 无 |
| `模块:目标` | ✅ | **`:` 根本不是运算符** |
| `consult/1` | ✅ 安静 | ✅ 但**往 stdout 打编译进度** |
| `:- include/1` | ✅ | ✅（同样只能指令位置） |
| `ensure_loaded/1` | ✅ | 无 |
| `dynamic/1` 谓词形式 | ✅ | **只有指令形式** |
| `current_predicate/1` 看内建 | ✅ | **看不到内建谓词** |

**所以本章的可移植方案是三条约定**：

```text
① 一个文件 = 一个单元；
② 对外名字加前缀，导出清单写在文件头注释里；
③ 真要「藏起来」时承认做不到 —— 要么接受 SWI 专有，要么别藏。
```

> **两份观察文件读的是「同一个文件」，结论却相反 —— 这就是「有没有模块系统」的全部差别。**
> `observe_22_swi.pl` 里 `mul/3` 被真的藏住，`observe_22_gnu.pl` 里它照样可见。

## 22.11 坑位清单

1. **两个文件定义同名谓词** → 同一个全局谓词，先到先试，报错信息不提示撞名。
2. **依靠 `:- module(...)` 做封装** → GNU 静默忽略，封装完全无效。
3. **`:- dynamic item/2.` 不带括号** → GNU 语法错误（`dynamic` 不是前缀运算符）。
4. **把 `:- module(...)` 放到文件中间** → SWI 直接报 `module_header expected`。
5. **在 `gplc` 通道里直接调用运行时加载的谓词** → `Undefined symbols`，必须 `=..` + `call/1`。
6. **以为 `=..` + `call/1` 还能有编译期检查** → 名字错要到运行时才知道。
7. **手写加载器不补 `retractall`** → 重复加载子句叠加，谓词越长越乱。
8. **示例里直接调 `consult/1`** → GNU 往 stdout 打编译进度，三通道比对失败。
9. **把内容拼进 `format` 格式串** → `%` 的语义两套引擎不同，必须走 `~s` 实参。
10. **运行时 `call(include(F))`** → 两个引擎都报错，`include` 只能写在指令位置。

---

上一章：[21 · 约束求解](21-constraints.md) · 下一章：[23 · 测试](23-testing.md)
