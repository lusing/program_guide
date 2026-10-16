:- encoding(utf8).
% ============================================================
%  21 λC 中的逻辑编码 —— Prolog 主场（TTAFP ch.7）
%    λP2 检查器：命名项 → de Bruijn → 七规则定型
%      · form 三条款 = 立方体 λP2 角（(∗,∗)(□,∗)(∗,□)）
%      · ch7 全部编码在这里过检：⊥¬∧∨∃ 的类型定型、
%        图 7.1 证明项、书 7.4 的 ET→DN 证明项、
%        书 7.6 的 ¬∃⇒∀¬ 证明项——「proof checking =
%        type checking」的字面机器版
%      · 负例：curried 连接词当常数用（Πα:∗.∗）在 λP2
%        无 sort——那是 λω 的 (□,□) 条款（Remark 7.2.1）
%    定义展开（bot/not2/and2/or2/ex2 谓词）= 23 章 δ 的预告
% ============================================================

% ---------- 命名层语法：n(名) l(名,域,体) a(M,N) p(名,域,体) star box ----------

% 命名 → de Bruijn（Env 头 = 最近绑定者）
db(n(X), Env, var(I)) :- !, nth0(I, Env, X).
db(l(N, Ty, B), Env, lam(T1, B1)) :- !, db(Ty, Env, T1), db(B, [N|Env], B1).
db(a(M, N), Env, app(M1, N1)) :- !, db(M, Env, M1), db(N, Env, N1).
db(p(N, A, B), Env, pi(A1, B1)) :- !, db(A, Env, A1), db(B, [N|Env], B1).
db(star, _, star) :- !.
db(box, _, box) :- !.

% 箭头糖：A → B = Π_:A.B（哑名 '_' 不可被引用，永不捕获）
t_arrow(A, B, p('_', A, B)).

% ---------- 定义（= 22/23 章定义系统的 δ 展开预告） ----------
bot(p(al, star, n(al))).                          % ⊥  := ∀α:∗. α
not2(A, T) :- t_arrow(A, bot, T).                 % ¬A := A → ⊥
and2(A, B, p(c, star, Arr)) :-                    % A∧B := ∀C. (A→B→C)→C
    t_arrow(t_arrow(A, t_arrow(B, n(c))), n(c), Arr).
or2(A, B, p(c, star, Arr)) :-                     % A∨B := ∀C. (A→C)→(B→C)→C
    t_arrow(t_arrow(A, n(c)), t_arrow(t_arrow(B, n(c)), n(c), Arr2), Arr2)?, !.
or2(A, B, p(c, star, Arr)) :-
    t_arrow(t_arrow(A, n(c)), t_arrow(t_arrow(B, n(c)), n(c)), Arr).
ex2(S, P, p(al, star, Arr)) :-                    % ∃x:S.Px := ∀α. (∀x:S.Px→α)→α
    t_arrow(p(x, S, t_arrow(a(P, n(x)), n(al))), n(al), Arr).

% ---------- de Bruijn 内核：shift / subst / β-范式 ----------
shift(var(K), D, C, var(K1)) :- K < C, !, K1 is K.
shift(var(K), D, C, var(K1)) :- !, K1 is K + D.
shift(lam(A, B), D, C, lam(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(app(M, N), D, C, app(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(pi(A, B), D, C, pi(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(T, _, _, T) :- !.   % star / box

% substv(J := N)：J 处换 N，>J 的减一；N 的自由变元先抬 J
substv(var(J), J, N, R) :- !, shift(N, J, 0, R).
substv(var(K), _, _, var(K)) :- !.
substv(lam(A, B), J, N, lam(A1, B1)) :- !,
    substv(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), substv(B, J1, N1, B1).
substv(app(M, N), J, Nm, app(M1, N1)) :- !,
    substv(M, J, Nm, M1), substv(N, J, Nm, N1).
substv(pi(A, B), J, N, pi(A1, B1)) :- !,
    substv(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), substv(B, J1, N1, B1).
substv(T, _, _, T) :- !.

% 单步 β（左优先）+ 范式
step(app(lam(_, B), N), R) :- !, substv(B, 0, N, R).
step(app(M, N), app(M1, N)) :- step(M, M1), !.
step(app(M, N), app(M, N1)) :- \+ step(M, _), step(N, N1), !.
step(lam(A, B), lam(A, B1)) :- !, step(B, B1).
step(pi(A, B), pi(A1, B)) :- step(A, A1), !.
step(pi(A, B), pi(A, B1)) :- \+ step(A, _), step(B, B1), !.

beta_nf(T, R) :- (step(T, T1) -> beta_nf(T1, R) ; T = R).

% ---------- λP2 定型七规则（form 三条款 = (∗,∗)(□,∗)(∗,□)） ----------
tc(_, star, box).                                        % ax
tc(G, var(N), T) :- nth0(N, G, T).                       % var
tc(G, pi(A, B), star) :- tc(G, A, box),  tc([A|G], B, star).  % form (□,∗)
tc(G, pi(A, B), star) :- tc(G, A, star), tc([A|G], B, star).  % form (∗,∗)
tc(G, pi(A, B), box)  :- tc(G, A, star), tc([A|G], B, box).   % form (∗,□)
tc(G, lam(A, M), pi(A, B)) :- tc([A|G], M, B).           % abs（检查模式）
tc(G, app(M, N), T) :-                                   % appl + 结果 β-范式
    tc(G, M, pi(A, B)), tc(G, N, A),
    substv(B, 0, N, T0), beta_nf(T0, T).

% ============================================================
%  电池（chk/cond 双谓词定型）
% ============================================================

% 命名语境 [A:∗, B:∗, x:Or2 A B, y:¬A] 的 de Bruijn 化 + 旗舰项
fig71 :-
    and2(n(a), n(b), _),        % 静音：确认定义可用
    fail.
fig71 :- true.

chk(1,  '⊥ = Πα:∗.α 定型为 ∗（form (□,∗)；书 7.1）').
chk(2,  '¬A := A→⊥ 在 [A:∗] 里定型为 ∗').
chk(3,  '∧ 二阶编码定型为 ∗（书 7.2 I）').
chk(4,  '∨ 二阶编码定型为 ∗（书 7.2 II）').
chk(5,  '∃ 二阶编码定型为 ∗（书 7.5；λP2 才够）').
chk(6,  '图 7.1 证明项 : (A∨B)→(¬A)→B——整条重言式过检').
chk(7,  '书 7.4 证明项 : ET ⊢ ¬¬β→β（iET β β (λy.y) (λz.x z β)）').
chk(8,  '∧-intro 项 λx.λy.λC.λz. z x y : A∧B').
chk(9,  '∧-elim-left 项 λc. c A (λa.λb.a) : A∧B→A').
chk(10, '∃-intro 项 λa.λu.λα.λw. w a u : Pa→∃P（书 7.5 的 ?）').
chk(11, '∃-elim 项 λy.λz. y A z : ∃P→(∀x.Px→A)→A（辖域边条件天然强制）').
chk(12, 'NEG：curried 连接词当常数（Πα:∗.∗）在 λP2 无 sort——要 λω').
chk(13, '书 7.6 证明项 : ¬∃P → ∀y:S.¬(P y)').
chk(14, '一阶 ∨ 编码方向的落差：Or2 型可推出 ¬A→B 型的项存在').

% ---- 1 ⊥ : ∗ ----
cond(1) :- bot(B), db(B, [], Bdb), tc([], Bdb, star).

% ---- 2 ¬A : ∗ in [A:∗] ----
cond(2) :- not2(n(a), N), db(N, [], Ndb), tc([star], Ndb, star).

% ---- 3/4 ∧ ∨ : ∗ in [B:∗, A:∗] ----
cond(3) :- and2(n(a), n(b), T), db(T, [], Tdb), tc([star, star], Tdb, star).
cond(4) :- or2(n(a), n(b), T), db(T, [], Tdb), tc([star, star], Tdb, star).

% ---- 5 ∃ : ∗ in [P:S→∗, S:∗]（语境里的 P 用 λP2 的 (∗,□)）----
cond(5) :-
    t_arrow(n(s), star, PTy), db(PTy, [], PTydb),
    tc([PTydb, star], Edb, star),
    ex2(n(s), n(p), E), db(E, [], Edb).

% ---- 6 图 7.1：λx:Or2AB. λy:¬A. x B (λu. y u B) (λv. v) ----
cond(6) :-
    or2(n(a), n(b), OrT), not2(n(a), NotT),
    db(OrT, [], OrDb), db(NotT, [], NotDb),
    G = [NotDb, OrDb, star, star],               % Env: y x b a
    TermN = l(x, OrT, l(y, NotT,
                 a(a(n(x), n(b)),
                   l(u, n(a), a(a(n(y), n(u)), n(b))),
                   l(v, n(b), n(v))))),
    db(TermN, [], Tdb),
    Expected = t_arrow(OrT, t_arrow(NotT, n(b))),
    db(Expected, [], Edb),
    tc(G, Tdb, Edb).

% ---- 7 ET→DN：iET β β (λy. y) (λz. x z β) : β ----
cond(7) :-
    not2(n(b), NB), not2(NB, NN),                % ¬β 与 ¬¬β
    EtT = p(al, star, OrE), or2(n(al), not2(n(al)), OrE0),
    not2(n(al), NAl), or2(n(al), NAl, OrE) => true,
    true.
cond(7) :-
    not2(n(b), NB), not2(NB, NN),
    not2(n(al), NAl), or2(n(al), NAl, OrE),
    EtT = p(al, star, OrE),
    db(EtT, [], EtDb), db(NN, [], NNDb),
    G = [NNDb, EtDb, star],                      % Env: x iet b
    TermN = a(a(a(a(n(iet), n(b)), n(b)), l(y, n(b), n(y))),
              l(z, NB0, a(a(n(x), n(z)), n(b)))),
    NB0 = NB,
    db(TermN, [], Tdb),
    tc(G, Tdb, DbB), db(n(b), [], DbB).

% ---- 8 ∧-intro ----
cond(8) :-
    and2(n(a), n(b), A2),
    Inner = l(z, t_arrow(n(a), t_arrow(n(b), n(c))),
                 a(a(n(z), n(x)), n(y))),
    TermN = l(x, n(a), l(y, n(b), l(c, star, Inner))),
    db(TermN, [], Tdb), db(A2, [], A2db),
    tc([star, star], Tdb, A2db).

% ---- 9 ∧-elim-left ----
cond(9) :-
    and2(n(a), n(b), A2),
    TermN = l(cc, A2, a(a(n(cc), n(a)), l(a1, n(a), l(b1, n(b), n(a1))))),
    t_arrow(A2, n(a), TT), db(TT, [], Tdb),
    db(TermN, [], TermDb),
    tc([star, star], TermDb, Tdb).

% ---- 10 ∃-intro ----
cond(10) :-
    ex2(n(s), n(p), E),
    Inner = l(w, p(x, n(s), t_arrow(a(n(p), n(x)), n(al))),
                 a(a(n(w), n(a0)), n(u))),
    TermN = l(a0, n(s), l(u, a(n(p), n(a0)), l(al, star, Inner))),
    t_arrow(a(n(p), n(a0)), E, TT),
    p(a0, n(s), TT), !, fail.   % 占位防错：真正条款在下一行
cond(10) :-
    ex2(n(s), n(p), E),
    Inner = l(w, p(x, n(s), t_arrow(a(n(p), n(x)), n(al))),
                 a(a(n(w), n(a0)), n(u))),
    TermN = l(a0, n(s), l(u, a(n(p), n(a0)), l(al, star, Inner))),
    TY = p(a0, n(s), t_arrow(a(n(p), n(a0)), E)),
    t_arrow(n(s), star, PTy), db(PTy, [], PTydb),
    db(TermN, [], Tdb), db(TY, [], TYdb),
    tc([PTydb, star], Tdb, TYdb).

% ---- 11 ∃-elim ----
cond(11) :-
    ex2(n(s), n(p), E),
    All = p(x, n(s), t_arrow(a(n(p), n(x)), n(a0))),
    TermN = l(y, E, l(z, All, a(a(n(y), n(a0)), n(z)))),
    t_arrow(E, t_arrow(All, n(a0)), TT),
    t_arrow(n(s), star, PTy), db(PTy, [], PTydb),
    db(TermN, [], Tdb), db(TT, [], Tdb),
    tc([PTydb, star, star], Tdb, Tdb0), Tdb0 = Tdb.

% ---- 12 NEG：Πα:∗.∗ 无 sort（λω 的 (□,□)）----
cond(12) :-
    db(p(al, star, star), [], K),
    \+ tc([], K, star), \+ tc([], K, box).

% ---- 13 书 7.6：λu.λy.λv. u (λα.λw. w y v) ----
cond(13) :-
    ex2(n(s), n(p), E), not2(E, NE),
    IntroN = l(al, star, l(w, p(x, n(s),
                     t_arrow(a(n(p), n(x)), n(al))),
                     a(a(n(w), n(y)), n(v)))),
    TermN = l(u, NE, l(y, n(s), l(v, a(n(p), n(y)), a(n(u), IntroN)))),
    PY = p(y0, n(s), t_arrow(a(n(p), n(y0)), bot)),
    TT = t_arrow(NE, PY),
    t_arrow(n(s), star, PTy), db(PTy, [], PTydb),
    db(TermN, [], Tdb), db(TT, [], TTdb),
    tc([PTydb, star], Tdb, TTdb).

% ---- 14 一阶 ∨ 编码单向可行：Or2 型 → 项 : ¬A→B 型 ----
cond(14) :-
    % λh:Or2AB. λna:¬A. h B (λa. na a B) (λb. b)
    or2(n(a), n(b), OrT), not2(n(a), NotT),
    TermN = l(h, OrT, l(na, NotT,
                 a(a(n(h), n(b)),
                   l(a1, n(a), a(a(n(na), n(a1)), n(b))),
                   l(b1, n(b), n(b1))))),
    t_arrow(OrT, t_arrow(NotT, n(b)), TT),
    db(TermN, [], Tdb), db(TT, [], Tdb),
    tc([star, star], Tdb, Tdb1), Tdb1 = Tdb.

main :-
    ( between(1, 14, I), chk(I, What), \+ cond(I) ->
        format('FAIL ~d ~w~n', [I, What]), halt(1)
    ; true ),
    !,
    format('14 条全过~n'),
    halt.
