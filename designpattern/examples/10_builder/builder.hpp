#pragma once
// 建造者：多参数、多不变量的对象分步组装。
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace dp {

struct HttpRequest {
    std::string method;
    std::string url;
    std::string body;
    std::vector<std::pair<std::string, std::string>> headers;
};

class RequestBuilder {
public:
    // 链式设置返回 RequestBuilder&&（把 *this 当右值转发），让整条链
    // 保持右值属性；build() 用 && 限定——只能在右值上收尾，防止
    // "组装一半的 builder 被误当完成品再用"。
    RequestBuilder&& method(std::string m) {
        req_.method = std::move(m);
        return std::move(*this);
    }
    RequestBuilder&& url(std::string u) {
        req_.url = std::move(u);
        return std::move(*this);
    }
    RequestBuilder&& header(std::string k, std::string v) {
        req_.headers.emplace_back(std::move(k), std::move(v));
        return std::move(*this);
    }
    RequestBuilder&& body(std::string b) {
        req_.body = std::move(b);
        return std::move(*this);
    }

    HttpRequest build() && {
        // 不变量校验集中在这里：缺 method/url 当场报，调用方改不了内部状态
        if (req_.method.empty() || req_.url.empty())
            throw std::invalid_argument("method/url 必填");
        return std::move(req_);
    }

private:
    HttpRequest req_;
};

// Director：固定"剧本"，把步骤顺序固化——这是建造者区别于链式调用器的关键。
inline HttpRequest construct_get_index() {
    return RequestBuilder{}
        .method("GET")
        .url("/index.html")
        .header("Accept", "text/html")
        .build();
}

}  // namespace dp
