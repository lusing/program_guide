:- encoding(utf8).
% 第 19 章 CH 与 AC 独立性：ccc 与泛型实数

% 条件的表示：dom/val 列表对
cond(Dom, Val).

% 相容性检查
compatible(cond(D1,V1), cond(D2,V2)) :-
    forall((member(X, D1), member(X, D2)),
           (nth0(I1, D1, X), nth0(I2, D2, X),
            nth0(I1, V1, B1), nth0(I2, V2, B2),
            B1 == B2)).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 19 CH 独立性~n"),
    P1 = cond([(0,0)], [1]),
    P2 = cond([(0,0)], [0]),
    P3 = cond([(0,1)], [1]),
    (   \+ compatible(P1, P2) -> format("  同域不同值：不相容 ✓~n"); true ),
    (   compatible(P1, P3) -> format("  不同域：相容 ✓~n"); true ),
    format("  ccc（引理 19.3）：有限域+可数值→不相容族可数~n"),
    format("  ⟹ Fn(κ×ω,2) 保基数 → 加 κ 个泛型实数 → 2^ℵ₀=κ~n"),
    format("  κ=ω₂ 时 ¬CH（Cohen 1963）~n"),
    format("  AC 独立性：HOD(A) 对称子模型 + 置换自同态（定理 45）~n"),
    format("END ====~n").
