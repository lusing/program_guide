// 23 备忘录。
#include <cassert>
#include <print>
#include <string>

#include "memento.hpp"

int main() {
    using namespace dp;

    TextEditor ed;
    ed.append("hello");
    ed.append(" world");
    assert(ed.text() == "hello world");

    // ---- 快照与回滚 ----
    ed.snapshot();
    assert(ed.snapshots() == 1);

    ed.append("!!!");
    assert(ed.text() == "hello world!!!");
    std::println("备忘录: 快照后追加 -> {}", ed.text());

    assert(ed.rollback());
    assert(ed.text() == "hello world");           // 精确回到快照点
    assert(ed.snapshots() == 0);                  // 快照已弹出
    std::println("备忘录: 回滚后 text={}", ed.text());

    // ---- 空栈回滚失败 ----
    assert(!ed.rollback());
    std::println("备忘录: 空快照栈回滚返回失败");

    // ---- 多快照逐级回退 ----
    ed.append("a");
    ed.snapshot();
    ed.append("b");
    ed.snapshot();
    ed.append("c");
    assert(ed.text() == "hello worldabc");
    assert(ed.snapshots() == 2);

    assert(ed.rollback() && ed.text() == "hello worldab");
    assert(ed.rollback() && ed.text() == "hello worlda");
    std::println("备忘录: 两级快照逐级回退 -> a -> 空");

    std::println("自检通过");
}
