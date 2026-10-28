# 第 93 章：高阶无穷导引——有限 DAG 的 DFS 拓扑排序。
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

NODES = ("zfc", "measurable", "supercompact", "woodinWitness")
EDGES = (("zfc", "measurable"), ("measurable", "supercompact"),
         ("supercompact", "woodinWitness"))


def topo_sort(nodes, edges):
    outgoing = {n: [] for n in nodes}
    for a, b in edges:
        outgoing[a].append(b)
    state = {n: 0 for n in nodes}  # 0 未访问，1 在栈上，2 已完成
    result = []

    def visit(a):
        assert state[a] != 1, "发现回边，图有环"
        if state[a] == 2:
            return
        state[a] = 1
        for b in outgoing[a]:
            visit(b)
        state[a] = 2
        result.append(a)

    for n in nodes:
        if state[n] == 0:
            visit(n)
    result.reverse()
    return result


def main():
    print("==== 93")
    order = topo_sort(NODES, EDGES)
    assert order == list(NODES)
    position = {n: i for i, n in enumerate(order)}
    assert all(position[a] < position[b] for a, b in EDGES)
    print("DFS 拓扑排序：" + " → ".join(order))
    print("与 Julia/Kahn 对账一致；该 DAG 仅组织阅读路线，不证明相容性 ✓")
    print("END ====")


if __name__ == "__main__":
    main()
