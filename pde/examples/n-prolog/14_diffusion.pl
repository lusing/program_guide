:- encoding(utf8).
% 14_diffusion.pl —— 第 14 章：加权隐式格式规则引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 增长因子 G = (1-4(1-θ)r s²)/(1+4θ r s²) 的 |G| 扫描；
%   (2) 稳定条件 2r(1-2θ) <= 1 的求解器；
%   (3) 书表 4.1 的关键行事实。

% |G| <= 1 判定（θ、r 给定，s² 扫描）
max_absG(Theta, R, MaxG) :-
    findall(V,
            ( between(1, 99, I), S2 is I / 100.0,
              Num is 1 - 4 * (1 - Theta) * R * S2,
              Den is 1 + 4 * Theta * R * S2,
              V is abs(Num / Den) ),
            Vs),
    max_list(Vs, MaxG).

stable_wi(Theta, R) :- max_absG(Theta, R, M), M =< 1.0 + 1.0e-9.
unstable_wi(Theta, R) :- max_absG(Theta, R, M), M > 1.0 + 1.0e-9.

% 稳定阈：θ >= 1/2 无条件；θ < 1/2 时 r <= 1/(2(1-2θ))
stability_limit(Theta, unbounded) :- Theta >= 0.5, !.
stability_limit(Theta, Rmax) :- Theta < 0.5, Rmax is 1 / (2 * (1 - 2 * Theta)).
% 修正：θ=0 时 1/(2·1) = 0.5 ✓；但 stability_limit(0.0, 0.5) 首解 Rmax = 0.5
% 而 main 用截断模式调用后继续（; 回溯会给出第二解 unbounded? 不会——第一条被
% cut 挡住）。真正问题：0.4 的阈 1/(2·0.2) = 2.5，浮点给 2.5000000000000004，
% 与字面量 2.5 不合一。用区间判定代替精确合一。

% ---------- 书表 4.1 关键事实 ----------
book41(0.25, 0.0180544, 0.0198705, 0.0189519).
book41(1.0,  blown,     0.0226935, 0.0188963).
book41(8.0,  blown,     shifted,   shifted).   % 勘误：λ=0.5/8 行列序错乱

% ---------- main ----------
main :-
    format("==== 14 diffusion~n"),

    % (1) θ >= 1/2 无条件稳定
    forall(member(Theta, [0.5, 0.75, 1.0]),
           forall(member(R, [0.5, 5.0, 100.0]), stable_wi(Theta, R))),
    format("theta >= 1/2: unconditionally stable (r up to 100)~n"),

    % (2) θ < 1/2 的阈：θ=0 时 r <= 1/2（FTCS 条件）
    stability_limit(0.0, L0), abs(L0 - 0.5) < 1e-9,
    stable_wi(0.0, 0.5), unstable_wi(0.0, 0.51),
    stability_limit(0.4, L4), abs(L4 - 2.5) < 1e-9,
    stable_wi(0.4, 2.4), unstable_wi(0.4, 2.6),
    format("theta=0: r<=1/2; theta=0.4: r<=1/(2(1-0.8))=2.5 (2.4 ok, 2.6 blows)~n"),

    % (3) 书表事实
    book41(0.25, A, B, C),
    abs(A - 0.0180544) < 1e-7, abs(B - 0.0198705) < 1e-7, abs(C - 0.0189519) < 1e-7,
    format("book41 row lam=0.25: FT 0.0180544 / BT 0.0198705 / CN 0.0189519 (exact 0.0183519)~n"),
    book41(1.0, blown, _, _),
    format("book41 row lam=1: FTCS blown; BT/CN fine~n"),

    format("END ====~n").
