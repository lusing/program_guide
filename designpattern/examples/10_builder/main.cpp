// 10 建造者。
#include <cassert>
#include <print>
#include <stdexcept>

#include "builder.hpp"

int main() {
    using namespace dp;

    // ---- 链式组装 + 收尾校验 ----
    auto req = RequestBuilder{}
                   .method("POST")
                   .url("/api/orders")
                   .header("Content-Type", "application/json")
                   .header("X-Trace", "t-1")
                   .body(R"({"item":1})")
                   .build();
    assert(req.method == "POST" && req.url == "/api/orders");
    assert(req.headers.size() == 2);
    assert(req.body == R"({"item":1})");
    std::println("建造者: {} {} headers={} body={}", req.method, req.url,
                 req.headers.size(), req.body);

    // ---- 缺必填项在 build() 收尾时才报：错误集中、构造细节零暴露 ----
    bool threw = false;
    try {
        auto bad = RequestBuilder{}.method("GET").build();   // 缺 url
    } catch (const std::invalid_argument& e) {
        threw = true;
        std::println("校验: build 拒绝 -> {}", e.what());
    }
    assert(threw);

    // ---- Director 固定剧本：同一请求处处一致 ----
    auto a = construct_get_index();
    auto b = construct_get_index();
    assert(a.method == "GET" && a.url == b.url && a.headers.size() == 1);
    std::println("Director: {} {} 固定产出", a.method, a.url);

    // ---- 现代对照：designated initializers 一行造简单请求 ----
    HttpRequest simple{
        .method = "GET",
        .url = "/health",
        .body = "",
        .headers = {},
    };
    assert(simple.method == "GET" && simple.url == "/health");
    std::println("现代: {} {} 一步到位（无需 builder）", simple.method,
                 simple.url);

    std::println("自检通过");
}
