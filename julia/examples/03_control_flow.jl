function main()
    n = 7
    if n < 0
        println("negative")
    elseif n == 0
        println("zero")
    else
        println("positive")
    end

    s = 0
    for i in 1:5
        s += i
    end
    println("sum=", s)

    k = 0
    while k < 3
        k += 1
    end
    println("k=", k)
end

main()
