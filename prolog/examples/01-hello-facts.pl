% ============================================================
%  01-hello-facts.pl —— 事实、规则与查询
%
%  运行（SWI-Prolog）：
%    swipl -q -f examples/01-hello-facts.pl -g main -t halt
%  运行（GNU Prolog）：
%    gprolog --consult-file examples/01-hello-facts.pl --entry-goal main
%
%  说明：Prolog 程序 = 事实 + 规则 + 查询。
%        没有 main 函数，这里用 main/0 只是为了脚本化运行。
% ============================================================

% 让 "abc" 在两套系统里都表示「字符码列表」（SWI 默认是 string）
:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、事实：无条件为真的陈述
% ------------------------------------------------------------
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

% ------------------------------------------------------------
%  二、规则：条件为真则结论为真
%      :- 读作「如果」，逗号读作「并且」
% ------------------------------------------------------------
father(X, Y) :- parent(X, Y), male(X).
mother(X, Y) :- parent(X, Y), female(X).

grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

% 同一个谓词的多个子句 = 逻辑「或」
sibling(X, Y) :- parent(P, X), parent(P, Y), X \== Y.
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

% ------------------------------------------------------------
%  三、入口
% ------------------------------------------------------------
main :-
    (   catch(run, E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** run/0 失败~n", []), halt(1)
    ).

run :-
    format("==== 01  事实、规则与查询 ====~n~n", []),

    % 1. 最简单的查询：不带变量，只问真假
    format("---- 真假查询 ----~n", []),
    ( parent(tom, bob) -> format("parent(tom,bob)  成立~n", [])
    ;                     format("parent(tom,bob)  不成立~n", []) ),
    ( parent(ann, tom) -> format("parent(ann,tom)  成立~n", [])
    ;                     format("parent(ann,tom)  不成立（事实库里没有）~n", []) ),

    % 2. 带变量的查询：Prolog 负责找出所有让目标成立的变量绑定
    nl, format("---- 带变量的查询 ----~n", []),
    ( father(tom, X) -> format("tom 的孩子之一：~w~n", [X]) ; true ),
    ( mother(bob, M) -> format("bob 的母亲：~w~n", [M])
    ;                   format("bob 的母亲：查不到（事实库里没有）~n", []) ),

    % 3. 一次拿全部解：findall/3
    nl, format("---- findall 收集全部解 ----~n", []),
    findall(C, parent(bob, C), Kids),
    format("bob 的孩子：~w~n", [Kids]),
    findall(G, grandparent(tom, G), Grandkids),
    format("tom 的孙辈：~w~n", [Grandkids]),

    % 4. 打印每个解：forall/2
    nl, format("---- 规则推导 ----~n", []),
    forall(grandparent(X2, Y2),
           format("  ~w 是 ~w 的祖辈~n", [X2, Y2])),
    forall(sibling(S1, S2),
           format("  ~w 和 ~w 是兄弟姐妹~n", [S1, S2])),

    nl, format("---- 递归规则 ancestor/2 ----~n", []),
    findall(A, ancestor(tom, A), Desc),
    format("tom 的所有后代：~w~n", [Desc]),
    ( ancestor(tom, jim) -> format("jim 是 tom 的后代：是~n", [])
    ;                       format("jim 是 tom 的后代：否~n", []) ),

    % 5. Prolog 的习惯：谓词常常「多模式」可用
    nl, format("---- 同一个谓词，不同用法 ----~n", []),
    findall(P3, parent(P3, pat), Ps),
    format("谁是 pat 的父母：~w~n", [Ps]),
    findall(C4, parent(tom, C4), Cs),
    format("tom 的孩子有谁：~w~n", [Cs]),
    findall(X4-Y4, parent(X4, Y4), All),
    format("所有 parent 事实：~w~n", [All]),

    nl, format("==== 01 结束 ====~n", []).
