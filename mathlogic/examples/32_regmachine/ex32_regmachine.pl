:- encoding(utf8).
% ex32_regmachine.pl —— 寄存器机的搜索面（EFT ch X）
%
% 与 Coq/Lean 通道（解释器+对账）互补，这里做 Prolog 的状态步进：
%   step(Program, Cfg, Cfg')   单步
%   runs(Program, Start, Cfg)  燃料内到达的配置（停机即 Some 语义）
%   halts(Program, Input)      有界停机判定
% 现场同书例 P_0 奇偶、加法、循环不停机。

% ---------- 指令与配置 ----------

% 指令：add(R,A) del(R,A) ife(R,L1,L2) print halt
% 配置：cfg(PC, Regs, Out)——Regs 为 nat 表

nthd(Regs, I, V) :- (   nth0(I, Regs, V0) -> V = V0 ; V = 0 ).

setn(Regs, I, V, Regs2) :-
    length(L1, I), append(L1, [_|L2], Regs), append(L1, [V|L2], Regs2).

% ---------- 单步 ----------

step(P, cfg(PC, Regs, Out), Cfg2) :-
    nth0(PC, P, Inst), !,
    step1(Inst, P, cfg(PC, Regs, Out), Cfg2).

step1(add(R, A), _, cfg(PC, Regs, Out), cfg(PC2, Regs2, Out)) :-
    PC2 is PC + 1, nthd(Regs, R, V), V2 is V + A, setn(Regs, R, V2, Regs2).
step1(del(R, A), _, cfg(PC, Regs, Out), cfg(PC2, Regs2, Out)) :-
    PC2 is PC + 1, nthd(Regs, R, V), V2 is max(0, V - A),
    setn(Regs, R, V2, Regs2).
step1(ife(R, L1, L2), _, cfg(_, Regs, Out), cfg(L, Regs, Out)) :-
    nthd(Regs, R, V), ( V =:= 0 -> L = L1 ; L = L2 ).
step1(print, _, cfg(PC, Regs, Out), cfg(PC2, Regs, Out2)) :-
    PC2 is PC + 1, nthd(Regs, 0, V), append(Out, [V], Out2).
step1(halt, _, C, C).

% ---------- 燃料运行 ----------

runs(_, _, 0, none).
runs(P, C, Fuel, Res) :-
    Fuel > 0, Fuel1 is Fuel - 1,
    step(P, C, C2),
    ( C2 = C -> Res = some(C) ; runs(P, C2, Fuel1, Res) ).

halts(P, Input, Fuel) :- runs(P, cfg(0, [Input,0,0], []), Fuel, some(_)).

% ---------- 现场程序 ----------

p0([ife(0,6,1), del(0,1), ife(0,5,3), del(0,1), ife(0,6,1), add(0,1), halt]).
padd([ife(1,4,1), del(1,1), add(0,1), ife(1,0,0), halt]).
ploop([add(0,1), ife(0,1,0)]).

% ---------- main ----------

main :-
    format('==== ex32 regmachine search START ====~n'),
    p0(P0),
    forall(between(0, 7, N),
           ( F is 3 * N + 20,
             ( runs(P0, cfg(0, [N,0,0], []), F, some(cfg(_, Regs, _)))
             -> nthd(Regs, 0, R), format('P0(~w)      : R0 = ~w~n', [N, R])
             ;  format('P0(~w)      : no halt in fuel~n', [N]) ) )),
    padd(Padd),
    forall(member([X, Y], [[3,4],[5,5],[0,1]]),
           ( F is 3 * (X + Y) + 20,
             ( runs(Padd, cfg(0, [X,Y], []), F, some(cfg(_, Regs, _)))
             -> nthd(Regs, 0, R), format('Padd(~w,~w) : R0 = ~w~n', [X, Y, R])
             ;  format('Padd(~w,~w) : no halt in fuel~n', [X, Y]) ) )),
    ploop(Ploop),
    forall(between(0, 3, N),
           ( F is 50,
             ( runs(Ploop, cfg(0, [N,0,0], []), F, some(_))
             -> format('Ploop(~w)   : HALTED (unexpected!)~n', [N])
             ;  format('Ploop(~w)   : loops (no halt in fuel)~n', [N]) ) )),
    format('==== ex32 regmachine search END ====~n').
