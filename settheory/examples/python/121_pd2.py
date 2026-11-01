"""第 121 章：独立枚举 256 张收益表，检查两层博弈与策略证书。"""


def bit(table, a, b, h):
    index = (4 if a else 0) + (2 if b else 0) + (1 if h else 0)
    return bool((table >> index) & 1)


def projected_payoff(table, a, b):
    return bit(table, a, b, False) or bit(table, a, b, True)


def base_value(table):
    # 先计算投影收益，再对两步原博弈作逆向归纳。
    projected = {(a, b): projected_payoff(table, a, b)
                 for a in (False, True) for b in (False, True)}
    return any(all(projected[a, b] for b in (False, True))
               for a in (False, True))


def auxiliary_value(table):
    # 直接递归三步博弈，不枚举策略表，与 Julia 的策略枚举独立。
    def visit(prefix):
        if len(prefix) == 3:
            return bit(table, *prefix)
        children = [visit(prefix + (move,)) for move in (False, True)]
        return all(children) if len(prefix) == 1 else any(children)

    return visit(())


def base_strategy_wins(table, a):
    return all(projected_payoff(table, a, b) for b in (False, True))


def auxiliary_strategy_wins(table, a, hidden):
    return all(bit(table, a, b, hidden[b]) for b in (False, True))


lift_total = 0
pullback_total = 0
for table in range(256):
    assert base_value(table) == auxiliary_value(table)
    for a in (False, True):
        if base_strategy_wins(table, a):
            hidden = {}
            for b in (False, True):
                hidden[b] = next(h for h in (False, True)
                                 if bit(table, a, b, h))
            assert auxiliary_strategy_wins(table, a, hidden)
            lift_total += 1
        for h0 in (False, True):
            for h1 in (False, True):
                hidden = {False: h0, True: h1}
                if auxiliary_strategy_wins(table, a, hidden):
                    assert base_strategy_wins(table, a)
                    pullback_total += 1
assert lift_total == 288
assert pullback_total == 512


def example_payoff(a, b, h):
    return (a or not b) and h == b


representative = sum(
    (1 << ((4 if a else 0) + (2 if b else 0) + (1 if h else 0)))
    for a in (False, True) for b in (False, True) for h in (False, True)
    if example_payoff(a, b, h)
)
assert representative == 145
assert base_value(representative) == auxiliary_value(representative) is True
assert base_strategy_wins(representative, True)
assert not base_strategy_wins(representative, False)
assert auxiliary_strategy_wins(representative, True, {False: False, True: True})
assert all(example_payoff(True, b, b) for b in (False, True))
assert all(projected_payoff(representative, True, b) for b in (False, True))
assert not any(example_payoff(False, True, h) for h in (False, True))

print("==== 121")
print("table=145 base=true auxiliary=true")
print(f"tables=256/256 lifts={lift_total} pullbacks={pullback_total}")
print("representative_lift=1 representative_pullback=1")
print("END ====")
