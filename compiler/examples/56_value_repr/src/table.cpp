// file: src/table.cpp
#include "table.hpp"

namespace tip {

// 散列取模：容量为 2 的幂时 hash & (cap-1) ≡ hash % cap（位与替模）
static size_t slotOf(uint32_t hash, size_t cap) { return hash & (cap - 1); }

Entry *Table::findEntry(const ObjString *key) {
    if (entries_.empty()) return nullptr;
    size_t i = slotOf(key->hash, entries_.size());
    Entry *firstTomb = nullptr;
    for (;;) {
        Entry &e = entries_[i];
        if (e.key == nilVal()) {
            // 真空槽：链到此断。插入用首个墓碑（回收），查找用本槽。
            return firstTomb ? firstTomb : &e;
        }
        if (e.key == boolVal(false)) {  // 墓碑：记下、继续走链
            if (!firstTomb) firstTomb = &e;
        } else {
            auto *k = dynamic_cast<ObjString *>(asObj(e.key));
            if (k && k->hash == key->hash && k->text == key->text)
                return &e;  // 命中（先比散列再比文本——快慢两道）
        }
        i = (i + 1) & (entries_.size() - 1);  // 线性探测（环绕）
    }
}

const Entry *Table::findEntry(const ObjString *key) const {
    return const_cast<Table *>(this)->findEntry(key);
}

bool Table::set(ObjString *key, Value value) {
    // 装填因子：活条目 + 墓碑一起压容量（墓碑同样占槽、同样伤探测）
    if ((count_ + tomb_ + 1) * 4 > entries_.size() * 3)
        adjustCapacity(entries_.empty() ? 8 : entries_.size() * 2);
    Entry *e = findEntry(key);
    if (e->key == boolVal(false)) {
        ++tomb_;   // 复用墓碑：墓碑转正
    } else if (e->key == nilVal()) {
        ++count_;  // 真空槽：新条目
    }               // 命中旧键：只改值
    e->key = objVal(key);
    e->value = value;
    return true;
}

bool Table::get(const ObjString *key, Value *value) const {
    if (entries_.empty()) return false;
    const Entry *e = findEntry(key);
    if (e->key == nilVal() || e->key == boolVal(false)) return false;
    if (value) *value = e->value;
    return true;
}

bool Table::deleteKey(ObjString *key) {
    if (entries_.empty()) return false;
    Entry *e = findEntry(key);
    if (e->key == nilVal() || e->key == boolVal(false)) return false;
    e->key = boolVal(false);  // 墓碑：探测链的连接件（不能真空槽化）
    e->value = nilVal();
    --count_;
    ++tomb_;
    return true;
}

void Table::adjustCapacity(size_t newCap) {
    std::vector<Entry> old = std::move(entries_);
    entries_.assign(newCap, Entry{});  // 全新空表（nil 键哨兵）
    tomb_ = 0;                         // 墓碑在搬家时全部蒸发
    // 活条目重散列入新表（墓碑不搬——它只是旧探测链的连接件）
    for (const Entry &e : old) {
        if (e.key == nilVal() || e.key == boolVal(false)) continue;
        ObjString *k = dynamic_cast<ObjString *>(asObj(e.key));
        Entry *ne = findEntry(k);
        ne->key = e.key;
        ne->value = e.value;
    }
    // count_ 不变（活条目一个不少）
}

void Table::addAll(Table &src) {
    for (const Entry &e : src.entries_) {
        if (e.key == nilVal() || e.key == boolVal(false)) continue;
        ObjString *k = dynamic_cast<ObjString *>(asObj(e.key));
        set(k, e.value);
    }
}

// ---------- 驻留池 ----------
ObjString *InternTable::intern(const std::string &text) {
    ObjString probe;
    probe.text = text;
    probe.hash = fnv1a(text);
    Value v;
    if (table_.get(&probe, &v)) return asObj(v) ? static_cast<ObjString *>(asObj(v)) : nullptr;
    auto s = std::make_unique<ObjString>();
    s->text = probe.text;
    s->hash = probe.hash;
    ObjString *raw = s.get();
    owned_.push_back(std::move(s));
    table_.set(raw, objVal(raw));
    return raw;
}

}  // namespace tip
