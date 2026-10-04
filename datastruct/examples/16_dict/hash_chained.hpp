#ifndef DS_HASH_CHAINED_HPP
#define DS_HASH_CHAINED_HPP

#include <cstddef>
#include <forward_list>
#include <functional>
#include <optional>
#include <utility>
#include <vector>

namespace ds {

// 链地址哈希表：桶数组 + 每个桶挂一条不带头节点的链。
//
// 不变量：
//  1) 每个键恰好存于 hash(key) % 桶数 这一个桶中，且桶内无重复键；
//  2) size_ 恒等于各桶节点数之和；
//  3) rehash 只搬节点、不改键值，搬完前后可观察内容完全相同。
template <class K, class V>
class ChainedHash {
public:
    explicit ChainedHash(size_t buckets = 16)
        : table_data_(buckets), buckets_(buckets) {}

    void insert(const K& key, const V& value) {
        auto& chain = table_data_[bucket_of(key)];
        for (auto& node : chain) {
            if (node.first == key) {
                node.second = value;  // upsert
                return;
            }
        }
        chain.emplace_front(key, value);
        ++size_;
    }

    [[nodiscard]] std::optional<V> get(const K& key) const {
        for (const auto& node : table_data_[bucket_of(key)]) {
            if (node.first == key) {
                return node.second;
            }
        }
        return std::nullopt;
    }

    bool erase(const K& key) {
        auto& chain = table_data_[bucket_of(key)];
        auto before = chain.before_begin();
        for (auto it = chain.begin(); it != chain.end(); ++it, ++before) {
            if (it->first == key) {
                chain.erase_after(before);
                --size_;
                return true;
            }
        }
        return false;
    }

    [[nodiscard]] size_t size() const noexcept { return size_; }

    [[nodiscard]] double load_factor() const {
        return static_cast<double>(size_) / static_cast<double>(buckets_);
    }

    size_t bucket_count() const noexcept { return buckets_; }

    // 重建到 new_buckets 个桶：旧节点全部重新取模挂位。
    void rehash(size_t new_buckets) {
        if (new_buckets == 0) {
            new_buckets = 1;
        }
        std::vector<std::forward_list<std::pair<K, V>>> rebuilt(new_buckets);
        for (auto& chain : table_data_) {
            while (!chain.empty()) {
                auto node_it = chain.begin();
                const size_t b = compressed_hash(node_it->first) % new_buckets;
                rebuilt[b].splice_after(rebuilt[b].before_begin(), chain,
                                        chain.before_begin());
            }
        }
        table_data_ = std::move(rebuilt);
        buckets_ = new_buckets;
    }

private:
    [[nodiscard]] size_t compressed_hash(const K& key) const {
        return hasher_(key);
    }

    [[nodiscard]] size_t bucket_of(const K& key) const {
        return compressed_hash(key) % buckets_;
    }

    std::vector<std::forward_list<std::pair<K, V>>> table_data_;
    size_t buckets_;
    size_t size_ = 0;
    std::hash<K> hasher_;
};

}  // namespace ds

#endif  // DS_HASH_CHAINED_HPP
