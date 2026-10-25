:- encoding(utf8).
% 第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）——Prolog 通道
% 与 Python 同一组检查：迭代相容分解、典型嵌入冲突换算、
% 有限支撑与坐标合并、Cantor 记录函数、greedy 相遇引擎。

% ---------- 一、一步迭代的相容分解（定理 3.14 的组合核心） ----------

% q 延拓 p（更强）：p 是 q 的前缀。
ext_p(_, []).
ext_p([X | Ps], [X | Qs]) :- ext_p(Ps, Qs).

% 串条件相容：互为前缀。
agree_p(P, Q) :- ext_p(P, Q).
agree_p(P, Q) :- ext_p(Q, P).

% 迭代条件取对：分量分别相容。
iter_agree(P1-Q1, P2-Q2) :- agree_p(P1, P2), agree_p(Q1, Q2).

% 合并构造：每个分量取公共延长（较长者）。
cmn(P, Q, R) :- ext_p(P, Q), !, R = Q.
cmn(P, _Q, R) :- R = P.
iter_common(P1-Q1, P2-Q2, R1-R2) :- cmn(P1, P2, R1), cmn(Q1, Q2, R2).

% 有限条件空间：0..2 层前缀。
bit(0). bit(1).
str_prefix(K, P) :- length(P, K), maplist(bit, P).
str_conds(SC) :-
    findall(P, ( between(0, 2, K), str_prefix(K, P) ), SC).

% 双向账：相容对有公共延长，且合并后的分量确是延长。
check_iter_agree(SC) :-
    forall(( member(P1, SC), member(Q1, SC), member(P2, SC), member(Q2, SC),
             iter_agree(P1-Q1, P2-Q2) ),
           ( iter_common(P1-Q1, P2-Q2, R1-R2),
             ext_p(P1, R1), ext_p(P2, R1), ext_p(Q1, R2), ext_p(Q2, R2) )).

% ---------- 二、典型嵌入的冲突换算（引理 3.54(6)） ----------

canon(P, P-[]).

check_canon(SC) :-
    forall(( member(P, SC), member(P2, SC) ),
           ( canon(P, CP), canon(P2, CP2),
             (  iter_agree(CP, CP2) -> agree_p(P, P2)
             ;  \+ agree_p(P, P2), \+ iter_agree(CP, CP2)
             ) )).

% ---------- 三、有限支撑迭代（定义 3.36） ----------

% 支撑：偏离最大元（none）的坐标个数。
spt(P, N) :- include(\=(none), P, Qs), length(Qs, N).

% 坐标合并：每个坐标取首先给出决定者。
merge_c(P, Q, R) :- maplist(take_first, P, Q, R).
take_first(none, B, B) :- !.
take_first(A, _, A).

% ---------- 四、Cantor 记录函数（定理 3.18 的 (b) 款） ----------

cantor(B, G, N) :- S is B + G, T is S * (S + 1), N is T // 2 + G.

% (b)：π 的第一分量不超过编号。
check_cantor_self_le :-
    forall(( between(0, 7, B), between(0, 7, G), cantor(B, G, N) ),
           B =< N).

% (a)：5x5 编号两两不同。
check_cantor_inj :-
    findall(N, ( between(0, 4, B), between(0, 4, G), cantor(B, G, N) ), Ns),
    sort(Ns, SNs), length(SNs, 25).

% greedy 相遇引擎（定理 3.1 的迭代面）。
decider(N, P, Q) :-
    length(P, L),
    (   N < L -> Q = P
    ;   K is N + 1 - L, length(Zs, K), maplist(=(0), Zs), append(P, Zs, Q)
    ).

greedy_chain(N, Chain) :-
    numlist(0, N, Ns), greedy_from([], Ns, Chain).
greedy_from(P, [], [P]).
greedy_from(P, [N | Ns], [P | Rest]) :-
    decider(N, P, Q), greedy_from(Q, Ns, Rest).

main :-
    writeln("==== 91"),
    str_conds(SC),
    check_iter_agree(SC),
    writeln("迭代相容 iff 分量相容：合并构造双向账 OK"),
    check_canon(SC),
    writeln("典型嵌入：i(p) 与 i(p') 相容 <=> p 与 p' 相容 OK"),
    spt([none, 1, none, 0], 2),
    merge_c([none, 1], [0, none], [0, 1]),
    merge_c([1, none], [none, 0], [1, 0]),
    check_support_bound,
    writeln("支撑计数 + 坐标合并：[none,1,none,0] 支撑 2 OK"),
    check_cantor_self_le,
    check_cantor_inj,
    writeln("Cantor 配对：b <= 编号（64 例）、5x5 编号两两不同 OK"),
    greedy_chain(2, Chain),
    maplist(length, Chain, [0, 1, 2, 3]),
    writeln("greedy 相遇链：长度 [0,1,2,3]——一步迭代的演示面 OK"),
    writeln("END ====").

check_support_bound :-
    findall(P, ( val3(A), val3(B), val3(C), P = [A, B, C] ), Ps),
    length(Ps, 27),
    forall(( member(P, Ps), spt(P, N) ), N =< 3).
val3(none). val3(0). val3(1).
