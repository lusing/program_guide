:- encoding(utf8).
% 08_functional_monotone_class.pl —— 第 08 章：函数 λ-闭包的符号版（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,2,3,4}，函数表示为 4 元组（整数值格 0..2）。
% λ-运算：非负数乘（标量 {0,1,2}）、优减劣（逐点 f≥g）、有界加法（≤2）。
% 对照 A（π-类 {∅,{1,2},Ω}）：闭包 == 按块常数格点函数（9 个）。
% 对照 B（非 π 类 {{1,2},{2,3}}）：闭包 9 个 ≪ σ(C')-可测格点全体（81 个），
%         且 I2 = I12·I23 不在闭包（乘积飞出 λ-运算）。

:- use_module(library(apply)).

valid(F) :- maplist([X]>>(integer(X), 0 =< X, X =< 2), F).
valid_add(F, G, T) :- maplist([X,Y,Z]>>(Z is X + Y, Z =< 2), F, G, T).
ge_all(F, G) :- maplist([X,Y]>>(X >= Y), F, G).
diff_ok(F, G, T) :- ge_all(F, G), maplist([X,Y,Z]>>(Z is X - Y), F, G, T).

scalars([0,1,2]).

% 一步闭包算子（各分支自带"新元素"守卫）
step(S, T) :- member(F, S), member(C, scalars),
              maplist([X,Y]>>(Y is C * X), F, Y), valid(Y), \+ member(Y, S), T = Y.
step(S, T) :- member(F, S), member(G, S), diff_ok(F, G, T), valid(T),
              \+ member(T, S).
step(S, T) :- member(F, S), member(G, S), valid_add(F, G, T), valid(T),
              \+ member(T, S).

% 迭代至不动点（先收再扩；0..2 格点上必然终止）
closure_(S, Final) :- findall(T, step(S, T), New),
    ( New == [] -> Final = S
    ; append(S, New, S1), dedup_list(S1, S2), closure_(S2, Final) ).

dedup_list(Xs, Ys) :- dedup_list_(Xs, [], Ys).
dedup_list_([], Acc, Acc).
dedup_list_([X|Xs], Acc, Ys) :-
    (   member(X, Acc) -> dedup_list_(Xs, Acc, Ys)
    ;   dedup_list_(Xs, [X|Acc], Ys) ).

% 计数语义下 tuples 相等即函数相等（列表直接比对）。

lb_pi(L) :- findall([A,A,B,B], (between(0,2,A), between(0,2,B)), L0),
    msort(L0, L).

lb_nonpi(L) :- findall([A,B,C,D], (between(0,2,A), between(0,2,B),
                                   between(0,2,C), between(0,2,D)), L0),
    msort(L0, L).

main :-
    format("==== 08 functional_monotone_class~n", []),
    % 对照 A：π-类
    closure_([[1,1,1,1],[1,1,0,0]], CA0),
    msort(CA0, CA),
    lb_pi(LA),
    length(CA, NA), length(LA, NL),
    format("pi-case: |closure| = ~w, |L_b grid| = ~w (expect 9, 9)~n", [NA, NL]),
    NA =:= 9, CA == LA,
    member([0,0,1,1], CA),
    format("pi-case: closure == L_b, I_{3,4} = 1 - I_{1,2} in closure: OK~n"),
    % 对照 B：非 π 类
    closure_([[1,1,1,1],[0,1,1,0]], CB0),
    msort(CB0, CB),
    lb_nonpi(LB),
    length(CB, NB), length(LB, NLB),
    format("non-pi: |closure| = ~w, |L_b grid| = ~w (expect 9, 81)~n", [NB, NLB]),
    NB =:= 9, NLB =:= 81,
    \+ member([0,1,0,0], CB),
    format("non-pi: closure strictly smaller, I_{2} = I12*I23 missing: OK~n"),
    format("END ====~n"), !.
