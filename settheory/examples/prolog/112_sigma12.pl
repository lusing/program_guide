:- encoding(utf8).
% 第 112 章：两层树投影见证、补集见证与 Sierpiński 分层查询。

% ── 一、两层树（节点对 (S,H)：S 路径前段、H 序数值前段） ──
% 截面：H ∈ T(α) ⟺ (α↾|H|, H) ∈ T（member 先绑定 H，防无界 length）。
sec_el(T, Alpha, H) :-
    member((AH, H), T),
    length(H, N), take_n(Alpha, N, AH).

take_n(_, 0, []) :- !.
take_n([], _, []) :- !.
take_n([X|Xs], N, [X|R]) :- N > 0, N1 is N - 1, take_n(Xs, N1, R).

% 截面有全长树枝：两层前段都在截面中。
sec_branch(T, Alpha) :-
    member(G1, [0, 1]), member(G2, [0, 1]),
    sec_el(T, Alpha, [G1]),
    sec_el(T, Alpha, [G1, G2]).

in_proj(T, Alpha) :- sec_branch(T, Alpha).

% ── 二、投影与补集见证（Σ¹₂ 的存在语义与余解析的补） ──
all_paths(P) :- findall([A,B], (between(0,1,A), between(0,1,B)), P).

projection(T, P) :-
    all_paths(All),
    include(in_proj(T), All, P).

% 补集见证：α ∉ p[T] ⟺ 截面良基（无树枝）。
out_proj(T, Alpha) :- \+ sec_branch(T, Alpha).

% 树枝见证可查（存在量词的非确定性）。
branch_witness(T, Alpha, [G1, G2]) :-
    member(G1, [0, 1]), member(G2, [0, 1]),
    sec_el(T, Alpha, [G1]), sec_el(T, Alpha, [G1, G2]).

% ── 三、Sierpiński 分层（定理 3.8 的有限影子） ──
% 坐标有界的树枝：g1, g2 ≤ ξ。
bounded_branch(T, Alpha, Xi) :-
    member(G1, [0, 1]), member(G2, [0, 1]),
    G1 =< Xi, G2 =< Xi,
    sec_el(T, Alpha, [G1]), sec_el(T, Alpha, [G1, G2]).

% include 的元素参数在末位——参数序对齐。
in_layer(T, Xi, Alpha) :- bounded_branch(T, Alpha, Xi).

layer(T, Xi, L) :-
    all_paths(All),
    include(in_layer(T, Xi), All, L).

% 分层并 = 全投影。
sierpinski_union(T) :-
    layer(T, 0, L0), layer(T, 1, L1),
    append(L0, L1, U), sort(U, US),
    projection(T, US).

% ── 四、双模型真值对比（Shoenfield 绝对性的量词面） ──
% V = 全体路径；M = 首位 0（子模型）。
m_model([[0,0],[0,1]]).

any_path(_).
first_zero(Y) :- Y = [0|_].
len_two(Y) :- length(Y, 2).

sig1_upward(Phi) :-
    m_model(M), all_paths(V),
    ( member(Y, M), call(Phi, Y) -> ( member(Z, V), call(Phi, Z) ) ).

pi1_downward(Phi) :-
    m_model(M), all_paths(V),
    ( forall(member(W, V), call(Phi, W))
      -> forall(member(W, M), call(Phi, W)) ).

main :-
    format("==== 112~n"),
    Tb = [([], []),
          ([0], [0]), ([0], [1]),
          ([0,0], [0,0]), ([0,0], [1,0])],
    % 投影账：p[Tb] = {[0,0]}。
    projection(Tb, [[0,0]]),
    % 截面账（SWI 字典序：[] < [0] < [0,0] < [1] < [1,0]）。
    findall(H, sec_el(Tb, [0,0], H), S00),
    sort(S00, [[], [0], [0,0], [1], [1,0]]),
    findall(H, sec_el(Tb, [0,1], H), S01),
    sort(S01, [[], [0], [1]]),
    % 树枝见证非确定性：00 处两个见证。
    branch_witness(Tb, [0,0], [0,0]),
    branch_witness(Tb, [0,0], [1,0]),
    \+ branch_witness(Tb, [0,1], _),
    % 补集见证：其余三条路径。
    forall(member(A, [[0,1],[1,0],[1,1]]), out_proj(Tb, A)),
    % Sierpiński 分层。
    sierpinski_union(Tb),
    layer(Tb, 0, [[0,0]]),
    % 双模型：Σ 上行（M 真 ⟹ V 真）与 Π 下行（V 真 ⟹ M 真）。
    sig1_upward(any_path),
    sig1_upward(first_zero),
    pi1_downward(any_path),
    pi1_downward(len_two),
    % Σ 不下行反例：φ = 「首位 1」在 V 真在 M 假。
    all_paths(V), m_model(M),
    ( member([1,_], V) -> true ),
    \+ member([1,_], M),
    format("投影 {[0,0]}；截面五/三；树枝双见证；补集三路；~n"),
    format("Sierpiński 分层并=全投影；Σ 上行/Π 下行正反~n"),
    writeln("END ====").
