:- encoding(utf8).
% 第 07 章 · 集合、函数与等价关系 —— Prolog 通道
%
% 关系三公理直译 + 模 3 同余等价类 + 划分枚举（贝尔数 B(4) = 15）。

% ---------- 三公理（forall 在验证侧语义正确） ----------
reflexive(R, Xs) :- forall(member(X, Xs), member(X-X, R)).
symmetric(R) :- forall(member(X-Y, R), member(Y-X, R)).
transitive(R) :- forall((member(X-Y, R), member(Y-Z, R)), member(X-Z, R)).
equivalence(R, Xs) :- reflexive(R, Xs), symmetric(R), transitive(R).

% ---------- 模 3 同余（0..4 上） ----------
mod3_rel(R) :-
    findall(A-B, (between(0, 4, A), between(0, 4, B), A mod 3 =:= B mod 3), R).

class_of(A, C) :-
    mod3_rel(R),
    findall(B, member(A-B, R), C0),
    sort(C0, C).

% ---------- 划分生成器：首个元素"并入既有块 / 单独成块"递归 ----------
partition([], []).
partition([X | Xs], P) :-
    partition(Xs, P0),
    (   member(B, P0),                       % X 并入既有某块
        select(B, P0, Rest),
        P = [[X | B] | Rest]
    ;   P = [[X] | P0]                       % X 单独成块
    ).

% 规范化（块内排序、块间按最小元素排序）以去重
norm_partition(P, NP) :-
    maplist(sort, P, PS),
    sort(PS, NP).

% ---------- 划分诱导等价关系 ----------
partition_rel(P, R) :-
    findall(A-B, (member(Blk, P), member(A, Blk), member(B, Blk)), R0),
    sort(R0, R).

main :-
    format("==== 07 集合、函数与等价关系~n"),

    % 模 3 同余是等价关系；等价类三块
    mod3_rel(R),
    equivalence(R, [0, 1, 2, 3, 4]),
    class_of(0, C0), class_of(1, C1), class_of(2, C2),
    C0 == [0, 3], C1 == [1, 4], C2 == [2],
    format("模 3 同余（0..4）：三公理全过，等价类 {[0,3],[1,4],[2]} ✓~n"),

    % 反例：≤ 不对称
    le_rel(LE), \+ symmetric(LE),
    format("反例：关系 ≤ 对称性破产 ✓~n"),

    % 4 元集划分 = 贝尔数 B(4) = 15；每个诱导等价关系三公理全过
    findall(NP, (partition([1,2,3,4], P), norm_partition(P, NP)), NPs0),
    sort(NPs0, NPs),
    length(NPs, N),
    N == 15,
    forall(member(P, NPs),
           ( partition_rel(P, R1),
             equivalence(R1, [1, 2, 3, 4]) )),
    format("4 元集划分恰 ~d 个（贝尔数 B(4)），每个诱导等价关系三公理全过 ✓~n", [N]),

    format("END ====~n").

le_rel([1-1, 2-2, 3-3, 1-2, 1-3, 2-3]).
