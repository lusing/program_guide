#pragma once
// 中介者：同事对象不再两两直连，全部经由中介者收发——网状耦合改星型。
#include <format>
#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

namespace dp {

// Mediator：聊天室——唯一的"枢纽"，成员表 + 消息日志。
class ChatRoom {
public:
    void join(std::string name) { members_.push_back(std::move(name)); }

    // 群发：from -> 所有其他成员；日志记一笔（含 "->" 行）
    void send(std::string_view from, std::string_view msg) {
        log_.push_back(std::format("{}->{}", from, msg));
    }

    [[nodiscard]] size_t log_size() const { return log_.size(); }
    [[nodiscard]] const std::vector<std::string>& log() const { return log_; }
    [[nodiscard]] size_t members() const { return members_.size(); }

private:
    std::vector<std::string> members_;
    std::vector<std::string> log_;
};

// Colleague：用户——只认识中介者，不认识任何其他用户。
struct User {
    std::string name;
    ChatRoom* room;                    // 中介者指针：同事的全部通信信道

    void say(std::string_view msg) const { room->send(name, msg); }
};

// ---- 现代线：信号槽——中介者退化为"广播表" ----
// 订阅即注册回调；发布即遍历回调。频道间零直接耦合。
class SignalHub {
public:
    using Slot = std::function<void(std::string_view, std::string_view)>;

    void subscribe(std::string who, Slot slot) {
        slots_.emplace_back(std::move(who), std::move(slot));
    }
    void publish(std::string_view from, std::string_view msg) const {
        for (const auto& [who, slot] : slots_)
            if (who != from) slot(from, msg);      // 不回声给自己
    }
    [[nodiscard]] size_t subscriber_count() const { return slots_.size(); }

private:
    std::vector<std::pair<std::string, Slot>> slots_;
};

}  // namespace dp
