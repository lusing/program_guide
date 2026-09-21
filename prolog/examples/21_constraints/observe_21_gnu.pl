%% ============================================================================
%%  observe_21_gnu.pl —— 观察通道（只在 GNU Prolog 上跑）
%%
%%  正文 21_constraints.pl 是【可移植子集】。这个文件反过来，专门看 GNU
%%  内建 fd 的原生能力。它不参与区间比对，只要求「跑到底、stderr 为空」。
%%
%%  看什么：
%%    1. 域的原生语法 fd_domain/3（GNU 不定义 in / .. / :: 运算符）
%%    2. 未标号的 fd 变量打印成什么样（以及为什么不能进正文）
%%    3. fd_labeling/1、fd_labelingff/1，以及 fd_labeling/2 的选项限制
%%    4. 最优化 fd_maximize/2、fd_minimize/2（SWI 用 labeling 的 max/min 选项）
%%    5. 全局约束 fd_all_different/1、fd_element/3
%%    6. fd 变量是【独立类型】的证据
%%    7. 反面清单：GNU 没有 SWI 那套名字
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 21 观察 开始 ====~n", []),
    say("观察通道 · GNU Prolog · 内建 fd 的原生写法"),
    say("（本文件只在一个引擎上跑，所以不追求跨引擎一致，只看原生能力）"),
    say(""),

    say("--- 1. 域的原生语法：fd_domain/3，而且没有运算符糖 ---"),
    (   current_op(_, xfx, in)
    ->  say("    in   是运算符")
    ;   say("    in   不是运算符 —— GNU 不定义它")
    ),
    (   current_op(_, xfx, '..')
    ->  say("    ..   是运算符")
    ;   say("    ..   不是运算符 —— GNU 不定义它")
    ),
    (   current_op(_, xfx, '::')
    ->  say("    ::   是运算符")
    ;   say("    ::   不是运算符 —— GNU 不定义它")
    ),
    say("    所以正文里如果直接写 X in 1..9，在 GNU 上【语法分析】就过不去；"),
    say("    正文用的是 '..'(Lo,Hi) 规范项 + call/1，绕开了运算符定义。"),
    (   fd_domain(X, 1, 9), X #> 5
    ->  format("    未标号时 write(X) 打出：", []),
        write(X), nl
    ;   say("    失败")
    ),
    say("    那是个 _#编号(域) 形式的特殊对象，编号每次运行都不同。"),
    say("    所以它绝不能出现在正文示例的输出里 —— 这是本章第 ① 条规矩。"),
    (   length(Vs, 4), fd_domain(Vs, 1, 4), fd_labeling(Vs)
    ->  format("    fd_domain 能一次声明一个列表（首解）：→ ~w~n", [Vs])
    ;   say("    失败")
    ),
    say(""),

    say("--- 2. 标号：fd_labeling/1 与 fd_labelingff/1 ---"),
    findall(Y, (fd_domain(Y, 1, 5), fd_labeling([Y])), L1),
    format("    fd_labeling([Y])   枚举顺序 → ~w~n", [L1]),
    findall(Y2, (fd_domain(Y2, 1, 5), fd_labelingff([Y2])), L2),
    format("    fd_labelingff([Y2]) 枚举顺序 → ~w~n", [L2]),
    say("    fd_labelingff 是 first-fail 变体。GNU 也有 fd_labeling/2，"),
    say("    但选项集和 SWI 的 labeling/2 完全是两回事："),
    say("      fd_labeling/2 只认 min(表达式) / max(表达式) 这几个；"),
    say("      SWI 的 labeling/2 认 up / down / ff / max(V) / min(V) …"),
    say("    正文一律不用选项，只用最基础的单参数标号。"),
    say(""),

    say("--- 3. 最优化：fd_maximize/2 与 fd_minimize/2 ---"),
    (   fd_domain(Z, 0, 30), fd_domain(K, 0, 10), Z #= 3 * K, Z #< 30,
        fd_maximize(fd_labeling([Z, K]), Z)
    ->  format("    小于 30 的最大 3 的倍数：Z = ~w（K = ~w）~n", [Z, K])
    ;   say("    失败")
    ),
    (   fd_domain(Z2, 0, 30), fd_domain(K2, 0, 10), Z2 #= 3 * K2,
        fd_minimize(fd_labeling([Z2, K2]), Z2)
    ->  format("    最小的 3 的倍数：Z = ~w（K = ~w）~n", [Z2, K2])
    ;   say("    失败")
    ),
    say("    注意第二个参数写的是「要求最大/最小的那个表达式」，"),
    say("    第一个参数是「怎么写标号目标」。SWI 那边是把目标塞进选项列表，"),
    say("    接口形状完全不同 —— 所以最优化没有公共写法，正文不碰。"),
    say(""),

    say("--- 4. 全局约束：fd_all_different/1 与 fd_element/3 ---"),
    (   length(Ws, 4), fd_domain(Ws, 1, 4), fd_all_different(Ws), fd_labeling(Ws)
    ->  format("    fd_all_different 首解 → ~w~n", [Ws])
    ;   say("    失败")
    ),
    (   fd_element(3, [10, 20, 30], E)
    ->  format("    fd_element(3, [10, 20, 30], E) → E = ~w~n", [E])
    ;   say("    失败")
    ),
    say("    fd_element 的下标是从 1 开始的，而且可以给「还没值的变量」用："),
    (   fd_domain(Ix, 1, 3), fd_element(Ix, [10, 20, 30], Val), fd_labeling([Val])
    ->  format("    fd_element(Ix, [10,20,30], Val) 首解 → Val = ~w~n", [Val])
    ;   say("    失败")
    ),
    say("    注意最后一句 fd_labeling([Val])：要标号的是被约束住的 Val，"),
    say("    而不是下标 Ix —— 这类「哪些变量需要标号」的判断，"),
    say("    在两边都靠手写。所谓「约束式」也不等于全自动。"),
    say(""),

    say("--- 5. GNU 的 fd 变量是一种【独立类型】 ---"),
    fd_domain(T, 1, 9),
    (   var(T)
    ->  say("    fd_domain 之后 var/1 仍然为真")
    ;   say("    fd_domain 之后 var/1 就为假了 —— 它已经不是普通变量")
    ),
    (   catch(functor(T, _, _), _, fail)
    ->  say("    但 functor/3 反而吃它 —— 因为它内部就是 _#编号(域) 这种复合结构")
    ;   say("    连 functor/3 都不吃它")
    ),
    say("    SWI 那边是【属性变量】：var/1 为真，是个「变量」而不是「复合项」。"),
    say("    这就是同一段约束代码在两个引擎上行为不同的根子："),
    say("    连「什么是变量」这件事的定义都不一样。"),
    say(""),
    say("    正文因此立了两条硬规矩："),
    say("      ① 只依赖 domain/3、labeling/1、alldiff/1 这三个动作；"),
    say("      ② 绝不打印未标号的约束变量。"),
    say(""),

    say("--- 6. fd 约束里的算术是有限的 ---"),
    say("    GNU 的 fd 不认识 mod，把它当非 fd 可求值的项："),
    (   catch((fd_domain(M, 1, 9), M mod 2 #= 0, fd_labeling([M])), Err, true)
    ->  (   var(Err)
        ->  format("    M mod 2 #= 0 居然过了：M = ~w~n", [M])
        ;   say("    M mod 2 #= 0 直接抛错（错误项里写着 fd_evaluable）")
        )
    ;   say("    没有解")
    ),
    (   fd_domain(M2, 1, 9), fd_domain(H2, 0, 4), M2 #= 2 * H2, fd_labeling([M2])
    ->  format("    改成乘法就没问题：M = 2 * H → M = ~w~n", [M2])
    ;   say("    失败")
    ),
    say("    结论：约束里的算术要用「域内可传播」的写法（加、减、乘常数），"),
    say("    不要指望两套引擎都支持取模、整除这类运算。"),
    say(""),

    say("--- 7. 反面清单：GNU 没有 SWI 那套名字 ---"),
    (   catch(call(in(_I1, '..'(1, 2))), _, fail)
    ->  say("    in/2              存在")
    ;   say("    in/2              不存在（那是 SWI clpfd 的名字）")
    ),
    (   catch(label([]), _, fail)
    ->  say("    label/1           存在")
    ;   say("    label/1           不存在（那是 SWI clpfd 的名字）")
    ),
    (   catch(all_different([]), _, fail)
    ->  say("    all_different/1   存在")
    ;   say("    all_different/1   不存在（那是 SWI clpfd 的名字）")
    ),
    say("    所以正文那层适配不是洁癖，是必须的。"),
    say(""),

    format("==== 21 观察 结束 ====~n", []).
