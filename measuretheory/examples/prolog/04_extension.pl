:- encoding(utf8).
% 04_extension.pl —— 第 04 章：块覆盖外测度与 Caratheodory 判据（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,2,3,4}。取块代数 C = {{1,2}, {3,4}}，外测度取"覆盖下确界"：
%   m*(A) = 覆盖 A 所需块的长度和（每块长 2）= 2 × (A 触及的块数)
% 这是真正满足单调 + 次可加的外测度，且只有 4 个 Caratheodory 可测集：
%   ∅、{1,2}、{3,4}、Ω —— 恰是块代数本身！
% 对照 Julia 通道的逐点计数模型（有限宇宙全体可测）：可测结构
% 由外测度的"分辨率"决定——正文把这一点讲成 Carathéodory 的核心洞见。

univ([1,2,3,4]).
block(b1, [1,2], 2).
block(b2, [3,4], 2).

subseteq([], _).
subseteq([H|T], S) :- member(H, S), subseteq(T, S).
seteq(A, B) :- subseteq(A, B), subseteq(B, A).

diff([], _, []).
diff([H|T], S, R) :- member(H, S), !, diff(T, S, R).
diff([H|T], S, [H|R]) :- diff(T, S, R).

intersect([], _, []).
intersect([H|T], S, [H|R]) :- member(H, S), !, intersect(T, S, R).
intersect([_|T], S, R) :- intersect(T, S, R).

union_([], S, S).
union_([H|T], S, R) :- member(H, S), !, union_(T, S, R).
union_([H|T], S, [H|R]) :- union_(T, S, R).

% 确定性子集枚举（位掩码 0..15）
all_subsets(S) :- between(0, 15, Msk), mask_set(Msk, S).
mask_set(Msk, S) :-
    findall(E, (nth0(I, [1,2,3,4], E), Msk /\ (1 << I) =\= 0), S).

% A 触及哪些块
hits(A, Hs) :- findall(B, (block(B, S, _), intersect(A, S, I), I \= []), Hs).

% 块覆盖外测度
outer(A, M) :- hits(A, Hs), length(Hs, N), M is 2 * N.

% Caratheodory 判据
caratheodory(A) :-
    \+ ( all_subsets(T),
         intersect(T, A, TA), diff(T, A, TcA),
         outer(T, M), outer(TA, MA), outer(TcA, MB),
         M =\= MA + MB ).

main :-
    format("==== 04 extension~n", []),
    % 单调性（全体子集对 A ⊆ B）
    \+ ( all_subsets(A), all_subsets(B),
         subseteq(A, B), outer(A, MA), outer(B, MB), MA > MB ),
    format("monotonicity over all comparable pairs: OK~n"),
    % 次可加性（全体子集对）
    \+ ( all_subsets(A), all_subsets(B), union_(A, B, W),
         outer(A, MA2), outer(B, MB2), outer(W, MW),
         MW > MA2 + MB2 ),
    format("subadditivity over all subset pairs: OK~n"),
    % 见证集：A = {1}，T = {1,2}
    intersect([1,2], [1], TA), diff([1,2], [1], TcA),
    outer([1,2], MT), outer(TA, MTA), outer(TcA, MTcA),
    S is MTA + MTcA,
    format("witness A={1}, T={1,2}: m*(T)=~w vs m*(TA)+m*(TcA)=~w+~w=~w~n",
           [MT, MTA, MTcA, S]),
    MT =\= S,
    % 可测集枚举
    findall(A, (all_subsets(A), caratheodory(A)), Meas0),
    dedup_sets(Meas0, Meas),
    length(Meas, N),
    format("caratheodory measurable sets: ~w of 16~n", [N]),
    (   N =:= 4 -> format("measurable class = block algebra {empty,{1,2},{3,4},Omega}: OK~n")
    ;   format("measurable count: FAIL~n"), fail ),
    format("END ====~n"), !.

dedup_sets([], []).
dedup_sets([H|T], [H|R]) :- \+ (member(H2, T), seteq(H, H2)), !, dedup_sets(T, R).
dedup_sets([_|T], R) :- dedup_sets(T, R).
