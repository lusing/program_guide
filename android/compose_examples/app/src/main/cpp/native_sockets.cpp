// 第 24 章：POSIX Socket——TCP/UDP/UNIX domain 回环 echo
// Kotlin 侧镜像：jni/SocketBridge.kt
//
// 三个示例都用"单线程回环"设计：服务器与客户端在同一个 JNI 调用里先后跑。
// TCP 的 connect 在对端 listen 之后即可经内核 backlog 完成，不需要先 accept，
// 所以顺序执行完全成立——真机可跑，逻辑也一眼读得完。
#include <jni.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cerrno>
#include <cstring>
#include <string>

namespace {

std::string errno_text(const char* what) {
    return std::string(what) + " 失败: " + strerror(errno);
}

std::string recv_all(int fd) {
    std::string out;
    char buf[512];
    for (;;) {
        ssize_t n = recv(fd, buf, sizeof(buf), 0);
        if (n < 0) {
            return out + "（recv 出错）";
        }
        if (n == 0) {
            break;  // 对端关闭写端：EOF
        }
        out.append(buf, (size_t) n);
    }
    return out;
}

}  // namespace

// ---------- TCP：socket/bind/listen/accept + connect/send/recv ----------
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_SocketBridge_socketTcpEcho(JNIEnv* env, jobject, jint port, jstring message) {
    const char* msgChars = env->GetStringUTFChars(message, nullptr);
    std::string report;

    int listenFd = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons((uint16_t) port);   // 端口必须转网络字节序

    if (listenFd < 0 || bind(listenFd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 ||
        listen(listenFd, 1) != 0) {
        report = errno_text("socket/bind/listen");
    } else {
        int clientFd = socket(AF_INET, SOCK_STREAM, 0);
        if (connect(clientFd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0) {
            send(clientFd, msgChars, strlen(msgChars), 0);
            shutdown(clientFd, SHUT_WR);            // 关写端：让服务器读到 EOF

            int serverSide = accept(listenFd, nullptr, nullptr);
            std::string echoed = recv_all(serverSide);
            send(serverSide, echoed.data(), echoed.size(), 0);
            close(serverSide);

            std::string back = recv_all(clientFd);
            close(clientFd);
            report = "TCP 发送 " + std::string(msgChars) + "，回环收到 " + back +
                     (back == msgChars ? "（一致 ✓）" : "（不一致 ✗）");
        } else {
            report = errno_text("connect");
            close(clientFd);
        }
    }
    close(listenFd);
    env->ReleaseStringUTFChars(message, msgChars);
    return env->NewStringUTF(report.c_str());
}

// ---------- UDP：无连接，sendto/recvfrom 各自带地址 ----------
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_SocketBridge_socketUdpEcho(JNIEnv* env, jobject, jint port, jstring message) {
    const char* msgChars = env->GetStringUTFChars(message, nullptr);
    std::string report;

    int serverFd = socket(AF_INET, SOCK_DGRAM, 0);
    int clientFd = socket(AF_INET, SOCK_DGRAM, 0);
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons((uint16_t) port);

    if (bind(serverFd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
        report = errno_text("bind");
    } else {
        // UDP 不建连：直接朝服务器地址发包
        sendto(clientFd, msgChars, strlen(msgChars), 0,
               reinterpret_cast<sockaddr*>(&addr), sizeof(addr));
        char buf[512];
        sockaddr_in from{};
        socklen_t fromLen = sizeof(from);
        ssize_t n = recvfrom(serverFd, buf, sizeof(buf), 0,
                             reinterpret_cast<sockaddr*>(&from), &fromLen);
        if (n > 0) {
            // 数据报自带"回信地址"，服务器照着原路弹回
            sendto(serverFd, buf, (size_t) n, 0,
                   reinterpret_cast<sockaddr*>(&from), fromLen);
        }
        n = recvfrom(clientFd, buf, sizeof(buf), 0, nullptr, nullptr);
        std::string back = n > 0 ? std::string(buf, (size_t) n) : std::string();
        report = "UDP 发送 " + std::string(msgChars) + "，回环收到 " + back +
                 (back == msgChars ? "（一致 ✓）" : "（不一致 ✗）");
    }
    close(serverFd);
    close(clientFd);
    env->ReleaseStringUTFChars(message, msgChars);
    return env->NewStringUTF(report.c_str());
}

// ---------- UNIX domain socket：本机 IPC，不走网络协议栈 ----------
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_SocketBridge_socketLocalEcho(JNIEnv* env, jobject, jstring path, jstring message) {
    const char* pathChars = env->GetStringUTFChars(path, nullptr);
    const char* msgChars = env->GetStringUTFChars(message, nullptr);
    std::string report;

    unlink(pathChars);  // 上次运行残留的 socket 文件会让 bind 撞 EADDRINUSE
    int listenFd = socket(AF_UNIX, SOCK_STREAM, 0);
    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, pathChars, sizeof(addr.sun_path) - 1);

    if (bind(listenFd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 ||
        listen(listenFd, 1) != 0) {
        report = errno_text("bind/listen(AF_UNIX)");
    } else {
        int clientFd = socket(AF_UNIX, SOCK_STREAM, 0);
        if (connect(clientFd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0) {
            send(clientFd, msgChars, strlen(msgChars), 0);
            shutdown(clientFd, SHUT_WR);

            int serverSide = accept(listenFd, nullptr, nullptr);
            std::string echoed = recv_all(serverSide);
            send(serverSide, echoed.data(), echoed.size(), 0);
            close(serverSide);

            std::string back = recv_all(clientFd);
            close(clientFd);
            report = "本地 socket 发送 " + std::string(msgChars) + "，回环收到 " + back +
                     (back == msgChars ? "（一致 ✓）" : "（不一致 ✗）");
        } else {
            report = errno_text("connect(AF_UNIX)");
            close(clientFd);
        }
    }
    close(listenFd);
    unlink(pathChars);  // 用完清掉 socket 文件
    env->ReleaseStringUTFChars(message, msgChars);
    env->ReleaseStringUTFChars(path, pathChars);
    return env->NewStringUTF(report.c_str());
}
