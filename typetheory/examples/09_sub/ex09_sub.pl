:- encoding(utf8).
/* ============================================================
   09 弱逻辑与子结构 λ —— Prolog：Hilbert 式 A-逻辑实验室（6D）
   四系统的公理集（6D3–6D6）：
     Intuitionist = {B, C, K, W}    R_ = {B, C, I, W}
     BCK          = {B, C, K}       BCI = {B, C, I}
   公理 = 对应组合子的主类型模式（书末主类型表 3E2a）。
   推理规则：MP（→E）+ 叶端代换（Sub，6D2 substitutions-first 定理：
   代换尽可推到叶端——合一自动完成，这正是 Prolog 的母语）。
   预算口径：可证性用深度 5；「不可证」格是**有界反驳**（深度 4
   内无证明），语义侧的真正排除见 docs 09 章正文。
   ============================================================ */

/* ---- 公理模式：主类型表（类型变元 = Prolog 变量，每次调用新鲜） ---- */
ax(b, arr(arr(A, B), arr(arr(C, A), arr(C, B)))).
ax(c, arr(arr(A, arr(B, C)), arr(B, arr(A, C)))).
ax(i, arr(A, A)).
ax(k, arr(A, arr(_, A))).
ax(w, arr(arr(A, arr(A, B)), arr(A, B))).

/* ---- 四系统（6D3–6D6） ---- */
system(int, [b, c, k, w]).
system(r_,  [b, c, i, w]).
system(bck, [b, c, k]).
system(bci, [b, c, i]).

/* ---- 叶端公理实例：目标与模式合一 = (Sub) 在叶端生效。
   必须 occurs-check：无检查的合一会造出 S = arr(S,…) 的循环项，
   把「无穷公式」当实例放行（本批实测翻车现场，见 docs 09 章）。 ---- */
axiom_instance(Sys, T) :-
    system(Sys, Combs), member(Cb, Combs),
    ax(Cb, Schema), unify_with_occurs_check(Schema, T).

/* ---- MP 深度受限搜索：prove(Sys, T, D) ---- */
prove(_, _, 0) :- !, fail.
prove(Sys, T, _) :- axiom_instance(Sys, T).
prove(Sys, T, D) :-
    D > 1, D1 is D - 1,
    prove(Sys, arr(A, T), D1),   % 大前提：某可推出的 σ→T（A 随合一落地）
    prove(Sys, A, D1).           % 小前提：σ 本身

/* ---- 检查宏 ---- */
check(Name, Goal) :-
    ( call(Goal) -> format("ok   ~w~n", [Name])
    ; format("FAIL ~w~n", [Name]), halt(1) ).

main :-
    /* ① I 的地位：r_/bci 里是公理；int/bck 里要靠 C+K 推（6D1.2/6D6.1） */
    check("I in int (derived)",        prove(int, arr(p, p), 5)),
    check("I in r_ (axiom)",           prove(r_,  arr(p, p), 5)),
    check("I in bck (derived, 6D1.2)", prove(bck, arr(p, p), 5)),
    check("I in bci (axiom)",          prove(bci, arr(p, p), 5)),

    /* ② K 的地位：int/bck 公理；r_/bci 不可证（相关/线性不许弱化） */
    check("K in int (axiom)",          prove(int, arr(p, arr(q, p)), 5)),
    check("K in bck (axiom)",          prove(bck, arr(p, arr(q, p)), 5)),
    check("K NOT in r_  (bounded d4)", \+ prove(r_,  arr(p, arr(q, p)), 4)),
    check("K NOT in bci (bounded d4)", \+ prove(bci, arr(p, arr(q, p)), 4)),

    /* ③ W 的地位：int/r_ 公理；bck/bci 不可证（不许收缩） */
    check("W in int (axiom)", prove(int, arr(arr(p, arr(p, q)), arr(p, q)), 5)),
    check("W in r_ (axiom)",  prove(r_,  arr(arr(p, arr(p, q)), arr(p, q)), 5)),
    check("W NOT in bck (bounded d4)",
          \+ prove(bck, arr(arr(p, arr(p, q)), arr(p, q)), 4)),
    check("W NOT in bci (bounded d4)",
          \+ prove(bci, arr(arr(p, arr(p, q)), arr(p, q)), 4)),

    format("all checks passed.~n").
