// file: src/table.hpp
// 第 59 章：开放定址散列表（匠书 §20）——线性探测、墓碑、装填因子、
// 扩容三状态机。替代第 58 章 GET_GLOBAL 背后的 std::map。
#ifndef TIP_TABLE_HPP
#define TIP_TABLE_HPP

#include <cstddef>
#include <vector>

#include "value.hpp"

namespace tip {

// 条目的键用 nil/false 两个单例当哨兵（§20.3.1）：
//   key == nil  → 空槽（从未用过）
//   key == false→ 墓碑（用过已删——探测链的"连接件"，不能真删）
struct Entry {
    Value key = nilVal();
    Value value = nilVal();
};

class Table {
  public:
    Table() = default;

    // 写入（新键或改值）。键须为 ObjString。
    bool set(ObjString *key, Value value);
    // 查找：命中返回 true 并写 value；找不到返回 false。
    bool get(const ObjString *key, Value *value = nullptr) const;
    // 删除：成功留墓碑返回 true；本来不在返回 false。
    bool deleteKey(ObjString *key);

    size_t count() const { return count_; }        // 活条目数
    size_t tombstones() const { return tomb_; }    // 墓碑数（扩容时清零）
    size_t capacity() const { return entries_.size(); }

    // 把 src 的活条目搬进来（§20.5 intern 池搬家用）
    void addAll(Table &src);

  private:
    // 找到 key 的槽或可插入的槽（墓碑可复用——首个墓碑记在 firstTomb）
    Entry *findEntry(const ObjString *key);
    const Entry *findEntry(const ObjString *key) const;
    void adjustCapacity(size_t newCap);  // 扩容：重散列、顺带清墓碑

    std::vector<Entry> entries_;  // capacity 为 2 的幂（探测的模运算前提）
    size_t count_ = 0;
    size_t tomb_ = 0;
};

// 驻留池：相等文本 → 同一指针（§19.3）
class InternTable {
  public:
    ObjString *intern(const std::string &text);

    size_t size() const { return table_.count(); }

  private:
    Table table_;  // 键：已驻留串；值：objVal(串)
    std::vector<std::unique_ptr<ObjString>> owned_;  // 所有权（池即根集）
};

}  // namespace tip

#endif  // TIP_TABLE_HPP
