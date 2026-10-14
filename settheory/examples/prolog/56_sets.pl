:- encoding(utf8).
% 第 56 章：朴素集合的机器化（Makinson Ch1）
% 子集/幂集/布尔定律/两两不交——谓词化集合代数。

% 子集（表为集合，升序无重复）
sub([], _).
sub([X|Xs], Y) :- member(X, Y), sub(Xs, Y).

% 幂集：每一步"继承 or 追加表头"
pow([], [[]]).
pow([X|Xs], P) :-
    pow(Xs, P0),
    findall([X|S], member(S, P0), Add),
    append(P0, Add, P).

% 幂集计数 2^n
card_pow(N) :-
    ( N =:= 0 -> L = [] ; numlist(1, N, L) ),
    pow(L, P), length(P, K),
    K =:= 2^N,
    format("  幂集计数：|P({1..~d})| = ~d = 2^~d ✓~n", [N, K, N]).

% 两两不交（族 = 表的表）
pairwise_disjoint([]).
pairwise_disjoint([S|Ss]) :-
    maplist(disj(S), Ss),
    pairwise_disjoint(Ss).
disj(S, T) :- \+ (member(X, S), member(X, T)).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 56~n"),

    % 一、幂集生成与计数
    pow([1,2,3], P3), length(P3, N3),
    format("  P({1,2,3}) 共 ~d 个元素：~w~n", [N3, P3]),
    N3 = 8,
    forall(between(0, 7, N), card_pow(N)),

    % 二、空集是最小子集、每集是自身子集
    pow([a,b], Pab), member([], Pab), member([a,b], Pab),
    format("  ∅ ∈ P(A) 且 A ∈ P(A)（两个极端元素都在）✓~n"),

    % 三、布尔定律抽查（在 P({1,2,3}) 上两两验证交的交换律与分配律）
    pow([1,2,3], P),
    forall((member(A, P), member(B, P)),
           (intersection(A, B, AB), intersection(B, A, BA),
            msame(AB, BA))),
    forall((member(A, P), member(B, P), member(C, P)),
           (union(B, C, BC), intersection(A, BC, L1),
            intersection(A, B, AB2), intersection(A, C, AC),
            union(AB2, AC, R1), msame(L1, R1))),
    format("  交的交换律与分配律在 P({{1,2,3}}) 上全部成立 ✓~n"),

    % 四、A ⊆ B iff A∩B = A
    forall((member(A, P), member(B, P)),
           ((sub(A, B) ->
                (intersection(A, B, ABx), msame(ABx, A))
            ;   (intersection(A, B, ABy), \+ msame(ABy, A))))),
    format("  A⊆B ⟺ A∩B=A 在全部 64 对上验证 ✓~n"),

    % 五、两两不交的三元反例（X={1,2}, Y={3}, Z={1,4}）
    ( pairwise_disjoint([[1,2],[3],[1,4]]) ->
        format("  意外：三元族居然两两不交？~n")
    ;   format("  X={{1,2}},Y={{3}},Z={{1,4}}：两两交非全空（X∩Z={{1}}），非两两不交 ✓~n")
    ),

    % 六、单元素集 ≠ 元素：P({∅}) = {∅, {∅}}——一层花括号之别
    pow([[]], PP), PP = [[], [[]]],
    format("  P({{∅}}) = {{∅, {{∅}}}}：两个元素，单元素集与其元素之别 ✓~n"),

    format("END ===="), nl.

% 集合相等（多重集无关顺序）
msame([], []).
msame(A, B) :- msort(A, As), msort(B, Bs), As = Bs.
