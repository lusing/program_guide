# SDL2 编程指南示例集

SDL2 C++ 教程与可编译示例。示例本身是跨平台代码（只用 SDL2 公共 API +
`SDL_MAIN_HANDLED`），两个构建入口分别覆盖 Windows/MSVC 与 macOS/Linux/clang。

## 目录结构

<!-- 目录结构示意，非运行输出 -->
```text
sdl2/
├── README.md              本文件：工具链 + 验证状态 + 平台差异
├── SDL2编程指南.md        教程正文（11 章，章号 = 示例号）
├── CHEATSheet.md          语法速查 + 实测坑位索引
├── run-all.sh             验证入口（shell 版：macOS / Linux）
├── build.ps1              验证入口（PowerShell 版：Windows / MSVC）
├── tools/
│   └── check_docs.py      文档机器核查（章节↔示例 / 输出引用 / 坑位数）
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

## 构建工具链

### macOS（本机实测）

| 项 | 值 |
|---|---|
| 编译器 | Apple clang 16.0.0（`x86_64-apple-darwin23.6.0`，Xcode CLT） |
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

## 验证状态

**macOS（Darwin 23.6 x86_64，Apple clang 16.0.0 + SDL2 2.32.10，2026-09-22 实测）**

| 场景 | 结果 |
|---|---|
| `./run-all.sh`（shared + static 双通道） | **10 示例 × 2 通道 = 20/20 通过** |
| `SDL_VIDEODRIVER=dummy ./run-all.sh --one`（无窗口会话） | **10/10 通过** |
| `-Wall -Wextra` 编译告警 | 0 条（编译期 stderr 非空即判失败） |

Windows/MSVC 侧：本机无 MSVC，`build.ps1` 只做了 PowerShell 语法解析通过，
**未实跑**，其判定逻辑与 `run-all.sh` 逐条对齐（详见文件头注释）。

判定标准（两个入口共用，shell 版多一条双通道比对）：

1. 编译退出码 0，且编译期 stderr 为空
2. 运行退出码 0
3. 运行 stderr 为空
4. stdout 里同时出现 `==== NN 开始 ====` 与 `==== NN 结束 ====`
5. 两标记之间的区间非空，且不含控制字符
6. 同一通道连跑两次，区间逐字节一致
7. **（仅 shell 版）** shared 与 static 两条通道的区间逐字节一致

第 7 条的存在理由：两个产物由同一份源码编译，比对不是为了验证两种语义，
而是检验**示例没有偷偷依赖动态库加载或安装前缀**。

## 平台差异速查（macOS ↔ Windows）

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

`sdl2-config --static-libs` 在本机的实际输出（供对照）：

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

未在本机验证、需要在真机确认的点：

- **纯 SSH（无 GUI 会话）下 `cocoa` 驱动的行为**：推断会 `SDL_Init(SDL_INIT_VIDEO)` 失败
  （拿不到 WindowServer 连接），本机始终在 GUI 会话中，无法制造该场景。CI 请
  直接设 `SDL_VIDEODRIVER=dummy`（已验证 10/10 通过）。
- **Windows/MSVC 的实际运行结果**：本机无 MSVC，仅保证 `build.ps1` 语法与判定逻辑对齐。
- **Apple Silicon（arm64）**：本机为 x86_64，未做交叉验证；示例不含任何架构相关代码，
  理论上可直接编译，但需真机确认。
