:- encoding(utf8).
:- discontiguous cond/1.
% ============================================================
%  25 λD 中的数学 —— Prolog 有限模型对照（TTAFP ch.12–13）
%    把 25 章的定义放在【有限具体结构】上过秤：
%      · 偏序：≤ 的运算表（0..3 上的 ≤、一个违反反对称的坏表）
%      · Least 的存在/唯一（Lemma 12.1.2 的有限版：反对称 ⇒ 唯一）
%      · 子集即谓词：位向量上的 Cap/Cup/Compl，De Morgan 逐点验证
%      · 映射 = 泛关系：∀x 恰一 y（好表 vs 坏表）；单射表检验
%    与 15 章（Farmer 轮）的结构枚举机同宗——定义的「内容」在
%    有限世界里变成可穷举的布尔。
% ============================================================

% ---------- 域与关系表 ----------
% le(N, X, Y)：0..N-1 上的自然 ≤
le_lt(N, X, Y) :- X >= 0, Y < N, X =< Y.
le4(X, Y) :- le_lt(4, X, Y).      % 闭包版：0..3 上的 ≤

% 坏表：N=2 上 0≤1 且 1≤0 但 0≠1——违反反对称
le_bad(0, 0). le_bad(0, 1). le_bad(1, 0). le_bad(1, 1).

% ---------- 序公理 ----------
refl(N, R) :- A is N - 1,
    forall(between(0, A, X), call(R, X, X)).
antisym(N, R) :- A is N - 1,
    forall((between(0, A, X), between(0, A, Y), call(R, X, Y), call(R, Y, X)),
           X == Y).
trans(N, R) :- A is N - 1,
    forall((between(0, A, X), between(0, A, Y), between(0, A, Z),
            call(R, X, Y), call(R, Y, Z)),
           call(R, X, Z)).

po(N, R) :- refl(N, R), antisym(N, R), trans(N, R).

% ---------- Least（Figure 12.13）与 Lemma 12.1.2 ----------
least(N, R, M) :- A is N - 1,
    between(0, A, M), forall(between(0, A, X), call(R, M, X)), !.

% 引理 12.1.2 的有限版：反对称 ⇒ 最小元若存在则唯一
least_unique_under_antisym(N, R) :-
    A is N - 1,
    antisym(N, R),
    ( setof(M, (between(0, A, M), forall(between(0, A, X), call(R, M, X))), Ms)
    -> length(Ms, L), L =< 1 ; true ).

% ---------- 子集即谓词：位向量 ----------
% 子集 = 0/1 表；Cap/Cup/Compl 逐点
mem([B|_], 0, B).
mem([_|Bs], X, B) :- X > 0, X1 is X - 1, mem(Bs, X1, B).

capv([], [], []).
capv([A|As], [B|Bs], [C|Cs]) :- C is A /\ B, capv(As, Bs, Cs).
cupv([], [], []).
cupv([A|As], [B|Bs], [C|Cs]) :- C is A \/ B, cupv(As, Bs, Cs).
complv([], []).
complv([A|As], [C|Cs]) :- C is 1 - A, complv(As, Cs).

% De Morgan：compl(cap(V,W)) 与 cup(compl V, compl W) 全坐标相等
demorgan(V, W) :-
    capv(V, W, I), complv(I, L),
    complv(V, CV), complv(W, CW), cupv(CV, CW, R),
    L == R.

cap_comm(V, W) :- capv(V, W, L), capv(W, V, R), L == R.

% ---------- 映射 = 泛关系（Figure 13.13） ----------
% F 用表给出：f(X, Y) 事实；IsMap：每个 x 恰有一个 y
is_map(N, F) :- A is N - 1,
    forall(between(0, A, X),
           ( findall(Y, (between(0, A, Y), call(F, X, Y)), Ys),
             length(Ys, 1) )).

% 单射：不同原像不同像
inj_table(N, F) :- A is N - 1,
    forall((between(0, A, X), between(0, A, Y), X < Y,
            call(F, X, AX), call(F, Y, AY)),
           AX =\= AY).

% 好映射：0↦1, 1↦0, 2↦3, 3↦2（对换——单射）
good_f(0, 1). good_f(1, 0). good_f(2, 3). good_f(3, 2).
% 坏映射：0↦1, 1↦1, 2↦3, 3↦2（0 与 1 同像——非单射）
bad_f(0, 1). bad_f(1, 1). bad_f(2, 3). bad_f(3, 2).
% 非映射：0 无像
nonmap(1, 2). nonmap(2, 3). nonmap(3, 2).

% ============================================================
%  电池（12 条）
% ============================================================

chk(1,  '0..3 上的 ≤ 是偏序（refl+antisym+trans）').
chk(2,  'NEG：le_bad 违反反对称——被拒').
chk(3,  'Least：0..3 上 ≤ 的最小元 = 0').
chk(4,  'Lemma 12.1.2 有限版：反对称 ⇒ 最小元至多一个').
chk(5,  '坏表的「最小元」可以有两个——反对称缺位时引理失效').
chk(6,  '位向量 De Morgan：compl(V∩W) = complV ∪ complW（4 位全查）').
chk(7,  'Cap 交换律（位向量）').
chk(8,  'good_f 是映射（每 x 恰一像）').
chk(9,  'good_f 单射').
chk(10, 'NEG：bad_f 非单射（0 与 1 同像）——被拒').
chk(11, 'NEG：nonmap 不是映射（0 无像）——被拒').
chk(12, '位向量 De Morgan 全枚举：4 位 V、W 全部 16×16 组合').

cond(1) :- po(4, le4).
cond(2) :- \+ antisym(2, le_bad).
cond(3) :- least(4, le4, 0).
cond(4) :- least_unique_under_antisym(4, le4).
cond(5) :- findall(M, (between(0, 1, M), forall(between(0, 1, X), le_bad(M, X))), Ms),
           length(Ms, 2).          % le_bad 上 0 与 1 都「最小」
cond(6) :- demorgan([1,0,1,0], [0,1,1,0]).
cond(7) :- cap_comm([1,0,1,0], [0,1,1,0]).
cond(8) :- is_map(4, good_f).
cond(9) :- inj_table(4, good_f).
cond(10) :- \+ inj_table(4, bad_f).
cond(11) :- \+ is_map(4, nonmap).
cond(12) :-
    findall(V, (between(0, 15, B), bits4(B, V)), Vs),
    forall((member(V, Vs), member(W, Vs)), demorgan(V, W)).

bits4(B, [A,B1,C,D]) :-
    A is (B >> 3) /\ 1, B1 is (B >> 2) /\ 1,
    C is (B >> 1) /\ 1, D is B /\ 1.

main :-
    ( between(1, 12, I), chk(I, What), \+ cond(I) ->
        format('FAIL ~d ~w~n', [I, What]), halt(1)
    ; true ),
    !,
    format('12 条全过~n'),
    halt.
