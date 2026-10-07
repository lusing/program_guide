:- encoding(utf8).
% ex41_buechi.pl —— 自动机与 LTL 模型检查（Ben-Ari 3e §16.4-16.8）
%
% 与 Coq/Lean 版同构的可运行现场：同一 K/K2、同一监视积、同一
% 「可达 × 接受 × 成环」三步空性检查。性质 AG F p（p 无限经常真），
% 否定监视 = 「某一刻起 p 永不再真」：活状态遇 p 落死点 9。
%
% 运行期输出纯 ASCII；谓词只用 SWI/GNU 公共面（call/3 元调用）。

% ---------- 模型 ----------

labelK(0).                        % p 只在状态 0

succK(0, 1).  succK(1, 2).  succK(2, 0).     % K：三循环，p 轮流出现
succK2(0, 1). succK2(1, 2). succK2(2, 1).    % K2：离开 0 后回不去

% ---------- 监视积（遇 p 落死点；死点自环不入接受表） ----------

msucc1(S, 9) :- labelK(S), !.
msucc1(9, 9) :- !.
msucc1(S, T) :- succK(S, T).

msucc2(S, 9) :- labelK(S), !.
msucc2(9, 9) :- !.
msucc2(S, T) :- succK2(S, T).

accepting(S) :- S \== 9.

% ---------- 轨道 / 可达 / 成环 ----------

runFrom(_, S, 0, S).
runFrom(P, S, T, R) :- T > 0, T1 is T - 1, call(P, S, S2), runFrom(P, S2, T1, R).

reachFrom(_, S, _, S).
reachFrom(P, S, Visited, R) :-
    call(P, S, S2), \+ member(S2, Visited),
    reachFrom(P, S2, [S2 | Visited], R).

% ◇ 的相位猜测：每个起点都试
reachAll(P, Rs) :-
    findall(R, (member(S, [0, 1, 2]), reachFrom(P, S, [S], R)), L),
    sort(L, Rs).

loopsAt(P, S) :- between(1, 8, T), runFrom(P, S, T, S).

findLoop(P) :- reachAll(P, Rs), member(S, Rs), accepting(S), loopsAt(P, S).

% ---------- main ----------

main :-
    format('==== ex38 buechi model checking START ====~n', []),
    (  findLoop(msucc1) ->
         format('K  (3-cycle, p at 0): loop FOUND (unexpected)~n')
    ;   format('K  (3-cycle, p at 0): no accepting loop -> AG F p HOLDS~n') ),
    (  findLoop(msucc2) ->
         format('K2 (0-1-2-1): counterexample FOUND (AG F p fails)~n')
    ;   format('K2 (0-1-2-1): no loop (unexpected)~n') ),
    findall(X, (between(0, 6, T), runFrom(msucc2, 1, T, X)), Orbit),
    format('K2 counterexample orbit from 1: ~w~n', [Orbit]),
    format('==== ex38 buechi model checking END ====~n', []).
