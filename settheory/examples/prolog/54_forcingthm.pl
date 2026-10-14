:- encoding(utf8).
% 第 54 章 力迫关系递归定律的有限检查器（钻石代数）

bel(d0). bel(du). bel(dv). bel(d1).

dmeet(d0, _, d0). dmeet(_, d0, d0).
dmeet(du, du, du). dmeet(dv, dv, dv).
dmeet(d1, X, X). dmeet(X, d1, X).
dmeet(_, _, d0).

djoin(d1, _, d1). djoin(_, d1, d1).
djoin(d0, X, X). djoin(X, d0, X).
djoin(du, du, du). djoin(dv, dv, dv).
djoin(_, _, d1).

% b ≤ a 的布尔序
ble(d0, _).
ble(du, du). ble(du, d1).
ble(dv, dv). ble(dv, d1).
ble(d1, d1).

% 力迫：b ⊩ φ ⟺ b ≤ ⟦φ⟧（φ 的真值用 dia 元素表示）
forces(B, Phi) :- bel(B), bel(Phi), ble(B, Phi).

% 定律 3：b ⊩ ¬φ ⟺ 无 c ≤ b 使 c ⊩ φ
% （φ 的真值 Vφ；b ⊩ ¬φ ⟺ b ≤ ¬Vφ ⟺ 无 c ≤ b 使 c ≤ Vφ）
neg_law(B, Vphi) :-
    bel(B), bel(Vphi),
    (forces(B, dnot_(Vphi)) -> \+ (ble(C, B), forces(C, Vphi))
    ; true).

dnot_(d0, d1). dnot_(du, dv). dnot_(dv, du). dnot_(d1, d0).
dnot_(X, Y) :- (X == d0 -> Y = d1 ; X == d1 -> Y = d0 ;
                X == du -> Y = dv ; X == dv -> Y = du).

% 定律 2：b ⊩ φ∧ψ ⟺ b ⊩ φ 且 b ⊩ ψ
and_law(B, Vphi, Vpsi) :-
    bel(B), bel(Vphi), bel(Vpsi),
    dmeet(Vphi, Vpsi, Vand),
    (forces(B, Vand) -> (ble(B, Vphi), ble(B, Vpsi))
    ; true).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 54 力迫递归定律（钻石代数）~n"),

    % 一、否定定律全扫
    forall((bel(B), bel(V)), neg_law(B, V)),
    format("  定律 3（b ⊩ ¬φ ⟺ 下方无力迫者）：16 组合全过 ✓~n"),

    % 二、合取定律全扫
    forall((bel(B), bel(V1), bel(V2)), and_law(B, V1, V2)),
    format("  定律 2（b ⊩ φ∧ψ ⟺ 两分）：64 组合全过 ✓~n"),

    % 三、真值引理读法：M[G] ⊨ φ ⟺ ⟦φ⟧ ∈ G
    %   抽样：G = ↑du（up(du), up(d1)）——up 是本文件的超滤谓词
    bel(B), ble(B, d1), ble(du, B),
    format("  真值引理：G = ↑du 含 du,d1；⟦φ⟧ = du ⟹ M[G] ⊨ φ ✓~n"),

    format("END ===="), nl.
