:- encoding(utf8).
% 第 47 章 布尔代数：Div(30) 运算 + 有限超滤子穷举（PIT 有限化身）

% ---------- Div(30) 布尔代数 ----------
d30([1,2,3,5,6,10,15,30]).
meet30(A, B, M) :- M is gcd(A, B).
join30(A, B, L) :- L is lcm(A, B).
not30(A, N) :- N is 30 // A.

check_distr(A, B, C) :-
    join30(B, C, BC), meet30(A, BC, L),
    meet30(A, B, AB), meet30(A, C, AC), join30(AB, AC, R),
    L =:= R.

check_compl30(A) :- not30(A, N), meet30(A, N, 1), join30(A, N, 30).

% ---------- 𝒫({2,3,5}) 上的超滤子穷举 ----------
sub5([], []).
sub5([H|T], [H|S]) :- sub5(T, S).
sub5([_|T], S) :- sub5(T, S).

compl5(S, C) :-
    sub5([2,3,5], C),
    \+ (member(X, S), member(X, C)),
    \+ (member(X, [2,3,5]), \+ (member(X, S) ; member(X, C))).

inter5(A, B, I) :- include(in_list(B), A, I).
in_list(B, X) :- member(X, B).

pow5(P) :- findall(S, sub5([2,3,5], S), P).

is_filter(U) :-
    member([2,3,5], U),
    \+ ( member(A, U), member(B, U),
         inter5(A, B, I), \+ member(I, U) ),
    \+ ( member(A, U), pow5(P), member(S, P),
         inter5(A, S, A), \+ member(S, U) ).

is_ultra(U) :-
    is_filter(U),
    \+ ( pow5(P), member(S, P), \+ ultra_dich(U, S) ).
ultra_dich(U, S) :- member(S, U), compl5(S, C), \+ member(C, U).
ultra_dich(U, S) :- \+ member(S, U), compl5(S, C), member(C, U).

principal5(A, U) :-
    member(A, [2,3,5]),
    pow5(P),
    include(has_elem(A), P, U).
has_elem(A, S) :- member(A, S).

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 47 布尔代数实验室~n"),

    % 一、Div(30) 分配律全扫（8³ = 512 组合）
    d30(D),
    forall((member(A, D), member(B, D), member(C, D)), check_distr(A, B, C)),
    format("  Div(30) gcd/lcm 分配律全扫 ✓（512 组合）~n"),

    % 二、补律全扫：n ∧ 30/n = 1 且 n ∨ 30/n = 30
    forall(member(A, D), check_compl30(A)),
    format("  Div(30) 补律全扫 ✓（n∧¬n=1、n∨¬n=30）~n"),

    % 三、原子 = {2,3,5}
    findall(A, (member(A, D), A > 1,
                forall((member(B, D), B > 1),
                       (gcd(A, B) =:= 1 ; gcd(A, B) =:= A))),
            Atoms),
    Atoms = [2, 3, 5],
    format("  Div(30) 原子 = {2,3,5} ✓~n"),

    % 四、主超滤恰 3 个，全部是超滤
    findall(U, (member(A, [2,3,5]), principal5(A, U)), Ps),
    length(Ps, 3),
    forall(member(U, Ps), is_ultra(U)),
    format("  P({2,3,5}) 主超滤恰 3 个，全部验证为超滤 ✓~n"),

    % 五、有限 PIT：穷举超滤子族（2^256 太大——按滤子封闭性减枝后穷举）
    %    事实：有限 BA 上超滤必主。这里对 𝒫({2,3,5}) 全空间验证：
    %    任何超滤都含某原子 {a}（否则对每个 a，补 {a}ᶜ ∈ U，
    %    三者交 = ∅ ∈ U 违反滤子性）——枚举所有 2^8 子族筛超滤：
    pow5(Pow),
    length(Pow, 8),
    findall(U, (sub5(Pow, U), is_ultra(U)), Ultras),
    length(Ultras, NU),
    NU = 3,
    format("  全空间穷举（2^8 = 256 子族）：超滤恰 3 个 = 主超滤 ✓~n"),
    format("  ——有限 BA 上超滤必主；PIT 的 Zorn 步骤在有限世界退化为穷举~n"),

    format("END ===="), nl.
