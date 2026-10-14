:- encoding(utf8).
% 第 46 章 预序字典：2^<4 前缀序的稠密/反链/滤子 + 原子事实（Fact 2.2.13）

% ---------- 0-1 有限串 ----------
bits(0).
bits(1).
strings(MaxLen, S) :-
    between(0, MaxLen, N),
    length(S, N),
    maplist(bits, S).

% prefix(X, Y)：X 是 Y 的初始段
prefix([], _).
prefix([B|Xs], [B|Ys]) :- prefix(Xs, Ys).

% Cohen 方向：Q 精化 P ⟺ P 是 Q 的初始段（延拓 = 精化）
refine(Q, P) :- prefix(P, Q).

% 相容：有公共延拓 ⟺ 一方是另一方初始段
compat(X, Y) :- prefix(X, Y).
compat(Y, X) :- prefix(X, Y).
incompat(A, B) :- \+ compat(A, B).

% dense(D)：∀p ∃q∈D, q 精化 p
dense(D) :-
    \+ ( strings(3, P), \+ ( member(Q, D), refine(Q, P) ) ).

% predense(D)：∀p ∃q∈D 与 p 相容
predense(D) :-
    \+ ( strings(3, P), \+ ( member(Q, D), compat(Q, P) ) ).

antichain([]).
antichain([A|Rest]) :- maplist(incompat(A), Rest), antichain(Rest).
max_antichain(A) :- antichain(A), predense(A).

% 滤子：上闭 + 两两有公共精化（这里取"路径的初始段全体"形态）
path_filter(F, G) :-
    findall(S, (prefix(S, F), length(S, L), L =< 3), G).

% ---------- 含原子的小偏序（Fact 2.2.13 的实检） ----------
% P = {e, l, r, z}，le(X,Y) := X ≤ Y（X 精化 Y）；z 是孤立原子
le(z,z).
le(l,e). le(r,e).
le(l,l). le(r,r). le(e,e).

poset4([e,l,r,z]).

dense4(D) :-
    findall(X, member(X,D), _),
    poset4(All),
    \+ ( member(P, All), \+ ( member(Q, D), le(Q,P) ) ).

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 46 预序字典（2^<4 前缀序）~n"),

    % 一、单点前稠密的串：只有空串
    findall([S], (strings(3,S), predense([S])), PD),
    PD = [[[]]],
    format("  单点前稠密：仅 [ ]（空串是万物初始段）✓~n"),

    % 二、长度恰 3 的八个串 = 极大反链
    findall(S, (length(S,3), maplist(bits,S)), L3),
    length(L3, 8),
    max_antichain(L3),
    format("  长度 3 全体（8 串）= 极大反链 ✓~n"),

    % 三、无原子：p 都可劈成 p⌢0 ⊥ p⌢1（Viale Ex 2.2.12）
    \+ ( strings(2, P),
         \+ ( append(P,[0],Q0), append(P,[1],Q1),
              incompat(Q0,Q1), refine(Q0,P), refine(Q1,P) ) ),
    format("  2^<3 无原子：p⌢0 与 p⌢1 互斥精化 ✓~n"),

    % 四、路径滤子 G_f 与三个诚实的稠密集都相交
    F = [0,1,0],
    path_filter(F, G),
    findall(S, (between(2,3,L2), length(S,L2),
                maplist(bits,S)), D_ge2),        % 长度 ≥ 2
    D_len3 = L3,                                   % 长度 3 全体
    findall(S, (between(1,3,L1), length(S,L1),
                maplist(bits,S)), D_ge1),         % 长度 ≥ 1
    dense(D_ge2), dense(D_len3), dense(D_ge1),
    member([0], G), member([0,1], G), member([0,1,0], G),
    det_member([0,1], G), det_member([0,1], D_ge2),
    det_member([0,1,0], G), det_member([0,1,0], D_len3),
    format("  G_{[0,1,0]} 与 D_{≥1}、D_{≥2}、D_len3 三个稠密集全相交 ✓~n"),

    % 五、有限性定理：有限偏序上稠密集必含一切原子
    %    ⟹ 任何滤子自动与一切稠密集相交——泛型性在有限世界是平凡的
    findall(S, (length(S,3), maplist(bits,S)), Atoms),
    findall(D, (subseq(Atoms, D), dense(D)), DenseOnAtoms),
    DenseOnAtoms = [Atoms],       % 稠密集只有一个：全体原子
    format("  有限性：原子层上的稠密集只有 {全体原子}——滤子自动泛型 ✓~n"),
    format("  （Viale Fact 5.1.8 的镜像：泛型性只在无穷/对可数 M 非平凡）~n"),

    % 六、Fact 2.2.13：原子 z ∈ 一切稠密集（穷举全部稠密集验证）
    findall(D, (subset_of_poset4(D), dense4(D)), Ds),
    length(Ds, NDS),
    forall(member(D,Ds), member(z,D)),
    format("  Fact 2.2.13：{e,l,r,z} 的 ~w 个稠密集全部含原子 z ✓~n", [NDS]),

    format("END ===="), nl.

det_member(X, L) :- member(X, L), !.

count_ones([], 0).
count_ones([1|T], N1) :- count_ones(T, N), N1 is N + 1.
count_ones([0|T], N) :- count_ones(T, N).

% 子序列枚举（幂集）
subseq([], []).
subseq([_|T], S) :- subseq(T, S).
subseq([H|T], [H|S]) :- subseq(T, S).

subset_of_poset4(D) :- poset4(All), subseq(All, D).
