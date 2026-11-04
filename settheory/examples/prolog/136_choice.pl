:- encoding(utf8).
% 第 136 章 Prolog：选择公理的有限终审。
% ① 选择函数：member 回溯就是"选择"——AC3 的逐块选一；
% ② 不交化技巧（书 4.6.1 (2)→(3)：打标签 i×X_i）——打标签族
%    两两不交，撕标签后得到原族的选择函数；
% ③ 极大元与极大链（Zorn/Hausdorff 的有限版）。

% ---------- ① 选择函数 ----------
pick_all([], []).
pick_all([X|Xs], [P|Ps]) :- member(P, X), pick_all(Xs, Ps).

check_choice :-
    Fam = [[a, b], [c, d], [e, f]],                   % 两两不交族
    pick_all(Fam, F),
    maplist([P, X] >> member(P, X), F, Fam),          % 每个选择都在块内
    forall(nth1(I, Fam, X),
           (nth1(I, F, P), member(P, X))),
    format("choice function: one pick from each block: OK~n").

% ---------- ② 不交化 ----------
check_tagging :-
    Fam = [[a, b], [b, c]],                           % 相交族
    findall(B, (nth1(I, Fam, X), findall(I-E, member(E, X), B)), Bs),
    forall((nth1(I, Bs, B1), nth1(J, Bs, B2), I < J),
           intersection(B1, B2, [])),                 % 打标签后两两不交
    pick_all(Bs, Picked),                             % 在打标签族上选择
    forall((nth1(I, Picked, I-E), nth1(I, Fam, X)),
           member(E, X)),                             % 撕标签后在原块内
    format("tagged disjointification: (i,x) blocks disjoint, picks valid: OK~n").

% ---------- ③ 极大元与极大链 ----------
subset_of2([], _).
subset_of2([H|T], S) :- member(H, S), subset_of2(T, S).

chain(Cs) :-
    forall((member(A, Cs), member(B, Cs)),
           (subset_of2(A, B) ; subset_of2(B, A))).

maximal2(U, M) :-
    member(M, U),
    \+ (member(O, U), subset_of2(M, O), \+ subset_of2(O, M)).

subselect2([], []).
subselect2([H|T], [H|S]) :- subselect2(T, S).
subselect2([_|T], S) :- subselect2(T, S).

check_zorn :-
    U = [[], [a], [b], [a, b], [a, b, c]],            % 五元立方格的下半
    findall(M, maximal2(U, M), Ms),
    Ms == [[a, b, c]],                                % 唯一极大元 = 顶
    findall(Cs, (subselect2(U, Cs), Cs \= [], chain(Cs)), Cs0),
    findall(C, (member(C, Cs0),
                \+ (member(D, Cs0), subset_of2(C, D), C \= D)), MaxChains),
    length(MaxChains, 2),                             % 两条极大链（经 {a} 或 {b}）
    format("zorn/hausdorff finite: top element and 2 maximal chains: OK~n").

main :-
    format("==== 136 choice~n"),
    check_choice,
    check_tagging,
    check_zorn,
    format("END ====~n"), !.

:- initialization(main).
