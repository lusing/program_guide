function safe_div(a, b)
    if b == 0
        return (false, "divide by zero")
    end
    return (true, a / b)
end

for (a, b) in [(10, 2), (10, 0)]
    ok, value = safe_div(a, b)
    println(ok ? "ok=$(value)" : "err=$(value)")
end

try
    parse(Int, "abc")
catch e
    println("caught=", typeof(e))
finally
    println("finally")
end

