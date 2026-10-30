:- encoding(utf8).
% 第 111 章：有限树秩递归、下降链搜索与截面投影见证查询。

% ── 一、树（堆编码：根 1，子点 2c/2c+1；深度上限 2） ──
depthd(1, 0) :- !.
depthd(C, D) :- C > 1, P is C // 2, depthd(P, D0), D is D0 + 1.

% 秩：叶 0、内部点 = 子最大 + 1（引理 3.5 的赋秩机制）。
rho(T, C, 0) :- \+ member(C, T), !.
rho(T, C, 0) :- depthd(C, 2), !.
rho(T, C, R) :-
    C0 is 2 * C, C1 is 2 * C + 1,
    ( member(C0, T) -> rho(T, C0, R0) ; R0 = 0 ),
    ( member(C1, T) -> rho(T, C1, R1) ; R1 = 0 ),
    ( ( \+ member(C0, T), \+ member(C1, T) ) -> R = 0
    ; R is 1 + max(R0, R1) ), !.

% 树枝（无秩）：从根逐层下行的全长路径（显式深度推进）。
branch(T, P) :- branch1(T, 1, 0, P).
branch1(T, C, 2, [C]) :- !, member(C, T).
branch1(T, C, D, [C | Rest]) :-
    D < 2, member(C, T),
    ( CC is 2 * C ; CC is 2 * C + 1 ),
    D1 is D + 1, branch1(T, CC, D1, Rest).

has_branch(T) :- branch(T, _).

% ── 二、下降链搜索（引理 3.4 的 WF 对偶） ──
% 关系 R 上的下降链：member((Y,X),R) 读作 Y 在 X 下方。
% 带燃料的有限链 + 极小终点 + 直接环见证。
desc(R, [X], _) :- \+ (member((Y, X), R), Y \= X).
desc(R, [X | T], N) :-
    N > 1, member((Y, X), R), Y \= X,
    N1 is N - 1, desc(R, T, N1).

% 直接环见证：X、Y 互相在对方下方（无穷下降的种子）。
loop_witness(R, X, Y) :- member((Y, X), R), member((X, Y), R), X \= Y.

all_end_minimal(R) :-
    forall(desc(R, C, 3), (append(_, [M], C), \+ member((Y, M), R), Y \= M)).

% ── 三、截面投影见证（引理 3.3：α ∈ p[S] ⟺ S(α) 有全长见证 y） ──
% 二维树 S 的对以等长表给出；见证 = 三层前段对全在 S。
wit3(S, [A, B], [C, D]) :-
    member(([], []), S),
    member(([A], [C]), S),
    member(([A, B], [C, D]), S).

in_proj(S, Alpha) :- length(Alpha, 2), wit3(S, Alpha, _).

% ── 四、主查询 ──
main :-
    format("==== 111~n"),
    % 三树秩账。
    T0 = [1,2,3], T1 = [1,2,3,4], T2 = [1,2,3,4,5],
    rho(T0, 1, 1), rho(T1, 1, 2), rho(T2, 1, 2),
    \+ has_branch(T0),
    has_branch(T1), has_branch(T2),
    branch(T1, [1,2,4]),
    % 下降链：良基关系一切链终于极小元、无环；环状关系有环见证。
    R_wf = [(1,2),(2,3)],
    R_cyc = [(1,2),(2,1)],
    all_end_minimal(R_wf),
    \+ (loop_witness(R_wf, _, _)),
    loop_witness(R_cyc, 1, 2),
    desc(R_wf, [3,2,1], 3),
    % 截面投影：对角树全域投影；单侧树只投 x 首位 0。
    S_diag = [([],[]),([0],[0]),([1],[1]),
              ([0,0],[0,0]),([0,1],[0,1]),([1,0],[1,0]),([1,1],[1,1])],
    forall((between(0,1,A), between(0,1,B)),
           in_proj(S_diag, [A,B])),
    S_side = [([],[]),([0],[0]),([0],[1]),([1],[0]),
              ([0,0],[0,0]),([0,0],[1,0]),([0,1],[0,1]),([0,1],[1,1])],
    in_proj(S_side, [0,0]), in_proj(S_side, [0,1]),
    \+ in_proj(S_side, [1,0]), \+ in_proj(S_side, [1,1]),
    wit3(S_diag, [0,1], [0,1]),             % 对角见证可查
    wit3(S_side, [0,1], [1,1]),             % 单侧见证（x=0 允许 y 双选）
    format("三树秩账（1/2/2）；树枝见证；良基无环/环状有环；对角/单侧投影账~n"),
    writeln("END ====").
