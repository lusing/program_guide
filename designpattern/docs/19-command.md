# 19 · 命令

责任链管"请求找谁处理"，命令模式管"请求本身长什么样"——它把一次操作**封装成对象**，于是操作可以像数据一样被排队、记账、撤销、重放。GoF 5.2 节的定义：**将一个请求封装为一个对象，从而使你可用不同的请求对客户进行参数化；对请求排队或记录请求日志，以及支持可撤销的操作**。定义里列的四个用途，撤销是 C++ 工程里最常见的一个，本章以它为主线。

## 意图与动机

编辑器的撤销（undo）是命令模式的教科书场景：用户做了"插入 ab"、"插入 cd"、"删除 b"三步，按 Ctrl+Z 要逐步回退。朴素实现里"一步操作"散落在 UI 回调函数中——回调只管往前做，**没有留下"怎么退回来"的痕迹**。要在数据结构层面支持撤销，每一步操作必须至少回答两个问题：**我做了什么（execute）** 和 **我怎么退回去（undo）**——一对操作，天然是一个对象的两个方法。把操作封装成对象后，"撤销栈"就是普通的命令容器，"重做"就是再执行一遍命令对象。

## 经典写法：可撤销的文档编辑

示例 `command.hpp`。Receiver 与命令接口：

```cpp
// Receiver：真正的执行者，命令的 undo 依赖它的原语。
class Document {
public:
    void insert(size_t pos, std::string_view s) { /* 插入 */ }
    void erase(size_t pos, size_t n) { /* 删除 */ }
    [[nodiscard]] const std::string& text() const { return text_; }
private:
    std::string text_;
};

// Command 接口：execute 与 undo 成对——撤销是命令模式的第一红利。
class Command {
public:
    virtual ~Command() = default;
    virtual void execute() = 0;
    virtual void undo() = 0;
};
```

两个具体命令——注意 undo 各自的"信息从哪来"：

```cpp
class InsertCommand final : public Command {
public:
    InsertCommand(Document& doc, size_t pos, std::string_view s)
        : doc_(doc), pos_(pos), s_(s) {}
    void execute() override { doc_.insert(pos_, s_); }
    void undo() override { doc_.erase(pos_, s_.size()); }   // 对称操作：插的逆是删
private:
    Document& doc_;
    size_t pos_;
    std::string s_;
};

class EraseCommand final : public Command {
public:
    EraseCommand(Document& doc, size_t pos, size_t n) : doc_(doc), pos_(pos), n_(n) {}
    void execute() override {
        removed_ = doc_.text().substr(pos_, n_);   // 执行时记下删了什么
        doc_.erase(pos_, n_);
    }
    void undo() override { doc_.insert(pos_, removed_); }   // 回插
private:
    Document& doc_;
    size_t pos_;
    size_t n_;
    std::string removed_;   // 撤销信息在 execute 时捕获——undo 不靠猜
};
```

对比这两段是本章的核心一课：**InsertCommand 的撤销信息编译期已知**（插了什么、插哪了，构造时都有），**EraseCommand 的撤销信息运行期才知道**（删除到底删到了什么——越界截断后的实际内容，只有 execute 执行完才确定）。所以前者 undo 直接用参数，后者在 execute 里先捕获 `removed_`。这条"**撤销信息要么构造期存好、要么执行时捕获，绝不二次推算**"的纪律是 undo 正确性的全部秘密。History 收尾：

```cpp
class History {
public:
    void push(std::unique_ptr<Command> c) {
        c->execute();                            // 入栈即执行
        done_.push_back(std::move(c));
    }
    bool undo() {
        if (done_.empty()) return false;
        done_.back()->undo();
        done_.pop_back();
        return true;
    }
    [[nodiscard]] size_t size() const { return done_.size(); }
private:
    std::vector<std::unique_ptr<Command>> done_;
};
```

运行输出：

```text
命令: 三步后 text=acd
命令: 三次 undo 精确回退，空历史返回失败
```

断言逐步验证：三步操作后 `"acd"`（ab + cd - b），三次 undo 后精确回到 `""`、`"ab"`、`"abcd"` 的逐级状态，空历史 undo 返回 false——撤销的每一步都与操作严格对称。

## 模式结构（ASCII 类图）

```text
  调用方（菜单/快捷键）──push(cmd)──> History（调用者+记账）
                                        │ 持有
                                        ▼
                              ┌──────────────────┐
                              │ Command          │
                              │ +execute()=0     │
                              │ +undo()=0        │
                              └────┬────────┬────┘
                                   │        │
                        InsertCommand   EraseCommand
                        （undo 信息构造期已知）（undo 信息执行时捕获）
                                   │ doc_ 引用
                                   ▼
                              Document（Receiver：只有 insert/erase 原语）
```

四个 GoF 角色：Command（接口）、ConcreteCommand（两个实现）、Receiver（Document）、Invoker（History——它不知道命令做什么，只知道"执行"和"撤销"两个动作）。**Invoker 与 Receiver 的解耦正是命令模式的收益**：快捷键系统（Invoker）可以绑定任何命令，不认识 Document。

## 现代写法：function 命令 + 对称 lambda 对

只有一个 execute/undo 两种操作的命令，类显得隆重——两个闭包就够（`command.hpp` 末尾）：

```cpp
struct FnCommand final : Command {
    std::function<void()> do_, undo_;
    void execute() override { do_(); }
    void undo() override { undo_(); }
};

// 使用：对称 lambda 对
auto cmd = std::make_unique<FnCommand>();
cmd->do_   = [&doc2] { doc2.insert(0, "hello"); };
cmd->undo_ = [&doc2] { doc2.erase(0, 5); };     // 对称：插的逆是删
hist2.push(std::move(cmd));
```

**"对称 lambda 对"是命令模式的现代最小形态**：do 和 undo 写在相邻两行，对称性肉眼可查。运行输出第三行验证它与类版撤销语义等效。取舍与全书 function/继承二分一致：命令只有一对操作、就地组装用 lambda；命令有身份（要序列化、要按类型分派、要在菜单里显示名字）用类。真实编辑器（含 VS Code 的实现思路）最终都要类形态——命令要持久化到磁盘、要在撤销历史里显示描述文字，闭包装不下这些身份信息。

## 补全 redo：完整的时间线

本章 History 只有 undo。补齐 redo 只需两处改动——教科书常忘的第 5 条陷阱就藏在这里：

```cpp
class History2 {
public:
    void push(std::unique_ptr<Command> c) {
        c->execute();
        done_.push_back(std::move(c));
        todo_.clear();                  // 新操作分叉：旧 redo 分支作废
    }
    bool undo() {
        if (done_.empty()) return false;
        done_.back()->undo();
        todo_.push_back(std::move(done_.back()));
        done_.pop_back();
        return true;
    }
    bool redo() {
        if (todo_.empty()) return false;
        todo_.back()->execute();        // 重做就是再执行一遍命令对象
        done_.push_back(std::move(todo_.back()));
        todo_.pop_back();
        return true;
    }
private:
    std::vector<std::unique_ptr<Command>> done_;   // 已做（undo 从尾部回退）
    std::vector<std::unique_ptr<Command>> todo_;   // 已撤销（redo 从尾部恢复）
};
```

三个不变量撑起正确性：`done_` 是从初始状态出发已执行的操作序列；undo 把命令从 `done_` 搬到 `todo_`（不销毁）；**push 新命令时清空 `todo_`**——时间线在当前位置分叉，被撤销的旧分支永远失去 redo 资格。命令对象"执行/撤销可重复调用"的性质（execute 与 undo 都是幂等于 receiver 原语的）让 redo 零成本：命令还是那个命令，再 execute 一次就是重做。

## 命令的其他三个用途

GoF 定义列了四个用途，撤销之外还有三个，各给一句话的最小形态：

- **排队**：`std::queue<std::unique_ptr<Command>>` + 消费线程——生产者组装命令，消费者执行。命令对象的"参数已冻结"性质使队列安全（入队时的参数就是执行时的参数，不受后续变量变化影响）。
- **日志**：执行前把命令序列化落盘，崩溃后重放即恢复状态——数据库 WAL（Write-Ahead Log）的思想原型。要求命令可序列化（这也是真实系统最终都要类形态命令的原因之一，见下）。
- **宏命令**：一个命令持有命令列表，`execute` 是顺序执行全部、`undo` 是逆序撤销全部——宏的撤销对称性由"成员命令各自对称"免费获得。

```cpp
// 宏命令的骨架：execute 顺序、undo 逆序——对称性免费获得
class MacroCommand final : public Command {
public:
    void add(std::unique_ptr<Command> c) { parts_.push_back(std::move(c)); }
    void execute() override { for (auto& c : parts_) c->execute(); }
    void undo() override {
        for (auto it = parts_.rbegin(); it != parts_.rend(); ++it) (*it)->undo();
    }
private:
    std::vector<std::unique_ptr<Command>> parts_;
};
```

## 与备忘录的分工：第 23 章预告

撤销有两种主流实现：命令式（本章——存"操作"，回退时反向执行）和快照式（备忘录——存"状态"，回退时整体恢复）。提前给一张对照表：

| | 命令式（本章） | 快照式（第 23 章备忘录） |
|---|---|---|
| 存什么 | 每步操作对象 | 每步后的完整状态 |
| 撤销成本 | O(1) 反向执行 | O(状态大小) 恢复 |
| 内存 | 小（命令只存参数） | 大（状态可能大） |
| 适用 | 状态大、操作小（编辑器） | 状态小（配置、棋局） |
| 风险 | 反向操作必须精确对称 | 快照必须完整且不可变 |

第 23 章会用 `TextEditor` 把快照版也实现一遍，两条路在同一 receiver 上正面对照。

## 陷阱清单

1. **undo 不对称**（现象：`do_` 插入两个字符、`undo_` 只删一个；原因：手工写对称对没对齐；后果：撤销后状态偏移，越撤销越乱。对策：对称 lambda 对紧挨着写；类命令把"执行时捕获的撤销信息"做成 undo 的唯一依据，不二次计算）。
2. **undo 依赖时序的环境**（现象：EraseCommand 的 undo 回插到 `pos_`，但此前的操作改变了该位置的含义；原因：命令假设环境静止；后果：多级撤销后内容错位。对策：撤销信息用"内容 + 锚点"（插在哪个内容前/后）而非裸下标；或干脆存执行前快照做"半命令半快照"）。
3. **命令执行有外部副作用**（现象：InsertCommand.execute 里弹窗、发网络；原因：命令里塞了 UI/IO；后果：undo 时副作用无法逆转。对策：命令只改模型状态，UI 反应交给观察者（第 25 章）监听模型）。
4. **History 无上限**（现象：撤销栈存十万条命令；原因：不做裁剪；后果：内存慢性增长。对策：按条数或按内存量裁剪（丢最老的），或把老操作序列化到磁盘）。
5. **重做（redo）栈忘记清空**（现象：撤销后做新操作，redo 栈里还留着旧命令；原因：漏了"新操作清 redo"；后果：重做跳回旧分支，历史分叉混乱。对策：push 新命令时清空 redo 栈——教科书常忘的一行）。

## 三书对应

- 之禅：第 15 章"命令模式"（15.2 定义、15.3 应用——Tailor 做衣服的比喻：客户提需求、裁缝接单执行、15.4 扩展——反悔问题正是 undo 的讨论）。
- 刘伟：第 18 章"命令模式"（18.1 动机与定义、18.2 结构与分析、18.3 实例——电视机遥控器（18.3.1）/功能键设置（18.3.2），18.4 效果与应用、18.5 扩展——撤销操作（加法器 Adder 的 undo 实例））。
- GoF：第 5 章 5.2 节 Command——"实现"节讨论"支持取消和重做"（多级撤销需要历史表列；DeleteCommand 每次执行删的内容不同，须在执行时存储——本章 EraseCommand 捕获 `removed_` 与 GoF 原文同源）与"避免取消操作过程中的错误积累"（本章陷阱 2 的源头讨论），另列命令的四个用途（按需参数化、排队、日志、撤销）。

*可选延伸：可运行示例见 examples/19_command/。*

---

上一章：[18 责任链](18-chainofresp.md) · 下一章：[20 解释器](20-interpreter.md)
