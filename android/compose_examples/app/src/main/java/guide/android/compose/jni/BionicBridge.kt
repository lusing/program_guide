package guide.android.compose.jni

/**
 * 第 29 章 Bionic 与 C++ 标准库。
 * 镜像文件：cpp/bionic_samples.cpp
 */
object BionicBridge {
    init {
        System.loadLibrary("guide_native")
    }

    /** sysconf(_SC_PAGESIZE)：内存页大小 */
    external fun bionicPageSize(): Int

    /** sysconf(_SC_NPROCESSORS_CONF)：系统配置的 CPU 数 */
    external fun bionicCpuCount(): Int

    /** __system_property_get("ro.build.version.sdk")：Bionic 系统属性 */
    external fun bionicSdkProp(): String

    /** getuid/getgid/getpwuid：应用沙箱身份 */
    external fun bionicUidInfo(): String

    /** 标准 C 文件 I/O：fopen/fwrite/fread 往返（path 用应用内部存储） */
    external fun bionicFileRoundTrip(path: String, content: String): String

    /** C++ STL：std::vector + std::sort 排序 */
    external fun bionicSortDoubles(arr: DoubleArray): DoubleArray?

    /** 异常与 RTTI 探测：try/catch + dynamic_cast + typeid */
    external fun bionicCppFeatures(): String
}
