# 第 121 章：256 张有限收益表上的原/辅助博弈对拍与策略转移。

bit(table, a, b, h) =
    ((table >> ((a ? 4 : 0) + (b ? 2 : 0) + (h ? 1 : 0))) & 1) == 1

response(mask, b) = ((mask >> (b ? 1 : 0)) & 1) == 1

function base_strategy_wins(table, a)
    for b in (false, true)
        any(h -> bit(table, a, b, h), (false, true)) || return false
    end
    return true
end

base_value(table) = any(a -> base_strategy_wins(table, a), (false, true))

function auxiliary_strategy_wins(table, a, mask)
    for b in (false, true)
        bit(table, a, b, response(mask, b)) || return false
    end
    return true
end

function auxiliary_value(table)
    for a in (false, true), mask in 0:3
        auxiliary_strategy_wins(table, a, mask) && return true
    end
    return false
end

lift_total = 0
pullback_total = 0
for table in 0:255
    @assert base_value(table) == auxiliary_value(table)
    for a in (false, true)
        if base_strategy_wins(table, a)
            mask = 0
            for b in (false, true)
                h_index = findfirst(h -> bit(table, a, b, h), (false, true))
                @assert h_index !== nothing
                h = (false, true)[h_index]
                h && (mask |= b ? 2 : 1)
            end
            @assert auxiliary_strategy_wins(table, a, mask)
            global lift_total += 1
        end
        for mask in 0:3
            if auxiliary_strategy_wins(table, a, mask)
                @assert base_strategy_wins(table, a)
                global pullback_total += 1
            end
        end
    end
end
@assert lift_total == 288
@assert pullback_total == 512

auxiliary_payoff(a, b, h) = (a || !b) && (h == b)
projected_payoff(a, b) = any(h -> auxiliary_payoff(a, b, h), (false, true))
representative = sum((auxiliary_payoff(a, b, h) ?
    (1 << ((a ? 4 : 0) + (b ? 2 : 0) + (h ? 1 : 0))) : 0)
    for a in (false, true), b in (false, true), h in (false, true))
@assert representative == 145
@assert base_value(representative) == auxiliary_value(representative) == true
@assert base_strategy_wins(representative, true)
@assert !base_strategy_wins(representative, false)
@assert auxiliary_strategy_wins(representative, true, 2)
@assert all(b -> auxiliary_payoff(true, b, b), (false, true))
@assert all(b -> projected_payoff(true, b), (false, true))
@assert all(h -> !auxiliary_payoff(false, true, h), (false, true))

println("==== 121")
println("table=145 base=true auxiliary=true")
println("tables=256/256 lifts=$lift_total pullbacks=$pullback_total")
println("representative_lift=1 representative_pullback=1")
println("END ====")
