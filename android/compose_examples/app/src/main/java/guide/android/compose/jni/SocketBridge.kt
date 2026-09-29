package guide.android.compose.jni

/**
 * 第 24 章 POSIX Socket：TCP/UDP/UNIX domain 回环 echo。
 * 镜像文件：cpp/native_sockets.cpp
 */
object SocketBridge {
    init {
        System.loadLibrary("guide_native")
    }

    /** TCP：socket/bind/listen/accept + connect/send/shutdown/recv 单线程回环 */
    external fun socketTcpEcho(port: Int, message: String): String

    /** UDP：无连接 sendto/recvfrom，数据报自带回信地址 */
    external fun socketUdpEcho(port: Int, message: String): String

    /** UNIX domain socket：本机 IPC（path 用应用内部存储下的文件） */
    external fun socketLocalEcho(path: String, message: String): String
}
