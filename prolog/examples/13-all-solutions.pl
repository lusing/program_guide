% ============================================================
%  13-all-solutions.pl —— 收集全部解：findall / bagof / setof
%
%  运行（SWI）: swipl -q -f examples/13-all-solutions.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/13-all-solutions.pl --entry-goal main
% ============================================================

:- set_prolog_flag(double_quotes, codes).

age(tom,  30).
age(ann,  25).
age(bob,  35).
age(liz,  25).

city(tom,  beijing).
city(ann,  shanghai).
city(bob,  beijing).
city(liz,  shenzhen).

% ------------------------------------------------------------
%  一、findall/3：最常用，无解时返回空表（不会失败）
% ------------------------------------------------------------
demo_findall :-
    format("---- findall/3 ----~n", []),
    findall(N, age(N, _), Names),
    format("  所有人：~w~n", [Names]),
    findall(N-A, age(N, A), Pairs),
    format("  名字-年龄：~w~n", [Pairs]),
    findall(N, (age(N, A), A >= 30), Old),
    format("  年龄 >= 30：~w~n", [Old]),
    findall(N, age(N, 99), None),
    format("  查不到时：~w（返回空表，不是失败）~n", [None]),
    format("  这一点很关键：findall 永远成功，别拿它当条件判断。~n", []).

% ------------------------------------------------------------
%  二、bagof/3：按自由变量分组
%     无解时失败（与 findall 不同）
% ------------------------------------------------------------
demo_bagof :-
    format("---- bagof/3（按自由变量分组）----~n", []),
    bagof(N1, age(N1, 25), At25),
    format("  25 岁的人：~w~n", [At25]),
    % 自由变量 A 没被 ^ 屏蔽时，bagof 会为 A 的每个取值各给一个解
    findall(Age-Group, bagof(N2, age(N2, Age), Group), Grouped),
    format("  按年龄分组：~w~n", [Grouped]),
    % 用 V^ 屏蔽掉不想分组的变量
    bagof(N4, A4^age(N4, A4), AllNames),
    format("  V^Goal 表示「V 是存在量化的，别按它分组」：~w~n", [AllNames]),
    ( bagof(X, age(X, 99), _) -> true
    ; format("  bagof 查不到时直接失败（findall 返回 []）~n", []) ).

% ------------------------------------------------------------
%  三、setof/3：bagof + 排序去重
% ------------------------------------------------------------
demo_setof :-
    format("---- setof/3（排序 + 去重）----~n", []),
    setof(A, N^age(N, A), Ages),
    format("  所有年龄（去重排序）：~w~n", [Ages]),
    setof(C, N2^city(N2, C), Cities),
    format("  所有城市：~w~n", [Cities]),
    findall(C2, city(_, C2), Raw),
    format("  对比 findall（原样、有重复）：~w~n", [Raw]).

% ------------------------------------------------------------
%  四、forall/2：不是收集，是「对所有解都成立」
% ------------------------------------------------------------
demo_forall :-
    format("---- forall/2 ----~n", []),
    ( forall(age(_, A), A >= 20)
    -> format("  所有人年龄都 >= 20：是~n", [])
    ;  format("  所有人年龄都 >= 20：否~n", []) ),
    ( forall(age(_, A2), A2 >= 30)
    -> format("  所有人年龄都 >= 30：是~n", [])
    ;  format("  所有人年龄都 >= 30：否（tom 30、ann 25 不满足）~n", []) ),
    % 常见误用：把 forall 当成「对每个元素做副作用」的循环
    format("  当成循环用（打印每个人）：~n", []),
    forall(age(N3, A3), format("    ~w: ~w 岁~n", [N3, A3])),
    format("  严格说这是 \\+ (Goal, \\+ Action) 的糖，只是恰好能当循环。~n", []).

% ------------------------------------------------------------
%  五、聚合：SWI 有 aggregate_all，GNU 没有 —— 手写替代
% ------------------------------------------------------------
demo_aggregate :-
    format("---- 聚合 ----~n", []),
    findall(A, age(_, A), As),
    length(As, Count),
    sumlist(As, Sum),
    min_list(As, MinV),
    max_list(As, MaxV),
    Avg is Sum / Count,
    format("  人数 ~w，总和 ~w，平均 ~w~n", [Count, Sum, Avg]),
    format("  最小 ~w，最大 ~w（min_list / max_list 两个引擎都有）~n", [MinV, MaxV]),
    (   current_prolog_flag(dialect, swi)
    ->  format("  SWI 上可以直接用 library(aggregate) 的 aggregate_all/3：~n", []),
        ( catch(aggregate_all(count, age(_,_), C2), _, fail)
        -> format("    aggregate_all(count, age(_,_), X) -> ~w~n", [C2])
        ;  format("    （本例没 :- use_module(library(aggregate))，所以没跑）~n", []) )
    ;   format("  GNU Prolog 没有 aggregate_all，只能用 findall + 手写。~n", [])
    ).

sumlist([], 0).
sumlist([X | Xs], S) :- sumlist(Xs, S1), S is S1 + X.

% ------------------------------------------------------------
%  六、copy_term/numbervars：收集后「冻结」变量
% ------------------------------------------------------------
demo_freeze :-
    format("---- 收集含变量的解 ----~n", []),
    findall(X, member(X, [1, f(_), g(_, _)]), Raw),
    format("  直接 findall：~w（变量还是变量，会被后续绑定影响）~n", [Raw]),
    findall(C, (member(T, [f(_), g(_, _)]), copy_term(T, C)), Copied),
    format("  copy_term 复制一份：~w~n", [Copied]),
    findall(Named, (member(T2, [f(_)]), copy_term(T2, T2C), numbervars(T2C, 0, _), Named = T2C), NamedL),
    format("  numbervars 把变量换成 '$VAR'(N)：~w~n", [NamedL]),
    format("  写调试/打印工具时这三件套配合起来很好用。~n", []).

run :-
    format("==== 13  收集全部解 ====~n", []), nl,
    demo_findall,  nl,
    demo_bagof,    nl,
    demo_setof,    nl,
    demo_forall,   nl,
    demo_aggregate,nl,
    demo_freeze.

main :-
    (   catch((run, nl, format("==== 13 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 13 运行失败~n", []), halt(1)
    ).
