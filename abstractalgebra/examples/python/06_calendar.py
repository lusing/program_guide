# 第 06 章 · 日期与天数 —— Python 通道
#
# 日历公式/康威系统 × datetime 全量对拍 + 复活节 + 椰子问题。

from datetime import date

print("==== 06 日期与天数")

JM = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]          # Jan..Dec 偏移（见 docs/06）


def dayofweek_formula(y, m, d):
    """命题 1.80：A ≡ d + j(m) + g(y) (mod 7)，0 = 星期日。"""
    if m <= 2:
        y -= 1
    g = y + y // 4 - y // 100 + y // 400
    return (d + JM[m - 1] + g) % 7


ANCHORS = {16: 2, 17: 0, 18: 5, 19: 3, 20: 2, 21: 0, 22: 5}


def doomsday(y):
    """命题 1.84：世纪锚 + N + ⌊N/4⌋。"""
    C, N = divmod(y, 100)
    return (ANCHORS[C] + N + N // 4) % 7


def days_in_month(y, m):
    if m == 2:
        return 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28
    return 31 if m in (1, 3, 5, 7, 8, 10, 12) else 30


# ---------- 锚点 ----------
assert dayofweek_formula(1776, 7, 4) == 4       # 星期四
assert dayofweek_formula(2000, 2, 29) == 2
assert dayofweek_formula(2024, 2, 29) == 4
print("锚点：1776-07-04 星期四；2000-02-29 星期二；2024-02-29 星期四 ✓")

# ---------- 全量对拍：1800–2100 年每一天 ----------
total = 0
for y in range(1800, 2101):
    for m in range(1, 13):
        for d in range(1, days_in_month(y, m) + 1):
            f = dayofweek_formula(y, m, d)
            s = (date(y, m, d).weekday() + 1) % 7   # Mon=0..Sun=6 → 0=Sun
            assert f == s, (y, m, d, f, s)
            total += 1
print(f"日历公式 × datetime 标准库：{total} 天逐日一致 ✓")

# ---------- 康威系统互证 ----------
for y in range(1800, 2101):
    assert dayofweek_formula(y, 2, days_in_month(y, 2)) == doomsday(y)
    for (m, d) in ((4, 4), (6, 6), (8, 8), (10, 10), (12, 12),
                   (5, 9), (9, 5), (7, 11), (11, 7)):
        assert dayofweek_formula(y, m, d) == doomsday(y)
print("康威审判日 = 2 月最后一天；九个锚点日期同星期（1800–2100）✓")

# ---------- 星期五十三号 ----------
counts = {}
for y in range(1800, 2101):
    counts[y] = sum(1 for m in range(1, 13) if dayofweek_formula(y, m, 13) == 5)
assert all(1 <= c <= 3 for c in counts.values())
assert [m for m in range(1, 13) if dayofweek_formula(1987, m, 13) == 5] == [2, 3, 11]
assert counts[2022] == 1
print("星期五十三号：每年 1–3 个；1987 = 2/3/11 月；2022 仅 5 月一个 ✓")

# ---------- 高斯复活节 + 福尔摩斯案 ----------
def easter(y):
    a, b, c = y % 19, y % 4, y % 7
    k = y // 100
    p = (13 + 8 * k) // 25
    q = k // 4
    M = (15 + k - p - q) % 30
    N = (4 + k - q) % 7
    d = (19 * a + M) % 30
    e = (2 * b + 4 * c + 6 * d + N) % 7
    day = 22 + d + e
    return (4, day - 31) if day > 31 else (3, day)

KNOWN = {1990: (4, 15), 2000: (4, 23), 2008: (3, 23), 2011: (4, 24),
         2016: (3, 27), 2024: (3, 31), 2025: (4, 20), 2030: (4, 21),
         1893: (4, 2)}
for y, md in KNOWN.items():
    assert easter(y) == md, (y, easter(y), md)
print("复活节算法：9 个年份对历书全对；1893 年复活节 = 4 月 2 日")
print("→ 福尔摩斯案：1893-04-21 非复活节（也不在星期日），嫌疑人在撒谎")

# ---------- 椰子问题（习题 1.97） ----------
def coconut_ok(n0):
    n = n0
    for _ in range(5):
        if (n - 1) % 5 != 0:
            return False
        n = (n - 1) // 5 * 4
    return n % 4 == 0                     # 早晨四人分得动（习题口径）

cand = next(n for n in range(1, 20001) if coconut_ok(n))
assert cand == 3121 == 5**5 - 4
assert coconut_ok(3121 + 5**5)            # 下一个解：差恰为 5⁵
print(f"椰子问题：最小解 {cand} = 5⁵ − 4；解的间距恰为 5⁵（N ≡ −4 mod 5⁵）✓")

print("END ====")
