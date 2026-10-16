:- encoding(utf8).
:- discontiguous cond/1.
% ============================================================
%  24 旗式自然演绎 —— Prolog 主场（TTAFP ch.11 + 附录 A）
%    「自然演绎规则 = 定义」（书 11.4）的机器化身：
%      · 前奏 Δ = 附录 A 规则库：⊥ ¬ ∧ ∨ 类型定义 + 规则常数
%        and_in / and_el_l / bot_el（参数望远镜吃到证明变元，
%        23 章 check_args 的滚动替换实战）
%      · 旗式行解释器 run_lines/7：fl 开旗（假设入语境）、
%        st 推导行（定型检查 = 书 11.3 旗式行三重意义之 (1)）、
%        un 收旗（作用域就此关闭）、defPrim 旗语境里的原始
%        定义（公理）、def 描述式定义——参数表 = 当前旗栈
%      · 旗舰：图 11.16 全 7 行——exc-thrd 公理化 + DN 推导
%      · 负例：收旗后引用旗变元失败（作用域纪律是硬的）
%    纪律：命名项里 t_arrow 是糖，喂 db 前必过 ex/2；
%          应用链完全嵌套（a/3 是静默失败源）。
% ============================================================

% ---------- 命名层与糖展开 ----------
db(n(X), Env, var(I)) :- !, nth0(I, Env, X).
db(l(N, Ty, B), Env, lam(T1, B1)) :- !, db(Ty, Env, T1), db(B, [N|Env], B1).
db(a(M, N), Env, app(M1, N1)) :- !, db(M, Env, M1), db(N, Env, N1).
db(p(N, A, B), Env, pi(A1, B1)) :- !, db(A, Env, A1), db(B, [N|Env], B1).
db(kn(N, As), Env, kk(N, As1)) :- !, map_db(As, Env, As1).
db(star, _, star) :- !.
db(box, _, box) :- !.

map_db([], _, []).
map_db([T|Ts], E, [T1|T1s]) :- db(T, E, T1), map_db(Ts, E, T1s).

t_arrow(A, B, p('_', A, B)).

ex(t_arrow(A, B), p('_', A1, B1)) :- !, ex(A, A1), ex(B, B1).
ex(l(N, Ty, B), l(N, T1, B1)) :- !, ex(Ty, T1), ex(B, B1).
ex(a(M, N), a(M1, N1)) :- !, ex(M, M1), ex(N, N1).
ex(p(N, A, B), p(N, A1, B1)) :- !, ex(A, A1), ex(B, B1).
ex(kn(N, As), kn(N, As1)) :- !, map_ex(As, As1).
ex(T, T) :- !.
map_ex([], []).
map_ex([T|Ts], [T1|T1s]) :- ex(T, T1), map_ex(Ts, T1s).

% ---------- de Bruijn 内核（21/23 章同款纪律） ----------
shift(var(K), _, C, var(K)) :- K < C, !.
shift(var(K), D, _, var(K1)) :- !, K1 is K + D.
shift(lam(A, B), D, C, lam(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(app(M, N), D, C, app(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(pi(A, B), D, C, pi(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(kk(N, As), D, C, kk(N, As1)) :- !, map_shift(As, D, C, As1).
shift(T, _, _, T) :- !.

substv(var(K), J, N, N) :- K =:= J, !.
substv(var(K), J, _, var(K1)) :- K > J, !, K1 is K - 1.
substv(var(K), _, _, var(K)) :- !.
substv(lam(A, B), J, N, lam(A1, B1)) :- !,
    substv(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), substv(B, J1, N1, B1).
substv(app(M, N), J, Nm, app(M1, N1)) :- !,
    substv(M, J, Nm, M1), substv(N, J, Nm, N1).
substv(pi(A, B), J, N, pi(A1, B1)) :- !,
    substv(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), substv(B, J1, N1, B1).
substv(kk(N, As), J, Nm, kk(N, As1)) :- !, map_subst(As, J, Nm, As1).
substv(T, _, _, T) :- !.

map_shift([], _, _, []).
map_shift([T|Ts], D, C, [T1|T1s]) :- shift(T, D, C, T1), map_shift(Ts, D, C, T1s).
map_subst([], _, _, []).
map_subst([T|Ts], J, N, [T1|T1s]) :- substv(T, J, N, T1), map_subst(Ts, J, N, T1s).

push_all([], []).
push_all([T|Ts], [T1|T1s]) :- shift(T, 1, 0, T1), push_all(Ts, T1s).
push(A, G, [A1|G1]) :- shift(A, 1, 0, A1), push_all(G, G1).

stepD(_, app(lam(_, B), N), R) :- !, substv(B, 0, N, R).
stepD(D, kk(N, As), R) :- !,
    ( member(d(N, Ps, Body, _), D),
      length(Ps, L), length(As, L),
      Body \= prim,
      inst_list(Body, As, R)
    ; step_args(As, As1), As1 \= As, R = kk(N, As1) ).
stepD(D, app(M, N), R) :- !,
    ( stepD(D, M, M1), R = app(M1, N)
    ; \+ stepD(D, M, _), stepD(D, N, N1), R = app(M, N1) ).
stepD(D, lam(A, B), R) :- !,
    ( stepD(D, A, A1), R = lam(A1, B)
    ; \+ stepD(D, A, _), stepD(D, B, B1), R = lam(A, B1) ).
stepD(D, pi(A, B), R) :- !,
    ( stepD(D, A, A1), R = pi(A1, B)
    ; \+ stepD(D, A, _), stepD(D, B, B1), R = pi(A, B1) ).
stepD(_, T, _) :- T = kk(_, _), !, fail.
stepD(_, T, _) :- atomic(T), !, fail.

step_args([], []).
step_args([A|As], [A1|As]) :- stepD(_, A, A1), !.
step_args([A|As], [A|As1]) :- \+ stepD(_, A, _), step_args(As, As1).

bdnf(D, T, R) :- (stepD(D, T, T1) -> bdnf(D, T1, R) ; T = R).

tc(_, _, star, box).
tc(_, G, var(N), T) :- nth0(N, G, T).
tc(D, G, pi(A, B), star) :- tc(D, G, A, box),  push(A, G, G1), tc(D, G1, B, star).
tc(D, G, pi(A, B), star) :- tc(D, G, A, star), push(A, G, G1), tc(D, G1, B, star).
tc(D, G, pi(A, B), box)  :- tc(D, G, A, star), push(A, G, G1), tc(D, G1, B, box).
tc(D, G, lam(A, M), pi(A, B)) :- push(A, G, G1), tc(D, G1, M, B).
tc(D, G, kk(N, As), T) :-
    member(d(N, Ps, _, Ty), D),
    length(Ps, L), length(As, L),
    reverse(Ps, PsB),              % 存储语境形 → 绑定序与实参配对
    check_args(D, G, PsB, As),
    inst_list(Ty, As, T).
tc(D, G, app(M, N), T) :-
    tc(D, G, M, M0), bdnf(D, M0, pi(A, B)),   % 函数类型先 βδ-范式化
    tc(D, G, N, A0),
    bdnf(D, A0, A0n), bdnf(D, A, An), A0n = An,
    substv(B, 0, N, T0), bdnf(D, T0, T).

check_args(D, G, Ps, As) :- length(Ps, N), check_args(D, G, Ps, As, N, []).
check_args(_, _, [], [], _, _).
check_args(D, G, [P|Ps], [U|Us], N, Sub) :-
    reverse(Sub, SubB),                 % 绑定序
    J is N - 1, subst_many(P, J, SubB, PInst),
    tc(D, G, U, PInst),
    check_args(D, G, Ps, Us, N, [U|Sub]).

% 同时代换 subst_many(T, J, As)：As 自 J 起降序对应（J, J-1, ...）。
% 顺序代换会互相腐蚀（后遍的减一伤及前遍的插入）——并行替换无此病。
% 望远镜 x1..xn（x1 最外 = index n-1）：实例化 = subst_many(T, n-1, Us绑定序)。
inst_list(T, Us, R) :- length(Us, L), J is L - 1, subst_many(T, J, Us, R).

% As[0] 对应 index J、As[1] 对应 J-1……var K ↦ As[J-K]（若在范围内）
subst_many(var(K), J, As, R) :- !,
    ( Idx is J - K, Idx >= 0, nth0(Idx, As, A) -> R = A
    ; K > J -> length(As, LA), K1 is K - LA, R = var(K1)
    ; R = var(K) ).
subst_many(lam(A, B), J, As, lam(A1, B1)) :- !,
    subst_many(A, J, As, A1),
    J1 is J + 1, map_shift(As, 1, 0, As1), subst_many(B, J1, As1, B1).
subst_many(app(M, N), J, As, app(M1, N1)) :- !,
    subst_many(M, J, As, M1), subst_many(N, J, As, N1).
subst_many(pi(A, B), J, As, pi(A1, B1)) :- !,
    subst_many(A, J, As, A1),
    J1 is J + 1, map_shift(As, 1, 0, As1), subst_many(B, J1, As1, B1).
subst_many(kk(N, As0), J, As, kk(N, As1)) :- !,
    map_many(As0, J, As, As1).
subst_many(T, _, _, T) :- !.

map_many([], _, _, []).
map_many([T|Ts], J, As, [T1|T1s]) :- subst_many(T, J, As, T1), map_many(Ts, J, As, T1s).

% ---------- (def) 良构检查（23 章同款；参数望远镜版） ----------
% 存储的参数类型表已是语境形态（最内层在前）——直接作 tc 语境
def_ok(D, d(_, Ps, Body, Ty)) :-
    ( Body = prim -> tc(D, Ps, Ty, S), member(S, [star, box])
    ; tc(D, Ps, Body, BT), bdnf(D, BT, B2), bdnf(D, Ty, T2), B2 = T2 ).

% ---------- 定义构造器：参数望远镜（再基版） ----------
% 约定：参数表 [pn(x1,T1),...,pn(xn,Tn)] 按绑定序给出；
% 存储的参数类型表 = 语境形态（最内层 xn 在前，逐个压栈再基）；
% body/ty db 于 Env = [xn,...,x1]（最后绑定者 index 0）。
build_def(Name, Body0, Ty0, Params, d(Name, Ctx, BodyDb, TyDb)) :-
    build_params(Params, [], [], Ctx, Env),
    ex(Body0, Body), ex(Ty0, Ty),
    db(Body, Env, BodyDb), db(Ty, Env, TyDb).

build_params([], C, E, C, E).
build_params([pn(X, T0)|Rest], C0, E0, C2, E2) :-
    ex(T0, T), db(T, E0, Tdb),      % E0 = 早绑定参数（可被 T 引用）
    push(Tdb, C0, C1),              % 压栈再基：统一坐标系
    build_params(Rest, C1, [X|E0], C2, E2).

% ---------- 附录 A 规则库（前奏 Δ） ----------
prelude(D) :-
    BD = p(al, star, n(al)),                                   % ⊥ := Πα.α
    ND = t_arrow(n(a0), kn(bot, [])),                          % ¬A := A→⊥
    AND = p(c, star, t_arrow(t_arrow(n(a0), t_arrow(n(b0), n(c))), n(c))),
    OR  = p(c, star, t_arrow(t_arrow(n(a0), n(c)),
                             t_arrow(t_arrow(n(b0), n(c)), n(c)))),
    ANDIN_B = l(c, star, l(z, t_arrow(n(a0), t_arrow(n(b0), n(c))),
                        a(a(n(z), n(u)), n(v)))),
    ANDELL_B = a(a(n(c2), n(a0)), l(u, n(a0), l(v, n(b0), n(u)))),
    BOTEL_T = n(x0),
    build_def(bot,    BD,   star, [],                          Dbot),
    build_def(neg,    ND,   star, [pn(a0, star)],              Dneg),
    build_def(and2,   AND,  star, [pn(a0, star), pn(b0, star)], Dand),
    build_def(or2,    OR,   star, [pn(a0, star), pn(b0, star)], Dor),
    build_def(and_in, ANDIN_B, kn(and2, [n(a0), n(b0)]),
              [pn(a0, star), pn(b0, star), pn(u, n(a0)), pn(v, n(b0))], Dain),
    build_def(and_el_l, ANDELL_B, n(a0),
              [pn(a0, star), pn(b0, star), pn(c2, kn(and2, [n(a0), n(b0)]))], Dael),
    build_def(bot_el, a(n(u), n(x0)), BOTEL_T,
              [pn(x0, star), pn(u, kn(bot, []))], Dbotel),
    D = [Dbot, Dneg, Dand, Dor, Dain, Dael, Dbotel].

% 命名层的常数应用糖：and2(A,B) 展开成 kn
and2(A, B, kn(and2, [A, B])).

% ---------- 旗式行解释器 ----------
% 行形：fl(X, TyN) | st(TermN, TyN) | un(X) |
%       defPrim(Name, TyN) | def(Name, BodyN, TyN)
% 状态：D（环境）G（de Bruijn 语境）E（旗名栈，头=最近开旗）
run_lines([], D, G, E, D, G, E).
run_lines([L|Ls], D0, G0, E0, D2, G2, E2) :-
    run_line(L, D0, G0, E0, D1, G1, E1),
    run_lines(Ls, D1, G1, E1, D2, G2, E2).

run_line(fl(X, Ty0), D, G0, E0, D, G1, [X|E0]) :-
    ex(Ty0, Ty), db(Ty, E0, Tdb),
    tc(D, G0, Tdb, S), member(S, [star, box]),
    push(Tdb, G0, G1).

run_line(st(Term0, Ty0), D, G, E, D, G, E) :-
    ex(Term0, Term), ex(Ty0, Ty),
    db(Term, E, Tdb), db(Ty, E, Tydb),
    tc(D, G, Tdb, Got), bdnf(D, Got, G1), bdnf(D, Tydb, T1), G1 = T1.

run_line(un(X), D, G0, [_|E0], D, G1, E0) :-
    ( G0 = [_|G1] -> true ; G1 = G0 ),
    atom(X).   % 收旗：语境与名栈弹出一个——作用域就此关闭

run_line(defPrim(Name, Ty0), D0, G, E, [d(Name, G, prim, TyDb)|D0], G, E) :-
    ex(Ty0, Ty), db(Ty, E, TyDb),
    tc(D0, G, TyDb, S), member(S, [star, box]).

run_line(def(Name, Body0, Ty0), D0, G, E, [d(Name, G, BodyDb, TyDb)|D0], G, E) :-
    ex(Body0, Body), ex(Ty0, Ty),
    db(Body, E, BodyDb), db(Ty, E, TyDb),
    tc(D0, G, BodyDb, BT), bdnf(D0, BT, B1), bdnf(D0, TyDb, T1), B1 = T1.

% ============================================================
%  电池（14 条）
% ============================================================

chk(1,  '前奏 Δ 七条定义全部良构（附录 A 规则库）').
chk(2,  '⊥ 定型为 ∗').
chk(3,  '¬(A) 在 [A:∗] 定型为 ∗').
chk(4,  '∧(A,B) 与 ∨(A,B) 定型为 ∗').
chk(5,  '规则常数 and_in 良构：4 参数望远镜吃到证明变元 u,v').
chk(6,  '规则常数 and_el_l 良构：第 3 参数类型 = ∧(A,B)（实例化的定义）').
chk(7,  '规则常数 bot_el 良构（⊥-elim 免费）').
chk(8,  'and_in 用例：u:A, v:B ⊢ and_in(A,B,u,v) : ∧(A,B)').
chk(9,  'and_el_l 用例：c:∧(A,B) ⊢ and_el_l(A,B,c) : A').
chk(10, 'bot_el 用例：u:⊥ ⊢ bot_el(A,u) : A').
chk(11, '旗式开旗/推导/收旗基本盘：⇒-intro 的 flag 形式').
chk(12, '图 11.16 全 7 行：exc-thrd 公理化 + DN 推导 + doub-neg 定义').
chk(13, 'NEG：收旗后引用旗变元——作用域外失败').
chk(14, 'NEG：and_in 参数喂错（u 的类型该是 A 不是 B）被拒').

cond(1) :- prelude(D), forall(member(E, D), def_ok(D, E)).

cond(2) :- prelude(D), db(kn(bot, []), [], B), tc(D, [], B, star).

cond(3) :- prelude(D), db(kn(neg, [n(a0)]), [a0], N), tc(D, [star], N, star).

cond(4) :- prelude(D),
    db(kn(and2, [n(a0), n(b0)]), [b0, a0], AND),
    db(kn(or2,  [n(a0), n(b0)]), [b0, a0], OR),
    tc(D, [star, star], AND, star), tc(D, [star, star], OR, star).

cond(5) :- prelude(D), member(d(and_in, _, _, _), D).
cond(6) :- prelude(D), member(d(and_el_l, _, _, _), D).
cond(7) :- prelude(D), member(d(bot_el, _, _, _), D).

cond(8) :-
    prelude(D),
    run_lines([fl(a0, star), fl(b0, star), fl(u, n(a0)), fl(v, n(b0)),
               st(kn(and_in, [n(a0), n(b0), n(u), n(v)]), kn(and2, [n(a0), n(b0)]))],
              D, [], [], _, _, _).

cond(9) :-
    prelude(D),
    run_lines([fl(a0, star), fl(b0, star), fl(c2, kn(and2, [n(a0), n(b0)])),
               st(kn(and_el_l, [n(a0), n(b0), n(c2)]), n(a0))],
              D, [], [], _, _, _).

cond(10) :-
    prelude(D),
    run_lines([fl(a0, star), fl(u, kn(bot, [])),
               st(kn(bot_el, [n(a0), n(u)]), n(a0))],
              D, [], [], _, _, _).

cond(11) :-
    prelude(D),
    % ⇒-intro 的 flag 形式：开 u:A，块内得 B，收旗成 λu.b : A→B
    run_lines([fl(a0, star), fl(b0, star),
               fl(u, n(a0)), st(n(u), n(a0)), un(u),
               st(l(u, n(a0), n(u)), t_arrow(n(a0), n(a0)))],
              D, [], [], _, _, _).

cond(12) :-
    prelude(D),
    A5 = l(w, kn(neg, [n(a0)]), a(a(n(u0), n(w)), n(a0))),
    Line6 = a(a(a(kn(exc_thrd, [n(a0)]), n(a0)), l(vv, n(a0), n(vv))), A5),
    Line6u = a(a(a(kn(exc_thrd, [n(a0)]), n(a0)), l(vv, n(a0), n(vv))),
             l(w, kn(neg, [n(a0)]), a(a(n(u0), n(w)), n(a0)))),
    run_lines([
        fl(a0, star),                                        % A : ∗
        defPrim(exc_thrd, kn(or2, [n(a0), kn(neg, [n(a0)])])),     % (1) 公理
        def(a2, l(vv, n(a0), n(vv)),                         % (2) A⇒A
            t_arrow(n(a0), n(a0))),
        fl(u0, kn(neg, [kn(neg, [n(a0)])])),                 % u : ¬¬A
        fl(v0, kn(neg, [n(a0)])),                            % v : ¬A
        st(a(n(u0), n(v0)), kn(bot, [])),                    % (3) u v : ⊥
        st(a(a(n(u0), n(v0)), n(a0)), n(a0)),                % (4) (uv)A : A
        st(l(w, kn(neg, [n(a0)]), a(a(n(u0), n(w)), n(a0))),
           t_arrow(kn(neg, [n(a0)]), n(a0))),                % (5) ¬A⇒A
        st(Line6, n(a0)),                                    % (6) exc A a2 a5
        un(v0), un(u0),                                      % 收旗
        def(doub_neg, l(u0, kn(neg, [kn(neg, [n(a0)])]), Line6u),
            t_arrow(kn(neg, [kn(neg, [n(a0)])]), n(a0)))     % (7)
      ], D, [], [], D2, _, _),
    member(d(doub_neg, _, _, _), D2).

cond(13) :-
    prelude(D),
    % 收旗后再引用 u：st 行在 un(u) 之后——db 找不到 u（不在名栈）
    \+ run_lines([fl(a0, star), fl(u, n(a0)), un(u), st(n(u), n(a0))],
                 D, [], [], _, _, _).

cond(14) :-
    prelude(D),
    % u 的类型喂成 B（应是 A）——check_args 滚动替换后不匹配
    \+ run_lines([fl(a0, star), fl(b0, star), fl(u, n(b0)), fl(v, n(b0)),
                  st(kn(and_in, [n(a0), n(b0), n(u), n(v)]),
                     kn(and2, [n(a0), n(b0)]))],
                 D, [], [], _, _, _).

main :-
    ( between(1, 14, I), chk(I, What), \+ cond(I) ->
        format('FAIL ~d ~w~n', [I, What]), halt(1)
    ; true ),
    !,
    format('14 条全过~n'),
    halt.
