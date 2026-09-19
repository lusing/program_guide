// url.cpp —— Boost.URL（2022）：RFC 3986 的完整解析与构造。
// 对应文档：docs/28-network.md
#include <boost/url.hpp>
#include <iostream>
#include <string>

namespace urls = boost::urls;

int main() {
    // 1) 解析：URL 的每个部件都有名字
    urls::url_view u = urls::parse_uri(
        "https://user:pw@codeberg.org:443/lusing/programming?tab=activity#README").value();

    std::cout << "scheme = " << u.scheme() << '\n';
    std::cout << "host = " << u.host() << '\n';
    std::cout << "port = " << u.port() << '\n';
    std::cout << "path = " << u.encoded_path() << '\n';
    std::cout << "片段 = " << u.fragment() << '\n';

    // 2) 查询参数：键值对视图
    for (auto param : u.params()) {
        std::cout << "参数 " << param.key << " = " << param.value << '\n';
    }

    // 3) 构造：从零件拼 URL（百分比编码自动处理）
    urls::url built;
    built.set_scheme("https");
    built.set_host("example.com");
    built.set_port("8443");
    built.set_path("/a path/中文");
    built.params().append({"q", "hello world"});      // 参数用 params().append
    std::cout << "构造 = " << built << '\n';

    // 4) 相对解析：成员函数形态（base.resolve(ref) 原地吸收相对引用）
    urls::url base = urls::parse_uri("https://example.com/docs/").value();
    urls::url_view ref = urls::parse_relative_ref("../api").value();
    base.resolve(ref);
    std::cout << "相对解析 = " << base << '\n';

    std::cout << "自检通过\n";
    return 0;
}
