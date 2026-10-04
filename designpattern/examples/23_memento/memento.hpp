#pragma once
// 备忘录：在不破坏封装的前提下捕获对象状态，需要时回滚。
#include <string>
#include <string_view>
#include <vector>

namespace dp {

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

}  // namespace dp
