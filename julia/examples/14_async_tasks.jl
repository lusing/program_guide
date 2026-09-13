ch = Channel{Int}(2)

t = @async begin
    for i in 1:3
        put!(ch, i * i)
    end
    close(ch)
end

vals = Int[]
for v in ch
    push!(vals, v)
end

wait(t)
println("vals=", vals)

f = @async begin
    sleep(0.05)
    return 42
end
println("fetch=", fetch(f))

