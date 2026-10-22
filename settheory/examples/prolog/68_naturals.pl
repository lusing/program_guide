:- encoding(utf8).
% 第 68 章：自然数与第一递归定义定理（冯琦 §1.3）
% 和谐函数系统（命题 1.9）+ 有限近似（引理 1.2/1.3）+ 取并；
% 鸽子笼枚举；素数集的雪崩名次（定理 1.11）。

% ---------- 函数 = K-V 对列表 ----------

func_value([K-V0|_], K, V0) :- !.
func_value([_|T], K, V) :- func_value(T, K, V).

compatible(F, G) :-
    forall((member(K-V, F), member(K-W, G)), V == W).

harmonious([]).
harmonious([F|Rest]) :-
    forall(member(G, Rest), compatible(F, G)),
    harmonious(Rest).

% 引理 1.2：长度 m+1 的有限近似（例：f(0)=1, f(n+1)=f(n)*(n+1)——阶乘）
g_step(X, N, Y) :- Y is X * (N + 1).

approx(0, [0-1]).
approx(M1, F1) :-
    M1 > 0, M is M1 - 1,
    approx(M, F0),
    func_value(F0, M, V0),
    g_step(V0, M, V),
    append(F0, [M1-V], F1).

% ---------- 雪崩映射：名次 = #{x ∈ X : x < k} ----------

prime(P) :- P >= 2, P1 is P - 1, \+ (between(2, P1, D), P mod D =:= 0).
primes_up_to(N, Ps) :- findall(P, (between(2, N, P), prime(P)), Ps).

rank_in(X, K, R) :-
    findall(x, (member(E, X), E < K), B),
    length(B, R).

% ---------- 鸽子笼 ----------

injective(V) :- length(V, L), sort(V, S), length(S, L).
surjective3(V) :- sort(V, [0, 1, 2]).

main :-
    % 三段式
    findall(F, (between(0, 6, M), approx(M, F)), Fs),
    ( harmonious(Fs) -> format("近似序列两两和谐（引理 1.3）✓~n")
    ; format("近似序列不和谐（不应发生）~n"), halt(1) ),
    last(Fs, F6),
    func_value(F6, 6, V6),
    format("焊接结果 f(6) = ~w（= 6!）✓~n", [V6]),
    % 鸽子笼
    findall(V, (between(0, 2, A), between(0, 2, B), between(0, 2, C),
                V = [A, B, C]), Vs33),
    include(injective, Vs33, Inj33),
    length(Inj33, L33),
    ( maplist(surjective3, Inj33) -> Surj = true ; Surj = false ),
    format("3→3 单射数 = ~w，全部满射 = ~w~n", [L33, Surj]),
    findall(V, (between(0, 2, A), between(0, 2, B), between(0, 2, C),
                between(0, 2, D), V = [A, B, C, D]), Vs43),
    include(injective, Vs43, Inj43),
    length(Inj43, L43),
    format("4→3 单射数 = ~w（定理 1.10 后半）~n", [L43]),
    % 雪崩
    primes_up_to(50, Ps),
    maplist(rank_in(Ps), [2, 3, 5, 11, 29], Ranks),
    format("素数集自然列表（2,3,5,11,29 的名次）= ~w~n", [Ranks]),
    format("END ====~n").
