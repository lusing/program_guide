:- encoding(utf8).
% ex68_turing.pl —— 图灵机的搜索面（Mendelson §5.1-5.2）
%
% 与 Coq/Lean 通道（解释器+对账+不变式归纳）互补，这里做 Prolog 的状态步进：
%   tstep(Program, Cfg, Cfg2)  单步（首匹配四元组；无匹配=停机）
%   trun(Program, Cfg, Fuel, Res)  燃料运行（some=停机配置/none=燃料尽）
% 现场同书例：Terase 抹除/Tsucc 后继/Tzero 零函数/Tadd 加法（连擦两笔版）。

% ---------- 四元组与配置 ----------
% 四元组：q(状态, 读符, 动作, 新状态)——动作 w(写符)/l/r
% 配置：cfg(状态, 左表, 当前符, 右表)；空白=0，笔=1

tstep(P, cfg(S, L, C, R), Cfg2) :-
    member(q(S, C, Act, S2), P), !,
    apply1(Act, S2, L, C, R, Cfg2).

apply1(w(B), S2, L, _, R, cfg(S2, L, B, R)).
apply1(l, S2, L, C, R, cfg(S2, L2, C2, [C | R])) :-
    (   L = [H | T] -> L2 = T, C2 = H
    ;   L == [] -> L2 = [], C2 = 0
    ).
apply1(r, S2, L, C, R, cfg(S2, [C | L], C2, R2)) :-
    (   R = [H | T] -> C2 = H, R2 = T
    ;   R == [] -> C2 = 0, R2 = []
    ).

% ---------- 燃料运行 ----------

trun(_, _, 0, none).
trun(P, C, F, Res) :-
    F > 0, F1 is F - 1,
    (   tstep(P, C, C2) -> trun(P, C2, F1, Res)
    ;   Res = some(C)
    ).

% ---------- 编码与计数 ----------

rep1(0, []).
rep1(N, [1 | T]) :- N > 0, N1 is N - 1, rep1(N1, T).

start1(N, cfg(0, [], 1, R)) :- rep1(N, R).
start2(M, N, cfg(0, [], 1, R)) :-
    rep1(M, R1), N1 is N + 1, rep1(N1, R2),
    append(R1, [0 | R2], R).

cnt1([], 0).
cnt1([1 | T], N) :- cnt1(T, N0), N is N0 + 1.
cnt1([0 | T], N) :- cnt1(T, N).

outbars(cfg(_, L, C, R), N) :-
    cnt1(L, A), cnt1(R, B),
    (   C =:= 1 -> D = 1 ; D = 0 ),
    N is A + B + D.

% ---------- 现场机器 ----------

terase([q(0, 0, r, 0), q(0, 1, w(0), 1)]).
tsucc([q(0, 1, l, 1), q(1, 0, w(1), 2)]).
tzero([q(0, 1, w(0), 1), q(1, 0, r, 0), q(0, 0, w(1), 2)]).
tadd([q(0, 1, r, 0), q(0, 0, w(1), 1), q(1, 1, r, 1), q(1, 0, l, 2),
      q(2, 1, w(0), 3), q(3, 0, l, 4), q(4, 1, w(0), 5)]).

% ---------- main ----------

main :-
    format('==== ex34 turing search START ====~n'),
    tsucc(Ts),
    forall(between(0, 9, N),
           (   start1(N, C),
               (   trun(Ts, C, 10, some(C2)) -> outbars(C2, B)
               ;   B = 999 ),
               E is N + 2, format('Tsucc(~w)  : bars = ~w (expect ~w)~n', [N, B, E])
           )),
    tzero(Tz),
    forall(between(0, 9, N),
           (   start1(N, C),
               (   trun(Tz, C, 30, some(C2)) -> outbars(C2, B)
               ;   B = 999 ),
               format('Tzero(~w)  : bars = ~w (expect 1)~n', [N, B])
           )),
    tadd(Ta),
    forall(between(0, 4, M),
           forall(between(0, 4, N),
                  (   start2(M, N, C),
                      (   trun(Ta, C, 40, some(C2)) -> outbars(C2, B)
                      ;   B = 999 ),
                      E is M + N + 1,
                      format('Tadd(~w,~w) : bars = ~w (expect ~w)~n',
                             [M, N, B, E])
                  ))),
    terase(Te),
    forall(between(0, 9, N),
           (   start1(N, C),
               (   trun(Te, C, 10, some(C2)) -> outbars(C2, B)
               ;   B = 999 ),
               format('Terase(~w) : bars = ~w (expect ~w)~n', [N, B, N])
           )),
    (   trun(Te, cfg(0, [], 0, []), 50, some(_))
    ->  format('Terase(blank): HALTED (unexpected!)~n')
    ;   format('Terase(blank): no halt in fuel (keeps moving right)~n')
    ),
    format('==== ex34 turing search END ====~n').
