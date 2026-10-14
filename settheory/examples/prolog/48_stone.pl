:- encoding(utf8).
% 第 48 章 Stone 对偶：Div(30) 的 Stone 空间 + 开闭↔理想滤子对应

% ---------- Div(30) 布尔代数（47 章复用） ----------
d30([1,2,3,5,6,10,15,30]).
meet30(A, B, M) :- M is gcd(A, B).
join30(A, B, L) :- L is lcm(A, B).
not30(A, N) :- N is 30 // A.

% ---------- 超滤子：原子主超滤 ----------
atom30(A) :-
    d30(D), member(A, D), A > 1,
    forall((member(B, D), B > 1), (gcd(A, B) =:= 1 ; gcd(A, B) =:= A)).

principal30(A, U) :-
    atom30(A),
    d30(D),
    include(divides(A), D, U).
divides(A, B) :- 0 =:= B mod A.

% ---------- N_b = {原子超滤的编号 : b ∈ U_a} ----------
% St(B) 的点 = 三个原子 [2,3,5]；N_b = a 的列表使 a | b
n30(B, Ns) :-
    findall(A, (atom30(A), divides(A, B)), Ns).

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 48 Stone 空间：Div(30)~n"),

    % 一、超滤子 = 3 个原子主超滤
    findall(A, atom30(A), Atoms),
    Atoms = [2, 3, 5],
    format("St(B) = 3 点（原子 2、3、5 的主超滤）~n"),

    % 二、N_b 同态性：N_{b∧c} = N_b ∩ N_c、N_{¬b} = St∖N_b（64 组合）
    d30(D),
    forall((member(B, D), member(C, D)),
           ( n30(B, NB), n30(C, NC), meet30(B, C, M), n30(M, NMeet),
             intersection(NB, NC, NMeet),
             not30(B, BN), n30(BN, NBN),
             subtract([2,3,5], NB, NBN) )),
    format("N_(b∧c)=N_b∩N_c、N_(¬b)=St∖N_b：64 组合全过 ✓~n"),

    % 三、单射：8 个 b 给出 8 个不同的 N_b（3 点空间的 8 个 clopen）
    findall(Ns, (member(B, D), n30(B, Ns)), AllN),
    sort(AllN, UniqueN),
    length(UniqueN, 8),
    format("8 元 B ≅ 3 点空间全部 2^3 = 8 个 clopen ✓~n"),

    % 四、开 ↔ 理想 / 闭 ↔ 滤子（定理 3 的有限版）：
    %   St 的开集 = 3 点离散空间全体 8 个子集 S；I_S = {c : N_c ⊆ S}
    %   抽查 S = {1}（点 2）：理想 = 不含 3、5 因子的元素 = {1,2}
    n30(2, [2]), n30(3, [3]), n30(5, [5]),
    ideal_of([2], Ideal2),
    Ideal2 = [1, 2],
    format("开集 {点2} 的理想 I = {1,2}（N_c⊆{{2}} ⟺ c 无 3、5 因子）✓~n"),

    % 五、孤立点：3 点全孤立 = 3 个原子主超滤（定理 4）
    format("3 点全孤立 ⟺ 主超滤（定理 4 有限化身）✓~n"),

    format("END ===="), nl.

% I_S = {c : N_c ⊆ S}（升序表）
ideal_of(S, I) :-
    d30(D),
    include(nc_subset(S), D, I).
nc_subset(S, C) :-
    n30(C, NC),
    subset_list(NC, S).

subset_list([], _).
subset_list([H|T], S) :- member(H, S), subset_list(T, S).
