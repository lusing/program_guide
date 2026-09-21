%% ============================================================================
%%  03_facts_rules.pl —— 事实、规则与查询（第 03 章配套）
%%
%%  Prolog 程序 = 事实 + 规则，程序运行 = 提出查询。
%%  本示例用一个家族关系库演示三件事：
%%    1. 事实是「无条件为真」的断言，规则是「条件为真则结论为真」
%%    2. 一个谓词可以有多个子句，语义是逻辑「或」
%%    3. 同一个谓词可以多种模式使用（正向查、反向查、枚举）
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、事实：无条件为真的陈述
%% ---------------------------------------------------------------------------
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).

male(tom).
male(bob).
male(jim).
female(liz).
female(ann).
female(pat).

%% ---------------------------------------------------------------------------
%%  二、规则：结论 :- 条件1, 条件2, ...
%%     逗号读作「并且」，分号读作「或者」，:- 读作「如果」
%% ---------------------------------------------------------------------------
father(X, Y) :- parent(X, Y), male(X).
mother(X, Y) :- parent(X, Y), female(X).

grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

% 同一谓词两个子句 = 逻辑或：要么是父母，要么是祖父母
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

% 兄弟姐妹：同父母且不是同一个人（\== 是「不同一」，第 05 章细讲）
sibling(X, Y) :- parent(P, X), parent(P, Y), X \== Y.

%% ---------------------------------------------------------------------------
%%  三、演示
%% ---------------------------------------------------------------------------
demo_truth :-
    say("---- 1. 不带变量的查询：只问真假 ----"),
    (   parent(tom, bob)
    ->  say("  parent(tom, bob)    成立")
    ;   say("  parent(tom, bob)    不成立")
    ),
    (   parent(ann, tom)
    ->  say("  parent(ann, tom)    成立")
    ;   say("  parent(ann, tom)    不成立（事实库里没有这条）")
    ),
    (   father(tom, bob)
    ->  say("  father(tom, bob)    成立（由规则推出来的）")
    ;   say("  father(tom, bob)    不成立")
    ),
    (   mother(tom, bob)
    ->  say("  mother(tom, bob)    成立")
    ;   say("  mother(tom, bob)    不成立（tom 是 male）")
    ).

demo_bind :-
    say("---- 2. 带变量的查询：Prolog 帮你找绑定 ----"),
    (   father(tom, X)
    ->  format("  tom 的一个孩子：~w~n", [X])
    ;   say("  tom 没有孩子")
    ),
    findall(C, parent(bob, C), Kids),
    format("  bob 的孩子（收集全部解）：~w~n", [Kids]),
    findall(G, grandparent(tom, G), Grandkids),
    format("  tom 的孙辈：~w~n", [Grandkids]).

demo_enumerate :-
    say("---- 3. 枚举全部解：forall/2 与 findall/3 ----"),
    forall(grandparent(A, B),
           format("  ~w 是 ~w 的祖辈~n", [A, B])),
    % 注意 forall(Cond, Action) 的语义是「对每个 Cond 解 Action 都必须成立」，
    % 所以这里要用 if-then-else 把「不是首序对」的情况显式放过，否则整句失败。
    forall(sibling(S1, S2),
           ( S1 @< S2
           -> format("  ~w 和 ~w 是兄弟姐妹~n", [S1, S2])
           ;  true
           )),
    findall(A2, ancestor(tom, A2), Desc),
    format("  tom 的全部后代：~w~n", [Desc]).

demo_multimode :-
    say("---- 4. 同一谓词，多种用法 ----"),
    findall(P, parent(P, pat), Parents),
    format("  谁是 pat 的父母：~w~n", [Parents]),
    findall(C, parent(tom, C), Children),
    format("  tom 的孩子有谁：~w~n", [Children]),
    findall(X-Y, parent(X, Y), All),
    format("  所有 parent 事实：~w~n", [All]),
    % 反向用法：给定孩子，枚举所有可能父母（来自两个子句的「或」）
    findall(A3, ancestor(A3, jim), Ancestors),
    format("  jim 的全部祖先：~w~n", [Ancestors]).

demo_or_semantics :-
    say("---- 5. 分号 = 逻辑或 ----"),
    findall(Y, ( parent(tom, Y) ; parent(bob, Y) ), Anyone),
    format("  tom 或 bob 的孩子：~w~n", [Anyone]),
    findall(Y2, ( ( parent(tom, Y2), male(Y2) ) ; parent(liz, Y2) ), Mixed),
    format("  （tom 的儿子）或（liz 的孩子）：~w~n", [Mixed]).

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []), halt(1)
    ).

run :-
    format("==== 03 开始 ====~n", []),
    say("Prolog 程序 = 事实 + 规则；运行 = 查询。没有赋值语句，也没有返回值。"),
    say(""),
    demo_truth,       say(""),
    demo_bind,        say(""),
    demo_enumerate,   say(""),
    demo_multimode,   say(""),
    demo_or_semantics, say(""),
    format("==== 03 结束 ====~n", []).
