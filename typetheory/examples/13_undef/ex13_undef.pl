:- encoding(utf8).
:- discontiguous chk/2, cond/1.
% ============================================================
% 13 未定义性 —— Prolog 对照实验室（Farmer 3.4/6.4）
% 两个「带无定义的逻辑」正面相撞：
%   · 强 Kleene 三值逻辑（K3）：公式可以取第三值 u
%   · TATU（负自由逻辑，Alonzo 的立场）：公式恒两值，
%     无定义谓词应用一律折成 f，部分性只住在非布尔层
% 对照样本：除法表（分母为 0 处缺键 = 无定义）
% ============================================================

% ============================================================
% 一、强 Kleene 三值表
% ============================================================
k3_not(t, f).  k3_not(f, t).  k3_not(u, u).
k3_or(t, _, t).
k3_or(_, t, t).
k3_or(f, f, f).
k3_or(f, u, u).  k3_or(u, f, u).  k3_or(u, u, u).
k3_and(f, _, f).
k3_and(_, f, f).
k3_and(t, t, t).
k3_and(t, u, u).  k3_and(u, t, u).  k3_and(u, u, u).
k3_imp(A, B, V) :- k3_not(A, NA), k3_or(NA, B, V).

% K3 项值域与公式求值（公式可取 u）
k3_eq(A, B, V) :- (A == u -> V = u ; B == u -> V = u ; A == B -> V = t ; V = f).
k3_fml(eq(A,B), V)    :- !, k3_eq(A, B, V).
k3_fml(not(A), V)     :- !, k3_fml(A, VA), k3_not(VA, V).
k3_fml(or(A,B), V)    :- !, k3_fml(A,VA), k3_fml(B,VB), k3_or(VA,VB,V).
k3_fml(and(A,B), V)   :- !, k3_fml(A,VA), k3_fml(B,VB), k3_and(VA,VB,V).
k3_fml(imp(A,B), V)   :- !, k3_fml(A,VA), k3_fml(B,VB), k3_imp(VA,VB,V).
% 叶子：公式位置上直接给值（sub_2 已把变量换成值）
k3_fml(u, u).  k3_fml(t, t).  k3_fml(f, f).

% K3 重言式检查：所有赋值下都为 t？
k3_vals([u, t, f]).
k3_taut(F) :-
    \+ ( k3_vals(L), member(A, L), member(B, L),
         sub_2(F, A, B, G), k3_fml(G, V), V \= t ).

% 只含一个变量的公式包装
sub_2(eq(x, x), A, _, eq(A, A)).
sub_2(or(not(x), x), A, _, or(not(A), A)).
sub_2(imp(x, x), A, _, imp(A, A)).
sub_2(and(x, x), A, _, and(A, A)).
% 双变量样本（排中律的另一面：蕴含三分律）
sub_2(imp(or(x, not(x)), and(y, y)), A, B, imp(or(A, not(A)), and(B, B))).
sub_2(imp(x, or(x, y)), A, B, imp(A, or(A, B))).

% ============================================================
% 二、TATU：除法样本 + 两值公式层
% ============================================================
% 除法表（整数除；分母 0 的行【缺键 = 无定义】）
div_entry((0,1), 1).  div_entry((0,2), 0).
div_entry((1,1), 1).  div_entry((1,2), 0).
div_entry((2,1), 2).  div_entry((2,2), 1).

tval(over(X,Y), V) :-              % 部分函数：表查询，缺键 = undef
    ( div_entry((X,Y), R) -> V = num(R) ; V = undef ).
tval(num(K), num(K)).

% 公式层恒两值（V4 的 o-落点）
tfml(eq(A,B), V) :-
    tval(A,VA), tval(B,VB),
    ( VA == undef -> V = f ; VB == undef -> V = f
    ; VA == VB -> V = t ; V = f ).
tfml(quasi(A,B), V) :-             % ≃：双无定义也算等
    tval(A,VA), tval(B,VB),
    ( VA == undef, VB == undef -> V = t
    ; VA == undef -> V = f ; VB == undef -> V = f
    ; VA == VB -> V = t ; V = f ).
tfml(dn(A), V) :- tval(A, VA), (VA == undef -> V = f ; V = t).
tfml(not(A), V) :- !, tfml(A, VA), bool_not(VA, V).
tfml(or(A,B), V)  :- !, tfml(A,VA), tfml(B,VB), bool_or(VA,VB,V).
tfml(and(A,B), V) :- !, tfml(A,VA), tfml(B,VB), bool_and(VA,VB,V).
tfml(imp(A,B), V) :- !, tfml(A,VA), tfml(B,VB), bool_not(VA,NA), bool_or(NA,VB,V).

bool_not(t, f). bool_not(f, t).
bool_or(t, _, t). bool_or(_, t, t). bool_or(f, f, f).
bool_and(t, t, t). bool_and(f, _, f). bool_and(_, f, f).

% ============================================================
% 三、电池（chk 事实 + cond 体）
% ============================================================
chk(1, 'K3：A∨¬A 在 u 处塌掉（非重言式）').
cond(1) :- \+ k3_taut(or(not(x), x)).

chk(2, 'K3：A⇒A 在 u 处塌掉（u⇒u = u ≠ t）').
cond(2) :- \+ k3_taut(imp(x, x)).

chk(3, 'K3：A∧A 在 u 处塌掉').
cond(3) :- \+ k3_taut(and(x, x)).

chk(4, 'K3：undef = undef 取第三值 u').
cond(4) :- k3_eq(u, u, u).

chk(5, 'TATU：1/0 = 1 为假').
cond(5) :- tfml(eq(over(1,0), num(1)), f).

chk(6, 'TATU：1/0 = 1/0 为假（= 须双定义）').
cond(6) :- tfml(eq(over(1,0), over(1,0)), f).

chk(7, 'TATU：1/0 ≃ 1 为假（一边有定义）').
cond(7) :- tfml(quasi(over(1,0), num(1)), f).

chk(8, 'TATU：1/0 ≃ 1/0 为真（双无定义也算等）').
cond(8) :- tfml(quasi(over(1,0), over(1,0)), t).

chk(9, 'TATU：2/1 = 2 为真（定义区照常）').
cond(9) :- tfml(eq(over(2,1), num(2)), t).

chk(10, 'TATU：(1/0)↓ 为假、(2/1)↓ 为真').
cond(10) :- tfml(dn(over(1,0)), f), tfml(dn(over(2,1)), t).

chk(11, 'TATU：含无定义的公式照样两值——(1/0=1) ⇒ (1/0=1) 为真').
cond(11) :- tfml(imp(eq(over(1,0), num(1)), eq(over(1,0), num(1))), t).

chk(12, 'TATU：¬(1/0=1/0) 为真——V3 的锋利处').
cond(12) :- tfml(not(eq(over(1,0), over(1,0))), t).

chk(13, '分野：同输入 K3 给 u、TATU 给 f').
cond(13) :- k3_eq(u, u, u), tfml(eq(over(1,0), over(1,0)), f).

main :-
    ( between(1, 13, I), chk(I, What), \+ cond(I)
    -> format('FAIL ~d  ~w~n', [I, What]), halt(1)
    ;  true ), !,
    format('13 条全过~n'), halt.
