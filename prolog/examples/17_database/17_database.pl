%% ============================================================================
%%  17_database.pl —— 动态数据库
%%
%%  Prolog 的程序本身就是一个数据库（事实 + 规则）。默认是「静态」的：
%%  编译/加载后不能改。declare 成 dynamic 之后就能在运行时增删改 ——
%%  这是 Prolog 里唯一真正的「全局可变状态」。
%%
%%  八个动词：
%%    assertz(Clause)   把子句加到最后
%%    asserta(Clause)   把子句加到最前（优先级更高，先被尝试）
%%    retract(Clause)   删一个匹配的子句（会留选择点！），失败若不存在
%%    retractall(Head)  删所有匹配的子句，永远成功
%%    clause(Head,Body) 反射：看某个子句的头与体
%%    abolish(Name/Arity) 删掉整个谓词
%%    dynamic(Name/Arity) 声明可改
%%    listing(Name)     打印（调试用，输出格式引擎相关，本教程不用于比对）
%%
%%  【核心陷阱】assert 与 retract 是副作用，不参与回溯 —— 程序回溯时
%%  它们留下的改动不会撤销。这是 Prolog「不纯粹」的那一面。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

:- dynamic(edge2/2).
:- dynamic(log_/1).
:- dynamic(counter/1).
:- dynamic(fact2/1).
:- dynamic(fib_cache/2).

%% ---------------------------------------------------------------------------
%%  一、基本的增删
%% ---------------------------------------------------------------------------
demo_basic :-
    say("---- 1. 增删改查 ----"),
    assertz(edge2(a, b)),
    assertz(edge2(b, c)),
    assertz(edge2(c, d)),
    findall(X - Y, edge2(X, Y), E1),
    format("  assertz 三条后     ~w~n", [E1]),

    % asserta 插到最前面 —— 影响的是「尝试顺序」
    asserta(edge2(z, a)),
    findall(X2 - Y2, edge2(X2, Y2), E2),
    format("  asserta(z,a) 后    ~w~n", [E2]),

    % retract 删一条；谓词里没别的解时本身失败
    (   retract(edge2(z, _))
    ->  say("  retract(edge2(z,_))   成功")
    ;   say("  retract(edge2(z,_))   失败")
    ),
    (   retract(edge2(no_such, _))
    ->  say("  retract 不存在的事实  成功？")
    ;   say("  retract 不存在的事实  失败（和查库一样，没有就是失败）")
    ),

    % retractall 一次清干净，永远成功
    retractall(edge2(b, _)),
    findall(X3 - Y3, edge2(X3, Y3), E3),
    format("  retractall(b,_) 后 ~w~n", [E3]).

%% ---------------------------------------------------------------------------
%%  二、副作用不回溯：最容易踩的坑
%% ---------------------------------------------------------------------------
demo_no_undo :-
    say("---- 2. 副作用不参与回溯 ----"),
    retractall(log_(_)),
    (   member(X, [1, 2, 3]),
        assertz(log_(X)),
        X > 1,          % X = 1 时这里会失败
        fail
    ;   true
    ),
    findall(X2, log_(X2), L),
    format("  记录到的是 ~w~n", [L]),
    say("  上面 X=1 那次逻辑上「失败了」（X>1 不成立），但它 assertz 进去的"),
    say("  log_(1) 照样留在库里 —— Prolog 回溯时会撤销绑定，但不会撤销副作用。"),
    say("  这就是为什么「用 assert 在循环里累加」能工作：它本来就不打算被撤销。"),
    say("  反过来说，也意味着一个「失败」的查询可能已经改了数据库，要留神。"),
    say("  对比：直接写 X = 1 这类绑定，回溯时会被撤销（第 06 章）。").

%% ---------------------------------------------------------------------------
%%  三、用动态库做「可变变量」：计数器循环
%% ---------------------------------------------------------------------------
%% Prolog 没有可变变量；真要可变，就用动态库里的一个事实当变量。
bump :-
    retract(counter(N)),
    N1 is N + 1,
    assertz(counter(N1)).

count_up(Target, Final) :-
    retractall(counter(_)),
    assertz(counter(0)),
    repeat,
    counter(C),
    (   C >= Target
    ->  !                       % 到目标就跳出循环，砍掉 repeat 的选择点
    ;   bump,
        fail                    % 否则加点数、回溯再来
    ),
    counter(Final).

demo_counter :-
    say("---- 3. 用动态库写「可变变量」----"),
    count_up(5, F1),
    format("  count_up(5)   -> ~w~n", [F1]),
    count_up(100, F2),
    format("  count_up(100) -> ~w~n", [F2]),
    say("  repeat + retract/assert + ! 是 Prolog 唯一的「命令式循环」写法："),
    say("    repeat 制造选择点 → 每轮做一步 → 条件成立就 ! 跳出，否则 fail 重来。"),
    say("  100 轮只是演示；Prolog 里能用递归就别用这种写法，它慢且难读。"),
    say("  真正需要它的场景：状态要在多个谓词之间共享，递归参数传不动。"),

    count_up(3, _),
    counter(Final),
    format("  循环结束后库里剩下的计数器 = ~w~n", [Final]).

%% ---------------------------------------------------------------------------
%%  四、记忆化：动态库最漂亮的应用
%% ---------------------------------------------------------------------------
%% 朴素 fib 是 O(2^n)；把算过的结果缓存进动态库，立刻降到 O(n)。
%% 这就是「记忆化（memoization）」—— 用一小块全局状态换指数级加速。
memo_fib(N, F) :-
    (   fib_cache(N, Cached)
    ->  F = Cached
    ;   fib_compute(N, F),
        assertz(fib_cache(N, F))
    ).

fib_compute(0, 0) :- !.
fib_compute(1, 1) :- !.
fib_compute(N, F) :-
    N > 1,
    N1 is N - 1,
    N2 is N - 2,
    memo_fib(N1, F1),
    memo_fib(N2, F2),
    F is F1 + F2.

demo_memo :-
    say("---- 4. 记忆化：动态库最漂亮的应用 ----"),
    memo_fib(10, F1),
    format("  memo_fib(10)  = ~w~n", [F1]),
    memo_fib(40, F2),
    format("  memo_fib(40)  = ~w~n", [F2]),
    findall(N, fib_cache(N, _), Cached),
    length(Cached, NC),
    format("  缓存里现在有 ~w 条记录~n", [NC]),
    say("  朴素的 fib(40) 要算约 3 亿次调用；带记忆化只要 40 次。"),
    say("  这是动态库最正当的用法：缓存是「幂等的派生物」，删了也只会重算，"),
    say("  不会破坏正确性 —— 所以那个「副作用不回溯」的坑在这里无害。"),
    say("  生产代码里记得给缓存加个清理入口（比如 retractall(fib_cache(_,_))）。").

%% ---------------------------------------------------------------------------
%%  五、反射：clause/2 看子句，abolish/1 删谓词
%% ---------------------------------------------------------------------------
demo_reflect :-
    say("---- 5. 反射：clause/2 与 abolish/1 ----"),
    assertz(fact2(0)),
    assertz((fact2(X) :- X > 1)),
    findall(H - B, clause(fact2(H), B), Clauses),
    numbervars(Clauses, 0, _),
    format("  clause/2 看到 (头-体)：~w~n", [Clauses]),
    say("  事实的体显示为 true；带规则的子句体就是它的右侧。"),
    say("  注意 clause/2 只看得到动态谓词的子句（这是标准的规定）。"),

    say("  current_predicate/1 可以问「这个谓词还存不存在」："),
    (   current_predicate(fact2/1)
    ->  say("    abolish 之前 current_predicate(fact2/1) 成立")
    ;   say("    abolish 之前 current_predicate(fact2/1) 不成立")
    ),
    abolish(fact2/1),
    (   current_predicate(fact2/1)
    ->  say("    abolish 之后仍然存在？")
    ;   say("    abolish 之后已不存在（调用会报 existence_error）")
    ),
    say("  abolish/1 删掉的是整个谓词（所有子句），不只是事实。"),
    say("  危险动作：它不看参数，一个手滑就清空整个谓词，慎用。"),
    say("  另外：对静态谓词 abolish 的行为两套引擎不一致（一个报权限错误，"),
    say("  一个照删不误），所以可移植代码只对 dynamic 谓词用 abolish。"),
    (   current_predicate(price/2)
    ->  say("  对照：静态谓词 price/2 一直都在")
    ;   say("  对照：静态谓词 price/2 也没了")
    ).

price(apple, 3).

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
    format("==== 17 开始 ====~n", []),
    say("动态数据库是 Prolog 唯一的全局可变状态，也是记忆化的标准实现手段。"),
    say(""),

    demo_basic,     say(""),
    demo_no_undo,   say(""),
    demo_counter,   say(""),
    demo_memo,      say(""),
    demo_reflect,   say(""),

    format("==== 17 结束 ====~n", []).
