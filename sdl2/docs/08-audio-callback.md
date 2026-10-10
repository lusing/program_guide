# 08 · 音频回调模型：desired/obtained 与打开后的暂停态

> 对应示例：[examples/08_audio_callback.cpp](../examples/08_audio_callback.cpp)

SDL2 的音频是**推式回调**模型：你交一个函数指针给驱动，驱动在它的音频线程里按固定节拍调你，每次要你填满一段缓冲。这个模型只有三个陷阱位（协商、线程、启动），但每一个都会炸得很响：协商错了音高跑偏，线程里阻塞会爆音，忘了"打开即暂停"则一声不响。本章示例生成 440Hz 正弦、打开默认输出设备、打印协商结果——并且**故意不播放**，用来把第三条陷阱讲清楚。

## 8.0 本章示例的骨架

```cpp
// ═══ 8.0 骨架：只开 AUDIO；回调本体在 main 之前定义 ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <cmath>
#include <cstring>
#include <iostream>

// ……（ToneState 与 AudioCallback 的源码见 8.1）……

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_AUDIO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }
```

骨架三行见 [01 章](01-init-version.md)。本章的子系统位是 `SDL_INIT_AUDIO`，与视频侧完全无关——所以 `SDL_VIDEODRIVER=dummy` 不影响它。反过来 `SDL_AUDIODRIVER=dummy` 会让它走"无声但照样跑"的通路：本机实测那条路径下打开与协商一字不差（`deviceOpened=1, freq=48000, channels=1, samples=1024`），只有设备名那行观测会变（8.4 有对照）。两个额外头文件是给回调本体的：`<cmath>` 提供 `std::sin`，`<cstring>` 提供 `std::memset`。

## 8.1 回调签名与它的三段活

```cpp
// ═══ 8.1 回调：SDLCALL 不能省，stream 是驱动给的缓冲 ═══
struct ToneState {
    double phase = 0.0;
    double step = 2.0 * 3.141592653589793 * 440.0 / 48000.0;
};

void SDLCALL AudioCallback(void* userdata, Uint8* stream, int len) {
    auto* tone = static_cast<ToneState*>(userdata);
    std::memset(stream, 0, static_cast<size_t>(len));
    auto* out = reinterpret_cast<int16_t*>(stream);
    int sampleCount = len / static_cast<int>(sizeof(int16_t));
    for (int i = 0; i < sampleCount; ++i) {
        out[i] = static_cast<int16_t>(std::sin(tone->phase) * 2000.0);
        tone->phase += tone->step;
        if (tone->phase > 2.0 * 3.141592653589793) {
            tone->phase -= 2.0 * 3.141592653589793;
        }
    }
}
```

三点要钉住：

- **`SDLCALL`** 是调用约定宏（`__cdecl`/`__stdcall`/x64 下为空）。回调是 SDL（甚至可能是另一个 DLL）来调你的函数，跨编译单元时约定不一致会栈错——在 Windows/MSVC 上尤其不是装饰性写法。
- **`stream` 是驱动分配的缓冲，`len` 是字节数**，不是样本数。本例 `desired.format = AUDIO_S16SYS`、单声道，所以样本数 = `len / sizeof(int16_t)`。换格式（`AUDIO_F32`、立体声）时这个换算必须跟着改，"先 memset 再按格式 reinterpret"是通用套路。
- **`userdata` 是唯一的上下文通道**，回调没有别的地方可以拿状态。本例传 `&tone`（指向 `main` 栈上的对象），成立的前提是设备在 `tone` 销毁前关闭——记住这条生命周期，8.4 会回收它。

关于 `ToneState::step` 里那个 `48000.0`：它是本章故意留下的靶子。为什么在本例里它是安全的、以及在真实程序里它为什么不安全，8.3 用协商语义解释。

## 8.2 想要什么：`SDL_AudioSpec` 的五个字段

```cpp
// ═══ 8.2 desired：格式/采样率/声道/每次回调的样本数 + 回调本体 ═══
    ToneState tone{};
    SDL_AudioSpec desired{};
    desired.freq = 48000;
    desired.format = AUDIO_S16SYS;
    desired.channels = 1;
    desired.samples = 1024;
    desired.callback = AudioCallback;
    desired.userdata = &tone;
```

| 字段 | 含义 | 备注 |
|---|---|---|
| `freq` | 采样率 | 常见 44100/48000 |
| `format` | 样本格式 | `AUDIO_S16SYS` = 本机字节序的有符号 16 位；还有 `AUDIO_F32`、`AUDIO_S8` 等 |
| `channels` | 声道数 | 1 单声道、2 立体声 |
| `samples` | **每次回调**要的样本数 | 决定延迟与爆音余量的权衡：小=低延迟高开销，大=反之 |
| `callback`/`userdata` | 回调与上下文 | 见 8.1 |

`AUDIO_S16SYS` 的"SYS"是**本机字节序**，跨端设备（网络音频、大端目标）要显式 `AUDIO_S16LSB`/`AUDIO_S16MSB`——与 04 章 `SDL_PIXELFORMAT_RGBA32` 是同一类字节序陷阱，SDL 在两个子系统里各留了一个。

## 8.3 拿到什么：`desired` 只是请求

```cpp
// ═══ 8.3 打开设备：第 5 个参数 allowed_changes 传 0 = 一项都不许改 ═══
    SDL_AudioSpec obtained{};
    SDL_AudioDeviceID dev = SDL_OpenAudioDevice(nullptr, 0, &desired, &obtained, 0);
    if (dev == 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }
```

`SDL_OpenAudioDevice(device, iscapture, desired, obtained, allowed_changes)`：

- `device = nullptr` → 系统默认输出（`"0"` 是第一个设备；`iscapture=1` 变输入设备）；
- `obtained` 回填**实际生效**的规格；
- `allowed_changes` 是位掩码，声明哪些字段可以让驱动改：`SDL_AUDIO_ALLOW_FREQUENCY_CHANGE`/`FORMAT_CHANGE`/`CHANNELS_CHANGE`/`SAMPLES_CHANGE`，或 `SDL_AUDIO_ALLOW_ANY_CHANGE`。

**本例传 `0`，语义是"四个字段一个都不许改"**：驱动无法满足 `desired` 时直接返回 `0`（错误串通常是 `Couldn't find compatible audio device`）。这带来一个有用的推论——`dev != 0` 成立就意味着 `obtained` 与 `desired` **逐字段相等**，所以 8.1 里写死的 `48000.0` 在本例是安全的（实测输出正是 `freq=48000, channels=1, samples=1024`）。

一旦你允许改动（生产代码通常允许 `ANY_CHANGE`），写死的采样率立刻变成 bug：相位步进 `step = 2π·f/sr` 里的 `sr` 必须换成 `obtained.freq`，否则在 44100 的设备上，440Hz 会被播成约 404Hz（440 × 44100/48000）。更稳的写法是打开后**用 `obtained` 反推状态**：把 `tone.step` 在 `SDL_OpenAudioDevice` 返回后按 `obtained.freq` 重算，再启动设备——8.4 的实测输出就是这个协商过程的证据。

顺带：`SDL_AudioSpec` 在 2.0.x 里对回调式和队列式（`SDL_QueueAudio`）复用，队列式不用填 `callback`。不想自己管缓冲的话，`SDL_OpenAudioDevice` + `SDL_QueueAudio` + `SDL_DequeueAudio` 是更省心的路（本教程聚焦回调模型，队列式未做示例）。

## 8.4 观测与协商证据，以及那个"没人听见"的设计

```cpp
// ═══ 8.4 区间内只放协商结果；设备名随机器变，放区间外 ═══
    std::cout << "==== 08 开始 ====\n";
    std::cout << "deviceOpened=" << (dev > 0)
              << ", freq=" << obtained.freq
              << ", channels=" << static_cast<int>(obtained.channels)
              << ", samples=" << obtained.samples << '\n';
    std::cout << "==== 08 结束 ====\n";
    std::cout << "[观测] 默认输出设备: " << SDL_GetAudioDeviceName(0, 0) << '\n';

    SDL_CloseAudioDevice(dev);
    SDL_Quit();
    return 0;
}
```

`build/shared/08_audio_callback.run1`：

```text
==== 08 开始 ====
deviceOpened=1, freq=48000, channels=1, samples=1024
==== 08 结束 ====
[观测] 默认输出设备: Built-in Output
```

**这个示例从头到尾没有发出一点声音**，而且这是刻意的：`SDL_OpenAudioDevice` 打开的设备处于**暂停态**，头文件写得很明确——"Newly-opened audio devices start in the paused state"，暂停期间驱动写静音、**回调保证一次都不被调用**。要真的播放必须 `SDL_PauseAudioDevice(dev, 0)`。本例只验证"协商是否成立、句柄能否打开"，所以停在暂停态最干净：不产生音频占用、不依赖声卡实际节拍，输出完全确定。

音频侧换成 dummy 后端再跑一遍（`SDL_AUDIODRIVER=dummy ./build/shared/08_audio_callback`），**区间四行逐字节相同**——这条对照正是"区间里只放跨后端恒真的量"的实证：

```text
==== 08 开始 ====
deviceOpened=1, freq=48000, channels=1, samples=1024
==== 08 结束 ====
```

变的只有区间外那行观测：coreaudio 报 `Built-in Output`，dummy 报 `System audio output device`。也就是说 `SDL_OpenAudioDevice(nullptr, ...)` 在 dummy 后端下照样打开、照样按请求的参数完成协商，只是不发声。这个差异要是写进断言，回归就会因为后端不同而随机变红；放在观测行里，它反而把"换了后端、没换协商结果"这件事摆到了眼前。

这条暂停语义反过来也有价值：它给了你一个安全窗口，在启动前初始化 `userdata` 指向的状态（比如按 `obtained.freq` 重算 `step`）而不用担心回调已经在跑。临时保护共享变量别用暂停（会造成 dropout），用 `SDL_LockAudioDevice`/`SDL_UnlockAudioDevice`。

"打开 → 初始化状态 → `SDL_PauseAudioDevice(dev, 0)` → 播放中改状态要锁 → `SDL_CloseAudioDevice`"就是回调式的完整生命周期；本例走的是前两步加关闭，中间那段留给需要真实音频的程序。

## 8.5 回调线程的纪律

回调运行在 SDL（或后端）的音频线程上，不是你的主线程。三条硬规矩：

- **不许阻塞**：不加互斥锁等主线程、不做 IO、不分配/释放堆（首次分配可能连带触发系统调用）。超时就是爆音（缓冲没填满）。
- **不许直接碰渲染器/窗口**：02 章那些句柄归主线程。要传数据就准备**环形缓冲**，音频线程只读写原子下标。
- **`SDL_CloseAudioDevice` 会等回调收尾**：关闭之后 `userdata` 指向的对象才安全销毁。本例 `tone` 在 `main` 栈上、`SDL_CloseAudioDevice(dev)` 在 `return` 之前，正好符合；反过来说，把 `tone` 换成堆对象却在关闭前析构，就是 use-after-free。

09 章会把"跨线程共享一个变量并加锁"做成可验证的示例，那正是这里环形缓冲的最小原型。

## 坑位清单

24. **假设 `obtained` 一定等于 `desired`**：驱动有权改 `freq`/`channels`/`samples`（除非 `allowed_changes` 传 `0`，本例正是这种严格协商，所以 `dev != 0` 蕴含两者相等）。一旦允许改动，回调里的相位步进必须按 `obtained.freq` 算——写死 48000 在 44100 的设备上音高直接跑偏。
25. **把设备名写进断言**：`Built-in Output` 取决于机器插了什么声卡/显示器/USB 音频，甚至插个耳机就变；换音频后端也会变（本机实测 `SDL_AUDIODRIVER=dummy` 下是 `System audio output device`）。只做观测，放区间外——区间内的 `deviceOpened`/`freq`/`channels`/`samples` 才是两边一致的量。
26. **在回调里加锁、分配、做 IO**：回调在音频线程上，超时就爆音。跨线程传数据用环形缓冲 + 原子下标；要保护变量用 `SDL_LockAudioDevice`，不要用 `SDL_PauseAudioDevice` 当锁（会造成 dropout）。
27. **以为 `SDL_OpenAudioDevice` 之后就在播放**：新打开的设备在**暂停态**，暂停期间回调保证不被调用（头文件原文）。要出声必须 `SDL_PauseAudioDevice(dev, 0)`；本例不播放，正是靠这条语义把输出做成完全确定的。
28. **`allowed_changes` 传 `0` 又指望自动适配**：`0` 是"一项都不许改"，设备不兼容时 `SDL_OpenAudioDevice` 直接返回 `0`（`Couldn't find compatible audio device`）。要宽适配请传 `SDL_AUDIO_ALLOW_ANY_CHANGE`，然后**按 `obtained` 重新准备所有依赖格式的换算**（含样本数、声道交织、字节序）。

---

上一章：[07 · 键盘输入状态：状态表、PumpEvents 与那个 512](07-keyboard-state.md) ｜ 下一章：[09 · 线程与互斥锁：让 `counter=2000` 成为确定性断言](09-threads-mutex.md) ｜ 返回：[README](../README.md)
