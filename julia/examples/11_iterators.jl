struct CountDown
    start::Int
end

function Base.iterate(c::CountDown, state=c.start)
    state < 1 && return nothing
    return (state, state - 1)
end

for x in CountDown(5)
    print(x, " ")
end
println()

