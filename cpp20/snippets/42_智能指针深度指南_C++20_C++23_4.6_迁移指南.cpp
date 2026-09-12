// 问题代码：可能导致内存泄漏
class Publisher;
class Subscriber {
    std::shared_ptr<Publisher> pub;  // 循环引用！
};

// 修正代码
class Subscriber {
    std::weak_ptr<Publisher> pub;  // 使用 weak_ptr
};
