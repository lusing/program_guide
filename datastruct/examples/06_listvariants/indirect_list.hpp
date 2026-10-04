#ifndef DS_INDIRECT_LIST_HPP
#define DS_INDIRECT_LIST_HPP

#include <algorithm>
#include <concepts>
#include <cstddef>
#include <span>
#include <utility>
#include <vector>

namespace ds {

// 间接表：表里不放数据本身，只放"指向数据的指针"。
// 重排表（sort）时只搬运指针，数据对象在内存中原地不动。
// 当每个元素又大又重时，搬指针与搬整条记录的代价天差地别。
template <std::copyable T>
class IndirectList {
public:
    using value_type = T;

    IndirectList() = default;

    explicit IndirectList(std::span<const T> src) {
        pointers_.reserve(src.size());
        bindings_.reserve(src.size());
        for (const T& item : src) {
            T* p = new T(item);
            pointers_.push_back(p);
            bindings_.push_back(Binding{p, item});  // 住址 ↔ 初始身份
        }
    }

    // 深拷贝：新表必须指向自己的新对象，不能与对方共享（否则双重释放）。
    IndirectList(const IndirectList& other) {
        pointers_.reserve(other.pointers_.size());
        for (T* p : other.pointers_) {
            pointers_.push_back(new T(*p));
        }
        bindings_.reserve(other.bindings_.size());
        for (const Binding& b : other.bindings_) {
            bindings_.push_back(Binding{translate_(other, b.address), b.initial});
        }
    }

    IndirectList(IndirectList&& other) noexcept
        : pointers_(std::move(other.pointers_)),
          bindings_(std::move(other.bindings_)) {
        other.pointers_.clear();
        other.bindings_.clear();
    }

    IndirectList& operator=(const IndirectList& other) {
        if (this != &other) {
            IndirectList tmp{other};
            swap(tmp);
        }
        return *this;
    }

    IndirectList& operator=(IndirectList&& other) noexcept {
        if (this != &other) {
            release_();
            pointers_ = std::move(other.pointers_);
            bindings_ = std::move(other.bindings_);
            other.pointers_.clear();
            other.bindings_.clear();
        }
        return *this;
    }

    ~IndirectList() { release_(); }

    [[nodiscard]] std::size_t size() const noexcept { return pointers_.size(); }
    [[nodiscard]] bool empty() const noexcept { return pointers_.empty(); }

    const T& at(std::size_t i) const { return *pointers_[i]; }

    // 当前第 i 个槽里装的是哪个对象。
    const T* pointer_at(std::size_t i) const { return pointers_[i]; }

    // 只对指针数组排序：被比较的是 *p（对象值），被交换的只是 p。
    void sort() {
        std::sort(pointers_.begin(), pointers_.end(),
                  [](const T* a, const T* b) { return *a < *b; });
    }

    // 初始绑定记录了每个对象"住址 ↔ 身份"的配对。排序只重排指针、
    // 从不改写对象，所以每个住址上的对象仍等于初始身份。
    [[nodiscard]] bool data_untouched() const {
        return std::all_of(bindings_.begin(), bindings_.end(),
                           [](const Binding& b) { return *b.address == b.initial; });
    }

    void swap(IndirectList& other) noexcept {
        pointers_.swap(other.pointers_);
        bindings_.swap(other.bindings_);
    }

private:
    // 绑定 = 对象地址 + 该对象的初始值副本（值随记录保存，
    // 不依赖外部数据是否还在）。
    struct Binding {
        T* address;
        T initial;
    };

    // 深拷贝时把"对方的旧地址"翻译成"我方的新地址"。
    T* translate_(const IndirectList& source, T* old_address) const {
        const auto it = std::find(source.pointers_.begin(),
                                  source.pointers_.end(), old_address);
        const std::size_t idx = static_cast<std::size_t>(
            it - source.pointers_.begin());
        return pointers_[idx];
    }

    void release_() {
        for (T* p : pointers_) {
            delete p;
        }
    }

    std::vector<T*> pointers_;
    std::vector<Binding> bindings_;
};

}  // namespace ds

#endif  // DS_INDIRECT_LIST_HPP
