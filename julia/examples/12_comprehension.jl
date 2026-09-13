squares = [x^2 for x in 1:10 if iseven(x)]
pairs = [(x, y) for x in 1:3, y in 1:2]
freq = Dict(ch => count(==(ch), "banana") for ch in ['a', 'b', 'n'])

println("squares=", squares)
println("pairs-size=", size(pairs))
println("freq=", freq)

