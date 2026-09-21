%% ============================================================================
%%  21_constraints.pl —— 约束逻辑编程：CLP(FD)
%%
%%  前面每一章的「求解」都是【生成-测试】：
%%  先靠回溯把所有取值猜出来，再逐个检查条件。规模一大就崩。
%%
%%  约束逻辑编程把顺序倒过来：先把【条件】全部声明出来，让求解器去剪枝，
%%  只在还有希望的空间里搜索。整数有限域上的这套叫 CLP(FD)
%%  （Constraint Logic Programming over Finite Domains）。
%%
%%  ===========================================================================
%%  【本章是全套教程里可移植性最差的一章】——因为两套引擎的 CLP(FD) 是
%%  两套【彼此独立】的实现，连变量的内部表示都不一样：
%%
%%    GNU Prolog ：约束【内建】，不需要加载任何东西。
%%                 谓词是 fd_domain/3、fd_labeling/1、fd_all_different/1。
%%                 fd 变量是一种【独立的类型】，fd_domain 之后 var/1 就是假了。
%%    SWI-Prolog ：约束在标准库里，必须 :- use_module(library(clpfd))。
%%                 谓词是 in/2、label/1、all_different/1。
%%                 fd 变量是【属性变量】，加约束后 var/1 仍然是真。
%%
%%  运算符也不一致：GNU 默认就有 #> #< #= #\= 这些运算符，
%%  SWI 要等 clpfd 加载完了才有（所以加载指令必须放在使用这些运算符的
%%  子句【之前】，否则连语法分析都过不去）。
%%
%%  本章的应对办法：把「两边写法不同的那几件事」包成一层薄适配层
%%  （domain/3、labeling/1、alldiff/1），正文只用适配层。这样示例本身
%%  仍然满足本教程的硬约束：三个通道输出【逐字节一致】。
%%  引擎识别用 current_prolog_flag(dialect, D)——SWI 得到 swi，GNU 得到
%%  gprolog，两边都支持这个标志。
%%
%%  【已知的噪声】下面那行 use_module 指令 GNU 不认识，它会往 stdout 打
%%  一行 "unknown directive use_module/1" 的警告然后忽略掉。这行落在
%%  开始/结束标记【外面】，所以不影响本教程的区间比对。
%%
%%  引擎独有的高级功能（SWI 的 labeling 选项、GNU 的 fd_maximize/2 等）
%%  见同目录的 observe_21_swi.pl 与 observe_21_gnu.pl。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

:- use_module(library(clpfd)).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  适配层（本章唯一与引擎相关的地方）
%% ---------------------------------------------------------------------------
engine(swi)     :- current_prolog_flag(dialect, swi), !.
engine(gprolog) :- current_prolog_flag(dialect, gprolog), !.
engine(unknown).

%%  调用 SWI 专有的谓词，这里必须绕一下：先用 =.. 把「名字 + 参数」拼成目标，
%%  再交给 call/1。为什么不直接写 label(Vs)？因为第三通道 gplc 是【静态链接】
%%  的：它扫到源码里直接的 label/1 调用，就会去符号表里找 label/1 的定义，
%%  找不到就报 "Undefined symbols"。用 =.. 之后，label 只是一个【原子常量】，
%%  链接器眼里它根本不是谓词引用，问题就没了。
swi_meta(Name, Args) :-
    Goal =.. [Name|Args],
    call(Goal).

%%  域声明
%%    GNU：fd_domain/3
%%    SWI：clpfd 的 in/2，域项写成 '..'(Lo, Hi)
%%  这里为什么不写 X in Lo..Hi？因为 GNU 没有定义 in 与 .. 这两个运算符，
%%  那一行在 GNU 上连【语法分析】都通不过。用 '..'(Lo,Hi) 的规范项写法
%%  交给 call/1，就把「运算符定义」这个差异绕开了。
domain(V, Lo, Hi) :- engine(gprolog), !, fd_domain(V, Lo, Hi).
domain(V, Lo, Hi) :- swi_meta(in, [V, '..'(Lo, Hi)]).

domain_list([], _, _).
domain_list([V|Vs], Lo, Hi) :- domain(V, Lo, Hi), domain_list(Vs, Lo, Hi).

%%  标号（把约束变量变成具体整数）
labeling(Vs) :- engine(gprolog), !, fd_labeling(Vs).
labeling(Vs) :- swi_meta(label, [Vs]).

%%  全局约束「两两互不相同」
alldiff(Vs) :- engine(gprolog), !, fd_all_different(Vs).
alldiff(Vs) :- swi_meta(all_different, [Vs]).

%% ---------------------------------------------------------------------------
%%  一、先看暴力法有多笨：3 阶幻方
%% ---------------------------------------------------------------------------
%% 3 阶幻方：把 1..9 填进 3x3，让每行、每列、两条对角线之和都是 15。
magic_ok([A,B,C, D,E,F, G,H,I]) :-
    15 =:= A+B+C, 15 =:= D+E+F, 15 =:= G+H+I,
    15 =:= A+D+G, 15 =:= B+E+H, 15 =:= C+F+I,
    15 =:= A+E+I, 15 =:= C+E+G.

%% 生成-测试：先枚举全部 9! 个排列，再逐个套条件
brute_magic(Sq) :-
    permutation([1,2,3,4,5,6,7,8,9], Sq),
    magic_ok(Sq).

factorial(N, F) :- N =< 1, !, F = 1.
factorial(N, F) :- N > 1, N1 is N - 1, factorial(N1, F1), F is N * F1.

show_magic([A,B,C,D,E,F,G,H,I]) :-
    format("    ~w ~w ~w~n", [A,B,C]),
    format("    ~w ~w ~w~n", [D,E,F]),
    format("    ~w ~w ~w~n", [G,H,I]).

demo_generate_test :-
    say("---- 1. 暴力法：生成-测试 ----"),
    factorial(9, Total),
    format("  1..9 的排列共 9! = ~w 个，暴力法要逐个检查 8 条和条件。~n", [Total]),
    findall(Sq, brute_magic(Sq), BM),
    sort(BM, BMS),
    length(BMS, NB),
    format("  检查完毕，得到 ~w 个解：~n", [NB]),
    BMS = [First|_],
    show_magic(First),
    say("  这 8 个解其实是同一个方阵的 8 种旋转 / 镜像。"),
    say("  问题在于：9! = 36 万这个代价是【先猜后查】的结构决定的，"),
    say("  条件本身完全没帮上忙 —— 比如「A 和 D 不能相等」这件事，"),
    say("  暴力法要等到猜完 9 个数、开始求和的时候才知道。"),
    say("  下一节换约束的做法：把条件【先】交出去。"),
    say(""),
    say("  对了，暴力法这里还有个隐患：permutation/2 生成的是 9! 个排列，"),
    say("  靠回溯一个个试。规模再大一级（比如 4 阶幻方 16! ）就彻底没戏了。").

%% ---------------------------------------------------------------------------
%%  二、适配层就位
%% ---------------------------------------------------------------------------
demo_port_layer :-
    say("---- 2. 先把两个引擎的写法差异挡住 ----"),
    say("  本章正文明令只使用 domain/3、labeling/1、alldiff/1 三个适配谓词，"),
    say("  它们在内部按引擎分派：GNU 走内建 fd_* 谓词，SWI 走 library(clpfd)。"),
    say("  所以本示例在 swipl / gprolog / gplc 三个通道下输出逐字节相同。"),
    say("  顺带一个纪律：下面【绝不打印当前是哪个引擎】——"),
    say("  一打印，三个通道的输出就不一样了，区间比对立刻失败。"),
    % 用一条最简单的事实验证适配层是通的
    domain(P, 1, 3),
    findall(P, labeling([P]), Ps),
    format("  验证一下适配层：域 1..3 的全部取值 ~w~n", [Ps]),
    say("  这段在两边都跑得通，就说明分派走对了。").

%% ---------------------------------------------------------------------------
%%  三、三步：声明域 → 加约束 → 标号
%% ---------------------------------------------------------------------------
demo_basic :-
    say("---- 3. 三步走：域 → 约束 → 标号 ----"),
    % 第一步：域。它是「取值范围」，不是赋值。
    domain(X, 1, 9),
    % 第二步：约束。注意加约束【不会】给 X 一个值。
    X #> 5,
    say("  域 X ∈ 1..9、约束 X > 5，两条都声明完了，此时 X 仍然没有确定值。"),
    say("  实现层面的差别（只说明、不打印）："),
    say("    GNU 的 fd 变量是【独立类型】，domain 之后 var/1 就为假了；"),
    say("    SWI 的 fd 变量是【属性变量】，加约束后 var/1 仍为真。"),
    say("    共同点是：两者都不产生「值」，值要到标号那天才落地。"),
    % 第三步：标号。把「约束集合」变成「具体整数」。
    findall(X, labeling([X]), All),
    format("  标号之后才拿到解，而且顺带拿到了【全部】解：~w~n", [All]),
    say("  关键：labeling/1 是【可回溯】的。标号一次，就遍历了整个解空间。"),
    say("  本教程的做法是先把解收进 findall 再打印，所以能打印「全部解」；"),
    say("  如果直接写 domain(...), X #> 5, labeling([X]), write(X)，"),
    say("  你会只看到第一个解 —— 想看下一个得靠回溯（; 或 fail 循环）。").

%% ---------------------------------------------------------------------------
%%  四、= / is / #= 是三种完全不同的东西
%% ---------------------------------------------------------------------------
demo_vs_is :-
    say("---- 4. = 与 is 与 #= ----"),
    T = 2 + 3,
    format("  T = 2 + 3      → T 这个项就是 ~q，没有算过~n", [T]),
    (   T =:= 5
    ->  say("  T =:= 5        → 真（=:= 会求值，它是算术比较，不是合一）")
    ;   say("  T =:= 5        → 假")
    ),
    N is 2 + 3,
    format("  N is 2 + 3     → N 被绑成数 ~w（is 求值后绑定）~n", [N]),
    domain(K, 1, 9),
    K #= 2 + 3,
    labeling([K]),
    format("  K #= 2 + 3     → K = ~w（既不是合一也不是求值，是【加约束】）~n", [K]),
    say("  一句话区分："),
    say("    =      结构合一。两边长得一样就成功，不管算术。"),
    say("    =:=    算术比较。两边都要求值成数，然后比大小。"),
    say("    is     算术求值 + 绑定。左边必须是待绑定的变量。"),
    say("    #=     加等式约束。两边可以含未绑定变量，由求解器负责满足。"),
    say("  所以 #= 能用 is 用不了的地方：X 还没值的时候。").

%% ---------------------------------------------------------------------------
%%  五、关系约束：一次声明，整个解空间
%% ---------------------------------------------------------------------------
demo_relations :-
    say("---- 5. 关系约束 ----"),
    findall(X-Y, (domain(X,1,3), domain(Y,1,3), X #< Y, labeling([X,Y])), P1),
    sort(P1, S1),
    format("  X < Y，X,Y ∈ 1..3        → ~w~n", [S1]),
    findall(X-Y, (domain(X,1,9), domain(Y,1,9), X + Y #= 10, labeling([X,Y])), P2),
    sort(P2, S2),
    format("  X + Y = 10，X,Y ∈ 1..9   → ~w~n", [S2]),
    findall(X, (domain(X,1,9), X #> 2, X #=< 5, X #\= 4, labeling([X])), L3),
    format("  2 < X ≤ 5 且 X ≠ 4       → ~w~n", [L3]),
    findall(X, (domain(X,-3,3), X #> 0, labeling([X])), L4),
    format("  X > 0，X ∈ -3..3         → ~w~n", [L4]),
    say("  注意最后一例：域可以有负数，域只是一个上下界。"),
    say("  这四条约束里，X #\\= 4 是「不等于」，不是「不等于某个结构」。"),
    say("  别拿 \\= 当它用：\\= 是「现在合不上」，X 未绑定时它一律为假。"),
    say("  另外注意上面每个 findall 都套了 sort/2 —— 见第 10 节的第 ④ 条。").

%% ---------------------------------------------------------------------------
%%  六、全局约束：alldiff 与鸽巢剪枝
%% ---------------------------------------------------------------------------
demo_alldiff :-
    say("---- 6. 全局约束：两两互不相同 ----"),
    % 手写 pairwise 版本作为对照：没有全局视野
    findall([A,B,C],
            ( domain(A,1,3), domain(B,1,3), domain(C,1,3),
              A #\= B, A #\= C, B #\= C,
              labeling([A,B,C]) ),
            H),
    sort(H, HS),
    length(HS, NH),
    format("  手写 A≠B, A≠C, B≠C，域 1..3 → ~w 个解：~w~n", [NH, HS]),
    % 全局版本：一样的结果
    findall([A,B,C],
            ( domain(A,1,3), domain(B,1,3), domain(C,1,3),
              alldiff([A,B,C]),
              labeling([A,B,C]) ),
            G),
    sort(G, GS),
    length(GS, NG),
    format("  换成 alldiff([A,B,C])，同一组域 → ~w 个解~n", [NG]),
    (   HS == GS
    ->  say("  解集合完全一样 —— 全局约束【不改变语义】，只改变求解效率。")
    ;   say("  解集合不一样（不该出现）")
    ),
    % 鸽巢：3 个变量只能取 2 个值，互不相同必无解
    findall([A,B,C],
            ( domain(A,1,2), domain(B,1,2), domain(C,1,2),
              alldiff([A,B,C]),
              labeling([A,B,C]) ),
            P),
    length(P, NP),
    format("  但域缩到 1..2 时：3 个变量互不相同 → ~w 个解~n", [NP]),
    say("  鸽巢原理（3 个东西塞进 2 个格子必然有重复）被【传播】直接判掉了，"),
    say("  求解器根本没去枚举 2³ = 8 种组合。这就是全局约束的价值："),
    say("  它知道「互不相同」这个关系的全局含义，而不只是三个二元不等式的堆积。").

%% ---------------------------------------------------------------------------
%%  七、幻方：约束版
%% ---------------------------------------------------------------------------
clp_magic([A,B,C, D,E,F, G,H,I]) :-
    domain_list([A,B,C, D,E,F, G,H,I], 1, 9),
    alldiff([A,B,C, D,E,F, G,H,I]),
    A+B+C #= 15, D+E+F #= 15, G+H+I #= 15,
    A+D+G #= 15, B+E+H #= 15, C+F+I #= 15,
    A+E+I #= 15, C+E+G #= 15,
    labeling([A,B,C, D,E,F, G,H,I]).

demo_magic :-
    say("---- 7. 幻方：同样的题，换个问法 ----"),
    findall(Sq, brute_magic(Sq), BM),
    sort(BM, BMS),
    length(BMS, NB),
    format("  生成-测试（9! 个排列逐个查）→ ~w 个解~n", [NB]),
    findall(Sq, clp_magic(Sq), CM),
    sort(CM, CMS),
    length(CMS, NC),
    format("  约束版（声明 8 条和等于 15 + 互不相同）→ ~w 个解~n", [NC]),
    (   BMS == CMS
    ->  say("  解集合逐项相同。约束只改变「怎么找」，不改变「找到什么」。")
    ;   say("  解集合不同（不该出现）")
    ),
    BMS = [FirstNeg|_],
    say("  两边唯一的差别是「怎么找」：暴力法用的是 permutation/2，"),
    say("  互不相同这个性质是生成方式自带的，所以条件里根本不用写；"),
    say("  约束版得自己把 alldiff 显式声明出来 —— 这正是声明式的代价与好处："),
    say("  代价是要想清楚所有条件，好处是每条条件都能被求解器拿去剪枝。"),
    show_magic(FirstNeg).

%% ---------------------------------------------------------------------------
%%  八、密码算术：SEND + MORE = MONEY
%% ---------------------------------------------------------------------------
send_more_money([S,E,N,D,M,O,R,Y]) :-
    domain_list([S,E,N,D,M,O,R,Y], 0, 9),
    alldiff([S,E,N,D,M,O,R,Y]),
    S #\= 0,                       % 首位不能是 0
    M #\= 0,
    1000*S + 100*E + 10*N + D
  + 1000*M + 100*O + 10*R + E
    #= 10000*M + 1000*O + 100*N + 10*E + Y,
    labeling([S,E,N,D,M,O,R,Y]).

show_crypt([S,E,N,D,M,O,R,Y]) :-
    Send  is 1000*S + 100*E + 10*N + D,
    More  is 1000*M + 100*O + 10*R + E,
    Money is 10000*M + 1000*O + 100*N + 10*E + Y,
    format("    ~w + ~w = ~w~n", [Send, More, Money]),
    format("    字母取值 S=~w E=~w N=~w D=~w M=~w O=~w R=~w Y=~w~n",
           [S,E,N,D,M,O,R,Y]).

demo_crypt :-
    say("---- 8. 密码算术：SEND + MORE = MONEY ----"),
    say("  题目：8 个字母各代表一个 0..9 的数字，互不相同，S 与 M 不为 0，"),
    say("  让 SEND + MORE = MONEY 成立。"),
    say("  暴力法要试 10 选 8 的排列 = 1814400 个，还要考虑首位不为 0。"),
    findall([S,E,N,D,M,O,R,Y], send_more_money([S,E,N,D,M,O,R,Y]), L),
    sort(L, Sorted),
    length(Sorted, N),
    format("  约束版给出 ~w 个解：~n", [N]),
    forall(member(Sol, Sorted), show_crypt(Sol)),
    say("  这里最值得注意的是最后一句 labeling([S,E,N,D,M,O,R,Y])："),
    say("  变量顺序是抄题目顺序写的，求解器照样很快。"),
    say("  因为它不是「从 S=0 开始穷举」，而是先让等式与 alldiff 互相传播，"),
    say("  把每个字母的域压到很小，再开始试。这正是约束求解的效率来源。").

%% ---------------------------------------------------------------------------
%%  九、N 皇后
%% ---------------------------------------------------------------------------
%% Qs 是每行的皇后所在列号，Qs 的第 R 个元素就是第 R 行的列号
queens(N, Qs) :-
    length(Qs, N),
    domain_list(Qs, 1, N),
    queens_safe(Qs),
    labeling(Qs).

queens_safe([]).
queens_safe([Q|Qs]) :- no_attack(Q, Qs, 1), queens_safe(Qs).

%% 第 D 行之后的皇后与 Q 不能同列、不能同对角线
no_attack(_, [], _).
no_attack(Q, [Q2|Qs], D) :-
    Q #\= Q2,
    Q #\= Q2 + D,
    Q #\= Q2 - D,
    D1 is D + 1,
    no_attack(Q, Qs, D1).

board_row(Qs, R, N) :-
    format("    ", []),
    forall(between(1, N, C), ( nth1(R, Qs, C) -> write('Q') ; write('.') )),
    nl.

show_board(Qs) :-
    length(Qs, N),
    forall(between(1, N, R), board_row(Qs, R, N)),
    nl.

demo_queens :-
    say("---- 9. N 皇后 ----"),
    say("  在 N×N 棋盘上放 N 个皇后，彼此不能互相攻击（不同行、列、对角线）。"),
    say("  用 N 个变量表示每行的列号，于是「不同行」免费得到，"),
    say("  剩下的条件就是 alldiff（不同列）+ 两条对角线约束。"),
    forall(member(N, [4,5,6,7,8]),
           ( findall(Qs, queens(N, Qs), L),
             sort(L, S),
             length(S, C),
             format("  N = ~w → ~w 个解~n", [N, C]) )),
    say("  这一串数字是 N 皇后问题的标准解数：2、10、4、40、92。"),
    say("  6 皇后的 4 个解长这样（Q 是皇后）："),
    findall(Qs, queens(6, Qs), L6),
    sort(L6, S6),
    forall(member(Board, S6), show_board(Board)),
    say("  注意上面每次 findall 之后都接了一句 sort/2。这不是多余："),
    say("  解的顺序取决于求解器标号时的枚举顺序，那是实现细节，"),
    say("  GNU 与 SWI 不保证一致，换个版本也可能变。要比较就先把解排好序。").

%% ---------------------------------------------------------------------------
%%  十、陷阱清单
%% ---------------------------------------------------------------------------
demo_traps :-
    say("---- 10. 用 CLP(FD) 最容易踩的几个坑 ----"),
    % ① 打印未标号的约束变量
    say("  ① 别打印【未标号】的约束变量。"),
    say("     约束变量在内存里是带域信息的特殊对象，两套引擎各有一套打印格式"),
    say("     （SWI 打 _1234 这类编号，GNU 打 _#编号(域) 这类），"),
    say("     所以打印出来必然不同。规矩很简单：先 labeling，再打印。"),
    domain(T1, 1, 9),
    T1 #> 5,
    labeling([T1]),
    format("     标号之后它就是个普通整数了：~w~n", [T1]),
    % ② 忘了声明域
    (   catch(labeling([_NoDom]), _, fail)
    ->  say("  ② 没声明域就 labeling：居然成功了（不该出现）")
    ;   say("  ② 没声明域就直接 labeling：两套引擎都拒绝（抛错或失败）")
    ),
    findall(I, (domain(I, 1, 3), I #> 3, labeling([I])), Impossible),
    length(Impossible, NImpossible),
    format("     但「域声明了、而约束自相矛盾」时两者都不报错，只是 ~w 个解。~n",
           [NImpossible]),
    say("     【静默无解】比报错难查得多 —— 所以解数是 0 时要先怀疑域写错了。"),
    say("     结论：每个约束变量都必须先落到某个 domain/3 上。"),
    % ③ #= 不是 =
    say("  ③ #= 不是 =。X = 2 + 3 把 X 绑成项 2+3；X #= 2 + 3 只是加约束。"),
    say("     反过来，#= 也不能当 = 用来传递结构：它只认整数域里的算术。"),
    % ④ 解的顺序
    say("  ④ 解的顺序是引擎实现细节。要比较两个引擎的结果，先 sort/2 把解排序。"),
    say("     这一条在本章被反复执行：每个 findall 后面几乎都跟着 sort。"),
    % ⑤ 全局约束优先
    say("  ⑤ 能用全局约束就别手写一堆二元约束。alldiff 知道鸽巢原理，"),
    say("     三个变量挤在两个值里它一眼判掉；手写三条 ≠ 只能慢慢试。"),
    % ⑥ 别解析引擎给的错误项
    say("  ⑥ 域写错、变量没域、算术项非法时，两套引擎抛的错误项形状不同。"),
    say("     和第 20 章一样：只捕获、只判断，不要解析里面的内容。"),
    say("  ⑦ 引擎独有的高级功能（SWI 的 labeling(选项, 变量)、GNU 的"),
    say("     fd_maximize/2 这类最优化接口）没有公共写法，用之前先想清楚"),
    say("     是否值得放弃可移植性 —— 本教程的选择是：正文只用公共子集。"),
    say("  最后一条好消息：CLP(FD) 里【没有】浮点。域、约束、标号全是整数，"),
    say("  所以第 07 章那些浮点打印位数、整数除法类型的分歧在这一章不存在。").

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
    format("==== 21 开始 ====~n", []),
    say("约束逻辑编程：把「条件」先声明出去，让求解器去剪枝。"),
    say(""),

    demo_generate_test, say(""),
    demo_port_layer,    say(""),
    demo_basic,         say(""),
    demo_vs_is,         say(""),
    demo_relations,     say(""),
    demo_alldiff,       say(""),
    demo_magic,         say(""),
    demo_crypt,         say(""),
    demo_queens,        say(""),
    demo_traps,         say(""),

    format("==== 21 结束 ====~n", []).
