println("==== 65")
println("  条件证明：A∪{a} ⊨ b → A ⊨ a→b 的语义验证")
println("  （即 (a→b) 的真值表：只在 a=T,b=F 时为 F）")
for (a_val, b_val) in [(true,true),(true,false),(false,true),(false,false)]
    impl = !a_val || b_val
    println("    a=$(a_val), b=$(b_val) → a→b = $(impl)")
end
# 唯一 F 的行是 a=T, b=F
@assert (!(true) || false) == false
@assert (!(true) || true) == true
@assert (!(false) || true) == true
@assert (!(false) || false) == true
println("  唯一 F 行：a=T ∧ b=F ✓")
println("END ====")
