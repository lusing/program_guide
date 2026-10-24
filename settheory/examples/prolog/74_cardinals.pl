:- encoding(utf8).
% 第 74 章：基数：和、积与典型秩序（冯琦 §1.9）——Prolog 通道
% Gödel 配对双射（定义 1.97/1.98 的 ℕ 截面：max-壳层典型序的名次）
% 全网格往返与"方块=前段"（定理 1.92）逐格对拍；ℵ 序列符号演算与
% max 规则引擎（推论 1.13：κ+λ = κ·λ = max）；aleph 不动点链
% （定理 1.91(2) 的程序版，符号嵌套展示）。

% ---------- Γ 配对：壳内偏移（0..m−1, m 行, m 列, (m,m)） ----------
gpair(A, B, P) :-
    M is max(A, B),
    (  A < M -> P is M*M + A
    ;  B < M -> P is M*M + M + B
    ;  P is M*M + 2*M ).

gunpair(P, A, B) :-
    M is integer(sqrt(P)),
    (  (M+1)*(M+1) =< P -> M1 is M+1 ; M1 = M ),
    (  M1*M1 > P -> M2 is M1-1 ; M2 = M1 ),
    T is P - M2*M2,
    (  T < M2 -> A = T, B = M2
    ;  T < 2*M2 -> A = M2, B is T - M2
    ;  A = M2, B = M2 ).

% ---------- 符号基数：fcard(n) 有限；aleph(α)（α 为嵌套 CNF on 项） ----------
is_inf(aleph(_)).

sclt(fcard(A), fcard(B)) :- A < B.
sclt(fcard(_), aleph(_)).
sclt(aleph(A), aleph(B)) :- olt(A, B).

% ON 比较（复用 73 章嵌套 CNF：on([t(E,C)|…])）
olt(A, B) :- A \== B, olt_(A, B).
olt_(on([]), on([_|_])).
olt_(on([t(Ea,Ca)|Ta]), on([t(Eb,Cb)|Tb])) :-
    (  olt(Ea, Eb) -> true
    ;  olt(Eb, Ea) -> fail
    ;  Ca \== Cb -> Ca < Cb
    ;  olt_(on(Ta), on(Tb)) ).

% 推论 1.13：κ+λ = κ·λ = max{κ,λ}（κ,λ 无穷）；有限退化普通算术
cadd(fcard(A), fcard(B), fcard(C)) :- !, C is A + B.
cadd(A, B, C) :- (sclt(A, B) -> C = B ; C = A).
cmul(fcard(A), fcard(B), fcard(C)) :- !, C is A * B.
cmul(A, B, C) :- (sclt(A, B) -> C = B ; C = A).

% ---------- aleph 不动点链：κ₀ = ℵ₀，κ_{n+1} = ℵ_{κ_n}（符号嵌套） ----------
show_chain(0, "ℵ₀") :- !.
show_chain(K, S) :-
    K > 0, K1 is K - 1, show_chain(K1, S1),
    format(atom(S), "ℵ_{~w}", [S1]).

% ---------- 主检定 ----------
main :-
    format("==== 74~n"),
    % Γ 双射：0..1999 往返；12×12 单射；m×m 方块=前段（m≤12）
    forall(between(0, 1999, P), (gunpair(P, A, B), gpair(A, B, P2), P2 =:= P)),
    findall(P, (between(0, 11, A), between(0, 11, B), gpair(A, B, P)), Ps),
    list_to_set(Ps, Ss), length(Ss, 144),
    forall(between(1, 12, M),
           (findall(P, (between(0, M, I), between(0, M, J), I < M, J < M,
                        gpair(I, J, P)), GP),
            sort(GP, SP), M2 is M*M - 1, numlist(0, M2, NL), SP == NL)),
    writeln("Γ 配对：0..1999 往返恒等 ✓、12×12 单射 ✓、m×m 方块=前段（m≤12）✓"),
    gpair(2, 5, P25), gpair(5, 2, P52), gpair(3, 3, P33),
    format("  样例：Γ(2,5)=~w、Γ(5,2)=~w、Γ(3,3)=~w~n", [P25, P52, P33]),
    % max 规则引擎（推论 1.13）
    cadd(aleph(on([t(on([]),2)])), aleph(on([])), R1),
    R1 == aleph(on([t(on([]),2)])),
    cmul(aleph(on([t(on([t(on([]),1)]),1)])), aleph(on([t(on([]),3)])), R2),
    R2 == aleph(on([t(on([t(on([]),1)]),1)])),
    cadd(aleph(on([t(on([]),2)])), aleph(on([t(on([]),1)])), S1),
    cmul(S1, aleph(on([])), R3),
    R3 == aleph(on([t(on([]),2)])),
    cadd(fcard(3), fcard(7), F1), F1 == fcard(10),
    cmul(fcard(3), fcard(7), F2), F2 == fcard(21),
    writeln("max 规则引擎：ℵ₂+ℵ₀ = ℵ_2、ℵ_ω·ℵ₃ = ℵ_ω、(ℵ₂+ℵ₁)·ℵ₀ = ℵ_2 ✓；有限退化 3+7=10、3·7=21 ✓"),
    % aleph 不动点链（定理 1.91(2)）
    forall(between(0, 4, N),
           (show_chain(N, S),
            (N =:= 1 -> format("  κ_~w = ~w  = ℵ_ω（第一个奇异基数，例 1.33）~n", [N, S])
            ; format("  κ_~w = ~w~n", [N, S])))),
    writeln("  …sup_n κ_n = λ 满足 ℵ_λ = λ——任意大的 aleph 不动点（定理 1.91(2)）"),
    writeln("END ====").
