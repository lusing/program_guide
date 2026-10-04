// 19 命令。
#include <cassert>
#include <memory>
#include <print>
#include <string>
#include <utility>

#include "command.hpp"

int main() {
    using namespace dp;

    Document doc;
    History hist;

    // ---- insert -> insert -> erase，History 记账，text 逐点断言 ----
    hist.push(std::make_unique<InsertCommand>(doc, 0, "ab"));
    assert(doc.text() == "ab");
    assert(hist.size() == 1);

    hist.push(std::make_unique<InsertCommand>(doc, 2, "cd"));
    assert(doc.text() == "abcd");

    hist.push(std::make_unique<EraseCommand>(doc, 1, 1));   // 删掉 'b'
    assert(doc.text() == "acd");
    assert(hist.size() == 3);
    std::println("命令: 三步后 text={}", doc.text());

    // ---- 逐次 undo：状态精确回退 ----
    assert(hist.undo() && doc.text() == "abcd");   // 撤销 erase：'b' 回插
    assert(hist.undo() && doc.text() == "ab");     // 撤销 insert("cd")
    assert(hist.undo() && doc.text().empty());     // 撤销 insert("ab")
    assert(!hist.undo());                          // 空历史：撤销失败
    assert(hist.size() == 0);
    std::println("命令: 三次 undo 精确回退，空历史返回失败");

    // ---- 现代对照：function 命令，对称 lambda 对 ----
    Document doc2;
    History hist2;
    auto cmd = std::make_unique<FnCommand>();
    cmd->do_   = [&doc2] { doc2.insert(0, "hello"); };
    cmd->undo_ = [&doc2] { doc2.erase(0, 5); };     // 对称：插的逆是删
    hist2.push(std::move(cmd));
    assert(doc2.text() == "hello");

    auto cmd2 = std::make_unique<FnCommand>();
    cmd2->do_   = [&doc2] { doc2.erase(0, 2); };
    cmd2->undo_ = [&doc2] { doc2.insert(0, "he"); };
    hist2.push(std::move(cmd2));
    assert(doc2.text() == "llo");

    assert(hist2.undo() && doc2.text() == "hello");
    assert(hist2.undo() && doc2.text().empty());
    std::println("现代: function 命令 + 对称 lambda 对，撤销语义与类版等效");

    std::println("自检通过");
}
