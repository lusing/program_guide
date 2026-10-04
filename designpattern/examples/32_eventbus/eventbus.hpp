#pragma once
// 32 事件总线：观察者模式的解耦极致——发布者与订阅者互不知名，只共享话题字符串。
// 订阅返回可退订的 id；内部按 topic 分桶，桶内是 (id, handler) 列表。
#include <cstddef>
#include <functional>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace dp {

struct Evt {
    std::string topic;
    std::string payload;
};

class EventBus {
public:
    using Handler = std::function<void(const Evt&)>;

    // 订阅：返回全局单调递增的 id，退订凭它。同一 topic 可挂任意多个 handler。
    std::size_t subscribe(std::string topic, Handler h) {
        const std::size_t id = next_id_++;
        topics_[std::move(topic)].push_back({id, std::move(h)});
        return id;
    }

    // 退订：找到持有该 id 的桶并摘除。返回是否真的退掉了（重复退订 = false）。
    bool unsubscribe(std::size_t id) {
        for (auto& [topic, list] : topics_) {
            for (auto it = list.begin(); it != list.end(); ++it) {
                if (it->first == id) {
                    list.erase(it);
                    return true;
                }
            }
        }
        return false;
    }

    // 发布：按 topic 定位桶，逐个通知。无人订阅的话题静默通过。
    void publish(const Evt& e) {
        auto it = topics_.find(e.topic);
        if (it == topics_.end()) return;
        for (const auto& [id, h] : it->second) h(e);   // 桶内顺序 = 订阅顺序
    }

private:
    std::unordered_map<std::string, std::vector<std::pair<std::size_t, Handler>>> topics_;
    std::size_t next_id_ = 1;
};

}  // namespace dp
