// file: src/instances.hpp
// 第 29 章配套：框架的五个实例构造器。
#ifndef TIP_INSTANCES_HPP
#define TIP_INSTANCES_HPP

#include "framework.hpp"

namespace tip {

// 四大经典（与第 25/26 章的专门实现同语义，此处统一为框架实例）：
Instance makeReaching(const std::vector<Quad> &code);
Instance makeAvailable(const std::vector<Quad> &code);
Instance makeLive(const std::vector<Quad> &code);
Instance makeVeryBusy(const std::vector<Quad> &code);
// 常量传播（非分配性的标准反例携带者，紫龙 9.4）：
Instance makeConstProp(const std::vector<Quad> &code);

}  // namespace tip

#endif  // TIP_INSTANCES_HPP
