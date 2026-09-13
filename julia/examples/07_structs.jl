struct Point
    x::Float64
    y::Float64
end

mutable struct Counter
    value::Int
end

distance(p::Point) = sqrt(p.x^2 + p.y^2)

p = Point(3.0, 4.0)
println("distance=", distance(p))

c = Counter(0)
c.value += 1
println("counter=", c.value)

