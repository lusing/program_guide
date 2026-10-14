:- encoding(utf8).
% 第 50 章 泛型滤子搜索 + Δ-系判定（46 章 2^<4 实验室续作）

% ---------- 2^<4 前缀序（46 章同款） ----------
bits(0).
bits(1).
strings(MaxLen, S) :- between(0, MaxLen, N), length(S, N), maplist(bits, S).

prefix([], _).
prefix([B|Xs], [B|Ys]) :- prefix(Xs, Ys).

compat(X, Y) :- prefix(X, Y).
compat(X, Y) :- prefix(Y, X).

% ---------- Δ-系判定 ----------
% 根从首对绑定（forall 不外传绑定——否定语义实测坑），余对否定校验
delta_root(S, R) :-
    member(A, S), member(B, S), A \= B,
    findall(X, (member(X, A), member(X, B)), I0), sort(I0, R),
    \+ ( member(C, S), member(D, S), C \= D,
         findall(Y, (member(Y, C), member(Y, D)), J0),
         sort(J0, J1), J1 \= R ).

% ---------- 泛型滤子搜索 ----------
% 给定稠密集列表 Ds（每个是条件表），找与每个相交的滤子（路径链形态）
path(F, G) :-         % F 的初始段全体（路径滤子）
    findall(S, (prefix(S, F), length(S, L), L =< 3), G).

meets_all(G, Ds) :-
    forall(member(D, Ds), (member(X, G), member(X, D))).

generic_search(F, Ds, G) :- path(F, G), meets_all(G, Ds), !.

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 50 泛型滤子搜索 + Δ-系~n"),

    % 一、Δ-系正反例
    delta_root([[1,2],[1,3],[1,4]], R1), R1 = [1],
    format("Δ-正例：{{1,2},{1,3},{1,4}} 根 = {1} ✓~n"),
    ( delta_root([[1,2],[2,3],[1,3]], _) -> format("Δ-负例误判！~n")
    ; format("Δ-负例：{{1,2},{2,3},{1,3}} 无公共根（判定失败=正确）✓~n") ),

    % 二、泛型滤子：D1 = 长度≥1，D2 = 长度 2 层，D3 = 长度 3 层
    findall(S, (strings(3, S), S \= []), D1),
    findall(S, (length(S, 2), maplist(bits, S)), D2),
    findall(S, (length(S, 3), maplist(bits, S)), D3),
    findall(F, (strings(3, F), generic_search(F, [D1, D2, D3], _)), Fs),
    length(Fs, NF),
    format("路径滤子与 D1/D2/D3 全相交的路径：~w 条（每条长度-3 路径都行）~n", [NF]),
    NF = 8,

    % 三、反面：路径 [0,0,0] 空过"以 1 开头"的稠密层
    findall(S, (strings(3, S), S = [1|_]), Dstart1),
    path([0,0,0], G000),
    \+ meets_all(G000, [Dstart1]),
    format("路径 [0,0,0] 空过 D=[以 1 开头]——滤子选择即泛型性选择 ✓~n"),

    format("END ===="), nl.
