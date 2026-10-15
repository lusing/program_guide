println("==== 64")
D = [0,1,2]
allP(P) = all(P.(D))
exP(P) = any(P.(D))
println("  ¬∀ ≡ ∃¬（恒假谓词）：", !allP(_->false) == exP(_->true) ? "✓" : "✗")
println("  ∀(a∧b) ≡ ∀a ∧ ∀b：", allP(x->x%2==0) && allP(x->true) == allP(x->x%2==0 && true) ? "✓" : "✗")
println("END ====")
