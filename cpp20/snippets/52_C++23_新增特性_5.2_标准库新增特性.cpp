#include <span>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};
std::span s = v;

// C++23 新增方法
s.first(3);   // 前3个元素
s.last(2);    // 后2个元素
s.subspan(1, 3);  // 从索引1开始的3个元素
