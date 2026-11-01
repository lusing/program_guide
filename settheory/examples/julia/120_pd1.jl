# 第 120 章：自底向上的有限博弈表；不冒充无限投影决定性。

payoff(h) = length(h) == 4 && h[2] == h[3]

function solve_bottom_up()
    values = Dict{Tuple{Vararg{Bool}},Bool}()
    for bits in Iterators.product(ntuple(_ -> (false, true), 4)...)
        values[bits] = payoff(bits)
    end
    for len in 3:-1:0
        for prefix in Iterators.product(ntuple(_ -> (false, true), len)...)
            children = (values[(prefix..., false)], values[(prefix..., true)])
            values[prefix] = iseven(len) ? (children[1] || children[2]) :
                                               (children[1] && children[2])
        end
    end
    return values
end

certified_play(b, d) = (false, b, b, d)

function check_chapter()
    values = solve_bottom_up()
    @assert length(values) == 31
    @assert values[()]
    @assert all(values[(false, b)] for b in (false, true))
    @assert all(payoff(certified_play(b, d))
                for b in (false, true), d in (false, true))
    @assert !payoff((false, true, false, false))
    println("==== 120")
    println("positions=31 root=true certificate=4/4")
    println("END ====")
end

check_chapter()
