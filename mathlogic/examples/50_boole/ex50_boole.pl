:- encoding(utf8).
% ex50_boole.pl —— Quine-McCluskey 方法（Jongsma §7.6.5）的机器件
%
% 模式编码：implicant 是 0/1/- 的表（- 为被合并消去的变量位），
%   如 [1,1,-] = x·y。与 Coq/Lean 通道（公理/加法器/minterm 定理）
%   互补，这里跑 §7.6.5 的两阶段算法本体：
%   combine/3 —— 两模式恰一位 0/1 互补、其余全同（杠位对齐）时
%     合并出该位为 - 的新模式（书 Table 7.2 的相邻单元合并）；
%   qmc_primes/2 —— 反复合并到不动点；未被任何合并吸收的模式
%     即素蕴涵项（prime implicant，阶段一）；
%   min_covers/3 —— 枚举素蕴涵项的全部覆盖、取极小（prime
%     implicant chart + essential 判定，阶段二）。
% 现场：三元多数函数（书例 7.6.8 → xy+xz+yz）与例 7.6.9
%   （minterms 1,3,4,5,6,7 → x+z）。

% ---------- 阶段一：合并与素蕴涵项 ----------

opp(0, 1).
opp(1, 0).

% 头部互补则尾部必须全同；否则头部相同、递归找内部互补位
combine([A|T], [B|T2], [-|T]) :- opp(A, B), T = T2.
combine([A|T], [A|T2], [A|T3]) :- combine(T, T2, T3).

% implicant 覆盖 minterm：非杠位逐位相等
covers_pat([], []).
covers_pat([-|T], [_|M]) :- covers_pat(T, M).
covers_pat([B|T], [B|M]) :- covers_pat(T, M).

% 3 变量 minterm 编号到模式（书 Table 7.2 的二进制标号）
bits(0, [0,0,0]). bits(1, [0,0,1]). bits(2, [0,1,0]). bits(3, [0,1,1]).
bits(4, [1,0,0]). bits(5, [1,0,1]). bits(6, [1,1,0]). bits(7, [1,1,1]).

combine_step(Ps, News, Used) :-
    findall(R, (member(P, Ps), member(Q, Ps), P @< Q, combine(P, Q, R)), NewsRaw),
    sort(NewsRaw, News),
    % 参与者须双向采集：combine 对称，而 111 这类最大模式从不当左元
    findall(U, (member(U, Ps), member(V, Ps), U \== V, combine(U, V, _)), UsedRaw),
    sort(UsedRaw, Used).

% 未被吸收的旧模式 ∪ 新层的素蕴涵项
qmc_primes(Ps, Primes) :-
    combine_step(Ps, News, Used),
    ( News == []
    -> Primes = Ps
    ;  subtract(Ps, Used, Keep),
       qmc_primes(News, Sub),
       append(Keep, Sub, P0),
       sort(P0, Primes) ).

% ---------- 阶段二：极小覆盖 ----------

subset_of([], []).
subset_of([H|T], [H|S]) :- subset_of(T, S).
subset_of([_|T], S) :- subset_of(T, S).

covers_all(S, Mints) :-
    forall(member(M, Mints), (member(P, S), covers_pat(P, M))).

min_covers(Primes, Mints, Covers) :-
    findall(S, (subset_of(Primes, S), S \== [], covers_all(S, Mints)), Solns),
    maplist(length, Solns, Ls),
    min_list(Ls, Min),
    include(len_is(Min), Solns, Cs),
    sort(Cs, Covers).
len_is(N, L) :- length(L, N).

% ---------- 模式到积项的打印 ----------

var_names([x, y, z]).
lit_au(-, _, '').
lit_au(1, V, V).
lit_au(0, V, A) :- atom_concat(V, '\'', A).   % 0 位 -> 反文字 x'

pat_name(P, Name) :-
    var_names(Vs),
    maplist(lit_au, P, Vs, As),
    exclude(=(''), As, As2),
    ( As2 == []
    -> Name = '1'
    ;  atomic_list_concat(As2, '', Name) ).

map_pat_name([], []).
map_pat_name([P|Ps], [N|Ns]) :- pat_name(P, N), map_pat_name(Ps, Ns).

% ---------- main ----------

run_qmc(Idx, ExpectCovers) :-
    maplist(bits, Idx, Ms),
    qmc_primes(Ms, Primes),
    min_covers(Primes, Ms, Covers),
    maplist(pat_name, Primes, PNames0), sort(PNames0, PNames),
    maplist(map_pat_name, Covers, CNames0),
    maplist(msort, CNames0, CNames1), sort(CNames1, CNames),
    maplist(msort, ExpectCovers, EC1), sort(EC1, ECSorted),
    format('minterms ~w~n  primes         : ~w~n  minimal covers : ~w~n',
           [Idx, PNames, CNames]),
    ( CNames = ECSorted
    -> format('  matches book result~n')
    ;  format('  MISMATCH (expected ~w)~n', [ECSorted]) ).

main :-
    format('==== ex50 boole QMC START ====~n'),
    % 三元多数函数（书例 7.6.8）：素蕴涵项 xy/xz/yz 全 essential
    run_qmc([3,5,6,7], [[xy, xz, yz]]),
    % 书例 7.6.9：两轮合并出 [1,-,-]=x 与 [-,-,1]=z，双 essential
    run_qmc([1,3,4,5,6,7], [[x, z]]),
    format('==== ex50 boole QMC END ====~n').
