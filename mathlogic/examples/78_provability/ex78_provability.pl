:- encoding(utf8).
% ex78_provability.pl -- 可证性条件 D1-D3、对角化与 Loeb 定理（郝 ch9.3+ch10）
% 演算作为数据：把 D 条件演算限制在一个手工公式宇宙（程序表宇宙配方，
% 70 章同款）上做饱和推理。公式项：a(N)/bot/i(X,Y)/box(X)。
%   规则面：mp（分离）+ d1（D1）；公理面：宇宙内全部命题重言式（Htaut
%   的机器化身——对 box 子式作原子处理后穷举赋值检测）、D2/D3 实例、
%   对角化不动点 S1/S2、（可切换的）Loeb 假设 S3。
%   main 跑两轮：带 S3 时 der(a0) 封口并打印推导树；去掉 S3 后 der(a0)
%   与 bot 都不在饱和闭包中——有限宇宙内的归纳证据：结论确实依赖假设。

% ---------- 公式工具 ----------

sub(X, X).
sub(i(A, _), S) :- sub(A, S).
sub(i(_, B), S) :- sub(B, S).
sub(box(A), S)  :- sub(A, S).

% 模态原子：atom 或 box(_)（□ 非真值函数，赋值时作原子处理）
matomic(a(_)).
matomic(box(_)).

% 真值求值：Env 把每个模态原子映到 0/1（用 assoc 表实现，member 查找）
ev(a(N), Env, V)   :- !, memberchk(a(N)-V, Env).
ev(box(X), Env, V) :- !, memberchk(box(X)-V, Env).
ev(bot, _, 0) :- !.
ev(i(A, B), Env, V) :- !,
    ev(A, Env, VA), ev(B, Env, VB),
    ( VA = 0 -> V = 1 ; ( VB = 1 -> V = 1 ; V = 0 ) ).

% 收集公式的全部模态原子
matoms(F, L) :- findall(M, (sub(F, M), matomic(M)), L0), sort(L0, L).

% 穷举赋值检测重言式
taut(F) :-
    matoms(F, L),
    length(L, N),
    Max is 2^N - 1,                       % 宇宙内模态原子数远小于 12
    findall(Env,
            ( between(0, Max, Bits),
              findall(M-V,
                      ( nth0(I, L, M),
                        V is (Bits >> (N - 1 - I)) mod 2 ),
                      Env) ),
            Envs),
    forall( ( member(Env, Envs), ev(F, Env, 0) ), fail ).

% ---------- 宇宙（Lob 推导所需的公式，程序表宇宙） ----------

universe(U) :-
    A0 = a(0), H = a(9),
    BH = box(H), BBH = box(box(H)), BA = box(A0),
    S1 = i(H, i(BH, A0)),            % Hfwd: h -> ([]h -> a)
    S2 = i(i(BH, A0), H),            % Hrev: ([]h -> a) -> h
    S3 = i(BA, A0),                  % hla : []a -> a
    U0 = [ A0, H, bot, BH, BBH, BA,
           S1, S2, S3,
           i(BH, A0),                          % S1'：前件形态
           i(BH, BA),                          % []h->[]a（目标中继）
           i(BH, box(i(BH, A0))),              % mp 结果 1
           i(BBH, BA),                         % [][]h->[]a
           i(BH, i(BBH, BA)),                  % 合并前件
           i(BH, BBH),                         % D3 实例（h）
           i(i(BH, i(BBH, BA)), i(i(BH, BBH), i(BH, BA))),  % S 组合子
           i(i(BH, BBH), i(BH, BA)),           % S 组合子 mp 结果
           i(box(S1), i(BH, box(i(BH, A0)))),  % D2 实例（h, S1'）
           i(box(i(BH, A0)), i(BBH, BA)),      % D2 实例（[]h, a）
           % 两座重言桥：饱和机只有 mp，imp_trans 的账由桥公式承担
           i(i(BH, box(i(BH, A0))),
             i(i(box(i(BH, A0)), i(BBH, BA)), i(BH, i(BBH, BA)))),
           i(i(BH, BA), i(i(BA, A0), i(BH, A0))),
           box(S1), box(i(BH, A0)), box(A0), box(H),
           box(bot), box(box(bot)),
           i(box(bot), box(A0)),               % D0 腿：[]bot->[]a 的物料
           i(box(bot), bot)                    % con（记账展示用）
         ],
    findall(F, (member(X, U0), sub(X, F)), Subs),
    append(U0, Subs, U1),
    findall(box(F), member(F, U1), Boxes),
    append([U1, Boxes], U2),
    sort(U2, U).

% ---------- 饱和推理机 ----------

:- dynamic d/2.   % d(F, Why)：Why ∈ seed(Tag)/taut/d2(A,B)/d3(A)/mp(F1,F2)/d1(F)

seed_all([], _).
seed_all([F | T], Tag) :-
    ( d(F, _) -> true ; assertz(d(F, seed(Tag))) ),
    seed_all(T, Tag).

seed_axioms(U) :-
    % Htaut 的机器面：宇宙中的重言式全部直送
    forall( ( member(F, U), \+ matomic(F), catch(taut(F), _, fail) ),
             ( d(F, _) -> true ; assertz(d(F, taut)) ) ),
    % D2/D3 实例：只撒公式本身在宇宙中的
    forall( ( member(A, U), member(B, U),
              F2 = i(box(i(A, B)), i(box(A), box(B))), member(F2, U) ),
             ( d(F2, _) -> true ; assertz(d(F2, d2(A, B))) ) ),
    forall( ( member(A, U), F3 = i(box(A), box(box(A))), member(F3, U) ),
             ( d(F3, _) -> true ; assertz(d(F3, d3(A))) ) ).

% 不动点饱和：mp + d1
% 注意不能写 (step(U),fail;true)——回溯不会重试已穷尽的左支
% （mp 支在早期无解后永不再进）；递归重开才安全。
saturate(U) :-
    ( step(U) -> saturate(U) ; true ), !.

step(U) :-
    ( member(i(A, B), U), d(i(A, B), _), d(A, _), \+ d(B, _),
      assertz(d(B, mp(i(A, B), A)))
    ; member(A, U), d(A, _), \+ d(box(A), _),
      assertz(d(box(A), d1(A)))
    ).

% ---------- 推导树打印（运行期纯 ASCII） ----------

fmt(a(N), S) :- !, swritef(S, 'a%d', [N]).
fmt(bot, 'bot') :- !.
fmt(box(A), S) :- !, fmt(A, S1), swritef(S, '[]%w', [S1]).
fmt(i(A, B), S) :- !, fmt(A, SA), fmt(B, SB), swritef(S, '(%w->%w)', [SA, SB]).

print_why(F, Ind) :-
    d(F, W),
    fmt(F, FS),
    ( W = seed(Tag) ->
        format('~w[hypothesis] ~w  (~w)~n', [Ind, FS, Tag])
    ; W = taut ->
        format('~w[tautology] ~w~n', [Ind, FS])
    ; W = d2(_, _) ->
        format('~w[D2 instance] ~w~n', [Ind, FS])
    ; W = d3(_) ->
        format('~w[D3 instance] ~w~n', [Ind, FS])
    ; W = mp(F1, F2) ->
        format('~w[mp] ~w  from~n', [Ind, FS]),
        atom_concat(Ind, '    ', Ind2),
        print_why(F1, Ind2), print_why(F2, Ind2)
    ; W = d1(F0) ->
        format('~w[D1] ~w  from~n', [Ind, FS]),
        atom_concat(Ind, '    ', Ind2),
        print_why(F0, Ind2)
    ).

% ---------- 主账 ----------

run(WithHla) :-
    retractall(d(_, _)),
    universe(U),
    length(U, NU),
    member(S1, U), S1 = i(a(9), i(box(a(9)), a(0))),
    member(S2, U), S2 = i(i(box(a(9)), a(0)), a(9)),
    member(S3, U), S3 = i(box(a(0)), a(0)),
    seed_all([S1, S2], diag),
    ( WithHla = yes -> seed_all([S3], hla) ; true ),
    seed_axioms(U),
    saturate(U),
    ( d(a(0), _) ->
        format('[with hla []a->a] Loeb rule closes: der(a0) holds (|U|=~d)~n', [NU]),
        print_why(a(0), '  ')
    ; format('[without hla] der(a0) NOT in saturated closure (|U|=~d)~n', [NU])
    ),
    ( d(bot, _) -> format('   !! bot derivable (unexpected)~n')
    ; format('   bot NOT derivable: abstract ledger consistent (con shadow)~n')
    ),
    nl.

main :-
    format('== ex78 derivability-condition calculus: finite-universe saturation ==~n'),
    run(yes),
    run(no),
    format('==== ex78 provability END ====~n').
