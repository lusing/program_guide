:- encoding(utf8).
% 第 102 章：局部见证族查询——f-闭包点、f-谢拉赫条款与
% 「每个函数都有足够见证」的全称量词检查。

% f 以表表示：nthf(I, F, V)。（整数下标——succ/1 模式不匹配
% 整数，首版只查了 i=0 被对拍抓获。）
nthf(0, [H|_], H).
nthf(I, [_|T], V) :- I > 0, I1 is I - 1, nthf(I1, T, V).

% f-闭包：∀ i<κ, f(i)<κ（定义 1.25(i) 影子）。
closedL(_, 0).
closedL(F, K) :- K > 0, K1 is K - 1, closed_upto(F, K1).

closed_upto(F, MaxI) :- forall((between(0, MaxI, I), nthf(I, F, V)), V < MaxI + 1).

% f-谢拉赫型条款：闭包 + κ<j(f)(κ) + 层捕获。
%（member 先行：Jfk 未绑定时 K < Jfk 会炸 < /2。）
f_shelah(F, K, Jfk, Cap) :-
    closedL(F, K),
    member(Jfk, Cap),
    K < Jfk.

% 局部见证族：对每个函数 f 找一个见证（伍丁型全称量词的有限面）。
has_witness(F, K, Jfk, Cap) :-
    between(1, 3, K),
    f_shelah(F, K, Jfk, Cap).

% 敌人造法：常值 κ 函数在任何 ≥κ 处…… 精确说：
% constant(κ) 在 κ 处闭包失败。
constant(K, F) :- length(F, 4), maplist(=(K), F).

main :-
    format("==== 102~n"),
    % 样本函数的见证集。
    findall(K, (between(1,3,K), closedL([1,1,1,1], K)), W11),
    W11 == [2, 3],
    findall(K, (between(1,3,K), closedL([2,2,2,2], K)), W22),
    W22 == [3],
    \+ closedL([1,3,1,1], 2),
    \+ closedL([1,3,1,1], 3),
    % 敌人：每个固定 κ 被常值 κ 打死。
    forall(between(1,3,K),
           (constant(K, F), \+ closedL(F, K))),
    % f-谢拉赫正反样本。
    f_shelah([1,1,1,1], 2, 3, [3]),
    \+ f_shelah([2,2,2,2], 2, 3, [3]),
    \+ f_shelah([1,1,1,1], 2, 4, [3]),
    % 局部见证族存在性（cap=[2,3,4] 宽捕获下三类函数各有见证）。
    has_witness([1,1,1,1], _, _, [2,3,4]),
    has_witness([2,2,2,2], _, _, [2,3,4]),
    \+ has_witness([1,3,1,1], _, _, [2,3,4]),
    format("见证集 [1,1,1,1]→[2,3]、[2,2,2,2]→[3]；常值 κ 敌人；~n"),
    format("f-谢拉赫正反样本；无闭包点者无见证——全称量词边界在闭包款~n"),
    writeln("END ====").
