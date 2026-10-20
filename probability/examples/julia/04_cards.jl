# -*- coding: utf-8 -*-
println("==== 04 cards")
# 第 04 章 Julia：牌桌的频率对拍（零依赖）。
# ① 十万手 5 张牌的九型频率 vs 精确概率；② 桥牌 Elliott
#    分布：20 万次发牌的花色分布谱（4-4-3-2 的占比）。
using Random

Random.seed!(4)

# 牌的编码：rank 1..13，suit 1..4；发 5 张（无放回抽样）
function deal_hand()
    # 52 张中无放回取 5（Fisher-Yates 部分洗牌）
    deck = collect(1:52)
    hand = Vector{Int}(undef, 5)
    for i in 1:5
        j = i + rand(0:(52 - i))
        deck[i], deck[j] = deck[j], deck[i]
        hand[i] = deck[i]
    end
    hand
end

rank_of(c) = (c - 1) % 13 + 1
suit_of(c) = (c - 1) ÷ 13 + 1

function classify(hand)
    ranks = sort(map(rank_of, hand))
    suits = map(suit_of, hand)
    cnt = Dict{Int,Int}()
    for r in ranks
        cnt[r] = get(cnt, r, 0) + 1
    end
    vals = sort(collect(values(cnt)), rev = true)
    flush = all(==(suits[1]), suits)
    # 顺子判定（A 可作 1 或 14）
    uniq = unique(ranks)
    straight = length(uniq) == 5 &&
        (uniq[end] - uniq[1] == 4 ||
         (uniq == [1, 10, 11, 12, 13]))   # A2345? 不：10JQKA
    if flush && straight
        return "straight_flush"
    elseif vals[1] == 4
        return "four_kind"
    elseif vals == [3, 2]
        return "full_house"
    elseif flush
        return "flush"
    elseif straight
        return "straight"
    elseif vals[1] == 3
        return "three_kind"
    elseif vals == [2, 2, 1]
        return "two_pair"
    elseif vals[1] == 2
        return "pair"
    else
        return "nothing"
    end
end

# ① 十万手的频率表 vs 精确概率
TRIALS = 100_000
freq = Dict{String,Int}()
for _ in 1:TRIALS
    c = classify(deal_hand())
    freq[c] = get(freq, c, 0) + 1
end
exact = Dict(
    "straight_flush" => 40, "four_kind" => 624, "full_house" => 3744,
    "flush" => 5108, "straight" => 10200, "three_kind" => 54912,
    "two_pair" => 123552, "pair" => 1098240, "nothing" => 1302540)
TOTAL = 2_598_960
for (k, v) in exact
    sim = get(freq, k, 0) / TRIALS
    theo = v / TOTAL
    # 3σ 带（二项）：sqrt(p(1-p)/N)
    sigma = sqrt(theo * (1 - theo) / TRIALS)
    @assert abs(sim - theo) < 4 * sigma + 1e-9 (k, sim, theo)
end
println("100k hands: all 9 hand frequencies within 4-sigma of theory: OK")

# ② 桥牌花色分布谱：13 张的花色分布最常见档位
function bridge_suit_pattern()
    deck = collect(1:52)
    for i in 1:13
        j = i + rand(0:(52 - i))
        deck[i], deck[j] = deck[j], deck[i]
    end
    suits = sort([count(c -> suit_of(c) == s, deck[1:13]) for s in 1:4],
                 rev = true)
    join(suits, "-")
end
pat = Dict{String,Int}()
for _ in 1:200_000
    p = bridge_suit_pattern()
    pat[p] = get(pat, p, 0) + 1
end
f4432 = get(pat, "4-4-3-2", 0) / 200_000
@assert 0.20 < f4432 < 0.235          # 理论 ≈ 21.6%——最常见
println("bridge patterns: 4-4-3-2 occurs ", round(f4432 * 100, digits=1),
        "% (theory 21.6%, most common): OK")

println("END ====")
