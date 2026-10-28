:- encoding(utf8).
% 第 81 章：四位全集上的对称差代数。掩码 0..15 穷举全部子集。

symdiff(A, B, S) :- S is (A xor B).
complement4(A, C) :- C is (15 xor A).

symdiff_by_union(A, B, S) :-
    L is A /\ (15 xor B),
    R is B /\ (15 xor A),
    S is L \/ R.

mask(M) :- between(0, 15, M).

main :-
    format("==== 81~n"),
    forall((mask(A), mask(B)),
           (symdiff(A, B, S), symdiff_by_union(A, B, S))),
    forall((mask(A), mask(B)),
           (complement4(A, CA), complement4(B, CB),
            symdiff(CA, CB, S0), symdiff(A, B, S0))),
    forall(mask(A), (symdiff(A, A, 0), symdiff(A, 0, A))),
    symdiff(6, 10, 12),
    writeln("Prolog：256 对掩码均通过 Δ=(差集并)与补集不变式"),
    writeln("样本 {1,2} Δ {1,3} = {2,3}（掩码 6 Δ 10 = 12）✓"),
    writeln("END ====").
