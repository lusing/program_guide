%% ============================================================================
%%  19_parser.pl —— 写一个真正的解析器
%%
%%  这一章把第 18 章的 DCG 用到实处：实现一个能算加减乘除、支持嵌套括号的
%%  计算器。整体是三段式经典结构，任何语言的解析器都长这样：
%%
%%      字符码  --词法分析-->  token 列表  --语法分析-->  抽象语法树  --求值--> 数
%%      lexer                  tokens        parser          AST        eval
%%
%%  Prolog 的独特之处：三段都可以用 DCG 写，而且【回溯】让「语法分析」天然
%%  支持歧义与试探 —— 不需要手写解析器的状态机。
%%
%%  约定：token 是
%%      num(N)   一个整数
%%      '+' '-' '*' '/' '(' ')'   运算符（原子）
%%      bad(C)   无法识别的字符码（第 15 章说过：非 ASCII 只在显示层用）
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ===========================================================================
%%  第一步：词法分析（字符码列表 → token 列表）
%% ===========================================================================
tokenize(Codes, Tokens) :-
    lex(Codes, Tokens).

lex([], []).
lex([C | Cs], Ts) :-
    (   C =:= 32                       % 空格：跳过
    ->  lex(Cs, Ts)
    ;   C >= 48, C =< 57               % 数字：连续吃
    ->  take_digits([C | Cs], Digits, Rest),
        number_codes(N, Digits),
        Ts = [num(N) | Ts1],
        lex(Rest, Ts1)
    ;   op_token(C, Op)                % 运算符
    ->  Ts = [Op | Ts1],
        lex(Cs, Ts1)
    ;   Ts = [bad(C) | Ts1],           % 不认识的字符
        lex(Cs, Ts1)
    ).

take_digits([C | Cs], [C | Ds], Rest) :-
    C >= 48,
    C =< 57,
    !,
    take_digits(Cs, Ds, Rest).
take_digits(Rest, [], Rest).

op_token(43, '+').
op_token(45, '-').
op_token(42, '*').
op_token(47, '/').
op_token(40, '(').
op_token(41, ')').

%% ===========================================================================
%%  第二步：语法分析（token 列表 → AST）
%%  优先级：expr（+ -）< term（* /）< factor（数字 或 括号）
%%  用「累加器版」保证左结合：10-3-2 必须读成 (10-3)-2
%% ===========================================================================
parse_expr(AST) -->
    parse_term(T),
    parse_expr_rest(T, AST).

parse_expr_rest(Acc, AST) --> ['+'], parse_term(T), {A1 = add(Acc, T)}, parse_expr_rest(A1, AST).
parse_expr_rest(Acc, AST) --> ['-'], parse_term(T), {A1 = sub(Acc, T)}, parse_expr_rest(A1, AST).
parse_expr_rest(AST, AST) --> [].

parse_term(AST) -->
    parse_factor(F),
    parse_term_rest(F, AST).

parse_term_rest(Acc, AST) --> ['*'], parse_factor(F), {A1 = mul(Acc, F)}, parse_term_rest(A1, AST).
parse_term_rest(Acc, AST) --> ['/'], parse_factor(F), {A1 = div(Acc, F)}, parse_term_rest(A1, AST).
parse_term_rest(AST, AST) --> [].

parse_factor(num(N)) --> [num(N)].
parse_factor(AST) --> ['('], parse_expr(AST), [')'].

%% ===========================================================================
%%  第三步：求值
%% ===========================================================================
eval(num(N), N) :- !.
eval(add(A, B), V) :- !, eval(A, VA), eval(B, VB), V is VA + VB.
eval(sub(A, B), V) :- !, eval(A, VA), eval(B, VB), V is VA - VB.
eval(mul(A, B), V) :- !, eval(A, VA), eval(B, VB), V is VA * VB.
eval(div(A, B), V) :- !, eval(A, VA), eval(B, VB), V is VA / VB.

%% ===========================================================================
%%  第四步：把 AST 打印回文本（用 DCG 做「生成」方向）
%%  同一套 DCG 既能「识别」也能「生成」，这是它的另一半威力。
%% ===========================================================================
%% 要把一个整数当「一批终结符」吐出去，得把码列表展开成逐个终结符。
%% 直接写 {number_codes(N, Cs)}, Cs 是错的：DCG 会把 Cs 当成非终结符去 call。
ast_text(num(N)) --> {number_codes(N, Cs)}, codes_term(Cs).
ast_text(add(A, B)) --> "(", ast_text(A), " + ", ast_text(B), ")".
ast_text(sub(A, B)) --> "(", ast_text(A), " - ", ast_text(B), ")".
ast_text(mul(A, B)) --> "(", ast_text(A), " * ", ast_text(B), ")".
ast_text(div(A, B)) --> "(", ast_text(A), " / ", ast_text(B), ")".

codes_term([]) --> [].
codes_term([C | Cs]) --> [C], codes_term(Cs).

%% ===========================================================================
%%  端到端：一行文本 → 值
%% ===========================================================================
%% 只取第一个成功的解析（计算器不需要歧义）
calc(Chars, Value) :-
    tokenize(Chars, Tokens),
    once(phrase(parse_expr(AST), Tokens)),
    eval(AST, Value).

%% 端到端 + 顺便拿到 AST 与 token
calc_full(Chars, Tokens, AST, Value) :-
    tokenize(Chars, Tokens),
    once(phrase(parse_expr(AST), Tokens)),
    eval(AST, Value).

%% ---------------------------------------------------------------------------
%%  演示
%% ---------------------------------------------------------------------------
demo_lex :-
    say("---- 1. 第一步：词法分析 ----"),
    tokenize("1 + 2 * 3", Ts),
    format("  \"1 + 2 * 3\"     -> ~w~n", [Ts]),
    tokenize("12*(3+4)", Ts2),
    format("  \"12*(3+4)\"      -> ~w~n", [Ts2]),
    tokenize("8 / 4", Ts3),
    format("  \"8 / 4\"         -> ~w~n", [Ts3]),
    tokenize("x + 1", Ts4),
    format("  \"x + 1\"         -> ~w（x 变成 bad(120)）~n", [Ts4]),
    say("  空格被吃掉了，多位数被合成一个 num(12) —— 这就是词法分析的全部工作。"),
    say("  认不出来的字符不做异常，而是包成 bad(C) 交给上层决定怎么报错。"),
    say("  工程上这叫「词法错误局部化」：解析器可以继续往下走，报出更多问题。"),
    % 用 bad/1 做一次友好的检查
    (   member(bad(C), Ts4)
    ->  format("  检查一下：Ts4 里确实有 bad(~w)~n", [C])
    ;   say("  检查一下：Ts4 里没有 bad/1")
    ).

demo_parse :-
    say("---- 2. 第二步：语法分析出 AST ----"),
    calc_full("1 + 2 * 3", _Ts, AST1, V1),
    phrase(ast_text(AST1), Text1),
    format("  \"1 + 2 * 3\"   AST = ", []),
    write_canonical(AST1),
    nl,
    format("                 打印回文本 = ~s  值 = ~w~n", [Text1, V1]),

    calc_full("(1 + 2) * 3", _Ts2, AST2, V2),
    phrase(ast_text(AST2), Text2),
    format("  \"(1 + 2) * 3\" AST = ", []),
    write_canonical(AST2),
    nl,
    format("                 打印回文本 = ~s  值 = ~w~n", [Text2, V2]),

    say("  注意 AST 里乘法的左参数已经是加法 —— 优先级在语法树形状里定死了。"),
    say("  之后求值只看树，完全不需要再考虑优先级，这就是「分离关注点」。").

demo_assoc :-
    say("---- 3. 左结合：为什么累加器版是必须的 ----"),
    calc_full("10 - 3 - 2", _Ts, AST, V),
    phrase(ast_text(AST), Text),
    format("  \"10 - 3 - 2\"   AST = ", []),
    write_canonical(AST),
    nl,
    format("                 打印回文本 = ~s  值 = ~w~n", [Text, V]),
    say("  正确读法是 (10-3)-2 = 5。如果语法写成右结合 sub(10,sub(3,2))，"),
    say("  结果会是 10-1 = 9 —— 所以左结合必须靠「累加器 + 尾递归」实现。"),
    calc_full("100 - 10 - 5 - 2", _Ts2, AST2, V2),
    phrase(ast_text(AST2), Text2),
    format("  再来一个：~s  ->  ~w~n", [Text2, V2]).

demo_eval :-
    say("---- 4. 第三步：求值 + 一整批用例 ----"),
    forall(member(E, ["1 + 2",
                      "2 * 3 + 4 * 5",
                      "((1 + 2) * (3 + 4))",
                      "10 / 4",
                      "7 - 2 * 3",
                      "2 * (3 + 4) - 5"]),
           (   calc(E, V)
           ->  format("  ~s   =  ~w~n", [E, V])
           ;   format("  ~s   =  解析失败~n", [E])
           )),
    say("  只有 10 / 4 是浮点 2.5，其余都是整数 —— 这也是演示刻意的选择："),
    say("  整除（如 8/4）两套引擎给的类型不同（整数 vs 浮点），不能用于比对。"),
    % 错误的输入
    (   calc("1 +", _V2)
    ->  say("  \"1 +\" 居然解析成功了？")
    ;   say("  \"1 +\"         -> 解析失败（表达式不完整）")
    ),
    (   calc("(1 + 2", _V3)
    ->  say("  \"(1 + 2\" 居然解析成功了？")
    ;   say("  \"(1 + 2\"       -> 解析失败（缺右括号）")
    ),
    say("  失败就是失败 —— 没有异常、没有 null。想给用户友好提示，"),
    say("  就再写一个「错误报告」谓词，把位置信息一起带出来（本章练习）。").

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
    format("==== 19 开始 ====~n", []),
    say("一个完整的解析器：词法 → 语法 → AST → 求值 → 再打印回文本。"),
    say(""),

    demo_lex,   say(""),
    demo_parse, say(""),
    demo_assoc, say(""),
    demo_eval,  say(""),

    format("==== 19 结束 ====~n", []).
