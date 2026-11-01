"""第 120 章：递归有限博弈求解器；与 Julia 的填表法独立。"""

from itertools import product


def payoff(history):
    return len(history) == 4 and history[1] == history[2]


def value(history):
    if len(history) == 4:
        return payoff(history)
    children = [value(history + (move,)) for move in (False, True)]
    return any(children) if len(history) % 2 == 0 else all(children)


def certified_play(b, d):
    return (False, b, b, d)


def main():
    assert value(())
    assert all(value((False, b)) for b in (False, True))
    leaves = list(product((False, True), repeat=4))
    assert len(leaves) == 16
    assert all(payoff(certified_play(b, d)) for b in (False, True) for d in (False, True))
    assert not payoff((False, True, False, False))
    print("==== 120")
    print("leaves=16 root=true certificate=4/4")
    print("END ====")


if __name__ == "__main__":
    main()
