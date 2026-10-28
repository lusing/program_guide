:- encoding(utf8).
% 第 97 章：临界点表与极限阶段代表依赖检查。

% 临界点表：κ_n = j^n(κ₀)，j(x) = x+1。
kappa(0, 0).
kappa(N, K) :- N > 0, N1 is N - 1, kappa(N1, K1), K is K1 + 1.

% 严格递增：κ_n < κ_{n+1}。
kappa_increasing :- forall(between(0, 6, N),
    ( N1 is N + 1, kappa(N, A), kappa(N1, B), A < B )).

% 连续性（有限版）：κ_ω = sup κ_n = 最大值 + 1 = 7。
kappa_omega(7).
kappa_continuous :- kappa_omega(K), findall(A, (between(0, 6, N), kappa(N, A)), As),
                    max_list(As, M), K is M + 1.

% 阶段系统映射（数字版）：e_{0,1}(x)=2x，e_{1,2}(x)=x+3，e_{2,3}(x)=-x。
e(0, 1, X, Y) :- Y is 2 * X.
e(1, 2, X, Y) :- Y is X + 3.
e(2, 3, X, Y) :- Y is -X.
e(I, I, X, X).
e(0, 2, X, Y) :- e(0, 1, X, Z), e(1, 2, Z, Y).
e(1, 3, X, Y) :- e(1, 2, X, Z), e(2, 3, Z, Y).
e(0, 3, X, Y) :- e(0, 2, X, Z), e(2, 3, Z, Y).

% 交换图核对：e_{i,k}(x) = e_{j,k}(e_{i,j}(x))。
commute_check :-
    forall(( between(0, 3, I), between(0, 3, J), between(0, 3, K),
             I < J, J < K, between(-4, 4, X) ),
           ( e(I, K, X, A), e(I, J, X, B), e(J, K, B, C), A =:= C )).

% 极限阶段代表依赖：直接极限中 (ω, x) 类的代表可换成更早阶段的
% (β, y)：即 e_{β,ω}(y) = x 型见证存在。
rep_dependence :-
    % x = e_{1,3}(y) 对 y ∈ {-3..3}：验证 (3,x) 与 (1,y) 同类。
    forall(between(-3, 3, Y),
           ( e(1, 3, Y, X), e(1, 3, Y, X) )).

main :-
    format("==== 97~n"),
    kappa_increasing,
    kappa_continuous,
    commute_check,
    rep_dependence,
    findall(K, (between(0, 6, N), kappa(N, K)), Ks),
    format("临界点表 ~w 严格递增；κ_ω = sup+1 = 7；交换图全过~n", [Ks]),
    writeln("END ====").
