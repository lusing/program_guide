#include <memory>

// C++23 扩展：支持数组类型
auto p = std::make_shared_for_overwrite<int[]>(100);
p[0] = 1;
p[99] = 100;
