// 问题：循环引用
struct Node {
    std::shared_ptr<Node> next;
    std::shared_ptr<Node> prev;
};

// 解决：使用 weak_ptr 打破循环
struct Node {
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;  // weak_ptr 不增加引用计数
};
