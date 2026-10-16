:- encoding(utf8).
/* ============================================================
   06 等式规则与语义完备性 —— Prolog：4B 有限结构实验室
   Hindley BSTT 4B3–4B7 的机器面：
     · 类型解释 ||σ→τ||V = {d | ∀e∈||σ||: d·e ∈ ||τ||}（4B5）
     · (→E) 的可靠性【由定义直接成立】——箭头解释就是 modus ponens
     · 外延性（4B3）是真实限制：见证非外延结构
     · (D,·) 不配叫 λ-模型：K/S 无家可归（组合完全性缺失）
   约定：main/0 打勾收尾；任一检查失败即 fail（build 通道判 1）。
   ============================================================ */

/* ---- 论域 D = {a0,a1,a2} 与应用表 ----
   a1 的行是恒等（a1·e = e）；a2 的行抄了 a0 —— 这正是非外延的见证。 */
d(a0). d(a1). d(a2).

app(a0,a0,a1). app(a0,a1,a2). app(a0,a2,a0).
app(a1,a0,a0). app(a1,a1,a1). app(a1,a2,a2).
app(a2,a0,a1). app(a2,a1,a2). app(a2,a2,a0).

/* ---- 4B5：类型的解释。
   类型词法：tv(X)（类型变元）| ar(S,T)（箭头 σ→τ）。
   赋值 V 是 [tv(X)-Set, ...] 形式的表；Set 是 D 的子集表。 */
interp(tv(X), V, S) :- member(X-S, V), !.
interp(ar(S,T), V, Set) :-
    interp(S, V, Ss), interp(T, V, Ts),
    findall(D, ( d(D),
                 forall( (d(E), member(E,Ss)),
                         (app(D,E,R), memberchk(R,Ts)) ) ),
            Set).

/* ---- 检查宏：名字 + 目标，失败即报错退出 ---- */
check(Name, Goal) :-
    ( call(Goal) -> format("ok   ~w~n", [Name])
    ; format("FAIL ~w~n", [Name]), halt(1) ).

main :-
    /* 赋值样本：p ↦ {a1}，q ↦ {a1,a2}，r ↦ {}（空类型合法！） */
    V = [p-[a1], q-[a1,a2], r-[]],

    /* ① 箭头解释按定义枚举：p→q 与 p→p 的成员逐一算出 */
    interp(ar(tv(p),tv(q)), V, PQ),
    format("||p->q||  = ~w~n", [PQ]),
    interp(ar(tv(p),tv(p)), V, PP),
    format("||p->p||  = ~w~n", [PP]),

    /* ② (→E) 的可靠性是箭头解释的定义式面目：
       d ∈ ||σ→τ|| 且 e ∈ ||σ|| ⟹ d·e ∈ ||τ||——对一切箭头与成员成立 */
    check("(->E) soundness by construction",
          forall( ( member(Sym1,[p,q,r]), member(Sym2,[p,q,r]),
                    interp(ar(tv(Sym1),tv(Sym2)), V, Fs),
                    member(F,Fs),
                    interp(tv(Sym1), V, As),
                    member(A,As) ),
                  ( app(F,A,R),
                    interp(tv(Sym2), V, Ts),
                    memberchk(R,Ts) ) )),

    /* ③ r = ∅ 的奇观：p→r 里的成员须满足 d·a1 ∈ ∅——无人胜任；
       但 r→p 人人胜任（空洞前提免费送）——空类型在语义侧的滋味 */
    interp(ar(tv(r),tv(p)), V, RP),
    check("||r->p|| = D  (vacuous premise)", RP == [a0,a1,a2]),
    interp(ar(tv(p),tv(r)), V, PR),
    check("||p->r|| = []  (unsatisfiable)", PR == []),

    /* ④ 非外延见证（4B3）：a0 与 a2 处处同心，却不是同一个元素 */
    check("non-extensional witness a0/a2",
          ( forall(d(E), (app(a0,E,R1), app(a2,E,R2), R1 == R2)),
            a0 \= a2 )),

    /* ⑤ 外延性对箭头解释的影响：a0 与 a2 同居每个 ||σ→τ||
       （外延性失败 ⟹ βη 不可靠，4B4(ii) 的语义侧前兆） */
    check("a0 and a2 cohabit every arrow set",
          forall( ( member(Sym1,[p,q,r]), member(Sym2,[p,q,r]),
                    interp(ar(tv(Sym1),tv(Sym2)), V, Fs) ),
                  ( memberchk(a0,Fs) -> memberchk(a2,Fs) ; true ) )),

    /* ⑥ 为什么 (D,·) 还不配叫 λ-模型（4B2）：
       K 需要 k 使 k·d1·d2 = d1 对一切 d1,d2 成立——全城搜不到；
       S 需要 s 使 s·d1·d2·d3 = d1·d3·(d2·d3)——同样搜不到。
       没有组合完全性的应用结构无法解释一切 λ-项。 */
    check("no K-like element in D",
          \+ ( d(Kk), forall( (d(D1),d(D2)),
                              ( app(Kk,D1,C1), app(C1,D2,D1) ) ) )),
    check("no S-like element in D",
          \+ ( d(Ss), forall( (d(D1),d(D2),d(D3)),
                              ( app(Ss,D1,C1), app(C1,D2,C2), app(C2,D3,Lhs),
                                app(D1,D3,X1), app(D2,D3,X2), app(X1,X2,Rhs),
                                Lhs == Rhs ) ) )),

    /* ⑦ 反向对照：恒等【是】可解释的（a1 扮演 I）——
       孤立的常元可以有家；成套的组合子才要模型结构 */
    check("identity is definable (a1 plays I)",
          forall( (d(D1), app(a1,D1,R)), R == D1 )),

    format("all checks passed.~n").
