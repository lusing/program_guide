# 25 · 原生图形、音频与性能

> 对应示例：`compose_examples/app/src/main/cpp/native_media.cpp` + `jni/MediaBridge.kt`（Compose 消费层在 `samples/JniSamples.kt`）

## 1. 三条原生媒体通道总览

原书第 12、20 章用两个完整播放器（AVI 视频 + WAVE 音频）串起了三条"native 直接碰显示与声音"的 API 通道，2026 年坐标如下：

| 通道 | 原书用法 | 2026 现状 | 本教程取材 |
|---|---|---|---|
| JNI Graphics（Bitmap 直访） | AVI 帧写进 Bitmap | **现役**（NDK 稳定 API） | 代码样张 |
| OpenGL ES + EGL | 手工 EGL 上下文 + 纹理上传 | 现役但路径变化（校准见第 4 节） | EGL 探测样张 |
| OpenSL ES | WAVE 播放器全流程 | **API 34 起官方 deprecated** → AAudio | 引擎探测样张 |

本章立场与第 27 章一脉相承：应用开发里图像显示交给 Compose/Coil、音频播放交给系统播放器与 ExoPlayer 系；这三条通道属于"引擎与播放器内核"的世界。教学目标是**看懂它们的样子与边界**，最后落在 NEON 与性能测量——那是全原生线的收束点。

## 2. JNI Graphics：Bitmap 像素直访

`AndroidBitmap_*` 一族（`libjnigraphics`）让 native 直接读写 Bitmap 的像素缓冲，`mediaBitmapInfo` 是最小样张：

```cpp
AndroidBitmapInfo info{};
AndroidBitmap_getInfo(env, bitmap, &info);          // 尺寸/格式/stride，零拷贝
void* pixels = nullptr;
if (AndroidBitmap_lockPixels(env, bitmap, &pixels) == ANDROID_BITMAP_RESULT_SUCCESS) {
    // pixels 指向整帧像素：width×height 个像素按 info.format 排布
    AndroidBitmap_unlockPixels(env, bitmap);         // lock/unlock 必须配对
}
```

两个实务认知：

- **stride 不等于 width × 每像素字节数**：行与行之间可能有对齐填充，逐行处理要按 `info.stride` 步进——按 width 硬算会在某些设备上把图撕成斜的
- **只吃软件位图**：`Bitmap.Config.ARGB_8888/RGB_565` 这些；`HARDWARE` 配置的位图（部分系统组件产出）像素在显存，`lockPixels` 直接失败——先 `copy(ARGB_8888, false)` 转一手（第 05 章 Bitmap 知识的延伸）

原书 12.3 的 AVI 播放器用这条通道把解码帧逐帧写进 Bitmap 再上屏——今天它是图像处理（滤镜、识别前预处理）的常用桥：Kotlin 出 Bitmap，native 算像素，Compose 显示结果。

## 3. OpenSL ES：音频引擎的探测与谢幕

OpenSL ES 是 Khronos 的嵌入式音频标准，Android 从 API 9 起提供（原书 13.1 的起点），`mediaOpenSlProbe` 走对象模型的第一步——创建引擎并 Realize：

```cpp
SLObjectItf engineObject = nullptr;
slCreateEngine(&engineObject, 0, nullptr, 0, nullptr, nullptr);   // 造引擎对象
(*engineObject)->Realize(engineObject, SL_BOOLEAN_FALSE);          // 异步模型同步化：建好才返回
(*engineObject)->Destroy(engineObject);                            // 用完销毁
```

它的对象模型（Create → Realize → GetInterface → 用 → Destroy）与状态机是理解这套 API 的钥匙，原书第 13 章用半章铺了 WAVE 播放器全流程（混音器 → 播放器 → 队列喂 PCM）。

**校准（必须知道）**：Android 15（API 34/35）起官方文档把 OpenSL ES 标记为 **deprecated**——功能仍在（大量存量与跨平台引擎还依赖它），但新代码的官方答案是 **AAudio**（API 26+，低延迟回调模型）或上层的 Oboe 库（Google 官方 C++ 包装）。选型：新原生音频项目 Oboe/AAudio；读老代码，OpenSL ES 的知识仍有效。

## 4. OpenGL ES 与 EGL：渲染的现代路径

原书 12.4–12.5 走的是"手工 EGL"路线：eglGetDisplay → eglInitialize → eglCreateContext → 每帧 eglSwapBuffers，另外还有 ANativeWindow 直写（`ANativeWindow_fromSurface` 拿 Surface、`setBuffersGeometry` 配置、lock/unlockAndPost 上屏）。`mediaEglProbe` 探测的是这条链的头两步：

```cpp
EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
EGLint major = 0, minor = 0;
eglInitialize(display, &major, &minor);
const char* version = eglQueryString(display, EGL_VERSION);
eglTerminate(display);
```

2026 年的应用层路线校准：

- **常规应用渲染**：`GLSurfaceView`（View 体系）持有 EGL 上下文与 GL 线程，你只实现 Renderer 回调；Compose 世界经 `AndroidView` 嵌一个即可（第 19 章第 11 节的互操作场景）。手工 EGL 属于游戏引擎/播放器内核的活
- **ES 版本**：原书兼写 ES 1.x 固定管线与 ES 2.0——**1.x 已淘汰**，现代目标是 ES 3.0/3.1（API 24 起全量支持，恰好是本教程 minSdk）
- **上屏路径**：纹理上传（`glTexSubImage2D`，原书 12.4 的方案）或 SurfaceView/ANativeWindow；无窗口离屏渲染用 EGL surfaceless 扩展或 PBuffer
- ANativeWindow 系列（`libandroid`）仍现役，是 Surface ↔ native 渲染的桥

一句话立场：**看得懂 EGL 三件套与"上下文/表面"的区分**即可入门口；真要写渲染，先 GLSurfaceView 后手工。

## 5. NEON：SIMD 的正确打开方式

ARM 的 SIMD 指令集叫 NEON：128 位寄存器一次算 4 个 int32 / 8 个 int16 / 16 个 int8。两个时代事实：

- **64 位 ARM（arm64-v8a）上 NEON 是必备**——`<arm_neon.h>` 直接用，无需运行时探测
- 32 位 armv7 时代才要 cpuid 探测 + 编译开关；2026 年新工程基本可忘

`mediaNeonAddShorts` 是 intrinsics（内在函数）写法的标准样子：

```cpp
int16x8_t va = vld1q_s16(bufA);      // 载入 128 位（8 路 int16）
int16x8_t vb = vld1q_s16(bufB);
int16x8_t sum = vaddq_s16(va, vb);   // 一条指令，8 路加法
vst1q_s16(bufA, sum);
```

命名法是查表钥匙：`v` + 操作（`add`）+ `q`（128 位 full register）+ 类型（`s16` 有符号 16 位）；`vld1q`/`vst1q` 是不交错装载/存储。循环按 8 个一组向量化，**尾巴（len 非 8 倍数）留给标量路径**——边界处理是 SIMD 代码一半的工作量。

但先泼两盆冷水，都来自原书第 14 章自己的提醒：

1. **先测量再向量化**（第 27 章"先 profiler 后下潜"的 SIMD 版）：NEON 上限加速约 8×（int16），实际拿到 2–4× 已属优秀——内存带宽与装载/存储常常才是瓶颈
2. **编译器会自动向量化**：`-O2` 起的 clang 对简单循环已能生成 NEON 代码（原书 14.3 整节讲此）。手写 intrinsics 的前提是 profiler 证明热点且自动向量化没吃满

## 6. 性能测量：GProf 已死，simpleperf 当立

原书 14.1 的测量方案（android-ndk-profiler + `monstartup` + `gmon.out` + `arm-linux-androideabi-gprof`）**已随 ndk-build 时代一起退役**。2026 年的正确工具：

| 需求 | 工具 | 用法一句话 |
|---|---|---|
| native 热点采样 | **simpleperf**（NDK 自带） | `simpleperf record -g ./app` → `report`，看调用树 |
| Java+native 联合 | Android Studio Profiler | CPU trace 选 "System Trace / Java+Native" |
| 函数级微基准 | benchmark 库 / 手写循环计时 | 固定输入、多次取中位、防编译器吃掉循环 |
| 内存问题 | ASAN（`arm64` 地址消毒） | CMake `-fsanitize=address`，越界/释放后使用当场抓 |

微基准的三条纪律（对 2014 与 2026 同样成立）：跑够次数取中位数；对照"关掉你的优化再测一次"；在真机测（模拟器的性能特征不代表任何真机）。

## 7. 常见坑

**stride 当 width 用**：第 2 节。逐行处理必须按 `info.stride` 步进，撕裂/错位的图八成是它。

**对 HARDWARE 位图 lockPixels**：必败。先转软件位图再进 native。

**给 OpenSL ES 开新工程**：deprecated 已官宣，新代码 AAudio/Oboe。老代码维护除外。

**ES 1.x 教程照抄**：固定管线 API（`glMatrixMode`/`glLoadIdentity`）在 ES 2.0+ 不存在。认准"shader/program"字样的教程再学。

**手写 NEON 前不测量**：拿 1.5× 的加速换一坨难维护的 intrinsics，是负收益。先 `-O2` + simpleperf 看自动向量化的成色。

**尾巴越界**：向量化循环 `i += 8` 但数组长度没对齐——最后一段读写越界，崩在无关处。`len / 8 * 8` 截断 + 标量收尾（本例代码）。

**微基准在模拟器上做结论**：性能结论只能来自真机，模拟器连 CPU 都可能在做二进制翻译。

## 8. 实战建议

- 图像预处理（滤镜/识别前缩放裁剪）是 Bitmap 直访在现代应用里最常见的正业，Compose 出图 → native 算 → 状态回显
- 音频新项目一律 AAudio/Oboe 起步；OpenSL ES 的对象模型知识用于读老引擎
- 渲染从 GLSurfaceView 起步，手工 EGL 留给引擎内核；ES 3.0 为最低目标
- SIMD 工作流固定为四步：simpleperf 找热点 → `-O2` 看自动向量化 → intrinsics 改写 → 回测对比。省任何一步都是赌博
- 原生线的总回顾：27 章（边界）→ 28 章（数据与异常）→ 29 章（环境）→ 30 章（并发）→ 31 章（网络）→ 本章（媒体与性能）——六步恰好是"接得住一个 native 库"的完整知识面
- 下一章回到纯 Kotlin 世界，用前 21 章的知识组装完整应用 MemoPad——原生线是纵深选修，不是必经之路

---

上一章：[31 POSIX Socket 原生网络](31-native-sockets.md) ｜ 下一章：[33 实战项目：MemoPad 便签应用](33-memopad.md) ｜ 返回：[README](../README.md)
