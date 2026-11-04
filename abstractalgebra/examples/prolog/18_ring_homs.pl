:- encoding(utf8).
% 第 18 章 · 环同态 —— Prolog 通道
%
% mod 同态核与像 + 吸收性 + 同态枚举。

addp(zm(M), X, Y, Z) :- Z is (X + Y) mod M.
mulp(zm(M), X, Y, Z) :- Z is (X * Y) mod M.
elem(zm(M), X) :- between(0, M, X0), X is X0 mod M.

% ---------- mod 同态 ℤ₁₂ → ℤ₄ ----------
f124(X, Y) :- Y is X mod 4.

% ---------- 同态检查 ----------
hom_12_4 :-
    forall((elem(zm(12), A), elem(zm(12), B)),
           (addp(zm(12), A, B, AB12), f124(AB12, L),
            f124(A, FA), f124(B, FB), addp(zm(4), FA, FB, R),
            L == R)),
    forall((elem(zm(12), A), elem(zm(12), B)),
           (mulp(zm(12), A, B, AB12), f124(AB12, L),
            f124(A, FA), f124(B, FB), mulp(zm(4), FA, FB, R),
            L == R)).

% 核的吸收性：r·x ∈ ker
absorbed :-
    forall((elem(zm(12), R), member(K, [0, 4, 8])),
           (mulp(zm(12), R, K, RK), 0 is RK mod 4)).

% ---------- 同态枚举：ℤ₄ → ℤ₄ ----------
% 映射以 F = [f(0), f(1), f(2), f(3)] 列表给出
all_maps4(Fs) :-
    findall(F, (member(A, [0,1,2,3]), member(B, [0,1,2,3]),
                member(C, [0,1,2,3]), member(D, [0,1,2,3]),
                F = [A, B, C, D]), Fs).

hom4(F) :-
    F = [_, 1, _, _],                    % f(1) = 1
    % 保加：f(a+b) = f(a)+f(b)
    forall((between(0, 3, A), between(0, 3, B)),
           (AplusB is (A + B) mod 4,
            nth0(A, F, FA), nth0(B, F, FB), FAB is (FA + FB) mod 4,
            nth0(AplusB, F, FABt), FABt == FAB)),
    % 保乘：f(ab) = f(a)f(b)
    forall((between(0, 3, A), between(0, 3, B)),
           (AtimesB is (A * B) mod 4,
            nth0(A, F, FA), nth0(B, F, FB), FAB is (FA * FB) mod 4,
            nth0(AtimesB, F, FABt), FABt == FAB)).

main :-
    format("==== 18 环同态~n"),

    hom_12_4,
    absorbed,
    format("ℤ₁₂ → ℤ₄（mod 4）：144 对保加保乘；核 {0,4,8} 吸收性 ✓~n"),

    all_maps4(Fs),
    include(hom4, Fs, Homs),
    length(Homs, N), N == 1,      % 环同态保 1 ⟹ 恒等
    format("ℤ₄ → ℤ₄ 环同态枚举：256 个映射中恰 ~d 个（保 1 迫使恒等）✓~n", [N]),

    % 高斯范数乘性
    forall((between(-3, 3, A), between(-3, 3, B),
            between(-3, 3, C), between(-3, 3, D)),
           (ZW_RE is A * C - B * D, ZW_IM is A * D + B * C,
            NZW is ZW_RE * ZW_RE + ZW_IM * ZW_IM,
            NZ is (A * A + B * B) * (C * C + D * D),
            NZW == NZ)),
    format("高斯范数：N(zw) = N(z)N(w)（49×49 对）✓~n"),

    format("END ====~n").
