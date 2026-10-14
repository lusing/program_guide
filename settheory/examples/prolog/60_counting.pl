:- encoding(utf8).
% 第 60 章：计数的机器化（Makinson Ch5）
% 四式选取 + 排列组合 + banana 重排 + 容斥。

% ---------- 生成器 ----------
pair5(A, B) :- between(0, 4, A), between(0, 4, B).

fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

permN(N, K, P) :- fact(N, FN), NK is N - K, fact(NK, FNK), P is FN // FNK.
combN(N, K, C) :- fact(N, FN), NK is N - K, fact(NK, FNK),
                  fact(K, FK), C is FN // (FK * FNK).

% 组合生成器（k 元子集）
comb(0, _, []).
comb(K, [X|Xs], [X|R]) :- K > 0, K1 is K - 1, comb(K1, Xs, R).
comb(K, [_|Xs], R) :- K > 0, comb(K, Xs, R).

% 排列生成器
perm([], []).
perm(L, [X|R]) :- select(X, L, Rest), perm(Rest, R).

% 重排计数：排列去重
anagram_count(Word, N) :-
    atom_chars(Word, Cs),
    findall(P, perm(Cs, P), Ps),
    sort(Ps, Us), length(Us, N).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 60~n"),

    % 一、四式选取（5 选 2）
    findall(_, (pair5(A, B), A =\= B), Or),
    length(Or, 20),
    findall(_, (pair5(A, B), A =< B), Cr),
    length(Cr, 15),
    findall(_, pair5(_,_), All),
    length(All, 25),
    format("  5 选 2：O+R+ = ~d，O+R- = ~d，O-R+ = ~d，O-R- = ~d（=10）~n",
           [25, 20, 15, 10]),

    % 二、组合生成器计数 vs 公式
    numlist(0, 4, D5),
    findall(S, comb(2, D5, S), Ss),
    length(Ss, 10),
    combN(5, 2, 10),
    format("  C(5,2)：生成器 10 = 公式 10 ✓~n"),
    combN(6, 3, 20),
    format("  C(6,3) = 20（杨辉行）~n"),

    % 三、banana 重排
    anagram_count(banana, 60),
    format("  banana 重排（排列去重枚举）= 60 = 6!/3!2! ✓~n"),

    % 四、大数公式（书本例）
    permN(10, 6, 151200),
    combN(10, 6, 210),
    format("  P(10,6) = 151200；C(10,6) = 210（子委员会例）~n"),
    permN(15, 5, TT), Yrs is TT // 52,
    format("  15 领带 5 天：~d 周 ≈ ~d 年~n", [TT, Yrs]),

    % 五、容斥
    IE is 5 + 10 + 7 - 3 - 2 - 2 + 1,
    format("  三人电话容斥：~d~n", [IE]),

    format("END ===="), nl.
