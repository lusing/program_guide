:- encoding(utf8).
% 第 63 章：命题逻辑（Makinson Ch8）
% 公式求值 + 五关系 + DNF 构造 + 真值树搜索。

% 公式（项编码）：v(P), neg(A), and(A,B), or(A,B)
ev(E, v(P), B) :- !, memberchk(P=B, E).
ev(E, neg(A), R) :- !, ev(E, A, R0), negate(R0, R).
ev(E, and(A,B), R) :- !, ev(E, A, RA), ev(E, B, RB), andb(RA, RB, R).
ev(E, or(A,B), R) :- !, ev(E, A, RA), ev(E, B, RB), orb(RA, RB, R).

negate(1, 0). negate(0, 1).
andb(1,1,1). andb(_,_,0).
orb(0,0,0). orb(_,_,1).


% 永真式：一切赋值下真（三字母 8 行穷举）
taut(F) :-
    forall((between(0,7,M), mask_env(M, E)), ev(E, F, 1)).

mask_env(M, [p=P,q=Q,r=R]) :-
    P is (M >> 2) /\ 1, Q is (M >> 1) /\ 1, R is M /\ 1.

% 非永真：存在赋值使其假
not_taut(F) :-
    between(0,7,M), mask_env(M, E),
    ev(E, F, 0), !.

% → 的缩写
impl(A, B, or(neg(A), B)).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 63~n"),

    % 九条永真蕴含
    impl(v(p),v(q),MP), taut(or(neg(and(v(p),MP)), v(q))),
    format("  MP ✓~n"),
    impl(v(p),v(q),I1), taut(or(neg(and(I1, neg(v(q)))), neg(v(p)))),
    format("  MT ✓~n"),
    taut(or(neg(and(or(v(p),v(q)), neg(v(p)))), v(q))),
    format("  DS ✓~n"),
    taut(or(neg(and(v(p),neg(v(p)))), v(q))),
    format("  右爆炸 ✓~n"),
    taut(or(neg(v(p)), or(v(q),neg(v(q))))),
    format("  左爆炸 ✓~n"),
    impl(v(p),v(q),I2), impl(v(q),v(r),I3), impl(v(p),v(r),I4),
    taut(or(neg(and(I2,I3)), I4)),
    format("  传递 ✓~n"),

    % De Morgan 双向
    taut(or(neg(neg(and(v(p),v(q)))), or(neg(v(p)),neg(v(q))))),
    format("  De Morgan→ ✓~n"),
    taut(or(neg(or(neg(v(p)),neg(v(q)))), neg(and(v(p),v(q))))),
    format("  De Morgan← ✓~n"),

    % 非 Taut 见证
    impl(v(p),v(q),IPQ), impl(IPQ,v(q),NN),
    not_taut(NN),
    format("  (p→q)→q 非永真 ✓~n"),

    % 真值树例：((p∧q)→r)→(p→r) 非 Taut
    impl(and(v(p),v(q)),v(r),I5), impl(v(p),v(r),I6), impl(I5,I6,Big),
    not_taut(Big),
    format("  ((p∧q)→r)→(p→r) 非 Taut ✓（反例 p=1,q=0,r=0）~n"),

    % DNF 语义构造：p→q 的 DNF = (¬p∧¬q)∨(¬p∧q)∨(p∧q)
    DNF = or(and(neg(v(p)),neg(v(q))), or(and(neg(v(p)),v(q)), and(v(p),v(q)))),
    impl(v(p),v(q),PQ),
    taut(or(neg(PQ), DNF)), taut(or(neg(DNF), PQ)),
    format("  p→q 与其 DNF 语义等价 ✓~n"),

    format("END ===="), nl.
