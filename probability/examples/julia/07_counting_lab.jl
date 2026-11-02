# -*- coding: utf-8 -*-
println("==== 07 counting_lab")
# 第 07 章 Julia：精确闭式、全枚举小宇宙与固定种子模拟的三方对拍。
using Random

Random.seed!(7)

# ① 生日问题：BigInt 有理数保证 22/23 判决无浮点舍入。
function birthday_exact(k)
    q = one(BigInt) // one(BigInt)
    for j in 0:(k - 1)
        q *= big(365 - j) // big(365)
    end
    1 - q
end

p22, p23 = birthday_exact(22), birthday_exact(23)
@assert p22 < 1//2 < p23
@assert binomial(52, 5) == 2_598_960
println("birthday exact: 22 below 1/2 and 23 above 1/2; p23 ≈ ",
        round(Float64(p23); digits=6), ": OK")

function birthday_sim(k, trials)
    hit = 0
    for _ in 1:trials
        seen = falses(365)
        collision = false
        for _ in 1:k
            d = rand(1:365)
            if seen[d]
                collision = true
                break
            end
            seen[d] = true
        end
        collision && (hit += 1)
    end
    hit / trials
end
sim23 = birthday_sim(23, 50_000)
@assert abs(sim23 - Float64(p23)) < 0.01
println("fixed-seed birthday simulation for 23 people is near exact 0.5073: OK")

# ② 52 张五张牌的九类精确账本。
exact_poker = Dict(
    "straight_flush" => 40,
    "four_kind" => 624,
    "full_house" => 3744,
    "flush" => 5108,
    "straight" => 10200,
    "three_kind" => 54912,
    "two_pair" => 123552,
    "pair" => 1098240,
    "nothing" => 1302540,
)
@assert sum(values(exact_poker)) == binomial(52, 5)
println("nine poker counts sum to C(52,5)=2598960: OK")

rank_of(c) = (c - 1) % 13 + 1
suit_of(c) = (c - 1) ÷ 13 + 1

function deal_five()
    deck = collect(1:52)
    hand = Vector{Int}(undef, 5)
    for i in 1:5
        j = i + rand(0:(52 - i))
        deck[i], deck[j] = deck[j], deck[i]
        hand[i] = deck[i]
    end
    hand
end

function classify_full(hand)
    ranks = sort(rank_of.(hand))
    suits = suit_of.(hand)
    cnt = Dict{Int,Int}()
    for r in ranks
        cnt[r] = get(cnt, r, 0) + 1
    end
    vals = sort(collect(values(cnt)); rev=true)
    flush = all(==(suits[1]), suits)
    uniq = unique(ranks)
    straight = length(uniq) == 5 &&
        (uniq[end] - uniq[1] == 4 || uniq == [1, 10, 11, 12, 13])
    flush && straight && return "straight_flush"
    vals[1] == 4 && return "four_kind"
    vals == [3, 2] && return "full_house"
    flush && return "flush"
    straight && return "straight"
    vals[1] == 3 && return "three_kind"
    vals == [2, 2, 1] && return "two_pair"
    vals[1] == 2 && return "pair"
    return "nothing"
end

trials = 50_000
freq = Dict{String,Int}()
for _ in 1:trials
    t = classify_full(deal_five())
    freq[t] = get(freq, t, 0) + 1
end
for (type, count) in exact_poker
    p = count / 2_598_960
    sigma = sqrt(p * (1 - p) / trials)
    @assert abs(get(freq, type, 0) / trials - p) < 5 * sigma + 1e-12
end
println("50,000 simulated five-card hands stay near exact category probabilities: OK")

# ③ 20 张迷你扑克：C(20,3)=1140 手全枚举。
function classify_mini(c1, c2, c3)
    ranks = sort([c1 % 5, c2 % 5, c3 % 5])
    suits = [c1 ÷ 5, c2 ÷ 5, c3 ÷ 5]
    flush = all(==(suits[1]), suits)
    straight = ranks[2] == ranks[1] + 1 && ranks[3] == ranks[2] + 1
    flush && straight && return "straight_flush"
    ranks[1] == ranks[2] == ranks[3] && return "three_kind"
    flush && return "flush"
    straight && return "straight"
    (ranks[1] == ranks[2] || ranks[2] == ranks[3]) && return "pair"
    return "nothing"
end

mini = Dict{String,Int}()
for a in 0:19, b in (a+1):19, c in (b+1):19
    t = classify_mini(a, b, c)
    mini[t] = get(mini, t, 0) + 1
end
@assert sum(values(mini)) == binomial(20, 3) == 1140
@assert mini == Dict(
    "straight_flush" => 12, "three_kind" => 20, "flush" => 28,
    "straight" => 180, "pair" => 480, "nothing" => 420,
)
println("mini-poker exhaustive 1140-hand counts match formulas: OK")

# ④ 桥牌的精确花色账。
bridge_total = binomial(big(52), big(13))
fixed_void = binomial(big(39), big(13)) // bridge_total
any_void = sum(j -> (-1)^(j+1) * binomial(big(4), j) *
                    binomial(big(52 - 13j), big(13)), 1:3) // bridge_total
p4432 = 12 * binomial(13, 4)^2 * binomial(13, 3) * binomial(13, 2) // bridge_total
@assert 1//100 < fixed_void < 14//1000
@assert fixed_void < any_void < 6//100
@assert 20//100 < p4432 < 23//100
println("bridge fixed void, any-void, and 4-4-3-2 probabilities checked: OK")

# ⑤ 秘书问题 n=4：24 个排列全枚举。
function append_permutations!(out, items, prefix)
    if isempty(items)
        push!(out, copy(prefix))
    else
        for (i, x) in enumerate(items)
            rest = vcat(items[1:(i-1)], items[(i+1):end])
            append_permutations!(out, rest, vcat(prefix, x))
        end
    end
end
perms4 = Vector{Int}[]
append_permutations!(perms4, collect(1:4), Int[])

function secretary_win(k, p)
    k == 0 && return p[1] == 4
    threshold = maximum(view(p, 1:k))
    for i in (k+1):4
        if p[i] > threshold
            return p[i] == 4
        end
    end
    false
end
counts = [count(p -> secretary_win(k, p), perms4) for k in 0:3]
@assert counts == [6, 11, 10, 6]
@assert 11//24 == (1//4) * (1//1 + 1//2 + 1//3)
println("secretary n=4 exhaustive counts [6,11,10,6], best k=1 is 11/24: OK")

println("END ====")
