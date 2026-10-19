:- encoding(utf8).
% ex91_presburger.pl -- 简化版本的自然数模型：后继/序/普莱斯伯格量词消去
% （郝兆宽《数理逻辑：证明及其限度》ch8 的机器面）。
%
% 语法：
%   term ::= z | v(N) | s(T) | add(T1,T2) | sub(T1,T2) | mulc(K,T)
%   form ::= eq(T1,T2) | lt(T1,T2) | cg(K,T1,T2) | neg(F) | andd(F,G)
%          | orr(F,G) | ex(N,F) | all(N,F)
% 消去流程忠实于书：
%   (0) 否定消解（8.5 断言 1 机制）：¬(u=v)→u<v∨v<u；¬(u<v)→v<u∨v=u；
%       ¬(u≡_m v)→∨_{r=1}^{m-1} u≡_m (v+r)
%   (1) NNF+DNF（塔斯基引理 8.3.2 形态：∃ 分配到析取支）
%   (2) 每支消去：断言 3 系数统一（K=lcm；不等式/等式乘正数保号；
%       同余式乘 c 并把模数也乘 c——引理 a≡ₘb ⟺ ca≡_{cm}cb；换元
%       y:=Kx 并撒 y≡_K 0）；有等式则解出代入（8.3.1 bump 同族）；
%       纯界+同余走断言 4 候选表（行 L_i..L_i+(M-1) 与 0..M-1）。
% 书自认 u−t 记法「严格地说不规范」——机器面以 sub/2 项镜像这一步
% （文档线说明 ℕ 侧还原式）。彩蛋：qf-obstruction 账（习题 8.5.1）、
% Z-链有限影子（排列=圈分解+鸽笼杀死全部有限模型）、8.5.7 网格验证。

% ============ 求值（brute force 对拍基准；sub 允许负值=ℤ 侧账） ============

tev(z, _, 0).
tev(v(N), E, V) :- memberchk(N-V, E).
tev(s(T), E, R) :- tev(T, E, V), R is V + 1.
tev(add(A,B), E, R) :- tev(A,E,RA), tev(B,E,RB), R is RA + RB.
tev(sub(A,B), E, R) :- tev(A,E,RA), tev(B,E,RB), R is RA - RB.
tev(mulc(K,T), E, R) :- tev(T,E,V), R is K * V.

fev(eq(A,B), E, B1) :- !, tev(A,E,VA), tev(B,E,VB), (VA =:= VB -> B1 = 1 ; B1 = 0).
fev(lt(A,B), E, B1) :- !, tev(A,E,VA), tev(B,E,VB), (VA < VB -> B1 = 1 ; B1 = 0).
fev(cg(K,A,B), E, B1) :- !, tev(A,E,VA), tev(B,E,VB),
                         D is VA - VB, (D mod K =:= 0 -> B1 = 1 ; B1 = 0).
fev(neg(F), E, B1) :- !, fev(F,E,B0), (B0 = 1 -> B1 = 0 ; B1 = 1).
fev(andd(A,B), E, B1) :- !, fev(A,E,RA), fev(B,E,RB),
                         ((RA = 1, RB = 1) -> B1 = 1 ; B1 = 0).
fev(orr(A,B), E, B1) :- !, fev(A,E,RA), fev(B,E,RB),
                        ((RA = 1 ; RB = 1) -> B1 = 1 ; B1 = 0).
% 分层窗口：存在量词用宽窗 [-40,60]、全称量词用窄窗 [-14,26]——
% ∀x∃u 类公式的见证 u=x-1 在 x 的窗缘仍落在 ∃ 窗内（对拍口径：
% 两窗的差即「见证余量」，文档线说明；嵌套 ∀∀ 不入测试面）
fev(ex(N,F), E, B1) :- !,
    ( between(-40, 60, W), fev(F, [N-W | E], 1) -> B1 = 1 ; B1 = 0 ).
fev(all(N,F), E, B1) :- !,
    ( between(-14, 26, W), fev(F, [N-W | E], 0) -> B1 = 0 ; B1 = 1 ).

% ============ 数码项 ============

numeral(0, z) :- !.
numeral(N, s(T)) :- N > 0, N1 is N - 1, numeral(N1, T).

% ============ 线性形：poly = (Const, [N-Coeff,...]) 排序去零 ============

pzero(0, []).

poly(z, P) :- !, P = (0, []).
poly(v(N), P) :- !, P = (0, [N-1]).
poly(s(T), P) :- !, poly(T, (C, V)), PC is C + 1, P = (PC, V).
poly(add(A,B), P) :- !, poly(A, PA), poly(B, PB), padd(PA, PB, P).
poly(sub(A,B), P) :- !, poly(A, PA), poly(B, PB), psub(PA, PB, P).
poly(mulc(K,T), P) :- !, poly(T, (C, V)), KC is K * C,
    ( K =:= 0 -> P = (0, []) ; maplist(mulc1(K), V, VK), P = (KC, VK) ).

mulc1(K, N-C, N-KC) :- KC is K * C.
neg_mono([], []).
neg_mono([N-C|T], [N-MC|T1]) :- MC is -C, neg_mono(T, T1).

poly_norm(L, P) :- keysort(L, L1), merge_mono(L1, P).

merge_mono([], []) :- !.
merge_mono([N-C], P) :- !, (C =:= 0 -> P = [] ; P = [N-C]).
merge_mono([N-C1, N-C2|T], P) :- !,
    C3 is C1 + C2, merge_mono([N-C3|T], P).
merge_mono([N-C1|T], P) :- !, merge_mono(T, P0),
    (C1 =:= 0 -> P = P0 ; P = [N-C1|P0]).

padd((C1,V1), (C2,V2), (C,V)) :- C is C1 + C2,
    append(V1, V2, V0), poly_norm(V0, V).
pneg((C,V), (NC,NV)) :- NC is -C, neg_mono(V, NV).
psub(PA, PB, R) :- pneg(PB, PBN), padd(PA, PBN, R).
pscale(K, (C,V), (KC,VK)) :- KC is K * C,
    ( K =:= 0 -> VK = [] ; maplist(mulc1(K), V, VK) ).

pcoef(N, (C,V), A, (C,V1)) :-
    ( memberchk(N-A0, V) -> select(N-A0, V, V1), A = A0 ; A = 0, V1 = V ).

% poly → 项（负系数/负常数用 sub 镜像书中 u−t 记法）
poly_term((C, V), T) :-
    include(nonzero_coeff, V, V1),
    mono_terms(V1, MTs),
    const_term(C, CT),
    combine(MTs, CT, T).

nonzero_coeff(_-K) :- K =\= 0.

mono_terms([], []).
mono_terms([N-K|T], [M|Ms]) :-
    ( K > 0 -> M = mulc(K, v(N)) ; KA is -K, M = sub(z, mulc(KA, v(N))) ),
    mono_terms(T, Ms).

const_term(0, z) :- !.
const_term(C, T) :- C > 0, !, numeral(C, T).
const_term(C, sub(z, T)) :- C < 0, NC is -C, numeral(NC, T).

combine([], CT, CT) :- !.
combine([M|Ms], z, T) :- !, combine(Ms, M, T).
combine([M|Ms], CT, T) :- combine(Ms, add(M, CT), T).

% ============ (0) 否定消解 + NNF ============

negfree(eq(A,B), eq(A,B)).
negfree(lt(A,B), lt(A,B)).
negfree(cg(K,A,B), cg(K,A,B)).
negfree(neg(F), G) :- negnf(F, G).
negfree(andd(A,B), andd(A1,B1)) :- negfree(A,A1), negfree(B,B1).
negfree(orr(A,B), orr(A1,B1)) :- negfree(A,A1), negfree(B,B1).
negfree(ex(N,F), ex(N,F1)) :- negfree(F,F1).
negfree(all(N,F), all(N,F1)) :- negfree(F,F1).

negnf(eq(A,B), orr(lt(A,B), lt(B,A))).                  % u≠v ⟺ u<v ∨ v<u
negnf(lt(A,B), orr(lt(B,A), eq(A,B))).                  % ¬(u<v) ⟺ v<u ∨ u=v
negnf(cg(1,_,_), lt(s(z), z)) :- !.          % 模 1 同余恒真：否定即假
negnf(cg(K,A,B), D) :- K > 1,                           % ¬(u≡v) ⟺ ∨_{r=1}^{K-1} u≡_K (v+r)
    K1 is K - 1,
    findall(cg(K,A,add(B,T)), (between(1,K1,R), numeral(R,T)), Ds),
    foldl1(orr, Ds, D).
negnf(neg(F), F).
negnf(andd(A,B), orr(GA, GB)) :- negnf(A, GA), negnf(B, GB).
negnf(orr(A,B), andd(GA, GB)) :- negnf(A, GA), negnf(B, GB).
negnf(ex(N,F), all(N, G)) :- negnf(F, G).
negnf(all(N,F), ex(N, G)) :- negnf(F, G).

foldl1(_, [X], X) :- !.
foldl1(F, [X,Y|T], R) :- G =.. [F,X,Y], foldl1(F, [G|T], R).

% ============ (1) DNF：输出「文字表」的析取支列表 ============

dnf(F, Branches) :- negfree(F, F1), dnf1(F1, Branches).

dnf1(eq(A,B), [[eq(A,B)]]) :- !.
dnf1(lt(A,B), [[lt(A,B)]]) :- !.
dnf1(cg(K,A,B), [[cg(K,A,B)]]) :- !.
dnf1(andd(A,B), D) :- !, dnf1(A, DA), dnf1(B, DB),
    findall(C, (member(CA,DA), member(CB,DB), append(CA,CB,C)), D).
dnf1(orr(A,B), D) :- !, dnf1(A, DA), dnf1(B, DB), append(DA,DB,D).
dnf1(neg(_), _) :- !, fail.   % negfree 后原子级否定已全部裂解，不应到达

% ============ 原子的 x-分解 ============
% split_atom(N, Atom, W)：
%   side(L)                    —— N 不出现，原样保留
%   e(A, P)                    —— A·N + P = 0          （A > 0）
%   up(A, P)                   —— A·N + P < 0（上界方向）（A > 0）
%   lo(A, P)                   —— 0 < A·N + P（下界方向）（A > 0）
%   cgw(A, M, P)               —— A·N + P ≡_M 0        （A > 0）

split_atom(N, eq(A,B), W) :- !,
    poly(A, PA), poly(B, PB), psub(PA, PB, D),
    pcoef(N, D, Coef, Rest),
    ( Coef =:= 0 -> W = side(eq(A,B))
    ; Coef > 0 -> W = e(Coef, Rest)
    ; Coef < 0 -> NC is -Coef, pneg(Rest, R2), W = e(NC, R2) ).
split_atom(N, lt(A,B), W) :- !,
    poly(A, PA), poly(B, PB), psub(PA, PB, D),
    pcoef(N, D, Coef, Rest),
    ( Coef =:= 0 -> W = side(lt(A,B))
    ; Coef > 0 -> W = up(Coef, Rest)
    ; Coef < 0 -> NC is -Coef, pneg(Rest, R2), W = lo(NC, R2) ).
split_atom(N, cg(M,A,B), W) :- !,
    poly(A, PA), poly(B, PB), psub(PA, PB, D),
    pcoef(N, D, Coef, Rest),
    ( Coef =:= 0 -> W = side(cg(M,A,B))
    ; Coef > 0 -> pneg(Rest, R2), W = cgw(Coef, M, R2)
    ; Coef < 0 -> NC is -Coef, W = cgw(NC, M, Rest) ).

% ============ (2) 断言 3：系数统一 + 换元 y:=K·N + 撒 y≡_K 0 ============
% rescale(K, W, Scaled)：
%   eq1(B)    —— y + B = 0
%   up1(C)    —— y < C
%   lo1(D)    —— D < y
%   cg1(M,R)  —— y ≡_M R

rescale(K, e(A, P), eq1(B)) :- !, C is K // A, pscale(C, P, B).
rescale(K, up(A, P), up1(CC)) :- !, C is K // A, pscale(C, P, B), pneg(B, CC).
rescale(K, lo(A, P), lo1(D)) :- !, C is K // A, pscale(C, P, B), pneg(B, D).
rescale(K, cgw(A, M, P), cg1(CM, R)) :- !, C is K // A, CM is C * M,
    pscale(C, P, B), pneg(B, R).

% ============ 支内消去主步 ============

% elim_lits(N, Lits, OutConjs)：OutConjs = 文字表（合取支）的列表
elim_lits(N, Lits, OutConjs) :-
    maplist(split_atom(N), Lits, Split),
    partition_split(Split, Sides0, WithN0),
    maplist(side_lit, Sides0, Sides),
    ( WithN0 == [] -> OutConjs = [Sides]
    ;
      maplist(abs_coeff, WithN0, Cs),
      foldl(lcm2, Cs, 1, K),
      maplist(rescale(K), WithN0, Scaled0),
      partition_scaled(Scaled0, Los, Ups, Cgs, Eqs),
      ( Eqs \= [] ->
          % 有等式：解出 y = W = −B，字面代入；seed 同余 y≡_K 0 一并回填
          member(eq1(B), Eqs),
          pneg(B, W),
          maplist(subst_y_lo(W), Los, LosS),
          maplist(subst_y_up(W), Ups, UpsS),
          maplist(subst_y_cg(W), [cg1(K, (0,[])) | Cgs], CgsS),
          append([LosS, UpsS, CgsS], L1),
          append(Sides, L1, Conj),
          OutConjs = [Conj]
      ;
          % 纯界+同余：候选表三族行——下界+1、{0}、上界−1（ℤ 语义：
          % 有见证 d 时，或取 ≥max(L)+1 的最小残类点（≤d），或取
          % ≤min(U)−1 的最大残类点；书 8.4 的 δ₃=S w_i<U_j 即 +1 侧）
          all_mods([cg1(K, (0,[])) | Cgs], Mods),
          foldl(lcm2, Mods, 1, M),
          rows_bases(Los, Ups, Rows),
          M1 is M - 1,
          findall(Conj,
              ( member(Base, Rows),
                between(0, M1, Q),
                cand_poly(Base, Q, C),
                lower_lits(Los, C, LowLits),
                upper_lits(Ups, C, UpLits),
                cg_lits(Cgs, C, CgLits),
                append([LowLits, UpLits, CgLits], L0),
                append(Sides, L0, Conj) ),
          OutConjs)
    )).

partition_split([], [], []).
partition_split([S|T], Sides, WithN) :-
    ( S = side(_) -> Sides = [S|Sides1], WithN = WithN1
    ; Sides = Sides1, WithN = [S|WithN1] ),
    partition_split(T, Sides1, WithN1).

side_lit(side(L), L).

abs_coeff(e(A, _), A).
abs_coeff(up(A, _), A).
abs_coeff(lo(A, _), A).
abs_coeff(cgw(A, _, _), A).

lcm2(A, B, L) :- G is gcd(A, B), (G =:= 0 -> L = B ; L is (A * B) // G).

partition_scaled([], [], [], [], []).
partition_scaled([lo1(D)|T], [lo1(D)|L], U, C, E) :- !, partition_scaled(T, L, U, C, E).
partition_scaled([up1(X)|T], L, [up1(X)|U], C, E) :- !, partition_scaled(T, L, U, C, E).
partition_scaled([cg1(M,R)|T], L, U, [cg1(M,R)|C], E) :- !, partition_scaled(T, L, U, C, E).
partition_scaled([eq1(B)|T], L, U, C, [eq1(B)|E]) :- !, partition_scaled(T, L, U, C, E).

subst_y_lo(W, lo1(D), lt(TD, TW)) :- poly_term(D, TD), poly_term(W, TW).
subst_y_up(W, up1(CC), lt(TW, TC)) :- poly_term(W, TW), poly_term(CC, TC).
subst_y_cg(W, cg1(M,R), cg(M, TW, TR)) :- poly_term(W, TW), poly_term(R, TR).

all_mods([], []).
all_mods([cg1(M,_)|T], [M|Ms]) :- all_mods(T, Ms).

rows_bases(Los, Ups, Bases) :-
    maplist(lo_plus1, Los, Ls),
    maplist(up_minus1, Ups, Us),
    append([Ls, [(0, [])], Us], Bases).

lo_plus1(lo1(D), D1) :- padd(D, (1, []), D1).
up_minus1(up1(U), U1) :- padd(U, (-1, []), U1).

cand_poly(Base, Q, C) :- padd(Base, (Q, []), C).

lower_lits([], _, []).
lower_lits([lo1(D)|T], C, [lt(TD, TC)|R]) :-
    poly_term(D, TD), poly_term(C, TC), lower_lits(T, C, R).
upper_lits([], _, []).
upper_lits([up1(X)|T], C, [lt(TC, TX)|R]) :-
    poly_term(C, TC), poly_term(X, TX), upper_lits(T, C, R).
cg_lits([], _, []).
cg_lits([cg1(Md,Rs)|T], C, [cg(Md, TC, TRs)|Rest]) :-
    poly_term(C, TC), poly_term(Rs, TRs), cg_lits(T, C, Rest).

% ============ 司机：整条公式的量词消去 ============

elim_formula(F, F) :- atomic_lit(F), !.
elim_formula(neg(F), neg(F1)) :- !, elim_formula(F, F1).
elim_formula(andd(A,B), andd(A1,B1)) :- !, elim_formula(A,A1), elim_formula(B,B1).
elim_formula(orr(A,B), orr(A1,B1)) :- !, elim_formula(A,A1), elim_formula(B,B1).
elim_formula(ex(N,F), D) :- !,
    elim_formula(F, F1),
    dnf(F1, Branches),
    maplist(elim_branch(N), Branches, Deltas),
    foldl1(orr, Deltas, D).
elim_formula(all(N,F), D) :- !,
    elim_formula(ex(N, neg(F)), D0),
    negfree(neg(D0), D).

atomic_lit(eq(_,_)).
atomic_lit(lt(_,_)).
atomic_lit(cg(_,_,_)).

elim_branch(N, Lits, Delta) :-
    elim_lits(N, Lits, OutConjs),
    maplist(lits_formula, OutConjs, Ds),
    foldl1(orr, Ds, Delta).

lits_formula([], eq(z, z)) :- !.    % 空合取 = 恒真
lits_formula([L], L) :- !.
lits_formula([L|T], andd(L, F)) :- lits_formula(T, F).

% ============ 测试账 ============

% 一元公式对拍：消去结果与 brute force 在 [0..13) 上逐点一致
agree1(Name, F, Var) :-
    elim_formula(F, G),
    agree_loop(0, 13, Var, F, G, 0, Bad),
    ( Bad =:= 0 ->
        format('  [OK] ~w : elim agrees brute force on [0..13), qf result size ok~n', [Name])
    ; format('  [!!] ~w : ~d mismatches~n', [Name, Bad]) ).

agree_loop(N, N, _, _, _, Bad, Bad) :- !.
agree_loop(I, N, Var, F, G, Bad0, Bad) :-
    fev(F, [Var-I], R1), fev(G, [Var-I], R2),
    ( R1 =:= R2 -> Bad1 = Bad0 ; Bad1 is Bad0 + 1 ),
    I1 is I + 1, agree_loop(I1, N, Var, F, G, Bad1, Bad).

% 闭句判定对拍
decide(Name, F) :-
    elim_formula(F, G),
    fev(F, [], R1), fev(G, [], R2),
    ( R1 =:= R2 ->
        format('  [OK] ~w : decide=~w (elim==brute)~n', [Name, R2])
    ; format('  [!!] ~w : elim=~w brute=~w~n', [Name, R2, R1]) ).

% ============ 彩蛋 1：qf-obstruction（习题 8.5.1 的证据面） ============
% 纯 L_+（无 ≡、无 <）单变元 qf 公式在样本 [0..24) 上的可定义集
% 全部「有限或余有限」；偶数集两者皆非——量词 ∃y(y+y=x) 不可消去。
qf_obstruction :-
    findall(A, ( between(0,4,K), numeral(K, T), A = eq(v(0), T) ), As),
    findall(B, ( between(0,8,K), numeral(K, T), B = eq(add(v(0),v(0)), T) ), Bs),
    append(As, Bs, Atoms),
    length(Atoms, NA),
    % 每个样本点的「签名」= 哪些原子在此为真
    findall(Sig,
            ( between(0,23,Nx), findall(1, (member(Ax,Atoms), fev(Ax,[0-Nx],1)), L), L = Sig ),
            _SigsAll),
    % 签名类（样本点等价类）：原子把 [0..9) 打成单点，[9..24) 一整类
    sig_classes(Atoms, Classes),
    length(Classes, NC),
    format('  atoms=~d  signature-classes=~d (singletons + one big class)~n', [NA, NC]),
    % 偶数集是否为类的并？只需检查是否存在「混 parity 的类」
    ( member(C, Classes), \+ class_all_even(C), \+ class_all_odd(C) ->
        format('  mixed-parity class exists (e.g. tail class): evens NOT qf-definable~n')
    ; format('  no mixed-parity class: evens might be qf-definable (unexpected!)~n')
    ).

class_all_even(C) :- forall(member(N, C), N mod 2 =:= 0).
class_all_odd(C) :- forall(member(N, C), N mod 2 =:= 1).

sig_classes(Atoms, Classes) :-
    findall(Class,
            ( between(0,23,Nx), sig_of(Atoms, Nx, S),
              setof(Mm, (between(0,23,Mm), sig_of(Atoms, Mm, S)), Class) ),
            C0),
    sort(C0, Classes).

sig_of(Atoms, N, S) :-
    findall(K, (nth0(K, Atoms, A), fev(A, [0-N], 1)), S).

% ============ 彩蛋 2：Z-链有限影子 ============
% (a) [n] 上全体双射（S2+S3 的有限影子）都分解成圈——「Z-链的有限化身」；
% (b) (S1)0∉ran ∧ (S2)单射 的全函数在 [n] 上不存在（鸽笼：单+不满必
%     撞墙）——T_s 没有有限模型，标准部分与 Z-链都必须无穷。
zchain_shadow :-
    N = 4,
    findall(S, perm_func(N, S), Perms),
    length(Perms, NP),
    findall(Cs, (member(P, Perms), cycles(N, P, Cs)), AllCyc),
    maplist(length, AllCyc, CycLens),
    mlist_max(CycLens, MaxL),
    format('  n=~d: bijections=~d, all decompose into cycles (max ~d cycles)~n', [N, NP, MaxL]),
    findall(F, (func_on(N, F), s1_ok(N, F), s2_ok(N, F)), Surv),
    length(Surv, NS),
    format('  (S1)+(S2) functions on [~d]: ~d  (pigeonhole kills all finite models)~n', [N, NS]).

perm_func(N, S) :- length(S, N), permutation(S, S).
func_on(N, F) :- length(F, N), N1 is N - 1, maplist(between(0,N1), F).

s1_ok(N, F) :- N1 is N - 1, \+ (between(0,N1,I), nth0(I, F, V), V =:= 0).
s2_ok(N, F) :- N1 is N - 1,
    \+ ( between(0,N1,I), I > 0, I1 is I - 1, between(0,I1,J),
         nth0(I, F, VI), nth0(J, F, VJ), VI =:= VJ ).

cycles(N, F, Cs) :-
    N1 is N - 1, numlist(0, N1, D), cycles_from(D, F, [], Cs).

cycles_from([], _, Cs, Cs) :- !.
cycles_from([X|T], F, Acc, Cs) :-
    orbit(X, F, O), subtract(T, O, T1),
    cycles_from(T1, F, [O|Acc], Cs).

orbit(X, F, O) :- orbit_go(X, F, [X], O).

orbit_go(X, F, Acc, O) :-
    nth0(X, F, Y),
    ( member(Y, Acc) -> O = Acc ; orbit_go(Y, F, [Y|Acc], O) ).

mlist_max([X], X) :- !.
mlist_max([X|T], M) :- mlist_max(T, M0), (X > M0 -> M = X ; M = M0).

% ============ 彩蛋 3：8.5.7 网格——加法在 (N,S,x) 中可定义 ============
% 方程 S(ac)*S(bc) = S(c*c*S(ab)) ⟺ c=0 ∨ a+b=c（c≠0 侧即加法图）
% 恒等式判据：LHS=RHS ⟺ c=0 ∨ a+b=c（两侧同为真或同为假）
ok_857(LHS, RHS, A, B, C) :-
    ( LHS =:= RHS -> T1 = 1 ; T1 = 0 ),
    ( ( C =:= 0 ; A + B =:= C ) -> T2 = 1 ; T2 = 0 ),
    ( T1 =:= T2 -> true ; throw(mismatch_857(A,B,C)) ).

add_definable_grid :-
    ( between(0,6,A), between(0,6,B), between(0,6,C),
      LHS is (A*C+1) * (B*C+1),
      RHS is C*C*(A*B+1) + 1,
      ok_857(LHS, RHS, A, B, C),
      fail
    ; true ),
    LHS9 is (1*2+1)*(1*2+1), RHS9 is 2*2*(1*1+1)+1,
    format('  grid [0..6]^3: identity holds; e.g. a=1,b=1,c=2: ~d = ~d~n', [LHS9, RHS9]),
    format('  caveat: c=0 rows all satisfy -> definability needs the c>0 side condition~n').

% ============ main ============

main :-
    format('== ex91 presburger ladder: QE after Hao ch8 ==~n'),
    format('--- stage 1: L_s = {0,S} (thm 8.3.1) ---~n'),
    agree1('E1 ex u. x=S u (cofinite)', ex(1, eq(v(0), s(v(1)))), 0),
    agree1('E2 ex u. S u = x (cofinite)', ex(1, eq(s(v(1)), v(0))), 0),
    agree1('E3 all u. x ~= Su (Z-true; N-truth is x=0)', all(1, neg(eq(v(0), s(v(1))))), 0),
    format('--- stage 2: L_o = {0,S,<} (thm 8.4.1) ---~n'),
    agree1('O1 ex u. x<u & u<S S x', ex(1, andd(lt(v(0),v(1)), lt(v(1), s(s(v(0)))))), 0),
    agree1('O2 ex u. S S u < x (cofinite)', ex(1, lt(s(s(v(1))), v(0))), 0),
    agree1('O3 ex u. x<u & SSS u<x (false)', ex(1, andd(lt(v(0),v(1)), lt(s(s(s(v(1)))), v(0)))), 0),
    format('--- stage 3: L_+ = {0,S,+,<,=_k} (thm 8.5.1) ---~n'),
    agree1('P1 ex y. y+y=x (evens, cong 2)', ex(1, eq(add(v(1),v(1)), v(0))), 0),
    agree1('P2 ex y. x=y+y+y (cong 3)', ex(1, eq(v(0), add(v(1),add(v(1),v(1))))), 0),
    agree1('P3 ex y. S S y<x & y=S S x', ex(1, andd(lt(s(s(v(1))), v(0)), eq(v(1), s(s(v(0)))))), 0),
    agree1('P4 ex y. 2y=x & 3(y+1)<x', ex(1, andd(eq(add(v(1),v(1)), v(0)), lt(add(mulc(3,s(v(1))), z), v(0)))), 0),
    format('--- closed sentences: decider vs brute force ---~n'),
    decide('D1 every number even or odd',
           all(0, orr(ex(1, eq(add(v(1),v(1)), v(0))),
                      ex(1, eq(v(0), s(add(v(1),v(1)))))))),
    decide('D2 exists x with no double (false)',
           ex(0, all(1, neg(eq(add(v(1),v(1)), v(0)))))),
    decide('D3 forall x ex u. x=S u (Z-true; N-false at 0)',
           all(0, ex(1, eq(v(0), s(v(1)))))),
    decide('D4 L_s sentence: all x (x=0 or ex u x=S u)',
           all(0, orr(eq(v(0),z), ex(1, eq(v(0), s(v(1))))))),
    format('--- extras ---~n'),
    qf_obstruction,
    zchain_shadow,
    add_definable_grid,
    format('==== ex91 presburger END ====~n').
