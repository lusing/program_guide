// json.cpp —— Boost.JSON（2021）：现代 JSON 库——DOM 与 SAX 双模、
// 零分配解析（parser + storage_ptr）、constexpr 序列化支持。
// 与 PropertyTree 的分野：JSON.JSON 是"专而快"，ptree 是"通用而慢"。
// 对应文档：docs/30-serialization.md
#include <boost/json.hpp>
#include <iostream>
#include <cstring>
#include <string>
#include <sstream>

namespace json = boost::json;

int main() {
    // 1) 解析成 DOM
    json::value v = json::parse(R"({
        "name": "ada",
        "age": 36,
        "tags": ["pioneer", "math"],
        "address": {"city": "London", "year": 1815}
    })");

    std::cout << "name = " << v.at("name").as_string() << '\n';
    std::cout << "age = " << v.at("age").as_int64() << '\n';
    std::cout << "tags 数 = " << v.at("tags").as_array().size() << '\n';
    std::cout << "city = " << v.at("address").at("city").as_string() << '\n';

    // 2) 构造（initializer_list 直观建树）
    json::value obj = {
        {"ok", true},
        {"items", {1, 2, 3}},
    };
    std::cout << "构造 = " << obj << '\n';

    // 3) 修改 DOM
    json::object& top = v.as_object();
    top["age"] = 37;
    top["extra"] = "added";
    std::cout << "age 改后 = " << v.at("age").as_int64()
              << " extra = " << v.at("extra").as_string() << '\n';

    // 4) 序列化
    std::cout << "序列化 = " << json::serialize(v).substr(0, 40) << "...\n";

    // 5) 错误处理：as_xxx 类型不符抛 system_error
    try {
        v.at("name").as_int64();
    } catch (const std::exception&) {
        std::cout << "字符串取 as_int64 被抓住\n";
    }

    // 6) SAX：流式处理大文件（不建整棵树）。
    //    注意：write() 要一次喂完整 JSON 文本，release 才不抛 incomplete——
    //    喂半截就 release 会抛 system_error（未捕获即 fail-fast，实测坑）
    json::parser p;
    p.reset();
    char const* chunk = R"({"streamed": true})";
    p.write(chunk, std::strlen(chunk));
    json::value sv = p.release();
    std::cout << "SAX 流式 = " << sv << '\n';

    std::cout << "自检通过\n";
    return 0;
}
