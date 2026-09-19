// beast.cpp —— Boost.Beast（2016）：asio 之上的 HTTP/WebSocket 库。
// 本例在本机回环地址跑一个完整 HTTP 请求-响应（同进程内服务端+客户端）。
// 对应文档：docs/28-network.md
#include <boost/asio.hpp>
#include <boost/beast.hpp>
#include <iostream>
#include <string>
#include <thread>

namespace beast = boost::beast;
namespace http  = beast::http;
namespace asio  = boost::asio;
using tcp = asio::ip::tcp;

// 服务端：接受一个连接，回一个固定响应
void serve_one(tcp::acceptor& acceptor) {
    tcp::socket sock(acceptor.get_executor());
    acceptor.accept(sock);

    beast::flat_buffer buf;
    http::request<http::string_body> req;
    http::read(sock, buf, req);

    http::response<http::string_body> res{http::status::ok, req.version()};
    res.set(http::field::server, "Beast Tutorial");
    res.set(http::field::content_type, "text/plain");
    res.body() = "你好，来自 Beast 的响应：" + std::string(req.target());
    res.prepare_payload();
    http::write(sock, res);
}

int main() {
    asio::io_context io;
    tcp::acceptor acceptor(io, {asio::ip::make_address("127.0.0.1"), 0});  // 随机端口
    auto port = acceptor.local_endpoint().port();

    // 服务端在另一线程跑
    std::thread server([&] { serve_one(acceptor); });

    // 客户端：连、发 GET、读响应
    tcp::socket client(io);
    client.connect({asio::ip::make_address("127.0.0.1"), port});
    http::request<http::empty_body> req{http::verb::get, "/hello", 11};
    req.set(http::field::host, "localhost");
    http::write(client, req);

    beast::flat_buffer buf;
    http::response<http::string_body> res;
    http::read(client, buf, res);

    std::cout << "状态 = " << res.result_int() << '\n';
    std::cout << "Server 头 = " << res[http::field::server] << '\n';
    std::cout << "响应体 = " << res.body() << '\n';

    server.join();
    std::cout << "自检通过\n";
    return 0;
}
