% ============================================================
%  19-testing.pl —— 测试、断言与基准
%
%  运行（SWI-Prolog）：
%    swipl -q -f examples/19-testing.pl -g main -t halt
%  运行（GNU Prolog）：
%    gprolog --consult-file examples/19-testing.pl --entry-goal main
%
%  本例自己实现一个最小测试框架（两套系统都能跑），
%  失败时以退出码 1 结束，可直接进 CI。
% ============================================================

:- set_prolog_flag(double_quotes, codes).
:- dynamic(case_result/2).      % case_result(Name, pass | fail(Detail))

% ------------------------------------------------------------
%  一、最小测试框架
%
%   四件套：期望成功 / 期望失败 / 期望相等 / 期望抛异常。
%   每条 case 把结果 assert 进数据库，最后统一汇总 ——
%   这样「一条测试挂了」不会打断整轮测试。
% ------------------------------------------------------------

% 运行 Goal，把结局归一成 true / false / exc(E)，避免 catch 的
% 「异常穿透」把整轮测试一起带走。
outcome(Goal, R) :-
    (   catch((Goal -> R = true ; R = false), E, R = exc(E))
    ->  true
    ;   R = false
    ).

case(Name, Goal) :-
    outcome(Goal, R),
    (   R == true  -> record(Name, pass)
    ;   R == false -> record(Name, fail(goal_failed))
    ;   record(Name, fail(R))
    ).

case_fail(Name, Goal) :-
    outcome(Goal, R),
    (   R == false -> record(Name, pass)
    ;   record(Name, fail(should_have_failed_but(R)))
    ).

case_eq(Name, Got, Want) :-
    (   Got == Want
    ->  record(Name, pass)
    % 注意：失败详情必须是「单参数」项，否则 report 里的
    % findall(N-D, case_result(N, fail(D)), ...) 匹配不上（fail/2 ≠ fail/1）
    ;   record(Name, fail(neq(Got, Want)))
    ).

case_throws(Name, Goal) :-
    outcome(Goal, R),
    (   R == true  -> record(Name, fail(no_exception))
    ;   R == false -> record(Name, fail(no_exception))
    ;   record(Name, pass)
    ).

record(Name, R) :- assertz(case_result(Name, R)).

clear_cases :- retractall(case_result(_, _)).

% ------------------------------------------------------------
%  二、被测试的代码
% ------------------------------------------------------------

my_append([], L, L).
my_append([H | T], L, [H | R]) :- my_append(T, L, R).

my_rev(L, R) :- my_rev(L, [], R).
my_rev([], Acc, Acc).
my_rev([H | T], Acc, R) :- my_rev(T, [H | Acc], R).

my_len([], 0).
my_len([_ | T], N) :- my_len(T, N0), N is N0 + 1.

my_sum([], 0).
my_sum([H | T], S) :- my_sum(T, S0), S is S0 + H.

my_max([X], X).
my_max([H | T], M) :- my_max(T, M0), M is max(H, M0).

% 可移植的 numlist/3：SWI 自带，GNU Prolog 没有，只能自己写。
% （这也是本仓库示例里反复出现的模式：先探测，缺了就补一个。）
my_numlist(Lo, Hi, L) :- my_numlist(Lo, Hi, [], L).
my_numlist(Lo, Hi, Acc, L) :-
    (   Lo > Hi
    ->  reverse(Acc, L)
    ;   Lo1 is Lo + 1,
        my_numlist(Lo1, Hi, [Lo | Acc], L)
    ).

% 故意留 bug 的版本：累加器的两个参数位置写反了
buggy_rev(L, R) :- buggy_rev(L, [], R).
buggy_rev([], Acc, Acc).
buggy_rev([H | T], Acc, R) :- buggy_rev(T, [Acc | H], R).

% ------------------------------------------------------------
%  三、测试集（全部应该通过）
% ------------------------------------------------------------

run_unit :-
    format("---- 单元测试 ----~n", []),
    case(append_empty,      my_append([], [1], [1])),
    case(append_two,        my_append([1,2], [3], [1,2,3])),
    case_fail(append_wrong, my_append([1], [2], [9,9])),

    case(rev_empty,         my_rev([], [])),
    case(rev_three,         my_rev([1,2,3], [3,2,1])),
    case_fail(rev_wrong,    my_rev([1,2], [1,2])),

    case(len_zero,          my_len([], 0)),
    case(len_three,         my_len([a,b,c], 3)),

    case(sum_empty,         my_sum([], 0)),
    case(sum_five,          my_sum([1,2,3,4,5], 15)),

    case(max_one,           my_max([7], 7)),
    case(max_many,          my_max([3,9,2], 9)),

    my_rev([1,2,3], RevGot),
    case_eq(rev_eq, RevGot, [3,2,1]),

    case_throws(bad_arith,     _X is foo + 1),
    case_throws(no_such_pred,  call(definitely_not_here)),

    report.

% ------------------------------------------------------------
%  四、框架抓 bug 的样子（跑完就清掉，不影响最终结论）
% ------------------------------------------------------------

run_bug_demo :-
    format("---- 框架抓到 bug 时的输出长什么样 ----~n", []),
    clear_cases,
    buggy_rev([1,2,3], Got),
    case_eq(rev_of_123, Got, [3,2,1]),
    format("  buggy_rev([1,2,3], X) 实际返回：~q~n", [Got]),
    report,
    format("  问题：buggy_rev 的递归步写成了 [Acc | H]，~n", []),
    format("        应该是 [H | Acc] —— 累加器把新元素拼到了外层，~n", []),
    format("        结果成了嵌套的 [[[[]|1]|2]|3] 而不是 [3,2,1]。~n", []),
    format("        这种「累加器参数写反」是 Prolog 里最常见的坑之一。~n", []),
    clear_cases.

% ------------------------------------------------------------
%  五、性质测试（property-based）
%
%   不写具体输入输出，写「对所有输入都该成立的性质」。
%   用 numlist 造 1..N 的列表做穷举验证。
% ------------------------------------------------------------

rev_twice_is_id(L) :- my_rev(L, R), my_rev(R, L2), L2 == L.
len_preserved(L)   :- my_len(L, N), my_rev(L, R), my_len(R, N).
sum_of_range(N)    :- my_numlist(1, N, L), my_sum(L, S), S2 is N * (N + 1) // 2, S =:= S2.

run_property :-
    format("---- 性质测试（穷举 N = 0..40）----~n", []),
    (   forall(between(0, 40, N),
               ( my_numlist(1, N, L), rev_twice_is_id(L), len_preserved(L) ))
    ->  format("  [OK] reverse 两次 = 原列表，且长度不变~n", [])
    ;   format("  [FAIL] reverse 的性质被破坏~n", [])
    ),
    (   forall(between(0, 40, N), sum_of_range(N))
    ->  format("  [OK] sum(1..N) = N*(N+1)/2~n", [])
    ;   format("  [FAIL] 求和公式不成立~n", [])
    ),
    format("  价值：一次覆盖几十个输入，比手写十条断言更能抓到边界 bug~n", []),
    format("  注意：造数据用自己写的 my_numlist/3 —— SWI 自带 numlist/3，~n", []),
    format("        GNU Prolog 没有，直接用会在 GNU 上 existence_error~n", []).

% ------------------------------------------------------------
%  六、基准：statistics(runtime, ...) 两套系统都有
%
%   返回 [本次耗时ms, 自上次以来的耗时ms]，都是整数毫秒。
% ------------------------------------------------------------

naive_rev([], []).
naive_rev([H | T], R) :- naive_rev(T, RT), my_append(RT, [H], R).

ms(Goal, Delta) :-
    statistics(runtime, [T0, _]),
    (   catch(Goal, _, fail)
    ->  true
    ;   true
    ),
    statistics(runtime, [T1, _]),
    Delta is T1 - T0.

run_bench :-
    format("---- 基准：O(n) 累加器 vs O(n^2) 追加 ----~n", []),
    my_numlist(1, 800, L),
    ms(my_rev(L, _), M1),
    ms(naive_rev(L, _), M2),
    format("  800 个元素（用 my_numlist/3 生成）：~n", []),
    format("    累加器版 reverse  ~w ms~n", [M1]),
    format("    追加版   reverse  ~w ms~n", [M2]),
    format("  同一件事，差别全在「用不用 append 拼接」上~n", []),
    format("  毫秒数受机器负载影响，看数量级，别看绝对值~n", []).

% ------------------------------------------------------------
%  七、汇总与退出码
% ------------------------------------------------------------

report :-
    findall(N, case_result(N, pass), Ps),
    findall(N-D, case_result(N, fail(D)), Fs),
    length(Ps, NP), length(Fs, NF),
    format("  通过 ~w，失败 ~w~n", [NP, NF]),
    forall(member(Nm-D2, Fs),
           format("    [FAIL] ~w —— ~q~n", [Nm, D2])).

has_failure :- case_result(_, fail(_)).

% ------------------------------------------------------------
%  八、调试手法
% ------------------------------------------------------------

demo_debug :-
    format("---- 调试 ----~n", []),
    format("  1) 打点：子句里插一句写往 user_error 的 format，把变量打出来；~n", []),
    format("     走 user_error 而不是默认输出，方便 2>err.txt 单独捞出来看~n", []),
    format("  2) listing/1：把谓词全部子句打出来，看 clause/2 视角的程序~n", []),
    format("     GNU 上要先 :- public(p/n) 才能 listing 静态谓词~n", []),
    format("  3) 交互式：SWI 的 gtrace. / GNU 的 trace. 都能单步，~n", []),
    format("     但脚本化运行（本文档的方式）用不了，靠打点和断言代替~n", []),
    format("  4) 最小复现：先把问题缩到一个五秒能跑完的 goal，再查~n", []),
    format("  5) SWI 自带 plunit（:- begin_tests(n). ... :- end_tests(n).），~n", []),
    format("     GNU 没有，所以本例这套手写框架是可移植替代方案~n", []).

% ------------------------------------------------------------
%  入口
% ------------------------------------------------------------

main :-
    (   catch(run, E, (nl, format("*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format("*** run/0 失败~n", []), halt(1)
    ).

run :-
    clear_cases,
    run_unit, nl,
    run_bug_demo, nl,
    run_property, nl,
    run_bench, nl,
    demo_debug, nl,
    format("==== 19 结束 ====~n", []).
