#ifndef DS_HASH_OPEN_HPP
#define DS_HASH_OPEN_HPP

#include <cstddef>
#include <functional>
#include <optional>
#include <utility>
#include <vector>

namespace ds {

// 开放定址哈希表（线性探查）：没有链，所有元素住在一张槽数组里，
// 撞车就顺序看下一个槽。删除不能直接腾空 —— 那会截断探查链，
// 只能把槽标为"已删除"（墓碑）。
//
// 不变量：
//  1) 每个 active 键只住在从其散列位置出发、沿 +1 探查能遇到的第一个它自己；
//  2) get 沿探查链遇到 empty 即止（墓碑不是终点）；
//  3) active 槽数恒为 size_；rehash 只搬 active 槽，墓碑被丢弃。
template <class K, class V>
class OpenAddressHash {
    enum class State { empty, active, deleted };

    struct Slot {
        State state = State::empty;
        K key{};
        V value{};
    };

public:
    explicit OpenAddressHash(size_t capacity = 8) : slots_(capacity) {}

    void insert(const K& key, const V& value) {
        const size_t start = hash(key) % slots_.size();
        size_t first_tomb = npos;
        for (size_t step = 0; step < slots_.size(); ++step) {
            Slot& s = slots_[probe(start, step)];
            if (s.state == State::active && s.key == key) {
                s.value = value;  // upsert
                return;
            }
            if (s.state == State::deleted && first_tomb == npos) {
                first_tomb = probe(start, step);
            }
            if (s.state == State::empty) {
                const size_t pos = (first_tomb == npos) ? probe(start, step) : first_tomb;
                slots_[pos] = Slot{State::active, key, value};
                ++size_;
                grow_if_needed();
                return;
            }
        }
        // 整表无 empty（只有墓碑）：复用第一个墓碑
        slots_[first_tomb] = Slot{State::active, key, value};
        ++size_;
        grow_if_needed();
    }

    [[nodiscard]] std::optional<V> get(const K& key) const {
        const Slot* s = find_slot_const(key);
        if (s != nullptr && s->state == State::active) {
            return s->value;
        }
        return std::nullopt;
    }

    bool erase(const K& key) {
        Slot* s = find_slot(key);
        if (s == nullptr || s->state != State::active) {
            return false;
        }
        s->state = State::deleted;  // 留墓碑，不腾空
        --size_;
        return true;
    }

    [[nodiscard]] size_t size() const noexcept { return size_; }

    [[nodiscard]] double load_factor() const {
        // 口径：active 元素 / 容量（墓碑不算元素但仍占探查成本）。
        return static_cast<double>(size_) / static_cast<double>(slots_.size());
    }

    size_t capacity() const noexcept { return slots_.size(); }

    // 重建到 new_cap：active 槽重新插入全新表，墓碑清空。
    void rehash(size_t new_cap) {
        if (new_cap == 0) {
            new_cap = 1;
        }
        std::vector<Slot> old = std::move(slots_);
        slots_.assign(new_cap, Slot{});
        size_ = 0;
        rehashing_ = true;  // 重建期间关闭自动扩容，否则中途再次触发 rehash
        for (const Slot& s : old) {
            if (s.state == State::active) {
                insert(s.key, s.value);
            }
        }
        rehashing_ = false;
    }

private:
    static constexpr size_t npos = static_cast<size_t>(-1);

    [[nodiscard]] size_t hash(const K& key) const {
        return hasher_(key);
    }

    [[nodiscard]] size_t probe(size_t start, size_t step) const {
        return (start + step) % slots_.size();
    }

    // 沿探查链找 key；遇 empty 停止。返回命中槽（供写）或 nullptr。
    [[nodiscard]] Slot* find_slot(const K& key) {
        const Slot* s = find_slot_const(key);
        return const_cast<Slot*>(s);
    }

    [[nodiscard]] const Slot* find_slot_const(const K& key) const {
        const size_t start = hash(key) % slots_.size();
        for (size_t step = 0; step < slots_.size(); ++step) {
            const Slot& s = slots_[probe(start, step)];
            if (s.state == State::empty) {
                return nullptr;
            }
            if (s.state == State::active && s.key == key) {
                return &s;
            }
        }
        return nullptr;
    }

    // active 装填超过 0.7 就翻倍重建，把线性探查的期望链长压住。
    void grow_if_needed() {
        if (!rehashing_ && load_factor() > 0.7) {
            rehash(slots_.size() * 2 + 1);
        }
    }

    std::vector<Slot> slots_;
    size_t size_ = 0;
    bool rehashing_ = false;
    std::hash<K> hasher_;
};

}  // namespace ds

#endif  // DS_HASH_OPEN_HPP
