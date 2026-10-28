:- encoding(utf8).
% 第 94 章：主超滤上函数一致关系的有限商。

binary_function(F) :-
    F = [A,B,C],
    member(A, [0,1]), member(B, [0,1]), member(C, [0,1]).

agree_at(F, G, I) :- nth0(I, F, X), nth0(I, G, X).

quotient_class(I, V, Class) :-
    setof(F, (binary_function(F), nth0(I, F, V)), Class).

all_same_at(Class, I, V) :-
    forall(member(F, Class), nth0(I, F, V)).

main :-
    format("==== 94~n"),
    findall(F, binary_function(F), Fs),
    length(Fs, 8),
    quotient_class(1, 0, C0), quotient_class(1, 1, C1),
    length(C0, 4), length(C1, 4),
    all_same_at(C0, 1, 0), all_same_at(C1, 1, 1),
    append(C0, C1, All), sort(All, Sorted), Sorted == Fs,
    forall((member(F, Fs), member(G, Fs), agree_at(F, G, 1)),
           (nth0(1, F, V), nth0(1, G, V))),
    writeln("Prolog：坐标 1 的主超滤商有两类，各 4 个函数，并集穷尽 8 个函数 ✓"),
    writeln("一致关系按焦点值划分；有限主超幂退化为求值，不模拟可测基数"),
    writeln("END ====").
