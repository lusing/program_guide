:- encoding(utf8).
% 第 20 章 积力迫与 Easton 定理

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 20 积力迫~n"),
    format("  Product Lemma（20.1）：G 泛型 ⟺ G=G1×G2~n"),
    format("  Levy 崩塌（20.4）：不可达变后继~n"),
    format("  Easton 定理（46）：连续统函数在正则基数处自由~n"),
    format("  约束：(i)F(κ)>κ (ii)单调 (iii)cf F(κ)>κ~n"),
    format("END ====~n").
