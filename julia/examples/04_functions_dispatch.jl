greet(name::String) = "hello, $name"
greet(id::Int) = "hello user#$id"

area(r::Float64) = π * r * r
area(w::Int, h::Int) = w * h

println(greet("alice"))
println(greet(9))
println(area(2.0))
println(area(3, 4))

