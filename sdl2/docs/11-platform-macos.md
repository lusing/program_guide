# 11 · 平台差异：macOS 与 Windows 的构建和运行分野

> 本章无独立示例，证据来自 `examples/` 全部 10 个示例的 `build/` 产物与两条链接通道的实测对照。

同一份 `.cpp` 在两个平台上的差别**全在构建命令行和后端选择上，一行代码都不用改**。本章把本次 macOS 校验沉淀下来的差异摊开：配置怎么探测、静态链接为什么要一长串 frameworks、后端矩阵长什么样、以及三条只有跑过才知道的运行侧事实。所有数字都取自本机（Darwin 24.6 x86_64 · Apple clang 17.0.0 · SDL2 2.32.10 · MacPorts `/opt/local`），文件路径都写在 `build/` 里可逐字节复核。

## 11.1 配置一律探测，不抄路径

macOS/Linux 上 SDL2 的安装前缀不止一个：MacPorts 在 `/opt/local`，Homebrew Intel 在 `/usr/local`、Apple Silicon 在 `/opt/homebrew`，源码安装还可能是 `/usr/local` 或用户目录。`run-all.sh` 的对策是**两级探测**：

```bash
# ═══ 11.1 探测顺序：sdl2-config → pkg-config → 报环境缺口退出 ═══
sdl2-config --cflags        # -I… -D_THREAD_SAFE
sdl2-config --libs          # -L… -lSDL2
sdl2-config --static-libs   # 完整静态链接参数（含 frameworks）
pkg-config --cflags --libs sdl2      # 退回方案
```

探测不到就直接打印"环境缺口"并以退出码 2 结束——**不猜路径，也不假装通过**。留档 `build/toolchain.txt`（本机实测，两行参数就是本章示例的编译依据）：

```text
CFLAGS       : -I/opt/local/include/SDL2 -D_THREAD_SAFE
LIBS(shared) : -L/opt/local/lib -lSDL2
```

`-D_THREAD_SAFE` 是 `--cflags` 附带的（macOS 上 pthread 相关），手工拼参数时最容易漏的就是它。Windows 侧没有等价工具，`build.ps1` 走"环境变量/已知路径 + 显式 `include\SDL2` + `SDL2.lib`"的方式，路径由使用者给定。

## 11.2 静态链接：macOS 的 `libSDL2.a` 不带系统依赖

动态链接时 `.dylib` 自己记着它依赖哪些 framework，`-lSDL2` 就够了。静态链接完全相反：`libSDL2.a` 里只是 Objective-C 与 CoreAudio 的**调用方**，被调方要你自己给全。本机 `sdl2-config --static-libs` 的完整输出（`build/toolchain.txt`）：

```text
-L/opt/local/lib /opt/local/lib/libSDL2.a -lm -Wl,-framework,CoreAudio
-Wl,-framework,AudioToolbox -Wl,-weak_framework,CoreHaptics
-Wl,-weak_framework,GameController -Wl,-framework,ForceFeedback -lobjc
-Wl,-framework,CoreVideo -Wl,-framework,Cocoa -Wl,-framework,Carbon
-Wl,-framework,IOKit -Wl,-weak_framework,QuartzCore -Wl,-weak_framework,Metal
```

逐项对应 SDL 的功能面：`Cocoa`/`CoreVideo`/`IOKit`/`Carbon` 是视频与输入（窗口、显示模式、设备枚举），`CoreAudio`/`AudioToolbox`/`ForceFeedback` 是音频，`-lobjc` 是 Objective-C 运行时（`objc_msgSend` 之类符号的来源），`Metal`/`QuartzCore` 是渲染后端，`CoreHaptics`/`GameController` 用 `-weak_framework` 链接——**旧系统上没有这两个 framework 也能跑**，运行时再判可用性。

漏掉 frameworks 的后果不是"某些功能不可用"，而是**链接期直接失败**。`run-all.sh` 里专门留了一段反例实验：故意只用裸 `libSDL2.a`（不带任何 `-framework`）链接 `01_init_version.cpp`，把失败原文写进 `build/static-link-missing-frameworks.err` 供文档引用。实测摘录：

```text
Undefined symbols for architecture x86_64:
      _COREAUDIO_Init in libSDL2.a[177](SDL_coreaudio.o)
ld: symbol(s) not found for architecture x86_64
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
```

看到一串 `_objc_*`、`_AudioObject*`、`_Cocoa_RegisterApp` 悬空符号，就是这一条。**结论：macOS 静态链接不要手工拼参数，直接取 `sdl2-config --static-libs`。**

## 11.3 后端矩阵：问 SDL 要它自己知道的事

`SDL_GetNumVideoDrivers`/`SDL_GetVideoDriver`、`SDL_GetNumAudioDrivers`/`SDL_GetAudioDriver`、`SDL_GetNumRenderDrivers`/`SDL_GetRenderDriverInfo` 三组枚举 API 能在**创建任何东西之前**回答"这台机器上有什么"。本机实测（补充实验，代码就是上面三个枚举调用的直译；产物不由 `run-all.sh` 生成）：

<!-- 补充实验的手工输出，非 run-all.sh 产物 -->
```text
video: cocoa offscreen dummy
audio: coreaudio disk dummy
render: metal opengl opengles2 software
```

三个可用环境变量覆盖默认选择：`SDL_VIDEODRIVER`、`SDL_AUDIODRIVER`、`SDL_RENDER_DRIVER`。`dummy` 是"没有窗口/没有音频"的通用后端，CI 里最常用（本教程 `SDL_VIDEODRIVER=dummy ./run-all.sh --one` 实测 10/10 通过）；`offscreen` 比 `dummy` 多做一件事——提供可用的窗口与可绘制表面但不真正上屏，`disk` 则把音频写进文件而非出声。

渲染器请求位的实测矩阵（同一台机器，两个驱动各跑一次；`gotFlags` 为 `SDL_GetRendererInfo().flags` 的数值，`2`=ACCELERATED、`4`=PRESENTVSYNC、`8`=TARGETTEXTURE、`1`=SOFTWARE）：

| 请求 flags | `cocoa` 驱动 | `dummy` 驱动 |
|---|---|---|
| `ACCELERATED` | OK `metal`，`gotFlags=10` | **FAIL**：`Couldn't find matching render driver` |
| `ACCELERATED\|PRESENTVSYNC` | OK `metal`，`gotFlags=14` | **FAIL**：同上 |
| `SOFTWARE\|PRESENTVSYNC` | OK `software`，`gotFlags=13` | OK `software`，`gotFlags=13` |
| `TARGETTEXTURE` | OK `metal`，`gotFlags=10` | OK `software`，`gotFlags=13` |

读这张表要点两件事：其一，请求位是 **AND 语义**，凑不齐就整体失败（所以 02 章的降级必须按"创建失败"分支写）；其二，**没请求的位不会白给**——只请求 `ACCELERATED` 时 `gotFlags=10` 里没有 `PRESENTVSYNC`，`SDL_RenderPresent` 不阻塞，帧率得自己控制（06 章）。Windows 侧的对应矩阵（`windows` 视频驱动、`direct3d`/`direct3d11` 渲染后端）本机无 MSVC，**未实测**，只在 `build.ps1` 层面保证判定逻辑与 `run-all.sh` 逐条对齐。

## 11.4 运行侧三条只有跑过才知道的事实

- **`dummy` 下没有加速后端**：`SDL_CreateRenderer` 返回 `nullptr`，错误串 `Couldn't find matching render driver`（11.3 表第二行）。示例 02 因此必须写降级，两份实测输出见 02 章 2.5 节。
- **帧长抖动**：同一台机器、同一份二进制，`SDL_GetTicks()` 差值在 `build/shared|static/06_timer_fps.run1|run2` 四轮里分别是 **18 / 16 / 20 / 18 ms**，`fps` 相应为 `55.5556 / 62.5 / 50 / 55.5556`。这类量一律不进比对区间（06 章的方法论）。
- **像素格式别名在两平台一致**：`SDL_PIXELFORMAT_RGBA32` 在小端 macOS 与小端 Windows 上都解析成 `ABGR8888`（04 章实测 `surfaceFormat=SDL_PIXELFORMAT_ABGR8888`），所以这次**没有**平台差异——差异在架构字节序，不在操作系统。

## 11.5 本机造不出来的三个场景

诚实清单，都是"推断合理但未实测"，不是示例缺陷：

- **纯 SSH（无 GUI 会话）下 `cocoa` 驱动的行为**：推断 `SDL_Init(SDL_INIT_VIDEO)` 会因拿不到 WindowServer 连接而失败，但本机始终在 GUI 会话中，无法制造该场景。CI 请直接 `SDL_VIDEODRIVER=dummy`。
- **Windows/MSVC 的实际运行结果**：本机无 MSVC，`build.ps1` 只做了 PowerShell 语法解析。
- **Apple Silicon（arm64）**：本机为 x86_64，未做交叉验证。示例不含任何架构相关代码，理论上可直接编译，需真机确认（Homebrew 前缀也会随之变成 `/opt/homebrew`，但 11.1 的探测逻辑对此无感）。

## 坑位清单

35. **macOS 静态链接 `libSDL2.a` 不带系统依赖**：缺 frameworks 直接 `ld: symbol(s) not found for architecture x86_64`（反例留档 `build/static-link-missing-frameworks.err`，含 `_COREAUDIO_Init`、`_objc_*` 一串悬空符号）。用 `sdl2-config --static-libs` 取完整参数，别手工拼。
36. **把 `-weak_framework` 改成 `-framework`**：`CoreHaptics`/`GameController`/`QuartzCore`/`Metal` 在旧系统上可能不存在，弱链接让"缺了也能跑"。手改成强链接等于给老系统判死刑，也丢掉了 SDL 自己做的运行时探测。
37. **把 `--cflags` 的 `-D_THREAD_SAFE` 或安装前缀硬编码进脚本**：MacPorts `/opt/local`、Homebrew Intel `/usr/local`、Apple Silicon `/opt/homebrew`，前缀随安装方式变；漏 `-D_THREAD_SAFE` 在部分配置下影响 pthread 语义。一律走 `sdl2-config`/`pkg-config` 探测，探不到就报环境缺口。

---

上一章：[10 · C++ RAII 封装：不泄漏不等于顺序对](10-raii-wrappers.md) ｜ 下一章：[12 · 统一编译验证：七条判定与双通道](12-verification.md) ｜ 返回：[README](../README.md)
