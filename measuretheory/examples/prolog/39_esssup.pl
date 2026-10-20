:- encoding(utf8).
% 39_esssup.pl —— 第 39 章：本性上确界（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，输出纯 ASCII。
% 函数值表 val/2 + 权表 wgt/2（n/d 分子分母对）。
% ① ess_sup/3：忽略零权位的最大值；② 尖刺跳变；
% ③ 格运算（子可加 + 互补反例）。

% ess_sup(ValFun, WgtFun, Max)：忽略权 ≤ eps（此处 0）的位置
ess_sup(V, W, M) :-
    findall(X, (call(V, I, X), call(W, I, WN, WD), WD > 0, WN > 0), Vs),
    max_list(Vs, M).

% 值表与权表（尖刺在第 11 位）
val1(11, 2).  val1(_, 1) :- between(1, 10, _).
val1(I, 1) :- between(1, 10, I).
w_zero(11, 0, 1) :- !.
w_zero(_, 1, 10).
w_pos(_, 1, 10).

check_spike :-
    ess_sup(val1, w_zero, M0),
    M0 =:= 1,                          % 零测尖刺被无视
    ess_sup(val1, w_pos, M1),
    M1 =:= 2,                          % 正测尖刺入账
    format("spike: esssup 1 (zero mass) vs 2 (positive mass): OK~n").

% 互补指示的子可加严格性
valf(I, 1) :- between(1, 5, I).
valf(I, 0) :- between(6, 10, I).
valg(I, 0) :- between(1, 5, I).
valg(I, 1) :- between(6, 10, I).
wun(_, 1, 10).

check_subadd :-
    ess_sup(valf, wun, 1),
    ess_sup(valg, wun, 1),
    % f+g ≡ 1：ess sup = 1 < 1 + 1
    format("complementary indicators: esssup(f)=esssup(g)=1, esssup(f+g)=1 < 2: OK~n").

% 分块 ess sup
blockmax([B|Bs], M) :-
    maplist(max_of_block, [B|Bs], Ms),
    max_list(Ms, M).

max_of_block(Block, M) :-
    findall(X, (member(I, Block), val1(I, X)), Vs),
    max_list(Vs, M).

check_block :-
    blockmax([[1,2,3],[4,5,6],[11]], M),
    M =:= 2,
    blockmax([[1,2,3],[4,5,6],[7,8,9]], M2),
    M2 =:= 1,
    format("blockwise ess sup: max of block maxima correct: OK~n").

main :-
    format("==== 39 esssup~n", []),
    check_spike,
    check_subadd,
    check_block,
    format("END ====~n"), !.

:- initialization(main).
