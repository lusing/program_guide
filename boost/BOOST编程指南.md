# Boost 编程指南（MSVC）

本文档配套可编译源码位于 [examples/](./examples/)。

## 1. 环境

- Boost：`G:\scoop\apps\boost\current`
- Visual C++：`G:\Program Files\Microsoft Visual Studio\18\Community\VC`

## 2. 构建方式

```powershell
cd G:\code\guide\boost
.\build.ps1 -All
```

## 3. 常用 Boost 模块示例

### 3.1 字符串算法（Boost.Algorithm）

源码：`examples/01_algorithm_string.cpp`

```cpp
#include <boost/algorithm/string.hpp>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string text = "Boost, C++, Library";
    boost::replace_all(text, " ", "");

    std::vector<std::string> parts;
    boost::split(parts, text, boost::is_any_of(","));

    std::cout << "count=" << parts.size() << '\n';
    std::cout << boost::join(parts, "|") << '\n';
    return 0;
}
```

### 3.2 可选值（Boost.Optional）

源码：`examples/02_optional.cpp`

```cpp
#include <boost/optional.hpp>
#include <iostream>

boost::optional<int> parse_positive(int value) {
    if (value > 0) return value;
    return boost::none;
}

int main() {
    auto ok = parse_positive(42);
    auto bad = parse_positive(-1);
    std::cout << (ok ? *ok : 0) << '\n';
    std::cout << (bad ? 1 : 0) << '\n';
    return 0;
}
```

### 3.3 变体类型（Boost.Variant）

源码：`examples/03_variant.cpp`

```cpp
#include <boost/variant.hpp>
#include <iostream>
#include <string>

struct Visitor : boost::static_visitor<> {
    Visitor() : boost::static_visitor<>() {}
    void operator()(int v) const { std::cout << "int=" << v << '\n'; }
    void operator()(const std::string& v) const { std::cout << "string=" << v << '\n'; }
};

int main() {
    boost::variant<int, std::string> value = 10;
    boost::apply_visitor(Visitor{}, value);
    value = std::string("boost");
    boost::apply_visitor(Visitor{}, value);
    return 0;
}
```

### 3.4 动态位集（Boost.DynamicBitset）

源码：`examples/04_dynamic_bitset.cpp`

```cpp
#include <boost/dynamic_bitset.hpp>
#include <iostream>

int main() {
    boost::dynamic_bitset<> flags(8);
    flags.set(1);
    flags.set(5);
    std::cout << flags << '\n';
    std::cout << "count=" << flags.count() << '\n';
    return 0;
}
```

### 3.5 JSON 配置（Boost.PropertyTree）

源码：`examples/05_property_tree_json.cpp`

```cpp
#include <boost/property_tree/json_parser.hpp>
#include <boost/property_tree/ptree.hpp>
#include <iostream>
#include <sstream>

int main() {
    std::stringstream ss(R"({"app":{"name":"guide","port":8080}})");
    boost::property_tree::ptree root;
    boost::property_tree::read_json(ss, root);
    std::cout << root.get<std::string>("app.name") << '\n';
    std::cout << root.get<int>("app.port") << '\n';
    return 0;
}
```

### 3.6 UUID（Boost.UUID）

源码：`examples/06_uuid.cpp`

```cpp
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <iostream>

int main() {
    boost::uuids::random_generator gen;
    boost::uuids::uuid id = gen();
    std::cout << id << '\n';
    return 0;
}
```

### 3.7 异步计时器（Boost.Asio）

源码：`examples/07_asio_timer.cpp`

```cpp
#include <boost/asio.hpp>
#include <chrono>
#include <iostream>

int main() {
    boost::asio::io_context io;
    boost::asio::steady_timer timer(io, std::chrono::milliseconds(5));
    timer.async_wait([](const boost::system::error_code& ec) {
        if (!ec) std::cout << "timer fired\n";
    });
    io.run();
    return 0;
}
```

### 3.8 多索引容器（Boost.MultiIndex）

源码：`examples/08_multi_index.cpp`

```cpp
#include <boost/multi_index/member.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index_container.hpp>
#include <iostream>
#include <string>

struct User {
    int id;
    std::string name;
};

int main() {
    using namespace boost::multi_index;
    using Users = multi_index_container<
        User,
        indexed_by<
            ordered_unique<member<User, int, &User::id>>,
            ordered_non_unique<member<User, std::string, &User::name>>
        >
    >;

    Users users;
    users.insert({1, "alice"});
    users.insert({2, "bob"});
    std::cout << "size=" << users.size() << '\n';
    return 0;
}
```

---

以上示例都通过 [build.ps1](./build.ps1) 在当前环境完成了编译验证。
