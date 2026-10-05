// file: src/memmodel.hpp
// 第 18 章补：内存模型——值的二分法（鲸书 §5.4.3）。
// unambiguous：编译器能把它孤立到唯一内存位置 ⇒ 可长住寄存器；
// ambiguous：可能被间接引用（指针、数组元素、身份不明的对象）⇒ 每次定义
// 都要考虑回落内存。间接写 *p = x 的"受害名单"= pointees[p] 全体。
#ifndef TIP_MEMMODEL_HPP
#define TIP_MEMMODEL_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

struct MemModelReport {
    std::set<std::string> unambiguous;
    std::set<std::string> ambiguous;
    std::vector<std::string> notes;   // 每次间接写的受害名单流水
};

// names：标量名单；pointees：每个指针可能指向的名字集合（别名分析的产物，
// 第 54 章）；indirectStores：形如 "*p = x" 的指针名序列。
MemModelReport memoryModel(const std::vector<std::string> &names,
                           const std::map<std::string, std::set<std::string>> &pointees,
                           const std::vector<std::string> &indirectStores);

}  // namespace tip

#endif  // TIP_MEMMODEL_HPP
