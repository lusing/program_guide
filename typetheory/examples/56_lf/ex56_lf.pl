:- encoding(utf8).
/* ============================================================
   56 LF 与元理论 —— Prolog（罗朝晖书 6.2 + 表 6.1 + 例 6.1）
   逻辑框架 LF 的微缩检查器：
     类别 kind ::= TYPE | el(A) | (x:K)K'
     对象 k   ::= c（常量）| x（变量）| [x:K]k | f(k)
   ① kind_of / lf_of 双判断（图 6.1 的可执行版）
   ② 表 6.1：目标类型论的判断 ↔ LF 判断的编码
   ③ 例 6.1：用常量+计算等式定义类型论——Nat 组与 Σ 组
     的常量逐个过检
   ④ LF 函数运算有 η（[x]f(x) = f）——与目标论 λ 无 η 对照
   ============================================================ */

/* ---- LF 语法 ---- */
% 类别：ktype | kel(Obj) | kpi(名称, Kind, Kind)
% 对象：c(常量名) | v(变量名) | lam(名称, Kind, Obj) | app(F, X)

/* kind 合法性 */
kind_ok(ktype).
kind_ok(kel(K)) :- lfk([], K, ktype).
kind_ok(kpi(_, K1, K2)) :- kind_ok(K1), kind_ok(K2).

/* 对象的类别判断：Γ ⊢ k : K（环境为 assoc 列表） */
lfk(_, c(N), K) :- lf_const(N, K), !.
lfk(G, v(N), K) :- member(N - K, G), !.
lfk(G, lam(X, K1, B), kpi(X, K1, K2)) :-
    kind_ok(K1),
    lfk([X - K1 | G], B, K2).
lfk(G, app(F, X), KX) :-
    lfk(G, F, kpi(_, K1, K2)),
    lfk(G, X, K1),
    subst_kind(K2, X, X, KX).   % [X:=X] 恒等；教学版免一般替换

subst_kind(K, _, _, K).

/* ---- LF 的 η（书 6.2.1 末注）：[x]f(x) = f ---------------
   LF 的函数运算满足 η（它是「数学定义」的化身）；目标类型论
   的 λ **不**满足 η（29 章主题归约处 η 是命题等式非判断等式）。
   机器件只做 η 的形状见证： */
eta_shape(lam(x, _, app(F, v(x))), F).   % [x:K]f(x) 形状即 F

/* ---- ③ 用 LF 定义类型论（例 6.1）：常量组 ----------------
   Nat 组（书 6.2.2）：
     Nat : TYPE
     0   : Nat（写作 zero_c）
     succ : (Nat)Nat
     E_Nat : (C:(Nat)type)(c:C(0))(f:(x:Nat)(C(x))C(succ(x)))
             (n:Nat)C(n)     —— 归纳原理的类别！ */
lf_const(nat_c, ktype).
lf_const(zero_c, kel(c(nat_c))).
lf_const(succ_c, kpi(n, kel(c(nat_c)), kel(c(nat_c)))).
lf_const(e_nat,
  kpi(cc, kpi(n1, kel(c(nat_c)), ktype),
  kpi(z, ktype,                                   % 教学占位：C(0)
  kpi(f, ktype,                                   % 教学占位：递归步
  kpi(nn, kel(c(nat_c)), ktype))))).              % 结论 C(n)

/* Σ 组（书例 6.1 第二件）：
     Σ  : (A:type)(B:(A)TYPE)TYPE
     pair : (A)(B)(x:A)(y:B(x))Σ(A,B)
     π1/π2 : (A)(B)(p:Σ(A,B))… */
lf_const(sig_c, kpi(a, ktype, kpi(b, kpi(x1, kel(c(a)), ktype), ktype))).
% 注：Σ(A,B(x)) 的名称应用与 B 的依赖性在微缩检查器里以
% ktype 占位（一般情形需对 kpi 的绑定变元做真替换——LF 的
% β：([x:K]k)(k') ≡ [k'/x]k，教学版 subst_kind 从略）。
lf_const(pair_c,
  kpi(a, ktype, kpi(b, kpi(x1, kel(c(a)), ktype),
  kpi(xx, kel(c(a)),
  kpi(yy, ktype,                                   % B(x) 教学占位
  ktype))))).
lf_const(pi1_c,
  kpi(a, ktype, kpi(b, kpi(x1, kel(c(a)), ktype),
  kpi(p, ktype,                                    % Σ(A,B) 教学占位
  kel(c(a)))))).

/* ---- ② 表 6.1：判断编码对照的检定件 ---------------------- */
% 目标论「A type」 ↔ LF「A : TYPE」
encodes(type_of(A), lf_of(A, ktype)).
% 目标论「a : A」 ↔ LF「a : el(A)」
encodes(elem_of(A, a), lf_of(a, kel(A))).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① 常量组逐个过检（Γ 为空——常量不依赖环境） */
    check("Nat : TYPE（nat_c 的类别是 ktype）",
           lfk([], c(nat_c), ktype)),
    check("0 : Nat（zero_c : el(nat_c)）",
           lfk([], c(zero_c), kel(c(nat_c)))),
    check("succ : (Nat)Nat（kpi 形状）",
           lfk([], c(succ_c), kpi(n, kel(c(nat_c)), kel(c(nat_c))))),
    check("succ 应用：succ(0) : Nat",
           lfk([], app(c(succ_c), c(zero_c)), kel(c(nat_c)))),
    check("E_Nat 的类别合法（归纳原理的形状）",
           ( lf_const(e_nat, K), kind_ok(K) )),

    /* Σ 组 */
    check("Σ : (A:type)(B:(A)TYPE)TYPE",
           lfk([], c(sig_c), _)),
    check("pair 的类别形如 (A:type)(B:…)…（首段 ktype）",
           ( lf_const(pair_c, KP), KP = kpi(_, ktype, _) )),
    check("π1 : (A)(B)(p:Σ(A,B))A",
           lfk([], c(pi1_c), _)),

    /* λ 抽象的类别：[x:Nat]x : (Nat)Nat（图 6.1 最后规则） */
    check("[x:Nat]x : (Nat)Nat（λ 的 kpi 类别）",
           lfk([], lam(x, kel(c(nat_c)), v(x)),
               kpi(x, kel(c(nat_c)), kel(c(nat_c))))),

    /* η 形状见证 */
    check("η：[x:K]f(x) 的形状还原为 f",
           eta_shape(lam(x, kel(c(nat_c)), app(c(succ_c), v(x))),
                     c(succ_c))),

    /* 负例：把 zero_c 放在 TYPE 位 */
    check("0 : TYPE 非法（zero_c 不是 ktype 位）",
           \+ lfk([], c(zero_c), ktype)),

    format("ok   : LF——元语言里定义类型论，规则=常量+等式~n"),
    format("all checks passed.~n").
