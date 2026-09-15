% ============================================================
%  12-metaprogramming.pl —— 元编程：把程序当数据
%
%  运行（SWI）: swipl -q -f examples/12-metaprogramming.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/12-metaprogramming.pl --entry-goal main
%
%  Prolog 的程序就是一个项（term），所以：
%    · 能读自己的子句（clause/2）
%    · 能构造项再 call（=..、functor/3、call/N）
%    · 能在编译期改源码（term_expansion，SWI 专有）
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、用 clause/2 读自己的规则
% ------------------------------------------------------------
% GNU Prolog 要求先 :- public 声明，否则 clause/2 访问静态谓词会报
% permission_error(access, private_procedure, ...)。SWI 没有这个限制。
:- if(current_prolog_flag(dialect, gprolog)).
:- public(grade/2).
:- public(parent2/2).
:- public(grandparent2/2).
:- endif.

grade(S, a) :- S >= 90.
grade(S, b) :- S >= 80.
grade(S, c) :- S >= 70.
grade(_,  f).

demo_read_self :-
    format("---- 读自己的子句 ----~n", []),
    findall(H-B, clause(grade(H, _), B), Clauses),
    forall(member(H1-B1, Clauses),
           format("  ~q :- ~q~n", [H1, B1])),
    format("  程序和数据是同一种东西，这就是 homoiconicity。~n", []).

% ------------------------------------------------------------
%  二、构造项再调用（=.. 与 call/N）
% ------------------------------------------------------------
demo_build_call :-
    format("---- 运行时构造调用 ----~n", []),
    Name = append,
    Args = [[1,2],[3],Out],
    Goal =.. [Name | Args],
    format("  构造出的目标：~q~n", [Goal]),
    call(Goal),
    format("  调用结果 Out = ~w~n", [Out]),
    % 根据名字分发到不同谓词
    forall(member(F, [plus1, times2, negate]),
           ( G2 =.. [F, 10, R2], call(G2), format("  ~w(10) = ~w~n", [F, R2]) )).

plus1(X, Y)  :- Y is X + 1.
times2(X, Y) :- Y is X * 2.
negate(X, Y) :- Y is -X.

% ------------------------------------------------------------
%  三、写一个迷你「规则引擎」：用事实存规则，再解释执行
% ------------------------------------------------------------
% 规则表示：rule(结论, [条件1, 条件2, ...])
rule(animal_is(dog),   [barks, wags_tail]).
rule(animal_is(cat),   [meows, has_fur]).
rule(animal_is(bird),  [flies, has_feathers]).
rule(is_pet,           [animal_is(dog)]).
rule(is_pet,           [animal_is(cat)]).

:- dynamic(fact/1).

% 正向链：prove(目标)
prove(Goal) :-
    (   fact(Goal)
    ->  true
    ;   rule(Goal, Conditions),
        forall(member(C, Conditions), prove(C))
    ).

explain(Goal, Depth) :-
    indent(Depth),
    (   fact(Goal)
    ->  format("~q（已知事实）~n", [Goal])
    ;   rule(Goal, Cs)
    ->  format("~q 需要：~n", [Goal]),
        D1 is Depth + 1,
        forall(member(C, Cs), explain(C, D1))
    ;   format("~q —— 无法证明~n", [Goal])
    ).

indent(0) :- !.
indent(N) :- N > 0, format("  ", []), N1 is N - 1, indent(N1).

demo_rules :-
    format("---- 迷你规则引擎 ----~n", []),
    retractall(fact(_)),
    assertz(fact(barks)), assertz(fact(wags_tail)),
    assertz(fact(meows)), assertz(fact(has_fur)),
    ( prove(animal_is(dog)) -> format("  能推出 animal_is(dog)~n", []) ; true ),
    ( prove(is_pet) -> format("  能推出 is_pet~n", []) ; true ),
    ( prove(animal_is(bird)) -> true ; format("  推不出 animal_is(bird)（缺条件）~n", []) ),
    nl,
    format("  推导过程：~n", []),
    explain(is_pet, 1),
    retractall(fact(_)).

% ------------------------------------------------------------
%  四、运行时生成谓词（用 assertz 造代码）
% ------------------------------------------------------------
:- dynamic(getter/2).
:- dynamic(person/2).

make_getter(Field) :-
    Head =.. [getter, Field, Value],
    Body =.. [Field, _, Value],       % 形如 person(_, Value)
    assertz((Head :- Body)).

% 造一个「按名字取字段」的通用访问器
demo_generate_code :-
    format("---- 运行时生成代码 ----~n", []),
    retractall(getter(_, _)),
    % 手工造一个 person/2 的事实
    F1 =.. [person, tom, 42],
    assertz(F1),
    make_getter(person),
    ( getter(person, V) -> format("  getter(person, X) -> ~w~n", [V]) ; true ),
    retractall(person(_, _)),
    retractall(getter(_, _)),
    format("  用 assertz 造出来的子句和写死在源码里的一模一样。~n", []),
    format("  代价：调试困难、类型全丢，谨慎使用。~n", []).

% ------------------------------------------------------------
%  五、自解释器：用 Prolog 解释 Prolog（极简版）
% ------------------------------------------------------------
% solve/1：只支持 true、逗号、以及已定义的事实/规则
solve(true) :- !.
solve((A, B)) :- !, solve(A), solve(B).
solve(Goal) :-
    Goal \= true,
    Goal \= (_ , _),
    clause(Goal, Body),
    solve(Body).

parent2(tom, bob).
parent2(bob, ann).
grandparent2(X, Z) :- parent2(X, Y), parent2(Y, Z).

demo_interpreter :-
    format("---- 极简自解释器 ----~n", []),
    ( solve(parent2(tom, bob)) -> format("  solve(parent2(tom,bob)) -> 真~n", []) ; true ),
    ( solve(grandparent2(tom, Who)) -> format("  solve(grandparent2(tom,X)) -> ~w~n", [Who]) ; true ),
    ( solve(grandparent2(ann, _)) -> true ; format("  solve(grandparent2(ann,_)) -> 假~n", []) ),
    format("  真正的 Prolog 解释器核心就是这样：clause + 递归。~n", []),
    format("  只是它还缺了回溯控制、cut、异常、模块这些。~n", []).

% ------------------------------------------------------------
%  六、编译期元编程（SWI 专有）
% ------------------------------------------------------------
demo_compile_time :-
    format("---- 编译期变换 ----~n", []),
    (   current_prolog_flag(dialect, swi)
    ->  format("  SWI 支持 term_expansion/2 和 goal_expansion/2，~n", []),
        format("  可以在 consult 时改写子句（比如给所有谓词加日志、实现 DSL）。~n", []),
        format("  GNU Prolog 没有这两个钩子，只能靠预处理脚本或宏风格的代码生成。~n", [])
    ;   format("  当前是 GNU Prolog：没有 term_expansion/2。~n", []),
        format("  想在 GNU 上做同样的事，得在外面用脚本生成 .pl 文件再 gplc。~n", [])
    ).

run :-
    format("==== 12  元编程 ====~n", []), nl,
    demo_read_self,     nl,
    demo_build_call,    nl,
    demo_rules,         nl,
    demo_generate_code, nl,
    demo_interpreter,   nl,
    demo_compile_time.

main :-
    (   catch((run, nl, format("==== 12 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 12 运行失败~n", []), halt(1)
    ).
