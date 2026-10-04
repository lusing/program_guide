# 23 · 备忘录

第 19 章留了一个对照表：撤销有两条路——命令式存"操作"、快照式存"状态"。本章兑现承诺，把快照式做出来。GoF 5.6 节的定义：**在不破坏封装性的前提下，捕获一个对象的内部状态，并在该对象之外保存这个状态。这样以后就可将该对象恢复到原先保存的状态**。定义里最值得咀嚼的是"不破坏封装"——快照明明要碰到内部状态，凭什么不破坏？

## 意图与动机

文本编辑器保存撤销历史，最省事的想法是把 `text_` 拿出来存一份。但 `text_` 是 private——外部拿它要么破坏封装（暴露成员），要么给编辑器加一对 `get_state/set_state` 公开方法（封装同样破了，任何人都能改状态）。GoF 的解法是**三方分工**：Originator（编辑器）自己创建和解读快照；Memento（快照对象）对 Originator 之外的任何人都不可读；Caretaker（外部保管者）只管存取快照、永远看不到内容。快照的"黑"由类型系统保证——这就是"不破坏封装"的实现方式。

## 经典写法：快照栈

示例 `memento.hpp`。本例的快照是 `std::string`——一个值类型，对外的可见部分为零，黑箱性质天然成立：

```cpp
// 窄接口备忘录：Originator（TextEditor）自己创建/解读快照；
// Caretaker（外部）只管存取，看不到快照内容——封装不破。
class TextEditor {
public:
    void append(std::string_view s) { text_ += s; }

    void snapshot() { snaps_.push_back(text_); }   // 创建备忘录并交给栈

    bool rollback() {                              // 回滚到最近快照
        if (snaps_.empty()) return false;
        text_ = snaps_.back();
        snaps_.pop_back();
        return true;
    }

    [[nodiscard]] const std::string& text() const { return text_; }
    [[nodiscard]] size_t snapshots() const { return snaps_.size(); }

private:
    std::string text_;
    std::vector<std::string> snaps_;               // 快照栈（Caretaker 角色）
};
```

三个 GoF 角色在这个 30 行的类里全部在场：`snapshot()` 是 Originator 的 `createMemento`（只拷贝状态、不暴露引用）；`rollback()` 是 `restore(memento)`（编辑器自己解读快照）；`snaps_` 是 Caretaker 的保管栈——注意它装的是**值的副本**而非编辑器的引用，外部即使拿到快照（这里连拿都拿不到），也只能整体恢复、不能读改内容。运行侧（`main.cpp`）：

```cpp
TextEditor ed;
ed.append("hello");
ed.append(" world");
ed.snapshot();                    // 存下 "hello world"

ed.append("!!!");
assert(ed.text() == "hello world!!!");
assert(ed.rollback());
assert(ed.text() == "hello world");           // 精确回到快照点
assert(ed.snapshots() == 0);                  // 快照已弹出
assert(!ed.rollback());                       // 空栈：失败
```

运行输出：

```text
备忘录: 快照后追加 -> hello world!!!
备忘录: 回滚后 text=hello world
备忘录: 空快照栈回滚返回失败
备忘录: 两级快照逐级回退 -> a -> 空
```

四组断言：追加后回滚精确回到快照点；回滚消耗一份快照（`snapshots()` 从 1 到 0）；空栈回滚返回 false（可预期失败走返回值，不抛异常——全书错误双轨的口径）；两级快照逐级回退 `hello worldabc -> ...ab -> ...a` 逐字精确。

## 模式结构（ASCII 图）

```text
   Caretaker（调用方）                Originator：TextEditor
        │ snapshot()  ──────────────>  text_ ──copy──> Memento(string 副本)
        │                                              │
        │   只见黑箱：存 / 取 / 删                    ▼
        ▼ <─────────────── Memento ────────  rollback(): 自己解读并恢复
   ┌─────────────┐
   │ 快照栈      │   外部对快照的唯一合法操作是
   │ [s0, s1..]  │   整体交还——读写内容都被类型挡住
   └─────────────┘
```

**窄接口 vs 宽接口**是本模式的术语核心：Memento 有两个接口面——对 Originator 的**宽接口**（能读能写状态），对 Caretaker 的**窄接口**（什么都不给）。C++ 实现窄宽二分的手段与第 17 章代理同源：快照类型把状态成员放 private，Originator 声明为 friend——友元是实现窄宽接口的标准 C++ 工具。本例快照干脆是值类型（string），窄接口退化为"值语义即黑箱"。

## 现代写法：值语义让备忘录退化

C++23 的视角下，本模式有一个惊人的观察：**当状态本身就是不可变值类型时，备忘录模式"消失"了**。看上面的代码——没有 Memento 类、没有 friend、没有接口分层，`snaps_.push_back(text_)` 一行就是完整的备忘录。这是因为 `std::string` 的拷贝构造天然完成了"捕获状态 + 深拷贝隔离"两件事。真正需要模式骨架的场景只剩三个：

1. **状态大、复制贵**——需要写时复制（COW）或增量快照（只记 diff，回滚反向应用），快照对象有了独立身份，模式重新现身。
2. **状态含外部资源**（句柄、连接）——快照不能是 memcpy，需要 Originator 定制"捕获/恢复"逻辑，窄宽接口分层的工程价值回来。
3. **快照要跨进程/落盘**——序列化边界要求快照是显式类型（不能依赖内存布局）。

给一张与第 19 章命令式对照的落地版（同是编辑器撤销）：

| | 命令式（第 19 章） | 快照式（本章） |
|---|---|---|
| 撤销成本 | O(1) 反向执行 | O(text 大小) 整体恢复 |
| 内存 | 每条命令只存参数 | 每快照一份全文 |
| 正确性风险 | undo 必须精确对称 | 快照必须完整不可变 |
| 实现复杂度 | 高（每操作写逆操作） | 低（一行 push_back） |
| 本例选择 | —— | 状态小 → 快照式完胜 |

本章示例选快照式的理由正是表里最后一行：`text_` 是几十字节的小状态，复制成本趋近于零，快照式用最低复杂度拿到精确回滚——**模式的"消失"本身就是一次正确的模式决策**。

## 大状态的两条活路：COW 与增量快照

现代小节说"值语义让模式消失"，前提是状态复制得起。状态一大（几 MB 的文档、几十万结点的棋局），每步快照全量拷贝就撑不住了。两条主流出路：

**出路一：写时复制（COW）。** 快照共享底层数据，谁改谁先复制：

```cpp
class CowText {
public:
    void append(std::string_view s) {
        if (buf_.use_count() > 1) buf_ = std::make_shared<std::string>(*buf_);
        *buf_ += s;                    // 写前复制：此刻才真正拷贝
    }
    [[nodiscard]] std::shared_ptr<const std::string> snapshot() const {
        return buf_;                   // O(1) 快照：只多一个引用计数
    }
    // restore = buf_ = saved;
private:
    std::shared_ptr<std::string> buf_ = std::make_shared<std::string>();
};
```

快照成本从 O(n) 降到 O(1)——`snapshot()` 只是多抓一个 `shared_ptr` 引用。正确性关键在 `append` 开头的 `use_count() > 1` 检查：**只要有别人（历史快照）共享这块数据，写之前必须复制**，否则历史被就地污染（正是陷阱 1 的 COW 形态）。代价是每次写都可能触发全量拷贝——写多读少的负载下 COW 反而更贵，先量再选。

**出路二：增量快照（diff）。** 只记"这步改了什么"，回滚时反向应用：

```cpp
struct Diff {                       // append 场景的最小 diff：位置 + 内容
    size_t pos;
    std::string added;
};
// 快照 = 记一条 Diff（零拷贝）；回滚 = erase(pos, added.size())
```

这就是命令模式的快照皮肤——**增量快照与命令在数学上同构**（diff 的"反向应用"就是 undo）。选择判据：操作可逆且类型少（append/erase/delete-block）用增量，操作不可逆（已删的内容没记全）或类型爆炸用 COW 全量。GoF 的 Constraint Solver 例走的是增量路线，刘伟 22.5 的"原型备忘录"是全量路线的变体。

## 快照栈变时间线：undo/redo 一起拿

本章 `rollback` 弹栈即销毁，redo 无处安放（陷阱 5）。把栈改成数组 + 游标，undo/redo 就是游标移动：

```cpp
class Timeline {
public:
    void checkpoint(const std::string& state) {
        states_.erase(states_.begin() + cursor_ + 1, states_.end());  // 分叉作废
        states_.push_back(state);
        ++cursor_;
    }
    bool undo(std::string& out) {
        if (cursor_ == 0) return false;
        out = states_[--cursor_];      // 回退不销毁
        return true;
    }
    bool redo(std::string& out) {
        if (cursor_ + 1 >= states_.size()) return false;
        out = states_[++cursor_];      // 前进
        return true;
    }
private:
    std::vector<std::string> states_;  // states_[0] 是初始状态
    size_t cursor_ = 0;
};
```

三个要点：`states_[0]` 永远存初始状态（所以 undo 的下界是 `cursor_ == 0` 而非空栈）；undo 只移游标不销毁快照——redo 的原料自动保留；`checkpoint` 先截断游标之后的分支（新操作分叉旧 redo 作废，与第 19 章 History2 的 `todo_.clear()` 同一纪律）。内存账：时间线比弹栈版多留全部历史，配合上一节的 COW/diff 压缩手段使用。第 19 章命令式的 `done_/todo_` 双栈与本章的游标时间线是同一状态机的两种存储——对照着看，"操作历史"与"状态历史"的对称性一目了然。

## 快照的正确性测试

快照模式的核心承诺是"回滚后状态与快照点逐位一致"，测试就该钉这个承诺：

- **回滚等价性**：状态 S₁ → 快照 → 任意多步操作 → 回滚 → 断言状态与 S₁ 相等。本例 main 的第一段就是这个测试的顺序版。
- **多级回退**：S₁→S₂→S₃ 三级快照，逐级回退断言每一级的精确值（`"hello worldabc"` → `"hello worldab"` → `"hello worlda"`）——只测一级会漏"栈序正确性"。
- **空历史边界**：无快照时回滚返回失败且**状态不动**（本例 `!ed.rollback()` 之外，还应断言 text 未变——失败路径的副作用检查）。
- **快照后原对象再改不影响历史**：快照 → 改状态 → 再回滚 → 必须回到快照点。COW 实现特别要测这条（陷阱 1 的直接检验）。

## 陷阱清单

1. **快照含可变引用**（现象：快照存了 `text_&` 或指针；原因：想省拷贝；后果：原对象一改，"历史"跟着变——快照失效且回滚出错。对策：快照一律深拷贝值，大状态用 COW（`std::shared_ptr` + 写时检查）压缩成本）。
2. **快照栈无限增长**（现象：十万次快照，内存涨到 GB；原因：与命令式陷阱 4 同源，快照更肥；后果：慢性 OOM。对策：按条数裁剪、按内容去重（连续快照相同则跳过）、或定期合并为"检查点 + 之后只记 diff"）。
3. **资源型状态 memcpy**（现象：结构体里有 FILE*、socket，快照直接拷结构体；原因：值语义的错觉；后果：回滚后双重 close、句柄复用。对策：资源走 RAII 包装，快照存"重建所需的参数"而非资源本身，恢复时重新打开）。
4. **Caretaker 触碰快照内容**（现象：外部为了 UI 显示把快照 cast 回具体类型读内容；原因：窄接口挡不住强转；后果：封装名存实亡，Originator 内部表示一改全崩。对策：快照类型与 Originator 的友元关系收紧，需要展示历史时由 Originator 提供"描述"方法而非暴露快照）。
5. **rollback 后 redo 语义丢失**（现象：回滚能做，但"重做"无处安放；原因：快照弹出即销毁；后果：功能不完整。对策：与第 19 章 redo 同构——回滚时不弹栈而是指针左移，redo 时指针右移，快照栈变成时间线数组）。

## 三书对应

- 之禅：第 24 章"备忘录模式"（24.2 定义、24.3 应用——克隆羊多利的比喻：复制状态以求恢复、24.4 扩展——"clone 方式的备忘录"讨论深浅拷贝选择，与本章陷阱 1 呼应）。
- 刘伟：第 22 章"备忘录模式"（22.1 动机与定义、22.2 结构与分析——窄/宽接口的正式定义（本章术语出处）、22.3 实例——中国象棋悔棋、22.5 扩展——与原型模式结合实现"原型备忘录"）。
- GoF：第 5 章 5.6 节 Memento——Constraint Solver 例（约束求解器的增量快照，正是"状态大用增量"的现实版），"实现"节讨论"语言支持（C++ 用 friend 实现窄宽接口）、存储增量 vs 完整快照"——本章现代小节的两条分支 GoF 都已点名。

*可选延伸：可运行示例见 examples/23_memento/。*
