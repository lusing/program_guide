# 第 06 章 · 日期与天数 —— 计算通道
#
# 日历公式（命题 1.74）与康威审判日系统（命题 1.78）双实现，
# 与 Julia Dates 标准库对每一天全量对拍。

println("==== 06 日期与天数")
using Dates

# ---------- 日历公式 ----------
# 自然月下标（1..12 月）的偏移表；原书 j(m) 按"3 月 = 1"给出
# 2,5,0,3,5,1,4,6,2,4,0,3，平移到 Jan..Dec 得下表（推导见 docs/06）。
const Jm = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]

"""命题 1.74：y 年 m 月 d 日 ≡ d + j(m) + g(y) (mod 7)，0 = 星期日。"""
function dayofweek_formula(y::Integer, m::Integer, d::Integer)
    if m <= 2
        y -= 1                          # 1、2 月归属前一年
    end
    g = y + fld(y, 4) - fld(y, 100) + fld(y, 400)
    mod(d + Jm[m] + g, 7)
end

# ---------- 康威审判日 ----------
# 世纪锚（1600:2, 1700:0, 1800:5, 1900:3，每 400 年循环）
const anchors = Dict(16 => 2, 17 => 0, 18 => 5, 19 => 3, 20 => 2, 21 => 0, 22 => 5)

"""命题 1.78：y 年的审判日 ≡ 锚 + N + ⌊N/4⌋ (mod 7)，N = y mod 100。"""
function doomsday(y::Integer)
    C, N = divrem(y, 100)
    a = anchors[C]
    mod(a + N + fld(N, 4), 7)
end

function days_in_month(y::Integer, m::Integer)
    m == 2 ? (iszero(y % 4) && (!iszero(y % 100) || iszero(y % 400)) ? 29 : 28) :
    (m in (1, 3, 5, 7, 8, 10, 12)) ? 31 : 30
end

# ---------- 史实锚点 ----------
@assert dayofweek_formula(1776, 7, 4) == 4       # 《独立宣言》：星期四（例 1.75）
@assert dayofweek_formula(2000, 2, 29) == 2      # 世纪审判日：星期二
@assert dayofweek_formula(2024, 2, 29) == 4      # 2024 审判日：星期四
println("锚点：1776-07-04 星期四；2000-02-29 星期二；2024-02-29 星期四 ✓")

# ---------- 全量对拍：1600–2200 年每一天 ----------
total = 0
for y in 1600:2200, m in 1:12, d in 1:days_in_month(y, m)
    f = dayofweek_formula(y, m, d)
    s = mod(Int(Dates.dayofweek(Date(y, m, d))), 7)   # 1=Mon..7=Sun → 0=Sun
    @assert f == s "公式与标准库在 $y-$m-$d 分歧：$f vs $s"
    global total += 1
end
println("日历公式 × Dates 标准库：$total 天逐日一致 ✓")

# ---------- 康威系统 vs 日历公式（两套独立公式互证） ----------
for y in 1600:2200
    f = dayofweek_formula(y, 2, days_in_month(y, 2))   # 2 月最后一天
    @assert f == doomsday(y) "y = $(y)：公式 $(f) vs 审判日 $(doomsday(y))"
end
println("康威审判日 = 2 月最后一天的星期数：1600–2200 全部一致 ✓")

# 锚点日期组：4/4, 6/6, 8/8, 10/10, 12/12, 5/9, 9/5, 7/11, 11/7 与审判日同星期
for y in 1600:2200
    D = doomsday(y)
    for (m, d) in ((4, 4), (6, 6), (8, 8), (10, 10), (12, 12),
                   (5, 9), (9, 5), (7, 11), (11, 7))
        @assert dayofweek_formula(y, m, d) == D
    end
end
println("锚点日期 4/4, 6/6, 8/8, 10/10, 12/12, 5/9, 9/5, 7/11, 11/7 与审判日同星期 ✓")

# ---------- 星期五十三号普查（6.2 节） ----------
counts = Dict{Int, Int}()
for y in 1600:2200, m in 1:12
    dayofweek_formula(y, m, 13) == 5 && (counts[y] = get(counts, y, 0) + 1)
end
@assert all(1 ≤ c ≤ 3 for c in values(counts))       # 每年 1..3 个
fri87 = [m for m in 1:12 if dayofweek_formula(1987, m, 13) == 5]
@assert fri87 == [2, 3, 11] "1987 年的星期五十三号在 $fri87"
singles = sort(filter(y -> counts[y] == 1, collect(keys(counts))))
@assert 2022 in singles && counts[2022] == 1          # 2022 年仅 5 月一个
println("星期五十三号：每年 1–3 个；1987 = 2/3/11 月；仅一个的年份样本：",
        join(singles[1:6], ", "), " …（2022 在列）✓")

# ---------- 复活节（高斯算法）与福尔摩斯案 ----------
function easter(y::Integer)
    a = mod(y, 19); b = mod(y, 4); c = mod(y, 7)
    k = div(y, 100); p = div(13 + 8k, 25); q = div(k, 4)
    M = mod(15 + k - p - q, 30)
    N = mod(4 + k - q, 7)
    d = mod(19a + M, 30)
    e = mod(2b + 4c + 6d + N, 7)
    day = 22 + d + e                       # 3 月 day 日（day 可能 > 31 → 4 月）
    day > 31 ? (4, day - 31) : (3, day)
end

known = Dict(1990 => (4, 15), 2000 => (4, 23), 2008 => (3, 23),
             2011 => (4, 24), 2016 => (3, 27), 2024 => (3, 31),
             2025 => (4, 20), 2030 => (4, 21), 1893 => (4, 2))
for (y, md) in known
    @assert easter(y) == md "复活节 $(y)：$(easter(y)) ≠ $(md)"
end
println("高斯复活节算法：9 个年份与历书一致；1893 年复活节 = 4 月 2 日")
println("→ 福尔摩斯案：嫌疑人称 1893-04-21 过复活节，而复活节在 4 月 2 日——谎言")

println("END ====")
