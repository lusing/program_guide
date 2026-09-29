# 16 · 多媒体开发

> 对应示例：`examples/25_media_playback.kt`。取材：李刚《疯狂Android讲义（第3版）》第 11 章全部（播放/录制/相机/录屏）与 10.4（AudioManager）。32 章讲过原生侧的 OpenSL ES/AAudio——那是往下潜；本章是框架侧的"够用且正统"。

## 1. 支持什么：格式与栈位

框架层多媒体四件套各管一段：

| 类 | 管什么 | 一句话 |
|---|---|---|
| `MediaPlayer` | 播放音频/视频 | 一次一个流，高级播放器内核 |
| `SoundPool` | 短音效池 | 密集、低延迟、可同播 |
| `MediaRecorder` | 录音频/视频 | 麦克风摄像头一条龙 |
| `VideoView` + `MediaController` | 视频播放控件 | MediaPlayer+Surface 的控件化封装 |

格式支持随设备而异（MP3/AAC/WAV/OGG、MP4/3GP/WebM 是安全区），底层编解码走厂商的 OpenMAX 实现——`MediaCodec`（32 章提过坐标）是这层的直接入口，一般只有播放器类 App 才下沉。

## 2. MediaPlayer：状态机是唯一的地图

MediaPlayer 是个**严格状态机**——"什么状态能调什么方法"错了就抛 `IllegalStateException`，记 API 表不如记状态图（书 11.1.1 的图 11.1 值得描一遍）：

```text
new → Idle → setDataSource → Initialized → prepare → Prepared
Prepared ⇄ start → Started ⇄ pause → Paused
Started/Paused → stop → Stopped（回不到 Started，须再 prepare）
任何状态 → release → End（终态）；出错 → Error（监听器兜住）
```

**便捷通道与完整通道**：`MediaPlayer.create(context, resid/uri)` 一步到 Prepared（适合单曲即播）；换曲/复用走全套——`reset()` 回 Idle → `setDataSource(path)` → `prepare()` → `start()`（书里"下一首"的模板）。**网络源必须 `prepareAsync()` + `setOnPreparedListener`**：同步 prepare 在主线程会卡到 ANR。

四个监听器各就各位：`OnPreparedListener`（异步准备完成，start 放这）、`OnCompletionListener`（播完，自动下一首放这）、`OnErrorListener`（返回 true 表示自己消化了错误）、`OnSeekCompleteListener`。最小骨架（`Example25MediaPlayer`）：

```kotlin
private var player: MediaPlayer? = null

private fun play(path: String) {
    player?.release()                          // 换曲先放生
    player = MediaPlayer().apply {
        setDataSource(path)
        setOnPreparedListener { it.start() }   // 异步准备完成才 start
        prepareAsync()
    }
}

override fun onDestroy() {
    player?.release()                          // 持有音频焦点与编解码器，必须放
    player = null
    super.onDestroy()
}
```

**音频焦点——书里没有、今天必做**：音频是全系统独占资源，不放焦点申请的播放器会被系统"混合外放"（用户挂电话/导航播报时你的歌还在响）。规矩：

```kotlin
val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
    .setAudioAttributes(AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
    .setOnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS -> stop()                  // 永久丢失：停
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> pause()       // 短暂（来电）：暂停
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->
                setVolume(0.2f)                                      // 短暂可压低（导航）：闪避
            AudioManager.AUDIOFOCUS_GAIN -> play()                  // 归还：恢复
        }
    }
    .build()
audioManager.requestAudioFocus(focusRequest)   // 播放前申请；停止后 abandonAudioFocusRequest
```

## 3. SoundPool：短音效的正确容器

MediaPlayer 资源重、延迟高、不可同播——按钮声、游戏打击声这类**短促密集**的音效用 SoundPool（书 11.1.3）：预加载进池（解码后的 PCM 常驻内存），`play(soundId, ...)` 即刻出声，多路叠加无压力。

```kotlin
val pool = SoundPool.Builder()                            // 5.0 起构造器废弃，Builder 是正门
    .setMaxStreams(4)                                     // 最多同时 4 路
    .setAudioAttributes(AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA).build())
    .build()
val id = pool.load("/sdcard/click.ogg", 1)                // priority 参数现状无效，恒传 1
pool.setOnLoadCompleteListener { _, sampleId, status ->   // 加载是异步的：完成前 play 无声
    if (status == 0) loaded.add(sampleId)
}
pool.play(id, 1f, 1f, 1, 0, 1f)      // 左右音量、优先级、loop(0/-1)、rate(0.5–2.0 变速不变调)
```

边界纪律（书里原话仍是金标准）：**单曲/背景音乐别用 SoundPool**（PCM 常驻内存，一首歌直接撑爆）；**它只是延迟小，不是零延迟**，低端机照样有几十毫秒。

## 4. 视频：VideoView 的三行与其他一切

`VideoView` 把"MediaPlayer 解码 + SurfaceView 出图 + 控制按钮"封装成了一个控件（书 11.1.4）：

```kotlin
val video = VideoView(this).apply {
    setVideoPath("/sdcard/movie.mp4")
    setMediaController(MediaController(this@Example25VideoView))   // 进度条/暂停/快进全套白送
    setOnCompletionListener { toast("播完") }
    start()
}
```

`MediaController` 默认浮层、点一下出现、几秒后淡出。要自定义 UI 或加弹幕/倍速，就退回书 11.1.5 的组合拳：**`MediaPlayer.setDisplay(surfaceHolder)`** 把解码输出接到 SurfaceView（13 章的 Surface 通道）——VideoView 内部正是这一套。**现代校准**：流媒体、DASH/HLS、广告插入、后台续播，工业答案全是 **Media3/ExoPlayer**（官方后继，API 形态与 MediaPlayer 相近但生命周期友好得多）；VideoView 只配本地文件的"能放就行"场景。

## 5. MediaRecorder：录制八步与顺序铁律

录音（书 11.2 的八步，顺序是铁律）：

```kotlin
val recorder = MediaRecorder(context).apply {              // API 31 起须传 Context，无参构造已废弃
    setAudioSource(MediaRecorder.AudioSource.MIC)          // ① 声源
    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)     // ② 输出容器
    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)        // ③ 编码器（必须在 ② 后！）
    setOutputFile(file.absolutePath)                       // ④ 落盘位置
    prepare()                                              // ⑤ 准备
    start()                                                // ⑥ 开始
}
// ⑦ stop()   ⑧ release()——两个都要，漏 release 麦克风灯常亮
```

**②③ 顺序反了直接 `IllegalStateException`**——这是本 API 族最著名的一坑（书里原话强调）。录视频只多三件事：`setVideoSource(CAMERA)`、`setVideoEncoder/setVideoSize/setVideoFrameRate`、`setPreviewDisplay(surface)` 把预览挂到 SurfaceView（书 11.3.2）。权限三连：`RECORD_AUDIO`/`CAMERA` 是运行时权限（11 章流程），写外部存储按 09 章分区存储规矩走。

**现代校准**：要波形数据/实时处理（语音识别、通话）用 `AudioRecord` 裸 PCM；要自定义编码管线用 MediaCodec；MediaRecorder 留给"按个按钮存个文件"的录音录像。

## 6. Camera2：五主角一场戏

书 11.3.1 把 Android 5.0 的 Camera2 讲得非常正统，五主角先对号：

| 类 | 角色 |
|---|---|
| `CameraManager` | 检测/打开摄像头（`cameraIdList`、`getCameraCharacteristics`） |
| `CameraCharacteristics` | 硬件能力表（朝向/分辨率/闪光灯…） |
| `CameraDevice` | 打开的设备（`openCamera` 异步获得） |
| `CameraCaptureSession` | 会话：`setRepeatingRequest` 预览、`capture` 拍照 |
| `CaptureRequest.Builder` | 每次捕获的参数（对焦/曝光/模板 `TEMPLATE_PREVIEW/RECORD/STILL_CAPTURE`） |

流程一场戏：`openCamera(id, stateCallback, handler)` → `onOpened` 拿到 `CameraDevice` → `createCaptureSession(listOf(surface), callback, handler)` → `onConfigured` 里 `setRepeatingRequest(previewRequest)` 出预览；拍照换 `TEMPLATE_STILL_CAPTURE`，`ImageReader` 的 surface 进 target，`capture()` 一响照片在 `OnImageAvailableListener` 里落盘。全程**异步回调驱动**，书里那句"没传 Handler 就全在主线程回调，实际项目应传工作线程 Handler"是这套 API 的第一生存法则。预览面用 TextureView 或 SurfaceView（13 章的老朋友）；`CAMERA` 运行时权限先拿。

**现代校准**：直接写 Camera2 属于"开手动挡"——**CameraX**（Jetpack）是官方自动挡：预览/拍照/分析三个用例组合、生命周期自绑定、兼容到老设备。新项目先 CameraX，Camera2 留给深度控制（帧级同步、多摄联动）。书里"拍照自动对焦"的 `CaptureRequest.CONTROL_AF_MODE` 参数在 CameraX 里是 `FocusMode` 配置项，思想同源。

## 7. 屏幕捕捉与音频特效（坐标章）

**MediaProjection 录屏**（书 11.4，API 21）：`getSystemService(MEDIA_PROJECTION_SERVICE)` → `createScreenCaptureIntent()` 发起系统授权弹窗 → 回调里 `getMediaProjection` → 建 `VirtualDisplay` 把屏幕投到 Surface。**2026 校准**：API 29 起录屏**必须跑在前台服务**（`foregroundServiceType="mediaProjection"` + 运行时先声明），书里的裸用法在现代系统上直接被拒——录屏类 App 的合规底线。

**AudioEffect 家族**（书 11.1.2）：`Equalizer`/`BassBoost`/`PresetReverb`/`Visualizer` 全部挂在 `audioSessionId` 上（`MediaPlayer.audioSessionId` 一拿即接），示波器 `Visualizer` 需要 `RECORD_AUDIO` 权限。API 至今可用，但注意**系统全局音效与出厂调音常已内置**，应用内 EQ 的场景比书时代少得多。`AudioManager`（书 10.4）日常两件事：音量/铃声模式（`setStreamVolume`、`ringerMode`）与 2 节的音频焦点——它是个系统服务，`getSystemService` 拿，别 new。

## 8. 常见坑

**状态机违规**：`prepare()` 前调 `start()`、`stop()` 后想再 `start()`（须重新 prepare 或用 `seekTo(0)+start`）、二次 `setDataSource` 不 reset——全是 `IllegalStateException`。改播放器行为前先画一遍状态图。

**`release()` 缺席**：MediaPlayer/MediaRecorder/SoundPool 都占着稀缺硬件（编解码器、麦克风、扬声器路由）。漏 release 的症状：麦克风指示灯常亮、后续播放无声、直到进程被杀。Activity 的 `onDestroy` 是 MediaPlayer 的最后期限。

**prepare 网络源卡主线程**：`prepare()` 是阻塞的，网络流上它就是 ANR 制造机——网络一律 `prepareAsync` + 监听。

**SoundPool 播不出声**：`load` 异步未完成就 `play`；或文件过大被静默拒绝。`OnLoadCompleteListener` 等状态 0。

**MediaRecorder 的 setOutputFormat/setAudioEncoder 顺序**：反了当场 `IllegalStateException`，且报错文案不直说原因——八步模板抄走别改顺序。

**Camera2 回调线程**：`openCamera` 等回调默认在调用线程的 Looper 上——主线程传 `null` handler 就是主线程干重活；正经写法 `Handler(HandlerThread 的 looper)`。

**音频焦点拿了不还**：`abandonAudioFocusRequest` 忘在停止时调，系统把你的"占用"记到用户头上（多 App 抢声混乱）。申请/归还成对，像 malloc/free。

**VideoView 播不了某些 MP4**：设备编解码器差异（H.265/10bit 等高级规格）——不是代码错。工业场景 Media3 的格式协商兜底。

## 9. 实战建议

- 播放器类需求（流媒体/列表/后台）直接上 **Media3/ExoPlayer**，框架 MediaPlayer 只学机制不选型
- 本地短音效 SoundPool、本地文件视频 VideoView：**短平快场景框架 API 就是终局**，别过度设计
- 音频播放器的"礼貌三件套"不可省：申请焦点、响应四种焦点变化、停止即归还——应用市场审核与用户口碑都在意
- 录制功能先想清边界：文件成品 MediaRecorder、实时流 AudioRecord/MediaCodec
- 相机新项目 CameraX 起步；要帧级控制再降 Camera2（书里的八步与参数表仍是最好的中文教材之一）
- 录屏/后台录音先核对前台服务与隐私政策（Android 14 起还有"部分媒体权限"，见 11 章权限谱系）

---
上一章：[15 Fragment 与任务栈](15-fragment-tasks.md) ｜ 下一章：[17 桌面组件与系统管理器](17-appwidget-managers.md) ｜ 返回：[README](../README.md)
