:- encoding(utf8).
% 第 85 章：传递模型（冯琦第二卷 §1.2）——Prolog 通道
% (1) 例 1.7：传递的序数段外延；缺了中间元的载体不再传递。
% (2) 定理 1.22：后继见证的斯科伦闭包把 {0,5} 补成 0..5。
% (3) 引理 1.20 的有限样品：∅ 的单元集链在秩 3 停下。

ord(N) :- between(0, 5, N).

mem(X, Y) :- ord(X), ord(Y), X < Y.

transitive(M) :-
    forall((member(X, M), mem(Y, X)), member(Y, M)).

same_inside(M, A, B) :-
    findall(Z, (member(Z, M), mem(Z, A)), ZA),
    findall(Z, (member(Z, M), mem(Z, B)), ZB),
    sort(ZA, SA), sort(ZB, SB), SA = SB.

extensional(M) :-
    forall((member(A, M), member(B, M)),
           (same_inside(M, A, B) -> A = B ; A \= B)).

% 后继：Y = X+1 且 Y < Z。
succ_wit(X, Z, Y) :-
    ord(Y), X < Y, Y < Z, Y =:= X + 1.

reflects(M) :-
    forall((member(X, M), member(Z, M), succ_wit(X, Z, Y)), member(Y, M)).

hull(M, M) :- reflects(M), !.
hull(M, H) :-
    member(X, M), member(Z, M), succ_wit(X, Z, Y), \+ member(Y, M), !,
    hull([Y|M], H).

% 单元集链：s(0)=∅ 的编码用数字秩。singleton 把秩 n 送到秩 n+1。
close_singleton(3, 3) :- !.
close_singleton(N, R) :-
    N < 3, N1 is N + 1, close_singleton(N1, R).

main :-
    format("==== 85~n"),
    M = [0,1,2,3,4,5],
    transitive(M), extensional(M),
    Thin = [0,2,4,5],
    \+ transitive(Thin),
    \+ reflects(Thin),
    hull([0,5], H),
    sort(H, [0,1,2,3,4,5]),
    reflects([0,1,2,3,4,5]),
    close_singleton(0, 3),
    format("0..5 传递且外延；{0,2,4,5} 既不传递也不含后继见证 ✓~n"),
    format("SH({0,5}) = 0..5；单元集链从秩 0 收到秩 3 ✓~n"),
    writeln("END ====").
