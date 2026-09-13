d = Dict("alice" => 90, "bob" => 85)
d["carol"] = 92

println("alice=", get(d, "alice", -1))
println("d-keys=", sort!(collect(keys(d))))

s = Set([1, 2, 2, 3, 4])
push!(s, 5)
println("in-set=", in(3, s))
println("set-size=", length(s))

