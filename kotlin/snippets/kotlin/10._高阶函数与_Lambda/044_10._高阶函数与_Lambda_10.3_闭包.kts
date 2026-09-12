var counter = 0
val increment: () -> Int = {
    counter++
    counter
}

println(increment())  // 1
println(increment())  // 2
