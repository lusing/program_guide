# 24 · 音频与视频：AVFoundation 的播放、录制、读写与合成

> 示例：`examples/24_audio_video/main.swift`
> 实测输出见 `build/24_audio_video/stdout.debug.txt`

第 19 章只用过 AVFoundation 的一件事——申请麦克风权限；第 23 章把「画面为什么会动」讲到了
`CALayer` 这一层。这一章把音视频那条链路整条走完，一共 17 节：

```
素材        §1  AVAudioFile 现场写一段 PCM wav（不依赖任何随仓库分发的二进制文件）
生命周期    §2  同一个文件：写入对象还活着时播不出来，释放之后才读得到时长
本地播放    §3  AVAudioPlayer —— 一次性把整个文件交给它，属性全是同步可读的
会话        §4  AVAudioSession：category / mode / options / 路由 / 打断，所有音频行为的总开关
录制        §5  AVAudioRecorder：prepareToRecord 与 record 是两个时刻
时间        §6  CMTime / CMTimeRange / CMTimeFlags —— AVFoundation 的地基，必须先吃透
合成视频    §7  AVAssetWriter + AVAssetWriterInputPixelBufferAdaptor 现场造一段 mp4
播放状态机  §8  AVPlayer / AVPlayerItem：状态、seek、时间观察者、KVO（排在所有 await 之前）
播放界面    §9  AVPlayerViewController、AVPlayerLayer、画中画能力查询
资产        §10 AVAsset 的「同步旧读法」与「try await 新读法」，以及 §8 为什么要抢跑
解码        §11 AVAssetReader 把文件解成 sample buffer
转码        §12 reader → writer 一条管线把 wav 压成 m4a
导出        §13 AVAssetExportSession：档位、兼容容器
抓帧        §14 AVAssetImageGenerator：缩略图
引擎        §15 AVAudioEngine 的手动（offline）渲染、混音增益、调度
效果器      §16 五个内置 AVAudioUnit + AVAudioConverter
系统联动    §17 MediaPlayer：锁屏信息、远端命令、音乐播放器、媒体库、音量控件
```

## 本章的方法：headless 环境怎么拿到确定的数字

本仓库的示例用 `xcrun simctl spawn` 直接跑一个可执行文件：没有扬声器、没有触摸、
没有肉眼可看的画面。这一章偏偏全是「听」和「看」，所以先把方法论立起来，
下面 17 节里每一个数字都是这么来的。

1. **墙钟不参与判断。** 播放推进了多少秒、观察者回调来了几次，全都随调度浮动。
   所以只断言布尔值（`isPlaying`、回调是否至少来了一次、`remove` 之后不再来），
   以及**与调度无关的具体值**（从 0 起步的第一个 tick 是 `0.0000`、零容差 seek 的落点）。
   绝不打印「播了 0.3 秒之后的 `currentTime`」——那样 debug 与 release 就对不上，
   第二次跑也和第一次对不上。
2. **`AVAudioEngine` 切到手动渲染模式**（`enableManualRenderingMode(.offline, …)`）。
   没有音频设备也能 `renderOffline`，你不推进时间，引擎一个采样都不算。
   本章所有波形峰值（`0.7071 / 0.3536 / 0.1768 / 0.0000`）都是这么来的，逐字节可复现。
3. **写完的文件要先撒手。** `AVAudioFile` 还活着时把同一个 URL 交给 `AVAudioPlayer`，
   得到的是 `duration=0`、`play()` 返回 `false` 且不报错。§2 专门做这个对照。
4. **需要主队列活着的实验，全部排在第一次顶层 `await` 之前。** 顶层 `await` 一旦发生，
   主线程就停在 main queue 的 block 里面，此后 `RunLoop.current.run(until:)` 排不动
   main queue：`AVPlayer` 的 item 停在 `unknown`、`currentTime` 冻结、时间观察者一个回调都不来。
   §8 里活得好好的同一套实验，在 §10 末尾重跑就是全零。
   **这是脚本环境特有的现象**，真机 App 里主 runloop 一直在转，不会遇到。

还有两条硬约束决定了本章代码的长相。判定 1 要求编译日志全空（零告警），
判定 3 要求 stderr 全空，所以：

- 不打印 `AVAudioFormat` / `AVAudioNode` / `AVPlayerItem` 的 `description`——
  里面带指针地址（`<AVAudioFormat 0x600002108e10: 1 ch, 44100 Hz, Float32>`），
  逐字节比对立刻失败。本章统一用 `fmt()` 自己拼字段。
- 带 `completionHandler` 的 API 在顶层（`async main`）里直接调用，编译器会提示改用
  async 版本；但离线渲染本来就是同步的，`await` 下去等的是「数据被消费」，
  手动模式里没有时钟在推，等不到。所以本章把这些调用包进**非 async** 的普通函数
  （`scheduleSync` / `scheduleFileSync` / `waitBriefly`），警告的前提就不成立了。

## 1) AVAudioFile：现场写一段 1 秒 440Hz 的 PCM wav

`AVAudioFile` 是「一个文件 + 它的格式」这一对概念的最小封装，读写都走它。
本章不下载、不附带二进制，第 1 节就自己生成素材——这也是后面每一节能反复读同一个文件的前提。

```swift
let settings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 44100,
    AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true,
]
let file = try AVAudioFile(forWriting: url, settings: settings,
                           commonFormat: .pcmFormatFloat32, interleaved: false)
let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames)!
buf.frameLength = frames                      // ← 必须自己设，新 buffer 的 frameLength 是 0
file.write(from: buf)
```

```
== 1) AVAudioFile：现场写一段 1 秒 440Hz 的 PCM wav ==
  磁盘字节数=180496
  读回来 length=44100 帧
  fileFormat ch=1 sr=44100.0 commonFormat=1 interleaved=true
  processingFormat ch=1 sr=44100.0 commonFormat=1 interleaved=false
  容量给满 44100 帧，第一次 read 只交了 frameLength=44032 帧；floatChannelData 非空=true int16ChannelData 非空=false
  第二次 read 交出剩下的 frameLength=68 帧；两次合计=44100
  前 4 个采样=["0.0000", "0.0313", "0.0625", "0.0935"]
  整段 peak=0.5000（生成时给的幅度是 0.5）
  ok   要读满 length 帧得**循环 read**；length 的单位是帧，不是字节
  ok   read(into:) 不保证一次把 buffer 填满 —— 探针三轮实测都是 44032 + 68，容量等于总帧数也一样先给你一块
  ok   处理格式由 commonFormat/interleaved 两个参数决定：这里恒为 Float32 非交织，与文件里的位深无关
  ok   峰值就是当初写进去的幅度
  ok   文件比 数据=帧数×4 字节还要大：多的是 wav 头与格式块
```

三个必须分清的东西：

- `length` 是**帧**，不是字节。1 秒 44.1kHz 就是 `44100`。
- `fileFormat` 与 `processingFormat` 是两回事：前者是文件里怎么存的（这里 `interleaved=true`，
  commonFormat 报 1 = Float32），后者是「读进内存时给我什么形状」——由构造参数决定，
  这里给的是非交织。**读出来的采样永远按 `processingFormat` 解释**，
  拿 `fileFormat` 去算偏移是新手最常见的错位来源。
- `read(into:)` 不保证填满你给的容量。三轮探针实测都是 **44032 + 68**：
  底层按块供数据，最后一块不够就给你剩下的。所以读满一个文件必须写循环，
  判据是 `buffer.frameLength == 0` 或者抛错，不是「调用了一次」。

前 4 个采样 `0.0000 / 0.0313 / 0.0625 / 0.0935` 是 `0.5 × sin(2π·440·i/44100)` 在 i=0…3 的值，
可以手算复核——音频代码能对到手算，这在后面 §15/§16 是常态。

文件读到尾再读一次会怎样，这一节也照了：

```
  EOF 之后再 read 抛错：type=_GenericObjCError domain=Foundation._GenericObjCError code=0
  抛错之后 frameLength=0
  ok   read(into:) 到文件尾是 **throws**（Swift 侧 Foundation._GenericObjCError），不会给你 frameLength=0 的安静信号
```

`Foundation._GenericObjCError code=0` 是 ObjC 侧 `NO` 返回值直接桥成错误的结果，
没有信息量；重点是**它抛**，不会安静地给你 `frameLength=0`。
所以「循环 read 直到读空」的写法必须把 `try` 包住，只按 `frameLength` 判空的写法会在 EOF 崩。

## 2) 生命周期坑：AVAudioFile 还攥在手里时，同一个文件播不出来

这一节是全章最短、也最值钱的一节。同一个 URL、同一份字节，唯一的区别是写入用的
`AVAudioFile` 还在不在作用域里。

```
== 2) 生命周期坑：AVAudioFile 还攥在手里时，同一个文件播不出来 ==
  文件已落盘，字节=180496，writer.length=44100
  writer 还在时：duration=0.0 prepareToPlay=false play()=false
  ok   文件明明在磁盘上，AVAudioPlayer 却给你一个 0 秒的空资产，而且**不抛错、不返回错误码**
  writer 释放后：duration=1.0 prepareToPlay=true
  ok   同一个 URL、同一份字节，只因为写入 AVAudioFile 被释放了，才读得到 1 秒时长
```

`duration=0` + `prepareToPlay()==false` + `play()==false`，三个信号一致，
却**没有任何一个错误**。原因在写侧：`AVAudioFile` 直到释放（或显式关闭）才把
音频文件头里的长度字段补完；文件头说「0 帧」，读侧就老老实实给你 0 秒。

写代码时的三条出路，按推荐顺序：

1. **让写入对象先出作用域**（本章 `writeTone()` 就是这么写的，`return url` 时 `file` 已释放）；
2. 用 `AVAudioFile` 的写侧接口时，写完把它置 `nil` 再交给播放器；
3. 如果必须同时持有，读时长走 `AVAsset`，别拿 `AVAudioPlayer.duration` 当判据。

## 3) AVAudioPlayer：把一段本地音频交给系统播

`AVAudioPlayer` 是「一次性把整个文件交给它」的播放模型，和 §8 的 `AVPlayer`
（状态机 + 时间轴）是两套完全不同的 API。它的属性全部同步可读，因此这一节能拿到
最多可以写进断言的具体值。

```
== 3) AVAudioPlayer：把一段本地音频交给系统播 ==
  delegate=nil volume=1.0 pan=0.0 rate=1.0 enableRate=false
  numberOfLoops=0 duration=1.0 numberOfChannels=1
  currentTime(还没播)=0.0 isPlaying=false metering=false
  url=24-tone.wav data=nil
  settings 键=["AVAudioFileTypeKey", "AVEncoderBitRateKey", "AVFormatIDKey", "AVLinearPCMBitDepthKey", "AVLinearPCMIsBigEndianKey", "AVLinearPCMIsFloatKey", "AVLinearPCMIsNonInterleaved", "AVNumberOfChannelsKey", "AVSampleRateKey"]
  AVFormatIDKey=1819304813（FourCC lpcm）AVSampleRateKey=44100 位深=32
  ok   settings 里的格式 ID 就是 FourCC，lpcm = 未压缩 PCM
  设完读回：volume=0.5 pan=-0.25 numberOfLoops=-1（-1 = 无限循环）
  不开启播放就测电平：peakPower(forChannel: 0)=-160.0 averagePower=-160.0
  ok   -160 dB 是「一次都没测到」的初值，不是真实电平
  越界声道号：peakPower(forChannel: 9)=-160.0
  prepareToPlay=true play()=true isPlaying=true
  ok   AVAudioPlayer 的 play() 是同步返回 Bool（不像 AVPlayer 靠状态机）
```

值得逐条说的：

- **默认值**：`volume=1.0 pan=0.0 rate=1.0 enableRate=false numberOfLoops=0`。
  `enableRate` 默认是 `false`，也就是说你设了 `rate=2.0` 也不会在 `play()` 时生效，
  必须先把开关打开。
- **`numberOfLoops = -1` 是无限循环**，`0` 是播一次，`2` 是「播三遍」（初始 + 两次重复）。
- **电平初值是 `-160.0`**，而且是 `peak` 与 `average` 都是：
  `不开启播放就测电平：peakPower(forChannel: 0)=-160.0 averagePower=-160.0`。
  这是「一次都没测到」的哨兵值，不是音量。要读电平必须先
  `isMeteringEnabled = true`，播放期间还要反复调 `updateMeters()`。
  越界声道号同样给 `-160.0`（`peakPower(forChannel: 9)=-160.0`），**不抛异常**，
  所以这个 API 不会替你校验输入。
- `play()` 同步返回 `Bool`，`isPlaying` 立刻可读；
  但**推进了多少**不能断言——所以这一节只断言「0.3 秒后 `currentTime > 0`」。

`currentTime` 的四个行为，本章用真实赋值逐个照出来：

```
  播放中设 currentTime=0.05，立刻读回=0.0500
  pause 后 isPlaying=false currentTime=0.0500
  ok   pause() 之后 isPlaying 同步变 false，不用等回调
  stop 后 isPlaying=false currentTime=0.0500 —— **没有归零**
  ok   探针实测 stop() 不会把 currentTime 清零，紧接着 play() 读到的还是原位；想从头播必须显式 currentTime = 0
  把 currentTime 设成 99（duration=1.0000）之后读回=1.0000 —— 越界请求被夹到 duration
  ok   越界赋值不抛错、不返回 false，只是被夹住；越界**读取**不会有异常，所以别指望它给你输入校验的反馈
  enableRate=true 后 rate=2.0 读回=2.0
  enableRate=false 时设 rate=0.5，属性读回仍然是=0.5（但播放速度不受影响 —— 这个开关只管 play() 那一刻要不要用 rate）
```

`stop()` 不清零是这里最容易记错的一条：`pause` 与 `stop` 之后 `currentTime` 都是 `0.0500`，
两者在「位置」上没区别，区别只在 `stop` 会把播放的资源释放掉（想再播要重新 `prepareToPlay`）。
想从头播必须显式写 `currentTime = 0`。

失败发生在**构造**时：

```
  文件不存在时构造就抛：domain=NSOSStatusErrorDomain code=2003334207
  localizedDescription=The operation couldn’t be completed. (OSStatus error 2003334207.)
  ok   AVAudioPlayer 的失败发生在**构造**时，错误是 OSStatus 包装成的 NSError
```

`2003334207` 按 FourCC 解是 `'fmt?'`——格式不认识／不可用。
本章后面还会遇到 `-50`（`param`）、`-1`，以及 §16 里那个同样是 `1718449215 = 'fmt?'` 的
`AVAudioRecorder` 构造错误，**OSStatus 是 FourCC** 这条规矩在 AVFoundation 里到处适用（§6 讲它的时间版本）。

## 4) AVAudioSession：所有音频行为的总开关

前面三节「能不能播、播成什么样」看着像播放器的事，其实八成败在会话上。
`AVAudioSession` 是**进程级单例**（`AVAudioSession.sharedInstance()`），它决定：
你这个进程能不能响、响的时候别人要不要让路、麦克风归谁、被电话打断之后怎么恢复。

```
== 4. AVAudioSession：category / mode / options / 路由 / 通知 ==
  默认 category=AVAudioSessionCategorySoloAmbient mode=AVAudioSessionModeDefault
  ok   新建进程的会话默认是 SoloAmbient + Default，不是 Playback —— 忘了改就「锁屏/静音键下没声音」
  sampleRate=48000 preferredSampleRate=0.0 ioBufferDuration=0.0100
  ok   preferredSampleRate 的 0.0 不是「0 Hz」，是「没提要求，由系统决定」
  currentRoute.inputs=0 outputs=["Speaker"]
  ok   模拟器上输出端口就叫 Speaker；真机插耳机/蓝牙时这个数组会变，所以路由要靠通知监听而不是假设
  outputVolume=0.60 isOtherAudioPlaying=false secondaryAudioShouldBeSilencedHint=false
  inputIsAvailable=true inputNumberOfChannels=1 outputNumberOfChannels=2 inputGain=1.0 inputGainSettable=false
  recordPermission rawValue=1684369017 解 FourCC=deny
  三个 case 的 rawValue 与 FourCC 解码: undetermined=1970168948/undt granted=1735552628/grnt denied=1684369017/deny
  ok   AVAudioSession.RecordPermission 的 rawValue 是 FourCC（4 个 ASCII 字节拼成的整数），不是 0/1/2
  iOS 17+ API：AVAudioApplication.shared.recordPermission.rawValue=1684369017
  ok   AVAudioApplication 是 iOS 17 才有的新入口（直接写在 iOS 15 目标上编译报 'AVAudioApplication' is only available in iOS 17.0 or newer），它返回自己的枚举，不能和会话的老属性直接 ==，只能比数值
```

三件事一次说清：

- **默认是 `SoloAmbient`**：跟随静音键、别人播东西时你不响、锁屏没声音。
  做播放器第一步就是 `setCategory(.playback)`。
- **`sampleRate=48000` 而 `preferredSampleRate=0.0`**。后者是「你的请求」，
  0 表示没提过；前者才是当前真值。这条规矩在后面 §15 的引擎、§16 的转换器上反复出现。
- **`recordPermission` 的 rawValue 是 FourCC**（`undt`/`grnt`/`deny` 四个 ASCII 拼成的整数），
  不是 0/1/2。调试时看到 `1684369017` 别当错误码——它就是字符串 `'deny'`。
  iOS 17 起 `AVAudioApplication.shared.recordPermission` 是同一个数值的另一扇门，
  两套枚举**不能直接 `==`**（类型不同），只能比数值，这就是那条 expect 的原话。

六个 category 逐个设置再读回，本章全跑了一遍：

```
  -- 六个 category 逐个设置 --
  setCategory(AVAudioSessionCategoryPlayback) -> 读回 AVAudioSessionCategoryPlayback
  setCategory(AVAudioSessionCategoryRecord) -> 读回 AVAudioSessionCategoryRecord
  setCategory(AVAudioSessionCategoryPlayAndRecord) -> 读回 AVAudioSessionCategoryPlayAndRecord
  setCategory(AVAudioSessionCategoryAmbient) -> 读回 AVAudioSessionCategoryAmbient
  setCategory(AVAudioSessionCategorySoloAmbient) -> 读回 AVAudioSessionCategorySoloAmbient
  setCategory(AVAudioSessionCategoryMultiRoute) -> 读回 AVAudioSessionCategoryMultiRoute
  playAndRecord + [.defaultToSpeaker,.allowBluetooth,.mixWithOthers] -> category=AVAudioSessionCategoryPlayAndRecord
  ok   setCategory(mode:options:) 之后 category 只回显主类别；SDK 里没有 categoryWithOptions 这个属性（探针试过，编译不过），想知道 options 只能自己记
  CategoryOptions 单项 rawValue: mixWithOthers=1 duckOthers=2 allowBluetooth=4 allowBluetoothA2DP=32 defaultToSpeaker=8 overrideMutedMicrophoneInterruption=128
  ok   options 是 OptionSet，合并 rawValue 按位或：1|2|32|8 = 43
```

`options` 是位标志，`1|2|4|8` 那几档挨着排，`allowBluetoothA2DP` 单独跳到 32；
三个合起来是 43。**没有 `categoryWithOptions` 这种属性**，`category` 只回显主类别，
所以「我现在到底带没带 `defaultToSpeaker`」系统不告诉你，只能自己记账——
这就是为什么正规工程里会话配置都封装在一个「设过一次就缓存」的对象里。

`setActive` 与 `preferred*` 提示：

```
  -- setActive --
  setActive(true)→(false)→(true) 三次调用的错误串=""
  ok   setActive(_:) 是 throws 的 Void：成功时没有任何返回值可看，只能靠有没有抛错判断
  -- preferred 提示 --
  提示之后 sampleRate=48000 preferredSampleRate=48000.0 ioBufferDuration=0.0027
  ok   setPreferred* 只是「请求」：preferredSampleRate 会记下你的请求，真正的 ioBufferDuration 由系统取整（0.005 变 0.00266…）
```

`setPreferredIOBufferDuration(0.005)` 之后读回 `0.0027`——系统按它自己的帧长粒度取整了。
延迟敏感的实现（录音可视化、乐器）要按**读回来的值**算节奏，不是按你请求的值。

三个通知名与两套枚举：

```
  -- 通知名（字符串就是系统 post 时用的名字）--
  interruption=AVAudioSessionInterruptionNotification
  routeChange=AVAudioSessionRouteChangeNotification
  mediaServicesWereReset=AVAudioSessionMediaServicesWereResetNotification
  ok   这三个通知名都是 AVAudioSession 的实例属性吗？不是 —— 它们是类型上的 Notification.Name 常量
  InterruptionType: began=1 ended=0（注意 began 是 1、ended 是 0）
  RouteChangeReason: unknown=0 newDeviceAvailable=1 oldDeviceUnavailable=2
```

**`InterruptionType.began = 1`、`ended = 0`**，和直觉的顺序反着来；
`RouteChangeReason` 里 `oldDeviceUnavailable=2` 才是「耳机被拔掉」那一条。
这两个枚举的值是打断恢复逻辑写错的高发点，值得抄在手边。
音频会话被打断的标准应对是：收到 `began` 就停并保存位置，收到 `ended` 时读
`AVAudioSessionInterruptionOption.shouldResume` 再决定要不要自己接着播。

## 5) AVAudioRecorder：prepareToRecord 与 record 是两个时刻

```
== 5. AVAudioRecorder：prepareToRecord / record / 电平 / deleteRecording ==
  刚构造好：isRecording=false isMeteringEnabled=false url=24-rec.caf
  ok   AVAudioRecorder(url:settings:) 只是建对象，连文件都不碰
  prepareToRecord()=true 之后文件存在=true
  ok   文件是 prepareToRecord() 创建的（0 字节骨架），不是 record()
  record()=false isRecording=false
  等 0.2s 之后 isRecording=false currentTime=0.0000
  stop 之后文件存在=true 大小=4096
  ok   没有录音权限时 record() 返回 false 且**不抛错**、也不回调失败 delegate —— 只能自己查返回值
  没录上时电平：peakPower(forChannel: 0)=-120.0 averagePower=-120.0
  ok   -120 dB 是「全零/没测到」的下限值，不是真实音量；忘记 updateMeters() 就会一直读到它
  settings 键=["AVAudioFileTypeKey", "AVFormatIDKey", "AVLinearPCMBitDepthKey", "AVLinearPCMIsBigEndianKey", "AVLinearPCMIsFloatKey", "AVLinearPCMIsNonInterleaved", "AVNumberOfChannelsKey", "AVSampleRateKey"]
  format：ch=1 sr=44100.0 commonFormat=3 interleaved=true
  ok   r.format 反映的是 settings 里的采样率/声道数，与设备当前的 48 kHz 无关
  deleteRecording()=false 文件还在=true
  ok   没录过就没有「录音」可删，deleteRecording() 返回 false 且文件留在原地 —— 想清理请自己 removeItem
  -- 非法 settings --
  乱写的 settings 在构造时就抛：domain=NSOSStatusErrorDomain code=1718449215
  ok   AVAudioRecorder 的错误同样是 OSStatus 直接塞进 NSError
```

四个「和播放器不一样」的点：

1. **三个时刻**：构造（不碰磁盘）→ `prepareToRecord()`（建 0 字节文件骨架）→
   `record()`（真的开始写）。把「文件不存在」当成「没权限」是最常见的误判。
2. **权限失败是静默的**。这台模拟器没有录音权限（§4 里 `recordPermission=deny`），
   `record()` 返回 `false`，不抛错，delegate 的失败回调也不来。
   `stop` 之后文件还是有 4096 字节——那是骨架和对齐用的填充，不是录音内容。
   所以录音功能必须自己先查权限、再看返回值，两层都要有。
3. **电平下限是 `-120.0`**（播放器那边是 `-160.0`，两套 API 的哨兵值不同！）
   没录上时 `peak` 和 `average` 都是 `-120.0`。
4. **`r.format` 说的是 settings，不是设备**。这里 settings 写 44100，
   设备当前 48000（§4 印过），`r.format` 仍然报 44100——它会重采样。
   而 `commonFormat=3` 是 int16，和 §1 的 `1`（Float32）不同，这是 `AVLinearPCMBitDepthKey: 16` 的结果。

`deleteRecording()` 在没有录音时返回 `false` 且文件留在原地，这个「删不掉」和
`removeItem` 的成功是两回事：前者只负责「录音内容」，想清理骨架请自己删文件。

## 6) CMTime / CMTimeRange / CMTimeFlags：AVFoundation 的地基

这一节不讲任何播放，但它决定你后面每一节能不能看懂数字。
`CMTime` 是一个有理数：`value/timescale`（Int64 / Int32）再加一组 `flags`。

```
== 6. CMTime / CMTimeRange / CMTimeFlags ==
  CMTimeMake(value:3, timescale:2) -> value=3 ts=2 valid=true indefinite=false secs=1.5 flags=1
  CMTime(seconds:1.5, preferredTimescale:600) -> value=900 ts=600 valid=true indefinite=false secs=1.5 flags=1
  ok   value/timescale 是分数表示，1.5 = 3/2 = 900/600，== 与 CMTimeCompare 都判等 —— 时间轴不同也能相等
```

`3/2` 和 `900/600` 相等——比较的是**数值**，不是 `value` 字段。
这是 `CMTime` 的第一个反直觉处：`t.value == 900` 说明不了什么，`t == CMTime(seconds: 1.5, …)` 才是判断。

四个特殊值必须靠 `flags` 分辨，因为光看 `seconds` 会误判：

```
  -- 四个特殊值：光看 seconds 会误判，必须看 flags --
  zero: value=0 ts=1 flags=1 valid=true indefinite=false posInf=false secs=0.0
  indefinite: value=0 ts=0 flags=17 valid=true indefinite=true posInf=false secs=nan
  positiveInfinity: value=0 ts=0 flags=5 valid=true indefinite=false posInf=true secs=inf
  negativeInfinity: value=0 ts=0 flags=9 valid=true indefinite=false posInf=false secs=-inf
  ok   indefinite 的 timescale 是 0，但 isValid 仍然是 true ——「有效」不等于「能算」
  ok   posInf 的 seconds 是 +inf（直播流的 duration 就长这样）
  手搓一个空 flags 的 CMTime：value=0 ts=0 valid=false indefinite=false secs=nan
  ok   flags 里没有 valid 位时 isValid=false；CMTime.invalid 就是这种东西
  CMTimeFlags 的 rawValue: valid=1 hasBeenRounded=2 positiveInfinity=4 negativeInfinity=8 indefinite=16 impliedValueFlagsMask=28
```

注意 `indefinite`、`positiveInfinity` 的 `value/timescale` **都是 0/0**，
唯一区别是 flags（17 vs 5）。`indefinite` 的 `isValid` 是 `true`，
但它不参与算术（`seconds` 是 `nan`）。「这个时间是有效的」和「这个时间能拿来算」是两回事。

最脏的一种情况——把 `Double.nan` 塞进构造函数：

```
  CMTime(seconds: .nan, preferredTimescale: 600) -> value=-9223372036854775808 flags=3 secs=-1.5372286728091294e+16
  ok   把 Double.nan 塞进 CMTime(seconds:) 不会报错，它变成 value=Int64.min（-9223372036854775808）—— 这就是「传了个脏时间」的现场
```

不报错、不返回 invalid，直接给你一个 `Int64.min`，`seconds` 再读回来是
`-1.53…e+16`。这一条就是「为什么 AVFoundation 的每个 API 都要你检查 `flags`」的最好证据。

精度与取整——三个 1/3 相加，分数时间轴上是精确的：

```
  -- 精度：三个 1/3 相加 --
  third=value=1 ts=3 valid=true indefinite=false secs=0.3333333333333333 ; third+third+third -> value=3 ts=3 valid=true indefinite=false secs=1.0
  ok   分数时间轴下 1/3+1/3+1/3 精确等于 1 秒（value=3/timescale=3 就是整数 1）
  1/2 换到 3 标度（1/2*3 = 1.5，正好卡在中间）：roundHalfAway value=2 secs=0.6666666666666666 flags=3 ; roundTowardZero value=1 secs=0.3333333333333333 flags=3
  ok   除不尽时取整方式真的会改变 value（2 vs 1）—— 这就是为什么 CMTime 要带 hasBeenRounded 这个 flag
  ok   两个结果的 flags 里都有 hasBeenRounded=2，说明系统知道这个数字被抹过
  换成 timescale 0：value=0 ts=0 valid=false indefinite=false secs=nan
  CMTimeRoundingMethod 的 rawValue: roundHalfAwayFromZero=1 roundTowardZero=2 roundAwayFromZero=3 quickTime=4 roundTowardPositiveInfinity=5 roundTowardNegativeInfinity=6 default=1（default 就是 roundHalfAwayFromZero，两者都是 1）
  ok   换算到 timescale=0 不抛错也不警告，直接给你一个 flags=0、isValid=false 的废时间，seconds 是 nan
```

`CMTimeConvertScale` 的两个极端：卡在中间时取整法决定结果是 `2` 还是 `1`（差 1/3 秒），
而 `timescale: 0` 不报错、直接给你废时间。**取整方法有 6 种，默认是 `roundHalfAwayFromZero`（=1）**。

`CMTimeRange` 与最后一击——为什么逐帧计数必须用 `CMTime`：

```
  -- CMTimeRange --
  CMTimeRangeMake(start=1/2, dur=2/1): start=0.5000 duration=2.0000 end=2.5000 empty=false
  ok   end 是 start+duration 算出来的属性，不是独立存的字段
  起点 0、时长 +inf（=「整条轨道」常用写法）：end 的 posInf=true valid=true secs=inf
  ok   读整条资产时就把 duration 设成 +inf，containsTime 对任何有限时间都成立
  -- 为什么非用 CMTime 不可：拿 Double 累加 0.1 秒 --
  CMTime：0.1+0.1+0.1 -> value=180 ; 直接 0.3 -> value=180 ; 相等=true
  Double：0.1+0.1+0.1 = 0.30000000000000004，和 0.3(=0.29999999999999999) 相等吗 false
  ok   整型 value 的加法不会累积误差；Double 的 0.1+0.1+0.1 得到 0.30000000000000004 —— 这就是逐帧计数必须用 CMTime 的理由
```

`CMTimeRange` 只存 `start` 和 `duration`，`end` 是算出来的；
「整条资产」的写法是 `start=zero, duration=positiveInfinity`，
这也是 §13 导出、§14 抓帧里默认 `timeRange` 的样子。
最后那两行是全章的地基结论：**`Double` 连加三次 0.1 不等于 0.3，`CMTime` 等于**。
凡是「按帧推进」「对齐到刻度」的逻辑，用 `CMTime` 的整型 `value` 做加法，
浮点秒只在展示层用。

## 7) AVAssetWriter + PixelBufferAdaptor：现场合成一段 mp4

素材自己造：320x240、10 帧、每帧画一个随帧号变化的纯色，用
`AVAssetWriterInputPixelBufferAdaptor` 逐帧 append。这是本章唯一的视频写路径，
§8 之后所有播放、导出、抓帧用的都是这个文件。

```
== 7. AVAssetWriter + PixelBufferAdaptor：现场合成一段 320x240、10 帧的 mp4 ==
  刚建好：status=0（unknown=0 writing=1 completed=2 failed=3 cancelled=4）
  writer.canAdd(vInput)=true
  adaptor 声明的键=["Height", "PixelFormatType", "Width"]
  adaptor.sourcePixelBufferAttributes 回读键=["Height", "PixelFormatType", "Width"]
  startWriting 之后 status=1
  startSession 之后 status=1，adaptor.pixelBufferPool 是否已就绪=true
  写了 10 帧
  ok   10 帧全部 append 成功，中途没有一次 append 返回 false
  闸门这道判断不能省：探针实测在 readyForMoreMediaData 为 NO 时硬 append 会直接崩
  —— NSInternalInconsistencyException, reason: 'A pixel buffer cannot be appended when readyForMoreMediaData is NO.'（ObjC 异常，Swift 的 try 抓不住）
  ok   循环结束时 writer 仍停在 writing=1 —— 此刻文件还没写完，字节数不能当真（见下面 finishWriting）
  finishWriting 之后 status=2 error=nil
  mp4 字节数=7080
  ok   status=2(completed) 且文件有内容
```

四个动作必须按顺序做完才能开始喂数据：`canAdd` → `add` → `startWriting()` →
`startSession(atSourceTime:)`。头文件把这条写成契约，而且违反契约的代价不是「返回 false」，
是崩溃——本章把最常被踩的那一道闸门的实测结果原样抄下来：

```
  闸门这道判断不能省：探针实测在 readyForMoreMediaData 为 NO 时硬 append 会直接崩
  —— NSInternalInconsistencyException, reason: 'A pixel buffer cannot be appended when readyForMoreMediaData is NO.'（ObjC 异常，Swift 的 try 抓不住）
```

`adaptor.pixelBufferPool` 是**请求出来的**：只有当你申请的 buffer 属性是
`kCVPixelBufferPixelFormatTypeKey = kCVPixelFormatType_32BGRA` 这一种、
并且键集和 adaptor 声明的完全一致时它才非 nil（这里印的是 `Height/Width/PixelFormatType` 三件）。
用系统给的池子省掉自己分配，是这类合成代码的性能来源。

**`status` 停在 `writing=1` 时字节数是骗人的**：`append` 全部成功、循环结束，
文件仍然可能是 0 字节或者残缺；只有 `finishWriting` 之后 `status=2` 才算写完。
这一节用 `DispatchSemaphore` 等回调（此刻还在所有顶层 `await` 之前，主队列还活着，
回调排得进来）。§12 之后一律改成 `await finishWriting()`，原因见 §10 末尾的对照。

## 8) AVPlayer / AVPlayerItem：状态机、观察者与 KVO

先记住三个状态枚举的数值，本章后面全靠它们：

```
  AVPlayerItem.Status: unknown=0 readyToPlay=1 failed=2
  AVPlayer.Status: unknown=0 readyToPlay=1 failed=2
  AVPlayer.TimeControlStatus: paused=0 waiting=1 playing=2
  AVAssetWriter.Status: unknown=0 writing=1 completed=2 failed=3 cancelled=4
  AVKeyValueStatus: unknown=0 loading=1 loaded=2 failed=3 cancelled=4
```

`player` 和 `item` 的 `Status` **数值一样但含义独立**，`TimeControlStatus` 又是另一套
（`paused=0 waiting=1 playing=2`，注意 `waiting` 在中间，不是失败）。

### 8.1 刚建好的 item：什么都还没发生

```
  刚建好的 item：status=0 error=nil
  item.duration=value=0 ts=0 valid=true indefinite=true secs=nan
  ok   AVPlayerItem 刚建好时 status=0(unknown)、duration 是 **indefinite**（secs=nan）而不是 0 —— 它还没去读文件
  item.currentTime()=value=0 ts=1 valid=true indefinite=false secs=0.0 isPlaybackLikelyToKeepUp=false isPlaybackBufferEmpty=true isPlaybackBufferFull=false
  item.presentationSize=(0.0, 0.0) videoComposition=nil audioMix=nil
  item.audioTimePitchAlgorithm=TimeDomain canPlayFastForward=false canPlayReverse=false canStepForward=false
  item.preferredForwardBufferDuration=0.0000 preferredPeakBitRate=0.0
  item.automaticallyLoadedAssetKeys=["duration", "availableMediaCharacteristicsWithMediaSelectionOptions"]
  ok   本地轨道的 canPlayXxx 全是 false —— 想倒放/快进得自己设 rate（负数、2.0），别等这几个标志
  ok   两个 preferred 都是 0 = 交给系统决定，不是「缓冲区 0 秒」
  挂上 player 之后什么都不做，只轮询 60 步：item.status=1 player.status=1 reason=nil
  ok   **AVPlayer(playerItem:) 这一步本身就是触发加载**：不 play、不 seek，item 也会自己从 unknown(0) 走到 readyToPlay(1) —— 反过来，只 new 一个 AVPlayerItem 放在手里，它永远不会去读文件
```

`duration` 是 `indefinite`（§6 讲过那个 flags=17 的 0/0），`currentTime()` 反倒是合法的 0。
`isPlaybackBufferEmpty=true` 也别慌——还没加载嘛。
这一节最重要的一条是最后那条：**赋值给 `player` 的那一刻才是加载的起点**。
「我 new 了 item 等了半分钟 status 还是 unknown」不是 bug，是没人去读文件。

### 8.2 play()：状态机先 waiting 再 playing

```
  play() 之后**立刻**读：item.status=1 rate=1.0000 timeControlStatus=1 reason=Optional("AVPlayerWaitingWhileEvaluatingBufferingRateReason")
  继续轮询到 playing=true：timeControlStatus=2 reason=nil item.status=1 player.status=1
  ok   play() 之后**同一行代码里**读到的还是 waiting(1)、reason=AVPlayerWaitingWhileEvaluatingBufferingRateReason —— 别在这里判「播起来了没有」
  ok   再等一会儿（本机实测约十几步 ×20ms）才走到 playing(2)、reason 变 nil：waiting 是过渡态，不是失败
  ready 之后 item.duration=value=44100 ts=44100 valid=true indefinite=false secs=1.0 currentTime()=value=0 ts=1 valid=true indefinite=false secs=0.0 likelyKeepUp=true bufferEmpty=false
  ok   duration 从 indefinite 变成 1.0 —— 是 play() 触发的加载给的，不需要你先 await load
  avPlayer.actionAtItemEnd=1（枚举：advance=0 pause=1 none=2；AVPlayer.h 明写只有 AVQueuePlayer 支持 advance，普通 player 设了会 raise NSInvalidArgumentException）
  ok   actionAtItemEnd 默认 pause（rawValue 1）—— 播完自动停，想循环得自己监听 AVPlayerItemDidPlayToEndTime 再 seek 回头
  avPlayer.automaticallyWaitsToMinimizeStalling=true preventsDisplaySleepDuringVideoPlayback=true allowsExternalPlayback=true volume=1.0000 isMuted=false
  ok   这三个开关默认全是 true —— 首帧卡顿归因、防熄屏、AirPlay 全在默认里开着
  pause() 之后 rate=0.0000 timeControlStatus=0
  ok   pause() 把 rate 归 0、状态回 paused=0
  直接设 rate=2.5 -> timeControlStatus=1 rate=2.5000
  设 rate=0 -> timeControlStatus=0
  ok   rate=0 等价于暂停，状态机自己会回 paused
```

`reason`（`AVPlayerItemLegibleOutput` 之外的 `player.reasonForWaitingToPlay`）在这里给的是
`AVPlayerWaitingWhileEvaluatingBufferingRateReason`——它是**归因**用的字符串，
`automaticallyWaitsToMinimizeStalling=true` 才会有这些等待原因。
另外注意 `rate` 是直接可写的：`rate = 2.5` 就快放，`rate = -1` 就倒放，
不需要 `canPlayReverse` 那类标志（8.1 已证它们对本地轨道全是 false）。

### 8.3 seek：completion 先到，ready 后到

```
  发起 seek(0.5s, 容差 .zero) 之后**立刻**读：currentTime=value=300 ts=600 valid=true indefinite=false secs=0.5 status=0
  completion 完成=Optional(true)，此时 currentTime=value=300 ts=600 valid=true indefinite=false secs=0.5 status=0
  ok   seek 的 completion=true、currentTime 精确落在 0.5，但 item.status 仍是 unknown —— 「seek 成功」不等于「可以播放」
  往 1.0000 秒的资产 seek 到 5.0（**默认容差**）：完成=true currentTime=value=44100 ts=44100 valid=true indefinite=false secs=1.0 status=1
  ok   player 会把越界的 seek 夹到 duration：读回来的是 1.0 而不是 5.0，也不报错 —— 别指望它替你校验输入
  同一位置改用**零容差** seek：完成=true currentTime=value=44100 ts=44100 valid=true indefinite=false secs=1.0
  ok   零容差也一样夹在 duration，容差只影响落点精度，不影响越界行为
```

`seek(to:toleranceBefore:toleranceAfter:)` 传 `.zero` 两端时，落点是 `300/600` 精确的 0.5 秒——
这是本章敢写进断言的少数「具体播放值」之一，因为它不依赖墙钟。
越界 seek 被夹到 `duration`（`44100/44100`）且 `completion` 照样是 `true`。

### 8.4 时间观察者：periodic 与 boundary

```
  暂停状态下挂上观察者、再 pump 0.2 秒：ticks=[]
  ok   暂停时 addPeriodicTimeObserver **不会**先给一次当前时间（AVPlayer.h 承诺的是「按 interval 回调」），想立刻拿到位置就自己读 currentTime()
  起步播放后收到的第一个 tick=0.0000
  ok   第一个 tick 给的是**起步位置** 0.0000，不是等满一个 interval 才来（interval=1/10 秒，从 0.3 起步时首个 tick 就是 0.3000 —— 探针实测）
  boundary 观察者（设在 0.5 秒）命中次数=1
  ok   boundary 只在时间**跨过**那个点时给一次，从 0 播到 0.5 就命中 1 次
  ok   removeTimeObserver 之后再播 1.2 秒，tick 数停在 7 不增长 —— 两种 token（AVPeriodicTimebaseObserver / AVOccasionalTimebaseObserver）都要还回去；忘了 remove 就是页面走了闭包还在被 player 持有
```

**回调次数随调度浮动，所以本章只断言三件事**：暂停时不来、第一个值是起步位置、
remove 之后不再增长。「播 0.2 秒应该有 2 个 tick」这种断言在 CI 上必然随机红。
`addBoundaryTimeObserver` 传的是 `[CMTime]` 数组（不是 `NSValue` 包装的写法在旧书里常见，
这一版 SDK 要 `CMTime` 值类型，用 `as [NSValue]` 桥是旧写法）。

### 8.5 KVO：change 里可能什么都没有

```
  只 new 了 item、还没挂 player，先注册 KVO 再读一次：kvoLog=["item.status old=nil new=nil（回调里现读 status=0）"]
  ok   options 带 .initial 时，第一条就是 old/new 都为 nil 的初始快照 —— 上来就强解 newValue! 会崩
  挂上 player 并播到 playing 之后 kvoLog=["item.status old=nil new=nil（回调里现读 status=0）", "currentItem.newValue=有", "item.status old=nil new=nil（回调里现读 status=1）"]
  ok   status 真的从 0 变到 1 了，但通知里的 old/new **仍然是 nil** —— AVPlayerItem.status 的 KVO 值不可靠，回调里重新读 item.status 才是准的
  ok   同一个 options 下 currentItem 的 KVO 就能拿到 newValue —— 拿不到值是 status 这类**内部手动通知**的键特有的坑，不是 KVO 全局如此
```

这是本章最实用的一条：**别写 `change[\.new] as? AVPlayerItemStatus`**，
在 `AVPlayerItem.status` 上它永远是 nil；在回调里现读 `item.status`。
而同一份代码里 `currentItem` 的 KVO 是能给值的，所以不能一概而论说「KVO 不好使」。

### 8.6 坏文件：什么时候才终于报 failed

```
  坏文件、只 new 了 item 没挂 player，轮询 60 步：item.status=0 error=nil
  ok   没人接手就没人去开文件：坏文件此时和好文件一模一样，停在 unknown(0)、error 还是 nil —— 8.1 那条「挂上 player 才触发加载」是这里唯一的分水岭
  只是挂上 player（**还没 play()**）就等到 failed=true：item.status=2 domain=Optional("AVFoundationErrorDomain") code=Optional(-11800) desc=Optional("The operation could not be completed")
  同一时刻 brokenPlayer.status=1 timeControlStatus=0 currentTime=value=0 ts=1 valid=true indefinite=false secs=0.0
  ok   触发加载之后坏文件立刻 failed(2) + AVFoundationErrorDomain/-11800（AVURLAsset 打不开文件统一是这个码，和「文件不存在」还是「格式不对」无关）
  ok   player 自己照样 readyToPlay(1)，坏的是 item —— 监听必须挂在 item.status 上，挂 player 上会看到「一切正常」
```

`-11800`（`kAVErrorFileFormatNotDetected`）是「打不开」的**通用码**，
`AVURLAssetResourceLoadingFailedErrorKey` 之类的细节不会给你区分「不存在」和「格式不对」。
最重要的结论：**player.status 与 item.status 是两条独立的生命**，错误监控必须挂 item。

## 9) AVPlayerViewController、AVPlayerLayer 与画中画能力

播放界面有两条路：`AVPlayerViewController`（系统全包：控制条、画中画、AirPlay、
NowPlaying 全帮你做）和 `AVPlayerLayer`（只要画面，其余自己写）。
这一节先把 §7 那段视频挂起来确认内容尺寸，再把两个类的默认值逐个印出来。

```
== 9. AVPlayerViewController、AVPlayerLayer 与画中画能力 ==
  视频 item：等到 readyToPlay=true status=1 presentationSize=(320.0, 240.0) duration=0.3333
  ok   presentationSize 是 320x240 —— §7 写进去多大就是多大；它是**轨道内容尺寸**，不是 layer 的尺寸
```

### 9.1 AVPlayerViewController 的默认值

```
  空 controller：player=nil showsPlaybackControls=true showsTimecodes=false
  ok   进度条默认显示（自己画控制条时第一件事就是把它关掉），时间码默认不显示（iOS 13 才有这个开关）
  allowsPictureInPicturePlayback=true canStartPictureInPictureAutomaticallyFromInline=false updatesNowPlayingInfoCenter=true
  ok   PiP 权限默认开、从 inline 自动进画中画默认关、NowPlaying 默认由它接管 —— 第三条要和 §17 自己写 MPNowPlayingInfoCenter 配合，两边都开就是互相覆盖
  entersFullScreenWhenPlaybackBegins=false exitsFullScreenWhenPlaybackEnds=false requiresLinearPlayback=false
  videoGravity=AVLayerVideoGravityResizeAspect isReadyForDisplay=false videoBounds=(0.0, 0.0, 0.0, 0.0) delegate=nil pixelBufferAttributes=nil
  ok   默认 AVLayerVideoGravityResizeAspect（等比例留黑边）；没进窗口层级时 isReadyForDisplay 就是 false
  contentOverlayView 类型=Optional<UIView>，它的 layer 是 AVPlayerLayer 吗=false
  ok   叠加层是普通视图 + 普通 CALayer：想往画面上盖自定义 UI 就 add 进 contentOverlayView，而不是去找那个看不见的播放层
  iOS 16 起的长按倍速表：speeds=["0.5000", "1.0000", "1.2500", "1.5000", "2.0000"] selectedSpeed=Optional(1.0)（系统默认表=["0.5000", "1.0000", "1.2500", "1.5000", "2.0000"]）
  ok   倍速档位是 AVPlaybackSpeed 对象数组（rate + localizedName），不是 [Double]；系统默认这 5 档
  只留 1.75x 一档：speeds=["1.7500"] selectedSpeed=Optional(1.75)
  ok   换了 speeds，selectedSpeed 立刻跟着变成新表里的档位 —— 它不是「用户点过哪个」的记录，别拿它当用户偏好存
  设 player 之后：pvc.player === videoPlayer ? true title=nil preferredContentSize=(0.0, 0.0)
  pvc.view 类型=Optional<UIView>，view.layer 类型=AVPresentationContainerViewLayer，view.subviews.count=0
  ok   没 present、没进窗口层级之前，控制条上一个子视图都还没建 —— 在这里遍历 subviews 找播放按钮一定是空
```

四条最容易咬人的：

- `showsPlaybackControls` 默认 **true**：自己画控制条时忘了关，屏幕上会叠两套 UI。
- `updatesNowPlayingInfoCenter` 默认 **true**：它会替你写锁屏信息。
  §17 里自己写 `MPNowPlayingInfoCenter` 的代码和它**同时开**就是互相覆盖，
  表现是「锁屏信息一会儿对一会儿错」——两边只能留一个。
- `contentOverlayView` 的 layer 不是 `AVPlayerLayer`。想盖字幕/水印就 add 进这个视图，
  别去 `layer.sublayers` 里找那个看不见的播放层。
- `view` 是懒建的：没 present、没进窗口层级之前 `subviews.count == 0`，
  任何「遍历 subviews 找播放按钮」的测试代码在这一步都是空。

### 9.2 AVPlayerLayer：把画面铺到自己视图里

```
  新建：videoGravity=AVLayerVideoGravityResizeAspect isReadyForDisplay=false videoRect=(0.0, 0.0, 0.0, 0.0) pixelBufferAttributes=nil
  AVLayerVideoGravity 三个取值：resize=AVLayerVideoGravityResize resizeAspect=AVLayerVideoGravityResizeAspect resizeAspectFill=AVLayerVideoGravityResizeAspectFill
  layerClass 写法：view.layer 是 AVPlayerLayer 吗=true，一开始 player=nil
  100x100 的盒子装 320x240 的画面：videoRect=(0.0, 12.5, 100.0, 75.0)（默认 resizeAspect → 等比缩到 100x75，上下各留 12.5 的黑边）
  ok   videoRect 由 videoGravity 和 layer 尺寸算出来：320x240 塞进 100x100 等比适配就是 (0,12.5,100,75) —— 想改填充方式就动 videoGravity
  改成 resizeAspectFill 之后 videoRect=(0.0, 0.0, 100.0, 100.0)
  挂进 view、设好 frame、播起来，轮询 60 步：isReadyForDisplay=false videoRect=(0.0, 0.0, 320.0, 240.0) bounds=(0.0, 0.0, 320.0, 240.0)
  ok   headless 里没有真正的 display：videoRect 照样给 320x240，isReadyForDisplay 却永远 false —— 「等 readyForDisplay 再显示封面」这类逻辑在测试里会一直卡住
  displayedPixelBuffer()（iOS 16+，想拿当前帧做二次处理用的）=nil —— 没有显示器就是 nil
```

`videoRect` 是本章在 headless 里唯一能算出「画面到底铺成什么样」的量：
`resizeAspect` 下 `(0, 12.5, 100, 75)`、`resizeAspectFill` 下满框。
这两种 gravity 的差别用数字写死，比看十遍文档有用。
而 `isReadyForDisplay` 在没有显示器的环境里永远 `false`——
**「等 readyForDisplay 再隐藏封面」这条常规逻辑在自动化测试里必卡**，要绕过它。

### 9.3 画中画：能力、ContentSource，以及不支持时那些「静默失效」的开关

```
  AVPictureInPictureController.isPictureInPictureSupported()=false（当前设备/模拟器）
  ContentSource(playerLayer:)：src.playerLayer === playerLayer ? true
  init(contentSource:) 返回值不是 Optional：isPictureInPicturePossible=false isActive=false isSuspended=false
  ok   设备不支持时 isPossible 永远是 false：startPictureInPicture() 不崩、不回调、状态也不动 —— 界面别只根据「我自己开了 PiP」就摆出一个画中画按钮
  不支持时 init 收下的 contentSource 读回来是 nil：pip.contentSource == nil ? true
  再手动赋值一次，读回还是 nil、还是不相等：==nil ? true ===src ? false
  ok   所有 setter 在这条路径上都是**静默丢弃**：赋完读回 nil —— 千万别用「读回来是不是我要的对象」验证配置成功
  开关也一样：canStartPictureInPictureAutomaticallyFromInline 默认=false，设 true 读回=false
  requiresLinearPlayback 默认=false，设 true 读回=false
  调过 startPictureInPicture() 之后 isActive=false（没崩，但什么都没发生）
  老写法 init(playerLayer:) 是 **failable**：legacyPip == nil ? true（返回类型 AVPictureInPictureController?，AVPlayerLayer 版内部还会做设备校验）
  ok   用 init(playerLayer:) 时必须处理 nil；init(contentSource:) 不返回 nil，但会悄悄把 contentSource 扔掉 —— 两种写法各有各的失败方式
```

这一节是「静默失效」的标本：设备不支持时 `AVPictureInPictureController` 的**每个 setter
都吞掉赋值**，`startPictureInPicture()` 什么都不做也不报错，
`init(contentSource:)` 甚至不把传进去的 source 存下来。
所以「读回来验证配置成功」这条通用技巧在这里是**错的**，唯一可信的是
`isPictureInPictureSupported()` 与 `isPictureInPicturePossible`。

两种 init 的失败方式不同（`playerLayer:` 可失败、`contentSource:` 不失败但丢内容），
这一条决定了你写的是 `guard let` 还是写完还得查 `contentSource == nil`。

示例里还留了一条更狠的实测注记——不支持时读 `pip.playerLayer` 会直接 SIGSEGV
（头文件标 `nonnull`，运行时是 nil）。这一条会 crash，所以本章代码**绝不读它**，
只在注释里记下探针结论。写 PiP 代码时，「按头文件的 nonnull 直接用」在这里会付出闪退代价。

## 10) AVAsset / AVAssetTrack：两种读法，一份数据

`AVAsset` 有两套读取 API：iOS 15 之前的**同步属性**（`asset.duration`、`asset.tracks`）
和 iOS 15 起的 **`try await asset.load(...)`**。同一份数据，区别只在「谁去读文件、在哪个线程读」。

```
== 10. AVAsset / AVAssetTrack：两种读法，一份数据 ==
  旧写法（直接访问属性）：duration=0.3333333333333333 tracks=1 isPlayable=true hasProtectedContent=false
  轨：mediaType=vide（FourCC=vide）trackID=1
  轨：naturalSize=(320.0, 240.0) nominalFrameRate=29.999998
  轨：timeRange start=0.0000 duration=0.3333 naturalTimeScale=600
  轨：preferredTransform a=1.0 d=1.0 isEnabled=true isDecodable=true isSelfContained=true
  轨：estimatedDataRate=148608.0 totalSampleDataLength=6192 segments=1 requiresFrameReordering=true
  轨：formatDescriptions=1 个，首个的 mediaType FourCC=vide
  ok   Swift 里 AVMediaType.video.rawValue 是字符串 'vide'，CoreMedia 层它是 UInt32 1986618469 = 4 个 ASCII 字节拼的 FourCC
  ok   naturalSize 是 (320, 240)：编码器如实记录了写入时的宽高
  ok   nominalFrameRate 读回 29.999998，不是整数 30 —— 别拿 == 比 CGFloat/Double 帧率
  ok   轨道的 timeRange.duration 和资产的 duration 在这里相等（只有一条轨时正常）
  ok   一条 H.264 轨对应一个 CMFormatDescription
```

`29.999998` 这一条值得单独背下来：写 30fps 进去，读回来不是整数 30，
`nominalFrameRate == 30` 的断言必然随机红。要么用容差，要么比 `CMTime` 的整型刻度。

轨道上还有两个「同一段视频里不同时间轴」的量：

```
  轨：hasMediaCharacteristic(.audible)=false hasMediaCharacteristic(.visual)=true
  轨：minFrameDuration=0.0333（10 帧一段 → 每帧 0.0333 秒）
  轨：samplePresentationTime(forTrackTime: 0.1s)=0.1333 —— trackTime 与呈现时间不是一回事
  轨：segment(forTrackTime: 0.1s) 存在=true isEmpty=Optional(false)
  ok   0.1 秒落在唯一的 segment 里
```

新写法的对照，以及两个读法之间的关系：

```
  await duration=value=200 ts=600 valid=true indefinite=false secs=0.3333333333333333 tracks=1
  ok   两种读法拿到的是同一个数 —— 差别只在「谁去读文件、在哪个线程读」
  await naturalSize=(320.0, 240.0) nominalFrameRate=29.999998 timeRange.duration=0.3333 formatDescriptions=1
  await mediaCharacteristics=["AVMediaCharacteristicFrameBased", "AVMediaCharacteristicVisual", "public.main-program-content"] isEnabled=true
  ok   mediaCharacteristics 里的值是 'AVMediaCharacteristicVisual'/'AVMediaCharacteristicFrameBased' 这类字符串，连 public.main-program-content 也算一种特征
  ok   load 之后同步属性也能读了 —— load(_:) 的作用就是把值取进缓存
  -- load 之后同步读会怎样 --
  await isPlayable=true，同步 asset.isPlayable=true
  ok   已 load 过的键，同步属性直接吃缓存；没 load 过的键在 iOS 上会阻塞甚至死锁
  statusOfValue(forKey: 'duration')=2（unknown=0 loading=1 loaded=2 failed=3 cancelled=4）
  ok   load(.duration) 之后状态机停在 loaded=2
```

**`load` 的实质是「取进缓存」**：load 过的键，同步属性读起来就是纯内存操作；
没 load 过的键在 iOS 上同步读会阻塞（老代码里主线程读 `asset.tracks` 卡住界面就是这么来的）。
`statusOfValue(forKey:)` 是那台状态机的可见窗口，值域和 `AVKeyValueStatus` 一致（§8 开头列过）。

音频资产做对照（同一个 API 家族，另一套 FourCC）：

```
  wav：duration=value=44100 ts=44100 valid=true indefinite=false secs=1.0 tracks=1 mediaType=soun
  wav 轨首个 formatDescription：mediaType=soun 子类型=lpcm
  wav 轨：timeRange.duration=1.0000 nominalFrameRate=0.0 naturalSize=(0.0, 0.0)
  wav 轨 mediaCharacteristics=["AVMediaCharacteristicAudible", "public.main-program-content"]
  ok   AVMediaType.audio 的 FourCC 是 'soun'；PCM 真正的编码标签（lpcm/sowt）在 formatDescription 里，不在 mediaType 里
  ok   音频轨的 mediaCharacteristics 里是 AVMediaCharacteristicAudible
```

`nominalFrameRate=0.0`、`naturalSize=(0,0)` 是音频轨的正常形态——这两个字段对音频没意义，
但很多代码会顺手拿它们做「是不是视频」的判断；正确的判据是 `mediaType`/`mediaCharacteristics`。

FourCC 汇总（本章用到的常量全部当场解过）：

```
  -- 常见 FourCC 一览（全部来自本次运行用到的常量）--
  AVVideoCodecType：h264=avc1(cc=1635148593) hevc=hvc1(cc=1752589105) jpeg=jpeg(cc=1785750887)
  kAudioFormatLinearPCM=1819304813/lpcm kAudioFormatMPEG4AAC=1633772320/aac 
  AVAudioCommonFormat: otherFormat=0 pcmFormatFloat32=1 pcmFormatFloat64=2 pcmFormatInt16=3
  ok   kAudioFormatLinearPCM 解出 'lpcm'，kAudioFormatMPEG4AAC 解出 'aac '（注意末尾那个空格，FourCC 必须占满 4 字节）
```

**`aac ` 末尾是一个空格**，不是 `aac`；FourCC 永远是 4 字节。
日志里看到 `'fmt?'`、`'sowt'`、`'avc1'` 都按这个规则解（`AVAudioCommonFormat` 是例外，它是普通 Int 枚举）。

### 10 末尾的对照实验：为什么 §8 必须抢在 await 之前

```
  -- 对照：同一份播放实验，放到 await **之后**再跑一次 --
  此刻 DispatchQueue.main.async 排进去的 block 有没有被执行=false（pump 了 20 步）
  ok   await 之后连一个 main queue 的 block 都排不动 —— §8 那些回调全靠它，这就是「live 实验必须抢在 await 之前」的根因，跟 AVFoundation 无关
  §8 里跑得活蹦乱跳的同一套代码，这里：item.status=0 timeControlStatus=1 currentTime=value=0 ts=1 valid=true indefinite=false secs=0.0 periodic 回调数=0
  ok   item 停在 unknown(0)、currentTime 冻在 0.0000、回调一个都不来 —— 这是**脚本环境**的现象：真机/App 里主 runloop 一直在转、没人往被占住的 main queue 里嵌套排队列，不会遇到
```

这是本章方法论第 4 条的实证：顶层 `await` 一旦发生，主线程就停在 main queue 的 block 里，
此后 `RunLoop.current.run(until:)` 排不动 main queue，`DispatchQueue.main.async` 的 block
一个都不执行。AVFoundation 的回调（`finishWriting`、时间观察者、KVO 派发）几乎全走 main queue，
所以「live 播放类实验」必须排在第一个 `await` 之前。
**真机 App 里主 runloop 一直在转，不会遇到这件事**——不要把这条当成 AVFoundation 的性质。

## 11) AVAssetReader：音频轨与视频轨分别解码

`AVAssetReader` + `AVAssetReaderTrackOutput` 是「把文件解成样本」的通路，
和 §1 的 `AVAudioFile`（一次 `read` 给你一个 `AVAudioPCMBuffer`）是两条独立的路。

```
== 11. AVAssetReader：音频轨与视频轨分别解码 ==
  AVAssetReader.Status: unknown=0 reading=1 completed=2 failed=3 cancelled=4
  asset.loadTracks(withMediaType: .audio) 在 mp4 上取到的第一条=nil
  ok   loadTracks(withMediaType:) 是按类型筛轨的异步方法 —— 这条 mp4 没有音轨，返回空数组
  刚建好：status=0 timeRange.duration=value=0 ts=0 valid=true indefinite=false secs=inf
  ok   不设 timeRange 时 reader 的 duration 是 **+inf**（flags=5），不是资产的 0.3333 秒 —— 别拿它当循环上限，也别拿 isIndefinite 去判它
  canAdd(probeOut)=true
  startReading=true：解出 10 帧，宽=[320]，前 3 个 PTS=["0.0000", "0.0333", "0.0667"]
  结束：status=2 error=nil
  ok   写完 10 帧、读回 10 帧，status 走到 completed=2 —— copyNextSampleBuffer() 返回 nil 就是结束信号
  ok   像素 buffer 的宽度就是当初的 320，PTS 严格按 1/30 递增
```

`timeRange.duration` 默认是 **+inf**（`flags=5`，`isIndefinite` 反而是 false），
这是 §6 那张特殊值表的现场应用：`while` 循环的边界**不能**拿它算，
只能靠 `copyNextSampleBuffer()` 返回 `nil` 收尾。

音频侧（同一台 reader 换一条轨）：

```
  wav：startReading=true 读到 6 个 sample buffer、合计 44100 帧，首个 PTS=0.0000
  输出的 ASBD=id=lpcm ch=1 sr=44100.0 bpf=4 bits=32 framesPerPacket=1
  第一个 buffer 的字节数=32768（帧数 × mBytesPerFrame）
  ok   解码出来的总帧数和 AVAudioFile.length 一致（44100 帧）—— 两条读文件的通路对同一份字节的解释相同
  ok   6 个 buffer 才凑出 44100 帧，第一个 buffer 装 32768 字节（8192 帧 × 4 字节）—— 音频是分批给的，必须 while copyNextSampleBuffer
  status 一旦变成 completed/failed，reader 就不能复用；要重读得重新 new 一个 AVAssetReader
```

两条通路（`AVAudioFile` 与 `AVAssetReader`）对同一份字节给出同一个总帧数，
这是本章敢于跨节复用数字的依据。**reader 是一次性的**：状态进入 `completed/failed` 之后
不能重头再读，必须重建——这条和 §10 末尾「reader 不能复用」的直觉相反，很多人栽在这里。

## 12) 转码管线：reader → writer

把 §11 的 reader 输出直接喂给 §7 的 writer 输入，一行不落：

```
== 12. 转码管线：AVAssetReaderTrackOutput → AVAssetWriterInput ==
  tWriter.canAdd(aInput)=true
  读了 2 个 PCM sample buffer、44100 帧，append 失败=false
  await finishWriting() 之后 status=2 error=nil
  m4a 字节数=5447（源 wav 是 180496 字节）
  ok   整条管线一帧不丢：44100 帧进、44100 帧出，status=completed
  ok   64 kbps 的 AAC 把 176 KB 的 PCM 压到了 5447 字节 —— 压缩比就是转码存在的理由
  读回转码结果：duration=value=44100 ts=44100 valid=true indefinite=false secs=1.0 tracks=1 子类型=aac 
```

`outputSettings` 给 `nil` 的含义是「按文件里原样给我」（这里是线性 PCM），
writer 侧给 `[AVFormatIDKey: kAudioFormatMPEG4AAC, …]` 决定输出编码——
**reader 的 outputSettings 管解什么，writer 的管编什么**，两边不是一套字典。

这一节还留了一条我自己写错断言的现场，值得原样读：

```
  ok   读回来 duration 是 44100/44100 = 1.0000 秒，和源**一模一样**。这里有个必须交代的过程：写这一节时我先按「AAC 有 priming/编码器延迟，容器一定会把时长记长一点」的直觉把断言写成 47104/44100，跑出来直接 FAIL —— 这条管线上 CoreAudio 把 priming 消化在轨道内部，asset 这一层读到的就是 44100。教训有两层：①**时长相等不能当正确性判据**（它相等也许只是这一层没记 priming），要比的是上面那条帧数；②凡是「按理说应该」的数值，一律先跑一遍再写进断言，本章每条 expect 都是这么来的
  对照：同一段 finishWriting {} + 轮询在 §7（还没 await）好使，在这里就不行了 —— 实测 status 永远停在 writing=1、文件 0 字节，因为那个完成 block 排不进被占住的 main queue（§10 末尾的对照实验）。这就是本章后半段一律用 await finishWriting() 的原因
```

「AAC 有 priming 所以容器时长一定更长」是**听起来完全合理**的直觉，
真跑下来这条管线上 `AVAsset.duration` 就是 44100/44100。
所以「转码前后时长相等」不能当正确性判据，要比的是帧数；
而本章每一条数值断言都是先跑一遍再写下来的。

## 13) AVAssetExportSession：档位与兼容容器

`AVAssetExportSession` 是「给我一个现成档位」的高层封装，不用自己配 reader/writer。

```
== 13. AVAssetExportSession：preset、支持的容器、导出 ==
  AVAssetExportSession.Status: unknown=0 waiting=1 exporting=2 completed=3 failed=4 cancelled=5
  allExportPresets()=19 项；exportPresets(compatibleWith: 这段 mp4)=13 项
  ok   「所有档位」比「这份资产能用的档位」多 —— 拿 NotApplicable 之外的档位去建 session 可能直接返回 nil
  ok   视频资产不兼容 AppleM4A 档位；反过来音频资产也没有 640x480 这类视频档位可用
  建好 session：status=0 progress=0.0000
  supportedFileTypes=["com.apple.immersive-video", "com.apple.m4v-video", "com.apple.quicktime-movie", "public.mpeg-4"]
  timeRange.duration=inf metadata=nil audioMix=nil shouldOptimizeForNetworkUse=false
  ok   session 默认的 timeRange 也是 +inf（整条资产），不是 duration 的 0.3333
  导出结束=true status=3 error=nil 字节=7088
  ok   status=3(completed)；回调只是通知「结束了」，成功与否还得看 status 和 error
  ok   completed 时 progress 读回 1.0000
  ok   导出的 mp4 有内容
```

状态枚举**和 reader/writer 都不一样**（`completed=3`，不是 2），
把三套状态码当同一套来判是这类代码的常见 bug。`exportAsynchronously` 的回调
只代表「结束了」，成功与否还得读 `status` 与 `error`。

档位可用性由**资产内容**决定，不是全局常量：

```
  -- 用音频资产再问一次档位 --
  ok   同一段 PCM 的 wav 让 AppleM4A 出现在兼容表里，视频 mp4 的表里却没有 —— 档位可用性由**资产内容**决定，不是全局常量
```

还有一条在示例里被刻意绕开的：`estimatedMaximumDuration` / `estimatedOutputFileLength`
是 **async throws** 的估算属性，在本文件的顶层（main actor）里读会撞并发告警
（`non-sendable type 'AVAssetExportSession' exiting main actor-isolated context … cannot cross actor boundary`）。
本章要求零告警，所以不调用它们；真机 App 里在 `Task` 里 `try await` 读是没问题的。

## 14) AVAssetImageGenerator：缩略图

抓帧这件事的三个「不看文档就会错」的地方：默认不套 `preferredTransform`、
默认容差极宽、越界不报错。

```
== 14. AVAssetImageGenerator：缩略图 ==
  默认：appliesPreferredTrackTransform=false maximumSize=(0.0, 0.0) apertureMode=nil
  默认容差：requestedTimeToleranceBefore.isIndefinite=false after=false
  ok   默认不套用轨的 preferredTransform（手机竖拍的视频抓出来会是横的），maximumSize=(0,0) 表示原始尺寸
  await image(at: 5/30) -> CGImage 160x120，actualTime=value=0 ts=600 valid=true indefinite=false secs=0.0
  ok   maximumSize 是「装进这个框」，160x120 恰好等比例，所以输出就是 160x120
  ok   只要了 5/30 秒但默认容差极宽，实际给的是 0 秒那一帧 —— 要精确就得把 tolerance 设成 .zero
  容差设成 zero 后抓 7/30 秒：actualTime=value=140 ts=600 valid=true indefinite=false secs=0.23333333333333334 尺寸=320x240
  ok   tolerance=.zero 之后 actualTime 就是请求的那一帧（0.2333），尺寸回到原始 320x240
  越界时间（99 秒，资产只有 0.3333 秒）抓帧**没有**抛错，反而给了 actualTime=value=0 ts=600 valid=true indefinite=false secs=0.0 的 160x120
  ok   超出范围的请求不报错、不返回 nil，而是给你最近的一帧（这里是第 0 帧）—— 靠返回值判断时间合法性是判断不出来的
  纯音频（没有视频轨）资产抓帧抛错：domain=AVFoundationErrorDomain code=-11869 desc=Cannot Open
  ok   没有视频轨时是 -11869 'Cannot Open'，不是返回 nil
  文件不存在时抛错：domain=AVFoundationErrorDomain code=-11800 desc=The operation could not be completed
  ok   「文件打不开」是 -11800，和「没有视频轨」的 -11869 是两个码 —— 报错信息一样，code 才是区分依据
```

`actualTime` 是必须读的第二个返回值：请求 `5/30` 拿到的是 0 秒那一帧，
只有把 `requestedTimeToleranceBefore/After` 设成 `.zero` 才保证落点（代价是要解码更多帧、更慢）。
`image(at:)` 的 `CGImage` 尺寸由 `maximumSize` 约束（等比例装框），
`(0,0)` 才是原始尺寸——「缩略图为什么是糊的/为什么这么大」都在这两个字段里。

错误码对照表（本章 AVFoundation 侧实测到的）：`-11800` 打不开文件、
`-11869` 内容不支持（这里是没有视频轨）。**两者的 `localizedDescription` 几乎一样**，
区分只能靠 `code`。

## 15) AVAudioEngine：手动渲染 —— 把音频图变成可复现的纯函数

前面 `AVAudioPlayer` 那一节只能告诉你「它在播」，采样到底长什么样是看不见的。
`AVAudioEngine` 不一样：它是一条**数据流图**，节点（node）+ 连线（connection），
引擎按时间推进，每个渲染周期把图从头算到尾。真机上这件事由音频线程按 44100 分之一秒的节奏自动做，
headless 环境既没有扬声器也不该依赖墙钟，所以本章把它切到**手动渲染模式**
（`enableManualRenderingMode(.offline, format:maximumFrameCount:)`）：
你不推进时间，引擎一个采样都不算；你调 `renderOffline(frameCount:to:)` 要多少帧它就算多少帧。
同样的图、同样的输入 → 逐字节相同的输出，于是波形峰值可以写进 `expect`，
这一节的所有 `0.7071 / 0.3536 / 0.1768 / 0.0000` 都是这么来的。

### 15.1 新引擎的默认状态

```
== 15) AVAudioEngine：手动（offline）渲染 —— 把音频图变成可复现的纯函数 ==
  isRunning=false isInManualRenderingMode=false isAutoShutdownEnabled=false
  inputNode=AVAudioInputNode outputNode=AVAudioOutputNode mainMixerNode=AVAudioMixerNode
  attachedNodes=3 types=["AVAudioInputNode", "AVAudioMixerNode", "AVAudioOutputNode"]
  （注）上面这一行读的是**已经读过 inputNode/outputNode/mainMixerNode 之后**的引擎：探针实测只 new 完、一个属性都不碰时 attachedNodes=0，
        碰过那三个属性就变 3 —— 它们是**惰性创建**的，attachedNodes 只登记已经建出来的，不代表「图里应该有什么」
  mainMixer.numberOfInputs=8 numberOfOutputs=1 outputVolume=1.0000
  inputNode.inputFormat(forBus:0)  ch=2 sr=0.0 commonFormat=3 interleaved=true
  inputNode.outputFormat(forBus:0) ch=2 sr=0.0 commonFormat=3 interleaved=true
  mainMixer.outputFormat(forBus:0) ch=2 sr=44100.0 commonFormat=1 interleaved=false
  硬件输入格式那个 commonFormat 打印出来是 AVAudioCommonFormat(rawValue: 3) —— 本 SDK 的 Swift 枚举只有 otherFormat=0 / pcmFormatFloat32=1 / pcmFormatFloat64=2，CoreAudio 却返回了 3，于是它变成一个枚举里没有的 case
  ok   mixer 出口永远是 Float32 非交织（commonFormat=1）；inputNode 的格式则**由设备决定**，模拟器上没有真实输入，sampleRate 直接是 0.0
  ok   新引擎不 attach 任何节点也有 3 个，但 isRunning=false：attach/connect 只是画图，start() 才开始流动
  ok   mainMixer 默认 8 路进 1 路出（numberOfInputs=8 是这张图能同时挂几个源的硬上限）
  ok   outputVolume 只在 mixer 这类节点上有，AVAudioOutputNode 根本不响应这个 selector —— 想调总音量得找 mainMixerNode
```

四个点都要单独说：

**`attachedNodes` 是惰性的。** 只 `new` 完引擎、一个属性都不碰时它是 0；
读过 `inputNode`/`outputNode`/`mainMixerNode` 这三个属性之后立刻变成 3。
所以「图里有几个节点」这个问题不能拿 `attachedNodes.count` 回答，
它登记的是**已经被创建出来**的节点，不是「这张图应该有什么」。15.8 那一行只有四种类型、
没有 `AVAudioInputNode`，就是因为那段代码从没读过 `e.inputNode`。

**`mainMixer` 默认 8 路进 1 路出。** 想在同一张图上挂更多 `playerNode`，
`numberOfInputs=8` 就是硬上限；超过得再开一台 mixer 并 `attach` 到图上。

**硬件输入格式里藏着一个枚举外的 case。** `commonFormat` 印出来是
`AVAudioCommonFormat(rawValue: 3)`：Swift 侧这个枚举只有 `otherFormat=0`、
`pcmFormatFloat32=1`、`pcmFormatFloat64=2`，CoreAudio 却给了 3（那是 `FLOAT32` 之外的
`pcmFormatFloat64BigEndian`/设备专有格式一族）。于是 `switch` 这个枚举必须留 `@unknown` 兜底，
而且**比较**它的代码要么写 `rawValue`，要么走 `default`——拿 `.pcmFormatFloat32` 去 `==` 一个
`rawValue: 3` 永远不成立，这就是那种「格式判断为什么总进不去」的根因。
`sampleRate=0.0` 同理：模拟器没有真实输入设备，0.0 不是「未知」也不是错误，是设备给的原样。

### 15.2 enable 手动模式改写了整台引擎的时钟

```
  -- 15.2 enableManualRenderingMode(.offline, …) 改写了整台引擎的时钟 --
  enable 之后：isInManualRenderingMode=true manualRenderingMode 原始值=0（offline=0 realtime=1）
  manualRenderingFormat ch=2 sr=44100.0 commonFormat=1 interleaved=false maxFrameCount=1024 sampleTime=0
  inputNode.outputFormat(forBus:0) 变成 ch=2 sr=44100.0 commonFormat=1 interleaved=false —— 手动模式下 inputNode 不再是麦克风，而是你喂数据的口子
  ok   打开手动模式那一刻时间轴停在 0：offline 就是「时钟归你管」
  ok   你给的 format 和 maximumFrameCount 就是此后 renderOffline 的天花板，读回来一模一样
  重复 enable（把上限从 1024 改成 512）：没有抛错，manualRenderingMaximumFrameCount=512
  ok   enable 可以反复调，最后一次说了算 —— 它不是「已开启就报错」的那种 API
```

`offline=0`、`realtime=1`；`manualRenderingSampleTime` 从 0 开始，每 `renderOffline` 一次就前进
你请求的帧数——这就是本节用来判断「播没播完」的那根游标（15.11 的 E 组会说明为什么不能用 `isPlaying`）。
`enable` 是**幂等覆盖**而不是「已开启就报错」，所以切格式、改上限不需要先 disable。

### 15.3 一次要太多帧：抛错，不是给你静音

```
  -- 15.3 一次要太多帧：抛错，不是给你静音 --
  renderOffline(2048) 而 maximumFrameCount=1024：domain=com.apple.coreaudio.avfaudio code=-50 desc=The operation couldn’t be completed. (com.apple.coreaudio.avfaudio error -50.)
  ok   要的帧数超过 enable 时给的 maximumFrameCount → kAudio_ParamError(-50)，**抛错**而不是给你一段静音
  renderOffline(1024, to: 容量 256 的 buffer)：domain=com.apple.coreaudio.avfaudio code=-50
  ok   第二个红线：capacity 装不下你要的帧数，同样是 -50 —— 这两条线都跟数据内容无关，纯粹是尺寸校验
```

两条红线都是 `-50`（`kAudio_ParamError`）：请求帧数 > `maximumFrameCount`，
以及请求帧数 > 目标 buffer 的 `frameCapacity`。它们和图里连了什么、buffer 里有什么数据完全无关，
是纯粹的尺寸校验——反过来也说明：**拿到 -50 别去查音频图，先查这两个数**。

### 15.4 交织陷阱：`floatChannelData[1]` 不是右声道

这一节是本章最容易写错的一段索引代码，所以把三种目标格式并排放：

```
  -- 15.4 目标格式 interleaved=true 时，floatChannelData[1] 不是右声道 --
  mono ch=1 sr=44100.0 commonFormat=1 interleaved=false：frameLength=1024 peak=0.7071 ch0 前 6 个=["0.0000", "0.0313", "0.0626", "0.0937", "0.1247", "0.1554"]
                     单声道 buffer 的 floatChannelData 只有一条，索引 [1] 是**越界读** —— 探针实测这一步直接 SIGSEGV，所以先判 channelCount
  ok   channelCount 是声道数的唯一依据：mono 目标格式渲染出来仍然只有 1 条声道，索引 [1] 绝不能碰
  stereo 非交织 ch=2 sr=44100.0 commonFormat=1 interleaved=false：frameLength=1024 peak=0.7071 ch0 前 6 个=["0.0000", "0.0313", "0.0626", "0.0937", "0.1247", "0.1554"]
                     ch1 前 6 个=["0.0000", "0.0313", "0.0626", "0.0937", "0.1247", "0.1554"]
  ok   非交织时两条声道各自独立：这里左右声道内容相同，所以第 4 个采样逐位相等
  stereo 交织 ch=2 sr=44100.0 commonFormat=1 interleaved=true：frameLength=1024 peak=0.7071 ch0 前 6 个=["0.0000", "0.0000", "0.0313", "0.0313", "0.0626", "0.0626"]
                     ch1 前 6 个=["0.0000", "0.0313", "0.0313", "0.0626", "0.0626", "0.0937"]
  ok   交织时 ch1 就是 ch0 整体往后挪一格：L0 R0 L1 R1 挤在同一段内存里，floatChannelData[1] 不是右声道
```

把交织那一版翻译成索引公式，就是这段代码该长的样子：

```swift
if let data = buffer.floatChannelData {
    if buffer.format.interleaved {
        // 只有一条连续内存：data[0][frame * channelCount + channel]
        // 此时 data[1] 越界（Swift 不做边界检查），读它 = 崩溃或垃圾
    } else {
        // 每条声道各自一段：data[channel][frame]
    }
}
```

三种格式的峰值都是 `0.7071`——**交织只改索引方式，不改数值**。所以如果你发现
「换成交织格式之后波形变了」，那一定是索引写错了，不是引擎变了。
`AVAudioFile` 那一侧同样有这条线（§1 写的 wav 是交织的），15.13 会再撞一次。

### 15.5 三层顺序：引擎要 `start`、播放器要 `play`、队列里还得真有帧

这三层各自失败的表现完全不同，本节把它们逐层拆开：

```
  -- 15.5 三层顺序：引擎要 start、播放器要 play、队列里还得真有帧 --
  第 1 层 isRunning=false isPlaying=false：prepare()/start() 都没调，renderPeaks=["throw com.apple.coreaudio.avfaudio/-80802"]
  只 prepare() 不 start()：isRunning=false，renderPeaks=["throw com.apple.coreaudio.avfaudio/-80802"]
  ok   prepare() 不改变 isRunning —— 它只是预热，别指望它让 renderOffline 能跑
  补上 start()：isRunning=true isPlaying=false renderPeaks=["0.0000", "0.0000"]
  ok   start() 之前 renderOffline 抛 com.apple.coreaudio.avfaudio/-80802（AVAudioEngine.h 的 AVAudioEngineManualRenderingErrorNotRunning），**不是**给你静音。但补上 start() 也不会自动补救：那句 play() 是在引擎没跑时叫的，已经作废，isPlaying 仍是 false、渲染仍是 0.0000 —— **得再 play() 一次**
  同一台引擎、同一个节点，再 play() 一次：isPlaying=true renderPeaks=["0.3536", "0.0000"]
  ok   再叫一次 play() 就出数据了 —— 「全零」和「抛错」是两种完全不同的失败，修法也不同：抛错说明引擎没跑，全零说明播放器没 play 或队列没帧
  第 2 层 isRunning=true 但还没 play()：isPlaying=false renderPeaks=["0.0000", "0.0000"]
  ok   引擎在跑、buffer 也排进去了，只差 play() —— 这次不抛错，直接给你 0.0000 的静音。headless 下这种失败最阴：一切都「正常」，只是没声音
  第 3 层 play() 之后：isPlaying=true renderPeaks=["0.3536", "0.0000", "0.0000"]
  ok   顺序摆正，第一个 512 帧块就是 0.3536（0.5 的源 × 1/√2）—— 刚才暂停时排进去的 buffer 还在队列里，play() 立刻把它吐出来
  ok   第二块回到 0.0000：源只有 512 帧，正好一块的量 —— **渲染块数 × capacity 必须 ≤ 你排进去的总帧数**才有得看，这不是 bug，是队列空了
  源换成 2048 帧、capacity 1024，渲染 3 块 peaks=["0.3536", "0.3536", "0.0000"]
  ok   2048 帧正好喂满两块，第三块归零：2048/1024=2 —— 拿这个对照能把「队列排了多少帧」和「渲染要了多少帧」这两件事彻底对上
```

诊断顺序就照这个层次走：`throw …/-80802` → 引擎没 `start()`；
`0.0000` → 播放器没 `play()` 或者队列里没帧；有数但只有第一块 → 排进去的总帧数不够。
**最容易漏的是第一层那条**：在 `start()` 之前叫的 `play()` 不会报错，也不会排队，它是**作废**了——
补上 `start()` 之后必须再 `play()` 一次，这一条能解释相当比例的「我明明调了 play」。

### 15.6 `mainMixerNode` 的 −3 dB：0.5 进去不是 0.5 出来

```
  -- 15.6 mainMixerNode 的 −3 dB：0.5 进去不是 0.5 出来 --
  源幅度 1.0000 → 渲染峰值 ["0.7071", "0.7071"]；1/√2 = 0.7071
  ok   outputVolume 明明还是默认的 1.0，出来却少了 3 dB —— 数据经过 mixer 的求和级就带上 1/√2，这是写断言前必须知道的固定系数
  源幅度 0.5000 → 渲染峰值 ["0.3536", "0.3536"]（§1 那段 wav 生成时用的正是 0.5，所以本章几乎所有波形数字都以它为基准）
```

这一条决定了本章所有波形数字的读法：**先把实测峰值除以 `1/√2` 再和源幅度比对**。
`1.0 → 0.7071`、`0.5 → 0.3536`、`0.25 → 0.1768`、`0.125 → 0.0884`。
系数来自 mixer 的求和级，与 `outputVolume` 无关（默认 1.0 时也在）。

### 15.7 `outputVolume` 是线性增益，而且运行中改会斜坡

```
  -- 15.7 mainMixerNode.outputVolume：线性增益，不是 dB --
  先看「设得早晚」：同一个值，在 start() 之前设和之后设，第一个渲染块不一样
  start **之前**设 outputVolume=1.0000 → 4x1024 peaks=["0.7071", "0.7071", "0.7071", "0.7071"]
  start **之前**设 outputVolume=0.2500 → 4x1024 peaks=["0.1768", "0.1768", "0.1768", "0.1768"]
  ok   0.25 就是乘 0.25：0.7071 × 0.25 = 0.1768，四块全一致 —— outputVolume 是**线性**的，不是 dB，想按 dB 调自己换算 pow(10, dB/20)
  start **之前**设 outputVolume=0.0000 → 4x1024 peaks=["0.0000", "0.0000", "0.0000", "0.0000"]
  引擎已经跑着（makeOffline 里 start 过了）才设 outputVolume=1.0000 → 4x1024 peaks=["0.7071", "0.7071", "0.7071", "0.7071"]
  引擎已经跑着（makeOffline 里 start 过了）才设 outputVolume=0.2500 → 4x1024 peaks=["0.6942", "0.1768", "0.1768", "0.1768"]
  引擎已经跑着（makeOffline 里 start 过了）才设 outputVolume=0.0000 → 4x1024 peaks=["0.6898", "0.0000", "0.0000", "0.0000"]
  ok   运行中改音量，**第一个块是过渡值** 0.6898（不是原来的 0.7071，也不是目标 0.0000），从第二块起才落到目标 —— mixer 对参数做了斜坡以避免爆音。写单元测试时要么在 start 前设好，要么先丢掉一块再取数
```

两个结论，一个是单位、一个是时序。`outputVolume` 是**线性倍数**（0.25 就是乘 0.25），
不是分贝；换算关系 `线性 = pow(10, dB/20)`，反过来 −3 dB ≈ 0.708。
时序那一条更实用：运行中改参数，**第一个渲染块是斜坡上的过渡值**（0.6942 / 0.6898），
从第二块起才精确落到目标。所以「音量明明设了为什么第一帧不对」不是 bug，
是防爆音的设计；测试里要么在 `start()` 前设好，要么丢弃首块。

### 15.8 混音是「逐采样相加」：峰值既不是两路之和，也不是最大值

```
  -- 15.8 混音是「逐采样相加」：峰值既不是两路之和，也不是最大值 --
  单路 0.3 @440Hz → peaks=["0.2121", "0.2121"]（0.3 × 1/√2 = 0.2121）
  attach 第二个 playerNode 之后 attachedNodes=4 types=["AVAudioMixerNode", "AVAudioOutputNode", "AVAudioPlayerNode", "AVAudioPlayerNode"]
  （注）这一行的四种类型是 mainMixer + outputNode + 两个 playerNode；没有 inputNode，因为这段代码从没读过 e.inputNode —— attachedNodes 记的是**已经被创建**的节点，15.1 那个 3 是读过那三个属性之后的结果。想知道图里有什么，别拿它的个数当准
  两路各 0.3（440Hz + 880Hz）→ peaks=["0.3734", "0.3734"]
  ok   两路相加出来 0.3734：既不是 0.2121+0.2121=0.4242（两路不会在同一时刻同时到峰），也不是 0.2121（取最大）。sin(x)+sin(2x) 的数学极大值是 1.759 倍单路幅度，0.2121×1.759≈0.373，和实测对得上 —— **混音后的峰值由相位关系决定**，指望「两路音量各降一半就不失真」是错的
  ok   混音结果落在 (单路, 2×单路) 之间 —— 判断「有没有真的混进来」用这个区间最稳
```

两路正弦的峰不会在同一时刻到达，所以混出来的峰值**不是**两路之和；
但它也远大于单路，因为 `sin(x)+sin(2x)` 的数学极大值是单路幅度的 1.759 倍。
这两个数字给出一个非常实用的判据：**混音后的峰值一定落在 `(单路, 2×单路)` 之间**，
落在区间内说明真的混进来了，等于单路说明第二路没接上。
反过来的警告同样重要：两路各 0.3 混出 0.3734，再叠第三、第四路就会往上顶，
「每路都调到一半就不会失真」这个直觉是错的，失真与否要看相加后的**瞬时值**。

### 15.9 把起播点排到未来：`AVAudioTime(sampleTime:atRate:)`

```
  -- 15.9 把起播点排到未来：AVAudioTime(sampleTime:atRate:) --
  AVAudioTime(sampleTime: 512, atRate: 44100)：sampleTime=512 atRate=44100.0 isSampleTimeValid=true isHostTimeValid=false
  ok   这个构造器造出来的是**纯采样时刻**，没有 mach 绝对时间（isHostTimeValid=false）—— 离线渲染只认 sampleTime，正好配它
  起播点设在第 512 帧，渲染 4x512 peaks=["0.0000", "0.3536", "0.3536", "0.3536"]
  ok   第一块整块静音：引擎时钟从 0 走到 512 时数据还没被放行，从第二块起才逐块吐 0.3536 —— 「定时起播」在离线渲染里就是一块可复现的空白，真机上这块空白就是你听到的开头延迟
  AVAudioPlayerNodeBufferOptions 原始值：loops=1 interrupts=2 interruptsAtLoop=4
  ok   []（空集合，普通播放）→1 loops →2 interrupts（高优先级抢占）→4 interruptsAtLoop（在循环点抢占）；传 [] 就是不循环、不打断
```

`scheduleBuffer(_:at:options:)` 的 `at:` 收一个 `AVAudioTime`。
`AVAudioTime(sampleTime:atRate:)` 造出来的实例 `isSampleTimeValid=true`、`isHostTimeValid=false`——
只有采样号、没有 mach 绝对时间，正好是离线渲染唯一认的东西（另一个构造器给 hostTime，
离线模式下它没有意义）。起播点设在第 512 帧，第一块输出就是**整块静音**，
这块空白可复现、可断言，等价于真机上那段「开头延迟」。
`options` 是 `OptionSet`，空集合就是普通播放；`interrupts` 会抢占队列里在播的内容，
`interruptsAtLoop` 只在循环点抢占（适合过场音乐）。

### 15.10 `.loops`：一块 buffer 变成长流

```
  -- 15.10 options: .loops —— 一块 buffer 变成长流 --
  不循环：4x512 peaks=["0.3536", "0.0000", "0.0000", "0.0000"]
  .loops：6x512 peaks=["0.3536", "0.3536", "0.3536", "0.3536", "0.3536", "0.3536"] 渲染之后 isPlaying=true sampleTime=3072
  ok   普通模式：一块 512 帧的 buffer 只够一块输出
  ok   .loops 让同一个 buffer 反复回放：6 块全是 0.3536，样本号一路推进（3072=6×512），却不需要你再排任何数据 —— 循环发生在**播放器队列**层，不在 mixer 层
  reset() 之后**当场**读 isPlaying=true，再渲染 1 块 peaks=["0.0000"]
  ok   reset() 只清数据队列，**不动播放意图**：正在 .loops 的播放器 reset 之后 isPlaying 照样 true，只是再没东西可吐。对比 15.11 的 C 组（先 pause 再 reset 才读到 false）—— isPlaying 反映的是 play/pause/stop 这层，别拿它判断队列空不空
```

`.loops` 的循环由播放器队列自己完成，不需要回调补数据，也不消耗新的 `schedule` 调用；
`manualRenderingSampleTime` 照旧推进（6×512=3072），这是「它确实在动」的客观证据。
下一行的 `reset()` 是第一个信号：**清队列 ≠ 停播放器**，两个维度各管各的。

### 15.11 四个控制调用的差别，用三段直流 buffer 逐个照出来

`play()` / `pause()` / `reset()` / `stop()` 经常被当成同义词。
这一节排三段不同幅度的 buffer（0.5 / 0.25 / 0.125，过 mixer 后是 0.3536 / 0.1768 / 0.0884），
用「还能不能听到第三段」把四个调用的差别照出来：

```
  -- 15.11 四个控制调用的差别，用三段直流 buffer 逐个照出来 --
  A) 排三段、**忘记 play()**：isPlaying=false peaks=["0.0000", "0.0000", "0.0000"]
  ok   全静音且没有任何报错 —— 这是最常见的「我的音频怎么没声」根因，play() 不是可选步骤
  A) 补上 play()：isPlaying=true peaks=["0.3536", "0.1768", "0.0884"]
  ok   补 play() 之后从头把队列吐出来，三段幅度 0.5/0.25/0.125 × 1/√2 = 0.3536/0.1768/0.0884，一帧不差 —— 数据没丢，只是之前没人推它
  B) pause：播 2 块=["0.3536", "0.1768"] → pause() 当场读 isPlaying=false，再渲染 2 块=["0.0000", "0.0000"] → 再 play() 2 块=["0.0884", "0.0000"]
  ok   pause() 之后 isPlaying=false，渲染继续要帧只会拿到静音 —— 引擎的时钟不会替你把数据攒着
  ok   再 play() 从**暂停处**接着走：第三段 0.125×1/√2=0.0884 正好接上，说明 pause 保住了队列里的播放位置（和 reset/stop 的关键区别）
  C) pause() → reset() 当场读 isPlaying=false → play() → 渲染 2 块 peaks=["0.0000", "0.0000"]
  ok   先 pause() 再 reset()：isPlaying 停在 pause 留下的 false（reset 不改它，见 15.10）—— 两个调用合起来才是「彻底归位」
  ok   reset() 把**没播完的队列整段丢掉**：即使再 play() 也没有数据可吐，只剩静音 —— 想播回去得重新 schedule
  D) play() 之后立刻 stop()：当场读 isPlaying=false，渲染 2 块 peaks=["0.0000", "0.0000"] → 再 play() 渲染 2 块 peaks=["0.0000", "0.0000"]
  ok   stop() = 清队列 + 停播放器，而且不像 pause 那样留位置：再 play() 也是空的。要「停止后从头播」必须 stop() → 重新 schedule → play()
  E) A 组那个队列已经吐完的播放器：isPlaying 读回来=true
  ok   帧全吐光了 isPlaying 还是 true —— 它表示「播放器处于播放意图」，不表示「还有数据」。用 isPlaying 判断播没播完是错的，得盯 manualRenderingSampleTime 或者 completion 回调
```

整理成表，四个调用只在两个维度上不同——「队列丢不丢」和「播放意图停不停」：

| 调用 | 队列（已排但没播完的数据） | 播放位置 | `isPlaying` | 之后 `play()` |
|---|---|---|---|---|
| `pause()` | 保留 | **保留** | → false | 从暂停处继续 |
| `reset()` | **丢弃** | 归零 | 不变（这里停在 pause 的 false） | 队列已空，只剩静音 |
| `stop()` | **丢弃** | 归零 | → false | 队列已空，只剩静音 |
| 忘记 `play()` | 保留 | 未开始 | 一直 false | 从头吐出全部队列 |

两个结论值得单独抄下来：**`isPlaying` 只反映 play/pause/stop 这一层，
不能用来判断「播完了没有」**（E 组：帧全吐光了它还是 true）；
判断播没播完要盯 `manualRenderingSampleTime`（离线）或者 completion 回调（见 15.12）。
另外 `reset()` 和 `stop()` 都会丢队列，但**只有 `stop()` 会顺手把 `isPlaying` 改成 false**——
15.10 那行「reset 之后当场读 isPlaying=true」和这里的 C 组是同一个事实的两面。

### 15.12 `completionCallbackType`：离线渲染永远等不到 `.dataPlayedBack`

```
  -- 15.12 completionCallbackType：离线渲染永远等不到 .dataPlayedBack --
  AVAudioPlayerNodeCompletionCallbackType 原始值：dataConsumed=0 dataRendered=1 dataPlayedBack=2
  dataConsumed：渲染 3 块之后回调到达=true 记录=["dataConsumed type=0"]
  dataRendered：渲染 3 块之后回调到达=true 记录=["dataRendered type=1"]
  dataPlayedBack：渲染 3 块之后回调到达=false 记录=[]
  ok   dataPlayedBack 在离线渲染下**永远不来**：.dataPlayedBack 的含义是「声音真的从输出设备放出去了」，而手动模式根本没有设备。真机上能等到、测试里等不到的回调，就是这一类
```

三个档位是三个不同的时刻：`dataConsumed`（引擎把 buffer 从队列拿走）、
`dataRendered`（已经算进输出）、`dataPlayedBack`（真的从设备放出去了）。
前两个在离线渲染里会被 `renderOffline` 触发，第三个**永远不会来**——手动模式没有输出设备。
这是一个典型的「真机能跑、测试里死等」的坑：如果你的逻辑挂在 `.dataPlayedBack` 上，
无设备环境的测试必须换成 `.dataRendered`，或者干脆把这段逻辑做成可注入的 seam。

### 15.13 让播放器自己去读 `AVAudioFile`

`scheduleFile(_:startFrame:frameCount:loops:)` 省掉「读成 buffer 再排」这一步，
代价是文件语义（帧号、游标、写完没写完）直接暴露给你：

```
  -- 15.13 让播放器自己去读 AVAudioFile --
  shortFile.length=4410 帧（0.1 秒 × 44100）fileFormat ch=1 sr=44100.0 commonFormat=1 interleaved=true processingFormat ch=1 sr=44100.0 commonFormat=1 interleaved=false
  ok   lpcm 文件在磁盘上是**交织**的（fileFormat.interleaved=true），AVAudioFile 读出来给你的是非交织的 processingFormat —— 15.4 那套索引规则只对 processingFormat 成立
  scheduleFile 整段：渲染 6x1024 peaks=["0.3536", "0.3536", "0.3536", "0.3536", "0.3536", "0.0000"] manualRenderingSampleTime=6144
  ok   4410 帧 ÷ 1024 = 4.3 块，实测 5 块有声、第 6 块归零：最后一块虽然不满，正弦的峰仍然落在里面。**scheduleFile 不要求文件长度是渲染块的整数倍**
  scheduleSegment(startingFrame: 1102, frameCount: 1024)：渲染 3x1024 peaks=["0.3536", "0.0000", "0.0000"]
  ok   只排 1024 帧就只有一块输出：startingFrame 是**文件里的帧号**，不是时间；1024 帧 ÷ capacity 1024 = 正好一块
  scheduleSegment(4000, 请求 5000 帧) 而文件只有 4410 帧：渲染 4x1024 peaks=["0.3536", "0.0000", "0.0000", "0.0000"]
  ok   请求 5000 帧但 4000 之后只剩 410 帧可读：**不抛错、不裁剪、也不告诉你少读了** —— 第一块里那 410 帧照常出声（0.3536），后面三块是静音。区间合法性只能自己校验 startingFrame + frameCount ≤ length，别指望 API 报错
```

`startingFrame` 是**帧号**，不是时间，也不是字节偏移；换算靠 `processingFormat.sampleRate`
（这里 1102 帧 ≈ 0.025 秒）。越界不报错的这条尤其危险——`frameCount: 0` 表示「读到文件尾」，
但一个超出 `length` 的正数会被静默截断，唯一的防线是自己写
`precondition(startingFrame + frameCount <= file.length)`。

`AVAudioFile` 那一侧的游标同样值得单独记：

```
  把 framePosition 设成 3 之后 read(8)：frameLength=8 采样=["0.0935", "0.1241", "0.1542", "0.1837", "0.2124", "0.2404", "0.2674", "0.2933"] 读完 framePosition=11
  ok   framePosition 就是「下一次 read 从哪一帧开始」，设成 3 读出来的第一个采样正是理论值 0.0935（0.5·sin(2π·440·3/44100)）—— §1 那个「read 到 EOF 抛错」也是同一根游标，**读之前**就能改起点，不用重开文件
  ok   读完游标自动前进 8（3 → 11）：AVAudioFile 是有状态的，同一个实例读第二次就是接着往下读
  游标停在文件尾再 read 抛错：type=_GenericObjCError domain=Foundation._GenericObjCError code=0
  ok   和 §1 一致：AVAudioFile 的 EOF 是 Objective-C 的 BOOL 失败映射成 Swift 错误，域是 Foundation._GenericObjCError、code=0 —— **拿 code 判断错误类型在这里没意义**，只能靠 domain 加「读到尾」这个上下文
```

`framePosition` 可读写：设成 3，读出来的第一个采样就是理论值 `0.0935`
（`0.5·sin(2π·440·3/44100)`）。也就是说想「从中间开始读」不需要重开文件，改游标即可；
想判断读到哪了，读游标比数自己累加的帧数可靠。EOF 那个错误的 `code` 是 0、
域是 `Foundation._GenericObjCError`——这是 ObjC 的 `BOOL` 失败被 Swift 桥成错误的通用形状，
**code 里没有任何信息**，只能靠 domain 加上「我刚刚在做什么」来判。

最后是 §2 那个坑在引擎这条路上的复现，也是本节最贵的一条：

```
  写入器还攥在手里：heldWriter.length=4410（写了 4410 帧，头部还没回填所以读到的不是 4410）
  同一时刻另开一个 AVAudioFile(forReading:)：length=0 → scheduleFile 渲染 2x1024 peaks=["0.0000", "0.0000"]
  ok   §2 那个坑在引擎这条路上原样复现：wav 头还没落盘 → 读侧 length=0 → scheduleFile 排进去的就是空区间 → 全程静音，**一个错误都没有**
  撒手（heldEngineWriter = nil）之后重开：length=4410 → 渲染 4x1024 peaks=["0.3536", "0.3536", "0.3536", "0.3536"]
  ok   只是把写入器释放掉，同一个 URL 立刻读出 4410 帧并渲染出满峰值 —— **引擎不背这个锅，是文件自己还没写完**
```

同一段字节，写入器还活着时读侧 `length=0`，撒手之后 `length=4410`。
注意 15.13 前面那条「请求 5000 帧只剩 410 帧也不报错」——这里 `length=0` 走的正是同一条静默路径：
空区间 → 全静音 → 零错误。**引擎不背这个锅，是文件自己还没写完。**

### 15.14 `disableManualRenderingMode()` 之后，图回到「真实设备」那一套

```
  -- 15.14 disableManualRenderingMode() 之后，图回到「真实设备」那一套 --
  disable 之前：isInManualRenderingMode=true isRunning=true
  disable 之后：isInManualRenderingMode=false isRunning=false manualRenderingFormat=ch=0 sr=0.0 commonFormat=1 interleaved=false maxFrameCount=0 sampleTime=0
  ok   disable 顺手把引擎**停了**（isRunning=false）：手动模式和自动模式是互斥的两套时钟，切回去必须先 stop
  ok   manualRenderingFormat 变成 ch=0 sr=0 的空壳、maxFrameCount 归 0：这两个属性只在手动模式下有意义，退出后读它们只会拿到占位值
  退出手动模式之后 renderOffline 抛错：domain=com.apple.coreaudio.avfaudio code=-80800
  ok   com.apple.coreaudio.avfaudio/-80800 = AVAudioEngine.h 里的 AVAudioEngineManualRenderingErrorInvalidMode —— 和 15.5 的 -80802(NotRunning) 是**两个不同的原因**：一个是模式不对，一个是引擎没跑
  inputNode.outputFormat(forBus:0) 回到 ch=2 sr=0.0 commonFormat=3 interleaved=true —— 又变回设备格式（15.1 那个 sr=0 的硬件输入）
  ok   退出手动模式把 inputNode 的格式也一并还原：这条路上「格式」从来不是你能定的，是设备给的
  disable 之后再 start()：isRunning=true
  再 play()：isPlaying=true（此时图接的是不存在的真实输出，数据出不去，但调用全部合法）
  ok   同一台引擎可以从手动模式切回普通模式并再次 start() —— 不需要重建
  detach(AVAudioPlayerNode)：attachedNodes 4 → 3，节点反查自己的 engine=nil
  ok   方法名是 **detach**，AVAudioEngine 上没有 remove(_:)，别按名字猜。detach 之后节点自己反查 engine 就是 nil —— 这是「节点真的被摘掉了」的可靠信号。（这里没有先 disconnect 就 detach，探针实测不崩；正规顺序还是先 disconnect 再 detach，两个调用各管一件事：连线归 disconnect，节点归 detach。）
```

三个「退出之后读到的是占位值」要记住：`manualRenderingFormat` 变成 `ch=0 sr=0` 的空壳、
`maxFrameCount` 归 0、`isRunning` 被顺手改成 false。这三个都不是错误，是「该属性在此刻无意义」。
错误码也在这里换了家族：`-80800`（模式不对）对 `-80802`（引擎没跑），
两者都是 `com.apple.coreaudio.avfaudio` 域，靠 code 区分。
最后一组是本章收尾的图管理：`detach`（不是 `remove`），以及「节点反查 `engine` 为 nil」
这个可靠的摘除信号。

## 16) 效果器与 AVAudioConverter：把「听上去怎样」变成一列数字

`AVAudioUnit` 家族（EQ / Delay / Reverb / Varispeed / TimePitch）也是引擎图里的节点，
所以 15 节那套离线渲染照样能把它们逐个照清楚：一块正弦进去，几块峰值出来，不靠耳朵。
这一节还有第二个主题，而且比数字更重要——**参数是存起来的，不是校验过的**：
越界的值照样原样读得回来，坏的结果出现在渲染出来的数字里，而不是一句报错。

### 16.1 五个内置效果单元的出厂值

```
== 16) 效果器与 AVAudioConverter —— 把「听上去怎样」变成一列数字 ==
  AVAudioUnitEQ() 无参构造：bands=16 globalGain=0.0000 bypass=false
  AVAudioUnitEQ(numberOfBands:3)：bands=3，bands[0] 和 bands[1] 是同一个对象=false
  band 出厂值：filterType=0 bypass=true frequency=40.0000 gain=0.0000 bandwidth=0.5000
  AVAudioUnitDelay：delayTime=1.0000 wetDryMix=50.0000 feedback=50.0000 lowPassCutoff=15000.0000
  AVAudioUnitReverb：wetDryMix=0.5000 bypass=false
  AVAudioUnitVarispeed：rate=1.0000
  AVAudioUnitTimePitch：rate=1.0000 pitch=0.0000 overlap=8.0000
  ok   无参的 AVAudioUnitEQ() 给 **16 条频段**（默认不是 1 条），要几条就写 numberOfBands: —— 别指望数组越界替你兜住，16 条足够你把默认值当 1 条用
  ok   band 出厂就是 bypass=true，频点 40Hz、带宽 0.5 个倍频程：新建 EQ 挂上去声音一点没变。要生效必须**逐条** bypass=false，只设 frequency/gain 是不够的（16.4 用数字证明）
  ok   两个单元的 wetDryMix 默认值差一百倍：reverb 是 0.5、delay 是 50（单位都是百分比，0=全干、100=全湿）。reverb 那个 0.5 等于「湿声只占半个百分点」，16.5 会看到它有多没存在感
```

三个默认值是三件不同的事，都值得单独背下来：无参 `AVAudioUnitEQ()` 是 **16 条 band**
（`bands[i]` 是各自独立的对象，改 `bands[0]` 不会连带 `bands[1]`）；
每条 band 出厂 `bypass=true`，所以「挂个 EQ」在默认状态下等于挂一根导线；
`wetDryMix` 在 delay 上是 50、在 reverb 上是 0.5——**同一个属性名、同一个单位（百分比），
差一百倍**，混响出厂几乎全干。

滤波器和混响预置的 rawValue 全表（`switch` 时靠这些数落进正确的 case）：

```
  EQ 的九种滤波器类型（AVAudioUnitEQFilterType 的 rawValue）：
    parametric = 0
    lowPass = 1
    highPass = 2
    resonantLowPass = 3
    resonantHighPass = 4
    bandPass = 5
    bandStop = 6
    lowShelf = 7
    highShelf = 8
  混响预置（AVAudioUnitReverbPreset）挑五个：
    smallRoom = 0
    mediumHall = 3
    plate = 5
    cathedral = 8
    largeHall2 = 12
```

这一节还有一份「名字不存在」清单，写之前逐个用 `swiftc` 试过，原文照引：

```
  （注）本节写之前拿 swiftc 逐个试过名，下面这些**在 iPhoneSimulator18.2.sdk 里不存在**，
        编译器原文各引一句（都是 error: …）：
        value of type 'AVAudioUnitDelay' has no member 'maxDelayTime' —— 延迟上限不由这个属性给
        type 'AVAudioUnitEQFilterType' has no member 'notch' —— 要陷波用 bandStop
        value of type 'AVAudioUnitReverb' has no member 'componentDescription'
        type 'AVAudioUnitReverbPreset' has no member 'largeChurch' —— 预置只到 largeHall2=12
        value of type 'AVAudioConverter' has no member 'sampleRateConverterComplexity'
        cannot find 'AVAudioConverterQuality' in scope —— 16.8 会看到质量参数其实是个裸 Int
      网上教程里这些名字出镜率很高，那是旧 SDK 或者别的框架。补全会顺着旧文档提示你，编译器不会。
```

`maxDelayTime`、`notch`、`componentDescription`、`largeChurch`、`AVAudioConverterQuality`
这些名字在旧教程里出镜率很高。Xcode 的补全会顺着旧文档提示你一些已经消失的成员，
**编译器不会**——所以本章的规矩是：凡是「我记得有个属性叫 X」，先编译一次再写进正文。

### 16.2 `wetDryMix`：干湿各 50% 时，峰值反而比纯干声大

把 `delayTime` 和 `feedback` 都归零，只动干湿比，就得到一条干净的曲线：

```
  -- 16.2 wetDryMix：干湿各 50% 时，峰值反而比纯干声大 --
  delayTime=0 feedback=0 wet=0 → ["0.3536", "0.3536"]
  delayTime=0 feedback=0 wet=50 → ["0.4935", "0.4935"]
  delayTime=0 feedback=0 wet=100 → ["0.3534", "0.3534"]
  wet=50 / wet=0 = 0.4935/0.3536 = 1.3956，而 √2 = 1.4142
  ok   **delayTime=0 时干路和湿路是同一份信号**，各乘 √0.5≈0.7071 再相加 → 0.3536×√2=0.4935；wet=100 全走湿路，等于把干声乘回 0.7071，于是 0.3534 又贴回基准。中间那个点比两端都响，是**等功率交叉淡入淡出**的形状，不是「50% 就是平均」的直线。做「淡出干声」这种效果时，走到 wet=50 附近整体会鼓起来 3 dB
```

干湿比走的是**等功率曲线**（两路各乘 `√(wet)` 与 `√(1-wet)`），不是线性平均。
所以中间点比两端都响（0.4935 > 0.3536），比值 1.3956 对着 `√2 = 1.4142`。
实践含义很直接：用 `wetDryMix` 做「淡入混响/回声」时，走到中点附近整体会鼓起 3 dB，
要么补偿总增益，要么改用线性交叉并接受中点变轻。

### 16.3 delay：一块 = 512 帧 = 11.610 ms，`delayTime` 给到这个数就对得上

```
  -- 16.3 delay：一块 = 512 帧 = 11.610 ms，delayTime 给到这个数就能对上 --
  512/44100*1000 = 11.6100 ms —— 手动模式的最大块就是「一格」的长度
  delayTime=0.0000 feedback=0.0000 wet=50.0000 → 6x512 peaks=["0.4935", "0.4935", "0.2402", "0.0000", "0.0000", "0.0000"]
  delayTime=0.0116 feedback=0.0000 wet=50.0000 → 6x512 peaks=["0.2500", "0.4650", "0.2499", "0.2402", "0.0000", "0.0000"]
  delayTime=0.0116 feedback=0.5000 wet=50.0000 → 6x512 peaks=["0.2500", "0.4650", "0.2508", "0.2408", "0.0012", "0.0000"]
  delayTime=0.0232 feedback=0.5000 wet=50.0000 → 6x512 peaks=["0.2500", "0.2500", "0.2499", "0.2499", "0.2402", "0.0012"]
  delayTime=0.0116 feedback=0.9000 wet=50.0000 → 6x512 peaks=["0.2500", "0.4650", "0.2516", "0.2414", "0.0022", "0.0000"]
  delayTime=0.0116 feedback=0.0000 wet=100.0000 → 6x512 peaks=["0.0000", "0.3534", "0.3534", "0.3397", "0.0000", "0.0000"]
  delayTime=0.0116 feedback=0.0000 wet=0.0000 → 6x512 peaks=["0.3536", "0.3536", "0.0000", "0.0000", "0.0000", "0.0000"]
  （源 1024 帧恰好两块，所以干声只出现在第 1、2 块，第 3 块起只剩尾巴）
  ok   delayTime=0.011610（正好一块）之后，第 1 块掉到 0.2500（它被拆成干湿各半，只剩 0.3536×0.7071），第 2 块 0.4650 = 第 1 块的回声撞上第 2 块的干声。回声确实**晚一块**出现，用峰值就能数出来
  ok   feedback=0.5 时第 5 块冒出 0.0012，feedback=0.9 时同一块是 0.0022：反馈量决定**回声自己再被回放几次**。0.9 的尾比 0.5 长一倍，但绝对值已经掉到千分位，听感上是「尾巴变长」而不是「变响」
  ok   wet=100（全湿）的第 1 块是 0.0000：干声被完全关掉，而回声要等 delayTime 到点才有内容 —— 「第一块静音」是 wet=100 的正常形状，不是 bug
  delayTime=10 赋完读回=10.0000，引擎 start 得住吗：isRunning=true
  ok   delayTime 的单位是**秒**（属性上没有任何提示），写 10 就是十秒回声，既不报错也不夹取。要按毫秒设得自己除 1000：0.011610 才是一块
```

这一组数字的读法：`delayTime` 每多一块（0.011610 秒 = 512 帧），整列峰值就往右挪一格。
`wet=100` 那一行的第一块是 `0.0000`——**这是正常形状**，不是 bug：干声关掉了，
回声又还没到点。最后一条是单位问题：`delayTime` 是**秒**，属性名和类型上没有任何提示，
写 `10` 就是十秒延迟、不报错、不夹取。想按毫秒设必须自己除以 1000。

### 16.4 EQ：默认全旁通；生效后 +12 dB 直接越过 1.0

```
  -- 16.4 EQ：默认全旁通；生效后 +12 dB 直接越过 1.0 --
  1 条 band、出厂 bypass=true → ["0.3536", "0.3536", "0.3536"]
  parametric 440Hz gain=0 bypass=false → ["0.3536", "0.3536", "0.3536"]
  parametric 440Hz gain=+12dB bypass=false → ["1.3298", "1.4025", "1.4070"]
  ok   +12 dB 把 0.3536 顶到 1.4070 —— 峰值**超过 1.0**。Float32 的图不会自己削波（数字照样如实给你 1.4070，第一块 1.3298 是滤波器还在建立响应），但下一步写进 16 bit 文件、或者交给真实输出设备就是一段削顶。先降源电平，再给 EQ 增益
  lowPass 200Hz，源是 440Hz → ["0.1345", "0.0715", "0.0715"]
  ok   440Hz 的正弦被 200Hz 低通压到 0.0715（不到原峰值的 1/4，第一块 0.1345 是过渡段）：类型是**每条 band 各有一个** filterType，不是整台单元一个
  三条 band 全旁通 + globalGain=6 → ["0.7054", "0.7054"]
  ok   globalGain 是整台单元的增益，和 band 旁不旁通无关：+6 dB → 0.3536×1.995=0.7054（6 dB 理论是 ×2，AudioUnit 的增益曲线在满量程附近差一点点）。只想「整体响一点、别的都不动」就用它，别逐条加 gain
  整台单元 bypass=true（band 自己 bypass=false）→ ["0.3536", "0.3536", "0.3536"]
  ok   两级开关同时存在时**单元级 bypass 赢**：band 配得再细，只要 AVAudioUnitEQ.bypass=true 就整台旁通。做「效果开/关」对比只该动这一个，别去逐条翻 band
```

四行数字把 EQ 的四件事说完：不改东西的 EQ 等于导线（默认态）、`gain` 是相对量（0 dB 时数字纹丝不动）、
`+12 dB` 会把峰值推过 1.0、`globalGain` 和 band 的 bypass 是两个层级。

最值得抄走的是**削波那条**：Float32 的图不会自己削波，`1.4070` 会如实留在 buffer 里，
所以离线渲染「看起来一切正常」；等到写进 16 bit PCM 或者交给真实输出设备，
超出 ±1.0 的部分才变成削顶。**先降源电平，再给 EQ 增益**，顺序反了就只能靠听发现。
另一条是两级 bypass 的优先级：做「效果开/关 A-B 对比」只动单元级 `bypass`，别逐条翻 band。

### 16.5 reverb：`loadFactoryPreset` 不动 `wetDryMix`

```
  -- 16.5 reverb：loadFactoryPreset 不动 wetDryMix --
  新建、一个预置都没加载：wetDryMix=0.5000 bypass=false
  loadFactoryPreset(.cathedral)（raw=8）之后：wetDryMix=0.5000 bypass=false
  loadFactoryPreset(.largeHall2)（raw=12）之后：wetDryMix=0.5000 bypass=false
  ok   五个预置之后 wetDryMix 仍是 0.5000，和不加载时一字不差：**loadFactoryPreset 只换混响内部那一整套参数（衰减时间、预延迟、高频阻尼…），不碰干湿比**。这是「加了混响却听不出来」的头号原因
  largeHall2，保持出厂 wet=0.5 → ["0.3518", "0.3512", "0.0010"]
  largeHall2 + 手动 wet=50 → ["0.1768", "0.1289", "0.0964"]
  largeHall2 + 手动 wet=100 → ["0.1014", "0.1902", "0.1928"]
  ok   出厂 wet=0.5 的三块：0.3518 / 0.3512 就是没挂混响的 0.3536 少掉一点点，第 3 块只剩 0.0010。源 1024 帧早就渲染完了，第三块本该是尾音的地盘，0.0010 说明湿声根本没起来
  ok   wet=50 之后第 2、3 块是 0.1289 / 0.0964 —— 源结束之后还有非零峰值，**那就是混响尾音**；第 1 块降到 0.1768 是干声被分走一半功率的结果。这一组是本章最能说明「混响是时间上的延展」的数字
  ok   wet=100（全湿）反而一块比一块响：0.1014 → 0.1902 → 0.1928。混响是**输入越多积累越响**的，短促正弦的干声过去了，能量还在墙之间叠 —— 别用「第一块的峰值」判断混响强度
  源只有 512 帧（一块）、wet=100，渲染 8 块看尾巴：
    smallRoom  → ["0.1303", "0.3701", "0.2353", "0.2472", "0.1444", "0.1137", "0.0827", "0.0741"]
    cathedral → ["0.0000", "0.0000", "0.0302", "0.0577", "0.0442", "0.0743", "0.0564", "0.0395"]
  ok   cathedral 的前两块是**纯静音**，第 3 块才 0.0302，随后 0.0577 / 0.0743 慢慢往上爬：大空间预置自带 pre-delay，声音要先「走到墙」再反射回来。小空间 smallRoom 第一块就有 0.1303。所以判断混响至少渲染八块，两块就下结论一定读错
  ok   smallRoom 的第 2 块 0.3701 比第 1 块 0.1303 高，也比干声基准 0.3536 高：混响和干声在湿路里叠起来了。峰值超过「源」本身是混响图的常态，不是增益算错
```

「加了混响听不出来」的头号原因就是这条：预置换的是内部那一整套参数（衰减时间、预延迟、
高频阻尼……），**不换干湿比**，出厂那 0.5（百分比）得自己抬到 50 以上才看得见。
其次，混响是时间上的延展：判断它不能看第一块峰值，要渲染足够多的块看尾巴——
`cathedral` 的前两块是纯静音（pre-delay），第三块才起来慢慢爬。
`smallRoom` 第二块 0.3701 甚至超过干声基准 0.3536，**这是常态**：湿路和干路在叠。

### 16.6 变速：`varispeed` 连着音高一起改，`timePitch` 保住音高改时长

```
  -- 16.6 变速：varispeed 连着音高一起改，timePitch 保住音高改时长 --
  varispeed rate=2，源 2048 帧 → 4x512 peaks=["0.3536", "0.3536", "0.3538", "0.0000"]
  ok   rate=2 把 2048 帧压成约 1024 帧的输出：三块满峰值（0.3536/0.3536/0.3538，第三块是跨在边界上的那半块）之后第 4 块彻底空。峰值高度没变 —— **变速不动增益**，动的是时长（顺带把音高抬一个八度）
  timePitch rate=1.5，源 2048 帧 → ["0.3183", "0.3506", "0.3249", "0.0287"]
  ok   timePitch 的每块峰值都不齐平（0.3183 / 0.3506 / 0.3249）：它是把信号切成小片、重叠加回去的，块边界的对齐关系被打散了，最后 0.0287 是残余的叠音尾巴。**峰值参差不齐正是 timePitch 在干活的迹象**，别把它当失真
  timePitch pitch=+1200 音分（升一个八度）、rate=1 → ["0.3215", "0.3546", "0.3582", "0.3769"]
  timePitch overlap=4（出厂 8） → ["0.3470", "0.3535", "0.3535"]
```

`varispeed` 是「磁带式的」：改速率必然连音高一起改，实现便宜、峰值不动；
`timePitch` 是「时间弹性」：`rate`/`pitch`/`overlap` 三个独立维度，
代价是峰值变得不齐平——**参差不齐恰好是它在重叠加窗的证据**，不是失真。
`pitch` 的单位是**音分**（1200 = 一个八度），`overlap` 是叠加窗片数（出厂 8）。

然后是这一节的核心警告——**没有任何一层替你校验范围**：

```
  越界赋值（还没进引擎）：rate=100.0000 pitch=5000.0000 overlap=999.0000
  attach+prepare+start 之后再读：rate=100.0000 pitch=5000.0000 overlap=999.0000 isRunning=true
  此时 t.engine 反查出来的就是刚 attach 的那台引擎=true —— 一个节点同一时刻只属于一台引擎
  用这组越界值渲染 4x512 → ["0.0322", "0.0211", "0.0072", "0.0006"]
  ok   **没有任何一层替你校验范围**：写 100 就读 100，装进正在运行的引擎之后还是 100。头文件注释里的 Range 只是文档，Swift 属性是个存值的桶
  ok   越界的后果长这样：0.0322 → 0.0006 一路衰减，几乎听不见。不抛错、不返回 nil，只是结果不再是你要的东西 —— 这类 bug 只能靠**断言渲染出来的数字**抓住
  varispeed rate=0.0001（放慢一万倍）→ ["0.0000", "0.0001", "0.0020", "0.2977"]，属性读回=0.0001
  ok   2048 帧被拉成两千万帧的规模，前几块都还在同一个波峰前面慢慢爬，第 4 块才到 0.2977：越界值能把「时长」这个维度玩到完全失控，而所有调用一律返回成功
```

`rate=100`、`pitch=5000`、`overlap=999` 一路写进去、attach、`prepareToPlay`、`start()`，
每个调用都成功，属性读回来还是那三个荒唐数字；渲染出来的峰值掉到 0.0322→0.0006。
头文件注释里写的 Range 只是文档，Swift 属性就是个存值的桶。
这类 bug 的**唯一**防线是断言渲染出来的数字（或者自己写参数校验），
返回值和错误码在这里一个都不会出现。
顺带那条 `t.engine` 反查也不是随手写的：一个节点同一时刻只能属于一台引擎，
把同一个 `AVAudioUnit` 实例 attach 到第二台会直接 abort（16.11 末尾记了原文）。

### 16.7 没有 playerNode 也能灌数据：`inputNode` 的手动喂数回调

```
  -- 16.7 没有 playerNode 也能灌数据：inputNode 的手动喂数回调 --
  setManualRenderingInputPCMFormat 返回=true
  inputNode.outputFormat(forBus:0)=ch=1 sr=44100.0 commonFormat=1 interleaved=false
  喂 0.25 的直流，渲染 3x512 → peaks=["0.1768", "0.1768", "0.1768"]
  回调共 3 次：["capacity=512 given=512", "capacity=512 given=512", "capacity=512 given=512"]
  已经渲染过之后再设一次 返回=false
  ok   返回 true 表示「这条路通了」，但它只登记回调，不保证有数据 —— 真正的证据在下面：回调被调了 3 次、渲染出非零峰值
  ok   0.25 的直流出来是 0.1768 = 0.25×0.7071：**和 15.6 同一个 −3 dB**。这条 −3 dB 是 mainMixerNode 的，跟数据是谁喂进来的无关 —— playerNode 路径和 inputNode 路径撞出同一个系数，正好说明它不是播放器的怪癖
  ok   回调参数 capacity 就是 renderOffline 要的那这么多帧；给满 512 就正好对上。少给（例如 capacity=512 只填 100 帧）也是合法的，引擎会再来要
  ok   已经 start/渲染过之后再想换一个喂数闭包 —— 返回 false，旧闭包继续用。**喂数入口只有开机前那一次机会**
  （注）闭包必须返回 `UnsafePointer<AudioBufferList>`，写法是 `feed.audioBufferList`；
        直接把 AVAudioPCMBuffer 返回给它是编译不过的。buffer 本身要留在闭包捕获的范围里活着（这里用 let feed），
        引擎拷走的是那块裸内存，函数返回后 buffer 就被释放的话，读到的会是垃圾。
```

`setManualRenderingInputPCMFormat(_:inputHandler:)` 是**开机前唯一一次**的机会：
一旦 `start()`/渲染过，再设返回 `false`，旧闭包继续用。
闭包签名返回的是 `UnsafePointer<AudioBufferList>`（写 `feed.audioBufferList`），
不是 `AVAudioPCMBuffer`，而且那块 buffer 必须活着——引擎拷的是裸内存，
闭包捕获的 buffer 一被释放，读到的就是垃圾。返回值 `true` 只代表「这条路登记上了」，
真正的证据是回调被调用了几次、渲染出来是不是非零。

### 16.8 `AVAudioConverter`：默认值、质量参数是裸 Int、`primeMethod` 决定开头怎么接

```
  -- 16.8 AVAudioConverter：默认值、质量参数是裸 Int、primeMethod 决定开头怎么接 --
  inputFormat=ch=1 sr=44100.0 commonFormat=1 interleaved=false outputFormat=ch=1 sr=48000.0 commonFormat=1 interleaved=false
  sampleRateConverterQuality：类型=Int 默认=64
  primeInfo 默认：leadingFrames=0 trailingFrames=0
  primeMethod 默认=1（pre=0 normal=1 none=2）dither=false downmix=false magicCookie=nil
  channelMap 默认：1→1=[0]
  quality=0 status=0 out.frameLength=1114 head=["0.0019", "0.0626", "0.1315", "0.1902"]
  quality=32 status=0 out.frameLength=1114 head=["0.0019", "0.0626", "0.1315", "0.1902"]
  quality=64 status=0 out.frameLength=1114 head=["0.0018", "0.0625", "0.1318", "0.1896"]
  quality=127 status=0 out.frameLength=1114 head=["0.0018", "0.0624", "0.1320", "0.1894"]
  ok   质量参数在 Swift 里就是**裸 Int**，默认 64（头文件注释给的 medium 档）。没有 AVAudioConverterQuality 这个枚举可以用（16.1 注），写 0/32/64/127 都照原样读回，编译器不管越界
  ok   quality=0 和 quality=127 的前四个采样就不一样（0.0019/0.0626/0.1315/0.1902 vs 0.0018/0.0624/0.1320/0.1894）：重采样算法真的换了，差别在第四位小数上。这种差异**听不出来但逐字节不相同**，所以本章所有对照实验都固定默认质量
```

`sampleRateConverterQuality` 的类型是 `Int`，不是枚举——16.1 那条 `cannot find 'AVAudioConverterQuality' in scope`
就是这件事的编译期证据。`primeMethod` 默认 `.normal`，`dither`/`downmix` 默认 false。
**质量档位的差异在第四位小数**：听不出来，但逐字节不同。这一条对写测试的人来说是关键——
本章所有对照实验都固定默认质量，否则快照无法复现。

`primeMethod` 三档给的是**三种输出帧数**：

```
  primeMethod raw=0 status=0 out.frameLength=1080 head=["0.4219", "0.3833", "0.3381", "0.2872", "0.2313"]
  primeMethod raw=1 status=0 out.frameLength=1114 head=["0.0018", "0.0625", "0.1318", "0.1896", "0.2509"]
  primeMethod raw=2 status=0 out.frameLength=1149 head=["-0.0000", "-0.0000", "-0.0000", "0.0000", "0.0000"]
  算术参考：1024 × 48000/44100 = 1114.5578 帧
  ok   同一份 1024 帧输入，三档 primeMethod 给出三种输出帧数：**pre=1080（少 34 帧，它拿输入去预热滤波器了，开头那段被吃掉 —— 看它的 head 是 0.4219 起步，正弦早就过了零点）；normal=1114（正好等于 1024×48000/44100 向下取整）；none=1149（比理论值还多，因为前后都按静音补，head 全是 -0.0000/0.0000）**。做转码要保证首尾不漏就得显式选档位，默认 .normal 是「零延迟」折中
```

这一条是转码首尾偏差的根源：`.pre` 拿输入的前段去预热滤波器，于是**输出少了 34 帧**、
开头内容直接被吃掉（head 从 0.4219 起步，正弦早就过了零点）；`.none` 前后按静音补，
输出反而比理论值多；`.normal` 是零延迟折中。要「首尾一帧不差」必须显式选档并对账帧数。

### 16.9 4410 帧 44100→48000：一次 convert 给不完，得轮到 `.endOfStream`

闭包版 `convert(toBuffer:error:)` 的循环形状是本章最需要背下来的代码之一：

```
  -- 16.9 4410 帧 44100→48000：一次 convert 给不完，得轮到 endOfStream --
  理论输出帧数：4410 × 48000/44100 = 4800.0000
  第一次 convert（容量给满 4800）：status=1 out1.frameLength=4096 err=nil
  第二次（闭包报 .endOfStream，raw=2）：status=0 out2.frameLength=704
  第三次还问：status=2 out3.frameLength=0
  合计=4800 帧；out1 peak=0.5000
  out2 ch0[0]=-0.1445 ch1[0]=-0.1445
  ok   第一次只交出 **4096 帧**（converter 自己定的块大小，跟你给的 4800 容量无关），status=inputRanDry=1 —— 意思是「我嘴里的输入不够填满你要的输出，再喂」。看到 1 不能当错误抛出，那是继续喂的信号
  ok   第二次报 endOfStream 之后剩余 **704 帧**全部出来（4096+704=4800，正好等于理论值），status 变回 haveData=0。**endOfStream 是逼出尾巴的那一句**：不报它，最后 704 帧永远留在 converter 里
  ok   第三次同样调用返回 endOfStream=2、frameLength=0 —— 这就是循环该停的条件。OutputStatus 三个数：haveData=0 inputRanDry=1 endOfStream=2 error=3
  ok   峰值四舍五入到四位仍是 0.5000（源幅度就是 0.5）：**AVAudioConverter 不带那 −3 dB**（对比 15.6 的引擎和 16.7 的 0.1768）。它只是重采样/换声道，增益一律不碰。同一段音频走引擎出 0.3536、走 converter 出 0.5，电平差就是这么来的
  ok   channelMap=[0,0] 把单声道复制进两个声道，所以 out2 的 ch0[0] 与 ch1[0] 完全相等
```

`4096 + 704 = 4800`，正好等于 `4410 × 48000/44100`。三个数字对应三个必须分开处理的分支：
`haveData=0` 继续、`inputRanDry=1` 再喂输入、`endOfStream=2` 停循环、`error=3` 才是真错。
**最常见的写法错误是把 `inputRanDry` 当失败抛出**，也常见的是永远不报 `.endOfStream`
（于是尾巴上那 704 帧永远留在 converter 里，转出来的文件短一截）。
另外 `AVAudioConverter` **不带 −3 dB**：同一段 0.5 幅度的音频走引擎出 0.3536、
走 converter 出 0.5000——两条通路对比时这个系数差就是「电平为什么不一样」的答案。

### 16.10 `channelMap` / `downmix`：立体声压成单声道，默认只留左声道

```
  -- 16.10 channelMap / downmix：立体声压成单声道，默认只留左声道 --
  channelMap 默认：1→1=[0] 1→2=[0, 0] 2→1=[0]
  downmix=false（出厂默认）：ch0[10]=0.8000 status=0 channelMap=[0]
  downmix=true：ch0[10]=0.5000 status=0 channelMap=[0]
  channelMap=[1,0]：ch0[10]=0.2000 status=0 channelMap=[1]
  channelMap=[5]（越界索引）：ch0[10]=0.8000 status=0 赋完读回=[0]
  ok   输入是「左 0.8 / 右 0.2」的立体声：默认 downmix=false 时输出 **0.8000**，也就是 channelMap=[0] 直接取第 0 个声道，右声道整条丢掉；downmix=true 才是 0.5000 =（0.8+0.2)/2。**「压成单声道只听见左边」是这个默认值造成的**，不是 bug
  ok   channelMap=[1,0] 之后输出 0.2000 —— 数组第 i 个元素的意思是「输出的第 i 个声道取输入的哪个声道」
  ok   越界索引不抛错也不 abort（和 16.6 的属性一样宽容），但**你写进去的值没保住**：赋 [5] 之后读回是 [0]。这类静默改写只能靠赋值后立刻读回来发现
```

`channelMap` 的语义是「输出的第 i 个声道取输入的哪个声道」，不是权重表。
2→1 的默认映射是 `[0]`——**丢右声道**；要平均得把 `downmix` 打开。
赋一个越界索引（`[5]`）既不抛错也不 abort，但值被静默改回 `[0]`：
这类属性唯一的检查手段是**赋完立刻读回来**。

### 16.11 一次性 `convert(to:from:)`：换声道可以，换采样率一律抛错

```
  -- 16.11 一次性 convert(to:from:)：换声道可以，换采样率一律抛错 --
  同格式 44100/1→44100/1，容量=输入长度 512：成功 out.frameLength=512
  同格式，容量 1024 > 输入 512：成功 out.frameLength=512
  2→1 声道（采样率不变），容量 512：成功 out.frameLength=512
  重采样 44100→48000，容量 4410：抛错 domain=NSOSStatusErrorDomain code=-50 out.frameLength=0
  重采样 44100→48000，容量 4801：抛错 domain=NSOSStatusErrorDomain code=-50 out.frameLength=0
  重采样 44100→48000，容量 4802：抛错 domain=NSOSStatusErrorDomain code=-50 out.frameLength=0
  重采样 44100→48000，容量 9000：抛错 domain=NSOSStatusErrorDomain code=-50 out.frameLength=0
  汇总 code：帧数不变的三个=[0, 0, 0]，要变采样率的四个=[-50, -50, -50, -50]
  ok   **只要帧数要变（这里是 44100→48000），容量给 4410、4801、4802 还是 9000 都一律抛 NSOSStatusErrorDomain/-50（paramErr）**，而且 out.frameLength 停在 0 —— 抛错之后它没写过这个 buffer。一次性 API 的用途是打包/解包与声道合并，重采样必须用 16.9 那个闭包版；这条结论是四次真实调用换出来的，不是读文档读出来的
```

这条结论值四次实验：一次性 API 只能做**帧数不变**的转换（同格式拷贝、交织↔非交织、声道合并/拆分），
一旦要变采样率就 `-50`，容量怎么凑都没用。要重采样只能用闭包版。

一次性版还有一个**直接终止进程**的坑，因为本章要求 stderr 为空，只记探针原文：

```
  （注）一次性版本还有一个会**直接终止进程**的坑，探针实测（本文件的示例不敢留它，判定 3 要求 stderr 为空）：
        输出 buffer 的 frameCapacity 小于输入 buffer 的 frameLength 时不是抛错，是 NSException：
        *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
        'required condition is false: outputBuffer.frameCapacity >= inputBuffer.frameLength'
        栈顶是 -[AVAudioConverter convertToBuffer:fromBuffer:error:]，exit=134（Abort trap）。
        闭包版没有这个约束（它自己按块取数据），这也是选闭包版的第二个理由。
```

最后是两个「错误信息帮不了你」的实测，都值得一背：

```
  闭包版喂 2 声道输入给期望 1 声道的 converter：status=3 out.frameLength=512
  NSError domain=NSOSStatusErrorDomain code=-1 desc=The operation couldn’t be completed. (OSStatus error -1.)
  ok   **喂错声道数不会 abort，但结果很难看**：status=error=3、NSError 给的是 code=-1（genericErr），描述里连格式名字都没有，而 out.frameLength 已经被改成了 512（内容是没换过的垃圾）。所以调用之前自己核对 inBuffer.format == cv.inputFormat，别指望错误信息告诉你哪里错了
  输出 buffer 用了 converter 的**输入**格式（44100）：status=3 frameLength=0
  NSError domain=NSOSStatusErrorDomain code=1718449215 这个 code 按 FourCC 解=fmt?
  ok   输出 buffer 格式不对时 frameLength 老老实实停在 0（比上一个错误干净），错误码 1718449215 用 §6 那个 fourcc 一解就是 **'fmt?'** —— CoreMedia/AudioToolbox 的很多错误码本身就是 FourCC，认得这个套路比背错误码有用
```

`1718449215` 按 FourCC 解出来是 `'fmt?'`——`kAudioFormatNotSupportedError`。
**CoreAudio 的一大类错误码就是四个 ASCII 字符拼成的整数**，认得这个套路
（§6 那个 `fourcc` 小函数）比背错误码表有用。

本章撞过的三次「不是抛错而是 SIGABRT」，原文都留在示例注释里（放进正文会把进程带走）：

```
  （注）本章示例写到这里，撞过两次「不是抛错而是 SIGABRT」，两条都在探针里复现过，
        放在示例里会把整个进程带走，所以只记原文：
        1) 单声道 buffer 排进输出格式是立体声的 playerNode：
           reason: 'required condition is false: _outputFormat.channelCount == buffer.format.channelCount'
           栈顶 -[AVAudioPlayerNode scheduleBuffer:atTime:options:completionHandler:]，exit=134。
           也就是说 15 章反复强调的「连线时的 format 要和你 schedule 的 buffer 一致」，违反的代价是进程没了
        2) 同一个 AVAudioUnit 实例 attach 到第二台引擎：
           reason: 'required condition is false: nil == owningEngine || GetEngine() == owningEngine'
           栈顶 -[AVAudioEngine attachNode:]，exit=134 —— 16.6 里那句 t.engine 反查就是在盯这个所有权
        3) 想走 KVC 的捷径拿参数：AVAudioUnitTimePitch().value(forKey: "parameterTree")
           reason: '[<AVAudioUnitTimePitch 0x…> valueForUndefinedKey:]: this class is not key value coding-compliant for the key parameterTree.'
           NSUnknownKeyException → exit=134。这正好是 §8 那条规矩的另一种死法：**KVC 的键名错了不返回 nil，是抛异常**
```

三条共同的形状是：`required condition is false: <一条 Swift 里读得懂的不变量>`。
它们不是「返回错误码」的 API，是运行时的前置断言——
所以「连线 format 要对齐 buffer」和「一个节点只属于一台引擎」这两条
只能靠写法保证，编译器与 `try` 都拦不住。

## 17) MediaPlayer：锁屏 / 控制中心 / 耳机线控那套「系统联动」

前 16 节都是 AVFoundation 的自我封闭世界：声音从哪来、变成什么数字。
用户按锁屏上的暂停、按耳机上的下一曲，走的却是另一个框架 `MediaPlayer`。
这套东西在 headless 模拟器上「听不见」，但**它的默认值、键名、状态机全部可查**，
而联动的 bug 九成出在三件事上：键名写错、状态没回、命令没使能——恰好全能断言。
这一节不播音乐（模拟器里没有媒体库），只做四件事：读默认值、写进去再读回来、
把常量真正等于哪个字符串打出来、看清权限被拒时各 API 长什么样。

### 17.1 `MPNowPlayingInfoCenter`：只有一个字典和一个播放状态

```
== 17) MediaPlayer：锁屏 / 控制中心 / 耳机线控那套「系统联动」 ==
  刚拿到手：nowPlayingInfo=nil playbackState=0
  MPNowPlayingPlaybackState：unknown=0 playing=1 paused=2 stopped=3 interrupted=4
  设成 .playing 之后读回=1
  写进去之后现在共 5 项
    title：键名常量本身就是字符串 "title"，值=Optional("示例曲目")
    artist：键名常量本身就是字符串 "artist"，值=Optional("示例作者")
    duration：键名常量本身就是字符串 "playbackDuration"，值=Optional(44.1)
    elapsed：键名常量本身就是字符串 "MPNowPlayingInfoPropertyElapsedPlaybackTime"，值=Optional(3.0)
    rate：键名常量本身就是字符串 "MPNowPlayingInfoPropertyPlaybackRate"，值=Optional(1.0)
  ok   playbackState 是**你自己写进去的**一个枚举（unknown=0 playing=1 paused=2 stopped=3 interrupted=4），系统不会替你对着 AVPlayer 改它。写完之后锁屏转不转圈，全看你有没有在暂停时把它设成 .paused —— 这是联动 bug 的第一名
  ok   时长/进度/倍速这类要参与锁屏进度条推算的值必须是 NSNumber 系的标量，塞 CMTime 或字符串系统读不到。这里 44.1 秒就是 §1 那段 wav 的长度
```

整个中心就是一个 `[String: Any]?` 加一个枚举，没有队列、没有异步。
两族键名的命名规矩**完全不同**，这一节把字符串本体印出来核对：

```
    elapsed：键名常量本身就是字符串 "MPNowPlayingInfoPropertyElapsedPlaybackTime"，值=Optional(3.0)
  ok   字典的键**就是这些常量的字符串值**，而这两族的命名规矩完全不同：MPMediaItem 那族全小写（MPMediaItemPropertyTitle 其实是 "title"），MPNowPlayingInfoProperty 那族却等于**自己的名字**（elapsed 那一条的字符串就是 MPNowPlayingInfoPropertyElapsedPlaybackTime 整串）。写中文键、把 title 首字母大写成 "Title"、猜一个 "elapsedPlaybackTime" 都不报错，锁屏上只是一片空白 —— 把字符串本体印出来核对，是这一节唯一的价值（这条 expect 我第一版按直觉写成 "elapsedPlaybackTime"，跑出来直接 FAIL）
  （注）MPNowPlayingInfoCenter 上可以写的键远不止这五个，但**只有 iOS 版本支持的那些才生效**，
        越新的键在越旧的系统上是静默忽略（不抛错、不打印）。本章只用了从头文件里当场读到名的那几个。
```

`MPMediaItemProperty*` 那族的字符串值是**全小写短名**（`"title"`、`"artist"`、`"playbackDuration"`），
`MPNowPlayingInfoProperty*` 那族的字符串值**等于符号名本身**。
写错的代价不是报错，是锁屏上一片空白（17.6b 会把这件事演一遍）。

### 17.2 `MPRemoteCommandCenter`：命令默认全是使能的，等你接单

```
  shared() 上的命令共 20 条，默认 isEnabled 与实际类型：
    play：isEnabled=true 类型=MPRemoteCommand
    pause：isEnabled=true 类型=MPRemoteCommand
    stop：isEnabled=true 类型=MPRemoteCommand
    togglePlayPause：isEnabled=true 类型=MPRemoteCommand
    previousTrack：isEnabled=true 类型=MPSkipTrackCommand
    nextTrack：isEnabled=true 类型=MPSkipTrackCommand
    seekForward：isEnabled=true 类型=MPRemoteCommand
    seekBackward：isEnabled=true 类型=MPRemoteCommand
    skipForward：isEnabled=true 类型=MPSkipIntervalCommand
    skipBackward：isEnabled=true 类型=MPSkipIntervalCommand
    changePlaybackRate：isEnabled=true 类型=MPChangePlaybackRateCommand
    changePlaybackPosition：isEnabled=true 类型=MPChangePlaybackPositionCommand
    like：isEnabled=true 类型=MPFeedbackCommand
    dislike：isEnabled=true 类型=MPFeedbackCommand
    bookmark：isEnabled=true 类型=MPFeedbackCommand
    rating：isEnabled=true 类型=MPRatingCommand
    changeShuffleMode：isEnabled=true 类型=MPChangeShuffleModeCommand
    changeRepeatMode：isEnabled=true 类型=MPChangeRepeatModeCommand
    enableLanguageOption：isEnabled=true 类型=MPRemoteCommand
    disableLanguageOption：isEnabled=true 类型=MPRemoteCommand
  当前 isEnabled=true 的有 20/20 条
  ok   **命令出厂就是 isEnabled=true**，但没人 addTarget 的话，用户按下去系统得到的是「没有处理者」，锁屏上那个按钮直接不出现。也就是说：**使能≠有人接**；要屏蔽某个按钮是把它 isEnabled=false，不是「不注册」
  ok   实际类型（上面每行都印了）和直觉对不上两处：**切歌**才是子类 —— previousTrack/nextTrack 是 MPSkipTrackCommand；而**看得到进度条的** seekForward/seekBackward 反而是裸 MPRemoteCommand，参数不在命令上、在 handler 收到的事件对象里。倍速默认空数组这条 expect 顺便钉死：supportedPlaybackRates 出厂就是 []
```

二十条命令的默认状态是同一句话：**全部使能**。所以「我没注册是不是就没有这个按钮」是反的——
按钮出现与否取决于**有没有 handler**，`isEnabled` 是你主动关掉某条命令时用的开关。
类型分布也和直觉错位：切歌是 `MPSkipTrackCommand`，跳过固定秒数是 `MPSkipIntervalCommand`，
而 `seekForward/seekBackward`（界面上那个拖动进度条）反而是裸 `MPRemoteCommand`，
参数在事件对象里。

几条参数的默认值，逐条都能坑人：

```
  skipForward：preferredIntervals=["10.0000"]
  设成 [15,30] 之后读回=["15.0000", "30.0000"]
  ok   跳过时长是个**数组**（界面上给你一串候选档位），默认只有 10 秒这一档。旧文档里的 skipInterval 单数属性在本 SDK 不存在，写它会编译不过
  changePlaybackRate：supportedPlaybackRates=[]（出厂是空的）
  给了 [0.5,1,1.5,2] 之后读回=["0.5000", "1.0000", "1.5000", "2.0000"]
  ok   倍速命令和上面那条正好相反：**默认不支持任何倍速**（空数组），必须自己声明，播放控件上才会出现倍速选项。这就是「我明明注册了倍速命令，界面上却没有」的答案
  like(MPFeedbackCommand)：isActive=false localizedTitle=""
  设过之后：isActive=true localizedTitle="收藏"
  ok   MPFeedbackCommand 出厂 isActive=false、localizedTitle 是**空串**（不是曲目名，也不是「喜欢」这种默认文案）。标题不设，控制中心上那个按钮就没有字；点亮与否(isActive)也完全是你自己维护的布尔值，系统不会因为用户点了一下就替你自己翻 —— 翻转要写在 handler 的返回值之后自己做
  rating(MPRatingCommand)：minimumRating=0.0000 maximumRating=0.0000
  ok   MPRatingCommand 出厂 minimumRating 和 maximumRating **都是 0** —— 上下限相等意味着这条命令没有任何可用刻度，用户端看到的五星/星级评分根本点不动。要它生效必须自己写 maximumRating = 5（这条命令是 MPRatingCommand，handler 事件里才带 rating）
```

四条默认值分两种失败模式：`preferredIntervals`/`supportedPlaybackRates` 是**数组**
（前者默认 `[10]`，后者默认**空**——这就是「注册了倍速命令却没有倍速选项」的答案）；
`localizedTitle`/`isActive`/`maximumRating` 不设就是**没字、没亮、没刻度**。
`skipInterval`（单数）在本 SDK 已经不存在，只有 `preferredIntervals`。

命令侧还有两组枚举和 handler 的形状：

```
  changeRepeatMode.currentRepeatType=0 （MPRepeatType：off=0 one=1 all=2）
  changeShuffleMode.currentShuffleType=0 （MPShuffleType：off=0 items=1 collections=2）
  ok   **注意这两族枚举的数值和 17.3 播放器上的 MPMusicRepeatMode/MPMusicShuffleMode 完全不同**：命令这边 off=0 one=1 all=2（压根没有 default/none 两档），播放器那边 default=0 none=1 one=2 all=3。同一屏上 currentRepeatType=0 说的是 Off，而 sys.repeatMode 读回 1 说的是 none —— 数字长得像、含义差一档，把一族的 rawValue 直接塞给另一族的属性，编译不拦、运行不报，界面上就是「单曲循环」和「不循环」互换
  handler 收到的事件类（只声明、不触发，用来验这些名字在本 SDK 写得出来）：["MPRemoteCommandEvent", "MPSkipIntervalCommandEvent", "MPSeekCommandEvent", "MPRatingCommandEvent", "MPChangePlaybackRateCommandEvent", "MPFeedbackCommandEvent", "MPChangePlaybackPositionCommandEvent"]
  MPRemoteCommandHandlerStatus 各档 rawValue：success=0 noSuchContent=100 noActionableNowPlayingItem=110 deviceNotFound=120 commandFailed=200
  addTarget 返回的 token 类型=__NSCFString
  ok   **注册了 handler 也不等于能被调用**：这一节里没有系统去点它，handled 当然是空。能断言的只有「addTarget 给我一个 token、removeTarget(token) 能摘掉」。真实触发要在真机上按控制中心/耳机线控，或者点锁屏 —— 那属于本章的诚实边界（见文末）
  ok   token 的真实类型是 String（ObjC 侧那边是个 __NSCFString），不是你以为的 id/AnyHashable：拿错类型去 removeTarget 会摘不掉，处理者越注册越多
```

`MPRemoteCommandHandlerStatus` 不是 0/1/2 顺序排下来的，是 `0 / 100 / 110 / 120 / 200`——
别拿「非 0 即失败」的直觉去排优先级，也别自己算相邻差值。
`addTarget` 给的 token 实际是 `String`，摘除时必须原样传回同一个类型。

### 17.3 `MPMusicPlayerController`：同名的两种播放器，行为完全不同

```
  -- 17.3 MPMusicPlayerController：同名的两种播放器，行为完全不同 --
  systemMusicPlayer 的 Swift 类型=MPMusicPlayerSystemController
  applicationQueuePlayer 的 Swift 类型=MPMusicPlayerApplicationController
  老 applicationMusicPlayer 的 Swift 类型=MPMusicPlayerApplicationController（注意它和上面 applicationQueuePlayer **动态类型同名**，靠 type(of:) 分不出新老播放器）
  两者 playbackState=0/0
  MPMusicPlaybackState：stopped=0 playing=1 paused=2 interrupted=3 seekingForward=4 seekingBackward=5
  nowPlayingItem：sys=nil app=nil
  indexOfNowPlayingItem（NSUInteger）：sys=0 app=0
  MPMusicRepeatMode：default=0 none=1 one=2 all=3，sys.repeatMode=1
  MPMusicShuffleMode：default=0 off=1 songs=2 albums=3，sys.shuffleMode=1
  ok   两个属性返回的**不是同一个类**：type(of:) 打出来 systemMusicPlayer 是 MPMusicPlayerSystemController（头文件里它的静态类型写作 MPMusicPlayerController<MPSystemMusicPlayerController>，是个「类 + 协议」组合，所以动态类型和静态类型不一样），applicationQueuePlayer 是 MPMusicPlayerApplicationController（在你自己进程里放队列）。拿错播放器时 setQueue 看着成功了，声音却在别处
  ok   模拟器里没有正在播的媒体：playbackState=stopped=0、nowPlayingItem=nil。这就是「联动看起来没生效」的真实原因 —— **不是你代码写错了，是根本没有媒体**
```

`systemMusicPlayer`（控制系统音乐 app）和 `applicationQueuePlayer`（在自己进程里放队列）
是两个不同的动态类型，接口同名。选错的那个，`setQueue` 会「成功」而声音在别处。
旧的 `applicationMusicPlayer` 和新的 `applicationQueuePlayer` **动态类型同名**，
`type(of:)` 分不出新老——想区分只能看你调的是哪个属性。

空队列与「不报错」的行为，是这一节最实用的一段：

```
  MPMediaItemCollection(items: [])：count=0 items.count=0 representativeItem=nil mediaTypes=0
  两边都 setQueue(with: 那个空队列) 之后 playbackState=0/0 nowPlayingItem=nil/nil
  刻意 repeatMode = .default、shuffleMode = .default 之后读回=1/1
  ok   空集合本身没毛病：count=0、items 是空数组（不是 nil）、representativeItem=nil —— 集合里没曲目时代表曲目就是 nil。有毛病的是它的**构造写法**，见下面那条注
  ok   prepareToPlay()/setQueue(with:) 在「媒体库不存在」这台机器上**不报错也不抛错**（这两个方法本身都不 throws），状态仍是 stopped。MediaPlayer 的失败一律不通知你，只体现在状态值上，所以每次调用之后自己去读 playbackState 是唯一可靠的检查
  ok   头文件给 indexOfNowPlayingItem 的注释写着 "May return NSNotFound if the index is not valid (e.g. an empty queue…)"，可这台机器在**空队列**上给的是 0，而同一时刻 nowPlayingItem 是 nil。NSUInteger 的 NSNotFound 是 18446744073709551615，所以 `if p.indexOfNowPlayingItem == NSNotFound` 这种判法在这里永远为假，会把「没有在播」读成「正在播第 0 首」。要判有没有曲目，读 nowPlayingItem 是不是 nil，别读下标
```

三件事叠在这里：**MediaPlayer 的错误几乎不走 `throws`**（这两个方法本身都不抛），
所以检查方式只能是调完之后自己读状态；`repeatMode = .default` 读回来是 `none=1`
（`.default` 不是「一个值」，是一个「让系统决定」的请求，落下来就变成某一档）；
以及 `indexOfNowPlayingItem` 在这台机器上**不返回 NSNotFound**，判有没有曲目必须读 `nowPlayingItem`。

构造写法的坑值得单列，因为它是「编译器不拦、运行时才炸」的典型：

```
  （注）上一段用 MPMediaItemCollection(items: [])，**不是** MPMediaItemCollection()。后者实测直接 abort：
        *** Terminating app due to uncaught exception 'MPMediaItemCollectionInitException',
        reason: '-init is not supported, use -initWithItems:'，栈顶 -[MPMediaItemCollection init]，exit=134
        头文件里 initWithItems: 被标成 NS_DESIGNATED_INITIALIZER，裸 init 是系统**故意禁掉**的，
        但 Swift 还是把 init() 给你生成了出来 —— 编译器不拦，运行时才炸，这是 ObjC 桥接的固有缺口
  （注）这一节里 `volume` 这个属性**在 Swift 里根本不可用**，编译期就拒绝：
        'volume' is unavailable in iOS: Use MPVolumeView for volume control.
        头文件里它写的是 deprecated，Swift 侧却被翻成了 unavailable，所以你连「试一下看会不会崩」都做不到。
```

### 17.4 `MPMediaLibrary` / `MPMediaQuery`：被拒之权下各 API 长什么样

```
  -- 17.4 MPMediaLibrary / MPMediaQuery：被拒之权下各 API 长什么样 --
  MPMediaLibrary.authorizationStatus()=1（notDetermined=0 denied=1 restricted=2 authorized=3）
  MPMediaLibrary.default() 类型=MPMediaLibrary（它只提供 lastModifiedDate 和库变更通知开关，取内容不归它管）
  MPMediaQuery.songs()：groupingType=0 filterPredicates=Optional(1) items=nil
  MPMediaGrouping 挑四个：title=0 artist=2 album=1 composer=4
  ok   模拟器上媒体库权限是 **denied=1**，不是 notDetermined=0 —— 因为模拟器压根没有「允许访问音乐」这一步可问。这对写代码很实际：授权分支必须自己造条件测，别只在真机上跑通就算数
  ok   权限被拒时这些 API 一律给 **nil，不是空数组**。`items?.count ?? 0` 之类写法看着安全，却把「没权限」和「有权限但库里 0 首」压成了同一个数字；判权限要单独读 authorizationStatus()
  ok   MPMediaQuery.songs() 的 groupingType 是 title=0（裸构造也是 0）：分组方式是查询对象的属性。MPMediaGrouping 里**没有 .song**，只有 .title —— 照着「songs() 该有 .song」的直觉写会得到编译错误
  （注）MPMediaLibrary 在本 SDK 上没有 items(matching:) 这个方法，编译器原文：
        value of type 'MPMediaLibrary' has no member 'items'。
        取内容走 MPMediaQuery，云端库另有一个 cloudItems，两个都是可选值，被拒权限时都是 nil。
```

**权限被拒时给的是 `nil`，不是空数组**——这条决定了 UI 的写法：
`items?.count ?? 0` 会把「没权限」和「库里 0 首」压成同一个数字，
所以必须单独读 `authorizationStatus()` 再分支。
模拟器上这个状态恒为 `denied=1`（不是 `notDetermined=0`，因为没有可问的弹窗），
意味着授权分支在模拟器上永远走不到——只能自己造条件测。

### 17.5 `MPVolumeView`：控件的子视图结构，以及通知名只能这么写

```
  -- 17.5 MPVolumeView：控件的子视图结构，以及通知名只能这么写 --
  MPVolumeView(frame: 200x40)：isHidden=false showsVolumeSlider=true showsRouteButton 这个属性还在但 iOS 13 就废弃了（本节故意不读它）
  自动生成的子视图：[MPVolumeSlider, UILabel, MPButton]
  ok   MPVolumeView 一建好就有子视图（音量滑块 + 标签 + 路由按钮），这是**系统给的现成控件**，自己画音量条只会跟系统不同步。反过来：它就是 17.3 注里 volume 不可用之后**唯一**能改音量的入口
  三个通知名的 rawValue：
    MPMusicPlayerControllerNowPlayingItemDidChange = "MPMusicPlayerControllerNowPlayingItemDidChangeNotification"
    MPMusicPlayerControllerPlaybackStateDidChange = "MPMusicPlayerControllerPlaybackStateDidChangeNotification"
    MPMusicPlayerControllerVolumeDidChange = "MPMusicPlayerControllerVolumeDidChangeNotification"
  MPNowPlayingInfoPropertyIsLiveStream 的字符串值="MPNowPlayingInfoPropertyIsLiveStream"
  ok   顺手把最容易写错的那个键钉住：真名是 **MPNowPlayingInfoPropertyIsLiveStream**（MPNowPlayingInfo 那一族，不是 MPMediaItemProperty 前缀），而且和 17.1 那两条一样，它的字符串值**就是自己的名字**，不是猜得出的 isLiveStream / isLiveStreaming。两头都错过：名字写错编译器拦得住，字符串值写错编译器拦不住
```

这一节最容易翻车的是通知名的**两层**：

```
  ok   这是最容易翻车的一处：Swift 侧的**符号名**短（`.MPMusicPlayerControllerVolumeDidChange`），可它的**字符串值带 Notification 后缀**（上面三条印得清清楚楚）。所以拿字符串比对通知（在测试里自己拼 `NSNotification.Name("…")`、或者去 Console 里 grep）认的是**带后缀**的那一串；把短名当字符串写进去一样能编过、一样合法，只是永远匹配不到回调 —— 静默失效，不抛错也不告警，表现就是「监听没反应」。反过来在代码里直接敲带后缀的裸常量名 `MPMusicPlayerControllerVolumeDidChangeNotification`，编译器报 has no member —— 两头别搞反
  （注）通知名在 Swift 里只能写成 `NSNotification.Name.MPMusicPlayerController…`（符号名不带后缀，
        可它的 rawValue 带 —— 上面那两条 expect 就是把这两层分开钉住的）。
        同理 MPRemoteCommandCenter 上的 addTargetWithHandler: 在 Swift 里
        就叫 addTarget(handler:)，照着旧书敲那个名字会得到 'has no member' 的编译错误。
```

符号名不带 `Notification`、字符串值带——**两个方向都会错**：
把短名当字符串写进去合法但永远匹配不到（表现是「监听没反应」，无报错无告警）；
在代码里直接敲带后缀的裸常量名，编译器报 `has no member`。
音量这一路的结论很硬：`volume` 在 Swift 里是 `unavailable`（17.3 注），
所以系统给的 `MPVolumeView` 是唯一入口，自绘音量条必然和系统不同步。

### 17.6 两个「播放状态」枚举：名字像，数值对不上

```
  -- 17.6 MPNowPlayingPlaybackState 与 MPMusicPlaybackState：名字像，数值对不上 --
  MPNowPlayingPlaybackState（§17.1 那个中心）：unknown=0 playing=1 paused=2 stopped=3 interrupted=4
  MPMusicPlaybackState（§17.3 那个播放器）：stopped=0 playing=1 paused=2 interrupted=3 seekingForward=4 seekingBackward=5
  顺带一个只有真编译过一次才会知道的细节：两个枚举的 rawValue **连类型都不一样**，
  中心那边是 Int、播放器那边是 UInt，所以下面这张表每一行都得先 Int(...) 转一道；
  不转的原文报错是 cannot convert value of type 'UInt' to expected argument type 'Int'。
  把中心的 5 档**按 rawValue 硬搬到**播放器枚举上会得到：
    unknown=0 → stopped
    playing=1 → playing
    paused=2 → paused
    stopped=3 → interrupted
    interrupted=4 → seekingForward
  ok   两家的 playing=1、paused=2 恰好重合，剩下的全错位：中心里 stopped=3 在播放器语义里是 interrupted，中心里 interrupted=4 在播放器里是 seekingForward。上面那张表就是「拿数值串过去」的实际结果 —— 不报错、不崩溃，只是 5 档里 3 档含义被换掉。联动 bug 的第二名，只能逐个 case 手写映射
  ok   中心只有 5 档、播放器有 6 档，可中心那 5 个数值**全都**落在播放器的合法区间（0…5）里，一个都不越界。这正是最坏的组合：按数值硬搬不会失败、不会报错，`MPMusicPlaybackState(rawValue:)` 永远给你个值出来，于是 5 档里有 3 档被悄悄换成别的含义；反过来播放器多出的 seekingBackward=5 在中心里没有对应。两边永远不可能一一对应，所以本章只并排印表、不写双向映射函数
```

这是全章最隐蔽的一个 bug 源：`MPNowPlayingPlaybackState(rawValue: npc.playbackState.rawValue)`
这种写法**语法正确、永远返回一个值、类型都能过**（还得先 `Int(...)` 转一道，
因为两家 rawValue 连类型都不同：中心是 `Int`、播放器是 `UInt`）。
5 档里有 3 档被悄悄换掉，而唯一重合的是 `playing=1`/`paused=2`——
恰好是最常用的两档，所以测试很容易「看起来是对的」。
映射只能逐个 `case` 手写，而且两个枚举永远无法一一对应。

### 17.6b 把写错的键塞进 `nowPlayingInfo`：字典照收，系统照沉默

```
  -- 17.6b 把写错的键塞进 nowPlayingInfo：字典照收，系统照沉默 --
  混着写三种键之后字典读出 3 项，键集（排序）=["Title", "isLiveStreaming", "title"]
  按真键取值=Optional("真键")，按错键取值=Optional("首字母大写的键")
  ok   nowPlayingInfo 的类型是 `[String: Any]?`，**它不是 API，是个普通字典**：你塞进去什么键都能原样读回来，编译器不做校验，系统不会告警，stderr 也干干净净。真键被大写成 "Title"、把 isLiveStream 多写成一步 ing（17.5 那条 expect 钉的就是它），锁屏上只是少了那一格，程序一点反应都没有
  ok   按真键取回来的是 "真键" 那条 —— 字典的键比较用的是**字符串值**，跟你用哪个常量拼出来的无关
  同一个键名换两种写法先后赋值：count=1，d[标题键]=Optional("后写的")
  ok   `MPMediaItemPropertyTitle` 就是 "title"（17.1 印过），所以这两行赋值打在同一个键上：**后写的静默覆盖先写的**，count 还是 1，没有报错也没有告警。分段拼装这个字典时（网络回调写一半、歌词解析写一半），同一键被谁最后碰到只能靠打字典才知道 —— 排查锁屏显示不对，先把 nowPlayingInfo 整个打出来核键名，比猜代码快
```

最后一条是拼装顺序的问题而不是键名问题：因为 `MPMediaItemPropertyTitle == "title"`，
`d["title"] = …` 和 `d[MPMediaItemPropertyTitle] = …` 打在**同一个键**上，后写的静默覆盖先写的，
`count` 还是 1。分段更新 `nowPlayingInfo` 的代码（网络回调写一半、歌词解析写一半）
最容易在这里出错，而排查方式只有一种：把整个字典打出来核键名。

这一节末尾记下它的适用边界，也就延伸到本章的边界：

```
  （注）§17 全程没有真机、也没有媒体库，所以这一节的三个 API 都只做到「读默认值 / 写进去读回来」。
        还有一类只有真机才暴露的差异：§4 里 AVAudioApplication 是 iOS 17 才有的入口，
        直接写在 iOS 15 目标上会得到 'AVAudioApplication' is only available in iOS 17.0 or newer；
        MediaPlayer 里同样有这种带版本门槛的成员，本章的做法是**只写头文件里当场读到、
        且当前 SDK 允许写进 iOS 15 目标的名字**，其余一律不碰 —— 与其抄一本旧书里的 API，
        不如让编译器逐字告诉你哪个名字在这个工具链上存在。
```

## 本章的诚实边界

示例末尾把这五条原样打印出来，本章不假装覆盖了没覆盖的东西：

```
== 本章的诚实边界 ==
  1) 音频的「听」这一环全部没验：headless 模拟器上没有可听输出，本章只能证明采样值、
     帧数、状态机、错误码，不能证明音色、混响好听不好听、变速有没有artifact。
  2) MPRemoteCommandCenter 的 handler 一次都没被真实触发过（没有系统去点它），
     只能断言默认使能状态、参数数组和注册/摘除；真机上按线控/锁屏才是那条路。
  3) 媒体库权限在模拟器上恒为 denied，MPMediaQuery 拿到的是 nil ——
     「有权限时列表长什么样」本章没有覆盖。
  4) AVPlayerViewController / Picture in Picture 只验了属性和能力查询，
     画面是否真的在动、画中画窗口是否浮起来，需要真机 + 肉眼。
  5) §8 那一类「主队列被 await 占住」的现象是脚本环境特有的，真机不会出现；
     反过来，真机上才有的路由变化、蓝牙抢占、后台被系统回收，脚本环境一个都造不出来。
```

## 坑清单

按「症状 → 原因/写法」排，每条都在本章示例里出现过实测证据。

| 症状 | 原因与正确写法 |
| --- | --- |
| 刚写完的 wav 播不出来 / `duration` 是 0 / `length` 是 0 | 写入用的 `AVAudioFile` 还攥在手里，RIFF 头没回填。释放写入器（置 nil / 出作用域）再读，或直接读 `AVAudioFile(forReading:)` 的 `length`（§2、§15.13） |
| `read(...)` 在文件尾抛错，`code` 是 0 | ObjC 的 `BOOL` 失败桥成 Swift 错误：`Foundation._GenericObjCError / 0`。code 不含信息，只能靠 domain + 「我刚在读文件」判（§1、§15.13） |
| 循环里 `while file.framePosition < file.length` 偶发少读一帧 | `AVAudioFile` 有状态，游标会自己往前走；`framePosition` 可写，可以在读之前改起点（§15.13） |
| 音量/路由/打断「设了没反应」 | `AVAudioSession` 的 category 要在 `setActive(true)` 之前定，且 `mode`/`options` 是另一层。§4 那六个 category 逐个设置后读回，能看见系统实际落到哪一档 |
| `'volume' is unavailable in iOS: Use MPVolumeView for volume control.` | 头文件写的是 deprecated，Swift 侧翻成 unavailable，编译期就拒绝。改音量只能挂 `MPVolumeView`（§17.3、§17.5） |
| `AVAudioApplication` 报 `is only available in iOS 17.0 or newer` | 本仓库目标是 iOS 15，得包 `if #available(iOS 17.0, *)`（§4、§17.6b 注） |
| 渲染出来的峰值是 0.7071 而不是源幅度 | `mainMixerNode` 的求和级带 −3 dB（1/√2），与 `outputVolume=1.0` 无关。断言前先除掉这个系数（§15.6） |
| 设了音量，第一块数值不精确 | 运行中改参数会斜坡，首块是过渡值（实测 0.6942 / 0.6898）。在 `start()` 前设好，或丢弃首块（§15.7） |
| 混音后的峰值不等于两路之和 | 混音是逐采样相加，结果落在 `(单路, 2×单路)`；两路正弦的峰不同时到（`sin(x)+sin(2x)` 的极大值是 1.759 倍）。别拿「两路各降一半」保证不失真（§15.8） |
| `renderOffline` 抛 `com.apple.coreaudio.avfaudio/-50` | 请求帧数 > `maximumFrameCount`，或 > 目标 buffer 的 `frameCapacity`。纯尺寸校验（§15.3） |
| `renderOffline` 抛 `-80802` | 引擎没 `start()`。`prepareToPlay()` 不改变 `isRunning`（§15.5） |
| `renderOffline` 抛 `-80800` | 已经 `disableManualRenderingMode()`，模式不对（§15.14） |
| 渲染全 `0.0000`，没有任何报错 | 三层里缺了后两层：播放器没 `play()`，或队列里没有帧。`scheduleBuffer` 之前叫的 `play()` 是**作废**，`start()` 之后要再叫一次（§15.5） |
| 用 `isPlaying` 判断「播完了没有」判不出来 | 帧全吐光 `isPlaying` 仍是 `true`；`reset()` 也不动它。判播完要盯 `manualRenderingSampleTime` 或 completion 回调（§15.10、§15.11） |
| `pause()` 之后想从头播 | `pause` 保位置、`reset`/`stop` 丢队列；只有 `stop()` 顺手把 `isPlaying` 置 false。「停止后从头播」= `stop()` → 重新 schedule → `play()`（§15.11） |
| 测试里 `dataPlayedBack` 回调永远不来 | 手动渲染没有输出设备，只有 `dataConsumed`/`dataRendered` 会触发（§15.12） |
| 读交织 buffer 时右声道拿到的是错的值 | `interleaved=true` 时只有 `floatChannelData[0]`，取数是 `data[0][frame*channelCount+channel]`；`data[1]` 是越界读（mono 实测 SIGSEGV）（§15.4） |
| 想移除节点，`remove(_:)` 编译不过 | 方法名是 `detach(_:)`；摘除的可靠信号是节点反查 `node.engine == nil`。连线归 `disconnect`，节点归 `detach`（§15.14） |
| `scheduleSegment` 请求超出文件长度，没报错也没声音 | 越界不抛错、不裁剪、不提示，只把缺的部分渲染成静音。自己校验 `startingFrame + frameCount ≤ length`（§15.13） |
| 新建的 EQ 挂上去声音一点没变 | 无参 `AVAudioUnitEQ()` 是 **16 条 band**，每条出厂 `bypass=true`；要逐条 `bypass=false`。整台单元的 `bypass` 优先级高于 band（§16.1、§16.4） |
| `+12 dB` 之后写出的文件削波 | Float32 图不自己削波，峰值如实到 1.4070；写进 16 bit 或交给设备才削顶。先降源电平再给增益（§16.4） |
| 加了混响听不出来 | `loadFactoryPreset` **不改 `wetDryMix`**，出厂是 0.5（百分比），要自己抬到 50。判断混响要渲染 ≥8 块看尾巴，大空间预置还有 pre-delay 前两三个全零（§16.5） |
| 干湿各 50% 时整体变响 | `wetDryMix` 走等功率曲线，中点比两端高约 3 dB（0.4935 vs 0.3536，比值 1.3956 ≈ √2）（§16.2） |
| `delayTime = 10` 变成十秒回声 | 单位是**秒**，类型和属性名都没有提示；不校验范围，写多少读多少（§16.3） |
| 效果器参数给了越界值，一切调用都成功 | 没有一层校验范围（`rate=100`、`pitch=5000`、`overlap=999` 全部原样读回），坏结果只出现在渲染数字里。要么自己 clamp，要么断言输出（§16.6） |
| 想换一个喂数闭包，返回 `false` | `setManualRenderingInputPCMFormat` 只有开机前那一次机会；闭包必须返回 `UnsafePointer<AudioBufferList>`，且 buffer 要在捕获范围内活着（§16.7） |
| `AVAudioConverter` 转换后电平比引擎低 3 dB | converter **不带 −3 dB**（同一段走引擎 0.3536、走 converter 0.5000）。两条通路混用时这是「电平为什么不一样」的答案（§16.9） |
| 重采样出来的帧数比理论少/多几十帧 | `primeMethod` 决定：`.pre` 吃掉头（1080）、`.normal` 向下取整（1114）、`.none` 前后补静音（1149）。要保证首尾不漏必须显式选档（§16.8） |
| `convert` 返回 `inputRanDry=1` 被当错误抛出 | 1 是「输入不够，继续喂」；只有 `error=3` 是真错。**不报 `.endOfStream`，尾巴那 704 帧永远留在 converter 里**（§16.9） |
| 立体声压单声道「只听见左边」 | `channelMap` 默认 2→1 是 `[0]`，`downmix` 出厂 false → 丢右声道。要平均得开 `downmix`（§16.10） |
| 一次性 `convert(to:from:)` 重采样一律 `-50` | 一次性 API 只能做帧数不变的转换；变采样率必须用闭包版。容量给 4410/4801/4802/9000 都一样抛（§16.11） |
| 一次性 convert 直接进程没了（exit=134） | 输出 buffer 的 `frameCapacity < 输入 frameLength` 是 `NSException`（`required condition is false: …`），不是抛错。闭包版无此约束（§16.11 注） |
| `channelMap` 赋了越界索引，读回变成 `[0]` | 不抛错但**静默改写**；这类属性唯一的检查是赋完立刻读回（§16.10） |
| 错误码是一串看不出意义的整数 | CoreAudio 一类码本身就是 FourCC：`1718449215` = `'fmt?'`。写个 fourcc 解码函数比背表有用（§6、§16.11） |
| 锁屏上一片空白，程序毫无反应 | `nowPlayingInfo` 是普通 `[String: Any]?`，键名写错不校验。`MPMediaItemProperty*` 的字符串值是全小写（`"title"`），`MPNowPlayingInfoProperty*` 等于自身名字（整串）。把键的字符串值印出来核对（§17.1、§17.6b） |
| 暂停了锁屏还在转圈 | `MPNowPlayingInfoCenter.playbackState` 是**你自己写的**，系统不跟着 `AVPlayer` 改（§17.1） |
| 「我没注册 nextTrack，为什么按钮还在」 | 20 条命令出厂全部 `isEnabled=true`；按钮出现与否取决于有没有 handler，要屏蔽得显式 `isEnabled=false`（§17.2） |
| 注册了倍速命令却没有倍速选项 | `supportedPlaybackRates` 出厂是**空数组**，必须自己声明（§17.2） |
| 评分控件点不动 | `MPRatingCommand` 出厂 `minimumRating = maximumRating = 0`，上下限相等没有刻度，要自己写 `maximumRating = 5`（§17.2） |
| 「喜欢」按钮没有字，点完也不亮 | `MPFeedbackCommand.localizedTitle` 出厂空串、`isActive` 不自动翻转，两者都得自己维护（§17.2） |
| 通知监听没反应，不报错 | Swift 符号名不带 `Notification`、rawValue 带（`MPMusicPlayerControllerVolumeDidChange` 的字符串值是 `…VolumeDidChangeNotification`）。拿短名当字符串比对＝静默失效；在代码里敲带后缀的常量名＝`has no member`（§17.5） |
| 单曲循环显示成不循环 | `MPRepeatType(off=0 one=1 all=2)` 与 `MPMusicRepeatMode(default=0 none=1 one=2 all=3)` 数值错一档；`MPNowPlayingPlaybackState` 与 `MPMusicPlaybackState` 五档里三档含义不同，且 `rawValue` 类型一个 `Int` 一个 `UInt`。只能逐 case 手写映射（§17.2、§17.6） |
| 空队列时 `indexOfNowPlayingItem` 判不出「没在播」 | 头文件说会给 `NSNotFound`，实测空队列给 **0**（而 `nowPlayingItem` 是 nil）。判曲目有没有就读 `nowPlayingItem`（§17.3） |
| `MPMediaItemCollection()` 直接 abort | `MPMediaItemCollectionInitException: -init is not supported, use -initWithItems:`。Swift 仍然给你生成了 `init()`，编译器不拦（§17.3 注） |
| 权限被拒时 `items?.count ?? 0` 看不出区别 | `MPMediaQuery` 被拒权限给的是 **nil 不是空数组**，模拟器上恒为 `denied=1`。判权限要单独读 `authorizationStatus()`（§17.4） |
| 找不到 `skipInterval` / `notch` / `maxDelayTime` / `largeChurch` / `AVAudioConverterQuality` / `items(matching:)` | 本 SDK 里不存在，编译器原文见 §16.1、§17.2、§17.4 的注。旧教程里这些名字出镜率很高 |

## 小结

- **先有可复现的输入，再谈断言。** 本章所有音频素材都是运行时现场生成的
  （§1 的 wav、§7 的 mp4），因此不需要仓库里塞任何二进制，也不会因为某个文件被改动就让全章数字失效。
  波形数字靠 `AVAudioEngine` 的手动渲染模式拿到：你不推进时间，引擎一个采样都不算。
- **一个系数贯穿全章：−3 dB。** `1/√2 = 0.7071` 来自 `mainMixerNode`，
  所以 `0.5 → 0.3536`、`0.25 → 0.1768`、`0.125 → 0.0884`。
  只有 `AVAudioConverter` 不带这个系数（它只换格式/采样率/声道），
  这就是「同一段音频走引擎和走 converter 电平不一样」的全部原因。
- **AVFoundation 的三条纪律**：时间用 `CMTime` 并读 `flags`（+inf 与 indefinite 是两回事）；
  状态机三套枚举数值互不兼容（writer `completed=2`、exporter `completed=3`、reader 另一套）；
  **写完/导出完之前，文件大小和时长都不能当真**。
- **失败有三种表现，其中两种不告诉你**：抛错（`-50`、`-80802`、`-80800`、`AVFoundationErrorDomain/-11800/-11869`）、
  静默给静音或给 `nil`（忘 `play()`、越界 `scheduleSegment`、写入器没释放、权限被拒），
  以及**直接终止进程**的 `NSException`（`readyForMoreMediaData=NO` 硬 append、
  `MPMediaItemCollection()`、`frameCapacity < frameLength`、channelCount 不匹配、
  同一节点 attach 两台引擎、KVC 键名）。第三种在 Swift 里 `try` 抓不住，只能靠写法避免。
- **MediaPlayer 这一侧的教训只有一条**：它不报错。键名写错、状态没回写、参数没声明，
  表现都是「界面上少了那一格」。所以本章把每个常量等于哪个字符串、每条命令出厂什么状态、
  每个枚举的 rawValue 全部印出来——这是这类代码唯一的排查手段。
- 真机才能验的三项（能听、线控真的被触发、有媒体库）留在诚实边界里，本章不假装覆盖。

下一章离开 AVFoundation，进入设备的另一组入口：**Core Motion 的传感器、
Core Location 的定位与地理围栏、以及权限与硬件能力查询**（相机之外的那一半——
加速度计、陀螺仪、高度计、GPS 与运动协调器）。
