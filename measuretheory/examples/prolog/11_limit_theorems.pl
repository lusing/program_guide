:- encoding(utf8).
% 11_limit_theorems.pl —— 第 11 章：有限格上三大定理的退化检查（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,...,6}，均匀概率 μ = |A|/6。函数 = 6 元组（值 ∈ {0,1,2}），
% lint(F) = (Σ值)/6。
% ① MCT 上行：有限链积分单调升到顶（有限空间上链自动"到达"极限）；
% ② Fatou：终归常值列上取等号（有限值域 liminf 精确可算）；
% ③ DCT：控制条件 |f| ≤ g 逐点核对（有限空间一切函数可积）。
% 诚实记录：三大定理的反例都需要无穷测度或无界性——有限模型全部退化为
% 平凡真（与第 09 章退化定理一脉相承）。

qle(q(A,B), q(C,D)) :- A * D =< C * B.
qeq(q(A,B), q(C,D)) :- A * D =:= C * B.

omega6([1,2,3,4,5,6]).

lint(F, q(S, 6)) :- sum_list(F, S).

le_pt(F, G) :- maplist([X,Y]>>(X =< Y), F, G).

% --- ① MCT 上行（有限链） ---
check_mct :-
    Chain = [[0,0,0,0,0,0], [0,1,0,1,0,0], [1,1,1,1,0,0], [1,1,1,1,1,2]],
    maplist(lint, Chain, Ms),
    check_nondecr(Ms),                       % 积分列单调不降
    last(Chain, Top), lint(Top, Mtop), last(Ms, Mlast),
    qeq(Mtop, Mlast),                        % 顶点积分 = 极限积分
    Ms = [q(0,6), q(2,6), q(4,6), q(7,6)],
    format("MCT-up finite chain: integrals 0,2/6,4/6,7/6 nondecreasing: OK~n").

check_nondecr([_]).
check_nondecr([A,B|T]) :- qle(A,B), check_nondecr([B|T]).

% --- ② Fatou（终归常值列取等号） ---
check_fatou :-
    Seq = [[1,0,1,0,1,0], [0,1,0,1,0,1], [1,1,0,0,1,1], [1,1,0,0,1,1]],
    maplist(lint, Seq, Ms),
    % liminf(积分列) = 尾列最小值的极限；终归常值 → = 末值
    last(Ms, MLast), last(Seq, Lim), lint(Lim, MLim),
    qeq(MLim, MLast), qeq(MLim, q(4,6)),
    format("Fatou equality on eventually-constant seq: mu(liminf) = 4/6: OK~n").

% --- ③ DCT 控制逐点核对 ---
check_dct :-
    F = [1,0,1,1,0,1], G = [2,1,2,2,1,2],
    le_pt(F, G),                             % |f| ≤ g 逐点
    lint(G, MG), qeq(MG, q(10,6)),           % ∫g = 10/6（有限空间恒可积）
    format("DCT control pointwise, g = 10/6 integrable: OK~n").

% --- main ---
main :-
    format("==== 11 limit_theorems~n", []),
    check_mct,
    check_fatou,
    check_dct,
    format("END ====~n"), !.
