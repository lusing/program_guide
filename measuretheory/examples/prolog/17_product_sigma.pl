:- encoding(utf8).
% 17_product_sigma.pl —— 第 17 章：乘积 σ-代数的符号闭包（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% X = Y = {0,1}：集合用位串整数（0..15）表示，bit(2a+b) 置位 = (a,b) 入集。
% ① 矩形全体 rect(A,B)（A,B ∈ 0..3 编码的 {0,1} 子集）去重得 10 个；
% ② 闭包谓词 in_prod_sigma/1：从矩形出发补/并封闭 → 幂集 16 个；
% ③ 截口谓词 section_x/3 与 section_y/3：穷举验证一切截口可测。

% --- 子集编码：x ⊆ {0,1} 用 0..3（bit a 置位 = a 入集）---
bit_set(S, B) :- S /\ (1 << B) =\= 0.

% 矩形 mask：A,B ⊆ {0,1}（0..3）→ 4 原子空间位串（0..15）
rect_mask(A, B, M) :-
    findall(I, (between(0,1,Ax), bit_set(A,Ax), between(0,1,Bx),
                bit_set(B,Bx), I is 2*Ax+Bx), Idxs),
    foldl([I,Acc,NA]>>(NA is Acc \/ (1 << I)), Idxs, 0, M).

% --- ① 枚举矩形并去重 ---
all_rectangles(Rs) :-
    findall(M, (between(0,3,A), between(0,3,B), rect_mask(A,B,M)), Ms),
    sort(Ms, Rs).

% --- ② 闭包：补与二元并的一步扩展 ---
step_extend(Fam, NewFam) :-
    setof(M, member(M, Fam), F1),
    findall(C, (member(A, F1), C is 15 /\ \A), Cs),
    findall(U, (member(A,F1), member(B,F1), U is A \/ B), Us),
    append([F1,Cs,Us], All),
    sort(All, NewFam).

closure(Fam, Closed) :-
    step_extend(Fam, Next),
    (   Next == Fam -> Closed = Fam
    ;   closure(Next, Closed)).

% --- ③ 截口：E_x = {b : (x,b) ∈ E}（返回 0..3）---
section_x(E, X, S) :-
    findall(B, (between(0,1,A), A =:= X, between(0,1,B),
                E /\ (1 << (2*A+B)) =\= 0), Bs),
    foldl([B,Acc,NS]>>(NS is Acc \/ (1 << B)), Bs, 0, S).

section_y(E, Y, S) :-
    findall(A, (between(0,1,B), B =:= Y, between(0,1,A),
                E /\ (1 << (2*A+B)) =\= 0), As),
    foldl([A,Acc,NS]>>(NS is Acc \/ (1 << A)), As, 0, S).

% --- 检查器 ---
check_rectangles :-
    all_rectangles(Rs),
    length(Rs, N),
    N =:= 10,                       % 16 对去重（∅×B 合并）
    format("rectangles dedup = 10: OK~n").

check_closure :-
    all_rectangles(Rs),
    closure(Rs, Closed),
    length(Closed, 16),
    numlist(0,15,Full),
    Closed == Full,                 % 矩形生成一切：A ⊗ B = 幂集
    format("closure from rectangles = powerset (16): OK~n").

check_sections :-
    forall(between(0,15,E),
           (forall(between(0,1,X), (section_x(E,X,S), S < 4)),
            forall(between(0,1,Y), (section_y(E,Y,T), T < 4)))),
    format("all sections (E,x)/(E,y) measurable (16 sets x 2 x 2): OK~n").

% --- main ---
main :-
    format("==== 17 product_sigma~n", []),
    check_rectangles,
    check_closure,
    check_sections,
    format("END ====~n"), !.

:- initialization(main).
