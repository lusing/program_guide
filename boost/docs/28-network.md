# 28 · 网络编程：asio / beast / url（+ mysql / redis / mqtt5 简介）

> 对应示例：`examples/28_network/`（3 个例程）

asio 是 Boost 对 C++ 生态最大的单件贡献之一——**C++ 异步 IO 的事实标准**二十年，C++26 `std::execution` 的精神源头。Beast 在它之上盖了 HTTP/WebSocket，URL 补上了解析层。三个"网络客户端"库（mysql/redis/mqtt5）需要活服务器，按既定策略给简介不进验证。

## 28.1 Boost.Asio（2005）：异步 IO 的地基

四个核心概念一例打尽：**io_context**（事件循环）、**async_wait + 回调**、**跨线程 run**、**work_guard**（防空转退出）：

```cpp
asio::io_context io;
asio::steady_timer t(io, 20ms);
t.async_wait([](auto ec) { ... });
io.run();                        // 阻塞直到没有工作
auto guard = asio::make_work_guard(io);   // 有任务才让 run 活着
asio::post(io, task);           // 向事件循环投递任务
```

运行输出（`asio.cpp`）：

```text
同步定时器到点
异步回调触发? 1
跨线程事件循环? 1
post 的任务被执行
自检通过
```

**毕业档案**：**平行共存**——`std::execution`（C++26，P2300）的执行模型思想直通 asio（作者 Chris Kohlhoff 深度参与提案），但 asio 的 socket/timer 体系本身没有 std 对应，**未来很多年它仍是网络的答案**。⭐ 大法器：strand（无锁串行化）、协程集成（16 章 cobalt）、buffer 家族、unix domain socket、SSL。

## 28.2 Boost.Beast（2016）：HTTP 与 WebSocket

asio 之上的协议层——例程在**本机回环地址跑了一个完整的 HTTP 请求-响应**（服务端与客户端同进程协作）：

```cpp
// 服务端：accept → http::read → 构造响应 → http::write
http::response<http::string_body> res{http::status::ok, 11};
res.body() = "你好，来自 Beast 的响应：" + std::string(req.target());
// 客户端：connect → http::write(req) → http::read(res)
```

运行输出（`beast.cpp`）：

```text
状态 = 200
Server 头 = Beast Tutorial
响应体 = 你好，来自 Beast 的响应：/hello
自检通过
```

HTTP/1.1 全量（chunked、keep-alive、文件体）、WebSocket 双向、基于 asio 的同步/异步/协程三种写法。⭐ C++ 网络服务的标准件（游戏服务器、API 网关的主力选择）。

## 28.3 Boost.URL（2022）：RFC 3986 完整实现

```cpp
urls::url_view u = urls::parse_uri("https://user:pw@host:443/p?tab=activity#README").value();
u.scheme(); u.host(); u.port(); u.encoded_path(); u.fragment();
u.params();                                    // 查询参数键值对
urls::url built; built.set_host("example.com")...;  // 构造（自动百分比编码）
base.resolve(ref);                             // 相对引用解析
```

运行输出（`url.cpp`）：

```text
scheme = https
host = codeberg.org
port = 443
path = /lusing/programming
片段 = README
参数 tab = activity
构造 = https://example.com:8443/a%20path/%E4%B8%AD%E6%96%87?q=hello+world
相对解析 = https://example.com/api
自检通过
```

解析零分配（`url_view` 指向原串）、百分号编码自动处理、RFC 3986 语义完整。⭐ Web/API 开发的地基件，std 无对应。

> 实测坑：`set_port` 吃字符串（`"8443"` 不吃 `8443`）；加查询参数是 `params().append({k,v})`（没有 `set_query_param`）；相对解析是**成员函数** `base.resolve(ref)`（原地吸收），不是自由函数二参版。

## 28.4 网络客户端三兄弟（简介，未纳入验证）

**Boost.MySQL / Boost.Redis / Boost.MQTT5**（2022-2024，三个新生代库）分别实现 MySQL 协议、RESP（Redis）、MQTT 5.0——全部构建在 asio 之上，全部需要活服务器才能验证。核心形态一览：

```cpp
// MySQL：asio 上的异步查询
boost::mysql::tcp_ssl_connection conn(ctx);
conn.connect(endpoint, params);          // 之后 execute("SELECT ...") / async_*
// Redis：RESP 协议的 C++ 化
boost::redis::connection conn; conn.execute(request, response);
// MQTT5：发布订阅
mqtt::async_client client("tcp://broker:1883", client_id);
```

三者共性：基于 asio 执行器、支持同步/异步/协程三形态、仅头文件或轻链接。等到你真要在 C++ 里连这三种服务时，它们是无第三方依赖（libmysqlclient/hiredis 之外）的原生选择。

---


> 上一章：[27 · 古典元编程](27-classic-tmp.md) ｜ 下一章：[29 · 进程与系统](29-process-system.md) ｜ 返回：[README](../README.md)
