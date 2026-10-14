:- encoding(utf8).
% 第 22 章 Suslin 问题

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 22 Suslin 问题~n"),
    format("  树=偏序集+良序前驱集；层/分支/反链~n"),
    format("  Aronszajn：height=ω₁+层可数+无不可数分支（ZFC ✓）~n"),
    format("  Suslin：+反链可数（独立：Tennenbaum-Jech+Jensen）~n"),
    format("  Δ-系统引理是 ccc 验证的核心~n"),
    format("END ====~n").
