import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
print("==== 65")
print("  条件证明：A∪{a} ⊨ b → A ⊨ a→b 的语义验证")
print("  （即 (a→b) 的真值表：只在 a=T,b=F 时为 F）")
for a, b in [(True,True),(True,False),(False,True),(False,False)]:
    print(f"    a={a}, b={b} → a→b = {(not a) or b}")
assert ((not True) or False) == False
assert ((not True) or True) == True
assert ((not False) or True) == True
assert ((not False) or False) == True
print("  唯一 F 行：a=T ∧ b=F ✓")
print("END ====")
