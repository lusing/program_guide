:- encoding(utf8).

% 第 114 章：Solovay 内模型与 HOD(Ω)——群作用、轨道代表（可定义代表
% 搜索）、稳定子、定义交换、配对整合与 DC 链（与 Julia/Python 对拍）。

% ── 一、Z/8 窗口与生成元 ──
u(X) :- between(0, 7, X).
rot(X, Y) :- Y is (X + 2) mod 8.

% ── 二、群作用与轨道（有界四步——轨道递归的地基） ──
% 群 A：k 作用 x ↦ (x + 2k) mod 8。
actA(K, X, Y) :- Y is (X + 2 * K) mod 8.

orbitA(X, Orb) :-
    findall(Y, (u(K), actA(K, X, Y)), Raw),
    sort(Raw, Orb).

stabA(X, St) :-
    findall(K, (u(K), actA(K, X, X)), St).

% 群 B：偶子群 k ∈ {0,2,4,6} 作用 x ↦ (x + k) mod 8。
hb(K) :- member(K, [0, 2, 4, 6]).
actB(K, X, Y) :- Y is (X + K) mod 8.
orbitB(X, Orb) :-
    findall(Y, (hb(K), actB(K, X, Y)), Raw),
    sort(Raw, Orb).

% ── 三、可定义代表：每条轨道的最小元 ──
repA(X, R) :- orbitA(X, Orb), min_list(Orb, R).

% ── 四、参数化谓词与群作用交换（OD 的影子） ──
odef(K, X) :- D is (X - K) mod 8, member(D, [0, 3, 5]).

% ── 五、配对整合与 DC 链 ──
gpair(M, K, G) :- G is M + 8 * K.

% next=rot 的 d 步链。
dchain(_, 0, _, []).
dchain(Next, D, A, [A | T]) :-
    D > 0, D1 is D - 1,
    call(Next, A, B),
    dchain(Next, D1, B, T).

% 相邻对满足「后继 = rot」。
adj_ok([]).
adj_ok([_]).
adj_ok([X, Y | T]) :- rot(X, Y), adj_ok([Y | T]).

% ── 六、HOD 燃料递归（闭包遗传） ──
parts(0, []).
parts(X, [Y]) :- X > 0, Y is X // 2.

inhod(0, _, _).
inhod(D, P, X) :-
    D > 0, D1 is D - 1,
    odef(P, X),
    parts(X, Ps),
    maplist(inhod(D1, P), Ps).

main :-
    % 群 A：拉格朗日 4*2=8 全员。
    forall(u(X), (orbitA(X, O), stabA(X, S),
                  length(O, NO), length(S, NS), NO * NS =:= 8)),
    orbitA(0, O0), O0 = [0, 2, 4, 6],
    stabA(0, S0), S0 = [0, 4],
    % 代表搜索：两条轨道的代表是 0 与 1。
    findall(R, (u(X), repA(X, R)), Rs0), sort(Rs0, [0, 1]),
    % 群 B：轨道为奇偶两类。
    orbitB(1, [1, 3, 5, 7]),
    % 定义交换：512 组全真。
    forall((u(K), u(X), u(J)),
           (odef((K + J) mod 8, (X + J) mod 8) -> odef(K, X) ; \+ odef(K, X))),
    % 不变对象：偶集对 rot 不变；翻转是反例。
    forall(u(X), (rot(X, Y), X mod 2 =:= Y mod 2)),
    7 - 2 =:= 5, 2 mod 2 =\= 5 mod 2,
    % 轨道封闭。
    forall((u(X), orbitB(X, O), member(Y, O), rot(Y, Z)), member(Z, O)),
    % 配对整合：64 值两两不同（窗口单射），解码往返。
    findall(G, (u(M), u(K), gpair(M, K, G)), Gs), sort(Gs, SGs), length(SGs, 64),
    gpair(3, 5, 43), 43 mod 8 =:= 3, 43 // 8 =:= 5,
    % DC 链：8 步链循环 0→2→4→6→0。
    dchain(rot, 8, 0, Ch), Ch = [0, 2, 4, 6, 0, 2, 4, 6], adj_ok(Ch),
    % HOD 燃料：各层成员数 6/2/1/1。
    findall(X, (between(0, 15, X), inhod(1, 0, X)), L1), length(L1, 6),
    findall(X, (between(0, 15, X), inhod(2, 0, X)), L2), length(L2, 2),
    findall(X, (between(0, 15, X), inhod(3, 0, X)), L3), length(L3, 1),
    % 闭包遗传：HOD(d+1) 的组件全落 HOD(d)。
    forall((between(1, 4, D), between(0, 15, X), inhod(D, 0, X)),
           forall((D1 is D - 1, parts(X, Ps), member(Y, Ps)), inhod(D1, 0, Y))),
    format("群A 拉格朗日 4*2=8；代表 [0,1]；定义交换 512 组；偶集不变+翻转反例~n"),
    format("配对整合 64 单射+解码往返；DC 链循环；HOD 燃料 6/2/1/1+闭包遗传~n"),
    writeln("END ====").
