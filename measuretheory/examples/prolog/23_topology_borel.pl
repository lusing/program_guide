:- encoding(utf8).
% 23_topology_borel.pl —— 第 23 章：有限拓扑的 Borel 符号账（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，输出纯 ASCII。
% τ = {∅,{1},{1,2},Ω}（四点非 T1 拓扑）。
% ① Borel 闭包（补/并饱和 → 8 元）；
% ② 连续函数全查（离散值域预像检验 → 仅 4 常值）；
% ③ Ba（连续零集闭包）= {∅,Ω} ⊊ B——有限非 T1 的 Ba/B 真差距现场。

% --- 开集事实（位串：bit i-1 置位 = 点 i 入集）---
open_set(0b0000).  open_set(0b0001).  open_set(0b0011).  open_set(0b1111).

% --- ① 闭包谓词 ---
in_fam_step(Fam, NewFam) :-
    findall(C, (member(A, Fam), C is 0b1111 /\ \A), Cs),
    findall(U, (member(A, Fam), member(B, Fam), U is A \/ B), Us),
    append([Fam, Cs, Us], All),
    sort(All, NewFam).

closure(Fam, Closed) :-
    in_fam_step(Fam, Next),
    (   Next == Fam -> Closed = Fam
    ;   closure(Next, Closed)).

borel(B) :-
    findall(S, open_set(S), Ss),
    closure(Ss, B).

check_borel :-
    borel(B),
    length(B, N),
    N =:= 8,
    format("Borel closure = 8 sets: OK~n").

% --- ② 连续函数：f : {1..4} → {0..3}，一切预像开 ---
f_val(f(F1,F2,F3,F4), 1, F1).  f_val(f(F1,F2,F3,F4), 2, F2).
f_val(f(F1,F2,F3,F4), 3, F3).  f_val(f(F1,F2,F3,F4), 4, F4).

preimage(F, V, M) :-
    findall(I, (between(1,4,X), f_val(F, X, Y),
                (V /\ (1 << Y)) =\= 0, I is 1 << (X-1)), Idxs),
    foldl([I,Acc,NA]>>(NA is Acc \/ I), Idxs, 0, M).

cont(F) :-
    forall(between(0, 15, V),
           (preimage(F, V, M), open_set(M))).

check_cont :-
    findall(F, (between(0,3,A), between(0,3,B), between(0,3,C),
                between(0,3,D), F = f(A,B,C,D), cont(F)), Fs),
    length(Fs, N),
    N =:= 4,                        % 仅常值：拓扑太粗，纤维必须开
    format("continuous functions = 4 constants (tau too coarse): OK~n").

% --- ③ Ba：连续函数零集的闭包 ---
zero_set(F, M) :-
    findall(I, (between(1,4,X), f_val(F, X, 0), I is 1 << (X-1)), Idxs),
    foldl([I,Acc,NA]>>(NA is Acc \/ I), Idxs, 0, M).

check_ba :-
    findall(M, (between(0,3,A), between(0,3,B), between(0,3,C),
                between(0,3,D), F = f(A,B,C,D), cont(F), zero_set(F, M)), Ms),
    sort(Ms, Zs0),
    closure(Zs0, Ba),
    Ba == [0, 15],                  % {∅, Ω}：Ba 平凡
    format("Ba = {empty, Omega} < B (8): finite non-T1 witness: OK~n").

% --- main ---
main :-
    format("==== 23 topology_borel~n", []),
    check_borel,
    check_cont,
    check_ba,
    format("END ====~n"), !.

:- initialization(main).
