#check @Bool.xor
#check @Bool.or_false
#check @Bool.and_true
#check @Bool.true_and
#check @Bool.false_or
#check @Bool.and_false
#check @Bool.false_and
example (x : Bool) : (true && x) = x := rfl
example : (Bool.xor true false) = true := rfl
