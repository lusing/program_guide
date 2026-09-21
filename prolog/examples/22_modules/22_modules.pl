%% ============================================================================
%%  22_modules.pl —— 模块、命名空间与加载边界
%%
%%  Prolog 的数据库是【一个全局命名空间】：所有谓词按「名字/元数」索引，
%%  谁都能看见谁。规模一大，两个不相干的文件定义同名谓词就会互相踩。
%%
%%  解决这个问题的正规手段是模块系统。可惜这套教程的双引擎里：
%%
%%    SWI-Prolog ：有完整的模块系统。:- module(名字, [导出表])、use_module/1,2、
%%                 「模块:目标」限定调用、import/1、reexport/2 …… 一应俱全。
%%    GNU Prolog ：【没有模块系统】。:- module(...) 会被【安静地】忽略掉 ——
%%                 连一行警告都没有，子句照样全部倒进全局数据库。
%%
%%  所以本章正文走【约定式】路线，只讲两边都能做的那部分：
%%    ① 命名空间冲突是怎么发生的（第 1 节）
%%    ② 靠前缀约定划名字（第 2 节）
%%    ③ 一个文件当一个单元边界，导出清单写在文件头注释里（第 3 节）
%%    ④ 加载一个单元到底发生了什么（第 4 节，含一个手写加载器）
%%    ⑤ 加载进来的谓词为什么只能靠元调用访问（第 5 节 —— 这条是第三通道
%%       gplc 逼出来的：它是静态编译，链接期就要把所有调用解析掉）
%%
%%  想看真正的模块系统，看同目录的两个观察文件：
%%    observe_22_swi.pl   真模块、真封装、模块限定调用
%%    observe_22_gnu.pl   同一份带模块头的文件，GNU 照单全收、什么都不藏
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% 第 1、2 节要演示「同一名字被两个单元占用」，所以要能运行时增删子句。
%% 注意这两条声明的写法：:- dynamic(add/3). 在 GNU 上连语法都过不去，
%% 因为 GNU 没把 dynamic 定义成前缀运算符 —— 必须写成带括号的形式。
:- dynamic(add/3).
:- dynamic(ma_add/3).
:- dynamic(lb_add/3).

%% ---------------------------------------------------------------------------
%%  工具：元调用与子句清空
%% ---------------------------------------------------------------------------
%% 把名字当【原子】用，用 =.. 现拼目标再 call/1。
%% 为什么要这么绕？第 5 节会讲清楚 —— 和 gplc 的静态链接有关。
mcall(Name, Args) :-
    Goal =.. [Name|Args],
    call(Goal).

%% 按「名字 + 元数」清空一个谓词。
%% 先 current_predicate/1 判断存在性，因为对不存在的谓词做 retractall 行为不定。
mretractall(Name, Arity) :-
    (   current_predicate(Name/Arity)
    ->  functor(Head, Name, Arity),
        retractall(Head)
    ;   true
    ).

%% 数一个谓词现在有几条子句
count_clauses(Name, Arity, N) :-
    functor(Head, Name, Arity),
    findall(Head, clause(Head, _Body), L),
    length(L, N).

%% ---------------------------------------------------------------------------
%%  一、命名空间冲突是怎么发生的
%% ---------------------------------------------------------------------------
demo_collision :-
    say("---- 1. 一个全局名字，两个不相干的语义 ----"),
    mretractall(add, 3),
    % 假装来自 unit_a.pl：add 是整数加法
    assertz((add(A, B, S) :- S is A + B)),
    % 假装来自 unit_b.pl：add 是把元素加到表头
    assertz((add(X, List, [X|List]))),
    say("  两个互不相关的单元各自定义了自己的 add/3。"),
    say("  在 Prolog 里它们【不是两个谓词】—— 而是同一个名字下的两组子句："),
    count_clauses(add, 3, N),
    format("    add/3 现有子句数 ~w，来自两个单元，共用一条名字~n", [N]),
    (   add(3, 4, R1)
    ->  format("    add(3, 4, R) → ~w（命中的是 unit_a 的子句，结果碰巧对）~n", [R1])
    ;   say("    add(3, 4, R) 失败")
    ),
    (   catch(add([], 5, _), Err, true)
    ->  (   var(Err)
        ->  say("    add([], 5, R) → 成功了（不该出现）")
        ;   say("    add([], 5, R)：先命中 unit_a 的子句，直接抛类型错")
        )
    ;   say("    add([], 5, R) 失败")
    ),
    say("  关键不在「哪条子句才对」，而在于："),
    say("  unit_b 的用户调 add/3 时，命中的是 unit_a 的子句 —— 对方根本不知道"),
    say("  自己的名字被别人占了。子句是先到先试的，报错信息也不会告诉你「撞名了」。"),
    mretractall(add, 3),
    count_clauses(add, 3, N0),
    format("  清空后 add/3 的子句数：~w~n", [N0]),
    say("  这就是模块要解决的问题：让两个单元的同名谓词互不可见。").

%% ---------------------------------------------------------------------------
%%  二、约定式命名空间：前缀
%% ---------------------------------------------------------------------------
demo_prefix :-
    say("---- 2. 退一步：靠前缀把名字分开 ----"),
    assertz((ma_add(A, B, S) :- S is A + B)),
    assertz(lb_add(X, List, [X|List])),
    (   ma_add(3, 4, R1)
    ->  format("  ma_add(3, 4, R)      → ~w（math 单元的加法）~n", [R1])
    ;   say("  ma_add 失败")
    ),
    (   lb_add(z, [a, b], R2)
    ->  format("  lb_add(z, [a, b], R) → ~w（list 单元往表头加元素）~n", [R2])
    ;   say("  lb_add 失败")
    ),
    say("  两条名字互不干扰了。这是 GNU 这类没有模块系统的实现的常规做法，"),
    say("  也是本章正文的选择：前缀约定 + 一个文件当一个单元边界。"),
    say("  代价有三条，都得认："),
    say("    ① 全靠人守规矩，编译器不检查，撞名了也没人提醒你；"),
    say("    ② 名字越写越长，跨单元调用时前缀要反复抄；"),
    say("    ③ 拦不住外面去调前缀里那些本该私有的谓词（下一节会看到这个洞）。"),
    mretractall(ma_add, 3),
    mretractall(lb_add, 3).

%% ---------------------------------------------------------------------------
%%  三、一个文件 = 一个单元边界
%% ---------------------------------------------------------------------------
unit_path('/tmp/prolog_tutorial_22_geo.pl').

%% 把「单元文件」写到磁盘上。
%% 里面故意放一条 :- op(...) 指令，第 7 节要用它演示「加载会改全局状态」。
%%
%% 【写法上的一个坑】下面每一行内容都是作为 ~s 的【实参】传进去的，
%% 而不是直接拼进格式串。原因：两套引擎对格式串里的 % 处理不同 ——
%%   SWI ：% 不是说明符，"%%"原样输出两个百分号
%%   GNU ：% 是说明符，"%%"输出一个百分号（单个 % 还会去实参表里找参数）
%% 两者永远不可能一致，所以本教程的规矩是：内容不进格式串。
write_unit_file :-
    unit_path(F),
    open(F, write, S),
    put_line(S, "%% 单元 geo —— 对外承诺：area/3 与 perimeter/3"),
    put_line(S, "%% 内部辅助：mul/3、add2/3（本该私有，但下面你会看到它们藏不住）"),
    put_line(S, ":- op(700, xfx, '===>')."),
    put_line(S, ":- dynamic(area/3)."),
    put_line(S, ":- dynamic(perimeter/3)."),
    put_line(S, "area(W, H, A) :- mul(W, H, A)."),
    put_line(S, "perimeter(W, H, P) :- add2(W, H, T), mul(2, T, P)."),
    put_line(S, "mul(A, B, R) :- R is A * B."),
    put_line(S, "add2(A, B, R) :- R is A + B."),
    close(S).

put_line(S, Line) :- format(S, "~s~n", [Line]).

demo_unit_layout :-
    say("---- 3. 一个文件 = 一个单元边界 ----"),
    unit_path(F),
    write_unit_file,
    format("  已写出单元文件：~w~n", [F]),
    say("  它的结构就是真实项目的常见样子，只有三层："),
    say("    第一层  头注释 —— 写清「对外承诺什么」。没有模块系统时，"),
    say("            导出清单只能靠注释，机器不检查。"),
    say("    第二层  指令  —— :- op(...) 与 :- dynamic(...)，"),
    say("            它们是「加载时必须执行的动作」，第 7 节会看到副作用。"),
    say("    第三层  实现  —— area/3、perimeter/3 是承诺，"),
    say("            它们再去调下面的内部辅助 mul/3、add2/3。"),
    say("  文件之间就靠「一个文件一个单元」这条约定分工，"),
    say("  加载谁不加载谁，就是你的依赖声明。"),
    say("  文件内容长这样："),
    print_file(F),
    say("  注意上面写文件时的一个坑：内容全都作为 ~s 的实参传进去，"),
    say("  没有一行塞进格式串。因为 % 在格式串里是【引擎相关】的："),
    say("    SWI 的 % 不是说明符，写两个就输出两个百分号；"),
    say("    GNU 的 % 是说明符，写两个只输出一个，单个还会去实参表里找参数。"),
    say("  本教程的规矩：内容不进格式串，一律走实参。").

%% 把文件原样念一遍（沿用第 14 章的 get_code 读行法）
print_file(F) :-
    open(F, read, S),
    print_lines(S),
    close(S).

print_lines(S) :-
    get_code(S, C),
    (   C =:= -1
    ->  true
    ;   get_line(S, C, Codes),
        format("    ~s~n", [Codes]),
        print_lines(S)
    ).

get_line(_, 10, []) :- !.
get_line(_, -1, []) :- !.
get_line(S, C, [C|Rest]) :-
    get_code(S, C2),
    get_line(S, C2, Rest).

%% ---------------------------------------------------------------------------
%%  四、加载一个单元：手写加载器
%% ---------------------------------------------------------------------------
%% 一个「加载」动作要做三件事：读项、执行指令、把子句收进数据库。
%% 内建的 consult/1 就是干这个的 —— 但它有个可移植性问题（第 6 节说明），
%% 所以本章自己写一个。顺便，写一遍就彻底理解 consult 到底做了什么。
load_unit(F) :-
    open(F, read, S),
    load_loop(S),
    close(S).

load_loop(S) :-
    read(S, T),
    (   T == end_of_file
    ->  true
    ;   load_one(T),
        load_loop(S)
    ).

%% 读到的东西分三类：
%%   (:- 目标)      指令   → 交给 load_directive/1
%%   (头 :- 体)     规则   → 存起来
%%   原子/复合项    事实   → 存起来
load_one((:- Goal)) :- !, load_directive(Goal).
load_one((Head :- Body)) :- !, assertz((Head :- Body)).
load_one(Fact) :- assertz(Fact).

%% 指令【不都是】可以当普通目标调的。
%%   op/3           两套引擎都当谓词实现，call/1 直接调得通。
%%   dynamic/1      GNU 只认它的【指令】形式，根本没有 dynamic/1 这个谓词，
%%                  一个 call/1 打过去就是 existence_error。
%% 所以加载器必须对指令分类，不能一律 call/1。
%% 顺带说明：dynamic/1 本来也只是条【声明】，不是必须执行的动作 ——
%% 后面往未定义的谓词上 assertz 时，两套引擎都会自动把它建成可改的谓词。
load_directive(dynamic(_Spec)) :- !, true.
load_directive(Goal) :- call(Goal).

demo_load :-
    say("---- 4. 加载一个单元 ----"),
    unit_path(F),
    write_unit_file,
    say("  现在把它加载进来（用的是上一节那个文件）："),
    mretractall(area, 3),
    mretractall(perimeter, 3),
    mretractall(mul, 3),
    mretractall(add2, 3),
    load_unit(F),
    say("  加载完毕。先试「对外承诺」的那两个："),
    mcall(area, [3, 4, A1]),
    format("    area(3, 4, A)      → ~w~n", [A1]),
    mcall(perimeter, [3, 4, P1]),
    format("    perimeter(3, 4, P) → ~w~n", [P1]),
    say("  再试本该「私有」的内部辅助谓词 mul/3："),
    (   current_predicate(mul/3)
    ->  say("    current_predicate(mul/3) → 真。它在外面【也看得见】。"),
        mcall(mul, [6, 7, M1]),
        format("    而且直接调也能跑：mul(6, 7, R) → ~w~n", [M1])
    ;   say("    current_predicate(mul/3) → 假，看不见")
    ),
    say("  这就是「没有模块系统」的真实后果：加载 = 把子句倒进同一个全局数据库，"),
    say("  根本没有边界。导出清单只能写在注释里，靠人守。"),
    say("  SWI 的 module/2 能真的把 mul/3 藏起来（见 observe_22_swi.pl），"),
    say("  GNU 连 module/2 都不认，上面这个「看得见」就是它的极限（见 observe_22_gnu.pl）。").

%% ---------------------------------------------------------------------------
%%  五、为什么加载进来的谓词只能靠元调用访问
%% ---------------------------------------------------------------------------
demo_meta_call :-
    say("---- 5. 静态编译与运行时加载是冲突的 ----"),
    say("  这一节是第三通道 gplc 逼出来的。gplc 把源码编译成本地二进制，"),
    say("  所有谓词调用都在【链接期】解析成符号地址。"),
    say("  如果正文里直接写一句 area(3, 4, A)，链接器就去找 area/3 的符号，"),
    say("  可 area/3 是程序跑起来之后才加载进来的 —— 于是链接失败："),
    say("    Undefined symbols: predicate(area/3)"),
    say("  解法：把名字当【原子】用，用 =.. 现拼目标再 call/1。"),
    say("  这样链接器看到的只是一个原子常量和 call/1，没有任何符号引用。"),
    unit_path(F),
    write_unit_file,
    mretractall(area, 3),
    mretractall(perimeter, 3),
    mretractall(mul, 3),
    mretractall(add2, 3),
    load_unit(F),
    mcall(area, [3, 4, A2]),
    format("  =.. + call/1 就能跑到：area(3, 4, A) → ~w~n", [A2]),
    say("  代价：丢掉了编译期的名字检查。名字写错不会在编译时报错，"),
    say("  要等运行到那一句才知道（existence_error）。"),
    say("  所以更省事的做法是：把加载边界放到【程序启动之前】——"),
    say("  用 :- consult(...) 这种【指令】加载（指令在第 14 章讲过），"),
    say("  那样谓词在加载期就位，正常调用即可，不必元调用。"),
    say("  运行时加载只有一个场景值得付出这个代价：插件 / 配置驱动的扩展点。").

%% ---------------------------------------------------------------------------
%%  六、加载是叠加，consult 是替换
%% ---------------------------------------------------------------------------
demo_replace :-
    say("---- 6. 重复加载：叠加还是替换 ----"),
    unit_path(F),
    write_unit_file,
    mretractall(area, 3),
    load_unit(F),
    count_clauses(area, 3, N1),
    format("  第一次加载之后，area/3 的子句数：~w~n", [N1]),
    load_unit(F),
    count_clauses(area, 3, N2),
    format("  再加载同一个文件之后：~w —— 手写加载器是【叠加】的~n", [N2]),
    mretractall(area, 3),
    load_unit(F),
    count_clauses(area, 3, N3),
    format("  先 retractall 再加载：~w~n", [N3]),
    say("  内建的 consult/1 自带「先清后加」的替换语义，重复加载不会堆子句；"),
    say("  手写加载器没有这一步，所以要自己补 retractall。"),
    say("  【本章为什么不用 consult/1】GNU 的 consult 会往 stdout 打编译进度："),
    say("    compiling /tmp/... .pl for byte code ..."),
    say("  SWI 不打。这一行要是落在输出里，三通道就不一致了。"),
    say("  真实项目里 consult 是标准做法 —— 只有当你要求跨引擎输出一致时，"),
    say("  才会像本章这样自己动手。").

%% ---------------------------------------------------------------------------
%%  七、加载会改全局状态
%% ---------------------------------------------------------------------------
demo_op_leak :-
    say("---- 7. 加载的副作用：运算符表是全局的 ----"),
    say("  单元文件开头有一条指令：:- op(700, xfx, '===>')."),
    (   current_op(_, xfx, '===>')
    ->  say("  加载之后 current_op(_, xfx, '===>') → 真。"),
        say("  运算符表是【全局】的：加载一个文件，新运算符就进了整个程序。")
    ;   say("  没有找到新运算符（不该出现）")
    ),
    say("  同类的「加载即改变全局状态」还有："),
    say("    · op/3          改运算符表"),
    say("    · set_prolog_flag/2  改引擎标志（本教程每个文件开头都在做这件事）"),
    say("    · dynamic/1     改谓词属性"),
    say("    · include/1     文本包含，连运算符声明都会一起带进来"),
    say("  所以单元文件应当把副作用压到最小 —— 这也是「加载边界」的一部分。"),
    say("  可移植代码的额外理由：两套引擎的运算符集、标志集本来就不一样，"),
    say("  加载进来的东西越多，两边跑出不同结果的机会就越大。").

%% ---------------------------------------------------------------------------
%%  八、include/1 与 consult/1 的区别
%% ---------------------------------------------------------------------------
demo_include :-
    say("---- 8. include/1 不是 consult/1 ----"),
    unit_path(F),
    (   catch(include(F), _, fail)
    ->  say("  include/1 在运行时【可以】调用")
    ;   say("  include/1 在运行时【不可调用】—— 它只能写在指令位置：")
    ),
    say("    :- include('文件.pl')."),
    say("  两者的区别："),
    say("    consult(F)    把 F 当成一个程序单元加载：读项、执行指令、收子句。"),
    say("    :- include(F) 是文本包含：等价于把 F 的内容原样抄到这个位置。"),
    say("                  「抄」意味着 F 里的运算符声明会立刻生效，"),
    say("                  也意味着出错信息里的行号会把两个文件混在一起算。"),
    say("  一句话：include 是文本级的，consult 是逻辑级的。"),
    say("  这也是为什么本教程正文一个 include 都没用 —— 它不可移植（上面的"),
    say("  「运行时不可调用」就是证据），而且副作用比 consult 更难追。").

%% ---------------------------------------------------------------------------
%%  九、可移植性清单
%% ---------------------------------------------------------------------------
demo_portability :-
    say("---- 9. 可移植性清单 ----"),
    say("  SWI-Prolog 的模块系统（本章正文一行都没用）："),
    say("    :- module(名字, [导出/元数, ...])   —— 而且必须是文件的第一条指令，"),
    say("                                          放在别处会直接报 module_header 错"),
    say("    :- use_module(文件)   :- use_module(库, [导入表])"),
    say("    模块限定调用    模块:目标    （冒号是运算符，GNU 不认）"),
    say("    import/1  reexport/2  meta_predicate/1  add_import_module/4 …"),
    say("  GNU Prolog：完全没有模块系统。"),
    say("    :- module(...) 会被【安静地】忽略掉 —— 连警告都不给，"),
    say("    子句照样全部进全局数据库。这种「认识但假装没看见」比报错更危险："),
    say("    你以为封装生效了，其实一点都没有（observe_22_gnu.pl 有实证）。"),
    say("  所以本章的可移植方案是三条约定："),
    say("    ① 一个文件 = 一个单元；"),
    say("    ② 对外名字加前缀，导出清单写在文件头注释里；"),
    say("    ③ 真要「藏起来」时承认做不到 —— 要么接受 SWI 专有，要么别藏。"),
    say("  想看两边原生是什么样，读同目录的两个观察文件："),
    say("    observe_22_swi.pl   同一份带模块头的文件，SWI 下内部谓词被真的藏住"),
    say("    observe_22_gnu.pl   同一份文件，GNU 下内部谓词照样可见"),
    say("  两份观察文件读的是【同一个文件】，结论却相反 ——"),
    say("  这就是「有没有模块系统」的全部差别。").

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
    format("==== 22 开始 ====~n", []),
    say("Prolog 的数据库是一个全局命名空间；模块系统是用来切开它的，"),
    say("但不一定每套实现都有。"),
    say(""),

    demo_collision,    say(""),
    demo_prefix,       say(""),
    demo_unit_layout,  say(""),
    demo_load,         say(""),
    demo_meta_call,    say(""),
    demo_replace,      say(""),
    demo_op_leak,      say(""),
    demo_include,      say(""),
    demo_portability,  say(""),

    format("==== 22 结束 ====~n", []).
