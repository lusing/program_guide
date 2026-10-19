:- encoding(utf8).
% 07_measurable_maps.pl —— 第 07 章：有限宇宙上 σ(f) 的符号版（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 集合用有序列表表示，Ω = {1..8}，f = [1,1,2,2,3,3,3,3]（三纤维）。
% 实验一：σ(f) = 纤维并集族（|σ(f)| = 2^3 = 8）+ σ-代数封闭自检。
% 实验二：因子定理——"按纤维常数"恰有 27/6561 个，且与"水平集可测"同真同假。
% 实验三：[f<a] 与 [f≤a] 的有限值域互转（五等价条件的转换内核）。

% ---- 基础集合算子 ----
subseteq([], _).
subseteq([H|T], S) :- member(H, S), subseteq(T, S).

seteq(A, B) :- subseteq(A, B), subseteq(B, A).

fibers([[1,2],[3,4],[5,6,7,8]]).
omega([1,2,3,4,5,6,7,8]).

append_sets([], []).
append_sets([F|Fs], U) :- append_sets(Fs, U0), append(F, U0, U1), sort(U1, U).

% 子列表枚举（保持顺序的选子序列；勿用内建 subset/2——参数序相反会爆栈）
sublist([], []).
sublist([H|T], [H|S]) :- sublist(T, S).
sublist([_|T], S) :- sublist(T, S).

sigma_f(S) :-
    fibers(Fs),
    findall(U, (sublist(Fs, Sub), append_sets(Sub, U)), Us0),
    dedup_sets(Us0, Us1), !, sort_sets(Us1, S).

dedup_sets(Xs, Ys) :- dedup_sets_(Xs, [], Ys).
dedup_sets_([], Acc, Acc).
dedup_sets_([X|Xs], Acc, Ys) :-
    (   member(E, Acc), seteq(E, X) -> dedup_sets_(Xs, Acc, Ys)
    ;   dedup_sets_(Xs, [X|Acc], Ys) ).

sort_sets(Xs, Ys) :- maplist(msort, Xs, Srt), msort(Srt, Ys).

complement(A, C) :- omega(O), subtract(O, A, C0), msort(C0, C).

% ---- 实验一 ----
check_sigma :-
    sigma_f(S),
    length(S, N),
    format("sigma(f) size = ~w (expect 8)~n", [N]),
    N =:= 8,
    forall(( member(A, S), complement(A, Ac), member(B, S),
             union(A, B, U0), msort(U0, U) ),
           ( member(Ac, S), member(U, S) )),
    format("sigma(f) closed under complement/union: OK~n").

% ---- 实验二：因子定理 ----
fiber_const(G) :-
    fibers(Fs),
    forall(( member(F, Fs), member(X, F), member(Y, F) ),
           ( nth1(X, G, VX), nth1(Y, G, VY), VX =:= VY )).

level_sets_meas(G) :-
    sigma_f(S),
    forall(( between(0, 2, V), findall(X, nth1(X, G, V), L0), L0 \= [] ),
           ( msort(L0, L), member(L, S) )).

values3([0,1,2]).
gen_g(G) :- length(G, 8), maplist([X]>>member(X, [0,1,2]), G).

check_factor :-
    findall(G, gen_g(G), Gs),
    length(Gs, Total),
    include(fiber_const, Gs, Const),
    length(Const, NC),
    format("constant-on-fibers count = ~w of ~w (expect 27 of 6561)~n", [NC, Total]),
    NC =:= 27, Total =:= 6561,
    % 两种判据在全部 6561 个函数上同真同假
    forall(member(G, Gs),
           ( fiber_const(G) -> level_sets_meas(G)
           ; \+ level_sets_meas(G) )),
    format("factor theorem: both criteria agree on all 6561 functions: OK~n").

% ---- 实验三：[f<a] 与 [f≤a] 互转 ----
vals_f([0.5, 1.5, 2.5]).
val_of(X, V) :- omega(O), nth1(X, O, I), vals_f(Vs0), nth1(I, Vs0, V).

check_convert :-
    forall(member(A, [1.0, 2.0, 3.0]),
           (   findall(X, (val_of(X, V), V < A), Ls),
               findall(X, ( between(1, 60, N), Sn is 1.0/N,
                            val_of(X, V), V =< A - Sn ), Us0),
               sort(Us0, Us), sort(Ls, Ls1),
               Ls1 == Us )),
    format("strict/non-strict conversion [f<a] = Union_n [f <= a - 1/n]: OK~n").

% ---- main ----
main :-
    format("==== 07 measurable_maps~n", []),
    check_sigma,
    check_factor,
    check_convert,
    format("END ====~n"), !.
