# SDL2 速查 + 实测坑位索引

编译运行入口：`./run-all.sh`（macOS/Linux，双通道）、`.\build.ps1 -All`（Windows/MSVC）。
判定标准见 [12 章 · 统一编译验证](docs/12-verification.md) 与 [README.md](README.md)「验证状态」节。

本文件共收录 **40 条实测坑位**，编号 1–40 与各章末「坑位清单」**一一对应**；
「章」列标出所在章并给出链接。章号 01–10 与示例同号，11/12 是工程侧两章。

## 一、初始化与错误约定（01 章）

| # | 坑位 | 章 |
|---|---|---|
| 1 | 定义了 `SDL_MAIN_HANDLED` 又链接 `SDL2main`：macOS 上 `SDL2main` 会接管入口，行为取决于链接顺序 | [01](docs/01-init-version.md) |
| 2 | 拿 `SDL_GetVersion()` 当编译期版本断言：它报运行时库版本，与头文件可能不一致（编译期用 `SDL_COMPILEDVERSION`） | [01](docs/01-init-version.md) |
| 3 | 把 `SDL_GetError()` 非空当"本次调用失败"：成功路径不清空错误串，返回的又是指向静态缓冲区的指针 | [01](docs/01-init-version.md) |

## 二、窗口与渲染器（02 章）

| # | 坑位 | 章 |
|---|---|---|
| 4 | 无条件要 `SDL_RENDERER_ACCELERATED`：`dummy` 驱动下必然失败（`Couldn't find matching render driver`），必须写软件降级 | [02](docs/02-window-renderer.md) |
| 5 | 只请求 `ACCELERATED` 却指望自带 vsync：请求位是 AND 语义，且没请求的位不会白给（实测 `gotFlags=10` 不含 `PRESENTVSYNC`） | [02](docs/02-window-renderer.md) |
| 6 | `SDL_CreateRenderer` 的 index 写死 `0`：`-1` 才是"任选"，`0` 是该平台枚举出的第 0 个驱动，跨平台含义不同 | [02](docs/02-window-renderer.md) |
| 7 | 把 `SDL_RendererInfo.name` 写进断言：macOS=`metal`、Windows=`direct3d*`、Linux=`opengl`，应断言 `accelerated` 语义位 | [02](docs/02-window-renderer.md) |

## 三、事件循环（03 章）

| # | 坑位 | 章 |
|---|---|---|
| 8 | 只靠 `SDL_QUIT` 事件退出：脚本环境没人点关闭（示例窗口还是 `HIDDEN`），要有计数或任务完成度兜底 | [03](docs/03-event-loop.md) |
| 9 | `if (SDL_PollEvent(&e))` 单条消费：一帧只处理一条事件，输入滞后；内层要 `while (... == 1)` 排空 | [03](docs/03-event-loop.md) |
| 10 | 纯 SSH（无 GUI 会话）跑视频示例：`cocoa` 拿不到 WindowServer 连接。**本机未实测**，CI 用 `SDL_VIDEODRIVER=dummy` | [03](docs/03-event-loop.md) |

## 四、像素格式与 Surface（04 章）

| # | 坑位 | 章 |
|---|---|---|
| 11 | `SDL_PIXELFORMAT_RGBA32` / `ARGB32` 是**字节序相关别名**，小端解析成 `ABGR8888`（04 章实测输出为证）；要固定布局写 `*_8888` | [04](docs/04-surface-texture.md) |
| 12 | Surface / Texture 生命周期混淆：上传完可 `SDL_FreeSurface`，Texture 归渲染器管要 `SDL_DestroyTexture`，且都在 `SDL_Quit()` 前 | [04](docs/04-surface-texture.md) |
| 13 | 手动读写像素按 `w*4` 跳行：一行的真实字节数是 `surface->pitch`（对齐补白）；`SDL_MapRGBA` 属于 Surface 侧，渲染器用 `SDL_SetRenderDrawColor` | [04](docs/04-surface-texture.md) |

## 五、绘制 API（05 章）

| # | 坑位 | 章 |
|---|---|---|
| 14 | `SDL_RenderPresent` 返回 `void`，不能用返回值判成败；要 `SDL_ClearError()` → 调用 → 查 `SDL_GetError()` | [05](docs/05-draw-primitives.md) |
| 15 | 绘制函数失败时返回负数但**未必**设置错误串；按批次判返回值比逐个查错误实际 | [05](docs/05-draw-primitives.md) |
| 16 | 以为 `SDL_RenderPresent` 会顺带清屏：`SDL_RenderClear` 每帧要显式调用；混合也要显式 `SDL_SetRenderDrawBlendMode` | [05](docs/05-draw-primitives.md) |

## 六、计时与帧率（06 章）

| # | 坑位 | 章 |
|---|---|---|
| 17 | 把实测帧长 / fps 当回归断言：本机连跑几次就是 16~19ms 的抖动，字节比对必然偶发失败 | [06](docs/06-timer-fps.md) |
| 18 | `SDL_GetTicks()` 是 `Uint32`，49.7 天回绕：差值靠无符号减法尚且安全，`now > deadline` 这类比较必错；长期运行用 `SDL_GetTicks64()` | [06](docs/06-timer-fps.md) |
| 19 | macOS 没有 GNU `timeout`，只有 MacPorts `gtimeout`；脚本探测顺序要 `gtimeout` → `timeout` | [06](docs/06-timer-fps.md) |

## 七、键盘输入（07 章）

| # | 坑位 | 章 |
|---|---|---|
| 20 | 把 `leftPressed=0` 当成平台拿不到键盘：那只是"没人按键"的事实，`entries` 恒为 512 | [07](docs/07-keyboard-state.md) |
| 21 | 忘了 `SDL_PumpEvents()`：`SDL_GetKeyboardState` 不会自己去收事件 | [07](docs/07-keyboard-state.md) |
| 22 | 把 `out_numkeys` 当"按下的键数"（它是数组长度）；返回的指针是 SDL 内部表不要释放；下标要用 `SDL_Scancode` 而非 `SDL_Keycode` | [07](docs/07-keyboard-state.md) |
| 23 | 用 `SDL_PushEvent` 注入按键"模拟按住"：实测事件能被 `SDL_PollEvent` 取到，但状态表仍是 0——注入只喂队列，不喂状态表 | [07](docs/07-keyboard-state.md) |

## 八、音频（08 章）

| # | 坑位 | 章 |
|---|---|---|
| 24 | 假设 `obtained == desired`：驱动有权改 `freq`/`channels`/`samples`，回调里要按 `obtained.freq` 算相位 | [08](docs/08-audio-callback.md) |
| 25 | 把设备名（`Built-in Output`）写进断言：随机器变化，只做观测 | [08](docs/08-audio-callback.md) |
| 26 | 在音频回调里加锁/分配/IO：回调跑在音频线程，超时即爆音；跨线程用环形缓冲 + 原子下标，保护变量用 `SDL_LockAudioDevice` 而不是暂停 | [08](docs/08-audio-callback.md) |
| 27 | 以为 `SDL_OpenAudioDevice` 之后就在播放：新设备处于**暂停态**，暂停期间回调保证不被调用，要 `SDL_PauseAudioDevice(dev, 0)` | [08](docs/08-audio-callback.md) |
| 28 | `allowed_changes` 传 `0` 又指望自动适配：`0` 是"一项都不许改"，不兼容直接返回 0；要宽适配传 `ANY_CHANGE` 并按 `obtained` 重算所有换算 | [08](docs/08-audio-callback.md) |

## 九、线程与锁（09 章）

| # | 坑位 | 章 |
|---|---|---|
| 29 | 用 `SDL_Delay` 等线程结束而不是 `SDL_WaitThread`：没有同步语义，结果依赖调度 | [09](docs/09-threads-mutex.md) |
| 30 | 创建失败分支只 `SDL_WaitThread` 了部分线程、或不等就 `SDL_DestroyMutex`：漏返回状态，还会销毁仍被持有的锁 | [09](docs/09-threads-mutex.md) |
| 31 | `SDL_TryLockMutex` 用 `< 0` 判失败：它返回 `0` / `SDL_MUTEX_TIMEDOUT`（=1，正数）/ `-1`；另外非属主线程 `SDL_UnlockMutex` 是未定义行为 | [09](docs/09-threads-mutex.md) |

## 十、C++ RAII（10 章）

| # | 坑位 | 章 |
|---|---|---|
| 32 | 以为 `unique_ptr` 保证释放顺序：它只保证"最终释放"，不保证"在 `SDL_Quit()` 之前"，凡有全局 init/quit 语义的库都有此坑 | [10](docs/10-raii-wrappers.md) |
| 33 | 只给 deleter 加判空就当安全：顺序错了照样踩已卸载的子系统；deleter 里抛异常等于给析构路径埋 `std::terminate` | [10](docs/10-raii-wrappers.md) |
| 34 | 把拥有权交给 C API（`.release()`），或把值句柄 `SDL_AudioDeviceID` 硬塞 `unique_ptr`：前者放弃 RAII 立刻泄漏，后者类型不合，要写 scope guard | [10](docs/10-raii-wrappers.md) |

## 十一、构建与链接（11 章）

| # | 坑位 | 章 |
|---|---|---|
| 35 | macOS 静态链接 `libSDL2.a` 不带系统依赖，缺 frameworks 直接 `ld: symbol(s) not found for architecture x86_64`；用 `sdl2-config --static-libs` | [11](docs/11-platform-macos.md) |
| 36 | 把 `-weak_framework` 改成 `-framework`：`CoreHaptics`/`GameController`/`QuartzCore`/`Metal` 在旧系统可能不存在，弱链接才保证"缺了也能跑" | [11](docs/11-platform-macos.md) |
| 37 | 硬编码安装前缀或漏 `--cflags` 的 `-D_THREAD_SAFE`：MacPorts `/opt/local`、Homebrew `/usr/local` 或 `/opt/homebrew`；一律探测 `sdl2-config`/`pkg-config` | [11](docs/11-platform-macos.md) |

## 十二、验证协议（12 章）

| # | 坑位 | 章 |
|---|---|---|
| 38 | 把 `[观测]` 类漂移量写进比对区间：判定第 6 条（两跑逐字节一致）偶发红，且"在你机器上是绿的"，最难查 | [12](docs/12-verification.md) |
| 39 | 只判退出码就宣布通过：必须再要求区间非空且无控制字符（"退出 0 但什么都不打印"曾经覆盖 8 个示例） | [12](docs/12-verification.md) |
| 40 | 不设运行超时跑回归：卡在 `SDL_WaitEvent` 或等键盘的示例会挂住整条链；`gtimeout`/`timeout` 各给 20 秒上限 | [12](docs/12-verification.md) |

## API 速查

<!-- API 速查表，非运行输出 -->
```text
初始化/退出    SDL_SetMainReady / SDL_Init / SDL_WasInit / SDL_Quit
版本          SDL_GetVersion（运行时） · SDL_VERSION / SDL_COMPILEDVERSION（编译期）
错误          SDL_GetError / SDL_ClearError
窗口          SDL_CreateWindow / SDL_DestroyWindow / SDL_WINDOW_HIDDEN
渲染器        SDL_CreateRenderer / SDL_GetRendererInfo / SDL_GetCurrentVideoDriver
后端枚举      SDL_GetNumVideoDrivers / SDL_GetVideoDriver
              SDL_GetNumAudioDrivers / SDL_GetAudioDriver
              SDL_GetNumRenderDrivers / SDL_GetRenderDriverInfo
绘制          SDL_SetRenderDrawColor / SDL_RenderClear / SDL_RenderDrawLine
              SDL_RenderFillRect / SDL_RenderPresent（返回 void）
Surface       SDL_CreateRGBSurfaceWithFormat / SDL_FillRect / SDL_FreeSurface
Texture       SDL_CreateTextureFromSurface / SDL_QueryTexture / SDL_DestroyTexture
事件          SDL_PollEvent / SDL_WaitEventTimeout / SDL_PushEvent / SDL_QUIT
计时          SDL_GetTicks / SDL_GetTicks64 / SDL_Delay
键盘          SDL_PumpEvents / SDL_GetKeyboardState / SDL_GetModState
音频          SDL_OpenAudioDevice / SDL_PauseAudioDevice / SDL_CloseAudioDevice
              SDL_GetAudioDeviceName / SDL_LockAudioDevice
线程          SDL_CreateThread / SDL_WaitThread / SDL_DetachThread
              SDL_CreateMutex / SDL_LockMutex / SDL_TryLockMutex
同步          SDL_CreateSemaphore / SDL_CreateCond
```

## 本机实测快照（Darwin 24.6 x86_64 · Apple clang 17.0.0 · SDL2 2.32.10）

下面几行都能在 `build/shared/*.run1` / `build/dummy-driver-02.out` 里逐字节找到：

```text
Linked SDL version: 2.32.10
videoDriver=cocoa
rendererName=metal
videoDriver=dummy
rendererName=software
surfaceFormat=SDL_PIXELFORMAT_ABGR8888
deviceOpened=1, freq=48000, channels=1, samples=1024
counter=2000
```
