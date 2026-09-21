# Prolog 速查表

语法速查 + 226 条实测坑位索引。双引擎：**SWI-Prolog 10.0.2** / **GNU Prolog 1.5.0**。
详细讲解见对应章（`N.M` = 第 N 章第 M 节）。

## 1. 命令速查

```bash
# 通道 1：SWI 解释执行
swipl -Dencoding=utf8 -q -f FILE.pl \
      -g "set_stream(user_output,encoding(utf8)),main" -t halt

# 通道 2：GNU 解释执行
gprolog --consult-file FILE.pl --entry-goal main

# 通道 3：gplc 编译成无依赖本地二进制（只在当前目录可靠）
{ echo ':- initialization(main).'; cat FILE.pl; } > build/NN.pl
cd build && gplc NN.pl -o NN.bin && ./NN.bin < /dev/null      # ← stdin 必须重定向！

# 交互式（调试用）
swipl                      # ?- consult('x.pl').  /  ?- halt.
gprolog                    # | ?- consult('x.pl'). /  | ?- halt.
```

```bash
./run-all.sh               # 全量，只打摘要
./run-all.sh -v            # 附输出区间
./run-all.sh 07 21         # 只跑指定编号
./run-all.sh -Clean        # 清 build/
pwsh ./build.ps1 -All      # PowerShell 等价入口
pwsh ./build.ps1 -Example 21
pwsh ./build.ps1 -Help
```

## 2. 六条判定（`run-all.sh` / `build.ps1` 共用）

```text
1  退出码 0
2  stderr 为空（连 singleton 警告都不许有）
3  stdout 含 "==== NN 开始 ====" 与 "==== NN 结束 ===="
4  区间非空、无 CR/ESC 等控制字符
5  区间内无 uncaught / command-line goal / 异常: / 运行失败
6  三通道抽出的区间【逐字节相同】
```

每个文件的骨架：

```prolog
:- set_prolog_flag(double_quotes, codes).     % ← 必写！SWI 默认 string，GNU 默认 codes

main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []), halt(1)
    ).

run :- format("==== NN 开始 ====~n", []), ..., format("==== NN 结束 ====~n", []).
```

**正常输出走 stdout，诊断走 stderr**；两条标记圈出**可比对区间**（把它们之外噪声滤掉）。

## 3. 项与合一（04/05）

```prolog
X = f(Y).           % 合一：双向绑定，可解方程
X == f(Y).          % 同一性：现在是否已相同，永不绑定
X \= Y.             % 不能合一（≠ 不是不等于）
f(a,B) = f(A,b).    % A=a, B=b
X = f(X).           % 发生检查默认关闭 → 造出循环项（04.6）

functor(T, N, A).   % f(a,b) → N=f, A=2
arg(1, T, X).       % 下标从 1 开始！
T =.. [F|Args].     % univ：项 ↔ [函子|实参]
copy_term(T, C).    % 复制（变量独立）
term_variables(T, Vs).

% 标准项序（04.7）：变量 < 数字 < 原子 < 复合项；同类型再按各自规则
```

## 4. 类型判定（12）

```prolog
var/1  nonvar/1  atom/1  number/1  integer/1  float/1
atomic/1  compound/1  callable/1  is_list/1  ground/1
```

```prolog
atom([])            % SWI 假 / GNU 真 —— 不可移植！判空用 length(L,0)
number(42)  ==真    % 整数与浮点统称 number
is_list([1,2])      % 真
compound([1,2])     % 也真（列表就是 '.'/2）
```

## 5. 算术与比较（07）

```prolog
X is 1 + 2.        % 求值并绑定 → 3
1 + 1 =:= 2.       % 算术比较 → 真
1 + 1 == 2.        % 同一性 → 假（左边是项 +(1,1)）
1 + 1 = 2.         % 合一 → 假
X =:= 2, X is 3.   % ← X 未绑定时 =:= 抛 instantiation_error
```

| 运算 | 说明 |
|---|---|
| `+ - *` | 两引擎一致 |
| `//` | **整除**（安全） |
| `/` | 结果类型因引擎而异（`8/4` → 整数 vs 浮点）→ **跨引擎比对禁用** |
| `mod` `rem` | 可用（但 21 章 fd 里 GNU 不支持 `mod`） |
| `**` | xfx 非结合 + 结果类型不一致 → **不用**；幂用 `^` |
| `trunc` | **GNU 缺失** → 用 `truncate` |
| `max/2` `min/2` `abs/1` `sign/1` `gcd/2` | 可用 |

## 6. 列表（08）

```prolog
[H|T]  []  [a,b|T]
member/2  append/3  length/2  reverse/2  nth0/3  nth1/3  last/2  sum_list/2
sort/2     % 排序 + 去重
msort/2    % 排序、保留重复
keysort/2  % 按 K-V 的 K 排
```

```prolog
% SWI 有、GNU 没有 → 手写
include/3  exclude/3  foldl/4  aggregate_all/3  sort/4  list_to_set/2  predsort/3
```

## 7. 递归与累加器（09）

```prolog
len([], 0).
len([_|T], N) :- len(T, N1), N is N1 + 1.     % ← 非尾递归，做不了 (-,+) 生成模式

len_acc(L, N) :- len_acc(L, 0, N).             % 尾递归，不消耗栈
len_acc([], Acc, Acc).
len_acc([_|T], Acc, N) :- Acc1 is Acc + 1, len_acc(T, Acc1, N).
```

**倒着攒、最后一次 `reverse/2`** 是 Prolog 最常见的模式（24 章的 `exec_loop/5`）。

## 8. 剪枝与否定（10）

```prolog
(G -> T ; E)      % if-then-else：G 的第一个解成立就走 T，否则 E
(G *-> T ; E)     % soft-cut：G 的【所有】解都要走 T（SWI 有，GNU 无）
\+ G              % 否定即失败（= not provable now）
once(G)           % 只取第一个解
!                 % 砍掉当前谓词剩余的选择点 + 左侧目标的选择点
```

| 类型 | 样子 | 用途 |
|---|---|---|
| **绿切** | 子句互斥时剪 | ✅ 安全，提升性能 |
| **红切** | 靠 `!` 表达逻辑「否则」 | ⚠️ 谓词不再对称，慎用 |

## 9. 高阶与元调用（11）

```prolog
call(G)  call(G, A1)  call(G, A1, A2) ...     % call/1..8
maplist(P, L)   maplist(P, L1, L2)
forall(Cond, Action)                          % ≡ \+ (Cond, \+ Action)
Goal =.. [Name|Args], call(Goal)              % 组装目标 ⇒ Prolog 版反射
```

**闭包 = 谓词名 + 部分实参**（`plus(3)`）；`call/N` 只能**往尾部追加**参数，
所以**配置参数要放前面**。

## 10. 解集收集（13）

| 谓词 | 无解时 | 分组 | 排序去重 |
|---|---|---|---|
| `findall(T, G, L)` | **成功，`[]`** | 从不 | 不 |
| `bagof(T, G, L)` | **失败** | **按自由变量分组** | 不 |
| `setof(T, G, L)` | **失败** | 同 bagof | **排序 + 去重** |

```prolog
findall(X-G, bagof(Y, likes(X,Y), G), Groups).   % bagof 多解，要 findall 收
bagof(Y, X^likes(X,Y), All).                     % ^ 藏起 X，不参与分组
findall(_, likes(nobody,_), L).                  % findall 不认 ^/2 → 会报错！
```

```prolog
% 可移植聚合（aggregate_all/3 只有 SWI 有）
count_all(G, N)  :- findall(dummy, call(G), L), length(L, N).
sum_of(T, G, S)  :- findall(V, (call(G), V = T), Vs), sum_rec(Vs, S).
```

## 11. I/O（14）

```prolog
open(F, read|write|append, S), ..., close(S).
format(S, "~w~n", [X]).         % format/1 【不存在】，必须给实参列表
write/1  writeq/1  print/1       % write 不加引号、writeq 加
write_term(S, T, [quoted(true)]).
put_char/1  put_char/2  nl/0  nl/1  tab/1     % tab 只有标准输出版
read(S, T).      % 文件尾返回原子 end_of_file（不是异常）
read_term(S, T, [variables(Vs)]).
get_code/2  % 拿整数码（~s 要吃码列表）
get_char/2  % 拿单字符原子
see/1 tell/1 seen/0 told/0       % 老接口，全局状态，别用
```

**格式说明符（两引擎共通）**：`~w ~q ~a ~d ~c ~s ~2f ~3f ~e ~g ~r`，`~n` 不吃参数。
**字面 `~` 写 `~~`；内容绝不进格式串**（见坑 22-5）。

## 12. 文本（15）

```prolog
'abc'            % 原子
"abc"            % 码列表 [97,98,99]（设了 double_quotes=codes 之后）
['a','b','c']    % 单字符列表

atom_codes/2  atom_chars/2  atom_length/2  sub_atom/5  atom_concat/3
char_code/2   % 单个字符 ↔ 码（不是码列表！）
number_codes/2  number_chars/2
```

```prolog
sub_atom(A, Before, Length, After, Sub)     % 第 3 个是【长度】不是终点
sub_atom(A, 0, N, _, P)     % 前缀
sub_atom(A, _, _, 0, S)     % 后缀
```

```prolog
% SWI 有、GNU 没有 → 手写
split_string/4  atomic_list_concat/3  upcase_atom/2  downcase_atom/2
atom_to_term/3  term_string/2  with_output_to/2
```

## 13. 运算符（16）

```prolog
:- op(优先级, 类型, 名字).       % 优先级 1..1200，越大越松
% 类型：xfx xfy yfx（中缀） fy fx（前缀） xf yf（后缀）
% x = 该侧必须严格更松；y = 可以相等
current_op(P, T, N).            % 问引擎（比背表靠谱）
```

| 优先级 | 运算符 | 类型 |
|---|---|---|
| 1200 | `:-` `-->` | xfx |
| 1100 | `;` | xfy |
| 1050 | `->` | xfy |
| 1000 | `,` | xfy |
| 900 | `\+` | fy |
| 700 | `=` `is` `=..` `==` `\=` | xfx |
| 600 | `:` | xfy |
| 500 | `+` `-` | yfx |
| 400 | `*` `/` `//` `mod` | yfx |
| 200 | `^` | **xfy**（不是 xfx） |
| 200 | `-`（负号） | fy |

```prolog
write_canonical(T)     % 把运算符还原成函子写法 —— 看解析树的最佳工具
```

## 14. 动态数据库（17）

```prolog
:- dynamic(item/2).        % GNU 必须带括号！`:- dynamic item/2.` 是语法错误
assertz/1  asserta/1       % 尾部 / 头部插入，永成功
retract/1                  % 删第一条，无匹配则【失败】，会留选择点
retractall/1               % 删全部，【永成功】
clause(H, B)               % 反射：事实的 B 是 true
abolish(Name/Arity)        % 删整个谓词（慎用；静态谓词行为两引擎不同）
current_predicate(Name/Arity).    % GNU 看不到内建谓词！
```

**回溯会撤销绑定，但不会撤销副作用** —— 失败的查询可能已经改了库。

## 15. DCG（18/19）

```prolog
ab --> [a], [b].                    % 终结符
anbn --> [].                        % 递归 → 上下文无关能力
anbn --> [a], anbn, [b].
three_x(N) --> [x],[x],[x], {N is 3}.      % {} 不消耗输入，做计算/校验
phrase(NT, Toks).                   % 必须吃光
phrase(NT, Toks, Rest).             % Rest 是没消耗的尾巴
```

```prolog
% 展开：NT//N ⇒ 普通谓词 NT/(N+2)，多出的两个参数 = 输入 / 剩余输入
ab(S0, S) :- S0 = [a|S1], S1 = [b|S].
```

**运算符左结合必须用「尾循环 + 累加器」**：

```prolog
expr(E)  --> term(A), expr_rest(A, E).
expr_rest(A, E) --> ['+'], term(B), expr_rest(plus(A,B), E).
expr_rest(A, A) --> [].
```

**DCG 里想吐出一段现成列表，不能直接写变量**（会被当非终结符 `call`）：

```prolog
codes_term([])     --> [].
codes_term([C|Cs]) --> [C], codes_term(Cs).       % 逐个吐
```

## 16. 异常（20）

```prolog
throw(Ball).
catch(Goal, Catcher, Recovery).      % 合一不上 → 【重抛】，不是失败！
```

```prolog
% 自定义错误项：名字 + 字段
throw(undefined_variable(X)).
throw(division_by_zero(A, B)).
throw(parse_error(Tokens)).

% 分类捕获：只捕你懂的
catch(G, out_of_range(V,Lo,Hi), R = rejected(range(V,Lo,Hi))).
```

**ISO 错误形状**（内容引擎自由，**只打 `functor`，不解析**）：

```prolog
error(Formal, Context)     % Formal: instantiation_error / type_error(T, Culprit)
                           %         domain_error(D, Culprit) / existence_error(...)
```

**「没找到」用失败表达，不用异常**；要显式表达有无，用 `some(X)` / `none`。

## 17. CLP(FD)（21）

**两套实现彼此独立，变量内部表示都不一样：**

| | GNU | SWI |
|---|---|---|
| 加载 | 内建 | `:- use_module(library(clpfd)).` |
| 域 | `fd_domain(V, Lo, Hi)` | `V in Lo..Hi` |
| 标号 | `fd_labeling/1` | `labeling/1` |
| 互不相同 | `fd_all_different/1` | `all_distinct/1`、`all_different/1` |
| 变量类型 | **独立类型**（`var/1` 假） | **属性变量**（`var/1` 真） |
| 未标号的打印 | `_#0(6..9)` | `_1870` |
| 最优化 | `fd_maximize/2` | `labeling([max(Z)], Vs)` |
| 具体化 | 无 | `#<==> #==> #\/ #/\` |

**公共子集就三个动作**（三步走）：

```prolog
domain(X, 1, 9),                    % ① 域
X #> 5,                             % ② 约束
findall(X, labeling([X]), All).     % ③ 标号（可回溯，遍历整个解空间）
```

**可移植适配层**（本章正文用的就是它）：

```prolog
engine(swi)     :- current_prolog_flag(dialect, swi), !.
engine(gprolog) :- current_prolog_flag(dialect, gprolog), !.
engine(unknown).

swi_meta(Name, Args) :- Goal =.. [Name|Args], call(Goal).   % ← 躲 gplc 静态链接

domain(V,Lo,Hi) :- engine(gprolog), !, fd_domain(V,Lo,Hi).
domain(V,Lo,Hi) :- swi_meta(in, [V, '..'(Lo,Hi)]).          % ← 躲 GNU 没定义的运算符
labeling(Vs)  :- engine(gprolog), !, fd_labeling(Vs).
labeling(Vs)  :- swi_meta(label, [Vs]).
alldiff(Vs)   :- engine(gprolog), !, fd_all_different(Vs).
alldiff(Vs)   :- swi_meta(all_different, [Vs]).
```

**`=` / `=:=` / `is` / `#=` 一句话区分**：

```text
=      结构合一，不管算术
=:=    算术比较，两边都要有值
is     算术求值 + 绑定，左边必须是变量
#=     加等式约束，两边可含未绑定变量  ← is 用不了的地方它能用
```

```prolog
% 解的顺序是引擎实现细节 → 比对前先 sort/2
findall(N, queens(8,N,_), Ls), sort(Ls, Sorted).
N 皇后解数：4→2  5→10  6→4  7→40  8→92
```

## 18. 模块（22）

**GNU 没有模块系统**；`:- module(...)` 被**静默忽略**（不警告！比报错更危险）。

| 特性 | SWI | GNU |
|---|---|---|
| `:- module(名, [导出/元数])` | ✅ **必须是文件第一条指令** | 静默忽略 |
| `use_module/1,2` | ✅ | 无 |
| `import/1` `reexport/2` `meta_predicate/1` | ✅ | 无 |
| `模块:目标` | ✅ | **`:` 不是运算符** |
| `consult/1` | ✅ 安静 | ✅ 但**往 stdout 打编译进度** |
| `:- include(F)` | ✅ | ✅（**只能指令位置**） |

**可移植三条约定**：① 一个文件 = 一个单元；② 对外名字加前缀，导出清单写文件头注释；
③ 真要「藏起来」就承认做不到。

**手写加载器**（GNU 的 `consult` 会污染 stdout）：

```prolog
load_unit(F) :- open(F, read, S), load_loop(S), close(S).
load_loop(S) :- read(S, T), ( T == end_of_file -> true ; load_one(T), load_loop(S) ).

load_one((:- Goal))      :- !, load_directive(Goal).
load_one((Head :- Body)) :- !, assertz((Head :- Body)).
load_one(Fact)           :- assertz(Fact).

load_directive(dynamic(_)) :- !, true.     % GNU 没有可调用的 dynamic/1！
load_directive(Goal)       :- call(Goal).
```

**`=..` + `call/1` 绕过 `gplc` 静态链接**：源码里**字面出现**的谓词调用会在链接期
解析符号；运行时才加载的谓词只能元调用，否则 `Undefined symbols: predicate(x/N)`。

## 19. 测试（23）

```prolog
run_one(name(N, G), R) :-
    catch( ( call(G) -> R = ok ; R = bad(failed) ), E, R = bad(threw(E)) ).

expect_true(G)  :- call(G).
expect_false(G) :- \+ call(G).
expect_set(T, G, Exp)    :- findall(T,G,L), sort(L,S), sort(Exp,E), S == E.
expect_bag(T, G, Exp)    :- findall(T,G,L), L == Exp.      % 保序、保留重复
expect_single(T, G)      :- findall(T,G,[_]).
expect_throw(G, Name) :-
    catch( ( call(G), fail ),                              % ← 那句 fail 是关键
           E, ( functor(E,F,_), ( F == Name -> true ; throw(unexpected(F,Name)) ) )).
```

**两条铁律**：① 断言比**项本身**，不比打印文本；② 测试数据也要可移植
（用 `between/3`、`length/2`、`findall/3`，别用随机数/时间）。

```prolog
% SWI 有、GNU 完全没有
library(plunit) begin_tests/1 test/1 end_tests/1 run_tests/1
assertion/1  call_with_time_limit/2  time/1
```

## 20. 坑位总索引（226 条）

按章列，只列**最常撞**的那几条；完整版在各章末尾的「坑位清单」。

| 章 | 高频坑 | 正解 |
|---|---|---|
| 02 | 忘写 `set_prolog_flag(double_quotes, codes)` | SWI 给字符串对象、GNU 给码列表 |
| 02 | `main/0` 不包 `catch` | 异常打到顶层终止，退出码也不对 |
| 03 | 靠同名谓词顺序做分支却不加 `!` | 多余解沿调用链上传 |
| 04 | `arg/3` 当 0 基 | 它是 **1 基** |
| 04 | 指望发生检查 | 默认关闭，`X = f(X)` 造循环项 |
| 05 | `X = 5` 当赋值 | 是合一；想「改」只能换新变量或动态库 |
| 05 | `\=` 当「不等于」 | `X` 未绑定时恒为假，约束里用 `#\=`（21 章） |
| 06 | 生成-测试规模一大就崩 | 换成约束（21 章） |
| 07 | 用 `/` 做跨引擎比对 | `8/4` 结果类型两引擎不同 |
| 07 | `trunc/1` | GNU 缺失 → `truncate/1` |
| 07 | `**` | xfx 非结合 + 类型不一致 → 用 `^` |
| 08 | `nth0` / `nth1` / `arg` 混用 | 三种下标约定不同 |
| 08 | `include/3` `exclude/3` `foldl/4` | SWI 专有 → 手写 |
| 09 | 非尾递归做 `(-,+)` 生成模式 | 不终止，见 23 章 |
| 10 | 红切破坏谓词对称性 | 优先靠子句顺序，`!` 最后用 |
| 10 | `(C -> T ; E)` 里 `C` 失败无兜底 | 静默失败，看起来「什么都没做」 |
| 11 | 只预置后面的参数 | `call/N` 只能往尾部追加 |
| 11 | `maplist/2` 当 filter 用 | 它只给真假，不给部分结果 |
| 12 | `retract/1` 不加 `once` | 回溯把同名事实全删 |
| 12 | `atom([])` 做类型判断 | SWI 假 / GNU 真 |
| 13 | 用 `bagof` 却冒出一堆组 | 自由变量分组；加 `^` 或改 `findall` |
| 13 | `findall` 里写 `X^Goal` | `findall` 不认 `^/2`，改通配变量 |
| 14 | `format/1` | **不存在**，必须给实参列表 |
| 14 | `write/1` 写带空格的原子 | 读不回来 → `writeq/1` 或 `quoted(true)` |
| 14 | `open(F, write, S)` 以为在追加 | `write` **清空**文件，追加用 `append` |
| 15 | 双引号串用 `~w` 打 | 打出 `[97,98,99]`，要 `~s` |
| 15 | 对中文调 `atom_length`/`sub_atom` | SWI 数码点、GNU 数字节 |
| 16 | 写 `- 3`（带空格） | SWI 得 `-(3)`、GNU 得整数 `-3` → 写 `-3` |
| 16 | 两个同优先级 `xfx` 并列 | 语法错误，要加括号 |
| 17 | 以为回溯会撤销 `assertz` | 不会；失败的查询可能已改库 |
| 17 | `:- dynamic item/2.` 不带括号 | GNU 语法错误 |
| 17 | `abolish/1` 忘写 `Name/Arity` | 写 `abolish(f)` 是错的 |
| 18 | 递归不消费输入 | 无限递归（`word//1` 忘吃字符） |
| 18 | DCG 里写普通目标不加 `{}` | 被当非终结符，报 `existence_error` |
| 19 | 左结合写成右结合 | `10-3-2` 算成 9，**静默错误** |
| 19 | DCG 里直接写列表变量 | 被当非终结符 `call` → 要逐个 `[C]` |
| 20 | `(catch(G,_,fail) -> … ; …)` 判异常 | 不匹配是**重抛**不是失败 |
| 20 | `catch(G, _, true)` 全捕 | 把 bug 吞成静默错误 |
| 20 | 指望异常回传变量绑定 | `throw` 前 `copy_term` 过 |
| 21 | 打印未标号的约束变量 | SWI `_1234` / GNU `_#0(6..9)` |
| 21 | 没声明域就 `labeling` | 两引擎都拒绝；域矛盾时**静默 0 解** |
| 21 | GNU 上写 `X in 1..9` | `in`/`..` 不是 GNU 运算符，**语法分析就失败** |
| 21 | SWI 侧直接写 `label(Vs)` | `gplc` 报 `Undefined symbols` → `=..`+`call` |
| 21 | 不 `sort` 就比对两引擎的解 | 标号顺序是实现细节 |
| 22 | 靠 `:- module(...)` 做封装 | GNU 静默忽略，封装完全无效 |
| 22 | 示例里直接调 `consult/1` | GNU 往 stdout 打编译进度 |
| 22 | 运行时 `call(include(F))` | 只能写在**指令位置** |
| 23 | `expect_throw` 漏了 `catch` 里的 `fail` | 「没抛错」被判成通过，**假绿** |
| 23 | 用 `=` 比较目标的解 | 悄悄绑定变量，写出永远通过的假测试 |
| 24 | `truth(true,1).` 这种写法 | 传进来的是项 `>(A,B)`，要 `call/1` |
| 24 | 环境查找用 `=` 而不是 `==` | 查询变量被静默绑到环境键上 |
| 24 | 用 `/` 而不是 `//` | 浮点打印位数因引擎而异 |

## 21. 安全子集（跨引擎一致的写法）

**只有这些才敢写进可移植代码**：

```text
控制    ,  ;  ->  \+  !  once/1  forall/2  call/1..8  repeat/0
合一    =  ==  \=  =..  functor/3  arg/3  copy_term/2  term_variables/2
判定    var nonvar atom number integer float atomic compound callable is_list ground
算术    + - * // mod rem  abs sign max min // > < >= =< =:= =\=
列表    member append length reverse nth0 nth1 last sort msort keysort
收集    findall bagof setof
文本    atom_codes atom_chars atom_length sub_atom atom_concat char_code number_codes
I/O     open close read read_term write writeq write_term format put_char nl get_code get_char
库      assert assertz asserta retract retractall clause abolish current_predicate
DCG     -->  phrase/2,3
异常    throw catch error/2
```

**刻意避开**：

```text
浮点                       打印位数不同（SWI 最短 / GNU 17 位）
CLP(FD) 高级功能           两套独立实现（21 章只用 domain/labeling/alldiff）
模块系统                   GNU 没有（22 章）
未绑定变量的打印            编号不同（_A vs _G123）
引擎给的错误项内容          形状自由（只打 functor）
with_output_to/2 term_string/2 atom_to_term/3 split_string/4
atomic_list_concat/3 upcase_atom/2 downcase_atom/2 include/3 exclude/3
foldl/4 aggregate_all/3 sort/4 predsort/3 library(plunit) statistics/2
exists_file/1（SWI）vs file_exists/1（GNU）—— 连文件存在性都不统一
```

---

**读法**：`docs/01-overview.md` 是地图，`docs/02`–`docs/24` 逐章；
每章末尾都有「坑位清单」。本表查语法与坑位，正文查原理与实测输出。
