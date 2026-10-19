:- encoding(utf8).
% 01_setclasses.pl —— 第 01 章：有限宇宙上的集类封闭性（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII（funanalysis 同款纪律）。
% 集合用有序列表表示，Ω = {1..6}。
% 实验内容：区间半环的 π-系性质、差分解、半环非环反例、不交并闭包穷尽幂集。

% 成员关系直接用标准 member/2（可回溯枚举——自制 mem 的 cut 会
% 把 member 的首个解钉死，后续解被剪掉，闭包/搜索全部失明）

subseteq([], _).
subseteq([H|T], S) :- member(H, S), subseteq(T, S).

seteq(A, B) :- subseteq(A, B), subseteq(B, A).

intersect([], _, []).
intersect([H|T], S, [H|R]) :- member(H, S), !, intersect(T, S, R).
intersect([_|T], S, R) :- intersect(T, S, R).

union_([], S, S).
union_([H|T], S, R) :- member(H, S), !, union_(T, S, R).
union_([H|T], S, [H|R]) :- union_(T, S, R).

diff([], _, []).
diff([H|T], S, R) :- member(H, S), !, diff(T, S, R).
diff([H|T], S, [H|R]) :- diff(T, S, R).

disjoint(A, B) :- \+ (member(X, A), member(X, B)).

% 区间 (a, b]（元素 a+1..b）
interval(A, B, S) :- B > A, !, findall(X, (between(A, B, X), X > A), S).
interval(_, _, []).

% 生成区间半环 C（Ω = {1..6}）
gen_class(C) :-
    findall(S, (between(0, 5, A), between(A, 6, B), interval(A, B, S)), L),
    dedup(L, C).

dedup([], []).
dedup([H|T], [H|R]) :- \+ (member(H2, T), seteq(H, H2)), !, dedup(T, R).
dedup([_|T], R) :- dedup(T, R).

% π-系检查：所有成员两两之交仍在类中
pi_system(C) :-
    \+ (member(S, C), member(T, C), intersect(S, T, I),
        \+ (member(U, C), seteq(U, I))).

% 不交并可由两片成员拼出
union_two_pieces(C, D) :-
    member(U, C), member(V, C), disjoint(U, V), union_(U, V, W), seteq(W, D).

% 不交并闭包迭代
closure_disjoint(C, S) :-
    iterate_step(C, S2, true), !, closure_disjoint(S2, S).
closure_disjoint(C, C).

iterate_step(C, Out, true) :-
    findall(W, (member(U, C), member(V, C), disjoint(U, V), union_(U, V, W)), Pieces),
    dedup_pieces(Pieces, C, Out, true).
iterate_step(C, C, false).

dedup_pieces([], C, C, false).
dedup_pieces([W|T], C, Out, true) :-
    \+ (member(U, C), seteq(U, W)), !,
    dedup_pieces(T, [W|C], Out, _).
dedup_pieces([_|T], C, Out, Ch) :- dedup_pieces(T, C, Out, Ch).

% ---- main ----
main :-
    format("==== 01 setclasses~n", []),
    gen_class(C),
    length(C, NC),
    format("interval semiring size: ~w~n", [NC]),
    (   pi_system(C) -> format("pi-system (closed under intersection): OK~n")
    ;   format("pi-system: FAIL~n"), fail ),
    interval(1, 4, S), interval(2, 3, T), diff(S, T, D),
    (   union_two_pieces(C, D) -> format("difference {2,3,4}\\{3} decomposes into disjoint intervals: OK~n")
    ;   format("difference decomposition: FAIL~n"), fail ),
    interval(1, 3, A), interval(4, 6, B), union_(A, B, U),
    (   \+ (member(W, C), seteq(W, U)) -> format("counterexample {2,3}u{5,6} not an interval (semiring is not a ring): OK~n")
    ;   format("counterexample check: FAIL~n"), fail ),
    closure_disjoint(C, S1),
    length(S1, N1),
    format("disjoint-union closure: ~w -> ~w (expect 64)~n", [NC, N1]),
    (   N1 =:= 64 -> format("closure exhausts power set: OK~n")
    ;   format("closure exhausts power set: FAIL~n"), fail ),
    format("END ====~n"), !.
