:- encoding(utf8).
% 第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）——Prolog 通道
% 与 Python 同一组检查：相遇链引擎、泛型对角避让、
% Fn(3,2) 的 27 条件与 8 全函数（ccc 计数）、力迫关系原子形态。

% ---------- 一、相遇链（定理 3.1 的递归引擎） ----------

% q 延拓 p（更强）：p 是 q 的前缀。
ext_p([], _).
ext_p([X | Ps], [X | Qs]) :- ext_p(Ps, Qs).

% 决定型稠密集 D_n 的选择函数：把 P 延长到第 n 位（0 基）被决定（补 0）。
decider(N, P, Q) :-
    length(P, L),
    (   N < L -> Q = P
    ;   K is N + 1 - L, length(Zs, K), maplist(=(0), Zs), append(P, Zs, Q)
    ).

% 链：从空条件按 0..N 逐层延长。
mk_chain(N, Chain) :-
    numlist(0, N, Ns), chain_from([], Ns, Chain).
chain_from(P, [], [P]).
chain_from(P, [N | Ns], [P | Rest]) :-
    decider(N, P, Q), chain_from(Q, Ns, Rest).

% ---------- 二、泛型对角避让 ----------

% 第 k 个分支在第 k 位（0 基）被翻转。
flip_bit(0, 1).  flip_bit(1, 0).

gen_build_from(Bs, G) :- gen_build_offset(0, Bs, G).
gen_build_offset(_, [], []).
gen_build_offset(K, [B | Bs], [V | Rest]) :-
    nth0(K, B, X), flip_bit(X, V),
    K1 is K + 1, gen_build_offset(K1, Bs, Rest).

% ---------- 三、Fn(3,2) 计数（ccc 有限引擎） ----------

% 相容：公共定义域上取值一致（none = 未定义坐标）。
compat2([], _).
compat2(_, []).
compat2([A | Fs], [B | Gs]) :-
    (A == none ; B == none ; A == B),
    compat2(Fs, Gs).

% 坐标取值：none / 0 / 1。
val(none). val(0). val(1).

% 零填充：none 补 0。
fill0([], []).
fill0([A | Fs], [B | Gs]) :-
    ( A == none -> B = 0 ; B = A ),
    fill0(Fs, Gs).

% 与 f 首次分歧的各长度前缀（例 3.3 的极大反链 A_f）。
antichain_a(F, Af) :-
    length(F, N),
    findall(P,
            ( between(1, N, K), K1 is K - 1,
              length(Pre, K1), append(Pre, [_], F),
              nth0(K1, F, X), flip_bit(X, V),
              append(Pre, [V], P) ),
            Af).

% ---------- 四、力迫关系的原子形态 ----------

% p 力迫「第 n 位（0 基）= b」：p 已决定该位。
forces_bit(P, N, B) :- nth0(N, P, B), integer(B).

bit(0). bit(1).
str_prefix(K, P) :- length(P, K), maplist(bit, P).
str_conds(SC) :-
    findall(P, ( between(0, 3, K), str_prefix(K, P) ), SC).

check_prefix(SC) :-
    forall(( member(P, SC), member(Q, SC), ext_p(P, Q) ),
           prefix_bits_agree(P, Q)).
prefix_bits_agree([], _).
prefix_bits_agree([X | Ps], [X | Qs]) :- prefix_bits_agree(Ps, Qs).

main :-
    writeln("==== 90"),
    % 相遇链：嵌套性 + 长度账
    mk_chain(3, Chain0),
    maplist(length, Chain0, [0, 1, 2, 3, 4]),
    forall(append(_, [P, Q | _], Chain0), ext_p(P, Q)),
    writeln("相遇链：决定型稠密集逐层相遇，链长 [0,1,2,3,4]"),
    % 泛型对角避让
    Ground = [[1,0,1,0],[0,0,0,0],[1,1,0,0],[0,1,1,1]],
    gen_build_from(Ground, G),
    G == [0, 1, 1, 0],
    forall(( nth0(K, Ground, Bk), nth0(K, G, Gk), nth0(K, Bk, Bkk) ),
           Gk \= Bkk),
    writeln("泛型分支 [0,1,1,0]：与每个地基分支恰在第 k 位不同"),
    % ccc 计数
    findall(C, (val(A), val(B), val(Cc), C = [A, B, Cc]), Conds3),
    length(Conds3, 27),
    findall(F, ( member(C, Conds3), fill0(C, F) ), Fills),
    sort(Fills, SFills),
    length(SFills, 8),
    writeln("Fn(3,2)：27 个条件，零填充像恰 2^3 = 8 个（ccc 计数账）"),
    forall(( member(F, Conds3), member(H, Conds3), \+ compat2(F, H) ),
           ( fill0(F, FF), fill0(H, HF), FF \= HF )),
    writeln("相冲条件的零填充两两不同：反链单射进全函数空间 OK"),
    antichain_a([1,0,1], Af),
    forall(( member(A1, Af), member(A2, Af), A1 \== A2 ), \+ compat2(A1, A2)),
    writeln("A_f 反链（与 f 首次分歧于各位的两两相冲条件）OK"),
    % 决定集稠密 + 前缀保持
    str_conds(SC),
    forall(( member(P, SC), between(0, 2, N), decider(N, P, Q) ),
           ( forces_bit(Q, N, 0) ; forces_bit(Q, N, 1) )),
    check_prefix(SC),
    writeln("决定集稠密 + 前缀保持：p 力迫 g(n)=b 时一切泛型满足 OK"),
    writeln("END ====").
