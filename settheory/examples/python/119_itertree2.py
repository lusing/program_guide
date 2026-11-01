# 第 119 章：独立递归实现有限策略，并穷举策略表对拍。
from itertools import product


def c_strategy(k):
    return 0 if k == 0 else k - 1


def bad_strategy(_k):
    return 6


def legal_target(k, p):
    return 0 <= p <= k and p == c_strategy(k)


def run_with(strategy, fuel, k=0, parents=()):
    """递归消耗燃料；表策略和函数策略走不同取值接口。"""
    if k >= 6:
        return "done", parents
    if fuel == 0:
        return "out_of_fuel", parents
    p = strategy(k) if callable(strategy) else strategy[k]
    if not legal_target(k, p):
        return "illegal", parents
    return run_with(strategy, fuel - 1, k + 1, parents + (p,))


C_PARENTS = (0, 0, 1, 2, 3, 4)
assert run_with(c_strategy, 6) == ("done", C_PARENTS)
assert run_with(c_strategy, 5)[0] == "out_of_fuel"
assert run_with(bad_strategy, 6)[0] == "illegal"

total = 0
done_tables = []
for table in product(range(7), repeat=6):
    status, parents = run_with(table, 6)
    total += 1
    if status == "done":
        done_tables.append(parents)
assert total == 7**6
assert done_tables == [C_PARENTS]

# 这只是两根已给证书之间的选择，不是适用于每棵无限树的策略。
good = {"even": False, "odd": True}
exists_good = any(good.values())
selected = [branch for branch in ("even", "odd") if good[branch]]
assert exists_good
assert selected == ["odd"]

print("==== 119")
print("六步策略完成；短燃料与非法目标均被拒绝")
print(f"穷举策略表={total}；完整策略={done_tables}")
print("有限存在见证与选枝函数均选 Odd；不声称一般可迭代性")
print("END ====")
