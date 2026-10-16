:- encoding(utf8).
:- discontiguous cond/1.
% ============================================================
%  23 λD 形式系统 —— Prolog 镜像（TTAFP ch.8–10）
%    λD0 = λC + 定义环境 Δ；λD = λD0 + 原始定义
%      · (def)：Δ 里每条描述式定义的体在「前缀 Δ + 参数语境」
%        过检且类型吻合——电池 1–2
%      · (inst)：常数完全应用 kk(N, As)；实参替换进类型
%        （多参数按逆参数序连续替换）——电池 3–5
%      · δ-归约：完全应用的描述式常数原地展开；βδ-范式
%        = 转换规则的引擎——plus two three ≡ five（电池 7）
%      · (def-prim)/(inst-prim)：⊥⊥ 占位、不展开——
%        iet(α) : α∨¬α 公理化（连 21 章）——电池 8–9
%    常数项 kk(Name, ArgsDb)；Δ 条目 d(Name, ParamsDb,
%    bodyDb|prim, TyDb)，体与类型 db 于参数望远镜（最内层
%    参数 = index 0）。项体与 Lean 版逐字对齐（已机器验证）。
% ============================================================

% ---------- de Bruijn 内核（与 21 章同款纪律） ----------
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

% substv(J := N)：==J 换入（N 已按深度预抬）；>J 减一；<J 不动
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

% 语境压栈：统一坐标系，全体条目 cutoff 0 上移一位
push_all([], []).
push_all([T|Ts], [T1|T1s]) :- shift(T, 1, 0, T1), push_all(Ts, T1s).
push(A, G, [A1|G1]) :- shift(A, 1, 0, A1), push_all(G, G1).

% ---------- βδ-归约 ----------
stepD(_, app(lam(_, B), N), R) :- !, substv(B, 0, N, R).
stepD(D, kk(N, As), R) :- !,
    ( member(d(N, Ps, Body, _), D),
      length(Ps, L), length(As, L),
      Body \= prim,
      inst_body(Body, As, R)          % δ：完全应用的描述式常数
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
stepD(_, T, _) :- T = kk(_, _), !, fail.   % 原始常数/参数不足：不动
stepD(_, T, _) :- atomic(T), !, fail.

step_args([], []).
step_args([A|As], [A1|As]) :- stepD(_, A, A1), !.
step_args([A|As], [A|As1]) :- \+ stepD(_, A, _), step_args(As, As1).

bdnf(D, T, R) :- (stepD(D, T, T1) -> bdnf(D, T1, R) ; T = R).

% ---------- 定型：λC 四条 form + (inst) ----------
tc(_, _, star, box).
tc(_, G, var(N), T) :- nth0(N, G, T).
tc(D, G, pi(A, B), star) :- tc(D, G, A, box),  push(A, G, G1), tc(D, G1, B, star).
tc(D, G, pi(A, B), star) :- tc(D, G, A, star), push(A, G, G1), tc(D, G1, B, star).
tc(D, G, pi(A, B), box)  :- tc(D, G, A, star), push(A, G, G1), tc(D, G1, B, box).
tc(D, G, lam(A, M), pi(A, B)) :- push(A, G, G1), tc(D, G1, M, B).
% (inst)：完全应用；类型按逆参数序连续替换
tc(D, G, kk(N, As), T) :-
    member(d(N, Ps, _, Ty), D),
    length(Ps, L), length(As, L),
    inst_args_ok(D, G, Ps, As, Ty, T).
tc(D, G, app(M, N), T) :-
    tc(D, G, M, pi(A, B)), tc(D, G, N, A0),
    bdnf(D, A0, A0n), bdnf(D, A, An), A0n = An,
    substv(B, 0, N, T0), bdnf(D, T0, T).

% 实参逐个检查（第 k 个实参的类型 = Ak[x1..x(k-1) := U1..U(k-1)]），
% 最终类型同理替换；逆参数序折叠（最内层参数在 index 0）
inst_args_ok(D, G, Ps, As, Ty, T) :-
    check_args(D, G, Ps, As, []),
    inst_list(Ty, As, T).

check_args(_, _, [], [], _).
check_args(D, G, [P|Ps], [U|Us], Sub) :-
    inst_list(P, Sub, PInst),
    tc(D, G, U, PInst),
    check_args(D, G, Ps, Us, [U|Sub]).

% 逆参数序连续替换（与 Lean 版 instantiate 同款：最内层参数在 index 0）
inst_list(T, Us, R) :- reverse(Us, W), inst_rev(T, W, R).
inst_rev(T, [], T).
inst_rev(T, [U|W], R) :- substv(T, 0, U, T1), inst_rev(T1, W, R).

inst_body(B, As, R) :- inst_list(B, As, R).

% ---------- (def) 的机器面：描述式良构 / 原始式类型为 sort ----------
def_ok(D, d(_, Ps, Body, Ty)) :-
    check_ctx(D, Ps),
    ( Body = prim -> tc(D, Ps, Ty, S), member(S, [star, box])
    ; tc(D, Ps, Body, BodyT), bdnf(D, BodyT, BT2), bdnf(D, Ty, Ty2),
      BT2 = Ty2 ).

check_ctx(_, []) :- !.
check_ctx(D, [P|Ps]) :- tc(D, Ps, P, S), member(S, [star, box]), check_ctx(D, Ps).

% ============================================================
%  样本 Δ（项与 Lean 版逐字对齐）
% ============================================================

d_zero(d(zero, [], lam(star, lam(pi(var(0), var(1)), lam(var(1), var(0)))),
        pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))))).

d_succ(d(succ, [],
      lam(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))),
        lam(star,
          lam(pi(var(0), var(1)),
            lam(var(1),
              app(var(1),
                app(app(app(var(3), var(2)), var(1)), var(0))))))),
      pi(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))),
         pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2))))))).

d_plus(d(plus, [],
      lam(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))),
        lam(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))),
          lam(star,
            lam(pi(var(0), var(1)),
              lam(var(1),
                app(app(app(var(4), var(2)), var(1)),
                    app(app(app(var(3), var(2)), var(1)), var(0)))))))),
      pi(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))),
         pi(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))),
            pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2)))))))).

d_id(d(id, [star], lam(var(0), var(0)), pi(var(0), var(1)))).

% iet(α) : α∨¬α = ΠC:*. (α→C)→((α→⊥)→C)→C ——原始定义
d_iet(d(iet, [star], prim,
      pi(star,
        pi(pi(var(1), var(1)),
          pi(pi(pi(var(2), pi(star, var(0))), var(2)), var(2)))))).

sample_delta(D) :-
    d_zero(D0), d_succ(D1), d_plus(D2), d_id(D3), d_iet(D4),
    D = [D0, D1, D2, D3, D4].

% ============================================================
%  电池（12 条）
% ============================================================

chk(1,  '(def)：五条定义全部良构（4 描述 + 1 原始）').
chk(2,  '(def) 负例：体类型不符的定义被拒').
chk(3,  '(inst) 0 参数：zero : N').
chk(4,  '零参数常数经 β 应用：succ zero : N').
chk(5,  '(inst) 1 参数：id(N) : N→N（类型里参数替换）').
chk(6,  'δ 展开：id(N) 应用于 zero 的 βδ-范式 = zero 的范式').
chk(7,  'δ 引擎旗舰：plus two three ≡ five（βδ-范式相等）').
chk(8,  '(inst-prim)：iet(N) : N∨¬N').
chk(9,  '原始定义不 δ-展开：iet(N) 范式保持自身').
chk(10, 'NEG：不在 Δ 里的常数失败').
chk(11, 'NEG：参数不足的常数不可定型').
chk(12, 'plus 可定型：plus two three : N').

cond(1) :-
    sample_delta(D),
    forall(member(E, D), def_ok(D, E)).

cond(2) :-
    sample_delta(D),
    % 声明 zero : N→N（错）——体是 N
    d_zero(d(zero, [], Body, _)),
    d_succ(d(_, [], _, WrongTy)),
    \+ def_ok(D, d(zero, [], Body, WrongTy)).

cond(3) :- sample_delta(D), tc(D, [], kk(zero, []), T), bdnf(D, T, T2),
           tyN2(TN), T2 = TN.

tyN2(pi(star, pi(pi(var(0), var(1)), pi(var(1), var(2))))).

cond(4) :- sample_delta(D),
           tc(D, [], kk(succ, []), pi(A, B)), tyN2(TN), A = TN, B = TN.

cond(5) :- sample_delta(D), tyN2(T),
           tc(D, [], kk(id, [T]), RT),
           bdnf(D, RT, pi(T, T)).

cond(6) :- sample_delta(D), tyN2(T),
           bdnf(D, app(kk(id, [T]), kk(zero, [])), R1),
           bdnf(D, kk(zero, []), R2), R1 = R2.

cond(7) :- sample_delta(D),
           Two = app(kk(succ, []), app(kk(succ, []), kk(zero, []))),
           Three = app(kk(succ, []), Two0), Two0 = app(kk(succ, []), app(kk(succ, []), kk(zero, []))),
           Five = app(kk(succ, []), app(kk(succ, []), app(kk(succ, []), app(kk(succ, []), app(kk(succ, []), kk(zero, [])))))),
           bdnf(D, app(app(kk(plus, []), Two), Three), R1),
           bdnf(D, Five, R2), R1 = R2.

cond(8) :- sample_delta(D), tyN2(T),
           tc(D, [], kk(iet, [T]), OrT), bdnf(D, OrT, OrNf),
           % 期望：ΠC. (N→C)→((N→⊥)→C)→C（C 是约束变元；⊥ 闭项不动）
           OrNf = pi(star,
                 pi(pi(T, var(1)),
                   pi(pi(pi(T, pi(star, var(0))), var(2)), var(2)))).

cond(9) :- sample_delta(D), tyN2(T),
           bdnf(D, kk(iet, [T]), kk(iet, [T])).

cond(10) :- sample_delta(D), \+ tc(D, [], kk(phantom, []), _).

cond(11) :- sample_delta(D), \+ tc(D, [], kk(iet, []), _).

cond(12) :- sample_delta(D),
            Two = app(kk(succ, []), app(kk(succ, []), kk(zero, []))),
            Three = app(kk(succ, []), app(kk(succ, []), app(kk(succ, []), kk(zero, [])))),
            tyN2(T), tc(D, [], app(app(kk(plus, []), Two), Three), T).

main :-
    ( between(1, 12, I), chk(I, What), \+ cond(I) ->
        format('FAIL ~d ~w~n', [I, What]), halt(1)
    ; true ),
    !,
    format('12 条全过~n'),
    halt.
