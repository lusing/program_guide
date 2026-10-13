:- encoding(utf8).
% 第 18 章 力迫与布尔值模型：力迫规则的推理机

% 三值代数
bsup(0, U, U).
bsup(U, 0, U).
bsup(h, h, h).
bsup(h, 1, 1).
bsup(1, _, 1).

bneg(0, 1). bneg(h, h). bneg(1, 0).

bimp(U, V, W) :- bneg(U, N), bsup(N, V, W).

% 力迫：p ⊩ φ ⟺ e(p) ≤ ‖φ‖
ble(0, _).
ble(h, h). ble(h, 1).
ble(1, 1).

forces(P, Val) :- ble(P, Val).

% 力迫规则（引理 18.7/18.8）
% (a) p ⊩ φ ∧ q ≤ p ⟹ q ⊩ φ
forces_mono(P, Q, Val) :- forces(P, Val), ble(Q, P).

% (b) p ⊩ φ∧ψ ⟺ p ⊩ φ ∧ p ⊩ ψ
forces_and(P, V1, V2) :- bsup(V1, V2, V), forces(P, V).

% ¬：p ⊩ ¬φ ⟺ 无 q ≤ p 使 q ⊩ φ
forces_not(P, Val) :- bneg(Val, NV), forces(P, NV).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 18 V^B：力迫规则~n"),
    (   forces(h, 1) -> format("  ½ ⊩ ‖φ‖=1 ✓（½≤1）~n"); true ),
    (   \+ forces(1, h) -> format("  1 ⊮ ‖φ‖=½ ✓（1≰½）~n"); true ),
    bimp(h, 0, W), format("  ½⇒0 = ~w~n", [W]),
    bimp(0, h, W2), format("  0⇒½ = ~w~n", [W2]),
    format("  力迫定理：M[G] ⊨ φ ⟺ ‖φ‖ ∈ G'~n"),
    format("END ====~n").
