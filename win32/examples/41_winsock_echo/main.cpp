// 41_winsock_echo —— 第 33 章：Winsock TCP/UDP 回显，select 多路复用
// 双模式：无参数 = 服务器（TCP+UDP 同端口 5150，select 循环伺候多连接）；
//         -c = 客户端（TCP 三条消息回显 + shutdown 半关闭 + UDP 两条数据报回显）
// 验证：后台起服务器，跑 -c 看全链路输出，最后 taskkill 收服务器。
#include <winsock2.h>              // ★ 必须在一切 windows.h 之前（33.2）
#include <ws2tcpip.h>              // getaddrinfo / inet_ntop
#include <stdio.h>
#pragma comment(lib, "ws2_32.lib")

static constexpr const char* PORT = "5150";
static constexpr int MAX_CLIENTS = 8;

// send 可能部分发送：循环到发完为止（33.5）
static int SendAll(SOCKET s, const char* buf, int len) {
    int total = 0;
    while (total < len) {
        int n = send(s, buf + total, len - total, 0);
        if (n == SOCKET_ERROR) return SOCKET_ERROR;
        total += n;
    }
    return total;
}

// ============ 服务器：TCP 监听 + UDP + 已接客户端，一个 select 循环 ============
static int RunServer() {
    printf("=== Winsock 回显服务器：TCP + UDP 双协议，端口 %s ===\n", PORT);

    // TCP：getaddrinfo 替我们填 sockaddr（AI_PASSIVE = bind 所有网卡）
    struct addrinfo hints = {}, *res = nullptr;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;
    if (getaddrinfo(nullptr, PORT, &hints, &res) != 0) { printf("getaddrinfo 失败\n"); return 1; }

    SOCKET listener = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (listener == INVALID_SOCKET) { printf("socket 失败 %d\n", WSAGetLastError()); return 1; }
    if (bind(listener, res->ai_addr, (int)res->ai_addrlen) == SOCKET_ERROR) {
        printf("TCP bind 失败 %d（端口被占？）\n", WSAGetLastError()); return 1;
    }
    if (listen(listener, SOMAXCONN) == SOCKET_ERROR) { printf("listen 失败 %d\n", WSAGetLastError()); return 1; }
    freeaddrinfo(res);
    printf("TCP 监听就绪（socket/bind/listen 三步完成）\n");

    // UDP：同端口再 bind 一个数据报 socket
    struct addrinfo uh = {}, *ures = nullptr;
    uh.ai_family = AF_INET; uh.ai_socktype = SOCK_DGRAM; uh.ai_protocol = IPPROTO_UDP;
    uh.ai_flags = AI_PASSIVE;
    if (getaddrinfo(nullptr, PORT, &uh, &ures) != 0) { printf("getaddrinfo(UDP) 失败\n"); return 1; }
    SOCKET udp = socket(ures->ai_family, ures->ai_socktype, ures->ai_protocol);
    if (bind(udp, ures->ai_addr, (int)ures->ai_addrlen) == SOCKET_ERROR) {
        printf("UDP bind 失败 %d\n", WSAGetLastError()); return 1;
    }
    freeaddrinfo(ures);
    printf("UDP 数据报就绪。Ctrl+C 退出；建议另开终端跑 \"41_winsock_echo -c\"\n\n");

    SOCKET clients[MAX_CLIENTS] = {};
    int nClients = 0;

    while (true) {
        fd_set readfds;                          // select 每轮重建集合（入出参复用）
        FD_ZERO(&readfds);
        FD_SET(listener, &readfds);
        FD_SET(udp, &readfds);
        for (int i = 0; i < nClients; ++i) FD_SET(clients[i], &readfds);

        struct timeval tv = { 1, 0 };            // 最多等 1 秒，回圈打印不卡死
        int ready = select(0, &readfds, nullptr, nullptr, &tv);   // 首参 Windows 无意义
        if (ready == SOCKET_ERROR) { printf("select 失败 %d\n", WSAGetLastError()); break; }
        if (ready == 0) continue;                // 超时空转，继续盯

        // ① 新 TCP 连接
        if (FD_ISSET(listener, &readfds)) {
            struct sockaddr_in peer = {}; int peerLen = sizeof(peer);
            SOCKET c = accept(listener, (sockaddr*)&peer, &peerLen);
            if (c != INVALID_SOCKET) {
                char ip[64]; inet_ntop(AF_INET, &peer.sin_addr, ip, sizeof(ip));
                if (nClients < MAX_CLIENTS) {
                    clients[nClients++] = c;
                    printf("[TCP] 接入 %s:%d（在线 %d）\n", ip, ntohs(peer.sin_port), nClients);
                } else {
                    printf("[TCP] %s 接入但客户端满，拒接\n", ip);
                    closesocket(c);
                }
            }
        }

        // ② UDP 数据报：recvfrom 原路退回
        if (FD_ISSET(udp, &readfds)) {
            char buf[512];
            struct sockaddr_in from = {}; int fromLen = sizeof(from);
            int n = recvfrom(udp, buf, sizeof(buf), 0, (sockaddr*)&from, &fromLen);
            if (n > 0) {
                int m = sendto(udp, buf, n, 0, (sockaddr*)&from, fromLen);
                printf("[UDP] 收 %d 字节，退回 %d 字节\n", n, m);
            }
        }

        // ③ 已接客户端：可读则回显；recv=0 表示对端优雅关闭
        for (int i = 0; i < nClients; ) {
            if (!FD_ISSET(clients[i], &readfds)) { ++i; continue; }
            char buf[512];
            int n = recv(clients[i], buf, sizeof(buf), 0);
            if (n > 0) {
                int m = SendAll(clients[i], buf, n);
                printf("[TCP] 收 %d 字节，回显 %d 字节\n", n, m);
                ++i;
            } else if (n == 0) {
                closesocket(clients[i]);
                printf("[TCP] 对端优雅关闭（recv = 0），收线\n");
                for (int j = i; j + 1 < nClients; ++j) clients[j] = clients[j + 1];
                --nClients;
            } else {
                printf("[TCP] recv 错误 %d，收线\n", WSAGetLastError());
                closesocket(clients[i]);
                for (int j = i; j + 1 < nClients; ++j) clients[j] = clients[j + 1];
                --nClients;
            }
        }
    }
    return 0;
}

// ============ 客户端：TCP 三条 + shutdown 半关闭，UDP 两条 ============
static int RunClient() {
    printf("=== Winsock 客户端：TCP 3 条消息 + 半关闭握手，UDP 2 条数据报 ===\n");

    // TCP 连接：getaddrinfo 返回链表，逐个试到连上（33.4）
    struct addrinfo hints = {}, *res = nullptr;
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    if (getaddrinfo("127.0.0.1", PORT, &hints, &res) != 0) { printf("getaddrinfo 失败\n"); return 1; }

    SOCKET s = INVALID_SOCKET;
    for (struct addrinfo* p = res; p; p = p->ai_next) {
        s = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
        if (s == INVALID_SOCKET) continue;
        if (connect(s, p->ai_addr, (int)p->ai_addrlen) != SOCKET_ERROR) break;
        closesocket(s); s = INVALID_SOCKET;
    }
    freeaddrinfo(res);
    if (s == INVALID_SOCKET) {
        printf("连不上 127.0.0.1:%s（%d）——先启动服务器模式（不带参数运行本程序）\n", PORT, WSAGetLastError());
        return 1;
    }
    printf("TCP 已连接 127.0.0.1:%s\n", PORT);

    // 三条消息：各发各收（SendAll 循环发送；收满同长度再算一条——回显协议自带边界）
    for (int i = 1; i <= 3; ++i) {
        char msg[64];
        int len = sprintf_s(msg, "TCP message #%d from 41_winsock_echo", i);
        if (SendAll(s, msg, len) == SOCKET_ERROR) { printf("send 失败 %d\n", WSAGetLastError()); return 1; }

        char echo[128]; int got = 0;
        while (got < len) {                                  // 回显可能分批到
            int n = recv(s, echo + got, len - got, 0);
            if (n <= 0) { printf("recv 提前结束 %d\n", WSAGetLastError()); return 1; }
            got += n;
        }
        printf("  第 %d 条：发 %d 字节，收回 %d 字节，一致 = %s\n",
               i, len, got, memcmp(msg, echo, len) == 0 ? "yes" : "no");
    }

    // 半关闭：我说完了，但继续听服务器把话说完（33.5）
    if (shutdown(s, SD_SEND) == SOCKET_ERROR) printf("shutdown 失败 %d\n", WSAGetLastError());
    char last[8];
    int n = recv(s, last, sizeof(last), 0);
    printf("  shutdown(SD_SEND) 后再 recv = %d（0 = 对端确认关闭：优雅收尾）\n", n);
    closesocket(s);

    // UDP 两条数据报：sendto 直发 / recvfrom 收回显
    SOCKET u = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    struct addrinfo uh = {}, *ures = nullptr;
    uh.ai_family = AF_INET; uh.ai_socktype = SOCK_DGRAM; uh.ai_protocol = IPPROTO_UDP;
    if (getaddrinfo("127.0.0.1", PORT, &uh, &ures) != 0) { printf("getaddrinfo(UDP) 失败\n"); closesocket(u); return 1; }
    for (int i = 1; i <= 2; ++i) {
        char msg[64];
        int len = sprintf_s(msg, "UDP datagram #%d", i);
        sendto(u, msg, len, 0, ures->ai_addr, (int)ures->ai_addrlen);

        char echo[128];
        struct sockaddr_in from = {}; int fromLen = sizeof(from);
        int m = recvfrom(u, echo, sizeof(echo), 0, (sockaddr*)&from, &fromLen);
        if (m < 0) { printf("  UDP 第 %d 条：recvfrom 失败 %d\n", i, WSAGetLastError()); break; }
        echo[m] = '\0';
        printf("  UDP 第 %d 条：%s（回显 %d 字节）\n", i, echo, m);
    }
    freeaddrinfo(ures);
    closesocket(u);
    printf("客户端全链路完成。\n");
    return 0;
}

int wmain(int argc, wchar_t** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);   // 服务器常驻，输出无缓冲才能被重定向/强杀后看到
    WSADATA wsa;
    int err = WSAStartup(MAKEWORD(2, 2), &wsa);   // 返回值即错误码，不走 GetLastError
    if (err != 0) { printf("WSAStartup 失败 %d\n", err); return 1; }

    int rc = (argc > 1 && wcscmp(argv[1], L"-c") == 0) ? RunClient() : RunServer();
    WSACleanup();
    return rc;
}
