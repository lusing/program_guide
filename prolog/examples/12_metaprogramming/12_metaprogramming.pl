%% ============================================================================
%%  12_metaprogramming.pl —— 元编程：把程序当数据处理
%%
%%  Prolog 的程序本身就是项（term），所以「分析、构造、改写、执行程序」
%%  和「处理普通数据」用的是同一套工具。这是 Prolog 最强的能力，
%%  也是它最适合写编译器、解释器、专家系统、DSL 的原因。
%%
%%  三组工具：
%%    解剖项   functor/3  arg/3  =../2  copy_term/2  term_variables/2
%%    判定类型 var/1 nonvar/1 atom/1 number/1 compound/1 atomic/1 callable/1
%%             is_list/1 ground/1
%%    执行项   call/1..call/N   以及动态数据库 assert/retract/clause
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、解剖一个项：名字、元数、参数
%% ---------------------------------------------------------------------------
demo_anatomy :-
    say("---- 1. 项的解剖 ----"),
    T = f(a, [1, 2], g(x)),

    % functor/3：拿名字与元数
    functor(T, Name, Arity),
    format("  functor(f(a,[1,2],g(x)), N, A)  -> N = ~w，A = ~w~n", [Name, Arity]),

    % arg/3：按下标取参数（下标从 1 开始！）
    arg(1, T, A1),
    arg(2, T, A2),
    arg(3, T, A3),
    format("  arg(1/2/3, T, X)  -> ~w / ~w / ~w~n", [A1, A2, A3]),

    % =../2（念作 univ）：项 <-> 列表[f, a1, a2, ...]
    T =.. Parts,
    format("  T =.. L  ->  L = ~w~n", [Parts]),
    Built =.. [h, 1, 2, 3],
    format("  L =.. [h,1,2,3]  ->  ~w~n", [Built]),

    % 原子与整数的 univ 结果就是「只含自己」的单元素列表
    Five = 5,
    Five =.. Parts2,
    format("  整数 5 的 univ 结果  ->  ~w~n", [Parts2]),

    say("  注意：[] 在 SWI 里 atom([]) 为假、在 GNU 里为真，所以拿它做类型"),
    say("  判断不可移植；判空请用 length(L, 0)。"),
    say("  另外 arg/3 的下标从 1 开始，而列表的 nth0/nth1 是两套并存，"),
    say("  这是 Prolog 里最容易记混的一对（第 08 章）。").

%% ---------------------------------------------------------------------------
%%  二、类型判定
%% ---------------------------------------------------------------------------
what_cat(Var, Cat) :-
    (   var(Var)       -> Cat = var
    ;   number(Var)    -> Cat = number
    ;   atom(Var)      -> Cat = atom
    ;   compound(Var)  -> Cat = compound
    ;   Cat = other
    ).

demo_types :-
    say("---- 2. 类型判定：Prolog 没有类型声明，但有类型判定 ----"),
    type_line("未绑定变量", _Any),
    type_line("整数 42", 42),
    type_line("浮点 3.5", 3.5),
    type_line("原子 foo", foo),
    type_line("列表 [1,2]", [1, 2]),
    type_line("复合项 f(a)", f(a)),

    (   callable(f(a))
    ->  say("  callable(f(a))     成立 —— 这个项可以当目标调用")
    ;   say("  callable(f(a))     不成立")
    ),
    (   ground(f(a, 1))
    ->  say("  ground(f(a,1))     成立 —— 不含未绑定变量")
    ;   say("  ground(f(a,1))     不成立")
    ),
    (   ground(f(a, _Z1))
    ->  say("  ground(f(a,_))     成立？")
    ;   say("  ground(f(a,_))     不成立 —— 含未绑定变量")
    ).

type_line(Label, V) :-
    what_cat(V, Cat),
    format("  ~s  -> ~w~n", [Label, Cat]).

%% ---------------------------------------------------------------------------
%%  三、改写程序：手写版 vs 通用版
%% ---------------------------------------------------------------------------
%% 目标：把算术表达式里每个数字乘 2，结构原封不动。
%% 手写版：每遇到一个运算符就得补一个子句 —— 加运算符就要改代码。
double_hand(N, N2) :- number(N), !, N2 is N * 2.
double_hand(A + B, A2 + B2) :- !, double_hand(A, A2), double_hand(B, B2).
double_hand(A * B, A2 * B2) :- !, double_hand(A, A2), double_hand(B, B2).
double_hand(X, X).

%% 通用版：用 =.. 拆开、递归改参数、再拼回去 —— 加运算符不用改代码。
double_gen(N, N2) :-
    number(N),
    !,
    N2 is N * 2.
double_gen(T, T2) :-
    compound(T),
    !,
    T =.. [F | Args],
    double_list(Args, Args2),
    T2 =.. [F | Args2].
double_gen(X, X).

double_list([], []).
double_list([H | T], [H2 | T2]) :-
    double_gen(H, H2),
    double_list(T, T2).

demo_rewrite :-
    say("---- 3. 改写成项：手写 vs 通用 ----"),
    double_hand(1 + 2 * 3, R1),
    V1 is R1,
    format("  手写版 1+2*3 -> ~w（值 ~w）~n", [R1, V1]),
    double_gen(1 + 2 * 3, R2),
    V2 is R2,
    format("  通用版 1+2*3 -> ~w（值 ~w）~n", [R2, V2]),

    % 通用版对任意函子都有效，包括自定义的
    double_gen(f(g(1), 2, [3, x]), R3),
    format("  通用版 f(g(1),2,[3,x]) -> ~w~n", [R3]),
    say("  这就是「把程序当数据」的威力：遍历器只写一遍，"),
    say("  能改写任何函子的项。写解释器、编译器、代码生成器全靠它。"),
    say("  代价是通用版慢一点（每次都要 =.. 拆装），所以两者都常用。").

%% ---------------------------------------------------------------------------
%%  四、动态数据库：把事实当成可变状态
%% ---------------------------------------------------------------------------
:- dynamic(item/2).

demo_db :-
    say("---- 4. 动态数据库：运行期增删事实 ----"),
    assertz(item(apple, 3)),
    assertz(item(pear, 5)),
    assertz(item(plum, 2)),

    findall(N - Q, item(N, Q), All),
    format("  插入三条后          ~w~n", [All]),

    % retract/1 会留下选择点；只想删一条要加 once 或 !
    once(retract(item(pear, _Q2))),
    findall(N2 - Q3, item(N2, Q3), All2),
    format("  retract 掉 pear 后  ~w~n", [All2]),

    % retractall 一次删干净，永远成功
    retractall(item(plum, _)),
    findall(N3, item(N3, _), Names),
    format("  retractall 掉 plum  ~w~n", [Names]),

    % clause/2 能看到子句的头与体 —— 运行时反射
    assertz((cheap(X) :- item(X, Q4), Q4 < 4)),
    (   clause(cheap(_X2), Body)
    ->  numbervars(Body, 0, _),
        format("  clause(cheap(X), B) B = ~w~n", [Body])
    ;   say("  clause(cheap(X), B) 没有匹配")
    ),

    retractall(item(_, _)),
    retractall(cheap(_)),
    say("  提醒：assert/retract 是有副作用的、不可回溯的操作（第 17 章细讲）。").

%% ---------------------------------------------------------------------------
%%  五、copy_term：把模式复制成互不干扰的模板
%% ---------------------------------------------------------------------------
demo_template :-
    say("---- 5. copy_term/2 做模板 ----"),
    Template = rule(_Who, _Action),
    copy_term(Template, I1),
    I1 = rule(tom, run),
    numbervars(Template, 0, _),
    format("  模板照旧          ~w~n", [Template]),
    format("  实例化后的副本    ~w~n", [I1]),
    say("  copy_term 之后两张表互不影响，适合做「规则模板 + 多次实例化」。"),
    say("  第 24 章的前向推理引擎就靠它避免规则之间互相污染。").

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 12 开始 ====~n", []),
    say("Prolog 的程序就是项，所以程序和数据用同一套工具处理。"),
    say(""),

    demo_anatomy,  say(""),
    demo_types,    say(""),
    demo_rewrite,  say(""),
    demo_db,       say(""),
    demo_template, say(""),

    format("==== 12 结束 ====~n", []).
