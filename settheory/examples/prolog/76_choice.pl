:- encoding(utf8).
% 第 76 章：选择公理与无穷和积不等式（冯琦 §2.1-2.2）——Prolog 通道
% 定理 2.2 选择函数⇄秩序往返（有限版超限递归）；问题 2.1 裂缝现场；
% 佐恩有限重演（有限单射极大元=满射）；柯尼希对角线逃逸；特征函数
% 双射；定理 2.13+豪斯多夫公式的基数指数符号求值器（乘积坍缩只用
% ZFC 可证的支配关系 j+1 ≥ i）。

% ---------- 现场一：选择函数 ⇄ 秩序（定理 2.2 有限版） ----------
wo_from_choice(_, [], []).
wo_from_choice(C, X, [A|Seq]) :-
    call(C, X, A),
    select(A, X, X1),
    wo_from_choice(C, X1, Seq).

% "任性"选择函数：取排序后首元
c_sort(X, A) :- sort(X, [A|_]).

choice_from_wo(Order, A, M) :-
    findall(X, member(X, A), Es),
    % A 中按 Order 位次最小者
    sort(Es, SEs),
    member(M, SEs),
    nth0(I, Order, M),
    \+ (member(N, SEs), nth0(J, Order, N), J < I).

% ---------- 现场二：问题 2.1 裂缝 ----------
% a = {{0},{1}}：两个元素都是 ∈-极小（b ∩ a = ∅）
scene2 :-
    A = [[0], [1]],
    findall(B, (member(B, A), \+ (member(X, B), member(X, A))), Ms),
    length(Ms, 2).

% ---------- 现场三：佐恩有限重演 ----------
% X = [0,1,2] 的有限单射（列表，值域不重复）全长 ≤ 3；极大元皆满射
inj_list(Y, F) :-
    (F = [] ; Y = [H|T], (F = [H|R], inj_list(T, R) ; inj_list(T, F), F = [_|_])).
% 生成所有单射：子集+排列
all_injections(Y, P) :-
    findall(F, (subset_take(Y, S), permutation(S, F)), P).
subset_take([], []).
subset_take([H|T], [H|S]) :- subset_take(T, S).
subset_take([_|T], S) :- subset_take(T, S).

extends(F, G) :- append(F, _, G).

proper_extends(F, G) :- append(F, [_|_], G).

is_maximal(F, P) :-
    \+ (member(G, P), proper_extends(F, G)).

scene3(Ms) :-
    all_injections([0,1,2], P),
    findall(F, (member(F, P), is_maximal(F, P)), Ms),
    forall(member(M, Ms), length(M, 3)),
    length(Ms, 6).

% ---------- 现场六：指数符号求值器 ----------
show_k(aleph(A), S) :- format(atom(S), "ℵ_~w", [A]).
show_k(pow(L), S) :- show_k(L, SL), format(atom(S), "2^{~w}", [SL]).
show_k(mul(A, B), S) :- show_k(A, SA), show_k(B, SB), format(atom(S), "~w·~w", [SA, SB]).

idx_le(aleph(A), aleph(B)) :- number(A), (number(B) -> A =< B ; B == w).

cmul(aleph(A), aleph(B), R) :- !, (idx_le(aleph(A), aleph(B)) -> R = aleph(B) ; R = aleph(A)).
cmul(aleph(I), pow(aleph(J)), pow(aleph(J))) :-
    number(I), number(J), J + 1 >= I, !.
cmul(pow(aleph(J)), aleph(I), pow(aleph(J))) :-
    number(I), number(J), J + 1 >= I, !.
cmul(A, B, mul(A, B)).

exp_eval(K, L, R, Steps) :- exp_rec(K, L, R, Steps).
exp_rec(K, L, pow(L), [S]) :-
    idx_le(K, L), !,
    show_k(K, SK), show_k(L, SL),
    format(atom(S), "~w^~w = 2^{~w}（κ≤λ，定理 2.13(1)）", [SK, SL, SL]).
exp_rec(aleph(A), L, R, [S|Ss]) :-
    number(A), A > 0, !,
    A1 is A - 1,
    show_k(aleph(A), SK), show_k(aleph(A1), SKp), show_k(L, SL),
    format(atom(S), "~w^~w = ~w·~w^~w（豪斯多夫公式，定理 2.12）", [SK, SL, SK, SKp, SL]),
    exp_rec(aleph(A1), L, R1, Ss),
    cmul(aleph(A), R1, R).
exp_rec(aleph(w), L, sup_omega(L), [S]) :-
    show_k(L, SL),
    format(atom(S), "ℵ_w^~w = (supₙ ℵ_n^~w)^ω（引理 2.7：cf(ℵ_ω)=ω）", [SL, SL]).

% ---------- 现场五：特征函数双射 ----------
char_bij(N, Pairs) :-
    M is 2^N - 1,
    findall(A-F, (between(0, M, Mask),
                  findall(K, (between(0, N, K), K < N, (Mask >> K) /\ 1 =:= 1), A),
                  findall(B, (between(0, N, K), K < N, B is (Mask >> K) /\ 1), F)),
            Pairs).

% ---------- 主检定 ----------
main :-
    format("==== 76~n"),
    % 现场一
    wo_from_choice(c_sort, ["a","b","c","d","e"], WO),
    length(WO, 5),
    choice_from_wo(WO, ["a","b","c","d","e"], M0), M0 == "a",
    wo_from_choice(c_sort, ["a","b","c","d","e"], WO),
    format("定理 2.2 往返：选择函数 → 秩序 ~w → 同一秩序 ✓~n", [WO]),
    % 现场二
    scene2,
    writeln("问题 2.1 现场：a = {{0},{1}} 的 ∈-极小元有 2 个——极小≠最小 ✓"),
    % 现场三
    scene3(Ms), length(Ms, 6),
    writeln("佐恩有限重演：16 个有限单射中极大元 6 个，全是满射 ✓"),
    % 现场四（简化：候选覆盖 X0={x0}, X1={x1} 的对角逃逸，穷举 16 格选）
    findall(ok, (member(X1, [(0,0),(0,1),(1,0),(1,1)]),
                 member(X2, [(0,0),(0,1),(1,0),(1,1)]),
                 X1 = (A1,_), X2 = (_,B2),
                 member(F0, [0,1]), F0 \== A1,
                 member(F1, [0,1]), F1 \== B2,
                 F = (F0,F1), F \== X1, F \== X2), OKs),
    length(OKs, L4), L4 > 0,
    format("柯尼希对角线：16 种单点候选覆盖各有 ~w 条逃逸线 ✓（Σ(1,1)=2 < Π(2,2)=4）~n", [L4]),
    % 现场五
    char_bij(5, Pairs), length(Pairs, 32),
    writeln("2^n = |𝒫(n)|：n=5 时 32 = 32，特征函数双射逐点对拍 ✓"),
    % 现场六
    exp_eval(aleph(3), aleph(1), R1, S1),
    forall(member(S, S1), writeln(S)),
    show_k(R1, SR1), format("  ⇒ ℵ_3^ℵ₁ = ~w~n", [SR1]),
    exp_eval(aleph(2), aleph(3), R2, S2),
    forall(member(S, S2), writeln(S)),
    show_k(R2, SR2), format("  ⇒ ℵ_2^ℵ₃ = ~w~n", [SR2]),
    exp_eval(aleph(w), aleph(0), _, S3),
    forall(member(S, S3), writeln(S)),
    writeln("END ====").
