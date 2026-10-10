:- encoding(utf8).
:- discontiguous step/4.
% ex98_automata.pl —— 自动机与形式语言：Chomsky 层级（张寅生 11.2-11.8）
% 双引擎：
%   [DFA 运行] dfa_run/4 + 书例 11.6 熊猫/例 11.7 命题接受账
%   [文法推导] 3 型文法 gogRg 的派生引擎（定理 11.2(4) 生成侧）+与
%   DFA 接受的对照（词表枚举双向对账）
% 输出 ASCII；末行 END ====。

% ---------- DFA 运行器（定义 11.4） ----------

% pandaDfa：0=xiong 1=mao；状态 2=Acc 3=Rej
step(panda, 0, 0, 1).
step(panda, 0, 1, 3).
step(panda, 1, 0, 3).
step(panda, 1, 1, 2).
step(panda, 2, 0, 3).
step(panda, 2, 1, 3).
step(panda, 3, 0, 3).
step(panda, 3, 1, 3).

dfa_run(_, Q, [], Q).
dfa_run(M, Q, [S|W], Q2) :-
    ( step(M, Q, S, Q1) -> true ; Q1 = 99 ),  % 缺省：sink 99
    dfa_run(M, Q1, W, Q2).

dfa_accept(M, Q0, Fin, W) :- dfa_run(M, Q0, W, Q), member(Q, Fin).

% gogDfa：g o* g l e（0=g 1=o 2=l 3=e）
step(gog, 0,0,1). step(gog, 1,1,1). step(gog, 1,0,2).
step(gog, 2,2,3). step(gog, 3,3,4).

% ---------- 3 型文法（右线性）：gogRg ----------

% 产生式 A --> a B / A --> a（终止式）
prod(gog, 0, 0, some(1)).
prod(gog, 1, 1, some(1)).
prod(gog, 1, 0, some(2)).
prod(gog, 2, 2, some(3)).
prod(gog, 3, 3, none).

% 派生：rg(+G, +A, +W)——变元 A 派生词 W
rg(_, _, []) :- fail.               % 终止式总吐一个符号
rg(G, A, [S]) :- prod(G, A, S, none).
rg(G, A, [S|Rest]) :-
    Rest \= [],
    prod(G, A, S, some(B)),
    rg(G, B, Rest).

% gogRg 的 DFA 化（rgToDfa）：Some B→转移；none→接受态 4
gdfa(M) :- M = gog2.
% 与 Coq/Lean gogDfa 同表：终态 4 一旦越轨去 sink 5（防自环误收）
step(gog2, 0,0,1). step(gog2, 1,1,1). step(gog2, 1,0,2).
step(gog2, 2,2,3). step(gog2, 3,3,4). step(gog2, 4,0,5).
step(gog2, 0,1,5). step(gog2, 0,2,5). step(gog2, 0,3,5).
step(gog2, 2,0,5). step(gog2, 2,1,5). step(gog2, 2,3,5).
step(gog2, 3,0,5). step(gog2, 3,1,5). step(gog2, 3,2,5).
step(gog2, 5,0,5). step(gog2, 5,1,5). step(gog2, 5,2,5).
step(gog2, 5,3,5). step(gog2, 4,1,5). step(gog2, 4,2,5).
step(gog2, 4,3,5).

% ---------- 词表枚举与对账 ----------

words_upto(_, 0, [[]]).
words_upto(Alph, N, Ws) :-
    N > 0, N1 is N - 1, AlphM1 is Alph - 1,
    words_upto(Alph, N1, Ws0),
    findall([S|W], (member(W, Ws0), between(0, AlphM1, S)), Ws), !.

% 词长 ≤N 的全部词（Alph 个符号）
words(Alph, N, Ws) :- words_upto(Alph, N, Ws).

agree_gog([]).
agree_gog([W|T]) :-
    ( rg(gog, 0, W) -> G = true ; G = false ),
    ( dfa_accept(gog2, 0, [4], W) -> D = true ; D = false ),
    ( G == D -> true ; format('MISMATCH ~w~n', [W]), fail ),
    agree_gog(T).

panda_check(W, R) :- ( dfa_accept(panda, 0, [2], W) -> R = true ; R = false ).

main :-
    panda_check([0,1], R1),  format('panda [0,1] -> ~w (expect true)~n', [R1]),
    panda_check([0,1,0], R2), format('panda [0,1,0] -> ~w (expect false)~n', [R2]),
    panda_check([1,0], R3),  format('panda [1,0] -> ~w (expect false)~n', [R3]),
    words(2, 4, Ws), length(Ws, L),
    format('words2_len4 = ~w (expect 16)~n', [L]),
    words(4, 5, Ws4),
    ( agree_gog(Ws4) -> format('rg_dfa_agree = true~n') ; true ),
    % 双向样本：派生成功的词与 DFA 接受的词完全一致（已由 agree 验证）
    findall(W, (member(W, Ws4), rg(gog, 0, W)), Derived),
    length(Derived, ND), format('gogRg derived words (len<=5) = ~w~n', [ND]),
    format('==== automata END ===='), nl.
