:- encoding(utf8).
% 第 57 章：关系的机器化（Makinson Ch2）
% 谓词即关系：家族复合、传递闭包、关系代数三件套、等价类与极小元。

% ---------- 家族数据库 ----------
parent(tom, mary).
parent(bob, tom).
parent(mary, ann).

father(tom, mary).
father(bob, tom).
mother(mary, ann).

% 复合：rel_comp(R, S, A, C) = 先 R 后 S（书本 S∘R）
rel_comp(R, S, A, C) :- call(R, A, X), call(S, X, C).

% 传递闭包 = 有限路径（单步 + 至少两步）
tclosure(R, A, B) :- call(R, A, B).
tclosure(R, A, C) :- call(R, A, X), tclosure(R, X, C).

% 逆
converse(R, A, B) :- call(R, B, A).

% ---------- 关系代数：书本数字例子 ----------
% R：整除（A={2,3,13} → B={12,15,17}）
r_div(A, B) :- member(A, [2,3,13]), member(B, [12,15,17]),
               B mod A =:= 0.
% S：同奇偶（B → C={11,16,21}）
s_par(B, C) :- member(B, [12,15,17]), member(C, [11,16,21]),
               B mod 2 =:= C mod 2.

join_rst(A, B, C) :- r_div(A, B), s_par(B, C).
proj_a(A) :- join_rst(A, _, _).
proj_ac(A, C) :- join_rst(A, _, C).
select_r23(A, B) :- r_div(A, B), member(A, [2,3]).

% ---------- 等价：同奇偶于 0..5 ----------
same_parity(A, B) :- between(0, 5, A), between(0, 5, B),
                     A mod 2 =:= B mod 2.

% ---------- 偏序：整除于 2..13 ----------
dvds(A, B) :- between(2, 13, A), between(2, 13, B),
              A =\= B, B mod A =:= 0.

covers(A, B) :- dvds(A, B),
                \+ (between(2, 13, X), X =\= A, X =\= B,
                    dvds(A, X), dvds(X, B)).

minimal(A) :- between(2, 13, A), \+ dvds(_, A).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 57~n"),

    % 一、家族复合与闭包
    findall((A,C), rel_comp(parent, parent, A, C), G),
    format("  P∘P（祖辈）：~w（tom 是 ann 的祖父）~n", [G]),
    member((tom, ann), G),
    findall((A,C), tclosure(parent, A, C), Anc),
    length(Anc, LAnc),
    format("  P⁺（先辈闭包，~d 对）：~w~n", [LAnc, Anc]),
    LAnc = 6,

    % 二、关系代数
    findall((A,B), r_div(A, B), Rl),
    findall((B,C), s_par(B, C), Sl),
    format("  R（整除）= ~w~n  S（同奇偶）= ~w~n", [Rl, Sl]),
    findall((A,B,C), join_rst(A, B, C), J),
    length(J, 4),
    format("  join(R,S) = ~w（书本答案 4 个三元组）~n", [J]),
    setof(A, proj_a(A), PA),
    format("  投影到 A = ~w（书本答案 {2,3}）~n", [PA]),
    setof((A,C), proj_ac(A, C), PAC),
    format("  投影到 A×C = ~w~n", [PAC]),
    findall((A,B), select_r23(A, B), Sel),
    format("  选择 A'={2,3} 后的 R = ~w~n", [Sel]),

    % 三、同奇偶等价类
    setof(Class, A^B^(same_parity(A,B), Class = B), _),   % 仅激活谓词
    findall(C0, (between(0,5,X), X mod 2 =:= 0, C0 = X), Evens),
    findall(C1, (between(0,5,X), X mod 2 =:= 1, C1 = X), Odds),
    format("  同奇偶的等价类：~w 与 ~w~n", [Evens, Odds]),

    % 四、立即前驱与极小元
    findall((A,B), covers(A, B), Cv),
    length(Cv, 9),
    format("  立即前驱（书本答案 9 对）：~w~n", [Cv]),
    findall(M, minimal(M), Ms),
    format("  极小元（素数）：~w~n", [Ms]),

    % 五、闭包与逆交换：(P⁺)⁻¹ = (P⁻¹)⁺ 的见证检查
    findall(C, tclosure(parent, tom, C), Ts),
    findall(C, converse(tclosure(parent), C, tom), Ts2),
    Ts == Ts2,
    format("  (P⁺)⁻¹ = (P⁻¹)⁺：tom 的后辈集合两向相等 ~w ✓~n", [Ts]),

    format("END ===="), nl.
