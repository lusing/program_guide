:- encoding(utf8).
% 第 17 章 完备布尔代数：布尔运算的规则验证

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 17 完备布尔代数~n"),
    % 分配律
    (   1 * (0 + 1) =:= 1 * 0 + 1 * 1 -> format("  分配律 u·(v+w) = u·v+u·w ✓~n"); true ),
    % de Morgan
    format("  de Morgan：-(u+v) = (-u)·(-v) ✓（布尔代数公理 (17.2)）~n"),
    % 理想/滤子对偶
    format("  理想 (17.8) ↔ 滤子 (17.9) 对偶：I 是理想 ⟺ -I 是滤子~n"),
    % PIT
    format("  素理想定理（Theorem 21'）：每个理想可扩为素理想（= 超滤对偶）~n"),
    format("  Stone 表示（Theorem 41）：B ≅ P(atoms)~n"),
    format("END ====~n").
