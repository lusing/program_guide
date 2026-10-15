import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
print("==== 64")
D = [0,1,2]
allP = lambda P: all(P(x) for x in D)
exP = lambda P: any(P(x) for x in D)
assert (not allP(lambda _: False)) == exP(lambda _: True)
print("  ¬∀ ≡ ∃¬ ✓")
assert allP(lambda x: x%2==0 and True) == (allP(lambda x: x%2==0) and allP(lambda _: True))
print("  ∀(a∧b) ≡ ∀a ∧ ∀b ✓")
print("END ====")
