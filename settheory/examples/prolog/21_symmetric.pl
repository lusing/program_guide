:- encoding(utf8).
% 第 21 章 对称子模型

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 21 对称子模型~n"),
    format("  ZFA：原子+集合；原子置换诱导宇宙自同构~n"),
    format("  正规滤子+对称性 ⟹ 遗传对称类 ⊨ ZF~n"),
    format("  例 I：A 无可数子集（AC 失败）~n"),
    format("  例 II：可数对族无选择函数（可数 AC 失败）~n"),
    format("  对称模型：HS 名的 G 解释 ⊆ M[G] ⊨ ZF+¬AC~n"),
    format("END ====~n").
