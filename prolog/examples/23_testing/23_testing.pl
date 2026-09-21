%% ============================================================================
%%  23_testing.pl —— 测试
%%
%%  Prolog 特别需要测试，原因有三层：
%%
%%    1. 同一个谓词在不同【调用模式】下是不同的东西。lib_append/3 既能当
%%       「拼接」也能当「拆分」，测了 (+,+,-) 不等于测了 (-,-,+)。
%%    2. 正确性不只是「答案对不对」，还包括【解的个数】【解的顺序】
%%       【有没有留多余选择点】【副作用发生几次】—— 这些肉眼都看不出来。
%%    3. 本教程要跑两套引擎（第 21、22 章已经见识过差异），
%%       「两边行为一致」这件事只能靠测试钉住。
%%
%%  工具方面两套引擎差得很远：
%%
%%    SWI-Prolog ：有 library(plunit)。:- begin_tests(名). test(名) :- ... 
%%                 :- end_tests(名). 用 run_tests(名) 跑。还带 assertion/1、
%%                 call_with_time_limit/2、time/1 这些。
%%    GNU Prolog ：以上一个都没有，连 assertion/1 都没有。
%%
%%  所以本章自己搭一个几十行的迷你框架。它只用到两边都有的
%%  call/1、catch/3、findall/3、sort/2、msort/2、==/2，
%%  所以三个通道都能跑，而且【输出格式完全由自己控制】——
%%  这一点很关键：本教程的 run-all.sh 要拿三通道的输出逐字节比对。
%%
%%  换句话说，run-all.sh 本身就是个测试框架：23 个示例 × 3 条通道 × 6 条判定，
%%  跑完给一张通过/失败表。它检查的是最硬的那种不变量：「两边输出逐字节相同」。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  被测试的小库
%% ---------------------------------------------------------------------------
lib_append([], L, L).
lib_append([H|T], L, [H|R]) :- lib_append(T, L, R).

lib_sum([], 0).
lib_sum([H|T], S) :- lib_sum(T, S1), S is S1 + H.

lib_max([H|T], M) :- lib_max_acc(T, H, M).

lib_max_acc([], Acc, Acc).
lib_max_acc([H|T], Acc, M) :- H > Acc, !, lib_max_acc(T, H, M).
lib_max_acc([_H|T], Acc, M) :- lib_max_acc(T, Acc, M).

lib_rev(L, R) :- lib_rev_acc(L, [], R).

lib_rev_acc([], Acc, Acc).
lib_rev_acc([H|T], Acc, R) :- lib_rev_acc(T, [H|Acc], R).

lib_len([], 0).
lib_len([_|T], N) :- lib_len(T, N1), N is N1 + 1.

%% 【有 bug 的版本】正数、负数各分一组。
%% 作者手写测试时用的数据里没有 0，于是漏掉了 H =:= 0 的那一支。
lib_sign_buggy([], [], []).
lib_sign_buggy([H|T], [H|Ps], Ns) :- H > 0, !, lib_sign_buggy(T, Ps, Ns).
lib_sign_buggy([H|T], Ps, [H|Ns]) :- H < 0, !, lib_sign_buggy(T, Ps, Ns).

%% 【修好的版本】只多了第四支：0 直接丢掉。
lib_sign([], [], []).
lib_sign([H|T], [H|Ps], Ns) :- H > 0, !, lib_sign(T, Ps, Ns).
lib_sign([H|T], Ps, [H|Ns]) :- H < 0, !, lib_sign(T, Ps, Ns).
lib_sign([0|T], Ps, Ns) :- lib_sign(T, Ps, Ns).

%% ---------------------------------------------------------------------------
%%  迷你测试框架
%% ---------------------------------------------------------------------------
%% 一条用例写成 name(名字, 目标)：目标成功算通过，失败或抛错都算不通过。
%% 想表达更细的断言，就用下面那组 expect_* 包一层 —— 它们本身就是普通谓词，
%% 所以可以自由组合、嵌套。

%% 跑一条用例，结果归一成 ok / bad(为什么)
run_one(name(_Name, Goal), Result) :-
    catch( ( call(Goal) -> Result = ok ; Result = bad(failed) ),
           Err,
           Result = bad(threw(Err)) ).

%% 跑一个套件并打报告
run_suite(Title, Cases) :-
    format("  ~s~n", [Title]),
    findall(N-R, ( member(name(N, G), Cases), run_one(name(N, G), R) ), Results),
    forall(member(N2-bad(Why), Results), report_bad(N2, Why)),
    length(Results, Total),
    findall(N3, member(N3-bad(_), Results), BadNames),
    length(BadNames, Bad),
    Ok is Total - Bad,
    format("    小结：共 ~w 例，通过 ~w，不通过 ~w~n", [Total, Ok, Bad]).

report_bad(Name, failed) :-
    format("    [FAIL] ~w：目标没有成立~n", [Name]).
report_bad(Name, threw(Err)) :-
    functor(Err, F, _),
    format("    [FAIL] ~w：抛了 ~w/… ~n", [Name, F]).

%% ---- 断言 ----

%% 目标必须成立
expect_true(Goal) :- call(Goal).

%% 目标必须无解。
%% 注意 \+ 的语义是「按当前绑定求解不通」，所以被测参数应当已经绑定；
%% 拿未绑定的变量去 expect_false，得到的结论没有意义。
expect_false(Goal) :- \+ call(Goal).

%% 解集合正好是 Expected：自动排序去重 → 忽略【解的顺序】与【重复解】
expect_set(Template, Goal, Expected) :-
    findall(Template, Goal, L),
    sort(L, S),
    sort(Expected, E),
    S == E.

%% 解序列正好是 Expected：保序、保留重复 → 连【解的个数与顺序】一起钉住。
%% 注意它和 expect_set 的区别就在这一句：这里【不排序】，
%% 直接拿 findall 出来的序列和期望序列比。
expect_bag(Template, Goal, Expected) :-
    findall(Template, Goal, L),
    L == Expected.

%% 有且仅有一个解。
%% 顺带说：这也是「没留下多余选择点」的代理指标 ——
%% findall 会把多余的解都收出来，收出一个以上就说明还有别的选择点。
expect_single(Template, Goal) :-
    findall(Template, Goal, [_]).

%% 目标必须抛错，且错误项的 functor 是 Name。
%% catch 里那句 fail 是关键：目标【没抛错】时强制整条用例失败，
%% 否则「没抛错」会被误判成通过。
expect_throw(Goal, Name) :-
    catch( ( call(Goal), fail ),
           Err,
           ( functor(Err, F, _),
             (   F == Name
             ->  true
             ;   throw(unexpected_exception(F, Name))
             )
           )).

%% ---------------------------------------------------------------------------
%%  一、为什么 Prolog 特别需要测试
%% ---------------------------------------------------------------------------
demo_why :-
    say("---- 1. 一个谓词，多种身份 ----"),
    say("  其他语言里，一个函数的观察点只有「返回值」；"),
    say("  Prolog 里同一个谓词换个调用模式就是完全不同的东西。看 lib_append/3："),
    lib_append([1,2], [3], X1),
    format("    拼接模式 lib_append([1,2], [3], X) → X = ~w~n", [X1]),
    findall(P-S, lib_append(P, S, [1,2]), Splits),
    format("    拆分模式 lib_append(P, S, [1,2])   → ~w~n", [Splits]),
    say("  所以「测过了」必须说清测的是哪个模式 —— 第 5 节专门讲这件事。"),
    say(""),
    say("  还有四件肉眼看不出来的事，它们的正确与否同样是 bug："),
    say("    ① 解的个数（多给一个解，调用方的循环就可能多跑一圈）"),
    say("    ② 解的顺序（靠 ! 或 findall 时顺序就是语义的一部分）"),
    say("    ③ 有没有留下多余的选择点（性能问题，甚至内存泄漏）"),
    say("    ④ 副作用发生了几次（assertz、写文件都可能被回溯重放）"),
    say(""),
    say("  再加上本教程的双引擎背景：同一段代码在 SWI 与 GNU 上行为可能不同"),
    say("  （第 21 章的 CLP(FD)、第 22 章的模块）。"),
    say("  把「两边输出一致」写进测试，比事后人工比对可靠得多。"),
    say("  这正是 run-all.sh 在做的事：23 个示例 × 3 条通道 × 6 条判定。"),
    say(""),
    say("  下面从几十行的迷你框架开始 —— 不用任何库，两边都能跑。").

%% ---------------------------------------------------------------------------
%%  二、框架自检：测试框架自己也要被测
%% ---------------------------------------------------------------------------
demo_framework :-
    say("---- 2. 框架自检 ----"),
    say("  搭测试框架的第一步不是测业务代码，而是【证明框架会报失败】。"),
    say("  一个永远打绿勾的框架比没有框架更糟：它给你虚假的安全感。"),
    say("  第一组用例都【应该】通过："),
    run_suite("套件：框架自检 A（预期全通过）", [
        name(true_is_true,        expect_true(true)),
        name(fail_is_false,       expect_false(fail)),
        name(set_ok,              expect_set(X, member(X, [1,2]), [1,2])),
        name(single_ok,           expect_single(X2, X2 = 7)),
        name(throw_ok,            expect_throw(throw(boom), boom)),
        name(bag_order_kept,      expect_bag(Y, member(Y, [3,1,2]), [3,1,2]))
    ]),
    say("  第二组里【故意】埋了四条注定失败的用例（第 1、3、5、6 条）："),
    run_suite("套件：框架自检 B（这四条应当被报成 [FAIL]）", [
        name(deliberately_fails,  expect_true(fail)),
        name(should_pass_1,       expect_true(true)),
        name(set_mismatch,        expect_set(X3, member(X3, [1,2]), [1,3])),
        name(should_pass_2,       expect_single(X4, X4 = 9)),
        name(bag_order_matters,   expect_bag(X5, member(X5, [3,1,2]), [1,2,3])),
        name(no_throw_expected,   expect_throw(true, boom))
    ]),
    say("  看，失败被如实地报出来了，而且指到了具体用例名。"),
    say("  注意第 3 与第 5 条是两种不同的失败方式："),
    say("    第 3 条 set_mismatch      —— 目标成立，但解集合不对；"),
    say("    第 5 条 bag_order_matters —— 解集合一样，只是顺序不同。"),
    say("  顺序也算失败，是 expect_bag 故意的：解的顺序在 Prolog 里是语义。"),
    say("  最后一条 expect_throw(真, boom) 同样值得注意 ——"),
    say("  「该抛错却没抛错」必须是失败，靠的是 catch 里那句 fail。"),
    say("  要是漏了它，这条用例会【静默通过】，是最危险的那种假绿。").

%% ---------------------------------------------------------------------------
%%  三、套件：正确的实现应该全绿
%% ---------------------------------------------------------------------------
demo_suite_pass :-
    say("---- 3. 套件：正常实现 ----"),
    say("  下面这组是被测库的主体，实现都是对的，所以应当全绿："),
    run_suite("套件：lib_sum / lib_max / lib_rev / lib_len", [
        name(sum_empty,    expect_set(S1, lib_sum([], S1), [0])),
        name(sum_ints,     expect_set(S2, lib_sum([1,2,3,4], S2), [10])),
        name(sum_neg,      expect_set(S3, lib_sum([-1,1,-2], S3), [-2])),
        name(max_single,   expect_set(M1, lib_max([7], M1), [7])),
        name(max_mixed,    expect_set(M2, lib_max([3,9,4,9,1], M2), [9])),
        name(max_negative, expect_set(M3, lib_max([-5,-2,-9], M3), [-2])),
        name(rev_empty,    expect_set(R1, lib_rev([], R1), [[]])),
        name(rev_ints,     expect_set(R2, lib_rev([1,2,3], R2), [[3,2,1]])),
        name(len_ground,   expect_set(N1, lib_len([a,b,c], N1), [3])),
        name(len_empty,    expect_set(N2, lib_len([], N2), [0]))
    ]),
    say("  注意这里断言全部用的是 expect_set（解集合）而不是「等于某个值」。"),
    say("  因为被测目标可能给出多个解，用 = 比较会悄悄绑定变量，"),
    say("  写出永远通过的假测试。"),
    say("  另外断言比较的是【项本身】（==），不是打印出来的文本 ——"),
    say("  比文本会踩到浮点位数、变量重命名这些引擎差异（第 7 节）。").

%% ---------------------------------------------------------------------------
%%  四、真实的 bug 是被「没想到的输入」抓出来的
%% ---------------------------------------------------------------------------
demo_suite_bug :-
    say("---- 4. bug 是怎么被抓出来的 ----"),
    say("  被测目标：lib_sign_buggy/3，把列表拆成正数表与负数表。"),
    say("  作者当时手写的三条用例，数据里都没有 0："),
    run_suite("套件：lib_sign_buggy（作者手写的三条）", [
        name(sign_mixed,   expect_set(P-N,   lib_sign_buggy([3,-1,2,-4], P, N), [[3,2]-[-1,-4]])),
        name(sign_all_pos, expect_set(P2-N2, lib_sign_buggy([1,2,3], P2, N2), [[1,2,3]-[]])),
        name(sign_all_neg, expect_set(P3-N3, lib_sign_buggy([-1,-2], P3, N3), [[]-[-1,-2]]))
    ]),
    say("  三条全过，于是「测试通过」了。补上边界用例，问题立刻现身："),
    run_suite("套件：同一实现，补上含 0 的用例", [
        name(sign_mixed_again,  expect_set(P4-N4, lib_sign_buggy([3,-1,2,-4], P4, N4), [[3,2]-[-1,-4]])),
        name(sign_with_zero,    expect_set(P5-N5, lib_sign_buggy([1,0,-2], P5, N5), [[1]-[-2]])),
        name(sign_only_zero,    expect_set(P6-N6, lib_sign_buggy([0,0], P6, N6), [[]-[]]))
    ]),
    say("  后两条被抓住了。原因不是「算错了」，而是【少了 H = 0 的那一支子句】："),
    say("  递归走到 0 时一条子句都匹配不上，谓词整个失败。"),
    say("  这是 Prolog 里最典型的一类 bug：缺子句，而不是算错数。"),
    say("  它有个讨厌的性质：失败会沿调用链往上传，"),
    say("  所以你看到的现象往往出现在离 bug 很远的地方。"),
    say(""),
    say("  修法就是补一支（lib_sign/3 的定义在本文件上方）："),
    run_suite("套件：lib_sign（补上 0 那一支，同样三条用例）", [
        name(sign_mixed_fixed, expect_set(P7-N7, lib_sign([3,-1,2,-4], P7, N7), [[3,2]-[-1,-4]])),
        name(sign_with_zero_fixed, expect_set(P8-N8, lib_sign([1,0,-2], P8, N8), [[1]-[-2]])),
        name(sign_only_zero_fixed, expect_set(P9-N9, lib_sign([0,0], P9, N9), [[]-[]]))
    ]),
    say("  全绿了。注意最后一条：0 被【丢掉】，不归任何一组 ——"),
    say("  这是设计决定。测试的作用不是替你决定，而是把这个决定写下来，"),
    say("  以后谁想改它都得先改测试。这就是回归测试的全部价值。").

%% ---------------------------------------------------------------------------
%%  五、同一个谓词，按调用模式分套件
%% ---------------------------------------------------------------------------
demo_modes :-
    say("---- 5. 按调用模式分开测 ----"),
    say("  被测目标：lib_append/3。它的三种模式行为完全不同："),
    run_suite("套件：lib_append 的三种模式", [
        name(mode_concat,     expect_set(X, lib_append([1,2], [3], X), [[1,2,3]])),
        name(mode_left_empty, expect_set(X2, lib_append([], [1], X2), [[1]])),
        name(mode_split,      expect_set(P-S, lib_append(P, S, [1,2]),
                                        [[]-[1,2], [1]-[2], [1,2]-[]])),
        name(mode_ground_ok,  expect_true(lib_append([1], [2], [1,2]))),
        name(mode_ground_bad, expect_false(lib_append([1], [2], [9,2])))
    ]),
    say("  前三条验「生成」，后两条验「检查」—— 同一个谓词，两套期望。"),
    say(""),
    say("  这里还藏着 Prolog 测试最容易忽略的一类 bug：【不终止】。"),
    say("  lib_len/2 的 (-,+) 模式就是活例子。这么写会永久跑下去："),
    say("    findall(L, (between(0,3,N), lib_len(L, N)), Ls)"),
    say("  原因不是 lib_len 写错了，而是 is/2 只会【失败】，不会帮忙剪枝："),
    say("  等式 N1 + 1 =:= 3 在 N1 = 2 时成立，但 Prolog 还得继续试"),
    say("  N1 = 3、4、5… 才能确认没有别的解 —— 而那个生成器永远不会停。"),
    say("  （写这个示例时我们真的被它挂住过一次，所以专门写下来。）"),
    say("  两个可移植的解法。一是给生成器套 once/1，剪掉多余的选择点："),
    findall(L2, ( between(0, 3, N3), once(lib_len(L2, N3)) ), Bounded),
    length(Bounded, BoundedLen),
    format("    once 版：安全跑完，~w 个解~n", [BoundedLen]),
    say("  二是干脆不用生成模式，改成「先定长度，再构造列表」："),
    findall(L3, ( between(0, 3, M3), length(L3, M3) ), Safe),
    length(Safe, SafeLen),
    format("    length/2 版：~w 个解（该版本连 once 都不用）~n", [SafeLen]),
    say("  样本的生成方式本身也必须可移植：between/3、length/2、findall/3"),
    say("  两边都有而且给出同样的序列 —— 换成引擎私有的随机数就没法比对了。"),
    say("  经验：写测试时先问「这个目标会终止吗」，再问「结果对不对」。").

%% ---------------------------------------------------------------------------
%%  六、性质测试：不写期望值，写不变量
%% ---------------------------------------------------------------------------
%% 样本：长度 N 的整数表，用 between/3 生成，保证两边顺序一致
nlist(N, L) :- findall(I, between(1, N, I), L).

%% 带正负的样本：1..N 各减 3，于是从 N=3 开始就一定会出现 0
nlist_signed(N, L) :- findall(V, ( between(1, N, I), V is I - 3 ), L).

%% 性质 1：反转不改变长度
prop_rev_len :-
    forall(between(0, 5, N),
           ( nlist(N, L), lib_rev(L, R), lib_len(R, RL), RL =:= N )).

%% 性质 2：反转两次回到原样
prop_rev_twice :-
    forall(between(0, 5, N),
           ( nlist(N, L), lib_rev(L, R1), lib_rev(R1, R2), R2 == L )).

%% 性质 3：正数表长度 + 负数表长度 = 原表长度（元素守恒）
prop_sign_count(Lib, L, P, N) :-
    call(Lib, L, P, N),
    lib_len(P, LP), lib_len(N, LN), lib_len(L, LL),
    LP + LN =:= LL.

%% 性质 4：负数表里的元素必须真的都是负数
prop_sign_neg_only(Lib, L, _P, N) :-
    call(Lib, L, _P2, N),
    forall(member(V, N), V < 0).

demo_property :-
    say("---- 6. 性质测试：不写期望值，写不变量 ----"),
    say("  前面每条用例都得手算期望值。性质测试换个思路："),
    say("  不写具体答案，只写【不管输入是什么都必须成立的性质】，"),
    say("  然后拿一批样本去撞。撞不破就说明没找到反例。"),
    run_suite("套件：lib_rev 的两条性质（样本长度 0..5）", [
        name(prop_length_preserved, prop_rev_len),
        name(prop_twice_is_identity, prop_rev_twice)
    ]),
    say("  这两条一过，lib_rev 基本就不用担心了，而且一条期望值都没手算。"),
    say("  加样本只要改 between 的上界 —— 对回归测试特别划算。"),
    say(""),
    say("  性质测试最漂亮的用法是【同一个性质撞两个实现】："),
    say("  元素守恒这条性质，撞修好的 lib_sign/3 会过，"),
    say("  撞有 bug 的 lib_sign_buggy/3 会被抓住："),
    run_suite("套件：元素守恒 + 负组纯净（样本里从 N=3 起一定含 0）", [
        name(prop_count_on_fixed,  prop_all_samples(lib_sign, sign_count_ok)),
        name(prop_neg_on_fixed,    prop_all_samples(lib_sign, sign_neg_ok)),
        name(prop_count_on_buggy,  prop_all_samples(lib_sign_buggy, sign_count_ok)),
        name(prop_neg_on_buggy,    prop_all_samples(lib_sign_buggy, sign_neg_ok))
    ]),
    say("  第 3、4 条被抓住了：lib_sign_buggy 在样本 [-2,-1,0] 上直接失败。"),
    say("  注意这里【没有】重写一条数据、也没有手算任何期望值 ——"),
    say("  同一个性质、同一批样本，换个实现撞就行。这就是它的杠杆。"),
    say("  代价要讲清楚：性质测试只能证明「没找到反例」，不能证明「正确」。"),
    say("  所以它和具体用例是互补的，谁也替不了谁。"),
    say("  一般做法：性质测试扫大范围找反例，找到之后把那个输入"),
    say("  固化成一条具体用例 —— 这样回归时既快又准。").

%% 用一批样本去撞一条性质：任一样本不成立就失败
prop_all_samples(Lib, Prop) :-
    forall(between(0, 4, N),
           ( nlist_signed(N, L),
             call(Prop, Lib, L, _P, _Ng)
           )).

sign_count_ok(Lib, L, P, Ng) :- prop_sign_count(Lib, L, P, Ng).
sign_neg_ok(Lib, L, P, Ng)   :- prop_sign_neg_only(Lib, L, P, Ng).

%% ---------------------------------------------------------------------------
%%  七、可移植性清单
%% ---------------------------------------------------------------------------
demo_portability :-
    say("---- 7. 测试工具的可移植性 ----"),
    say("  SWI-Prolog 有 library(plunit)："),
    say("    :- begin_tests(名字).   test(用例名) :- 目标.   :- end_tests(名字)."),
    say("    跑：run_tests(名字)。还有 assertion/1、call_with_time_limit/2、time/1。"),
    say("  GNU Prolog：以上一个都没有，连一个断言谓词都没有。"),
    say("  两边的交集就是 call/1、catch/3、findall/3、sort/2、msort/2、==/2。"),
    say("  本章框架只用这几个拼出来，所以三个通道都能跑。"),
    say(""),
    say("  工程上怎么选："),
    say("    · 只跑 SWI —— 直接用 plunit，功能齐，能和 CI 集成；"),
    say("    · 要跨引擎 —— 像本章这样自己搭，或者把测试当普通谓词跑。"),
    say("  两条经验，都是被前面几章的差异逼出来的："),
    say("  ① 断言比较【项本身】，不要比较【打印出来的文本】。"),
    say("     比文本会踩到浮点位数（第 07 章）、约束变量打印（第 21 章）、"),
    say("     错误项形状（第 20 章）这些差异。第 4 节那两个套件要是改成"),
    say("     「把解转成字符串再比」，三通道的输出立刻就不一致了。"),
    say("  ② 测试数据也必须是可移植的。样本用 between/3、length/2、findall/3"),
    say("     生成，别用引擎私有的随机数或时间函数 —— 那样连跑两次都不一致。"),
    say("  最后一条，和第 14 章同一个道理：测试【不要往 stderr 写东西】。"),
    say("  run-all.sh 的判定里有一条就是「stderr 必须为空」，"),
    say("  所以本教程所有示例（包括测试代码）的诊断信息都往 stdout 走，"),
    say("  并且只在真的出错时才写 stderr。").

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
    format("==== 23 开始 ====~n", []),
    say("测试框架自己也要被测；断言比项本身，不比文本。"),
    say(""),

    demo_why,         say(""),
    demo_framework,   say(""),
    demo_suite_pass,  say(""),
    demo_suite_bug,   say(""),
    demo_modes,       say(""),
    demo_property,    say(""),
    demo_portability, say(""),

    format("==== 23 结束 ====~n", []).
