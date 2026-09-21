%% ============================================================================
%%  observe_22_gnu.pl —— 观察通道（只在 GNU Prolog 上跑）
%%
%%  正文 22_modules.pl 走的是「约定式」路线。这个文件用【同一份带模块头的
%%  文件】在 GNU 上跑一遍，看看会发生什么 —— 结论是：什么都不发生。
%%
%%  它不参与区间比对，只要求「跑到底、stderr 为空」。
%%
%%  看什么：
%%    1. 同一份 :- module(...) 文件，GNU 把指令当未知指令忽略掉
%%    2. 于是内部谓词 mul/3 照样全局可见 —— 一点封装都没有
%%    3. 「模块:谓词」这种限定写法在 GNU 上根本写不出来（: 不是运算符）
%%    4. use_module/1,2、import/1 这类谓词都不存在
%%    5. GNU 的现实做法：consult 加载 + 前缀命名 + 注释里写导出清单
%%    6. consult 会往 stdout 打编译进度 —— 这正是正文自己写加载器的原因
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

geo_path('/tmp/prolog_tutorial_22_obs_gnu.pl').

put_line(S, Line) :- format(S, "~s~n", [Line]).

%% 和 observe_22_swi.pl 写的是【同一份】模块文件
write_geo :-
    geo_path(F),
    open(F, write, S),
    put_line(S, "%% 模块 geo：对外导出 area/3 与 perimeter/3"),
    put_line(S, ":- module(geo, [area/3, perimeter/3])."),
    put_line(S, "area(W, H, A) :- mul(W, H, A)."),
    put_line(S, "perimeter(W, H, P) :- add2(W, H, T), mul(2, T, P)."),
    put_line(S, "mul(A, B, R) :- R is A * B."),
    put_line(S, "add2(A, B, R) :- R is A + B."),
    close(S).

main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 22 观察 开始 ====~n", []),
    say("观察通道 · GNU Prolog · 同一份带模块头的文件"),
    say("（本文件只在一个引擎上跑，所以不追求跨引擎一致，只看原生能力）"),
    say(""),

    say("--- 1. 先确认「模块」这个概念在 GNU 里不存在 ---"),
    (   current_op(_, xfx, ':')
    ->  say("    :  是运算符")
    ;   say("    :  不是运算符 —— 「模块:谓词」这种限定写法根本写不出来")
    ),
    (   catch(use_module('/tmp/whatever.pl'), _, fail)
    ->  say("    use_module/1 存在")
    ;   say("    use_module/1 不存在（连谓词都没有）")
    ),
    (   catch(import(foo/1), _, fail)
    ->  say("    import/1 存在")
    ;   say("    import/1 不存在")
    ),
    say("    这是 ISO 标准本身就没规定的东西，GNU 的实现选择是不做。"),
    say(""),

    say("--- 2. 加载同一份模块文件，看看模块头起了什么作用 ---"),
    write_geo,
    geo_path(F),
    format("    已写出模块文件 ~w~n", [F]),
    say("    它和 observe_22_swi.pl 写的是【同一份】内容，"),
    say("    第一行就是 :- module(geo, [area/3, perimeter/3])."),
    say("    注意下面 consult 的输出里【没有】任何 unknown directive 警告 ——"),
    say("    GNU 认得 module/2 这个名字，但选择安静地忽略它。"),
    say("    （对照一下：写个真不认识的 :- modulex(...). 它会警告"),
    say("      unknown directive modulex/2 —— 所以 module/2 是「认识但不做」。）"),
    say("    这种「安静地忽略」比报错更危险：你以为封装生效了，其实没有。"),
    consult(F),
    (   current_predicate(area/3)
    ->  say("    current_predicate(area/3) → 真（导出表里的）")
    ;   say("    current_predicate(area/3) → 假（不该出现）")
    ),
    (   current_predicate(mul/3)
    ->  say("    current_predicate(mul/3) → 真 —— 内部辅助谓词照样【全局可见】")
    ;   say("    current_predicate(mul/3) → 假（不该出现）")
    ),
    (   catch(mul(6, 7, M1), _, fail)
    ->  format("    而且直接调也是通的：mul(6, 7, R) → ~w~n", [M1])
    ;   say("    mul(6, 7, R) 调不通")
    ),
    say("    结论：模块头被整条忽略，导出表没有任何作用，"),
    say("    所有子句一律倒进同一个全局数据库。"),
    say("    SWI 那边同一个文件下 mul/3 是藏住的 —— 这就是全部差别。"),
    say(""),

    say("--- 3. 那 GNU 上怎么做「模块」 ---"),
    say("    只有三条现实手段："),
    say("      ① consult/1（或 :- include/1）把文件加载进来，一个文件当一个单元；"),
    say("      ② 对外名字加前缀（正文第 2 节的 ma_add / lb_add 那种做法）；"),
    say("      ③ 导出清单写在文件头注释里，靠人守。"),
    say("    前两条正文都演示过了，这里补第三条的一个实操细节："),
    say("    既然藏不住，就别假装有封装 —— 把内部谓词也起成带前缀的名字，"),
    say("    至少让人一眼看出「这是别家的内部实现，不该调」。"),
    say(""),

    say("--- 4. consult 会污染 stdout：正文为什么自己写加载器 ---"),
    say("    注意上面 consult 打印的那两行编译进度："),
    say("      compiling /tmp/... .pl for byte code ..."),
    say("      ... compiled, N lines read - M bytes written, X ms"),
    say("    SWI 的 consult 不会打这些。所以只要示例里调一次 consult，"),
    say("    两个引擎的输出就不可能逐字节一致。"),
    say("    正文 22_modules.pl 因此自己写了一个加载器（读项 + 执行指令 + assertz），"),
    say("    代价是要自己补 retractall 来实现 consult 的「先清后加」替换语义。"),
    say("    真实项目里当然直接用 consult —— 只有要求跨引擎输出一致时才这么讲究。"),
    say(""),

    say("--- 5. GNU 侧可用的加载接口（就这两个） ---"),
    (   catch(consult(F), _, fail)
    ->  say("    consult/1        可用（但会打编译进度）")
    ;   say("    consult/1        不可用")
    ),
    say("      :- include(文件). 只能写在【指令】位置，运行时 call/1 调不通。"),
    say("    两者之外没有第三条路：GNU 没有 ensure_loaded/1，也没有 use_module。"),
    say(""),

    format("==== 22 观察 结束 ====~n", []).
