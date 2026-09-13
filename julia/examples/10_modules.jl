module MathTools
export add2, clamp01

add2(x) = x + 2
clamp01(x) = max(0.0, min(1.0, x))
end

using .MathTools
println(add2(10))
println(clamp01(1.8))

