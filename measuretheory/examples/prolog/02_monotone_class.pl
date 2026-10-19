:- encoding(utf8).
% 02_monotone_class.pl —— 第 02 章：σ / 单调 / λ 三种闭包（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,2,3,4}。实验：π-系上 λ = σ；非 π-系上 λ ⊊ σ；
% 单调闭包在有限宇宙退化（教学点）。

univ([1,2,3,4]).

subseteq([], _).
subseteq([H|T], S) :- member(H, S), subseteq(T, S).

seteq(A, B) :- subseteq(A, B), subseteq(B, A).

intersect([], _, []).
intersect([H|T], S, [H|R]) :- member(H, S), !, intersect(T, S, R).
intersect([_|T], S, R) :- intersect(T, S, R).

union_([], S, S).
union_([H|T], S, R) :- member(H, S), !, union_(T, S, R).
union_([H|T], S, [H|R]) :- union_(T, S, R).

compl(S, C) :- univ(U), diff(U, S, C).

diff([], _, []).
diff([H|T], S, R) :- member(H, S), !, diff(T, S, R).
diff([H|T], S, [H|R]) :- diff(T, S, R).

disjoint(A, B) :- \+ (member(X, A), member(X, B)).

% 通用迭代闭包：Step(C, D) 生成由 C 出发一步新增的集合
closure_(Step, C, S) :-
    findall(D, call(Step, C, D), New),
    (   any_new(New, C)
    ->  append_new(New, C, C2), closure_(Step, C2, S)
    ;   S = C ).

% any_new/2：列表中有 C 外的新集合则为真——空列表必须失败
% （否则不动点处恒真，闭包永不停止——实测坑）
any_new([W|_], C) :- \+ (member(U, C), seteq(U, W)), !.
any_new([_|T], C) :- any_new(T, C).

append_new([], C, C).
append_new([W|T], C, R) :-
    (   \+ (member(U, C), seteq(U, W))
    ->  append_new(T, [W|C], R)
    ;   append_new(T, C, R) ).

% σ-步：补或并
sigma_step(C, D) :- member(S, C), compl(S, D).
sigma_step(C, D) :- member(S, C), member(T, C), union_(S, T, D).

% 单调步：可比对的并/交
mono_step(C, D) :- member(S, C), member(T, C),
    ( subseteq(S, T) ; subseteq(T, S) ),
    ( union_(S, T, D) ; intersect(S, T, D) ).

% λ-步：真差或不交并（全集先放入）
lambda_step(C, D) :- member(U, C), member(V, C), subseteq(V, U), diff(U, V, D).
lambda_step(C, D) :- member(U, C), member(V, C), disjoint(U, V), union_(U, V, D).

count_closure(Step, Gen, N) :- closure_(Step, Gen, S), length(S, N).

main :-
    format("==== 02 monotone_class~n", []),
    % 实验一：π-系 {∅,单点×4}
    Gen1 = [[],[1],[2],[3],[4]],
    count_closure(sigma_step, Gen1, NS1),
    Gen1U = [[1,2,3,4]|Gen1],
    count_closure(lambda_step, Gen1U, NL1),
    count_closure(mono_step, Gen1, NM1),
    format("pi-system: sigma=~w lambda=~w mono=~w~n", [NS1, NL1, NM1]),
    (   NS1 =:= 16, NL1 =:= 16 -> format("lambda = sigma on pi-system: OK~n")
    ;   format("lambda = sigma on pi-system: FAIL~n"), fail ),
    (   NM1 =:= 5 -> format("mono closure degenerate (5 members): OK~n")
    ;   format("mono closure degenerate: FAIL~n"), fail ),
    % 实验二：非 π-系 {{1,2},{2,3}}
    Gen2 = [[1,2],[2,3]],
    count_closure(sigma_step, Gen2, NS2),
    Gen2U = [[1,2,3,4]|Gen2],
    count_closure(lambda_step, Gen2U, NL2),
    format("non-pi: sigma=~w lambda=~w~n", [NS2, NL2]),
    (   NL2 < NS2 -> format("lambda < sigma without pi: OK~n")
    ;   format("lambda < sigma without pi: FAIL~n"), fail ),
    % 实验三：代数 {∅,{1,2},{3,4},Ω}
    Gen3 = [[],[1,2],[3,4],[1,2,3,4]],
    count_closure(sigma_step, Gen3, NS3),
    count_closure(mono_step, Gen3, NM3),
    format("algebra: sigma=~w mono=~w~n", [NS3, NM3]),
    (   NS3 =:= 4, NM3 =:= 4 -> format("finite algebra is sigma-algebra: OK~n")
    ;   format("finite algebra: FAIL~n"), fail ),
    format("END ====~n"), !.
