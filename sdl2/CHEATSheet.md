# SDL2 速查 + 实测坑位索引

编译运行入口：`./run-all.sh`（macOS/Linux，双通道）、`.\build.ps1 -All`（Windows/MSVC）。
判定标准见 [README.md](./README.md)「验证状态」节。

本文件共收录 **22 条实测坑位**，与 [SDL2编程指南.md](./SDL2编程指南.md) 各章末尾
「坑位清单」的编号 **1–22 一一对应**（下表的「指南」列标出所在章）。

## 一、构建与链接

| # | 坑位 | 指南 |
|---|---|---|
| 1 | 定义了 `SDL_MAIN_HANDLED` 又链接 `SDL2main`：macOS 上 `SDL2main` 会接管入口，行为取决于链接顺序 | 2 |
| 4 | macOS 静态链接 `libSDL2.a` 不带系统依赖，缺 frameworks 直接 `ld: symbol(s) not found for architecture x86_64`；用 `sdl2-config --static-libs` | 3 |
| 13 | macOS 没有 GNU `timeout`，只有 MacPorts `gtimeout`；脚本探测顺序要 `gtimeout` → `timeout` | 7 |

静态链接的完整参数（本机 `sdl2-config --static-libs` 实测，留档见 `build/toolchain.txt`）：

<!-- 命令输出，非示例运行输出 -->
```text
-L/opt/local/lib /opt/local/lib/libSDL2.a -lm -Wl,-framework,CoreAudio
-Wl,-framework,AudioToolbox -Wl,-weak_framework,CoreHaptics
-Wl,-weak_framework,GameController -Wl,-framework,ForceFeedback -lobjc
-Wl,-framework,CoreVideo -Wl,-framework,Cocoa -Wl,-framework,Carbon
-Wl,-framework,IOKit -Wl,-weak_framework,QuartzCore -Wl,-weak_framework,Metal
```

## 二、窗口与渲染器

| # | 坑位 | 指南 |
|---|---|---|
| 3 | 无条件要 `SDL_RENDERER_ACCELERATED`：`dummy` 驱动下必然失败（`Couldn't find matching render driver`），必须写软件降级 | 3 |
| 5 | 把 `SDL_RendererInfo.name` 写进断言：macOS=`metal`、Windows=`direct3d*`、Linux=`opengl`，应断言 `accelerated` 语义位 | 3 |
| 6 | 纯 SSH（无 GUI 会话）跑视频示例：`cocoa` 拿不到 WindowServer 连接。**本机未实测**，CI 用 `SDL_VIDEODRIVER=dummy` | 4 |
| 7 | 只靠 `SDL_QUIT` 事件退出：脚本环境没人点关闭，要有计数兜底 | 4 |
| 10 | `SDL_RenderPresent` 返回 `void`，不能用返回值判成败；要 `SDL_ClearError()` → 调用 → 查 `SDL_GetError()` | 6 |
| 11 | 绘制函数失败时返回负数但**未必**设置错误串；按批次判返回值比逐个查错误实际 | 6 |

## 三、像素格式与 Surface

| # | 坑位 | 指南 |
|---|---|---|
| 8 | `SDL_PIXELFORMAT_RGBA32` / `ARGB32` 是**字节序相关别名**，小端解析成 `ABGR8888`；要固定布局写 `*_8888` 精确名 | 5 |
| 9 | Surface / Texture 生命周期混淆：上传完可 `SDL_FreeSurface`，Texture 归渲染器管要 `SDL_DestroyTexture`，且都在 `SDL_Quit()` 前 | 5 |

## 四、计时与输入

| # | 坑位 | 指南 |
|---|---|---|
| 2 | 拿 `SDL_GetVersion()` 当编译期版本断言：它报运行时库版本，与头文件可能不一致 | 2 |
| 12 | 把实测帧长 / fps 当回归断言：本机连跑两次就 17~19ms 抖动，字节比对必然偶发失败 | 7 |
| 14 | 把 `leftPressed=0` 当成 macOS 拿不到键盘：那只是「没人按键」的事实，`entries` 恒为 512 | 8 |
| 15 | 忘了 `SDL_PumpEvents()`：`SDL_GetKeyboardState` 不会自己去收事件 | 8 |

## 五、音频

| # | 坑位 | 指南 |
|---|---|---|
| 16 | 假设 `obtained == desired`：驱动有权改 `freq`/`channels`/`samples`，回调里要按 `obtained.freq` 算相位 | 9 |
| 17 | 把设备名（`Built-in Output`）写进断言：随机器变化，只做观测 | 9 |
| 18 | 在音频回调里加锁/分配/IO：回调跑在音频线程，超时会爆音；用环形缓冲 + 原子下标 | 9 |

## 六、线程与 RAII

| # | 坑位 | 指南 |
|---|---|---|
| 19 | 用 `SDL_Delay` 等线程结束而不是 `SDL_WaitThread`：没有同步语义，结果依赖调度 | 10 |
| 20 | 失败分支只 `SDL_WaitThread` 了部分线程：漏掉返回状态、可能悬空 mutex | 10 |
| 21 | 以为 `unique_ptr` 保证释放顺序：它只保证「最终释放」，不保证「在 `SDL_Quit()` 之前」 | 11 |
| 22 | 自定义 deleter 只挡空指针不够：顺序错了照样踩已卸载的子系统 | 11 |

<!-- API 速查表，非运行输出 -->
```text
初始化/退出    SDL_SetMainReady / SDL_Init / SDL_WasInit / SDL_Quit
版本          SDL_GetVersion（运行时） · SDL_VERSION / SDL_COMPILEDVERSION（编译期）
错误          SDL_GetError / SDL_ClearError
窗口          SDL_CreateWindow / SDL_DestroyWindow / SDL_WINDOW_HIDDEN
渲染器        SDL_CreateRenderer / SDL_GetRendererInfo / SDL_GetCurrentVideoDriver
绘制          SDL_SetRenderDrawColor / SDL_RenderClear / SDL_RenderDrawLine
              SDL_RenderFillRect / SDL_RenderPresent（返回 void）
Surface       SDL_CreateRGBSurfaceWithFormat / SDL_FillRect / SDL_FreeSurface
Texture       SDL_CreateTextureFromSurface / SDL_QueryTexture / SDL_DestroyTexture
计时          SDL_GetTicks / SDL_Delay
键盘          SDL_PumpEvents / SDL_GetKeyboardState
音频          SDL_OpenAudioDevice / SDL_CloseAudioDevice / SDL_GetAudioDeviceName
线程          SDL_CreateThread / SDL_WaitThread / SDL_CreateMutex / SDL_LockMutex
```

## 本机实测快照（Darwin 23.6 x86_64 · Apple clang 16.0.0 · SDL2 2.32.10）

下面几行都能在 `build/shared/*.sec1` 里逐字节找到（`videoDriver` 的默认值为
`cocoa`；`dummy` 驱动下同一份二进制会走到 software 后端）：

```text
videoDriver=cocoa
rendererName=metal
surfaceFormat=SDL_PIXELFORMAT_ABGR8888
deviceOpened=1, freq=48000, channels=1, samples=1024
counter=2000
```
