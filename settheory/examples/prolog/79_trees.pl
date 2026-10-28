:- encoding(utf8).
% 第 79 章：树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）——Prolog 通道
% 三个搜索，全部是定理 2.44（可数稠密子集族必有泛善子集）与树分支语言的
% 有限形态：
% (1) 深 K 二叉前缀树枚举全部 2^K 根长度 K 的枝，并构造逐次补 0 的等高枝；
% (2) 有限子集偏序（包含序）上对稠密集 D_a={S : a∈S} 逐次加强，
%     下闭得到泛善滤子，机器核对定向、下闭、与每个 D_a 相遇；
% (3) 例 2.17(3) 的有限版：{0..M} 上严格下降序列树，最大枝长恰为 M+1。

% ---------- (1) 二叉前缀树的枝 ----------
bit(0). bit(1).

% 长度 K 的 0/1 串即完整二叉树深 K 的等高枝候选。
branch_of(K, B) :- length(B, K), maplist(bit, B).

n_branches(K, N) :- findall(B, branch_of(K, B), Bs), length(Bs, N).

% 逐次补 0 的等高枝（定理 2.44 在 D_n={长度≥n} 上的构造）。
zero_branch(0, []) :- !.
zero_branch(K, [0|Rest]) :- K > 0, K2 is K - 1, zero_branch(K2, Rest).

prefix_n(_, 0, []) :- !.
prefix_n([H|T], N, [H|P]) :- N > 0, N2 is N - 1, prefix_n(T, N2, P).

% 枝的全部前缀（含空前缀）即它下闭生成的滤子。
prefixes(B, Ps) :-
    length(B, K),
    findall(P, (between(0, K, N), prefix_n(B, N, P)), Ps).

% 两个串一个是另一个前缀（链上两两相容）。
comparable(P, Q) :- length(P, N), prefix_n(Q, N, P).
comparable(P, Q) :- length(Q, N), prefix_n(P, N, Q).

% ---------- (2) 有限子集偏序上的泛善滤子 ----------
% 底集 {1..B}；条件用有序表表示有限子集，序为包含（表包含）。
sublist([], _).
sublist([X|T], L) :- member(X, L), sublist(T, L).

subset_of([], []).
subset_of([H|T], [H|S]) :- subset_of(T, S).
subset_of([_|T], S) :- subset_of(T, S).

% 链 ∅ ⊂ {1} ⊂ {1,2} ⊂ … ⊂ {1..B}：第 a 步与 D_a 相遇。
chain(B, Chain) :- findall(S, (between(0, B, A), numlist(1, A, S)), Chain).

% 链中某条件包含 X（与 D_X 相遇的见证）。
meets(Chain, X) :- member(S, Chain), member(X, S).

% 链的下闭：B 有限时顶条件是全集，下闭就是全部子集。
all_subsets(B, Subs) :-
    numlist(1, B, Base),
    findall(S, subset_of(Base, S), Subs).

% 定向：F 中任意两条件之并（有序表合并去重）仍被 F 中条件包含（顶条件即可）。
union_lists([], L, L).
union_lists([X|T], L, U) :- member(X, L), !, union_lists(T, L, U).
union_lists([X|T], L, [X|U]) :- union_lists(T, L, U).

directed(F, Top) :-
    forall((member(P, F), member(Q, F)),
           (union_lists(P, Q, U), sublist(U, Top))).

downclosed(F, Subs) :-
    forall((member(P, F), member(S, Subs)), (sublist(S, P) -> member(S, F) ; true)).

generic_filter(B) :-
    chain(B, Chain),
    all_subsets(B, F),
    numlist(1, B, Top),
    forall(between(1, B, A), meets(Chain, A)),   % 相遇每个 D_a
    directed(F, Top),                             % 定向
    downclosed(F, F).                             % 全幂集对包含自然下闭

% ---------- (3) 严格下降序列树 ----------
desc_node(M, L) :-
    numlist(0, M, A),
    subset_of(A, S),
    reverse(S, L).   % 选出的升序子集反转为严格下降序列；空集给出空节点

max_desc_len(M, K) :-
    findall(Len, (desc_node(M, L), length(L, Len)), Ls),
    max_list(Ls, K).

% ---------- 主检定 ----------
main :-
    format("==== 79~n"),
    % (1) 深 K 二叉树：恰 2^K 根枝；补 0 构造给出等高枝，其前缀两两相容。
    forall(between(1, 8, K),
           (n_branches(K, N), N =:= 2^K)),
    zero_branch(6, B6), length(B6, 6),
    prefixes(B6, Ps6), length(Ps6, 7),
    forall((member(P, Ps6), member(Q, Ps6)), comparable(P, Q)),
    format("二叉树搜索：K=1..8 等高枝数恰 2^K；深 6 补 0 枝含 ~w 个前缀且两两相容 ✓~n", [7]),
    % (2) B=6 个稠密集全部相遇的泛善滤子（构造性，不依赖 ccc）。
    generic_filter(6),
    writeln("泛善滤子搜索：{1..6} 子集偏序上链 ∅⊂{1}⊂…⊂{1..6} 的下闭定向、下闭且相遇 6 个稠密集 ✓"),
    % (3) 下降序列树：最大枝长 M+1（M=0..5）。
    forall(between(0, 5, M), (max_desc_len(M, K), K =:= M + 1)),
    max_desc_len(5, K5),
    format("下降序列树：M=0..5 最大枝长均为 M+1（M=5 时 ~w，取尽字母）✓~n", [K5]),
    writeln("END ====").
