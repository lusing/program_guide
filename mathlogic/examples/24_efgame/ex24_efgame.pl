:- encoding(utf8).
% ex24_efgame.pl —— EF 博弈的搜索面（EFT ch XII）
%
% 与 Coq/Lean 通道（dup_wins 求解器+分离现场）互补，这里做回溯搜索
% 本体：spoiler 两侧选点、duplicator 应对、部分同构逐轮检查。
% 结构以 (关系谓词, 论域大小) 传入；efg(M, RelA, NA, RelB, NB, Pairs)
% 成功当且仅当 M 轮 duplicator 有赢策略。

% ---------- 结构关系 ----------

zord_rel(N, U, V) :- U >= 0, U < V, V < N.
zempty_rel(_, _, _) :- false.
zfull_rel(N, U, V) :- U >= 0, U < N, V >= 0, V < N.

% ---------- 部分同构：两投影单射 + 关系双向一致 ----------

dup_ok(Pairs, RelA, RelB) :-
    \+ (member(U1-V1, Pairs), member(U2-V2, Pairs),
        U1 == U2, V1 \== V2),
    \+ (member(U1-V1, Pairs), member(U2-V2, Pairs),
        V1 == V2, U1 \== U2),
    \+ (member(U1-V1, Pairs), member(U2-V2, Pairs),
        call(RelA, U1, U2), \+ call(RelB, V1, V2)),
    \+ (member(U1-V1, Pairs), member(U2-V2, Pairs),
        \+ call(RelA, U1, U2), call(RelB, V1, V2)).

% ---------- n 轮博弈：spoiler 每轮任选一侧，dup 应对 ----------

efg(0, RelA, _, RelB, _, Pairs) :- !, dup_ok(Pairs, RelA, RelB).
efg(M, RelA, NA, RelB, NB, Pairs) :-
    M > 0, M1 is M - 1,
    NA1 is NA - 1, NB1 is NB - 1,
    forall(between(0, NA1, A0),
           (between(0, NB1, B0),
            efg(M1, RelA, NA, RelB, NB, [A0-B0|Pairs]))),
    forall(between(0, NB1, B0),
           (between(0, NA1, A0),
            efg(M1, RelA, NA, RelB, NB, [A0-B0|Pairs]))).

% ---------- main ----------

main :-
    format('==== ex24 efgame search START ====~n'),
    ( efg(3, zord_rel(1), 1, zord_rel(2), 2, [])
    -> format('Z1 vs Z2   3 rounds : dup wins~n')
    ;  format('Z1 vs Z2   3 rounds : spoiler wins (1 < 2^3-1)~n') ),
    ( efg(2, zord_rel(2), 2, zord_rel(3), 3, [])
    -> format('Z2 vs Z3   2 rounds : dup wins~n')
    ;  format('Z2 vs Z3   2 rounds : spoiler wins (adjacency leaks)~n') ),
    ( efg(1, zord_rel(2), 2, zord_rel(3), 3, [])
    -> format('Z2 vs Z3   1 round  : dup wins~n')
    ;  format('Z2 vs Z3   1 round  : spoiler wins~n') ),
    ( efg(3, zord_rel(3), 3, zord_rel(4), 4, [])
    -> format('Z3 vs Z4   3 rounds : dup wins~n')
    ;  format('Z3 vs Z4   3 rounds : spoiler wins~n') ),
    ( efg(2, zord_rel(3), 3, zord_rel(4), 4, [])
    -> format('Z3 vs Z4   2 rounds : dup wins (both >= 2^2-1)~n')
    ;  format('Z3 vs Z4   2 rounds : spoiler wins~n') ),
    ( efg(3, zord_rel(7), 7, zord_rel(8), 8, [])
    -> format('Z7 vs Z8   3 rounds : dup wins (both >= 2^3-1)~n')
    ;  format('Z7 vs Z8   3 rounds : spoiler wins~n') ),
    ( efg(2, zempty_rel(2), 2, zempty_rel(3), 3, [])
    -> format('empty 2/3  2 rounds : dup wins~n')
    ;  format('empty 2/3  2 rounds : spoiler wins~n') ),
    ( efg(3, zempty_rel(2), 2, zempty_rel(3), 3, [])
    -> format('empty 2/3  3 rounds : dup wins~n')
    ;  format('empty 2/3  3 rounds : spoiler wins (size needs 3 picks)~n') ),
    ( efg(3, zfull_rel(2), 2, zfull_rel(3), 3, [])
    -> format('full 2/3   3 rounds : dup wins~n')
    ;  format('full 2/3   3 rounds : spoiler wins~n') ),
    format('==== ex24 efgame search END ====~n').
