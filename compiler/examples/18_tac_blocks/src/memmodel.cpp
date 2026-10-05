// file: src/memmodel.cpp
// 第 18 章补：内存模型的实现（鲸书 §5.4.3）。
#include "memmodel.hpp"

namespace tip {

MemModelReport memoryModel(const std::vector<std::string> &names,
                           const std::map<std::string, std::set<std::string>> &pointees,
                           const std::vector<std::string> &indirectStores) {
    MemModelReport r;
    for (const auto &n : names) r.unambiguous.insert(n);
    for (const auto &p : indirectStores) {
        auto it = pointees.find(p);
        std::string victims = "*";
        victims += p;
        victims += " 波及:";
        if (it == pointees.end() || it->second.empty()) {
            // 指针去向不明：保守口径——全体标量都是潜在受害者
            for (const auto &n : names) {
                if (n == p) continue;
                r.ambiguous.insert(n);
                r.unambiguous.erase(n);
                victims += " " + n + ",";
            }
            r.notes.push_back(victims + "（去向不明：全员）");
            continue;
        }
        for (const auto &n : it->second) {
            r.ambiguous.insert(n);
            r.unambiguous.erase(n);
            victims += " " + n + ",";
        }
        r.notes.push_back(victims.substr(0, victims.size() - 1));
    }
    return r;
}

}  // namespace tip
