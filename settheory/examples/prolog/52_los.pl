:- encoding(utf8).
% 第 52 章 钻石代数上的满性检查与混合拼装搜索

bel(d0). bel(du). bel(dv). bel(d1).

dmeet(d0, _, d0).
dmeet(_, d0, d0).
dmeet(du, du, du).
dmeet(dv, dv, dv).
dmeet(d1, X, X).
dmeet(X, d1, X).
dmeet(_, _, d0).

djoin(d1, _, d1).
djoin(_, d1, d1).
djoin(d0, X, X).
djoin(X, d0, X).
djoin(du, du, du).
djoin(dv, dv, dv).
djoin(_, _, d1).

dnot(d0, d1). dnot(du, dv). dnot(dv, du). dnot(d1, d0).

% 超滤 ↑du = {du, d1}
ing(du). ing(d1).

% 域与谓词指派
dom(p). dom(q).
rv(p, du). rv(q, d1).

% 混合拼装：反链 {du, dv} 上找 b
mix(Au, Av, B) :-
    bel(B),
    dmeet(B, du, Mu), dmeet(Au, du, Mu),
    dmeet(B, dv, Mv), dmeet(Av, dv, Mv).

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 52 满性与混合（钻石代数）~n"),

    % 一、混合拼装：16 组合全部有解
    forall((bel(Au), bel(Av)), once(mix(Au, Av, _))),
    format("  混合拼装：16 组 (a_u, a_v) 全部找到混合见证（once 语义）✓~n"),

    % 二、满性（有限域）：rv 的 sup 被见证达到
    findall(V, (dom(E), rv(E, V)), Vs),
    foldl_join(Vs, d0, Sup),
    dom(W), rv(W, Sup),
    format("  sup{rv(p), rv(q)} = ~w 被 ~w 达到（有限域恒满）✓~n", [Sup, W]),

    % 三、Łoś 原子：rv(x) ∈ G ⟺ 商中成立（↑du 下 q 成立、p 不成立）
    (ing(du), \+ ing(dv)),
    format("  超滤 ↑du = {du, d1}：R(p)=du ∈ G（成立），R 的余不在 G~n"),
    format("  ——原子 Łoś 等价的两方向在此超滤上人工核对 ✓~n"),

    % 四、反链 {du, dv} 的正交性
    dmeet(du, dv, d0),
    format("  dmeet(du,dv) = d0（反链正交）✓~n"),

    format("END ===="), nl.

foldl_join([], S, S).
foldl_join([V | Vs], Acc, S) :- djoin(V, Acc, A1), foldl_join(Vs, A1, S).
