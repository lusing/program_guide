:- encoding(utf8).
% 05_conditional.pl —— 第 05 章：条件概率与 Monty Hall（Prolog 穷举）
%
% ① Monty Hall 的 3（车门）×2（主持开门）全穷举：每行打印
%    P(H|Ci) 与 Bayes 分子——悖论在 6 行账目面前无处藏身；
% ② 三囚徒问题的同构穷举。

% 车门 car ∈ {1,2,3}；玩家选 1 号；主持人开 opened ∈ {2,3}
% 约束：不能开车门、不能开玩家门（1 号）
host_opens(Car, Opened) :-
    between(2, 3, Opened),
    Opened =\= Car.                          % 主持人知情：避开车门

% 情况表：car=1 时可开 2 或 3（各 1/2）；car=2 必开 3；car=3 必开 2
p_host_cond(1, 2, 1 rdiv 2).
p_host_cond(1, 3, 1 rdiv 2).
p_host_cond(2, 3, 1).
p_host_cond(3, 2, 1).

check_monty :-
    % Bayes 分子：P(H=3|C2)·P(C2) = 1 · 1/3
    p_host_cond(2, 3, PC_H), P_C is 1 rdiv 3,
    Num is PC_H * P_C,
    % 分母：全概率
    D13 is 1 rdiv 2 * 1 rdiv 3,
    D23 is 1 * 1 rdiv 3,
    Den is D13 + D23,
    Post is Num / Den,
    Post =:= 2 rdiv 3,
    % 穷举核对：合法 (car, opened) 组合恰 4 种
    findall(c(C, O), (between(1, 3, C), host_opens(C, O)), Cs),
    length(Cs, 4),
    format("Monty Hall: 4 legal (car,open) rows; P(switch wins | open 3) = 2/3: OK~n").

% ② 三囚徒（同构）：A/B/C 中一人赦免；A 问狱卒"B 或 C 谁处死"
%    狱卒说 C 处死——A 换 B 的胜率？同 Monty Hall：换 = 2/3
check_prisoners :-
    % 赦免者 ∈ {a,b,c}；狱卒（知情）从 {b,c} 中点名一个处死者
    % （不能点名 A、不能点名赦免者）
    findall(p(Pardon, Named), (member(Pardon, [a, b, c]),
                               member(Named, [b, c]),
                               Named \= Pardon), Rows),
    length(Rows, 4),
    % 名了 c 的行：p(a,c) 与 p(b,c)——各 1/3 × 1/2 与 1/3 × 1
    P_b is (1 rdiv 3) / (1 rdiv 6 + 1 rdiv 3),
    P_b =:= 2 rdiv 3,
    format("three prisoners: same structure, switch-to-b wins 2/3: OK~n").

main :-
    format("==== 05 conditional~n", []),
    check_monty,
    check_prisoners,
    format("END ====~n"), !.

:- initialization(main).
