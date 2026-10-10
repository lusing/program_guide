# SDL2 编程指南示例集

SDL2 C++ 教程与可编译示例。正文按章拆分在 `docs/`（12 章，01–10 与示例同号），
示例本身是跨平台代码（只用 SDL2 公共 API + `SDL_MAIN_HANDLED`），两个构建入口
分别覆盖 Windows/MSVC 与 macOS/Linux/clang。

## 目录结构

<!-- 目录结构示意，非运行输出 -->
```text
sdl2/
├── README.md              本文件：分章导航 + 工具链 + 验证状态 + 平台差异
├── CHEATSheet.md          语法速查 + 40 条实测坑位索引
├── run-all.sh             验证入口（shell 版：macOS / Linux）
├── build.ps1              验证入口（PowerShell 版：Windows / MSVC）
├── docs/                  12 章正文（NN-slug.md，章号 = 示例号；11/12 无示例）
│   ├── 01-init-version.md
│   ├── 02-window-renderer.md
│   ├── 03-event-loop.md
│   ├── 04-surface-texture.md
│   ├── 05-draw-primitives.md
│   ├── 06-timer-fps.md
│   ├── 07-keyboard-state.md
│   ├── 08-audio-callback.md
│   ├── 09-threads-mutex.md
│   ├── 10-raii-wrappers.md
│   ├── 11-platform-macos.md     平台差异（macOS ↔ Windows）
│   └── 12-verification.md       统一编译验证（七条判定 + 双通道）
├── tools/
│   └── check_docs.py      文档机器核查（章节↔示例 / 输出对账 / 坑位 / 导航 / 正文自足）
├── examples/              10 个独立单文件示例
│   ├── 01_init_version.cpp
│   ├── 02_window_renderer.cpp
│   ├── 03_event_loop_skeleton.cpp
│   ├── 04_texture_surface.cpp
│   ├── 05_draw_primitives.cpp
│   ├── 06_timer_fps.cpp
│   ├── 07_keyboard_state.cpp
│   ├── 08_audio_callback.cpp
│   ├── 09_threads_mutex.cpp
│   └── 10_raii_wrappers.cpp
└── build/                 验证产物（可删）
```

## 分章导航

**第一部分 图形主线（窗口 → 事件 → 像素 → 绘制）**

1. [初始化与版本：把入口权拿回自己手里](docs/01-init-version.md)
2. [窗口与渲染器：加速后端拿不到怎么办](docs/02-window-renderer.md)
3. [事件循环骨架：PollEvent 与"没人点关闭"的退出](docs/03-event-loop.md)
4. [Surface 与 Texture：像素在 CPU 还是在 GPU](docs/04-surface-texture.md)
5. [基础绘制 API：返回 void 的 Present 怎么判成败](docs/05-draw-primitives.md)

**第二部分 时间与输入**

6. [计时与帧率：哪些数字能进字节比对](docs/06-timer-fps.md)
7. [键盘输入状态：状态表、PumpEvents 与那个 512](docs/07-keyboard-state.md)

**第三部分 音频与并发**

8. [音频回调模型：desired/obtained 与打开后的暂停态](docs/08-audio-callback.md)
9. [线程与互斥锁：让 `counter=2000` 成为确定性断言](docs/09-threads-mutex.md)

**第四部分 C++ 封装与工程侧**

10. [C++ RAII 封装：不泄漏不等于顺序对](docs/10-raii-wrappers.md)
11. [平台差异：macOS 与 Windows 的构建和运行分野](docs/11-platform-macos.md)
12. [统一编译验证：七条判定与双通道](docs/12-verification.md)

坑位共 **40 条实测坑位**，按章编号 1–40，索引见 [CHEATSheet.md](CHEATSheet.md)。

## 构建工具链

### macOS（本机实测）

| 项 | 值 |
|---|---|
| 编译器 | Apple clang 17.0.0（`x86_64-apple-darwin24.6.0`，Xcode CLT） |
| SDL2 | 2.32.10，MacPorts 装在 `/opt/local` |
| 配置工具 | `/opt/local/bin/sdl2-config`（退回 `pkg-config sdl2`） |
| 头文件 | `-I/opt/local/include/SDL2 -D_THREAD_SAFE` |
| 动态链接 | `-L/opt/local/lib -lSDL2` |
| 静态链接 | `sdl2-config --static-libs`（**必须带 frameworks，见下**） |
| 超时保护 | `/opt/local/bin/gtimeout`（MacPorts coreutils；**macOS 没有 GNU `timeout`**） |

安装：

```bash
sudo port install libsdl2 coreutils
xcode-select --install     # 提供 clang 与链接器
```

工具链一律由 `run-all.sh` 探测（`sdl2-config` → `pkg-config`），**不硬编码路径**；
找不到就报「环境缺口」退出，不会假装通过。

### Windows

- SDL2：`G:\scoop\apps\sdl2\current`
- VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC`
- 编译器：`cl.exe (MSVC)`，`/std:c++20 /EHsc /utf-8`，链接 `SDL2.lib`

## 编译验证

macOS / Linux：

```bash
./run-all.sh            # 全部示例 × shared/static 双通道
./run-all.sh -v         # 附带每个示例的区间输出
./run-all.sh 02 06      # 只跑指定编号
./run-all.sh --one      # 只跑 shared 一条通道
```

Windows：

```powershell
.\build.ps1 -All
.\build.ps1 -File 06_timer_fps.cpp
.\build.ps1 -CompileOnly      # 只编译，跳过运行判定
.\build.ps1 -Clean
```

文档核查（五关：章节↔示例、输出块与 build 产物对账、坑位编号自洽、导航链接有效、
**示例每一行代码都在正文里有出处**）：

```bash
python3 tools/check_docs.py
```

判定标准（两个入口共用，shell 版多一条双通道比对）与每条的存在理由，
正文见 [12 章 · 统一编译验证](docs/12-verification.md)：编译退出码 0 且编译期
stderr 为空（`-Wall -Wextra`，任何告警即失败）→ 运行退出码 0 → 运行 stderr 为空
→ stdout 含 `==== NN 开始/结束 ====` 双标记 → 区间非空且不含控制字符 → 同通道
两跑逐字节一致 → shared 与 static 两条通道逐字节一致。

## 验证状态

**macOS（Darwin 24.6 x86_64，Apple clang 17.0.0 + SDL2 2.32.10，2026-10-10 实测）**

| 场景 | 结果 |
|---|---|
| `./run-all.sh`（shared + static 双通道） | **10 示例 × 2 通道 = 20/20 通过** |
| `SDL_VIDEODRIVER=dummy ./run-all.sh --one`（无窗口会话） | **10/10 通过** |
| `-Wall -Wextra` 编译告警 | 0 条（编译期 stderr 非空即判失败） |

Windows/MSVC 侧：本机无 MSVC，`build.ps1` 只做了 PowerShell 语法解析通过，
**未实跑**，其判定逻辑与 `run-all.sh` 逐条对齐（详见文件头注释）。

## 平台差异速查（macOS ↔ Windows）

详版（含后端枚举实测、渲染器请求位矩阵、链接反例证据）见
[11 章 · 平台差异](docs/11-platform-macos.md)。

| 主题 | Windows / MSVC | macOS / clang |
|---|---|---|
| 配置工具 | 手工指定 `include\SDL2` + `SDL2.lib` | `sdl2-config --cflags/--libs` 或 `pkg-config sdl2` |
| 静态链接 | `SDL2.lib`/`SDL2-static.lib` 自带依赖 | `libSDL2.a` **不带**系统依赖，必须 `-framework Cocoa CoreAudio AudioToolbox CoreVideo IOKit Carbon ForceFeedback -lobjc -lm` + `-weak_framework CoreHaptics GameController QuartzCore Metal`，否则 `objc_msgSend` 等符号全找不到 |
| 视频驱动（默认） | `windows` | `cocoa` |
| 硬件渲染器 | `direct3d` / `direct3d11` | `metal`（SDL 2.32 起，`opengl` 仍可用） |
| 无窗口会话 | 一般仍有 GDI 后端 | 只有 `dummy`；须 `SDL_VIDEODRIVER=dummy` |
| 加速后端缺失 | 少见 | `dummy` 驱动下 `SDL_RENDERER_ACCELERATED` **必然失败**，报 `Couldn't find matching render driver` → 必须写软件降级 |
| 超时命令 | 无内置 | 无 GNU `timeout`，需 MacPorts `gtimeout` |
| `SDL_PIXELFORMAT_RGBA32` | 小端 → `ABGR8888` | 小端 → `ABGR8888`（两平台相同；陷阱在大端机，别把它当固定内存布局） |

`sdl2-config --static-libs` 在本机的实际输出（`run-all.sh` 已把它留档进
`build/toolchain.txt` 的 `LIBS(static)` 行，可逐字节对账）：

```text
-L/opt/local/lib /opt/local/lib/libSDL2.a -lm -Wl,-framework,CoreAudio
-Wl,-framework,AudioToolbox -Wl,-weak_framework,CoreHaptics
-Wl,-weak_framework,GameController -Wl,-framework,ForceFeedback -lobjc
-Wl,-framework,CoreVideo -Wl,-framework,Cocoa -Wl,-framework,Carbon
-Wl,-framework,IOKit -Wl,-weak_framework,QuartzCore -Wl,-weak_framework,Metal
```

## 本次 macOS 校验发现并修复的问题

| # | 问题 | 归属 | 处理 |
|---|---|---|---|
| 1 | 目录只有 `build.ps1`，macOS 完全没有入口 | 教程结构 | 新增 `run-all.sh`（双通道 + 七条判定） |
| 2 | `02` 硬要 `SDL_RENDERER_ACCELERATED`，`dummy` 驱动下 `SDL_CreateRenderer` 返回 nullptr，示例 exit=1 | **示例问题** | 改成「拿不到加速就退到软件」的事实判断，并打印 `fellBackToSoftware` |
| 3 | `10` 的 `unique_ptr` 在 `SDL_Quit()` **之后**才析构 → 子系统已卸载后再 `DestroyWindow` | **示例问题**（跨平台） | `SDL_Quit()` 前显式 `reset()`；ASan/UBSan 实测未报错，但属未定义行为范围 |
| 4 | `06` 把随负载波动的 `frameTime`/`fps` 当主输出，无法逐字节比对 | 示例可验证性 | 区间内只放 `frameTargetMet`（跨机器恒真），实测值挪到区间外 `[观测]` 行 |
| 5 | 8 个示例没有任何 stdout，跑对了也无从验证 | 示例可验证性 | 全部加 `==== NN 开始/结束 ====` 区间，区间内放驱动名、渲染器名、返回码等稳定事实 |
| 6 | `05` 里 `SDL_RenderPresent` 返回 `void`，校验脚本自己写错被编译器抓住 | 示例/脚本 | 改用 `SDL_ClearError()` + `SDL_GetError()` 判成败 |
| 7 | 静态链接缺 frameworks（实测 `ld: symbol(s) not found`） | 环境差异 | 不手工拼，统一取 `sdl2-config --static-libs`，并写进本文件速查表 |
| 8 | 「`SDL_CreateThread` 之前要 `SDL_Init(SDL_INIT_TIMER)`」——SDL 1.2 的文档遗留被当成 SDL2 的规则沿用 | **文档问题** | 用 `SDL.h` 原文（threading 默认初始化）+ 三种初始化状态的实测纠正，见 [09 章 9.0](docs/09-threads-mutex.md) 的补充实验 |
| 9 | 正文是代码罗列：整份示例一次性贴出，讲解得回源码查 | 教程结构 | 按章拆分，讲解按片段引用进正文并逐行标号；核查新增第⑤关，把「示例的每一行代码都在正文里有出处」变成机器判定 |

对应正文：#2 → [02 章](docs/02-window-renderer.md)，#3 → [10 章](docs/10-raii-wrappers.md)，
#4 → [06 章](docs/06-timer-fps.md)，#5 → [12 章](docs/12-verification.md)，
#6 → [05 章](docs/05-draw-primitives.md)，#7 → [11 章](docs/11-platform-macos.md)，
#8 → [09 章](docs/09-threads-mutex.md)，#9 → 全部章节 + `tools/check_docs.py`。

未在本机验证、需要在真机确认的三个点（纯 SSH 会话下的 `cocoa` 驱动、Windows/MSVC
实跑结果、Apple Silicon arm64），逐条说明见 [11 章 11.5 节](docs/11-platform-macos.md)。
