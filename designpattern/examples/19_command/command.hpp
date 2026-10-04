#pragma once
// 命令：把"一次操作"封装成对象——可排队、可撤销、可记账。
#include <format>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace dp {

// Receiver：真正的执行者，命令的 undo 依赖它的原语。
class Document {
public:
    void insert(size_t pos, std::string_view s) {
        if (pos > text_.size()) pos = text_.size();
        text_.insert(pos, s);
    }
    void erase(size_t pos, size_t n) {
        if (pos >= text_.size()) return;
        text_.erase(pos, std::min(n, text_.size() - pos));
    }
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

// History：宏命令容器 + 撤销栈。
class History {
public:
    void push(std::unique_ptr<Command> c) {
        c->execute();
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

// ---- 现代线：std::function 命令——对称 lambda 对，undo 闭包捕获 ----
struct FnCommand final : Command {
    std::function<void()> do_, undo_;
    void execute() override { do_(); }
    void undo() override { undo_(); }
};

}  // namespace dp
