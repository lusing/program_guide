:- encoding(utf8).
% 第 51 章 有限 B-值模型真值表生成器（B = 4 元代数）

% B 的元素：0, u, v, 1（0 < u,v < 1，u v 互不相容）
bel(0). bel(u). bel(v). bel(1).

bmeet(0, _, 0).
bmeet(_, 0, 0).
bmeet(u, u, u). bmeet(u, v, 0). bmeet(u, 1, u).
bmeet(v, u, 0). bmeet(v, v, v). bmeet(v, 1, v).
bmeet(1, X, X).

bjoin(1, _, 1).
bjoin(_, 1, 1).
bjoin(u, u, u). bjoin(u, v, 1). bjoin(u, 0, u).
bjoin(v, u, 1). bjoin(v, v, v). bjoin(v, 0, v).
bjoin(0, X, X).

bnot(0, 1). bnot(u, v). bnot(v, u). bnot(1, 0).

% 域 = {a, b}；等词与关系指派
dom(a). dom(b).
beq(a, a, 1). beq(b, b, 1). beq(a, b, 0). beq(b, a, 0).
brel(a, a, u). brel(a, b, v). brel(b, a, v). brel(b, b, 1).

% 语义指派（命题闭包 + 一元量词的有限版：sup/inf over dom）
sem(p(X), V) :- dom(X), brel(X, X, V).          % 原子样本
sem(eq(X, Y), V) :- dom(X), dom(Y), beq(X, Y, V).
sem(neg(F), W) :- sem(F, V), bnot(V, W).
sem(and(F, G), W) :- sem(F, V), sem(G, U), bmeet(V, U, W).
sem(or(F, G), W) :- sem(F, V), sem(G, U), bjoin(V, U, W).
sem(ex(X, F), W) :-                             % ∃ = sup over dom
    findall(V, (dom(X), sem(F, V)), Vs),
    foldl_join(Vs, 0, W).
sem(al(X, F), W) :-                             % ∀ = inf over dom
    findall(V, (dom(X), sem(F, V)), Vs),
    foldl_meet(Vs, 1, W).

foldl_join([], W, W).
foldl_join([V | Vs], Acc, W) :- bjoin(V, Acc, A1), foldl_join(Vs, A1, W).
foldl_meet([], W, W).
foldl_meet([V | Vs], Acc, W) :- bmeet(V, Acc, A1), foldl_meet(Vs, A1, W).

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 51 B-值真值表（B = 钻石代数 {0,u,v,1}）~n"),

    % 一、德摩根恒等式在语义层成立
    forall((sem(and(p(a), eq(a,b)), V), sem(neg(and(p(a), eq(a,b))), W),
            sem(or(neg(p(a)), neg(eq(a,b))), U)),
           (bnot(V, W), W == U)),
    format("  ⟦¬(φ∧ψ)⟧ = ¬⟦φ⟧∨¬⟦ψ⟧（De Morgan 语义层）✓~n"),

    % 二、量词的 sup/inf 形态
    sem(ex(X, p(X)), W1), W1 == 1,      % ∃x R(x,x)：u ⊔ 1 = 1
    format("  ⟦∃x R(x,x)⟧ = u ⊔ 1 = 1 ✓~n"),
    sem(al(X, p(X)), W2), W2 == u,      % ∀x R(x,x)：u ⊓ 1 = u（< 1）
    format("  ⟦∀x R(x,x)⟧ = u ⊓ 1 = u（严格小于 1——真值可以是\"未定\"）✓~n"),

    % 三、等词三律
    forall(dom(X), sem(eq(X, X), 1)),
    forall((dom(X), dom(Y)), (sem(eq(X, Y), V), sem(eq(Y, X), V))),
    format("  等词反身、对称 ✓（传递由 0-等词平凡）~n"),

    % 四、量词与联词的分配样例：∃x(φ) ⊨ ∨ 形态
    sem(or(p(a), p(b)), W3), W3 == 1,
    sem(ex(X, p(X)), W3),
    format("  ⟦∃x R(x,x)⟧ = ⟦R(a,a) ∨ R(b,b)⟧ = 1（有限域上量词展开）✓~n"),

    format("END ===="), nl.
