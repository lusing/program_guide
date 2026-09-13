path = "julia_demo.txt"
open(path, "w") do io
    write(io, "line1\nline2\n")
end

lines = readlines(path)
println("line-count=", length(lines))
for line in lines
    println("read=", line)
end

