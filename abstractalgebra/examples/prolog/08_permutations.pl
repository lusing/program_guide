:- encoding(utf8).
% 第 08 章 · 置换 —— Prolog 通道
%
% 复合/循环分解/符号 + S₃ 全量断言 + 对换 = 奇。

% ---------- 基础件 ----------
perm_compose(Alpha, Beta, AB) :-
    length(Alpha, N),
    findall(A, (between(1, N, I), nth1(I, Beta, B), nth1(B, Alpha, A)), AB).

perm_inv(Alpha, Inv) :-
    length(Alpha, N),
    length(Inv, N),
    forall(between(1, N, I),
           (nth1(I, Alpha, A), nth1(A, Inv, I))).

% 循环分解（"跟着走"）
perm_cycles(Alpha, Cs) :-
    length(Alpha, N),
    numlist(1, N, All),
    perm_cycles_(Alpha, All, [], Cs).

perm_cycles_(_, [], Acc, Cs) :- !,
    reverse(Acc, Cs).
perm_cycles_(Alpha, [I | Rest], Acc, Cs) :-
    nth1(I, Alpha, Ai),
    (   Ai =:= I ->
        perm_cycles_(Alpha, Rest, Acc, Cs)
    ;   walk(Alpha, I, I, [], C),           % 从 I 走一圈
        subtract(Rest, C, Rest1),           % 圈内点全部标记
        perm_cycles_(Alpha, Rest1, [C | Acc], Cs)
    ).

% 从 Start 出发沿 Alpha 走到回到 Start：循环 = 途经点序列
walk(Alpha, Start, Cur, Acc, C) :-
    nth1(Cur, Alpha, Next),
    (   Next =:= Start ->
        reverse(Acc, RA),
        append(RA, [Cur], C)
    ;   walk(Alpha, Start, Next, [Cur | Acc], C)
    ).

% 符号：逆序数奇偶
perm_sign(Alpha, S) :-
    length(Alpha, N),
    aggregate_all(count,
        (between(1, N, I), between(1, N, J), I < J,
         nth1(I, Alpha, A), nth1(J, Alpha, B), A > B), Inv),
    (Inv mod 2 =:= 0 -> S = 1 ; S = -1).

% 阶：幂回到恒等
perm_order(Alpha, K) :-
    perm_order_(Alpha, Alpha, 1, K).
perm_order_(Cur, Alpha, K, K) :-
    identity_perm(Alpha, Cur), !.
perm_order_(Cur, Alpha, K0, K) :-
    perm_compose(Alpha, Cur, Next),
    K1 is K0 + 1,
    perm_order_(Next, Alpha, K1, K).

identity_perm(Alpha, Id) :-
    length(Alpha, N),
    numlist(1, N, Id).

% ---------- S₃ 全部置换 ----------
s3_all([[1,2,3], [2,1,3], [3,2,1], [1,3,2], [2,3,1], [3,1,2]]).

main :-
    format("==== 08 置换~n"),

    % 循环分解手算对照
    perm_cycles([2,3,1], C1), C1 == [[1,2,3]],
    perm_cycles([2,1,3], C2), C2 == [[1,2]],
    perm_compose([2,1,3], [1,3,2], AB), AB == [2,3,1],
    format("循环分解与复合（从右向左）：手算一致 ✓~n"),

    % 命题 2.55：阶 = lcm 循环长（S₃ 全量）
    forall((s3_all(Ss), member(P, Ss)),
           ( perm_cycles(P, Cs),
             maplist(length, Cs, Ls),
             (Ls == [] -> K is 1 ; lcm_list(Ls, K)),
             perm_order(P, K) )),
    format("命题 2.55（阶 = lcm 循环长）：S₃ 全部 6 个置换 ✓~n"),

    % 定理 2.39：sgn 乘法性（S₃ 全部 36 对；变量名与上文错开防捕获）
    forall((s3_all(Ss39), member(PA, Ss39), member(PB, Ss39)),
           ( perm_compose(PA, PB, PAB),
             perm_sign(PA, SA39), perm_sign(PB, SB39), perm_sign(PAB, SAB39),
             SAB39 =:= SA39 * SB39 )),
    aggregate_all(count, (s3_all(SsN), member(PE, SsN), perm_sign(PE, 1)), NE),
    NE == 3,
    format("定理 2.39（sgn(αβ) = sgn(α)sgn(β)）：S₃ 全部 36 对；偶置换恰 3 个（A₃）✓~n"),

    % 对换是奇置换
    forall(member(TR, [[2,1,3], [1,3,2], [3,2,1]]), perm_sign(TR, -1)),
    % 3-循环是偶置换（两个对换之积）
    forall(member(TC, [[2,3,1], [3,1,2]]), perm_sign(TC, 1)),
    format("对换 = 奇，3-循环 = 偶 ✓~n"),

    format("END ====~n").

lcm_list([], 1) :- !.
lcm_list([X | Xs], L) :- lcm_list(Xs, L0), L is lcm(X, L0).
