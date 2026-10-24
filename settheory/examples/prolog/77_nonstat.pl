:- encoding(utf8).
% 第 77 章：滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）——Prolog 通道
% 三个现场：对角线交 ΔC 的生成器-检验器搜索（diag_members/3）；压小函数
% 的最大常值纤维（fodor_fiber/4），含例 2.13 单射压小 f(i)=i−1 的
% 全单点纤维（非荟萃集上佛多失效的现场）；f(e)=(Σe) mod 7 的可数子代数
% 不动点迭代（closure_under/3），与 Julia 实验三对拍（种子 {3,5} 两步得 Z_7）。

% ---------- 现场一：对角线交搜索 ----------
% club 序列：C_j = {i<N : (j+1) | i}（模 j+1 的尾集替身）
club_mod(N, J, Cj) :-
    D is J + 1,
    Max is N - 1,
    findall(I, (between(0, Max, I), 0 is I mod D), Cj).

clubs_mod(N, Clubs) :-
    Max is N - 1,
    findall(Cj, (between(0, Max, J), club_mod(N, J, Cj)), Clubs).

% ξ ∈ ΔC ⟺ ∀j<ξ member(ξ, C_j)
diag_member(N, Clubs, Xi) :-
    MaxXi is N - 1,
    between(0, MaxXi, Xi),
    LtXi is Xi - 1,
    (   LtXi < 0
    ->  true
    ;   forall(between(0, LtXi, J),
               (nth0(J, Clubs, Cj), memberchk(Xi, Cj)))
    ).

diag_members(N, Clubs, Members) :-
    findall(Xi, diag_member(N, Clubs, Xi), Ms0),
    sort(Ms0, Members).

% ---------- 现场二：压小函数与佛多纤维 ----------
to_zero(_, 0).
minus1(I, V) :- V is I - 1.

% 是否压小（regressive）：∀x∈S, x>0 ⟹ f(x)<x
pressing_down(F, S) :-
    forall((member(X, S), X > 0, call(F, X, V)), V < X).

all_fibers(F, S, Tagged) :-
    findall(V, (member(X, S), call(F, X, V)), Vs0),
    sort(Vs0, Vs),
    findall(Len-(V-Fiber),
        (member(V, Vs),
         findall(X, (member(X, S), call(F, X, V)), Fiber),
         length(Fiber, Len)),
        Tagged).

tagged_max([H], H).
tagged_max([Len-X|T], Best) :-
    tagged_max(T, Best0),
    Best0 = (Len0-_),
    (Len > Len0 -> Best = (Len-X) ; Best = Best0).

% fodor_fiber：最大常值纤维（值 BV、纤维 BFiber）
fodor_fiber(F, S, BV, BFiber) :-
    all_fibers(F, S, Tagged),
    tagged_max(Tagged, _-(BV-BFiber)).

% ---------- 现场三：可数子代数不动点 ----------
subset_of([], []).
subset_of([H|T], [H|S]) :- subset_of(T, S).
subset_of([_|T], S) :- subset_of(T, S).

sum_mod(L, M, R) :- sum_list(L, S), R is S mod M.

% 一步扩张：A ↦ A ∪ {f(e) : e ⊆ A}，f(e)=(Σe) mod 7
expand_step(A, B) :-
    findall(V, (subset_of(A, E), sum_mod(E, 7, V)), Vs),
    append(A, Vs, Raw),
    sort(Raw, B).

% closure_under：迭代到不动点，Steps 计扩张步数
closure_under(A, Steps, Closed) :-
    expand_step(A, B),
    (   B == A
    ->  Steps = 0, Closed = A
    ;   closure_under(B, S1, Closed), Steps is S1 + 1
    ).

% ---------- 主检定 ----------
main :-
    format("==== 77~n"),
    % 现场一：ΔC = {0,1,2}
    clubs_mod(10, Clubs),
    diag_members(10, Clubs, DM),
    DM = [0,1,2],
    format("对角线交搜索：C_j={i<10: (j+1)|i}，ΔC = ~w ✓（ξ 需被 1..ξ 整除，仅 0,1,2）~n", [DM]),
    % 现场二：佛多纤维
    S = [1,2,3,4,5],
    pressing_down(to_zero, S),
    fodor_fiber(to_zero, S, V0, F0), length(F0, L0),
    format("压小 f≡0 于 S=[1..5]：最大常值纤维 f⁻¹(~w)=~w（长 ~w，荟萃——佛多有牙）✓~n", [V0,F0,L0]),
    pressing_down(minus1, S),
    fodor_fiber(minus1, S, _, F1), length(F1, L1),
    L1 = 1,
    format("例 2.13 单射压小 f(i)=i−1：最大纤维长 ~w（全单点，非荟萃集上佛多失效）✓~n", [L1]),
    % 现场三：闭包
    closure_under([3,5], Steps, Closed),
    Steps = 2, Closed = [0,1,2,3,4,5,6],
    format("closure_under：种子 {3,5} 在 f(e)=(Σe)mod7 下 ~w 步闭包为 ~w = Z_7 ✓~n", [Steps, Closed]),
    writeln("END ====").
