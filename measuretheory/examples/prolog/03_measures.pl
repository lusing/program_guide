:- encoding(utf8).
% 03_measures.pl —— 第 03 章：有限原子测度的可数可加律（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 用有理数 q(N, D)（D>0 已约简）精确表示 μ({k}) = 1/2^k，
% 验证：总质量、单调性、次可加性、有限可加、截断下方连续。

gcd(A, 0, A) :- !.
gcd(A, B, G) :- C is A mod B, gcd(B, C, G).

qnorm(q(N0, D0), q(N, D)) :-
    gcd(abs(N0), D0, G), G \= 0, N is N0 // G, D is D0 // G.

qadd(q(N1, D1), q(N2, D2), Q) :-
    N is N1 * D2 + N2 * D1, D is D1 * D2, qnorm(q(N, D), Q).

qle(q(N1, D1), q(N2, D2)) :- N1 * D2 =< N2 * D1.

% 原子质量 μ({k}) = 1/2^k
mu_atom(K, q(1, P)) :- P is 2 ** K.

% 有限集合的测度
mu_set([], q(0, 1)).
mu_set([K|T], Q) :- mu_atom(K, M1), mu_set(T, M2), qadd(M1, M2, Q).

% 1..N 总质量 = 1 - 2^-N（截断）
total_mass(N, q(A, B)) :- numlist(1, N, L), mu_set(L, q(A, B)).

check_total :- total_mass(20, q(A, B)),
    format("total mass 1..20 = ~w/~w (expect 1048575/1048576)~n", [A, B]),
    A =:= 1048575, B =:= 1048576.

check_mono :-
    % {1..10} ⊆ {1..15} ⟹ 测度小
    numlist(1, 10, L1), numlist(1, 15, L2),
    mu_set(L1, M1), mu_set(L2, M2),
    qle(M1, M2),
    format("monotonicity mu(1..10) <= mu(1..15): OK~n").

check_add :-
    % 不交并：{1..5} ⊎ {6..9} = {1..9}
    numlist(1, 5, A), numlist(6, 9, B), numlist(1, 9, C),
    mu_set(A, MA), mu_set(B, MB), mu_set(C, MC),
    qadd(MA, MB, MSum), MSum = MC,
    format("finite additivity {1..5} u {6..9}: OK~n").

check_sub :-
    % 次可加：{1..5} ∪ {4..8} = {1..8}（重叠 4..5）
    numlist(1, 5, A), numlist(4, 8, B), numlist(1, 8, C),
    mu_set(A, MA), mu_set(B, MB), mu_set(C, MC),
    qadd(MA, MB, MSum), qle(MC, MSum),
    format("subadditivity overlapping union: OK~n").

check_tail :-
    % 上方连续截断：尾部 {n..20} 的测度 = 2^{-(n-1)} - 2^{-20}
    forall(member(N, [1, 3, 8]),
           ( numlist(N, 20, L), mu_set(L, q(A, B)),
             E is 2 ** (N - 1), F is 2 ** 20,
             A * F =:= (F // E) * B - B,   % A/B = 1/E - 1/2^20
             format("tail ~w: ~w/~w = 2^-(~w-1) - 2^-20 OK~n", [N, A, B, N]) )).

check_even_odd :-
    % 偶/奇不交分解（截断到 40）
    findall(K, (between(1, 40, K), K mod 2 =:= 0), Ev),
    findall(K, (between(1, 40, K), K mod 2 =:= 1), Od),
    mu_set(Ev, q(EA, EB)), mu_set(Od, q(OA, OB)),
    qadd(q(EA, EB), q(OA, OB), q(SA, SB)),
    total_mass(40, q(TA, TB)),
    SA =:= TA, SB =:= TB,
    format("even+odd = total (truncated at 40): OK~n").

main :-
    format("==== 03 measures~n", []),
    check_total, check_mono, check_add, check_sub, check_tail, check_even_odd,
    format("END ====~n"), !.
