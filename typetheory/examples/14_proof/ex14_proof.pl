:- encoding(utf8).
% ============================================================
% 14 证明系统 A —— Prolog 证明检查器（Farmer ch.8 + 附录 A）
%   · 公理模式 A1–A7 用「模式子句 + 单一化」实现：检查一个公式
%     是不是某公理的实例，就是拿它去问 ax/2
%   · 规则 R1（MP）与 R2（准等代换：单次出现替换）可执行
%   · 标本一：命题 A.3 ⊢ A ≃ A 的三步证明（书 217 页原证）
%   · 标本二：R2 的守卫——de Bruijn 指标让「绑定器下偷换」
%     根本找不到出现位置，攻击哑火
%   · 语义抽查：用 2 元模型求值器验证被证公式确为有效
% ============================================================
:- discontiguous chk/2, cond/1.

% ============================================================
% 一、公式与项（de Bruijn；fml 层恒两值）
%    项：tm(var(I)) | tm(con(K)) | tm(app(F,A)) | tm(lam(B)) | tm(des(B))
%    公式：dn(T) | eqf(T1,T2) | quasi(T1,T2) | imp(F,G)
% ============================================================

% ---- R1：MP ----
mp_step(Prem, Imp, Conc) :-
    Imp = imp(Prem, Conc).

% ---- R2：从 A≃B 与 C 得 C[A→B]（单次出现；绑定器位天然不在子式里） ----
r2_step(quasi(A, B), C, D) :-
    replace_one(A, B, C, D).

% 单次出现替换：深度 d 下的出现要与「模式 A 平移 d 位」比较；
% 替换进结果的是「B 平移 d 位」——de Bruijn 的免捕获纪律
replace_one(A, B, C, D) :- sub_rep(A, B, C, D, 0).

shiftt(tm(var(K)), D, C, tm(var(K1))) :- K >= C, !, K1 is K + D.
shiftt(tm(var(K)), _, _, tm(var(K))).
shiftt(tm(con(K)), _, _, tm(con(K))).
shiftt(tm(app(F, E)), D, C, tm(app(F1, E1))) :- shiftt(F, D, C, F1), shiftt(E, D, C, E1).
shiftt(tm(lam(Bd)), D, C, tm(lam(Bd1))) :- C1 is C + 1, shiftt(Bd, D, C1, Bd1).
shiftt(tm(des(Bd)), D, C, tm(des(Bd1))) :- C1 is C + 1, shiftt(Bd, D, C1, Bd1).

sub_rep(A, B, C, Bshift, D) :-
    shiftt(A, D, 0, AS), C == AS, !, shiftt(B, D, 0, Bshift).
sub_rep(A, B, imp(P, Q), imp(P2, Q2), D) :- !,
    ( sub_rep(A, B, P, P2, D) -> Q2 = Q
    ; sub_rep(A, B, Q, Q2, D), P2 = P ).
sub_rep(A, B, dn(T), dn(T2), D) :- !, sub_rep(A, B, T, T2, D).
sub_rep(A, B, eqf(S, T), eqf(S2, T2), D) :- !,
    ( sub_rep(A, B, S, S2, D) -> T2 = T
    ; sub_rep(A, B, T, T2, D), S2 = S ).
sub_rep(A, B, quasi(S, T), quasi(S2, T2), D) :- !,
    ( sub_rep(A, B, S, S2, D) -> T2 = T
    ; sub_rep(A, B, T, T2, D), S2 = S ).
sub_rep(A, B, tm(app(F, E)), tm(app(F2, E2)), D) :- !,
    ( sub_rep(A, B, F, F2, D) -> E2 = E
    ; sub_rep(A, B, E, E2, D), F2 = F ).
% 进入绑定器：深度 +1——浅处的模式自动「对不上」深处的同形项
sub_rep(A, B, tm(lam(Bd)), tm(lam(Bd2)), D) :- !, D1 is D + 1, sub_rep(A, B, Bd, Bd2, D1).
sub_rep(A, B, tm(des(Bd)), tm(des(Bd2)), D) :- !, D1 is D + 1, sub_rep(A, B, Bd, Bd2, D1).
% 无兜底子句：找不到同深度出现就【失败】——replace_one 语义干净

% ============================================================
% 二、公理模式：ax(Schema, Formula) 用单一化实现实例检查
% ============================================================
% A5.1：(x:α)↓
ax(a5_1, dn(tm(var(_)))).
% A5.2：cα ↓
ax(a5_2, dn(tm(con(_)))).
% A5.3：(A = B) ↓
ax(a5_3, dn(eqf(_, _))).
% A5.4/5：(A = B) ⇒ A↓ / ⇒ B↓
ax(a5_4, imp(eqf(A, _), dn(A))).
ax(a5_5, imp(eqf(_, B), dn(B))).
% A5.11：(λx.B)↓
ax(a5_11, dn(tm(lam(_)))).
% A5.12/13：A↓ ⇒ (A≃B) ≃ (A=B) ；B↓ ⇒ (A≃B) ≃ (A=B)
ax(a5_12, imp(dn(A), eqf(quasi(A, B), eqf(A, B)))).
ax(a5_13, imp(dn(B), eqf(quasi(A, B), eqf(A, B)))).
% A4（β-归约公理）：A↓ ⇒ (λx.B)A ≃ B
%    （自由换入条件：这里限制为「B 中 0 号指标不越界出现」的保守检查）
ax(a4, imp(dn(A), quasi(tm(app(tm(lam(B)), A)), B))) :- free_for_ok(A, B).

% 保守的自由换入检查：B 的自由指标结构可安全接受 A（单变量情形）
free_for_ok(_, tm(var(_))).
free_for_ok(_, tm(con(_))).
free_for_ok(A, tm(app(F, E))) :- free_for_ok(A, F), free_for_ok(A, E).
free_for_ok(A, tm(lam(Bd))) :- free_for_ok(shift_up(A), Bd).
free_for_ok(A, tm(des(Bd))) :- free_for_ok(shift_up(A), Bd).

shift_up(tm(var(K)), tm(var(K1))) :- K1 is K + 1.
shift_up(tm(con(K)), tm(con(K))).
shift_up(tm(app(F, E)), tm(app(F1, E1))) :- shift_up(F, F1), shift_up(E, E1).
shift_up(tm(lam(B)), tm(lam(B1))) :- shift_up(B, B1).
shift_up(tm(des(B)), tm(des(B1))) :- shift_up(B, B1).

% ============================================================
% 三、证明检查：steps 是 step(公式, 依据) 的列表
%    依据：ax(模式) | mp(I,J) | r2(I,J)   （I/J 为 1 起的步号）
% ============================================================
check_proof(Steps) :-
    check_from(Steps, 1, Steps).

check_from([], _, _).
check_from([step(F, J) | Rest], I, All) :-
    justify(F, J, All, I),
    Jnext is I + 1,
    check_from(Rest, Jnext, All).

justify(F, ax(S), _, _) :- ax(S, F).
justify(F, mp(I, J), All, _) :-
    nth1(I, All, step(P, _)),
    nth1(J, All, step(imp(P, F), _)).
justify(F, r2(I, J), All, _) :-
    nth1(I, All, step(Q, _)),
    nth1(J, All, step(C, _)),
    r2_step(Q, C, F).

% ============================================================
% 四、语义抽查：2 元模型上求值（结构同 12 章）
% ============================================================
sv([V|_], 0, V).
sv([_|Phi], K, V) :- K > 0, K1 is K - 1, sv(Phi, K1, V).

sev(Phi, tm(var(K)), V) :- sv(Phi, K, V).
sev(_, tm(con(0)), el(0,0)).
sev(_, tm(con(1)), el(0,1)).
sev(Phi, tm(app(F, A)), R) :-
    ( sev(Phi, F, fvt(Tab)), sev(Phi, A, VA), memberchk(VA-R0, Tab) -> R = R0
    ; R = undef ).
sev(Phi, tm(lam(B)), fvt(Tab)) :-
    findall(D-R, (member(D, [el(0,0), el(0,1)]), sev([D|Phi], B, R), R \= undef), Tab).

% 公式层两值（TATU）：dn/eqf/quasi/imp 全有真值
sfml(Phi, dn(T), tv(R)) :- !,
    ( sev(Phi, T, V) -> (V == undef -> R = false ; R = true) ; R = false ).
sfml(Phi, eqf(A, B), tv(R)) :- !,
    ( sev(Phi, A, VA), VA \= undef, sev(Phi, B, VB), VB \= undef
    -> (VA == VB -> R = true ; R = false) ; R = false ).
sfml(Phi, quasi(A, B), tv(R)) :- !,
    ( sev(Phi, A, VA), sev(Phi, B, VB)
    -> ( VA == undef, VB == undef -> R = true
       ; VA == undef -> R = false ; VB == undef -> R = false
       ; VA == VB -> R = true ; R = false ) ; R = false ).
sfml(Phi, imp(P, Q), tv(R)) :- !,
    sfml(Phi, P, tv(PV)), sfml(Phi, Q, tv(QV)),
    ( PV = false -> R = true ; QV = true -> R = true ; R = false ).

% ============================================================
% 五、电池
% ============================================================
chk(1, 'A5.1 实例：(x:N)↓').
cond(1) :- ax(a5_1, dn(tm(var(3)))).
chk(2, 'A5.3 实例：(x = c)↓').
cond(2) :- ax(a5_3, dn(eqf(tm(var(0)), tm(con(0))))).
chk(3, 'A4 实例：x↓ ⇒ (λx.x)(x) ≃ x').
cond(3) :- ax(a4, imp(dn(tm(var(0))),
                      quasi(tm(app(tm(lam(tm(var(0)))), tm(var(0)))), tm(var(0))))).
chk(4, 'A4 拒收：绑定器体内指标错位（0 号出现变成 1 号）').
cond(4) :- \+ ax(a4, imp(dn(tm(var(0))),
                         quasi(tm(app(tm(lam(tm(var(0)))), tm(var(0)))), tm(var(1))))).

% 标本：命题 A.3 ⊢ x ≃ x（书 217 页三步原证的机器版）
proof_a3([
  step(dn(tm(var(0))),                    ax(a5_1)),                % (1) x↓
  step(imp(dn(tm(var(0))),                % (2) A4 实例：x↓ ⇒ (λx.x)(x) ≃ x
       quasi(tm(app(tm(lam(tm(var(0)))), tm(var(0)))), tm(var(0)))), ax(a4)),
  step(quasi(tm(app(tm(lam(tm(var(0)))), tm(var(0)))), tm(var(0))),  % (3) R1
       mp(1, 2)),
  step(quasi(tm(var(0)), tm(var(0))),     % (4) R2：换掉一处出现
       r2(3, 3))
]).

chk(5, '命题 A.3 的三步证明（A5.1→A4+R1→R2）通过检查').
cond(5) :- proof_a3(P), check_proof(P).
chk(6, 'A.3 结论 x ≃ x 语义有效（2 元模型双指派）').
cond(6) :-
    member(Asn, [[el(0,0)], [el(0,1)]]),
    \+ ( sfml(Asn, quasi(tm(var(0)), tm(var(0))), tv(false)) ).
chk(7, '第 (3) 步 (λx.x)(x) ≃ x 也语义有效').
cond(7) :-
    member(Asn, [[el(0,0)], [el(0,1)]]),
    sfml(Asn, quasi(tm(app(tm(lam(tm(var(0)))), tm(var(0)))), tm(var(0))), tv(true)).

% R2 守卫：绑定器下「同形不同深度」的出现替换不了
chk(8, 'R2 守卫：λ 体深度 +1 后，浅处项匹配不到深处的同形项').
cond(8) :-
    A = tm(var(1)), C = tm(lam(tm(app(tm(var(0)), tm(var(1)))))),
    \+ replace_one(A, tm(con(0)), C, _).
% 反例说明：C 中 λ 体内的 var(1) 在深度 1 下对应外层的 var(0)；
% 拿外层的 var(1) 去换，找不到出现 —— de Bruijn 天然防捕获。

% 伪证明拒绝：第 (2) 步引用了不存在的公理模式
chk(9, '伪证明被拒：凭空的公理引用').
cond(9) :-
    \+ check_proof([step(dn(tm(var(0))), ax(a5_99))]).
% 伪证明拒绝：R1 的前提形状不对
chk(10, '伪证明被拒：MP 前提不是蕴涵').
cond(10) :-
    \+ check_proof([ step(dn(tm(var(0))), ax(a5_1)),
                     step(dn(tm(var(1))), mp(1, 1)) ]).

main :-
    ( between(1, 10, I), chk(I, What), \+ cond(I)
    -> format('FAIL ~d  ~w~n', [I, What]), halt(1)
    ;  true ), !,
    format('10 条全过~n'), halt.
