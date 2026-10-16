:- encoding(utf8).
:- discontiguous base_size/3, tab/3, arrow_dom/3, interp/4.
:- discontiguous chk/2, cond/1.
% ============================================================
% 12 Alonzo：Church 式简单类型论 —— Prolog 侧（Farmer ch.4–5）
% 语义实验室：广义模型的 V1–V7 部分赋值逐条落地
%   · 值：tv(true/false) | el(基型标签,元素号) | fv(表) | pv(A,B)
%     无定义 = 原子 undef；函数表缺键 = 该点无定义
%   · Henkin 条款可执行化：lam 的指称必须落在手选域（frame_ok/2）
%   · 同构引理 5.12 引擎：换标模型 m1s 上重算同一批闭式，值随 θ 走
%   · 最小语言的最小模型：从 ty(o) 出发，λx.x 与 K 组合子都落域
% ============================================================

% ---- 类型检查 type_of(+Depth, +Tm, -Ty)（简化：深度只对 var 查） ----
type_of(D, tm(var(X,Ty)), Ty) :- X < D.
type_of(_, tm(con(_,Ty)), Ty).
type_of(D, tm(eq(A,B)), ty(o)) :-
    type_of(D,A,T), type_of(D,B,T).
type_of(D, tm(app(F,A)), Beta) :-
    type_of(D,F,ty(arr(Al,Beta))), type_of(D,A,Al).
type_of(D, tm(lam(X,B)), ty(arr(X,Beta))) :- D1 is D+1, type_of(D1,B,Beta).
type_of(D, tm(des(X,A)), X) :- D1 is D+1, type_of(D1,A,ty(o)).
type_of(D, tm(pair(A,B)), ty(prod(TA,TB))) :-
    type_of(D,A,TA), type_of(D,B,TB).

% ============================================================
% m1：|D_N| = 2，plus = 模 2 加；D_{N→N} 装 4 张表（16 选 4）
% ============================================================
base_size(m1, 0, 2).

tab(m1, id,     [el(0,0)-el(0,0), el(0,1)-el(0,1)]).
tab(m1, const0, [el(0,0)-el(0,0), el(0,1)-el(0,0)]).
tab(m1, const1, [el(0,0)-el(0,1), el(0,1)-el(0,1)]).
tab(m1, delta,  []).
tab(m1, plus,   [pv(el(0,0),el(0,0))-el(0,0), pv(el(0,0),el(0,1))-el(0,1),
                 pv(el(0,1),el(0,0))-el(0,1), pv(el(0,1),el(0,1))-el(0,0)]).
tab(m1, p_all,  [el(0,0)-tv(true),  el(0,1)-tv(true)]).
tab(m1, p_0,    [el(0,0)-tv(true),  el(0,1)-tv(false)]).
tab(m1, p_1,    [el(0,0)-tv(false), el(0,1)-tv(true)]).
tab(m1, p_none, [el(0,0)-tv(false), el(0,1)-tv(false)]).

arrow_dom(m1, ty(arr(ty(b(0)),ty(b(0)))),      [id, const0, const1, delta]).
arrow_dom(m1, ty(arr(ty(prod(ty(b(0)),ty(b(0)))),ty(b(0)))), [plus]).
arrow_dom(m1, ty(arr(ty(b(0)),ty(o))),         [p_all, p_0, p_1, p_none]).

interp(m1, 0, ty(b(0)), el(0,0)).
interp(m1, 1, ty(b(0)), el(0,1)).
interp(m1, 2, ty(arr(ty(prod(ty(b(0)),ty(b(0)))),ty(b(0)))), fv(T)) :- tab(m1, plus, T).
interp(m1, 3, ty(arr(ty(b(0)),ty(b(0)))), fv(T)) :- tab(m1, delta, T).

% ---- m1bad：D_{N→N} 故意缺常 1 函数 —— λx.c1 落不了域 ----
base_size(m1bad, 0, 2).
tab(m1bad, N, T) :- tab(m1, N, T).
arrow_dom(m1bad, ty(arr(ty(b(0)),ty(b(0)))), [id, const0, delta]).
arrow_dom(m1bad, T, Ns) :- arrow_dom(m1, T, Ns), T \= ty(arr(ty(b(0)),ty(b(0)))).
interp(m1bad, C, Ty, V) :- interp(m1, C, Ty, V).

% ============================================================
% 域与求值
% ============================================================
dom(_, ty(o), [tv(false), tv(true)]).
dom(M, ty(b(N)), Es) :-
    base_size(M, N, K), findall(el(N,D), (between(0,K,D), D < K), Es).
dom(M, ty(arr(A,B)), Fs) :-
    arrow_dom(M, ty(arr(A,B)), Names), maplist(tab_of(M), Names, Fs).
dom(M, ty(prod(A,B)), Ps) :-
    dom(M, A, As), dom(M, B, Bs),
    findall(pv(X,Y), (member(X,As), member(Y,Bs)), Ps).

tab_of(M, Name, fv(T)) :- tab(M, Name, T).

% ---- V1–V7：eval(+Model, +Phi, +Tm, -Val)（可为 undef） ----
eval(_, Phi, tm(var(X,_)), V) :- nth0(X, Phi, V).                 % V1
eval(M, _, tm(con(C,Ty)), V) :- interp(M, C, Ty, V).             % V2
eval(M, Phi, tm(eq(A,B)), tv(R)) :-                              % V3：等式永远有定义
    ( defined(M,Phi,A,VA), defined(M,Phi,B,VB)
    -> (VA == VB -> R = true ; R = false)
    ;  R = false ).
eval(M, Phi, tm(app(F,A)), R) :-                                 % V4
    type_of(0, F, ty(arr(_,Beta))), !,
    ( defined(M,Phi,F,fv(Tab)), defined(M,Phi,A,VA), memberchk(VA-R0, Tab)
    -> R = R0
    ;  ( Beta == ty(o) -> R = tv(false) ; R = undef ) ).
eval(M, Phi, tm(lam(X,B)), fv(Tab)) :-                           % V5：逐点成表
    dom(M, X, Ds),
    findall(D-R, (member(D,Ds), defined(M,[D|Phi],B,R)), Tab).
eval(M, Phi, tm(des(X,A)), R) :-                                 % V6：恰一满足者
    dom(M, X, Ds), include(sat(M,Phi,A), Ds, Hit),
    ( Hit = [D] -> R = D ; R = undef ).
eval(M, Phi, tm(pair(A,B)), R) :-                                % V7：严格对
    ( defined(M,Phi,A,VA), defined(M,Phi,B,VB) -> R = pv(VA,VB) ; R = undef ).

defined(M, Phi, T, V) :- eval(M, Phi, T, V), V \= undef.
sat(M, Phi, A, D) :- eval(M, [D|Phi], A, tv(true)).

% ============================================================
% Henkin 落域检查
% ============================================================
sub_tm(T, T).
sub_tm(tm(app(F,A)), S) :- !, ( sub_tm(F,S) ; sub_tm(A,S) ).
sub_tm(tm(eq(A,B)),  S) :- !, ( sub_tm(A,S) ; sub_tm(B,S) ).
sub_tm(tm(pair(A,B)),S) :- !, ( sub_tm(A,S) ; sub_tm(B,S) ).
sub_tm(tm(lam(_,B)),  S) :- !, sub_tm(B,S).
sub_tm(tm(des(_,A)),  S) :- !, sub_tm(A,S).

% t 的每个 λ 子式指称都落在对应手选域内（Henkin 条款）
frame_ok(M, T) :-
    \+ ( sub_tm(T, S), S = tm(lam(X,_)),
         type_of(0, S, ty(arr(X,Beta))),
         eval(M, [], S, fv(Tab)),
         \+ ( arrow_dom(M, ty(arr(X,Beta)), Names),
              member(Nn, Names), tab(M, Nn, Tab) ) ).

% ============================================================
% 同构换标（引理 5.12 / 推论 5.13 的引擎）
% ============================================================
theta(el(0,0), el(0,1)).
theta(el(0,1), el(0,0)).
theta(tv(X), tv(X)).
theta(pv(A,B), pv(AS,BS)) :- theta(A,AS), theta(B,BS).

% m1s：把 m1 的所有表与常数沿 θ 换标
tab(m1s, N, TS) :- tab(m1, N, T), maplist([A-B,AS-BS]>>((theta(A,AS),theta(B,BS))), T, TS).
base_size(m1s, 0, 2).
arrow_dom(m1s, Arr, Ns) :- arrow_dom(m1, Arr, Ns).
interp(m1s, 0, ty(b(0)), W) :- interp(m1, 0, ty(b(0)), V), theta(V, W).
interp(m1s, 1, ty(b(0)), W) :- interp(m1, 1, ty(b(0)), V), theta(V, W).
interp(m1s, C, Ty, W) :- interp(m1, C, Ty, V), C >= 2, theta_val(V, W).

theta_val(fv(T), fv(TS)) :- maplist([A-B,AS-BS]>>((theta(A,AS),theta(B,BS))), T, TS).

% ============================================================
% 最小语言的最小模型：基型空，一切从 ty(o) 长出
% ============================================================
tab(mmin, id_o,  [tv(false)-tv(false), tv(true)-tv(true)]).
tab(mmin, not_o, [tv(false)-tv(true),  tv(true)-tv(false)]).
tab(mmin, cst_t, [tv(false)-tv(true),  tv(true)-tv(true)]).
tab(mmin, cst_f, [tv(false)-tv(false), tv(true)-tv(false)]).
% K = λx:o.λy:o.x 的指称：两张常函数表的表
tab(mmin, k_o, [tv(false)-fv([tv(false)-tv(false),tv(true)-tv(false)]),
                tv(true)-fv([tv(false)-tv(true),tv(true)-tv(true)])]).
base_size(mmin, 0, 0).
arrow_dom(mmin, ty(arr(ty(o),ty(o))), [id_o, not_o, cst_t, cst_f]).
arrow_dom(mmin, ty(arr(ty(o),ty(arr(ty(o),ty(o))))), [k_o]).

% ============================================================
% 电池
% ============================================================
% ---- 电池：chk(编号, 描述, 目标) 逐条执行，失败即报并 halt(1) ----
t_x(T)   :- T = tm(var(0, ty(b(0)))).
t_c0(T)  :- T = tm(con(0, ty(b(0)))).
t_c1(T)  :- T = tm(con(1, ty(b(0)))).
t_plus(T) :- T = tm(con(2, ty(arr(ty(prod(ty(b(0)), ty(b(0)))), ty(b(0)))))).
t_delta(T) :- T = tm(con(3, ty(arr(ty(b(0)), ty(b(0)))))).

chk(1, '例5.3：(λx.plus(x,x)=c1) 0 ↦ f').
cond(1) :-    t_x(X), t_c0(C0), t_c1(C1), t_plus(P),
    A = tm(app(P, tm(pair(X, X)))),
    B = tm(eq(A, C1)),
    eval(m1, [], tm(app(tm(lam(ty(b(0)), B)), C0)), tv(false)).
chk(2, 'V6 恰一：I x. x=c0 ↦ 0').
cond(2) :-    t_x(X), t_c0(C0),
    eval(m1, [], tm(des(ty(b(0)), tm(eq(X, C0)))), el(0,0)).
chk(3, 'V6 二义：I x. x=x ↦ undef').
cond(3) :-    t_x(X), eval(m1, [], tm(des(ty(b(0)), tm(eq(X, X)))), undef).
chk(4, 'V6 零满足：⊥_N ↦ undef').
cond(4) :-    t_x(X), t_c0(C0), t_c1(C1),
    eval(m1, [], tm(des(ty(b(0)), tm(eq(tm(eq(X, C0)), tm(eq(X, C1)))))), undef).
chk(5, 'V3 锋利：⊥ = ⊥ 为假').
cond(5) :-    t_x(X), t_c0(C0), t_c1(C1),
    Bot = tm(des(ty(b(0)), tm(eq(tm(eq(X, C0)), tm(eq(X, C1)))))),
    eval(m1, [], tm(eq(Bot, Bot)), tv(false)).
chk(6, 'V4 不对称：∆ c0 = c0 为假').
cond(6) :-    t_c0(C0), t_delta(D),
    eval(m1, [], tm(eq(tm(app(D, C0)), C0)), tv(false)).
chk(7, 'V7 严格对：含 ∆ 应用的序对 ↦ undef').
cond(7) :-    t_c0(C0), t_delta(D),
    eval(m1, [], tm(pair(tm(app(D, C0)), C0)), undef).
chk(8, 'Henkin：m1 覆盖 λx.c1').
cond(8) :-    t_c1(C1), frame_ok(m1, tm(lam(ty(b(0)), C1))).
chk(9, 'Henkin：m1bad 不覆盖 λx.c1（非广义模型）').
cond(9) :-    t_c1(C1), \+ frame_ok(m1bad, tm(lam(ty(b(0)), C1))).
chk(10, '5.9 引擎：4 个 λ 项给出 4 个互异谓词且全落域').
cond(10) :-    t_x(X), t_c0(C0), t_c1(C1),
    findall(T, ( member(E, [
            tm(lam(ty(b(0)), tm(eq(X, X)))),
            tm(lam(ty(b(0)), tm(eq(X, C0)))),
            tm(lam(ty(b(0)), tm(eq(X, C1)))),
            tm(lam(ty(b(0)), tm(eq(tm(eq(X, C0)), tm(eq(X, C1)))))) ]),
          eval(m1, [], E, fv(T))), Tabs),
    length(Tabs, 4),
    setof(T, member(T, Tabs), Set), length(Set, 4),
    maplist([T]>>(tab(m1, _, T)), Set).
chk(11, '同构 5.12/5.13：I x.x=c0 的值随 θ 走').
cond(11) :-    t_x(X), t_c0(C0),
    D = tm(des(ty(b(0)), tm(eq(X, C0)))),
    eval(m1, [], D, V1), theta(V1, V1s),
    eval(m1s, [], D, V1s).
chk(12, '最小模型：λx.x 落域').
cond(12) :-    frame_ok(mmin, tm(lam(ty(o), tm(var(0, ty(o)))))).
chk(13, '最小模型：K 落域（满空间含常函数）').
cond(13) :- frame_ok(mmin, tm(lam(ty(o), tm(lam(ty(o), tm(var(1, ty(o)))))))).

main :-
    ( between(1, 13, I), chk(I, What), \+ cond(I)
    -> format('FAIL ~d  ~w~n', [I, What]), halt(1)
    ;  true ), !,
    format('13 条全过~n'), halt.
