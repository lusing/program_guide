% ============================================================
%  10-dcg-parser.pl —— 用 DCG 写解析器：算术表达式计算器
%
%  运行（SWI）: swipl -q -f examples/10-dcg-parser.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/10-dcg-parser.pl --entry-goal main
%
%  完整流程：字符码 -> 词法（tokenize）-> 语法（DCG）-> AST -> 求值
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、词法分析：字符码列表 -> 记号列表
%     记号形如 num(123)，运算符直接用字符码表示
% ------------------------------------------------------------
tokenize([], []).
tokenize([C | Cs], Ts) :-
    C =< 32, !,                       % 空白直接跳过
    tokenize(Cs, Ts).
tokenize([C | Cs], [num(N) | Ts]) :-
    C >= 0'0, C =< 0'9, !,
    take_digits([C | Cs], Ds, Rest),
    number_codes(N, Ds),
    tokenize(Rest, Ts).
tokenize([C | Cs], [C | Ts]) :-       % 其它符号原样保留
    tokenize(Cs, Ts).

take_digits([C | Cs], [C | Ds], Rest) :-
    C >= 0'0, C =< 0'9, !,
    take_digits(Cs, Ds, Rest).
take_digits(L, [], L).

% ------------------------------------------------------------
%  二、语法分析：分层解决优先级（expr > term > factor）
%     乘除比加减优先，靠「让 term 先吃掉乘除」实现，
%     这是不用优先级表也能写对算术表达式的标准做法
% ------------------------------------------------------------
expr(E)       --> term(T), expr_rest(T, E).
expr_rest(A, E) --> [0'+], term(T), { A1 is A + T }, expr_rest(A1, E).
expr_rest(A, E) --> [0'-], term(T), { A1 is A - T }, expr_rest(A1, E).
expr_rest(A, A) --> [].

term(T)       --> factor(F), term_rest(F, T).
term_rest(A, T) --> [0'*], factor(F), { A1 is A * F }, term_rest(A1, T).
term_rest(A, T) --> [0'/], factor(F), { A1 is A / F }, term_rest(A1, T).
term_rest(A, A) --> [].

factor(N)     --> [num(N)].
factor(E)     --> [0'(], expr(E), [0')].
factor(N)     --> [0'-], factor(V), { N is -V }.   % 一元负号

% ------------------------------------------------------------
%  三、边解析边求值（上面的版本已经是了），再补一个造 AST 的版本
% ------------------------------------------------------------
ast(A)        --> aterm(T), ast_add(T, A).
ast_add(L, R) --> [0'+], aterm(T), ast_add(add(L, T), R).
ast_add(L, R) --> [0'-], aterm(T), ast_add(sub(L, T), R).
ast_add(L, L) --> [].
aterm(A)      --> afactor(F), ast_mul(F, A).
ast_mul(L, R) --> [0'*], afactor(F), ast_mul(mul(L, F), R).
ast_mul(L, R) --> [0'/], afactor(F), ast_mul(div(L, F), R).
ast_mul(L, L) --> [].
afactor(num(N)) --> [num(N)].
afactor(E)      --> [0'(], ast(E), [0')].
afactor(neg(V)) --> [0'-], afactor(V).

eval(num(N), N).
eval(add(L, R), V) :- eval(L, A), eval(R, B), V is A + B.
eval(sub(L, R), V) :- eval(L, A), eval(R, B), V is A - B.
eval(mul(L, R), V) :- eval(L, A), eval(R, B), V is A * B.
eval(div(L, R), V) :- eval(L, A), eval(R, B), V is A / B.
eval(neg(X),   V) :- eval(X, A), V is -A.

% ------------------------------------------------------------
%  四、入口包装
% ------------------------------------------------------------
calc(Text, Value) :-
    atom_codes(Text, Codes),
    tokenize(Codes, Tokens),
    phrase(expr(Value), Tokens).

calc_ast(Text, Tree, Value) :-
    atom_codes(Text, Codes),
    tokenize(Codes, Tokens),
    phrase(ast(Tree), Tokens),
    eval(Tree, Value).

demo_calc :-
    format("---- 计算器 ----~n", []),
    forall(member(Q, ['1+2*3', '(1+2)*3', '-5+10', '100/4/5', '2*(3+4)-5']),
           ( calc(Q, V), format("  ~w = ~w~n", [Q, V]) )).

demo_ast :-
    format("---- 先造 AST 再求值 ----~n", []),
    calc_ast('1+2*3', Tree, V),
    format("  AST = ~q~n", [Tree]),
    format("  求值 = ~w~n", [V]),
    calc_ast('(1+2)*(3-1)', Tree2, V2),
    format("  AST = ~q~n", [Tree2]),
    format("  求值 = ~w~n", [V2]),
    format("  分成两步的好处：AST 可以再做优化、打印、类型检查、编译~n", []).

demo_tokenize :-
    format("---- 词法分析中间结果 ----~n", []),
    atom_codes('12 + 34*(5-1)', Cs),
    tokenize(Cs, Ts),
    format("  '12 + 34*(5-1)' -> ~w~n", [Ts]),
    format("  （0'+ 这样的记号是字符码，用 0' 前缀读起来就是字符本身）~n", []).

demo_errors :-
    format("---- 解析失败与回溯 ----~n", []),
    ( calc('1+', V1) -> format("  '1+' -> ~w~n", [V1])
    ; format("  '1+' -> 解析失败（语法不完整，phrase 返回假）~n", []) ),
    ( calc('1+)2(', V2) -> format("  '1+)2(' -> ~w~n", [V2])
    ; format("  '1+)2(' -> 解析失败~n", []) ),
    format("  DCG 的「失败」就是普通的失败：phrase 返回假，不会抛异常。~n", []),
    format("  要报错就得自己加：先 phrase 一次，失败则抛语法错误。~n", []),
    ( catch(calc_or_error('1+', _V1), E, (format("  calc_or_error('1+') 抛出：~q~n", [E]), fail))
    -> true ; true ),
    calc_or_error('2*3', V2ok),
    format("  calc_or_error('2*3') -> ~w（正常时照常返回）~n", [V2ok]).

calc_or_error(Text, V) :-
    atom_codes(Text, Cs), tokenize(Cs, Ts),
    (   phrase(expr(V), Ts)
    ->  true
    ;   throw(syntax_error(Text))
    ).

demo_generate :-
    format("---- DCG 反向：生成表达式 ----~n", []),
    % 注意：让记号列表完全未绑定去「生成」会卡住 ——
    % expr 里要做算术，变量没绑定时 is/2 会抛 instantiation_error。
    % 想反向生成，得先造出 AST 再让 DCG 把 AST 转成记号串（这里从略）。
    findall(T2, (T2 = [num(1), 0'+, num(2)], phrase(expr(_), T2)), Gs),
    length(Gs, NG),
    format("  用 [num(1),+,num(2)] 反查可解析串：~w 种（~w）~n", [NG, Gs]),
    format("  说明：DCG 是关系，不是函数，正着反着都能用。~n", []).

run :-
    format("==== 10  DCG 解析器：算术表达式 ====~n", []), nl,
    demo_tokenize, nl,
    demo_calc,     nl,
    demo_ast,      nl,
    demo_errors,   nl,
    demo_generate.

main :-
    (   catch((run, nl, format("==== 10 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 10 运行失败~n", []), halt(1)
    ).
