%% ============================================================================
%%  24_capstone.pl —— 综合项目：一个表达式语言的解释器
%%
%%  前面 22 章各讲一块，这一章把它们拼成一个能跑的东西：
%%  从一段源码文本（字符）走到一个结果（整数），中间经过四步：
%%
%%    源码文本
%%      │  ① 词法 lex/2        字符码列表 → token 列表        （第 15 章）
%%      ▼
%%    token 列表
%%      │  ② 语法 parse_prog/2  token 列表 → 语句列表          （第 18、19 章）
%%      ▼
%%    语句列表（AST）
%%      │  ③ 语义 exec/3        在环境里求值，产出值与绑定表   （第 05、08、09 章）
%%      ▼
%%    结果
%%      │  ④ 测试 run_suite/2   用迷你框架验语义与错误路径     （第 23 章）
%%      ▼
%%    通过 / 不通过
%%
%%  语言很小，但五脏俱全：
%%    · 语句    let 名字 = 表达式 ;          引入绑定
%%              表达式 ;                     输出它的值
%%    · 表达式  整数 标识符 ( … ) 一元 - 
%%              + - * /   （左结合，优先级 * / 高于 + -）
%%              <  >       （非结合，结果是 1 或 0）
%%              if 条件 then 甲 else 乙
%%    · 错误    除零、未定义变量、非法字符、语法错 —— 全部用 throw/1 报出
%%
%%  ---------------------------------------------------------------
%%  【两处语言设计是被「可移植性」逼出来的，值得单独说】
%%
%%  1. 除法取整除（//），不做浮点除法。
%%     因为浮点数的打印位数两套引擎不一致：SWI 打最短表示（3.14），
%%     GNU 打 17 位（3.1400000000000001）。语言里只要出现浮点，
%%     三通道输出就不可能逐字节一致（第 07 章的坑在这里收账）。
%%
%%  2. 比较表达式返回 1 或 0，不返回 true / false。
%%     布尔原子在两边打印虽然一致，但「条件」和「算术」会用两套类型，
%%     解释器要多一层转换。统一成整数更简单，也让 if 的语义更好讲：
%%     0 为假、非 0 为真。
%%  ---------------------------------------------------------------
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ===========================================================================
%%  ① 词法：字符码列表 → token 列表
%% ===========================================================================
%% 输入用 code list（本教程每个文件都设了 double_quotes=codes，
%% 所以 "abc" 就是 [97,98,99]）。
lex([], []).
lex([C|Cs], Toks) :-
    (   C =< 32
    ->  lex(Cs, Toks)                              % 空白：跳过
    ;   digit_code(C)
    ->  take_digits(Cs, Ds, Rest),                 % 数字
        digits_value([C|Ds], N),
        Toks = [t_num(N)|T],
        lex(Rest, T)
    ;   letter_code(C)
    ->  take_name(Cs, Ns, Rest),                   % 名字 / 关键字
        atom_codes(A, [C|Ns]),
        (   keyword(A, KT)
        ->  Toks = [KT|T]
        ;   Toks = [t_id(A)|T]
        ),
        lex(Rest, T)
    ;   symbol_token(C, Sym)                       % 单字符符号
    ->  Toks = [Sym|T],
        lex(Cs, T)
    ;   throw(lex_error(C))                        % 其它一律报错
    ).

digit_code(C) :- C >= 48, C =< 57.
letter_code(C) :- ( C >= 97, C =< 122 ; C >= 65, C =< 90 ; C =:= 95 ).
name_code(C) :- digit_code(C) ; letter_code(C).

take_digits([C|Cs], [C|Ds], Rest) :- digit_code(C), !, take_digits(Cs, Ds, Rest).
take_digits(Rest, [], Rest).

take_name([C|Cs], [C|Ns], Rest) :- name_code(C), !, take_name(Cs, Ns, Rest).
take_name(Rest, [], Rest).

%% 累加出数值：避免依赖引擎的 number_codes/2
digits_value(Ds, N) :- dv(Ds, 0, N).
dv([], Acc, Acc).
dv([C|Cs], Acc, N) :- A1 is Acc * 10 + (C - 48), dv(Cs, A1, N).

keyword(let,  t_let).
keyword(if,   t_if).
keyword(then, t_then).
keyword(else, t_else).

symbol_token(43, t_plus).       % +
symbol_token(45, t_minus).      % -
symbol_token(42, t_star).       % *
symbol_token(47, t_slash).      % /
symbol_token(40, t_lparen).     % (
symbol_token(41, t_rparen).     % )
symbol_token(61, t_eq).         % =
symbol_token(59, t_semi).       % ;
symbol_token(60, t_lt).         % <
symbol_token(62, t_gt).         % >

%% ===========================================================================
%%  ② 语法：token 列表 → 语句列表（DCG 递归下降）
%% ===========================================================================
%% 表达式的分层写法（每层一个非终结符），这样优先级就体现在结构里，
%% 不需要任何优先级表：
%%    expr → cmp → add → mul → unary → primary
%% 左结合用「尾循环 + 累加器」实现：add_loop/2 一路把左边的结果带下去。
parse_prog(Tokens, Stmts) :-
    (   phrase(prog(Stmts), Tokens)
    ->  true
    ;   throw(parse_error(Tokens))
    ).

prog(Stmts) --> stmt_list(Stmts).

stmt_list([S|Ss]) --> stmt(S), stmt_list(Ss).
stmt_list([]) --> [].

stmt(let(X, E)) --> [t_let, t_id(X), t_eq], expr(E), [t_semi].
stmt(emit(E))   --> expr(E), [t_semi].

expr(E) --> cmp(E).

%% 比较是非结合的：a < b < c 不合法，必须写成 (a < b) < c
cmp(E) --> add(A), cmp_rest(A, E).
cmp_rest(A, lt(A, B)) --> [t_lt], add(B).
cmp_rest(A, gt(A, B)) --> [t_gt], add(B).
cmp_rest(A, A)        --> [].

%% 加减左结合
add(E) --> mul(A), add_loop(A, E).
add_loop(A, E) --> [t_plus],  mul(B), add_loop(plus(A, B), E).
add_loop(A, E) --> [t_minus], mul(B), add_loop(minus(A, B), E).
add_loop(A, A) --> [].

%% 乘除左结合，优先级高于加减（因为它们处在更下层）
mul(E) --> unary(A), mul_loop(A, E).
mul_loop(A, E) --> [t_star],  unary(B), mul_loop(times(A, B), E).
mul_loop(A, E) --> [t_slash], unary(B), mul_loop(divide(A, B), E).
mul_loop(A, A) --> [].

%% 一元负号
unary(neg(A)) --> [t_minus], unary(A).
unary(A)      --> primary(A).

primary(num(N))   --> [t_num(N)].
primary(ident(X)) --> [t_id(X)].
primary(E)        --> [t_lparen], expr(E), [t_rparen].
primary(ifthenelse(C, T, E)) -->
    [t_if], expr(C), [t_then], expr(T), [t_else], expr(E).

%% ===========================================================================
%%  ③ 语义：在环境里求值
%% ===========================================================================
%% 环境就是关联表 [名字-值, ...]，最新的绑定放在最前面。
%% 查找用 == 比较（不绑定变量），返回 some/ none —— 和前一章同一个思路，
%% 「找不到」是一个正常结果，不该用异常表达（第 20 章）。
lookup(X, Env, Result) :-
    (   find_binding(X, Env, V)
    ->  Result = some(V)
    ;   Result = none
    ).

find_binding(X, [X2-V|_], V) :- X == X2, !.
find_binding(X, [_|Rest], V) :- find_binding(X, Rest, V).

%% 对表达式求值。环境是只读的，所以整个求值是纯的 ——
%% 这一点很重要：纯谓词可以随便回溯、随便放进 findall（第 23 章用它写断言）。
eval(num(N), _Env, N) :- !.
eval(ident(X), Env, V) :-
    !,
    (   lookup(X, Env, some(V0))
    ->  V = V0
    ;   throw(undefined_variable(X))
    ).
eval(neg(A), Env, V) :- !, eval(A, Env, VA), V is -VA.
eval(plus(A, B),  Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), V is VA + VB.
eval(minus(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), V is VA - VB.
eval(times(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), V is VA * VB.
eval(divide(A, B), Env, V) :-
    !,
    eval(A, Env, VA),
    eval(B, Env, VB),
    (   VB =:= 0
    ->  throw(division_by_zero(VA, VB))
    ;   V is VA // VB                    % 整除，理由见文件头
    ).
eval(lt(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), truth(VA < VB, V).
eval(gt(A, B), Env, V) :- !, eval(A, Env, VA), eval(B, Env, VB), truth(VA > VB, V).
eval(ifthenelse(C, T, E), Env, V) :-
    !,
    eval(C, Env, VC),
    (   VC =:= 0
    ->  eval(E, Env, V)          % 0 为假
    ;   eval(T, Env, V)          % 非 0 为真
    ).

%% 把「成立 / 不成立」变成整数 1 / 0。
%% 注意参数收的是【目标】而不是布尔项：Prolog 里 VA > VB 只在被调用时才求值，
%% 写成 truth(VA > VB, V) 传进来的是项 >(VA,VB)，它既不是 true 也不是 false，
%% 所以下面必须用 call/1 去调它 —— 这是从别的语言过来最容易踩的一脚。
truth(Goal, 1) :- call(Goal), !.
truth(_Goal, 0).

%% 跑语句列表：维护环境，收集所有 emit 的值（按出现顺序）
exec(Stmts, Env, Values) :- exec_loop(Stmts, [], Env, [], Acc), reverse(Acc, Values).

exec_loop([], Env, Env, Acc, Acc).
exec_loop([let(X, E)|Rest], Env0, Env, Acc, Values) :-
    eval(E, Env0, V),
    exec_loop(Rest, [X-V|Env0], Env, Acc, Values).
exec_loop([emit(E)|Rest], Env0, Env, Acc, Values) :-
    eval(E, Env0, V),
    exec_loop(Rest, Env0, Env, [V|Acc], Values).

%% 给测试用：只要最后一个 emit 的值
value_of(Src, V) :-
    lex(Src, Toks),
    parse_prog(Toks, Stmts),
    exec(Stmts, _Env, Values),
    last(Values, V).

%% ===========================================================================
%%  ④ 展示用的几个小程序
%% ===========================================================================
show_bindings(Env) :-
    reverse(Env, Ordered),
    (   Ordered == []
    ->  say("      绑定表：空")
    ;   say("      绑定表（按声明顺序）："),
        forall(member(X-V, Ordered), format("        ~w = ~w~n", [X, V]))
    ).

show_values(Values) :-
    (   Values == []
    ->  say("      （没有输出表达式）")
    ;   say("      输出值（按出现顺序）："),
        forall(member(V, Values), format("        ~w~n", [V]))
    ).

run_source(Src) :-
    format("    源码：~s~n", [Src]),
    lex(Src, Toks),
    parse_prog(Toks, Stmts),
    exec(Stmts, Env, Values),
    show_bindings(Env),
    show_values(Values).

show_ast(Src) :-
    format("    ~s~n", [Src]),
    lex(Src, Toks),
    parse_prog(Toks, Stmts),
    forall(member(S, Stmts), format("      ~q~n", [S])).

%% 错误只打印 functor / 元数，不打印引擎给的东西（第 20 章的纪律）。
%% 唯一的例外是 undefined_variable/1 —— 那是我自己抛的，可以放心打全。
show_error(Err) :-
    functor(Err, F, N),
    (   Err = undefined_variable(X)
    ->  format("      抓到 undefined_variable(~w)~n", [X])
    ;   format("      抓到 ~w/~w（错误项的内容是引擎自由的，不解析）~n", [F, N])
    ).

try_source(Src) :-
    format("    源码：~s~n", [Src]),
    (   catch(( lex(Src, Toks), parse_prog(Toks, Stmts), exec(Stmts, _Env, Vs) ),
              Err,
              ( show_error(Err), fail ))
    ->  (   Vs == []
        ->  say("      跑完了，没有输出表达式")
        ;   format("      跑完了，输出值 ~w~n", [Vs])
        )
    ;   true
    ).

%% ===========================================================================
%%  迷你测试框架（用第 23 章那套，这里只留需要的三个断言）
%% ===========================================================================
run_one(name(_Name, Goal), Result) :-
    catch( ( call(Goal) -> Result = ok ; Result = bad(failed) ),
           Err,
           Result = bad(threw(Err)) ).

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

expect_set(Template, Goal, Expected) :-
    findall(Template, Goal, L),
    sort(L, S),
    sort(Expected, E),
    S == E.

expect_throw(Goal, Name) :-
    catch( ( call(Goal), fail ),
           Err,
           ( functor(Err, F, _),
             (   F == Name
             ->  true
             ;   throw(unexpected_exception(F, Name))
             )
           )).

%% ===========================================================================
%%  各节
%% ===========================================================================
demo_goal :-
    say("---- 1. 项目：四步流水线 ----"),
    say("  目标：读一段源码文本，算出结果。中间是四步流水线，"),
    say("  每一步都对应前面某一章的手法："),
    say("    ① 词法  lex/2         字符码列表 → token 列表     第 15 章"),
    say("    ② 语法  parse_prog/2  token 列表 → 语句列表(AST)  第 18、19 章"),
    say("    ③ 语义  exec/3        在环境里求值 → 值 + 绑定表  第 05、08、09 章"),
    say("    ④ 测试  run_suite/2   验语义与错误路径            第 23 章"),
    say("  另外还用到了："),
    say("    错误用 throw/catch 报（第 20 章）、「找不到变量」用 some/none（第 20 章）、"),
    say("    环境用关联表 + member/2 查找（第 08 章）、"),
    say("    一元负号与优先级靠运算符/分层写（第 16 章）、"),
    say("    整个求值是纯的，所以能直接塞进 findall 做断言（第 11、13 章）。"),
    say(""),
    say("  语言语法（很小，但该有的都有）："),
    say("    语句     let 名字 = 表达式 ;      表达式 ;"),
    say("    表达式   整数 名字 ( … ) 一元-   + - * /"),
    say("              < >（结果 1 或 0）  if 条件 then 甲 else 乙"),
    say("  两处设计是被「可移植性」逼出来的，第 4 节末尾会专门交代。").

demo_lex :-
    say("---- 2. 第一步：词法 ----"),
    say("  输入是字符码列表（本教程设了 double_quotes=codes，\"abc\" 就是 [97,98,99]），"),
    say("  输出是 token 列表。看几个例子："),
    lex("let a = 3;", T1),
    format("    let a = 3;      → ~w~n", [T1]),
    lex("1 + 2 * (3 - 4);", T2),
    format("    1 + 2 * (3 - 4); → ~w~n", [T2]),
    lex("if x > 5 then 1 else 0;", T3),
    format("    if x > 5 then 1 else 0; → ~w~n", [T3]),
    say("  实现上的两个细节："),
    say("    · 数字和名字都是「先收集字符、再一次性成值」的循环（take_digits / take_name），"),
    say("      这种「收集到分隔符为止」的写法在第 15 章整理过。"),
    say("    · 数值是自己累加的（Acc * 10 + (C - 48)），没用 number_codes/2 ——"),
    say("      少依赖一个引擎可能实现不一致的谓词，成本只是三行。"),
    say("  遇到不认识的字符直接 throw lex_error(C)，不返回「带错误标记的 token」："),
    say("  错误早发现比晚发现好，而且 token 列表保持「全是合法的」这个不变量，"),
    say("  后面的语法阶段就不用再检查了。").

demo_parse :-
    say("---- 3. 第二步：语法（DCG 递归下降）----"),
    say("  表达式的分层写法让优先级体现在结构里，不需要优先级表："),
    say("    expr → cmp → add → mul → unary → primary"),
    say("  左结合用「尾循环 + 累加器」：add_loop/2 把左边已经算好的结果一路带下去。"),
    say("  先看优先级是怎么落地成 AST 形状的："),
    show_ast("1 + 2 * 3;"),
    show_ast("1 * 2 + 3;"),
    show_ast("(1 + 2) * 3;"),
    say("  再看左结合、一元负号、条件表达式、以及一个完整的 let 语句："),
    show_ast("1 - 2 - 3;"),
    show_ast("let k = -8 + 10;"),
    show_ast("if 1 < 2 then 3 else 4;"),
    say("  注意 1 - 2 - 3 解析成 minus(minus(num(1),num(2)),num(3))，"),
    say("  也就是「先算左边」—— 这就是左结合。"),
    say("  比较是非结合的：a < b < c 会直接语法错，必须写成 (a < b) < c。"),
    say("  这一条是故意的：让「链式比较」这种歧义在语法层就消失。"),
    say("  还有一个经典坑：悬空 else。if 甲 then if 乙 then 1 else 2 else 3 里，"),
    say("  那个 else 归谁？本实现的规则是「先满足内层」，于是内层吃掉 else 之后"),
    say("  外层再找不到自己的 else，整个式子语法错。想看嵌套 if 就加括号："),
    show_ast("if 1 < 2 then (if 3 > 4 then 1 else 2) else 3;").

demo_eval :-
    say("---- 4. 第三步：语义（环境 + 求值）----"),
    say("  环境是关联表，最新的绑定放最前面，所以后来者遮蔽先来者。"),
    say("  求值是纯的：eval/3 只读环境，不写数据库，也没有副作用。"),
    say(""),
    say("  [a] 算术与优先级："),
    run_source("let a = 3; let b = 4; let c = a * a + b * b; c;"),
    say(""),
    say("  [b] 变量遮蔽：同一个名字绑定两次，后来的生效："),
    run_source("let a = 1; let a = 2; a;"),
    say(""),
    say("  [c] 括号、整除、一元负号："),
    run_source("let r = (2 + 3) * (4 + 1); r;"),
    run_source("let d = 17; let q = d / 4; q;"),
    run_source("let m = 8; let k = -m + 10; k;"),
    say(""),
    say("  [d] 条件：比较表达式返回 1 / 0，0 为假、非 0 为真："),
    run_source("if 5 > 3 then 100 else 200;"),
    run_source("if 5 > 7 then 100 else 200;"),
    run_source("5 > 3;"),
    say(""),
    say("  [e] 一个程序可以有多条输出："),
    run_source("let n = 10; n; n * n; if n > 5 then n * 2 else n;"),
    say("  注意绑定表是按声明顺序打印的 —— 环境里其实是倒序（新绑定在前），"),
    say("  展示时 reverse 了一下。这一步用第 08 章的 reverse/2 就够了。"),
    say(""),
    say("  两处语言设计是被可移植性逼出来的："),
    say("    ① 除法取整除（//）。因为浮点打印位数两套引擎不一致："),
    say("       SWI 打最短表示（3.14），GNU 打 17 位（3.1400000000000001）。"),
    say("       语言里只要出现浮点，三通道输出就不可能逐字节一致。"),
    say("    ② 比较返回 1 / 0 而不是 true / false。"),
    say("       统一成整数后，if 的语义只有一条规则：0 为假、非 0 为真，"),
    say("       不必在「布尔类型」和「整数类型」之间来回转换。"),
    say("  这两条都是设计决定，也都能换个做法 —— 代价是放弃跨引擎一致。").

demo_errors :-
    say("---- 5. 错误路径：四类错误，四种 functor ----"),
    say("  解释器用 throw/1 报错，错误项统一是「名字 + 字段」的形状（第 20 章）。"),
    say("  调用方按 functor 分类处理，绝不解析引擎给的错误项。"),
    say(""),
    say("  [a] 非法字符（词法阶段）："),
    try_source("let a = 1 & 2;"),
    say(""),
    say("  [b] 语法错（语法阶段）。错误项里带着出错位置剩下的 token ——"),
    say("      但只在调试时看，正式代码只认 functor："),
    try_source("let a = ;"),
    try_source("let a = 1 +;"),
    say(""),
    say("  [c] 未定义变量（语义阶段）："),
    try_source("x + 1;"),
    try_source("let a = b;"),
    say(""),
    say("  [d] 除零（语义阶段，而且是运行到那一步才知道）："),
    try_source("let a = 7 / 0;"),
    say(""),
    say("  注意四种错误的 functor 各不相同，所以调用方可以精确地分类："),
    say("    lex_error/1        输入里有非法字符"),
    say("    parse_error/1      语法不对"),
    say("    undefined_variable/1  名字没绑定"),
    say("    division_by_zero/2 除数为 0"),
    say("  还有一个「不该用异常」的地方：查一个没绑定的变量。"),
    say("  等等 —— 那不就是 undefined_variable 吗？区别在于【谁的责任】："),
    say("    用户写的源码里引用了未绑定的名字 → 是程序错误 → 抛异常；"),
    say("    解释器内部去查一个环境 → 查不到是正常结果 → 返回 none。"),
    say("  同样一件事，在语言边界内是错误，在实现内部是返回值。"),
    say("  lookup/3 用的就是 none，而 eval/3 把它升级成了异常 ——"),
    say("  这一层「翻译」发生在哪里，就是模块设计的分界线。").

demo_tests :-
    say("---- 6. 第四步：给解释器写测试 ----"),
    say("  流水线三步都是纯谓词，所以测试特别省事：给源码字符串、要期望值。"),
    say("  value_of/2 把「词法 + 语法 + 语义」串起来，直接返回最后一个输出值："),
    run_suite("套件：核心语义", [
        name(arith_precedence, expect_set(V1,  value_of("1 + 2 * 3;", V1), [7])),
        name(paren_override,   expect_set(V2,  value_of("(1 + 2) * 3;", V2), [9])),
        name(left_assoc_minus, expect_set(V3,  value_of("10 - 3 - 2;", V3), [5])),
        name(unary_minus,      expect_set(V4,  value_of("let m = 8; let k = -m + 10; k;", V4), [2])),
        name(integer_div,      expect_set(V5,  value_of("17 / 4;", V5), [4])),
        name(let_chain,        expect_set(V6,  value_of("let a = 3; let b = a * 2; b + 1;", V6), [7])),
        name(shadowing,        expect_set(V7,  value_of("let a = 1; let a = 2; a;", V7), [2])),
        name(cmp_true_is_one,  expect_set(V8,  value_of("5 > 3;", V8), [1])),
        name(cmp_false_is_zero, expect_set(V9, value_of("5 < 3;", V9), [0])),
        name(cond_true,        expect_set(V10, value_of("if 5 > 3 then 100 else 200;", V10), [100])),
        name(cond_false,       expect_set(V11, value_of("if 5 > 7 then 100 else 200;", V11), [200])),
        name(nested_if_parens, expect_set(V12,
                 value_of("if 1 < 2 then (if 3 > 4 then 1 else 2) else 3;", V12), [2])),
        name(cond_zero_is_false, expect_set(V13,
                 value_of("if 0 then 1 else 2;", V13), [2])),
        name(multi_emit,       expect_set(V14,
                 value_of("let n = 6; n * n;", V14), [36]))
    ]),
    say(""),
    say("  错误路径同样要测 —— 而且这是最容易漏测的一半："),
    run_suite("套件：错误路径（每种错误都该抛出，functor 固定）", [
        name(err_lex_char,    expect_throw(value_of("let a = 1 & 2;", _), lex_error)),
        name(err_parse_stmt,  expect_throw(value_of("let a = ;", _), parse_error)),
        name(err_parse_expr,  expect_throw(value_of("1 +;", _), parse_error)),
        name(err_undef_var,   expect_throw(value_of("x + 1;", _), undefined_variable)),
        name(err_undef_rhs,   expect_throw(value_of("let a = b;", _), undefined_variable)),
        name(err_div_zero,    expect_throw(value_of("7 / 0;", _), division_by_zero))
    ]),
    say("  全绿。这里体现了两条原则："),
    say("    ① 断言只比【值】（expect_set 比项本身），不比打印出来的文本；"),
    say("       否则浮点位数、变量重命名这些差异会把测试弄成假绿或假红。"),
    say("    ② 错误路径也有契约。既然 functor 是承诺的一部分，就写进测试；"),
    say("       哪天有人把 division_by_zero 改名成 div0，测试立刻报警。"),
    say("  另外 value_of/2 是纯的，所以将来要换成性质测试（第 23 章）也行："),
    say("  比如「对任意两组整数，加法满足交换律」—— 撒样本撞就行。").

demo_wrapup :-
    say("---- 7. 收尾 ----"),
    say("  这个项目一共四百来行，把前面 22 章的手法都用上了："),
    say("    词法    字符码、atom_codes、累加（第 15 章）"),
    say("    语法    DCG、分层优先、尾循环左结合（第 18、19 章）"),
    say("    语义    关联表、some/none、纯求值（第 08、20 章）"),
    say("    错误    throw/catch、自己的错误项、不解析引擎错误项（第 20 章）"),
    say("    测试    迷你框架、断言比项、错误路径也测（第 23 章）"),
    say("    展示    format 排版、~q 看 AST（第 14、16 章）"),
    say("    约束    三通道逐字节一致，逼出了「整除」与「1/0 当布尔」（第 07、21 章）"),
    say(""),
    say("  最后一个问题：这个解释器在两边跑出来一样吗？"),
    say("  一样。它的每一条判定都只用公共子集，而且刻意避开了："),
    say("    · 浮点（打印位数不同）"),
    say("    · CLP(FD)（两套实现，第 21 章）"),
    say("    · 模块系统（GNU 没有，第 22 章）"),
    say("    · 打印未绑定的变量（编号不同）"),
    say("    · 解析引擎给的错误项（形状不同）"),
    say("  这就是 24 章下来沉淀出的那份「安全子集」—— 它不华丽，但两边都认。"),
    say(""),
    say("  想继续往下走，几个方向："),
    say("    · 给语言加函数定义与递归调用 —— 会碰上闭包与作用域，这里正好练手；"),
    say("    · 把 AST 反向打印回源码（第 19 章做过一半：DCG 生成）；"),
    say("    · 加类型检查，把 undefined_variable 从运行时错误提前到静态错误；"),
    say("    · 把环境换成持久化数据结构，体会一下纯函数的代价与好处。"),
    say("    · 想做「约束求解器」这种更大件的东西，回头看第 21 章的 CLP(FD)。"),
    say(""),
    say("  最后一句话：Prolog 的长处不在「写得快」，而在「改得准」。"),
    say("  声明式的部分越纯粹（像这里的词法、语法、求值），"),
    say("  能被测试、能被复用、能跨实现的面积就越大。"),
    say("  前面 23 章里那些看起来琐碎的「可移植性纪律」，到这里就变成了工程红利。").

%% ===========================================================================
%%  入口
%% ===========================================================================
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 24 开始 ====~n", []),
    say("综合项目：源码文本 → 词法 → 语法 → 语义 → 测试。"),
    say(""),

    demo_goal,     say(""),
    demo_lex,      say(""),
    demo_parse,    say(""),
    demo_eval,     say(""),
    demo_errors,   say(""),
    demo_tests,    say(""),
    demo_wrapup,   say(""),

    format("==== 24 结束 ====~n", []).
