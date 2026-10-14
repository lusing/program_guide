:- encoding(utf8).
% 第 53 章 名字的项表示与 G-读出推理（钻石代数）

bel(d0). bel(du). bel(dv). bel(d1).

dmeet(d0, _, d0). dmeet(_, d0, d0).
dmeet(du, du, du). dmeet(dv, dv, dv).
dmeet(d1, X, X). dmeet(X, d1, X).
dmeet(_, _, d0).

% 超滤
ing(du). ing(d1).
ingv(dv). ingv(d1).

% 名字：ncons(子名, 标签, 尾) / nempty
% 读出：val_G(τ, 读出集)
val(nempty, _, []).
val(ncons(_, B, R), G, Out) :-
    (member(B, G) -> val(R, G, Rest), Out = [B | Rest] ; val(R, G, Out)).

% 主检查：双标签名在两个超滤下的双读性
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 53 名字与 G-读出（钻石代数）~n"),

    T = ncons(nempty, du, ncons(nempty, dv, nempty)),
    val(T, [du, d1], Out1), Out1 = [du],
    val(T, [dv, d1], Out2), Out2 = [dv],
    format("  双标签名：G_u 读出 [du]，G_v 读出 [dv] ✓~n"),
    format("  ——泛型多读性：同一图纸、不同 G、不同集合~n"),

    % check 名：ǔ = ncons(nempty, d1, nempty)
    Ck = ncons(nempty, d1, nempty),
    val(Ck, [du, d1], [d1]),
    val(Ck, [dv, d1], [d1]),
    format("  check 名 {Ø,(∅,1)}：两个 G 下都读出 [d1]（G-无关性）✓~n"),

    % 空名
    val(nempty, [du, d1], []),
    format("  空名读出空集 ✓~n"),

    % ∈ 真值样例：⟦tagged du ∈ tagged du⟧ = du
    dmeet(du, d1, du),
    format("  ⟦tagged du ∈ tagged du⟧ = du ∧ 1 = du（中间真值）✓~n"),

    format("END ===="), nl.
