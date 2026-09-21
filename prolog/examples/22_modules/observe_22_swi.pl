%% ============================================================================
%%  observe_22_swi.pl —— 观察通道（只在 SWI-Prolog 上跑）
%%
%%  正文 22_modules.pl 走的是「约定式」路线：前缀命名 + 文件当边界 + 注释里
%%  写导出清单。那是两边都能做的部分。
%%
%%  这个文件反过来，专门看 SWI 的【真模块系统】。它不参与区间比对，
%%  只要求「跑到底、不往 stderr 写东西」。
%%
%%  看什么：
%%    1. :- module(名字, [导出表]) —— 而且必须是文件的第一条指令
%%    2. use_module/1 加载之后，导出谓词进 user，内部谓词【真的藏住了】
%%    3. 「私有」只是不导出：用「模块:谓词」的限定名照样能调
%%    4. 两个模块可以各自导出同名的 area/3，互不干涉 —— 这就是模块的意义
%%    5. use_module(文件, [导入表]) 选择性导入
%%    6. predicate_property/2 看 exported 属性
%%    7. 反面：GNU 没有这一套
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

geo_path('/tmp/prolog_tutorial_22_obs_geo.pl').
alt_path('/tmp/prolog_tutorial_22_obs_alt.pl').
mix_path('/tmp/prolog_tutorial_22_obs_mix.pl').

put_line(S, Line) :- format(S, "~s~n", [Line]).

%% 模块文件：注意第一行必须是 :- module(...)，否则 use_module 直接报
%% "Domain error: module_header expected"。
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

%% 第二个模块：导出的也叫 area/3，但语义完全不同（算的是周长）
write_alt :-
    alt_path(F),
    open(F, write, S),
    put_line(S, "%% 模块 alt：同样导出 area/3，但它的 area 算的是周长"),
    put_line(S, ":- module(alt, [area/3])."),
    put_line(S, "area(W, H, A) :- A is 2 * (W + H)."),
    close(S).

%% 第三个模块：两个导出，用来演示选择性导入
write_mix :-
    mix_path(F),
    open(F, write, S),
    put_line(S, "%% 模块 mix：导出 foo/1 与 bar/1"),
    put_line(S, ":- module(mix, [foo/1, bar/1])."),
    put_line(S, "foo(1)."),
    put_line(S, "bar(2)."),
    close(S).

main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 22 观察 开始 ====~n", []),
    say("观察通道 · SWI-Prolog · 真模块系统"),
    say("（本文件只在一个引擎上跑，所以不追求跨引擎一致，只看原生能力）"),
    say(""),

    say("--- 1. 加载模块：导出进来，内部藏住 ---"),
    write_geo,
    geo_path(GF),
    format("    已写出模块文件 ~w~n", [GF]),
    say("    它第一行就是 :- module(geo, [area/3, perimeter/3])."),
    say("    这个头【必须在第一条】—— 放到后面，use_module 会直接拒绝："),
    say("      Domain error: module_header expected, found ..."),
    use_module(GF),
    (   current_predicate(area/3)
    ->  say("    加载后 current_predicate(area/3) → 真（导出表里的，进了 user）")
    ;   say("    加载后 current_predicate(area/3) → 假（不该出现）")
    ),
    (   current_predicate(mul/3)
    ->  say("    但 current_predicate(mul/3) → 真（不该出现：mul/3 没在导出表里）")
    ;   say("    而 current_predicate(mul/3) → 假 —— mul/3 被【真的藏住了】")
    ),
    (   current_predicate(geo:mul/3)
    ->  say("    current_predicate(geo:mul/3) → 真 —— 它不是不存在，是「没导出」")
    ;   say("    current_predicate(geo:mul/3) → 假（不该出现）")
    ),
    say(""),

    say("--- 2. 「私有」只是不导出，限定名照样能到 ---"),
    (   catch(geo:mul(6, 7, M1), _, fail)
    ->  format("    geo:mul(6, 7, R) → ~w（模块限定的调用，越过了导出表）~n", [M1])
    ;   say("    geo:mul(6, 7, R) 调不通")
    ),
    say("    所以 SWI 的「私有」是约定 + 导入控制的产物，不是权限墙。"),
    say("    想真正封死，得靠模块里的 meta_predicate/1 或干脆别导出接口。"),
    say(""),

    say("--- 3. 两个模块各自导出同名 area/3，互不干涉 ---"),
    write_alt,
    alt_path(AF),
    % 这个模块不导入任何东西（第二个参数是空表），否则和 geo 的 area/3 撞名
    use_module(AF, []),
    (   catch(geo:area(3, 4, A1), _, fail)
    ->  format("    geo:area(3, 4, A) → ~w（geo 的 area 是面积）~n", [A1])
    ;   say("    geo:area 调不通")
    ),
    (   catch(alt:area(3, 4, A2), _, fail)
    ->  format("    alt:area(3, 4, A) → ~w（alt 的 area 是周长）~n", [A2])
    ;   say("    alt:area 调不通")
    ),
    say("    两个 area/3 同时存在、同名、语义不同，谁也没踩谁。"),
    say("    这就是第 1 节里那个「撞车」问题在 SWI 下的正规解法。"),
    say("    注意上面 use_module 的第二个参数是 []：空导入表 = 只加载、不导入。"),
    say("    要是让它导入，area/3 就会和 geo 的导出撞名，SWI 会报导入冲突。"),
    say(""),

    say("--- 4. 选择性导入：只拿你要的那几个 ---"),
    write_mix,
    mix_path(MF),
    use_module(MF, [foo/1]),
    (   current_predicate(foo/1)
    ->  say("    use_module(文件, [foo/1]) 之后 foo/1 可见")
    ;   say("    foo/1 不可见（不该出现）")
    ),
    (   current_predicate(bar/1)
    ->  say("    但 bar/1 也可见了（不该出现：它没在导入表里）")
    ;   say("    而没写进导入表的 bar/1 不可见 —— 导入表是精确控制的")
    ),
    say("    注意区分两个表：模块自己的【导出表】决定谁能拿，"),
    say("    使用方的【导入表】决定自己拿哪些。"),
    say(""),

    say("--- 5. 从属性上看导出与不导出 ---"),
    (   predicate_property(geo:area(_, _, _), exported)
    ->  say("    predicate_property(geo:area(_,_,_), exported) → 真")
    ;   say("    geo:area 没有 exported 属性（不该出现）")
    ),
    (   predicate_property(geo:mul(_, _, _), exported)
    ->  say("    geo:mul 也有 exported 属性（不该出现）")
    ;   say("    predicate_property(geo:mul(_,_,_), exported) → 假")
    ),
    say("    exported 是【模块声明过】的属性，不是「能被调用」的属性："),
    say("    geo:mul 没有 exported，可第 2 节里它照样调得通。"),
    say(""),

    say("--- 6. 反面清单：GNU 没有这一套 ---"),
    (   current_op(_, xfx, ':')
    ->  say("    :  是运算符")
    ;   say("    :  不是运算符 —— 那「模块:谓词」这种写法根本写不出来")
    ),
    say("    GNU 完全没有：module/2、use_module/1,2、import/1、reexport/2、"),
    say("    meta_predicate/1、add_import_module/4，连「:」这个运算符都没有。"),
    say("    所以正文才只能走前缀命名 + 文件当边界那条路。"),
    say("    同一份带模块头的文件在 GNU 下是什么结果，看 observe_22_gnu.pl。"),
    say(""),

    format("==== 22 观察 结束 ====~n", []).
