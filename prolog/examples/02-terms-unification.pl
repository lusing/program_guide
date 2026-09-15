% ============================================================
%  02-terms-unification.pl —— 项与合一
%
%  运行（SWI）: swipl -q -f examples/02-terms-unification.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/02-terms-unification.pl --entry-goal main
%
%  说明：Prolog 里没有「赋值」，只有「合一（unification）」。
%        理解合一 = 理解 Prolog 的一半。
% ============================================================

% 让双引号在两个引擎上含义一致（码表），避免 SWI 的 string 与 GNU 的 codes 打架
:- set_prolog_flag(double_quotes, codes).

run :-
    format("==== 02  项与合一 ====~n", []),

    % --------------------------------------------------------
    %  一、项的四种形态
    % --------------------------------------------------------
    nl, format("---- 项的种类 ----~n", []),
    kind(atom,        atom),
    kind(number,      42),
    kind(number,      -3.5),
    kind(compound,    point(1, 2)),
    kind(compound,    f(g(a), [1, 2])),
    kind(var,         _Unbound),

    % --------------------------------------------------------
    %  二、合一 =/2 与恒等 ==/2
    %    X = Y     尝试合一，成功则绑定变量
    %    X == Y    不做任何绑定，只判断两项是否已经完全相同
    % --------------------------------------------------------
    nl, format("---- = 与 == ----~n", []),
    show_unify(1, 1),
    show_unify(1, 2),
    show_unify(f(a), f(a)),
    show_unify(f(_X1), f(b)),        % X1 会被绑定到 b
    show_unify(g(_X2), f(b)),        % 函子不同，合一失败
    show_unify([1, 2], [1 | [2]]),   % 列表就是 .(1, .(2, []))
    show_identical(Same2, Same2),    % 同一个变量：== 成立
    show_identical(_B2, _C2),        % 两个不同变量：== 不成立

    % --------------------------------------------------------
    %  三、用合一做「模式匹配」：这是 Prolog 拆数据结构的方式
    % --------------------------------------------------------
    nl, format("---- 合一拆解复合项 ----~n", []),
    point(3, 4) = point(X3, Y3),
    format("  point(3,4) = point(X,Y)  ->  X=~w Y=~w~n", [X3, Y3]),

    [H3 | T3] = [10, 20, 30],
    format("  [H|T] = [10,20,30]      ->  H=~w T=~w~n", [H3, T3]),

    date(Y4, M4, D4) = date(2026, 9, 15),
    format("  date(Y,M,D) 匹配         ->  ~w-~w-~w~n", [Y4, M4, D4]),

    % 部分实例化：只给出一部分也能匹配
    person(name(Name5), age(Age5)) = person(name(tom), age(_)),
    format("  部分匹配 person/2        ->  name=~w age=~w~n", [Name5, Age5]),

    % --------------------------------------------------------
    %  四、发生检查（occurs check）
    %    X = f(X) 会造出无限项。默认 Prolog 不检查（为了速度），
    %    需要时显式用 unify_with_occurs_check/2
    % --------------------------------------------------------
    nl, format("---- 发生检查 ----~n", []),
    (   unify_with_occurs_check(X6, f(X6))
    ->  format("  X = f(X) 竟然成功了（不该发生）~n", [])
    ;   format("  unify_with_occurs_check(X, f(X)) 正确地失败了~n", [])
    ),
    (   unify_with_occurs_check(_X7a, f(_Y7b))
    ->  format("  unify_with_occurs_check(X, f(Y)) 成功，Y 仍是未绑定变量~n", [])
    ;   format("  失败~n", [])
    ),

    % --------------------------------------------------------
    %  五、标准项序：@< @> @=< @>= compare/3
    %    用途：sort/2、keysort/2 等排序都建立在它之上
    % --------------------------------------------------------
    nl, format("---- 标准项序 ----~n", []),
    format("  变量 < 数字 < 原子 < 复合项~n", []),
    cmp(1, 2),
    cmp(abc, abd),
    cmp(f(a), f(b)),
    cmp(f(1), f(1, 2)),

    % --------------------------------------------------------
    %  六、copy_term/2：复制时保留变量之间的「共享」关系
    % --------------------------------------------------------
    nl, format("---- copy_term ----~n", []),
    copy_term(f(X8, X8), Copy8),
    format("  copy_term(f(X,X), C) ->  C = ~q~n", [Copy8]),
    copy_term(g(_, _), Copy9),
    format("  copy_term(g(_,_), C) ->  C = ~q（两个不同的新变量）~n", [Copy9]),

    nl, format("==== 02 结束 ====~n", []).

% ------------------------------------------------------------
%  辅助词
% ------------------------------------------------------------
kind(Expect, Term) :-
    classify(Term, Got),
    (   Got == Expect
    ->  format("  ~q -> ~w~n", [Term, Got])
    ;   format("  ~q -> ~w（预期 ~w）~n", [Term, Got, Expect])
    ).

classify(T, var)      :- var(T), !.
classify(T, number)   :- number(T), !.
classify(T, atom)     :- atom(T), !.
classify(T, compound) :- compound(T), !.
classify(_, unknown).

show_unify(A, B) :-
    (   A = B
    ->  format("  ~q = ~q  成功~n", [A, B])
    ;   format("  ~q = ~q  失败~n", [A, B])
    ).

show_identical(A, B) :-
    (   A == B
    ->  format("  ~q == ~q  恒等~n", [A, B])
    ;   format("  ~q == ~q  不恒等~n", [A, B])
    ).

cmp(A, B) :-
    compare(Order, A, B),
    format("  compare(~q, ~q) -> ~w~n", [A, B, Order]).

main :-
    (   catch(run, E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** run/0 失败~n", []), halt(1)
    ).
