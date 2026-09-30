// ============================================================
// 24 - 音频与视频：AVFoundation 的播放、录制、读写与合成
//
// 第 19 章只用 AVFoundation 申请过麦克风权限，第 23 章把「画面为什么会动」讲到了层。
// 这一章是教材里音视频那一章的骨架，走完整条链路：
//   素材从哪来（§1）：AVAudioFile 现场写一段 PCM wav（不依赖任何随仓库分发的二进制）
//   本地播放（§3）：AVAudioPlayer —— 一次性把整个文件交给它
//   会话（§4）：AVAudioSession 的 category / mode / options / 激活 / 路由 / 打断通知
//   录制（§5）：AVAudioRecorder 的准备、录制、电平、删除
//   时间（§6）：CMTime / CMTimeRange / CMTimeFlags —— AVFoundation 的地基，必须先吃透
//   写文件（§7）：AVAssetWriter + PixelBufferAdaptor 现场合成 mp4
//   播放器（§8）：AVPlayer / AVPlayerItem 的状态机、时间观察者、KVO —— 排在所有 await 之前
//   界面（§9）：AVPlayerViewController、AVPlayerLayer、画中画能力查询
//   资产（§10）：AVAsset 的「同步旧读法」与「try await 新读法」，以及 §8 为什么要抢跑
//   读回来（§11）：AVAssetReader 把文件解成 sample buffer
//   转码（§12）：reader → writer 一条管线把 wav 压成 m4a
//   导出与抓帧（§13、§14）：AVAssetExportSession、AVAssetImageGenerator
//   图形与引擎（§15、§16）：AVAudioEngine 的手动（offline）渲染、混音、效果器、AVAudioConverter
//   系统联动（§17）：MediaPlayer —— MPNowPlayingInfoCenter、MPRemoteCommandCenter、
//     MPMusicPlayerController、MPMediaLibrary/MPMediaQuery、MPVolumeView
//
// headless 怎么拿到确定的数字（本章的四招）：
//   1) **墙钟不参与判断**。播放推进多少、观察者回调几次，全都随调度浮动，
//      所以只断言布尔值（isPlaying / 回调是否至少来了一次 / remove 之后不再来）
//      和**与调度无关的具体值**（从 0 起步的第一个 tick=0.0000、零容差 seek 的落点），
//      绝不打印播放若干秒之后的 currentTime。
//   2) **AVAudioEngine 用手动渲染模式**（enableManualRenderingMode(.offline, …)）。
//      没有音频设备也能 renderOffline，采样值逐字节可复现 —— 本章所有波形数字
//      （0.7071 / 0.3536 / 0.1768 / 0.0000）都是这么来的。
//   3) **写完的文件要先撒手**。AVAudioFile 还活着时，同一个 URL 交给
//      AVAudioPlayer 会得到 duration=0、play() 返回 false 且不报错（下面第 2 节做对照）。
//   4) **需要主队列活着的实验，全部排在第一次顶层 await 之前**。顶层 await 一旦发生过，
//      主线程就停在 main queue 的 block 里面，此后 RunLoop.current.run(until:) 排不动
//      main queue：AVPlayer 的 item 停在 unknown、currentTime 冻结、时间观察者一个回调都不来。
//      §8 里活得好好的同一套实验，到 §10 末尾再跑就是全零 —— 这是脚本环境的现象，
//      真机/App 里主 runloop 一直在转，不会遇到。
//
// 判定 1（零告警）与判定 3（stderr 必须为空）的约束：
//   - 不打印 AVAudioFormat / AVAudioNode / AVPlayerItem 的 description：
//     探针实测 AVAudioFormat 是 "<AVAudioFormat 0x600002108e10: 1 ch, 44100 Hz, Float32>"，
//     AVAudioNode 的 description 是一整张带 6 个指针地址的 GraphDescription
//   - 不用 statusOfValue(forKey: "乱写的键")：实测会往 stderr 打
//     "-[AVAsset statusOfValueForKey:error:] invoked with unrecognized key bogus."
//   - 顶层代码里不能直接 RunLoop.current.run(until:)（implicit async main 会报
//     "instance method 'run' is unavailable from asynchronous contexts"），
//     必须包进一个非 async 的函数，本文件的 pump() 就是干这件事的
// ============================================================

import Foundation
import UIKit
import AVFoundation
import AVKit
import MediaPlayer

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
/// 四位小数：波形峰值、时长这类值用它足够，且 -Onone / -O 下逐字节一致
func f4(_ v: Double) -> String { String(format: "%.4f", v) }
func f4(_ v: Float) -> String { String(format: "%.4f", Double(v)) }
/// 把 CMTime 拆成能逐字核对的字段，而不是只给一个 double
func cm(_ t: CMTime) -> String {
    "value=\(t.value) ts=\(t.timescale) valid=\(t.isValid) indefinite=\(t.isIndefinite) secs=\(CMTimeGetSeconds(t))"
}
/// 非 async 的等待：顶层是 async main，直接调 run(until:) 会被编译器拒绝
func pump(_ seconds: TimeInterval) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
}
/// 轮询到某个条件成立，返回一共走了几步（步数只用来判断「有没有等到」，不打印）
func waitUntil(_ limit: Int = 400, _ body: () -> Bool) -> Bool {
    for _ in 0..<limit { if body() { return true }; pump(0.02) }
    return body()
}
func tmp(_ name: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
}
func bytesOf(_ url: URL) -> Int {
    (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? -1
}
/// FourCC：CoreMedia 的 mediaType / 编码格式本质是 4 字节整型，解成字符串好核对
func fourcc(_ v: UInt32) -> String {
    let b: [UInt8] = [UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)]
    return String(bytes: b, encoding: .ascii) ?? "?"
}
/// FourCC 的反方向：把 'avc1' 这类 4 字符标签打包成 UInt32（不足 4 字节按惯例补空格）
func cc(_ s: String) -> UInt32 {
    let b = Array((s + "    ").utf8.prefix(4))
    var v: UInt32 = 0
    for byte in b { v = v << 8 | UInt32(byte) }
    return v
}
/// AVFoundation 的 Swift 覆面里，有的 rawValue 是 String（AVMediaType），有的是 UInt32（CMFormatDescription），
/// 统一走这个函数，两边都能显示
func fourccAny(_ v: Any) -> String {
    if let u = v as? UInt32 { return fourcc(u) }
    if let str = v as? String { return str }
    return "?"
}
func fmt(_ f: AVAudioFormat?) -> String {
    guard let f = f else { return "nil" }
    return "ch=\(f.channelCount) sr=\(f.sampleRate) commonFormat=\(f.commonFormat.rawValue) interleaved=\(f.isInterleaved)"
}
func peakOf(_ b: AVAudioPCMBuffer) -> Float {
    guard let d = b.floatChannelData else { return 0 }
    var m: Float = 0
    for c in 0..<Int(b.format.channelCount) {
        for i in 0..<Int(b.frameLength) { m = max(m, abs(d[c][i])) }
    }
    return m
}

let SR = 44100.0
let monoF = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: SR, channels: 1, interleaved: false)!
let stereoF = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: SR, channels: 2, interleaved: true)!
/// 生成一段正弦 PCM。写盘这件事必须在**函数作用域**里完成 —— 见第 2 节
func writeTone(_ name: String, seconds: Double, channels: Int, hz: Double, amp: Float) throws -> URL {
    let url = tmp(name)
    try? FileManager.default.removeItem(at: url)
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: SR,
        AVNumberOfChannelsKey: channels,
        AVLinearPCMBitDepthKey: 32,
        AVLinearPCMIsFloatKey: true,
    ]
    let file = try AVAudioFile(forWriting: url, settings: settings,
                               commonFormat: .pcmFormatFloat32, interleaved: false)
    let frames = AVAudioFrameCount(SR * seconds)
    let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames)!
    buf.frameLength = frames
    let ch = buf.floatChannelData!
    for i in 0..<Int(frames) {
        let v = amp * Float(sin(2 * .pi * hz * Double(i) / SR))
        for c in 0..<Int(file.processingFormat.channelCount) { ch[c][i] = v }
    }
    try file.write(from: buf)
    return url   // file 在这里出作用域、被释放 —— 这正是后面能播出来的原因
}

// ============================================================ 1
line("== 1) AVAudioFile：现场写一段 1 秒 440Hz 的 PCM wav ==")
let toneURL = try writeTone("24-tone.wav", seconds: 1.0, channels: 1, hz: 440, amp: 0.5)
line("  磁盘字节数=\(bytesOf(toneURL))")
let readBack = try AVAudioFile(forReading: toneURL)
line("  读回来 length=\(readBack.length) 帧")
line("  fileFormat ch=\(readBack.fileFormat.channelCount) sr=\(readBack.fileFormat.sampleRate) commonFormat=\(readBack.fileFormat.commonFormat.rawValue) interleaved=\(readBack.fileFormat.isInterleaved)")
line("  processingFormat \(fmt(readBack.processingFormat))")
let readCapacity = AVAudioFrameCount(readBack.length)
let chunk = AVAudioPCMBuffer(pcmFormat: readBack.processingFormat, frameCapacity: readCapacity)!
try readBack.read(into: chunk)
line("  容量给满 \(readCapacity) 帧，第一次 read 只交了 frameLength=\(chunk.frameLength) 帧；floatChannelData 非空=\(chunk.floatChannelData != nil) int16ChannelData 非空=\(chunk.int16ChannelData != nil)")
let rest = AVAudioPCMBuffer(pcmFormat: readBack.processingFormat, frameCapacity: readCapacity)!
try readBack.read(into: rest)
line("  第二次 read 交出剩下的 frameLength=\(rest.frameLength) 帧；两次合计=\(chunk.frameLength + rest.frameLength)")
let first4 = (0..<4).map { f4(Double(chunk.floatChannelData![0][$0])) }
line("  前 4 个采样=\(first4)")
line("  整段 peak=\(f4(Double(peakOf(chunk))))（生成时给的幅度是 0.5）")
expect(Int(chunk.frameLength + rest.frameLength) == readBack.length,
       "要读满 length 帧得**循环 read**；length 的单位是帧，不是字节")
expect(chunk.frameLength < readCapacity && rest.frameLength > 0,
       "read(into:) 不保证一次把 buffer 填满 —— 探针三轮实测都是 44032 + 68，容量等于总帧数也一样先给你一块")
expect(readBack.processingFormat.commonFormat == .pcmFormatFloat32 && readBack.processingFormat.channelCount == 1,
       "处理格式由 commonFormat/interleaved 两个参数决定：这里恒为 Float32 非交织，与文件里的位深无关")
expect(abs(Double(peakOf(chunk)) - 0.5) < 0.005, "峰值就是当初写进去的幅度")
expect(bytesOf(toneURL) > readBack.length * 4, "文件比 数据=帧数×4 字节还要大：多的是 wav 头与格式块")
// 读完之后再读：Swift 侧是抛错，不是安静地返回 frameLength = 0
let eofTrap = AVAudioPCMBuffer(pcmFormat: readBack.processingFormat, frameCapacity: 1)!
var eofThrew = false
do { try readBack.read(into: eofTrap) } catch {
    eofThrew = true
    let ns = error as NSError
    line("  EOF 之后再 read 抛错：type=\(type(of: error)) domain=\(ns.domain) code=\(ns.code)")
    line("  抛错之后 frameLength=\(eofTrap.frameLength)")
}
expect(eofThrew, "read(into:) 到文件尾是 **throws**（Swift 侧 Foundation._GenericObjCError），不会给你 frameLength=0 的安静信号")

// ============================================================ 2
line("")
line("== 2) 生命周期坑：AVAudioFile 还攥在手里时，同一个文件播不出来 ==")
// 故意把一个用于**写入**的 AVAudioFile 存到可变全局里，让它活得比 AVAudioPlayer 久
var heldWriter: AVAudioFile? = nil
let heldURL = tmp("24-held.wav")
try? FileManager.default.removeItem(at: heldURL)
do {
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: SR, AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true,
    ]
    let f = try AVAudioFile(forWriting: heldURL, settings: settings,
                            commonFormat: .pcmFormatFloat32, interleaved: false)
    let b = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(SR))!
    b.frameLength = AVAudioFrameCount(SR)
    b.floatChannelData![0][0] = 0.1
    try f.write(from: b)
    heldWriter = f          // ← 关键：写入器被留住，没有出作用域
}
line("  文件已落盘，字节=\(bytesOf(heldURL))，writer.length=\(heldWriter?.length.description ?? "nil")")
let playerWhileHeld = try AVAudioPlayer(contentsOf: heldURL)
line("  writer 还在时：duration=\(playerWhileHeld.duration) prepareToPlay=\(playerWhileHeld.prepareToPlay()) play()=\(playerWhileHeld.play())")
expect(playerWhileHeld.duration == 0 && !playerWhileHeld.play(),
       "文件明明在磁盘上，AVAudioPlayer 却给你一个 0 秒的空资产，而且**不抛错、不返回错误码**")
heldWriter = nil
let playerAfterRelease = try AVAudioPlayer(contentsOf: heldURL)
line("  writer 释放后：duration=\(playerAfterRelease.duration) prepareToPlay=\(playerAfterRelease.prepareToPlay())")
expect(playerAfterRelease.duration > 0.9, "同一个 URL、同一份字节，只因为写入 AVAudioFile 被释放了，才读得到 1 秒时长")
playerAfterRelease.stop()

// ============================================================ 3
line("")
line("== 3) AVAudioPlayer：把一段本地音频交给系统播 ==")
let player = try AVAudioPlayer(contentsOf: toneURL)
line("  delegate=\(String(describing: player.delegate)) volume=\(player.volume) pan=\(player.pan) rate=\(player.rate) enableRate=\(player.enableRate)")
line("  numberOfLoops=\(player.numberOfLoops) duration=\(player.duration) numberOfChannels=\(player.numberOfChannels)")
line("  currentTime(还没播)=\(player.currentTime) isPlaying=\(player.isPlaying) metering=\(player.isMeteringEnabled)")
line("  url=\(player.url?.lastPathComponent ?? "nil") data=\(String(describing: player.data))")
line("  settings 键=\(player.settings.keys.sorted())")
let s = player.settings
line("  AVFormatIDKey=\(s[AVFormatIDKey] ?? "?")（FourCC \(fourcc(UInt32(truncating: (s[AVFormatIDKey] as? NSNumber) ?? 0)))）AVSampleRateKey=\(s[AVSampleRateKey] ?? "?") 位深=\(s[AVLinearPCMBitDepthKey] ?? "?")")
expect(fourcc(UInt32(truncating: (s[AVFormatIDKey] as? NSNumber) ?? 0)) == "lpcm", "settings 里的格式 ID 就是 FourCC，lpcm = 未压缩 PCM")
player.volume = 0.5
player.pan = -0.25
player.numberOfLoops = -1
line("  设完读回：volume=\(player.volume) pan=\(player.pan) numberOfLoops=\(player.numberOfLoops)（-1 = 无限循环）")
player.numberOfLoops = 0
player.isMeteringEnabled = true
player.updateMeters()
line("  不开启播放就测电平：peakPower(forChannel: 0)=\(player.peakPower(forChannel: 0)) averagePower=\(player.averagePower(forChannel: 0))")
expect(player.peakPower(forChannel: 0) == -160 && player.averagePower(forChannel: 0) == -160,
       "-160 dB 是「一次都没测到」的初值，不是真实电平")
line("  越界声道号：peakPower(forChannel: 9)=\(player.peakPower(forChannel: 9))")
let prepared = player.prepareToPlay()
let started = player.play()
line("  prepareToPlay=\(prepared) play()=\(started) isPlaying=\(player.isPlaying)")
expect(prepared && started && player.isPlaying, "AVAudioPlayer 的 play() 是同步返回 Bool（不像 AVPlayer 靠状态机）")
pump(0.3)
let advanced = player.currentTime
expect(advanced > 0 && player.isPlaying, "播放 0.3 秒后 currentTime 确实在推进（具体值随调度浮动，所以只断言 >0）")
player.currentTime = 0.05
line("  播放中设 currentTime=0.05，立刻读回=\(f4(player.currentTime))")
player.pause()
line("  pause 后 isPlaying=\(player.isPlaying) currentTime=\(f4(player.currentTime))")
expect(player.isPlaying == false, "pause() 之后 isPlaying 同步变 false，不用等回调")
player.stop()
line("  stop 后 isPlaying=\(player.isPlaying) currentTime=\(f4(player.currentTime)) —— **没有归零**")
expect(player.isPlaying == false && player.currentTime > 0,
       "探针实测 stop() 不会把 currentTime 清零，紧接着 play() 读到的还是原位；想从头播必须显式 currentTime = 0")
player.currentTime = 0
player.currentTime = 99
line("  把 currentTime 设成 99（duration=\(f4(player.duration))）之后读回=\(f4(player.currentTime)) —— 越界请求被夹到 duration")
expect(player.currentTime == player.duration,
       "越界赋值不抛错、不返回 false，只是被夹住；越界**读取**不会有异常，所以别指望它给你输入校验的反馈")
player.pause()
player.enableRate = true
player.rate = 2.0
line("  enableRate=true 后 rate=2.0 读回=\(player.rate)")
player.enableRate = false
player.rate = 0.5
line("  enableRate=false 时设 rate=0.5，属性读回仍然是=\(player.rate)（但播放速度不受影响 —— 这个开关只管 play() 那一刻要不要用 rate）")
// 坏文件：AVAudioPlayer 的构造是 throws 的
var badThrew = ""
do { _ = try AVAudioPlayer(contentsOf: tmp("24-不存在.wav")) } catch {
    let ns = error as NSError
    badThrew = "domain=\(ns.domain) code=\(ns.code)"
    line("  文件不存在时构造就抛：\(badThrew)")
    line("  localizedDescription=\(ns.localizedDescription)")
}
expect(badThrew.contains("NSOSStatusErrorDomain"), "AVAudioPlayer 的失败发生在**构造**时，错误是 OSStatus 包装成的 NSError")

// ============================================================
// 4. AVAudioSession —— 所有音频行为的总开关
// ============================================================
line("== 4. AVAudioSession：category / mode / options / 路由 / 通知 ==")
let sess = AVAudioSession.sharedInstance()
line("  默认 category=\(sess.category.rawValue) mode=\(sess.mode.rawValue)")
expect(sess.category == .soloAmbient && sess.mode == .default,
       "新建进程的会话默认是 SoloAmbient + Default，不是 Playback —— 忘了改就「锁屏/静音键下没声音」")
line("  sampleRate=\(Int(sess.sampleRate)) preferredSampleRate=\(sess.preferredSampleRate) ioBufferDuration=\(f4(sess.ioBufferDuration))")
expect(sess.preferredSampleRate == 0.0,
       "preferredSampleRate 的 0.0 不是「0 Hz」，是「没提要求，由系统决定」")
line("  currentRoute.inputs=\(sess.currentRoute.inputs.count) outputs=\(sess.currentRoute.outputs.map { $0.portName })")
expect(sess.currentRoute.outputs.map { $0.portName } == ["Speaker"],
       "模拟器上输出端口就叫 Speaker；真机插耳机/蓝牙时这个数组会变，所以路由要靠通知监听而不是假设")
line("  outputVolume=\(String(format: "%.2f", sess.outputVolume)) isOtherAudioPlaying=\(sess.isOtherAudioPlaying) secondaryAudioShouldBeSilencedHint=\(sess.secondaryAudioShouldBeSilencedHint)")
line("  inputIsAvailable=\(sess.isInputAvailable) inputNumberOfChannels=\(sess.inputNumberOfChannels) outputNumberOfChannels=\(sess.outputNumberOfChannels) inputGain=\(sess.inputGain) inputGainSettable=\(sess.isInputGainSettable)")
let perm = sess.recordPermission
line("  recordPermission rawValue=\(perm.rawValue) 解 FourCC=\(fourcc(UInt32(perm.rawValue)))")
line("  三个 case 的 rawValue 与 FourCC 解码: "
     + "undetermined=\(AVAudioSession.RecordPermission.undetermined.rawValue)/\(fourcc(UInt32(AVAudioSession.RecordPermission.undetermined.rawValue))) "
     + "granted=\(AVAudioSession.RecordPermission.granted.rawValue)/\(fourcc(UInt32(AVAudioSession.RecordPermission.granted.rawValue))) "
     + "denied=\(AVAudioSession.RecordPermission.denied.rawValue)/\(fourcc(UInt32(AVAudioSession.RecordPermission.denied.rawValue)))")
expect(perm.rawValue == 1970168948 || perm.rawValue == 1735552628 || perm.rawValue == 1684369017,
       "AVAudioSession.RecordPermission 的 rawValue 是 FourCC（4 个 ASCII 字节拼成的整数），不是 0/1/2")
if #available(iOS 17.0, *) {
    let appPerm = AVAudioApplication.shared.recordPermission
    line("  iOS 17+ API：AVAudioApplication.shared.recordPermission.rawValue=\(appPerm.rawValue)")
    expect(String(appPerm.rawValue) == String(perm.rawValue),
           "AVAudioApplication 是 iOS 17 才有的新入口（直接写在 iOS 15 目标上编译报 'AVAudioApplication' is only available in iOS 17.0 or newer），它返回自己的枚举，不能和会话的老属性直接 ==，只能比数值")
}
line("  -- 六个 category 逐个设置 --")
for c: AVAudioSession.Category in [.playback, .record, .playAndRecord, .ambient, .soloAmbient, .multiRoute] {
    do {
        try sess.setCategory(c)
        line("  setCategory(\(c.rawValue)) -> 读回 \(sess.category.rawValue)")
    } catch { line("  setCategory(\(c.rawValue)) 抛 \(error as NSError) ") }
}
try? sess.setCategory(.playAndRecord, mode: .default,
                      options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
line("  playAndRecord + [.defaultToSpeaker,.allowBluetooth,.mixWithOthers] -> category=\(sess.category.rawValue)")
expect(sess.category == .playAndRecord,
       "setCategory(mode:options:) 之后 category 只回显主类别；SDK 里没有 categoryWithOptions 这个属性（探针试过，编译不过），想知道 options 只能自己记")
line("  CategoryOptions 单项 rawValue: mixWithOthers=\(AVAudioSession.CategoryOptions.mixWithOthers.rawValue) "
     + "duckOthers=\(AVAudioSession.CategoryOptions.duckOthers.rawValue) "
     + "allowBluetooth=\(AVAudioSession.CategoryOptions.allowBluetooth.rawValue) "
     + "allowBluetoothA2DP=\(AVAudioSession.CategoryOptions.allowBluetoothA2DP.rawValue) "
     + "defaultToSpeaker=\(AVAudioSession.CategoryOptions.defaultToSpeaker.rawValue) "
     + "overrideMutedMicrophoneInterruption=\(AVAudioSession.CategoryOptions.overrideMutedMicrophoneInterruption.rawValue)")
expect(AVAudioSession.CategoryOptions([.mixWithOthers, .duckOthers, .allowBluetoothA2DP, .defaultToSpeaker]).rawValue == 43,
       "options 是 OptionSet，合并 rawValue 按位或：1|2|32|8 = 43")
line("  -- setMode --")
try? sess.setMode(.voiceChat)
line("  setMode(.voiceChat) -> \(sess.mode.rawValue)")
try? sess.setMode(.default)
line("  setMode(.default) -> \(sess.mode.rawValue)")
line("  -- setActive --")
var setActiveThrew = ""
do {
    try sess.setActive(true)
    try sess.setActive(false)
    try sess.setActive(true)
} catch {
    let ns = error as NSError
    setActiveThrew = "domain=\(ns.domain) code=\(ns.code)"
}
line("  setActive(true)→(false)→(true) 三次调用的错误串=\"\(setActiveThrew)\"")
expect(setActiveThrew.isEmpty, "setActive(_:) 是 throws 的 Void：成功时没有任何返回值可看，只能靠有没有抛错判断")
line("  -- preferred 提示 --")
try? sess.setPreferredSampleRate(48000)
try? sess.setPreferredIOBufferDuration(0.005)
line("  提示之后 sampleRate=\(Int(sess.sampleRate)) preferredSampleRate=\(sess.preferredSampleRate) ioBufferDuration=\(f4(sess.ioBufferDuration))")
expect(sess.preferredSampleRate == 48000 && sess.ioBufferDuration > 0,
       "setPreferred* 只是「请求」：preferredSampleRate 会记下你的请求，真正的 ioBufferDuration 由系统取整（0.005 变 0.00266…）")
line("  -- 通知名（字符串就是系统 post 时用的名字）--")
line("  interruption=\(AVAudioSession.interruptionNotification.rawValue)")
line("  routeChange=\(AVAudioSession.routeChangeNotification.rawValue)")
line("  mediaServicesWereReset=\(AVAudioSession.mediaServicesWereResetNotification.rawValue)")
expect(AVAudioSession.interruptionNotification.rawValue == "AVAudioSessionInterruptionNotification"
       && AVAudioSession.routeChangeNotification.rawValue == "AVAudioSessionRouteChangeNotification",
       "这三个通知名都是 AVAudioSession 的实例属性吗？不是 —— 它们是类型上的 Notification.Name 常量")
line("  InterruptionType: began=\(AVAudioSession.InterruptionType.began.rawValue) ended=\(AVAudioSession.InterruptionType.ended.rawValue)（注意 began 是 1、ended 是 0）")
line("  RouteChangeReason: unknown=\(AVAudioSession.RouteChangeReason.unknown.rawValue) "
     + "newDeviceAvailable=\(AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue) "
     + "oldDeviceUnavailable=\(AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue)")
try? sess.setCategory(.playback)

// ============================================================
// 5. AVAudioRecorder —— headless 下能测到的边界
// ============================================================
line("== 5. AVAudioRecorder：prepareToRecord / record / 电平 / deleteRecording ==")
let recURL = tmp("24-rec.caf")
try? FileManager.default.removeItem(at: recURL)
let recSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVSampleRateKey: 44100.0,
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false,
]
do {
    let r = try AVAudioRecorder(url: recURL, settings: recSettings)
    line("  刚构造好：isRecording=\(r.isRecording) isMeteringEnabled=\(r.isMeteringEnabled) url=\(r.url.lastPathComponent)")
    expect(FileManager.default.fileExists(atPath: recURL.path) == false,
           "AVAudioRecorder(url:settings:) 只是建对象，连文件都不碰")
    let prepared = r.prepareToRecord()
    line("  prepareToRecord()=\(prepared) 之后文件存在=\(FileManager.default.fileExists(atPath: recURL.path))")
    expect(prepared && FileManager.default.fileExists(atPath: recURL.path),
           "文件是 prepareToRecord() 创建的（0 字节骨架），不是 record()")
    let started = r.record()
    line("  record()=\(started) isRecording=\(r.isRecording)")
    pump(0.2)
    line("  等 0.2s 之后 isRecording=\(r.isRecording) currentTime=\(f4(r.currentTime))")
    r.stop()
    let sz = bytesOf(recURL)
    line("  stop 之后文件存在=\(FileManager.default.fileExists(atPath: recURL.path)) 大小=\(sz)")
    expect(started == false && r.isRecording == false,
           "没有录音权限时 record() 返回 false 且**不抛错**、也不回调失败 delegate —— 只能自己查返回值")
    r.isMeteringEnabled = true
    _ = r.record(forDuration: 0.3)
    pump(0.35)
    r.updateMeters()
    line("  没录上时电平：peakPower(forChannel: 0)=\(r.peakPower(forChannel: 0)) averagePower=\(r.averagePower(forChannel: 0))")
    expect(r.peakPower(forChannel: 0) == -120,
           "-120 dB 是「全零/没测到」的下限值，不是真实音量；忘记 updateMeters() 就会一直读到它")
    line("  settings 键=\(r.settings.keys.sorted())")
    line("  format：\(fmt(r.format))")
    expect(r.format.channelCount == 1 && r.format.sampleRate == 44100,
           "r.format 反映的是 settings 里的采样率/声道数，与设备当前的 48 kHz 无关")
    let deleted = r.deleteRecording()
    line("  deleteRecording()=\(deleted) 文件还在=\(FileManager.default.fileExists(atPath: recURL.path))")
    expect(deleted == false,
           "没录过就没有「录音」可删，deleteRecording() 返回 false 且文件留在原地 —— 想清理请自己 removeItem")
} catch {
    let ns = error as NSError
    line("  构造抛出：domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
}
line("  -- 非法 settings --")
do {
    _ = try AVAudioRecorder(url: tmp("24-bad.caf"), settings: [AVFormatIDKey: 12345678])
    line("  居然没抛错")
} catch {
    let ns = error as NSError
    line("  乱写的 settings 在构造时就抛：domain=\(ns.domain) code=\(ns.code)")
    line("  localizedDescription=\(ns.localizedDescription)")
    expect(ns.domain == "NSOSStatusErrorDomain", "AVAudioRecorder 的错误同样是 OSStatus 直接塞进 NSError")
}

// ============================================================
// 6. CMTime —— AVFoundation 的时间地基
// ============================================================
line("== 6. CMTime / CMTimeRange / CMTimeFlags ==")
let m = CMTimeMake(value: 3, timescale: 2)
line("  CMTimeMake(value:3, timescale:2) -> \(cm(m)) flags=\(m.flags.rawValue)")
let d600 = CMTime(seconds: 1.5, preferredTimescale: 600)
line("  CMTime(seconds:1.5, preferredTimescale:600) -> \(cm(d600)) flags=\(d600.flags.rawValue)")
expect(m == d600 && CMTimeCompare(m, d600) == 0,
       "value/timescale 是分数表示，1.5 = 3/2 = 900/600，== 与 CMTimeCompare 都判等 —— 时间轴不同也能相等")
line("  -- 四个特殊值：光看 seconds 会误判，必须看 flags --")
for (name, t): (String, CMTime) in [("zero", .zero), ("indefinite", .indefinite),
                                       ("positiveInfinity", .positiveInfinity),
                                       ("negativeInfinity", CMTime.negativeInfinity)] {
    line("  \(name): value=\(t.value) ts=\(t.timescale) flags=\(t.flags.rawValue) valid=\(t.isValid) "
         + "indefinite=\(t.isIndefinite) posInf=\(t.flags.contains(CMTimeFlags.positiveInfinity)) secs=\(CMTimeGetSeconds(t))")
}
line("  indefinite 的 seconds 是 nan、posInf 的是 inf —— Double 的 nan 参与 ==/max/min 全是坑，所以要用 isIndefinite/flags 判断")
expect(CMTime.indefinite.isIndefinite && CMTime.indefinite.timescale == 0 && CMTime.indefinite.isValid,
       "indefinite 的 timescale 是 0，但 isValid 仍然是 true ——「有效」不等于「能算」")
expect(CMTimeGetSeconds(CMTime.positiveInfinity) == .infinity, "posInf 的 seconds 是 +inf（直播流的 duration 就长这样）")
let badTime = CMTime(value: 0, timescale: 0, flags: [], epoch: 0)
line("  手搓一个空 flags 的 CMTime：\(cm(badTime))")
expect(badTime.isValid == false, "flags 里没有 valid 位时 isValid=false；CMTime.invalid 就是这种东西")
line("  CMTimeFlags 的 rawValue: valid=\(CMTimeFlags.valid.rawValue) hasBeenRounded=\(CMTimeFlags.hasBeenRounded.rawValue) "
     + "positiveInfinity=\(CMTimeFlags.positiveInfinity.rawValue) negativeInfinity=\(CMTimeFlags.negativeInfinity.rawValue) "
     + "indefinite=\(CMTimeFlags.indefinite.rawValue) impliedValueFlagsMask=\(CMTimeFlags.impliedValueFlagsMask.rawValue)")
let nanAsTime = CMTime(seconds: .nan, preferredTimescale: 600)
line("  CMTime(seconds: .nan, preferredTimescale: 600) -> value=\(nanAsTime.value) flags=\(nanAsTime.flags.rawValue) secs=\(CMTimeGetSeconds(nanAsTime))")
expect(nanAsTime.value == Int64.min && nanAsTime.flags.contains(CMTimeFlags.valid),
       "把 Double.nan 塞进 CMTime(seconds:) 不会报错，它变成 value=Int64.min（-9223372036854775808）—— 这就是「传了个脏时间」的现场")
line("  -- 精度：三个 1/3 相加 --")
let third = CMTimeMake(value: 1, timescale: 3)
let sum3 = CMTimeAdd(CMTimeAdd(third, third), third)
line("  third=\(cm(third)) ; third+third+third -> \(cm(sum3))")
expect(sum3 == CMTimeMakeWithSeconds(1.0, preferredTimescale: 600) && CMTimeCompare(sum3, CMTimeMake(value: 1, timescale: 1)) == 0,
       "分数时间轴下 1/3+1/3+1/3 精确等于 1 秒（value=3/timescale=3 就是整数 1）")
let thirdScaled = CMTimeConvertScale(third, timescale: 600, method: .roundHalfAwayFromZero)
let thirdDown = CMTimeConvertScale(third, timescale: 600, method: .roundTowardZero)
line("  1/3 换到 600 标度：halfAway -> value=\(thirdScaled.value) (\(CMTimeGetSeconds(thirdScaled))) ; roundTowardZero -> value=\(thirdDown.value) (\(CMTimeGetSeconds(thirdDown)))")
expect(thirdScaled.value == 200 && thirdDown.value == 200,
       "1/3 在 600 标度下正好是整数 200，两种取整法结果相同（下面 1/2 换到 3 标度就是另一种情况）")
let half = CMTimeMake(value: 1, timescale: 2)
let halfScaled3 = CMTimeConvertScale(half, timescale: 3, method: .roundHalfAwayFromZero)
let halfDown3 = CMTimeConvertScale(half, timescale: 3, method: .roundTowardZero)
line("  1/2 换到 3 标度（1/2*3 = 1.5，正好卡在中间）：roundHalfAway value=\(halfScaled3.value) secs=\(CMTimeGetSeconds(halfScaled3)) flags=\(halfScaled3.flags.rawValue) ; roundTowardZero value=\(halfDown3.value) secs=\(CMTimeGetSeconds(halfDown3)) flags=\(halfDown3.flags.rawValue)")
expect(halfScaled3.value == 2 && halfDown3.value == 1,
       "除不尽时取整方式真的会改变 value（2 vs 1）—— 这就是为什么 CMTime 要带 hasBeenRounded 这个 flag")
expect(halfScaled3.flags.contains(CMTimeFlags.hasBeenRounded) && halfDown3.flags.contains(CMTimeFlags.hasBeenRounded),
       "两个结果的 flags 里都有 hasBeenRounded=2，说明系统知道这个数字被抹过")
let scaledZero = CMTimeConvertScale(CMTimeMake(value: 1, timescale: 3), timescale: 0, method: .roundHalfAwayFromZero)
line("  换成 timescale 0：\(cm(scaledZero))")
line("  CMTimeRoundingMethod 的 rawValue: roundHalfAwayFromZero=\(CMTimeRoundingMethod.roundHalfAwayFromZero.rawValue) "
     + "roundTowardZero=\(CMTimeRoundingMethod.roundTowardZero.rawValue) roundAwayFromZero=\(CMTimeRoundingMethod.roundAwayFromZero.rawValue) "
     + "quickTime=\(CMTimeRoundingMethod.quickTime.rawValue) "
     + "roundTowardPositiveInfinity=\(CMTimeRoundingMethod.roundTowardPositiveInfinity.rawValue) "
     + "roundTowardNegativeInfinity=\(CMTimeRoundingMethod.roundTowardNegativeInfinity.rawValue) "
     + "default=\(CMTimeRoundingMethod.default.rawValue)（default 就是 roundHalfAwayFromZero，两者都是 \(CMTimeRoundingMethod.default.rawValue)）")
expect(scaledZero.isValid == false && scaledZero.timescale == 0 && scaledZero.flags.rawValue == 0,
       "换算到 timescale=0 不抛错也不警告，直接给你一个 flags=0、isValid=false 的废时间，seconds 是 nan")
line("  -- CMTimeRange --")
let range = CMTimeRangeMake(start: CMTimeMake(value: 1, timescale: 2), duration: CMTimeMake(value: 2, timescale: 1))
line("  CMTimeRangeMake(start=1/2, dur=2/1): start=\(f4(CMTimeGetSeconds(range.start))) duration=\(f4(CMTimeGetSeconds(range.duration))) end=\(f4(CMTimeGetSeconds(range.end))) empty=\(range.isEmpty)")
expect(CMTimeGetSeconds(range.end) == 2.5, "end 是 start+duration 算出来的属性，不是独立存的字段")
line("  CMTimeRange.zero: empty=\(CMTimeRange.zero.isEmpty) start.flags=\(CMTimeRange.zero.start.flags.rawValue) dur.flags=\(CMTimeRange.zero.duration.flags.rawValue)")
let infRange = CMTimeRangeMake(start: .zero, duration: .positiveInfinity)
line("  起点 0、时长 +inf（=「整条轨道」常用写法）：end 的 posInf=\(infRange.end.flags.contains(CMTimeFlags.positiveInfinity)) valid=\(infRange.end.isValid) secs=\(CMTimeGetSeconds(infRange.end))")
expect(infRange.containsTime(CMTimeMakeWithSeconds(9999, preferredTimescale: 600)),
       "读整条资产时就把 duration 设成 +inf，containsTime 对任何有限时间都成立")
line("  -- 时间运算 --")
line("  Max(1s,2s)=\(f4(CMTimeGetSeconds(CMTimeMaximum(CMTimeMake(value: 1, timescale: 1), CMTimeMake(value: 2, timescale: 1))))) Min=\(f4(CMTimeGetSeconds(CMTimeMinimum(CMTimeMake(value: 1, timescale: 1), CMTimeMake(value: 2, timescale: 1)))))")
line("  Subtract(3s,1s)=\(f4(CMTimeGetSeconds(CMTimeSubtract(CMTimeMake(value: 3, timescale: 1), CMTimeMake(value: 1, timescale: 1))))) Multiply(2.5s@600, 2)=\(f4(CMTimeGetSeconds(CMTimeMultiply(CMTime(seconds: 2.5, preferredTimescale: 600), multiplier: 2))))")
line("  MultiplyByFloat64(1/3, 3.0)=\(f4(CMTimeGetSeconds(CMTimeMultiplyByFloat64(CMTimeMake(value: 1, timescale: 3), multiplier: 3.0))))")
line("  -- 为什么非用 CMTime 不可：拿 Double 累加 0.1 秒 --")
let t600 = CMTimeMakeWithSeconds(0.1, preferredTimescale: 600)
let addThree = CMTimeAdd(CMTimeAdd(t600, t600), t600)
let direct = CMTimeMakeWithSeconds(0.3, preferredTimescale: 600)
line("  CMTime：0.1+0.1+0.1 -> value=\(addThree.value) ; 直接 0.3 -> value=\(direct.value) ; 相等=\(addThree == direct)")
let dAdd = 0.1 + 0.1 + 0.1
line("  Double：0.1+0.1+0.1 = \(String(format: "%.17g", dAdd))，和 0.3(=\(String(format: "%.17g", 0.3))) 相等吗 \(dAdd == 0.3)")
expect(addThree == direct && dAdd != 0.3,
       "整型 value 的加法不会累积误差；Double 的 0.1+0.1+0.1 得到 0.30000000000000004 —— 这就是逐帧计数必须用 CMTime 的理由")

// ============================================================
// 7. AVAssetWriter —— 把像素 buffer 压成 mp4
// ============================================================
let W = 320, H = 240, FRAME_COUNT = 10
let FPS: Int32 = 30
line("== 7. AVAssetWriter + PixelBufferAdaptor：现场合成一段 \(W)x\(H)、\(FRAME_COUNT) 帧的 mp4 ==")
let vidURL = tmp("24-clip.mp4")
try? FileManager.default.removeItem(at: vidURL)
let writer = try AVAssetWriter(outputURL: vidURL, fileType: .mp4)
line("  刚建好：status=\(writer.status.rawValue)（unknown=0 writing=1 completed=2 failed=3 cancelled=4）")
let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: W,
    AVVideoHeightKey: H,
])
vInput.expectsMediaDataInRealTime = false
line("  writer.canAdd(vInput)=\(writer.canAdd(vInput))")
writer.add(vInput)
let adaptorAttrs: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: W,
    kCVPixelBufferHeightKey as String: H,
]
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: vInput,
                                                   sourcePixelBufferAttributes: adaptorAttrs)
line("  adaptor 声明的键=\(adaptorAttrs.keys.sorted())")
line("  adaptor.sourcePixelBufferAttributes 回读键=\(adaptor.sourcePixelBufferAttributes?.keys.sorted() ?? [])")
writer.startWriting()
line("  startWriting 之后 status=\(writer.status.rawValue)")
writer.startSession(atSourceTime: .zero)
line("  startSession 之后 status=\(writer.status.rawValue)，adaptor.pixelBufferPool 是否已就绪=\(adaptor.pixelBufferPool != nil)")
func makeFrame(_ index: Int) -> CVPixelBuffer {
    var pb: CVPixelBuffer? = nil
    let st = CVPixelBufferCreate(kCFAllocatorDefault, W, H, kCVPixelFormatType_32BGRA, nil, &pb)
    precondition(st == kCVReturnSuccess, "CVPixelBufferCreate 失败：\(st)")
    guard let buffer = pb else { fatalError() }
    CVPixelBufferLockBaseAddress(buffer, [])
    if let base = CVPixelBufferGetBaseAddress(buffer) {
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let bpr = CVPixelBufferGetBytesPerRow(buffer)
        for y in 0..<H {
            for x in 0..<W {
                let o = y * bpr + x * 4
                ptr[o] = UInt8((x + index * 7) & 0xFF)   // B
                ptr[o + 1] = UInt8(y & 0xFF)             // G
                ptr[o + 2] = 200                         // R
                ptr[o + 3] = 255                         // A
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(buffer, [])
    return buffer
}
var appendedFrames = 0
var notReadyWaits = 0
var appendFailed = false
while appendedFrames < FRAME_COUNT {
    if vInput.isReadyForMoreMediaData {
        let pts = CMTimeMake(value: Int64(appendedFrames), timescale: FPS)
        if adaptor.append(makeFrame(appendedFrames), withPresentationTime: pts) {
            appendedFrames += 1
        } else {
            appendFailed = true
            line("  append 失败：writer.status=\(writer.status.rawValue) error=\(String(describing: writer.error?.localizedDescription))")
            break
        }
    } else {
        notReadyWaits += 1
        pump(0.002)
    }
}
line("  写了 \(appendedFrames) 帧")
expect(appendedFrames == FRAME_COUNT && !appendFailed, "\(FRAME_COUNT) 帧全部 append 成功，中途没有一次 append 返回 false")
// notReadyWaits 的**具体值不进 stdout**：同一个循环在 -Onone 下实测等过 0 次、-O 下等过 25 次，
// 属于优化等级放大的调度差异，打印出来就过不了 debug/release 逐字节比对。
line("  闸门这道判断不能省：探针实测在 readyForMoreMediaData 为 NO 时硬 append 会直接崩")
line("  —— NSInternalInconsistencyException, reason: 'A pixel buffer cannot be appended when readyForMoreMediaData is NO.'（ObjC 异常，Swift 的 try 抓不住）")
expect(writer.status == .writing, "循环结束时 writer 仍停在 writing=1 —— 此刻文件还没写完，字节数不能当真（见下面 finishWriting）")
vInput.markAsFinished()
writer.finishWriting {}
_ = waitUntil(400) { writer.status != .writing }
line("  finishWriting 之后 status=\(writer.status.rawValue) error=\(String(describing: writer.error?.localizedDescription))")
let clipBytes = bytesOf(vidURL)
line("  mp4 字节数=\(clipBytes)")
expect(writer.status == .completed && clipBytes > 1000, "status=2(completed) 且文件有内容")

// ============================================================
// 8. AVPlayer / AVPlayerItem —— 状态机、时间观察者、KVO
//
// 这一节刻意排在**本章第一次 try await 之前**（§10 才引入 await）。原因见 §10 末尾的对照实测：
// 顶层代码只要 await 过一次，主线程就停在 main queue 的 block 里面，此后
// RunLoop.current.run(until:) 排不动 main queue，而 AVPlayer 的加载、时间推进、
// 时间观察者全吊在 main queue 上 —— 于是全部停摆。
// ============================================================
line("== 8. AVPlayer / AVPlayerItem：状态机、观察者与 KVO ==")
line("  AVPlayerItem.Status: unknown=\(AVPlayerItem.Status.unknown.rawValue) readyToPlay=\(AVPlayerItem.Status.readyToPlay.rawValue) failed=\(AVPlayerItem.Status.failed.rawValue)")
line("  AVPlayer.Status: unknown=\(AVPlayer.Status.unknown.rawValue) readyToPlay=\(AVPlayer.Status.readyToPlay.rawValue) failed=\(AVPlayer.Status.failed.rawValue)")
line("  AVPlayer.TimeControlStatus: paused=\(AVPlayer.TimeControlStatus.paused.rawValue) waiting=\(AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate.rawValue) playing=\(AVPlayer.TimeControlStatus.playing.rawValue)")
line("  AVAssetWriter.Status: unknown=\(AVAssetWriter.Status.unknown.rawValue) writing=\(AVAssetWriter.Status.writing.rawValue) "
     + "completed=\(AVAssetWriter.Status.completed.rawValue) failed=\(AVAssetWriter.Status.failed.rawValue) cancelled=\(AVAssetWriter.Status.cancelled.rawValue)")
line("  AVKeyValueStatus: unknown=\(AVKeyValueStatus.unknown.rawValue) loading=\(AVKeyValueStatus.loading.rawValue) "
     + "loaded=\(AVKeyValueStatus.loaded.rawValue) failed=\(AVKeyValueStatus.failed.rawValue) cancelled=\(AVKeyValueStatus.cancelled.rawValue)")

line("  -- 8.1 刚建好的 item：什么都还没发生 --")
// 用 §1 的 1 秒 wav：够长，能看清时间推进；又短，实验两三秒就跑完
let playerAsset = AVURLAsset(url: toneURL)
let item = AVPlayerItem(asset: playerAsset)
let avPlayer = AVPlayer(playerItem: item)
line("  刚建好的 item：status=\(item.status.rawValue) error=\(String(describing: (item.error as NSError?)?.domain))")
line("  item.duration=\(cm(item.duration))")
expect(item.status == .unknown && item.duration.isIndefinite,
       "AVPlayerItem 刚建好时 status=0(unknown)、duration 是 **indefinite**（secs=nan）而不是 0 —— 它还没去读文件")
line("  item.currentTime()=\(cm(item.currentTime())) isPlaybackLikelyToKeepUp=\(item.isPlaybackLikelyToKeepUp) isPlaybackBufferEmpty=\(item.isPlaybackBufferEmpty) isPlaybackBufferFull=\(item.isPlaybackBufferFull)")
line("  item.presentationSize=\(item.presentationSize) videoComposition=\(String(describing: item.videoComposition)) audioMix=\(String(describing: item.audioMix))")
line("  item.audioTimePitchAlgorithm=\(item.audioTimePitchAlgorithm.rawValue) canPlayFastForward=\(item.canPlayFastForward) canPlayReverse=\(item.canPlayReverse) canStepForward=\(item.canStepForward)")
line("  item.preferredForwardBufferDuration=\(f4(item.preferredForwardBufferDuration)) preferredPeakBitRate=\(item.preferredPeakBitRate)")
line("  item.automaticallyLoadedAssetKeys=\(item.automaticallyLoadedAssetKeys)")
expect(item.canPlayFastForward == false && item.canPlayReverse == false,
       "本地轨道的 canPlayXxx 全是 false —— 想倒放/快进得自己设 rate（负数、2.0），别等这几个标志")
expect(item.preferredForwardBufferDuration == 0.0 && item.preferredPeakBitRate == 0.0,
       "两个 preferred 都是 0 = 交给系统决定，不是「缓冲区 0 秒」")
_ = waitUntil(60) { item.status == .readyToPlay }
line("  挂上 player 之后什么都不做，只轮询 60 步：item.status=\(item.status.rawValue) player.status=\(avPlayer.status.rawValue) reason=\(String(describing: avPlayer.reasonForWaitingToPlay?.rawValue))")
expect(item.status == .readyToPlay,
       "**AVPlayer(playerItem:) 这一步本身就是触发加载**：不 play、不 seek，item 也会自己从 unknown(0) 走到 readyToPlay(1) —— 反过来，只 new 一个 AVPlayerItem 放在手里，它永远不会去读文件")

line("  -- 8.2 play()：状态机先 waiting 再 playing --")
avPlayer.play()
let rightAfterPlay = avPlayer.timeControlStatus
line("  play() 之后**立刻**读：item.status=\(item.status.rawValue) rate=\(f4(Double(avPlayer.rate))) timeControlStatus=\(rightAfterPlay.rawValue) reason=\(String(describing: avPlayer.reasonForWaitingToPlay?.rawValue))")
let reachedPlaying = waitUntil(100) { avPlayer.timeControlStatus == .playing }
line("  继续轮询到 playing=\(reachedPlaying)：timeControlStatus=\(avPlayer.timeControlStatus.rawValue) reason=\(String(describing: avPlayer.reasonForWaitingToPlay?.rawValue)) item.status=\(item.status.rawValue) player.status=\(avPlayer.status.rawValue)")
expect(item.status == .readyToPlay && avPlayer.status == .readyToPlay,
       "本地 wav 在 headless 里照样进 readyToPlay(1)，player 和 item 两个 status 一起变 1")
expect(rightAfterPlay == .waitingToPlayAtSpecifiedRate,
       "play() 之后**同一行代码里**读到的还是 waiting(1)、reason=AVPlayerWaitingWhileEvaluatingBufferingRateReason —— 别在这里判「播起来了没有」")
expect(reachedPlaying && avPlayer.reasonForWaitingToPlay == nil,
       "再等一会儿（本机实测约十几步 ×20ms）才走到 playing(2)、reason 变 nil：waiting 是过渡态，不是失败")
let ctAfterReady = item.currentTime()
// currentTime() 是墙钟读数：这一行在 play() 之后跑，慢一点就读到 0.04 秒、快一点读到 0.0，
// 连 timescale 都跟着变 —— 所以只报它的形状（有效、非 indefinite），具体秒数不进输出。
line("  ready 之后 item.duration=\(cm(item.duration)) currentTime() 的 valid=\(ctAfterReady.isValid) indefinite=\(ctAfterReady.isIndefinite)（秒数是墙钟读数，不参与打印与断言）likelyKeepUp=\(item.isPlaybackLikelyToKeepUp) bufferEmpty=\(item.isPlaybackBufferEmpty)")
expect(ctAfterReady.isValid && !ctAfterReady.isIndefinite,
       "readyToPlay 之后 currentTime() 已经是有效时间（valid=true、indefinite=false）—— 但「现在是第几秒」取决于这一行什么时候被执行，本机 debug 与 release 就读出过两个值，所以只断言形状")
expect(CMTimeGetSeconds(item.duration) == 1.0,
       "duration 从 indefinite 变成 1.0 —— 是 play() 触发的加载给的，不需要你先 await load")
line("  avPlayer.actionAtItemEnd=\(avPlayer.actionAtItemEnd.rawValue)（枚举：advance=\(AVPlayer.ActionAtItemEnd.advance.rawValue) pause=\(AVPlayer.ActionAtItemEnd.pause.rawValue) none=\(AVPlayer.ActionAtItemEnd.none.rawValue)；AVPlayer.h 明写只有 AVQueuePlayer 支持 advance，普通 player 设了会 raise NSInvalidArgumentException）")
expect(avPlayer.actionAtItemEnd == .pause,
       "actionAtItemEnd 默认 pause（rawValue \(avPlayer.actionAtItemEnd.rawValue)）—— 播完自动停，想循环得自己监听 AVPlayerItemDidPlayToEndTime 再 seek 回头")
line("  avPlayer.automaticallyWaitsToMinimizeStalling=\(avPlayer.automaticallyWaitsToMinimizeStalling) preventsDisplaySleepDuringVideoPlayback=\(avPlayer.preventsDisplaySleepDuringVideoPlayback) allowsExternalPlayback=\(avPlayer.allowsExternalPlayback) volume=\(f4(Double(avPlayer.volume))) isMuted=\(avPlayer.isMuted)")
expect(avPlayer.automaticallyWaitsToMinimizeStalling && avPlayer.preventsDisplaySleepDuringVideoPlayback && avPlayer.allowsExternalPlayback,
       "这三个开关默认全是 true —— 首帧卡顿归因、防熄屏、AirPlay 全在默认里开着")
avPlayer.pause()
line("  pause() 之后 rate=\(f4(Double(avPlayer.rate))) timeControlStatus=\(avPlayer.timeControlStatus.rawValue)")
expect(avPlayer.rate == 0.0 && avPlayer.timeControlStatus == .paused, "pause() 把 rate 归 0、状态回 paused=0")
avPlayer.rate = 2.5
line("  直接设 rate=2.5 -> timeControlStatus=\(avPlayer.timeControlStatus.rawValue) rate=\(f4(Double(avPlayer.rate)))")
avPlayer.rate = 0.0
line("  设 rate=0 -> timeControlStatus=\(avPlayer.timeControlStatus.rawValue)")
expect(avPlayer.timeControlStatus == .paused, "rate=0 等价于暂停，状态机自己会回 paused")
avPlayer.rate = 1.0
line("  设 rate=1 -> timeControlStatus=\(avPlayer.timeControlStatus.rawValue)")
avPlayer.pause()

line("  -- 8.3 seek：completion 先到，ready 后到 --")
let seekItem = AVPlayerItem(url: toneURL)
let seekPlayer = AVPlayer(playerItem: seekItem)
var exactSeekDone: Bool? = nil
seekPlayer.seek(to: CMTimeMakeWithSeconds(0.5, preferredTimescale: 600),
                toleranceBefore: .zero, toleranceAfter: .zero) { finished in
    exactSeekDone = finished
}
line("  发起 seek(0.5s, 容差 .zero) 之后**立刻**读：currentTime=\(cm(seekItem.currentTime())) status=\(seekItem.status.rawValue)")
_ = waitUntil(100) { exactSeekDone == true }
line("  completion 完成=\(String(describing: exactSeekDone))，此时 currentTime=\(cm(seekItem.currentTime())) status=\(seekItem.status.rawValue)")
expect(exactSeekDone == true && CMTimeGetSeconds(seekItem.currentTime()) == 0.5 && seekItem.status == .unknown,
       "seek 的 completion=true、currentTime 精确落在 0.5，但 item.status 仍是 unknown —— 「seek 成功」不等于「可以播放」")
var clampDone = false
avPlayer.seek(to: CMTimeMakeWithSeconds(5.0, preferredTimescale: 600)) { finished in clampDone = finished }
_ = waitUntil(100) { clampDone }
line("  往 \(f4(CMTimeGetSeconds(item.duration))) 秒的资产 seek 到 5.0（**默认容差**）：完成=\(clampDone) currentTime=\(cm(item.currentTime())) status=\(item.status.rawValue)")
expect(clampDone && CMTimeGetSeconds(item.currentTime()) == CMTimeGetSeconds(item.duration),
       "player 会把越界的 seek 夹到 duration：读回来的是 1.0 而不是 5.0，也不报错 —— 别指望它替你校验输入")
var clampDone2 = false
avPlayer.seek(to: CMTimeMakeWithSeconds(5.0, preferredTimescale: 600),
              toleranceBefore: .zero, toleranceAfter: .zero) { clampDone2 = $0 }
_ = waitUntil(100) { clampDone2 }
line("  同一位置改用**零容差** seek：完成=\(clampDone2) currentTime=\(cm(item.currentTime()))")
expect(CMTimeGetSeconds(item.currentTime()) == 1.0, "零容差也一样夹在 duration，容差只影响落点精度，不影响越界行为")

line("  -- 8.4 时间观察者：periodic 与 boundary --")
final class TickBox {
    var ticks: [String] = []
    var boundaryHits = 0
}
let box = TickBox()
var rewindDone = false
avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { rewindDone = $0 }
_ = waitUntil(100) { rewindDone }
line("  回到起点：currentTime=\(cm(item.currentTime()))")
let interval = CMTimeMake(value: 1, timescale: 10)
let observer = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { t in
    box.ticks.append(f4(CMTimeGetSeconds(t)))
}
pump(0.2)
line("  暂停状态下挂上观察者、再 pump 0.2 秒：ticks=\(box.ticks)")
expect(box.ticks.isEmpty,
       "暂停时 addPeriodicTimeObserver **不会**先给一次当前时间（AVPlayer.h 承诺的是「按 interval 回调」），想立刻拿到位置就自己读 currentTime()")
let bToken = avPlayer.addBoundaryTimeObserver(
    forTimes: [NSValue(time: CMTimeMakeWithSeconds(0.5, preferredTimescale: 600))], queue: .main) {
    box.boundaryHits += 1
}
avPlayer.play()
_ = waitUntil(150) { box.ticks.isEmpty == false }
line("  起步播放后收到的第一个 tick=\(box.ticks.first ?? "无")")
expect(box.ticks.first == "0.0000",
       "第一个 tick 给的是**起步位置** 0.0000，不是等满一个 interval 才来（interval=1/10 秒，从 0.3 起步时首个 tick 就是 0.3000 —— 探针实测）")
_ = waitUntil(150) { box.boundaryHits > 0 }
line("  boundary 观察者（设在 0.5 秒）命中次数=\(box.boundaryHits)")
expect(box.boundaryHits == 1, "boundary 只在时间**跨过**那个点时给一次，从 0 播到 0.5 就命中 1 次")
avPlayer.pause()
let ticksBeforeRemove = box.ticks.count
avPlayer.removeTimeObserver(bToken)
avPlayer.removeTimeObserver(observer)
avPlayer.play()
_ = waitUntil(60) { box.ticks.count > ticksBeforeRemove }
avPlayer.pause()
expect(box.ticks.count == ticksBeforeRemove,
       "removeTimeObserver 之后再播 1.2 秒，tick 数停在 \(ticksBeforeRemove) 不增长 —— 两种 token（\(type(of: observer)) / \(type(of: bToken))）都要还回去；忘了 remove 就是页面走了闭包还在被 player 持有")

line("  -- 8.5 KVO：change 里可能什么都没有 --")
var kvoLog: [String] = []
let kvoItem = AVPlayerItem(url: toneURL)
let itemObs = kvoItem.observe(\.status, options: [.initial, .new]) { _, change in
    let oldS = change.oldValue.map { String($0.rawValue) } ?? "nil"
    let newS = change.newValue.map { String($0.rawValue) } ?? "nil"
    kvoLog.append("item.status old=\(oldS) new=\(newS)（回调里现读 status=\(kvoItem.status.rawValue)）")
}
line("  只 new 了 item、还没挂 player，先注册 KVO 再读一次：kvoLog=\(kvoLog)")
expect(kvoLog.contains { $0.contains("old=nil new=nil") },
       "options 带 .initial 时，第一条就是 old/new 都为 nil 的初始快照 —— 上来就强解 newValue! 会崩")
let kvoPlayer = AVPlayer(playerItem: kvoItem)
let kvoObs = kvoPlayer.observe(\.currentItem, options: [.initial, .new]) { _, change in
    kvoLog.append("currentItem.newValue=\(change.newValue == nil ? "nil" : "有")")
}
_ = waitUntil(100) { kvoItem.status == .readyToPlay }
kvoPlayer.play()
_ = waitUntil(100) { kvoPlayer.timeControlStatus == .playing }
line("  挂上 player 并播到 playing 之后 kvoLog=\(kvoLog)")
expect(kvoLog.contains { $0.contains("new=nil") && $0.contains("现读 status=1") },
       "status 真的从 0 变到 1 了，但通知里的 old/new **仍然是 nil** —— AVPlayerItem.status 的 KVO 值不可靠，回调里重新读 item.status 才是准的")
expect(kvoLog.contains { $0.contains("currentItem.newValue=有") },
       "同一个 options 下 currentItem 的 KVO 就能拿到 newValue —— 拿不到值是 status 这类**内部手动通知**的键特有的坑，不是 KVO 全局如此")
kvoObs.invalidate()
itemObs.invalidate()

line("  -- 8.6 坏文件：什么时候才终于报 failed --")
let brokenURL = tmp("24-不存在.mp4")
let brokenItem = AVPlayerItem(url: brokenURL)
_ = waitUntil(60) { brokenItem.status != .unknown }
line("  坏文件、只 new 了 item 没挂 player，轮询 60 步：item.status=\(brokenItem.status.rawValue) error=\(String(describing: (brokenItem.error as NSError?)?.domain))")
expect(brokenItem.status == .unknown,
       "没人接手就没人去开文件：坏文件此时和好文件一模一样，停在 unknown(0)、error 还是 nil —— 8.1 那条「挂上 player 才触发加载」是这里唯一的分水岭")
let brokenPlayer = AVPlayer(playerItem: brokenItem)
let sawFailed = waitUntil(60) { brokenItem.status == .failed }
let brokenErr = brokenItem.error as NSError?
line("  只是挂上 player（**还没 play()**）就等到 failed=\(sawFailed)：item.status=\(brokenItem.status.rawValue) domain=\(String(describing: brokenErr?.domain)) code=\(String(describing: brokenErr?.code)) desc=\(String(describing: brokenErr?.localizedDescription))")
line("  同一时刻 brokenPlayer.status=\(brokenPlayer.status.rawValue) timeControlStatus=\(brokenPlayer.timeControlStatus.rawValue) currentTime=\(cm(brokenPlayer.currentTime()))")
expect(brokenItem.status == .failed && brokenErr?.domain == "AVFoundationErrorDomain" && brokenErr?.code == -11800,
       "触发加载之后坏文件立刻 failed(2) + AVFoundationErrorDomain/-11800（AVURLAsset 打不开文件统一是这个码，和「文件不存在」还是「格式不对」无关）")
expect(brokenPlayer.status == .readyToPlay,
       "player 自己照样 readyToPlay(1)，坏的是 item —— 监听必须挂在 item.status 上，挂 player 上会看到「一切正常」")
// ============================================================
// 9. AVPlayerViewController / AVPlayerLayer / 画中画 —— 播放器上面那层界面
// （同样排在 await 之前：videoRect 这类值要 player 真就绪了才有意义）
// ============================================================
line("== 9. AVPlayerViewController、AVPlayerLayer 与画中画能力 ==")
// 这里换成 §7 现合成的 mp4：有画面才谈得上 videoGravity 与画中画
let videoItem = AVPlayerItem(asset: AVURLAsset(url: vidURL))
let videoPlayer = AVPlayer(playerItem: videoItem)
let videoReady = waitUntil(100) { videoItem.status == .readyToPlay }
line("  视频 item：等到 readyToPlay=\(videoReady) status=\(videoItem.status.rawValue) presentationSize=\(videoItem.presentationSize) duration=\(f4(CMTimeGetSeconds(videoItem.duration)))")
expect(videoItem.status == .readyToPlay && videoItem.presentationSize.width == 320.0,
       "presentationSize 是 320x240 —— §7 写进去多大就是多大；它是**轨道内容尺寸**，不是 layer 的尺寸")

line("  -- 9.1 AVPlayerViewController 的默认值 --")
let pvc = AVPlayerViewController()
line("  空 controller：player=\(String(describing: pvc.player)) showsPlaybackControls=\(pvc.showsPlaybackControls) showsTimecodes=\(pvc.showsTimecodes)")
expect(pvc.showsPlaybackControls && !pvc.showsTimecodes,
       "进度条默认显示（自己画控制条时第一件事就是把它关掉），时间码默认不显示（iOS 13 才有这个开关）")
line("  allowsPictureInPicturePlayback=\(pvc.allowsPictureInPicturePlayback) canStartPictureInPictureAutomaticallyFromInline=\(pvc.canStartPictureInPictureAutomaticallyFromInline) updatesNowPlayingInfoCenter=\(pvc.updatesNowPlayingInfoCenter)")
expect(pvc.allowsPictureInPicturePlayback && !pvc.canStartPictureInPictureAutomaticallyFromInline && pvc.updatesNowPlayingInfoCenter,
       "PiP 权限默认开、从 inline 自动进画中画默认关、NowPlaying 默认由它接管 —— 第三条要和 §17 自己写 MPNowPlayingInfoCenter 配合，两边都开就是互相覆盖")
line("  entersFullScreenWhenPlaybackBegins=\(pvc.entersFullScreenWhenPlaybackBegins) exitsFullScreenWhenPlaybackEnds=\(pvc.exitsFullScreenWhenPlaybackEnds) requiresLinearPlayback=\(pvc.requiresLinearPlayback)")
line("  videoGravity=\(pvc.videoGravity.rawValue) isReadyForDisplay=\(pvc.isReadyForDisplay) videoBounds=\(pvc.videoBounds) delegate=\(String(describing: pvc.delegate)) pixelBufferAttributes=\(String(describing: pvc.pixelBufferAttributes))")
expect(pvc.videoGravity == AVLayerVideoGravity.resizeAspect && !pvc.isReadyForDisplay,
       "默认 AVLayerVideoGravityResizeAspect（等比例留黑边）；没进窗口层级时 isReadyForDisplay 就是 false")
line("  contentOverlayView 类型=\(type(of: pvc.contentOverlayView as Any))，它的 layer 是 AVPlayerLayer 吗=\(pvc.contentOverlayView?.layer is AVPlayerLayer)")
expect(pvc.contentOverlayView?.layer is AVPlayerLayer == false,
       "叠加层是普通视图 + 普通 CALayer：想往画面上盖自定义 UI 就 add 进 contentOverlayView，而不是去找那个看不见的播放层")
if #available(iOS 16.0, *) {
    line("  iOS 16 起的长按倍速表：speeds=\(pvc.speeds.map { f4(Double($0.rate)) }) selectedSpeed=\(String(describing: pvc.selectedSpeed?.rate))（系统默认表=\(AVPlaybackSpeed.systemDefaultSpeeds.map { f4(Double($0.rate)) })）")
    expect(pvc.speeds.map { Double($0.rate) } == [0.5, 1.0, 1.25, 1.5, 2.0],
           "倍速档位是 AVPlaybackSpeed 对象数组（rate + localizedName），不是 [Double]；系统默认这 5 档")
    pvc.speeds = [AVPlaybackSpeed(rate: 1.75, localizedName: "1.75x")]
    line("  只留 1.75x 一档：speeds=\(pvc.speeds.map { f4(Double($0.rate)) }) selectedSpeed=\(String(describing: pvc.selectedSpeed?.rate))")
    expect(pvc.selectedSpeed?.rate == 1.75,
           "换了 speeds，selectedSpeed 立刻跟着变成新表里的档位 —— 它不是「用户点过哪个」的记录，别拿它当用户偏好存")
}
pvc.player = videoPlayer
line("  设 player 之后：pvc.player === videoPlayer ? \(pvc.player === videoPlayer) title=\(String(describing: pvc.title)) preferredContentSize=\(pvc.preferredContentSize)")
line("  pvc.view 类型=\(type(of: pvc.view))，view.layer 类型=\(type(of: pvc.view.layer))，view.subviews.count=\(pvc.view.subviews.count)")
expect(pvc.view.subviews.isEmpty,
       "没 present、没进窗口层级之前，控制条上一个子视图都还没建 —— 在这里遍历 subviews 找播放按钮一定是空")

line("  -- 9.2 AVPlayerLayer：把画面铺到自己视图里 --")
let playerLayer = AVPlayerLayer(player: videoPlayer)
line("  新建：videoGravity=\(playerLayer.videoGravity.rawValue) isReadyForDisplay=\(playerLayer.isReadyForDisplay) videoRect=\(playerLayer.videoRect) pixelBufferAttributes=\(String(describing: playerLayer.pixelBufferAttributes))")
line("  AVLayerVideoGravity 三个取值：resize=\(AVLayerVideoGravity.resize.rawValue) resizeAspect=\(AVLayerVideoGravity.resizeAspect.rawValue) resizeAspectFill=\(AVLayerVideoGravity.resizeAspectFill.rawValue)")
final class PlayerBackedView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
let boxView = PlayerBackedView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
line("  layerClass 写法：view.layer 是 AVPlayerLayer 吗=\(boxView.layer is AVPlayerLayer)，一开始 player=\(String(describing: boxView.playerLayer.player))")
boxView.playerLayer.player = videoPlayer
line("  100x100 的盒子装 320x240 的画面：videoRect=\(boxView.playerLayer.videoRect)（默认 resizeAspect → 等比缩到 100x75，上下各留 12.5 的黑边）")
expect(boxView.playerLayer.videoRect == CGRect(x: 0, y: 12.5, width: 100, height: 75),
       "videoRect 由 videoGravity 和 layer 尺寸算出来：320x240 塞进 100x100 等比适配就是 (0,12.5,100,75) —— 想改填充方式就动 videoGravity")
boxView.playerLayer.videoGravity = .resizeAspectFill
line("  改成 resizeAspectFill 之后 videoRect=\(boxView.playerLayer.videoRect)")
let hostView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
hostView.layer.addSublayer(playerLayer)
playerLayer.frame = hostView.bounds
videoPlayer.play()
_ = waitUntil(60) { playerLayer.isReadyForDisplay }
line("  挂进 view、设好 frame、播起来，轮询 60 步：isReadyForDisplay=\(playerLayer.isReadyForDisplay) videoRect=\(playerLayer.videoRect) bounds=\(playerLayer.bounds)")
expect(playerLayer.isReadyForDisplay == false && playerLayer.videoRect.width == 320.0,
       "headless 里没有真正的 display：videoRect 照样给 320x240，isReadyForDisplay 却永远 false —— 「等 readyForDisplay 再显示封面」这类逻辑在测试里会一直卡住")
if #available(iOS 16.0, *) {
    line("  displayedPixelBuffer()（iOS 16+，想拿当前帧做二次处理用的）=\(String(describing: boxView.playerLayer.displayedPixelBuffer())) —— 没有显示器就是 nil")
}
videoPlayer.pause()

line("  -- 9.3 画中画：能力、ContentSource，以及不支持时那些「静默失效」的开关 --")
let pipSupported = AVPictureInPictureController.isPictureInPictureSupported()
line("  AVPictureInPictureController.isPictureInPictureSupported()=\(pipSupported)（当前设备/模拟器）")
let pipSource = AVPictureInPictureController.ContentSource(playerLayer: playerLayer)
line("  ContentSource(playerLayer:)：src.playerLayer === playerLayer ? \(pipSource.playerLayer === playerLayer)")
let pip = AVPictureInPictureController(contentSource: pipSource)
line("  init(contentSource:) 返回值不是 Optional：isPictureInPicturePossible=\(pip.isPictureInPicturePossible) isActive=\(pip.isPictureInPictureActive) isSuspended=\(pip.isPictureInPictureSuspended)")
expect(pipSupported == false && pip.isPictureInPicturePossible == false,
       "设备不支持时 isPossible 永远是 false：startPictureInPicture() 不崩、不回调、状态也不动 —— 界面别只根据「我自己开了 PiP」就摆出一个画中画按钮")
line("  不支持时 init 收下的 contentSource 读回来是 nil：pip.contentSource == nil ? \(pip.contentSource == nil)")
pip.contentSource = pipSource
line("  再手动赋值一次，读回还是 nil、还是不相等：==nil ? \(pip.contentSource == nil) ===src ? \(pip.contentSource === pipSource)")
expect(pip.contentSource == nil,
       "所有 setter 在这条路径上都是**静默丢弃**：赋完读回 nil —— 千万别用「读回来是不是我要的对象」验证配置成功")
line("  开关也一样：canStartPictureInPictureAutomaticallyFromInline 默认=\(pip.canStartPictureInPictureAutomaticallyFromInline)，设 true 读回=\(pip.canStartPictureInPictureAutomaticallyFromInline)")
line("  requiresLinearPlayback 默认=\(pip.requiresLinearPlayback)，设 true 读回=\(pip.requiresLinearPlayback)")
pip.startPictureInPicture()
line("  调过 startPictureInPicture() 之后 isActive=\(pip.isPictureInPictureActive)（没崩，但什么都没发生）")
let legacyPip = AVPictureInPictureController(playerLayer: playerLayer)
line("  老写法 init(playerLayer:) 是 **failable**：legacyPip == nil ? \(legacyPip == nil)（返回类型 AVPictureInPictureController?，AVPlayerLayer 版内部还会做设备校验）")
expect(legacyPip == nil, "用 init(playerLayer:) 时必须处理 nil；init(contentSource:) 不返回 nil，但会悄悄把 contentSource 扔掉 —— 两种写法各有各的失败方式")
line("  （注）探针实测：不支持时读 pip.playerLayer 会直接 SIGSEGV —— 它在头文件里标成 nonnull，运行时却是 nil，")
line("  Swift 不做检查就当成非 Optional 用。所以本章只读 contentSource / isPictureInPicturePossible，绝不碰 playerLayer。")

// ============================================================
// 10. AVAsset —— 同步旧读法 vs try await 新读法
// ============================================================
line("== 10. AVAsset / AVAssetTrack：两种读法，一份数据 ==")
let asset = AVURLAsset(url: vidURL)
let durSync = CMTimeGetSeconds(asset.duration)
let tracksSync = asset.tracks
line("  旧写法（直接访问属性）：duration=\(durSync) tracks=\(tracksSync.count) isPlayable=\(asset.isPlayable) hasProtectedContent=\(asset.hasProtectedContent)")
let vTrack = tracksSync.first(where: { $0.mediaType == .video })!
line("  轨：mediaType=\(vTrack.mediaType.rawValue)（FourCC=\(fourccAny(vTrack.mediaType.rawValue))）trackID=\(vTrack.trackID)")
line("  轨：naturalSize=\(vTrack.naturalSize) nominalFrameRate=\(vTrack.nominalFrameRate)")
line("  轨：timeRange start=\(f4(CMTimeGetSeconds(vTrack.timeRange.start))) duration=\(f4(CMTimeGetSeconds(vTrack.timeRange.duration))) naturalTimeScale=\(vTrack.naturalTimeScale)")
line("  轨：preferredTransform a=\(vTrack.preferredTransform.a) d=\(vTrack.preferredTransform.d) isEnabled=\(vTrack.isEnabled) isDecodable=\(vTrack.isDecodable) isSelfContained=\(vTrack.isSelfContained)")
line("  轨：estimatedDataRate=\(vTrack.estimatedDataRate) totalSampleDataLength=\(vTrack.totalSampleDataLength) segments=\(vTrack.segments.count) requiresFrameReordering=\(vTrack.requiresFrameReordering)")
line("  轨：formatDescriptions=\(vTrack.formatDescriptions.count) 个，首个的 mediaType FourCC=\(fourccAny((vTrack.formatDescriptions.first as! CMFormatDescription).mediaType.rawValue))")
expect(vTrack.mediaType == .video && vTrack.mediaType.rawValue == "vide" && cc("vide") == 1986618469,
       "Swift 里 AVMediaType.video.rawValue 是字符串 'vide'，CoreMedia 层它是 UInt32 1986618469 = 4 个 ASCII 字节拼的 FourCC")
expect(vTrack.naturalSize == CGSize(width: W, height: H),
       "naturalSize 是 (320, 240)：编码器如实记录了写入时的宽高")
expect(abs(vTrack.nominalFrameRate - 30.0) < 0.001,
       "nominalFrameRate 读回 \(vTrack.nominalFrameRate)，不是整数 30 —— 别拿 == 比 CGFloat/Double 帧率")
expect(CMTimeGetSeconds(vTrack.timeRange.duration) == durSync,
       "轨道的 timeRange.duration 和资产的 duration 在这里相等（只有一条轨时正常）")
expect(vTrack.formatDescriptions.count == 1, "一条 H.264 轨对应一个 CMFormatDescription")
line("  轨：hasMediaCharacteristic(.audible)=\(vTrack.hasMediaCharacteristic(.audible)) hasMediaCharacteristic(.visual)=\(vTrack.hasMediaCharacteristic(.visual))")
line("  轨：minFrameDuration=\(f4(CMTimeGetSeconds(vTrack.minFrameDuration)))（\(FRAME_COUNT) 帧一段 → 每帧 \(f4(1.0/Double(FPS))) 秒）")
let ptsAt01 = CMTimeGetSeconds(vTrack.samplePresentationTime(forTrackTime: CMTimeMake(value: 1, timescale: 10)))
line("  轨：samplePresentationTime(forTrackTime: 0.1s)=\(f4(ptsAt01)) —— trackTime 与呈现时间不是一回事")
let seg = vTrack.segment(forTrackTime: CMTimeMake(value: 1, timescale: 10))
line("  轨：segment(forTrackTime: 0.1s) 存在=\(seg != nil) isEmpty=\(String(describing: seg?.isEmpty))")
expect(seg?.isEmpty == false, "0.1 秒落在唯一的 segment 里")
line("  轨：preferredVolume=\(vTrack.preferredVolume)")
line("  -- 新写法：try await asset.load(...) --")
let durAsync = try await asset.load(.duration)
let tracksAsync = try await asset.load(.tracks)
line("  await duration=\(cm(durAsync)) tracks=\(tracksAsync.count)")
expect(CMTimeGetSeconds(durAsync) == durSync && tracksAsync.count == tracksSync.count,
       "两种读法拿到的是同一个数 —— 差别只在「谁去读文件、在哪个线程读」")
let natSizeA = try await vTrack.load(.naturalSize)
let rateA = try await vTrack.load(.nominalFrameRate)
let rangeA = try await vTrack.load(.timeRange)
let fdA = try await vTrack.load(.formatDescriptions)
let charsA = try await vTrack.load(.mediaCharacteristics)
let enabledA = try await vTrack.load(.isEnabled)
line("  await naturalSize=\(natSizeA) nominalFrameRate=\(rateA) timeRange.duration=\(f4(CMTimeGetSeconds(rangeA.duration))) formatDescriptions=\(fdA.count)")
line("  await mediaCharacteristics=\(charsA.map { $0.rawValue }.sorted()) isEnabled=\(enabledA)")
expect(charsA.contains(.visual) && charsA.contains(.frameBased),
       "mediaCharacteristics 里的值是 'AVMediaCharacteristicVisual'/'AVMediaCharacteristicFrameBased' 这类字符串，连 public.main-program-content 也算一种特征")
expect(f4(CMTimeGetSeconds(rangeA.duration)) == f4(CMTimeGetSeconds(vTrack.timeRange.duration)),
       "load 之后同步属性也能读了 —— load(_:) 的作用就是把值取进缓存")
line("  -- load 之后同步读会怎样 --")
let playableA = try await asset.load(.isPlayable)
line("  await isPlayable=\(playableA)，同步 asset.isPlayable=\(asset.isPlayable)")
expect(playableA == asset.isPlayable, "已 load 过的键，同步属性直接吃缓存；没 load 过的键在 iOS 上会阻塞甚至死锁")
line("  statusOfValue(forKey: 'duration')=\(asset.statusOfValue(forKey: "duration", error: nil).rawValue)（unknown=0 loading=1 loaded=2 failed=3 cancelled=4）")
expect(asset.statusOfValue(forKey: "duration", error: nil) == .loaded, "load(.duration) 之后状态机停在 loaded=2")
line("  -- 音频资产做对照：同一个 API 家族 --")
let audioAsset = AVURLAsset(url: toneURL)
let aDur = try await audioAsset.load(.duration)
let aTracks = try await audioAsset.load(.tracks)
let aTrack = aTracks.first!
let aChars = try await aTrack.load(.mediaCharacteristics)
line("  wav：duration=\(cm(aDur)) tracks=\(aTracks.count) mediaType=\(aTrack.mediaType.rawValue)")
let aFD = aTrack.formatDescriptions.first as! CMFormatDescription
line("  wav 轨首个 formatDescription：mediaType=\(fourccAny(aFD.mediaType.rawValue)) 子类型=\(fourccAny(CMFormatDescriptionGetMediaSubType(aFD)))")
line("  wav 轨：timeRange.duration=\(f4(CMTimeGetSeconds(aTrack.timeRange.duration))) nominalFrameRate=\(aTrack.nominalFrameRate) naturalSize=\(aTrack.naturalSize)")
line("  wav 轨 mediaCharacteristics=\(aChars.map { $0.rawValue }.sorted())")
expect(aTrack.mediaType == .audio && aTrack.mediaType.rawValue == "soun",
       "AVMediaType.audio 的 FourCC 是 'soun'；PCM 真正的编码标签（lpcm/sowt）在 formatDescription 里，不在 mediaType 里")
expect(aChars.contains(.audible), "音频轨的 mediaCharacteristics 里是 AVMediaCharacteristicAudible")
line("  -- 常见 FourCC 一览（全部来自本次运行用到的常量）--")
line("  AVVideoCodecType：h264=\(AVVideoCodecType.h264.rawValue)(cc=\(cc(AVVideoCodecType.h264.rawValue))) "
     + "hevc=\(AVVideoCodecType.hevc.rawValue)(cc=\(cc(AVVideoCodecType.hevc.rawValue))) "
     + "jpeg=\(AVVideoCodecType.jpeg.rawValue)(cc=\(cc(AVVideoCodecType.jpeg.rawValue)))")
line("  kAudioFormatLinearPCM=\(Int(kAudioFormatLinearPCM))/\(fourcc(UInt32(kAudioFormatLinearPCM))) "
     + "kAudioFormatMPEG4AAC=\(Int(kAudioFormatMPEG4AAC))/\(fourcc(UInt32(kAudioFormatMPEG4AAC)))")
line("  AVAudioCommonFormat: otherFormat=\(AVAudioCommonFormat.otherFormat.rawValue) pcmFormatFloat32=\(AVAudioCommonFormat.pcmFormatFloat32.rawValue) pcmFormatFloat64=\(AVAudioCommonFormat.pcmFormatFloat64.rawValue) pcmFormatInt16=\(AVAudioCommonFormat.pcmFormatInt16.rawValue)")
expect(fourcc(UInt32(kAudioFormatLinearPCM)) == "lpcm" && fourcc(UInt32(kAudioFormatMPEG4AAC)) == "aac ",
       "kAudioFormatLinearPCM 解出 'lpcm'，kAudioFormatMPEG4AAC 解出 'aac '（注意末尾那个空格，FourCC 必须占满 4 字节）")

line("  -- 对照：同一份播放实验，放到 await **之后**再跑一次 --")
// 顶层 await 一发生，主线程就停在 main queue 的 block 里面；此后嵌套的
// RunLoop.current.run(until:) 不再排空 main queue（libdispatch 不允许重入主队列的 drain）。
// AVPlayer 的加载、时间推进、观察者投递全吊在 main queue 上，于是整体停摆。
var mainBlockRan = false
DispatchQueue.main.async { mainBlockRan = true }
let drained = waitUntil(20) { mainBlockRan }
line("  此刻 DispatchQueue.main.async 排进去的 block 有没有被执行=\(drained)（pump 了 20 步）")
expect(drained == false,
       "await 之后连一个 main queue 的 block 都排不动 —— §8 那些回调全靠它，这就是「live 实验必须抢在 await 之前」的根因，跟 AVFoundation 无关")
let deadItem = AVPlayerItem(url: toneURL)
let deadPlayer = AVPlayer(playerItem: deadItem)
var deadTicks: [String] = []
let deadToken = deadPlayer.addPeriodicTimeObserver(
    forInterval: CMTimeMake(value: 1, timescale: 10), queue: .main) { t in
    deadTicks.append(f4(CMTimeGetSeconds(t)))
}
deadPlayer.play()
_ = waitUntil(60) { deadTicks.isEmpty == false }
line("  §8 里跑得活蹦乱跳的同一套代码，这里：item.status=\(deadItem.status.rawValue) "
     + "timeControlStatus=\(deadPlayer.timeControlStatus.rawValue) currentTime=\(cm(deadPlayer.currentTime())) periodic 回调数=\(deadTicks.count)")
expect(deadItem.status == .unknown && CMTimeGetSeconds(deadPlayer.currentTime()) == 0.0 && deadTicks.isEmpty,
       "item 停在 unknown(0)、currentTime 冻在 0.0000、回调一个都不来 —— 这是**脚本环境**的现象：真机/App 里主 runloop 一直在转、没人往被占住的 main queue 里嵌套排队列，不会遇到")
deadPlayer.removeTimeObserver(deadToken)

// ============================================================
// 11. AVAssetReader —— 把文件解成 sample buffer
// ============================================================
line("== 11. AVAssetReader：音频轨与视频轨分别解码 ==")
line("  AVAssetReader.Status: unknown=\(AVAssetReader.Status.unknown.rawValue) reading=\(AVAssetReader.Status.reading.rawValue) "
     + "completed=\(AVAssetReader.Status.completed.rawValue) failed=\(AVAssetReader.Status.failed.rawValue) cancelled=\(AVAssetReader.Status.cancelled.rawValue)")
let audioTrackForReader = try await asset.loadTracks(withMediaType: .audio).first
line("  asset.loadTracks(withMediaType: .audio) 在 mp4 上取到的第一条=\(String(describing: audioTrackForReader))")
expect(audioTrackForReader == nil, "loadTracks(withMediaType:) 是按类型筛轨的异步方法 —— 这条 mp4 没有音轨，返回空数组")
let videoTrack = try await asset.loadTracks(withMediaType: .video).first!
let vReader = try AVAssetReader(asset: asset)
line("  刚建好：status=\(vReader.status.rawValue) timeRange.duration=\(cm(vReader.timeRange.duration))")
expect(vReader.timeRange.duration.flags.contains(CMTimeFlags.positiveInfinity)
       && CMTimeGetSeconds(vReader.timeRange.duration) == .infinity,
       "不设 timeRange 时 reader 的 duration 是 **+inf**（flags=5），不是资产的 0.3333 秒 —— 别拿它当循环上限，也别拿 isIndefinite 去判它")
let probeOut = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
line("  canAdd(probeOut)=\(vReader.canAdd(probeOut))")
let bgraSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: W,
    kCVPixelBufferHeightKey as String: H,
]
let vOut = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: bgraSettings)
vReader.add(vOut)
let vStarted = vReader.startReading()
var vFrameCount = 0
var vWidths: [Int] = []
var firstPTSs: [String] = []
while let sb = vOut.copyNextSampleBuffer() {
    vFrameCount += 1
    if vFrameCount <= 3 { firstPTSs.append(f4(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sb)))) }
    if let pb = CMSampleBufferGetImageBuffer(sb) {
        vWidths.append(CVPixelBufferGetWidth(pb))
    }
}
line("  startReading=\(vStarted)：解出 \(vFrameCount) 帧，宽=\(Array(Set(vWidths)).sorted())，前 3 个 PTS=\(firstPTSs)")
line("  结束：status=\(vReader.status.rawValue) error=\(String(describing: (vReader.error as NSError?)?.domain))")
expect(vStarted && vReader.status == .completed && vFrameCount == FRAME_COUNT,
       "写完 10 帧、读回 10 帧，status 走到 completed=2 —— copyNextSampleBuffer() 返回 nil 就是结束信号")
expect(vWidths.allSatisfy { $0 == W } && firstPTSs == ["0.0000", "0.0333", "0.0667"],
       "像素 buffer 的宽度就是当初的 \(W)，PTS 严格按 1/\(FPS) 递增")
// 音频侧：读 §1 的 wav
let wavAsset = AVURLAsset(url: toneURL)
let wavTrack = try await wavAsset.loadTracks(withMediaType: .audio).first!
let aReader = try AVAssetReader(asset: wavAsset)
let aOut = AVAssetReaderTrackOutput(track: wavTrack, outputSettings: [
    AVFormatIDKey: kAudioFormatLinearPCM, AVNumberOfChannelsKey: 1, AVSampleRateKey: SR,
])
aReader.add(aOut)
let aStarted = aReader.startReading()
var sbCount = 0
var totalFrames = 0
var firstAudioPTS = -1.0
var asbdLine = "没有 formatDescription"
var firstBufBytes = 0
while let sb = aOut.copyNextSampleBuffer() {
    sbCount += 1
    totalFrames += CMSampleBufferGetNumSamples(sb)
    if sbCount == 1 {
        firstAudioPTS = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sb))
        if let fd = CMSampleBufferGetFormatDescription(sb) {
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fd)!.pointee
            asbdLine = "id=\(fourcc(asbd.mFormatID)) ch=\(asbd.mChannelsPerFrame) sr=\(asbd.mSampleRate) "
                     + "bpf=\(asbd.mBytesPerFrame) bits=\(asbd.mBitsPerChannel) framesPerPacket=\(asbd.mFramesPerPacket)"
        }
        firstBufBytes = CMSampleBufferGetDataBuffer(sb).map { CMBlockBufferGetDataLength($0) } ?? 0
    }
}
line("  wav：startReading=\(aStarted) 读到 \(sbCount) 个 sample buffer、合计 \(totalFrames) 帧，首个 PTS=\(f4(firstAudioPTS))")
line("  输出的 ASBD=\(asbdLine)")
line("  第一个 buffer 的字节数=\(firstBufBytes)（帧数 × mBytesPerFrame）")
line("  结束：status=\(aReader.status.rawValue)")
expect(aStarted && aReader.status == .completed && totalFrames == Int(readBack.length),
       "解码出来的总帧数和 AVAudioFile.length 一致（\(totalFrames) 帧）—— 两条读文件的通路对同一份字节的解释相同")
expect(sbCount > 1 && firstBufBytes == 32768,
       "\(sbCount) 个 buffer 才凑出 \(totalFrames) 帧，第一个 buffer 装 32768 字节（8192 帧 × 4 字节）—— 音频是分批给的，必须 while copyNextSampleBuffer")
line("  status 一旦变成 completed/failed，reader 就不能复用；要重读得重新 new 一个 AVAssetReader")

// ============================================================
// 12. reader → writer：把 wav 转码成 m4a（AAC）
// ============================================================
line("== 12. 转码管线：AVAssetReaderTrackOutput → AVAssetWriterInput ==")
let m4aURL = tmp("24-clip.m4a")
try? FileManager.default.removeItem(at: m4aURL)
let tWriter = try AVAssetWriter(outputURL: m4aURL, fileType: .m4a)
let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVSampleRateKey: SR,
    AVNumberOfChannelsKey: 1,
    AVEncoderBitRateKey: 64_000,
])
aInput.expectsMediaDataInRealTime = false
line("  tWriter.canAdd(aInput)=\(tWriter.canAdd(aInput))")
tWriter.add(aInput)
let srcReader = try AVAssetReader(asset: wavAsset)
let srcTrack = try await wavAsset.loadTracks(withMediaType: .audio).first!
// outputSettings 给 nil = 「按文件里原样给我」，这里是线性 PCM
let srcOut = AVAssetReaderTrackOutput(track: srcTrack, outputSettings: nil)
srcReader.add(srcOut)
tWriter.startWriting()
tWriter.startSession(atSourceTime: .zero)
let pumpStarted = srcReader.startReading()
var pcmBuffers = 0
var transcodedFrames = 0
var transcodeAppendFailed = false
while let sb = srcOut.copyNextSampleBuffer() {
    if aInput.isReadyForMoreMediaData {
        if aInput.append(sb) {
            pcmBuffers += 1
            transcodedFrames += CMSampleBufferGetNumSamples(sb)
        } else {
            transcodeAppendFailed = true
            line("  append 抛错：\((tWriter.error as NSError?)?.localizedDescription ?? "?")")
            break
        }
    } else {
        pump(0.002)
    }
}
aInput.markAsFinished()
line("  读了 \(pcmBuffers) 个 PCM sample buffer、\(transcodedFrames) 帧，append 失败=\(transcodeAppendFailed)")
await tWriter.finishWriting()
line("  await finishWriting() 之后 status=\(tWriter.status.rawValue) error=\(String(describing: (tWriter.error as NSError?)?.domain))")
let m4aBytes = bytesOf(m4aURL)
line("  m4a 字节数=\(m4aBytes)（源 wav 是 \(bytesOf(toneURL)) 字节）")
expect(pumpStarted && !transcodeAppendFailed && tWriter.status == .completed && transcodedFrames == Int(readBack.length),
       "整条管线一帧不丢：\(transcodedFrames) 帧进、\(transcodedFrames) 帧出，status=completed")
expect(m4aBytes > 0 && m4aBytes < bytesOf(toneURL) / 4,
       "64 kbps 的 AAC 把 176 KB 的 PCM 压到了 \(m4aBytes) 字节 —— 压缩比就是转码存在的理由")
let m4aAsset = AVURLAsset(url: m4aURL)
let m4aDur = try await m4aAsset.load(.duration)
let m4aTracks = try await m4aAsset.load(.tracks)
let m4aFD = m4aTracks.first!.formatDescriptions.first as! CMFormatDescription
line("  读回转码结果：duration=\(cm(m4aDur)) tracks=\(m4aTracks.count) 子类型=\(fourccAny(CMFormatDescriptionGetMediaSubType(m4aFD)))")
expect(m4aDur.value == 44100 && m4aDur.timescale == 44100 && fourccAny(CMFormatDescriptionGetMediaSubType(m4aFD)) == "aac ",
       "读回来 duration 是 44100/44100 = \(f4(CMTimeGetSeconds(m4aDur))) 秒，和源**一模一样**。这里有个必须交代的过程：写这一节时我先按「AAC 有 priming/编码器延迟，容器一定会把时长记长一点」的直觉把断言写成 47104/44100，跑出来直接 FAIL —— 这条管线上 CoreAudio 把 priming 消化在轨道内部，asset 这一层读到的就是 44100。教训有两层：①**时长相等不能当正确性判据**（它相等也许只是这一层没记 priming），要比的是上面那条帧数；②凡是「按理说应该」的数值，一律先跑一遍再写进断言，本章每条 expect 都是这么来的")
line("  对照：同一段 finishWriting {} + 轮询在 §7（还没 await）好使，在这里就不行了 —— 实测 status 永远停在 writing=1、文件 0 字节，因为那个完成 block 排不进被占住的 main queue（§10 末尾的对照实验）。这就是本章后半段一律用 await finishWriting() 的原因")

// ============================================================
// 13. AVAssetExportSession —— 「给我一个现成档位」
// ============================================================
line("== 13. AVAssetExportSession：preset、支持的容器、导出 ==")
line("  AVAssetExportSession.Status: unknown=\(AVAssetExportSession.Status.unknown.rawValue) waiting=\(AVAssetExportSession.Status.waiting.rawValue) "
     + "exporting=\(AVAssetExportSession.Status.exporting.rawValue) completed=\(AVAssetExportSession.Status.completed.rawValue) "
     + "failed=\(AVAssetExportSession.Status.failed.rawValue) cancelled=\(AVAssetExportSession.Status.cancelled.rawValue)")
let allPresets = AVAssetExportSession.allExportPresets()
let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
line("  allExportPresets()=\(allPresets.count) 项；exportPresets(compatibleWith: 这段 mp4)=\(compatiblePresets.count) 项")
line("  兼容清单=\(compatiblePresets.sorted())")
expect(allPresets.count > compatiblePresets.count,
       "「所有档位」比「这份资产能用的档位」多 —— 拿 NotApplicable 之外的档位去建 session 可能直接返回 nil")
expect(!compatiblePresets.contains(AVAssetExportPresetAppleM4A),
       "视频资产不兼容 AppleM4A 档位；反过来音频资产也没有 640x480 这类视频档位可用")
if let exp = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
    line("  建好 session：status=\(exp.status.rawValue) progress=\(f4(Double(exp.progress)))")
    line("  supportedFileTypes=\(exp.supportedFileTypes.map { $0.rawValue }.sorted())")
    line("  timeRange.duration=\(f4(CMTimeGetSeconds(exp.timeRange.duration))) metadata=\(String(describing: exp.metadata)) audioMix=\(String(describing: exp.audioMix)) shouldOptimizeForNetworkUse=\(exp.shouldOptimizeForNetworkUse)")
    expect(exp.timeRange.duration.flags.contains(CMTimeFlags.positiveInfinity),
           "session 默认的 timeRange 也是 +inf（整条资产），不是 duration 的 0.3333")
    let outURL = tmp("24-export.mp4")
    try? FileManager.default.removeItem(at: outURL)
    exp.outputURL = outURL
    exp.outputFileType = .mp4
    var exportDone = false
    exp.exportAsynchronously { exportDone = true }
    _ = waitUntil(600) { exportDone }
    let exportBytes = bytesOf(outURL)
    line("  导出结束=\(exportDone) status=\(exp.status.rawValue) error=\(String(describing: (exp.error as NSError?)?.code)) 字节=\(exportBytes)")
    expect(exportDone && exp.status == .completed && (exp.error as NSError?) == nil,
           "status=3(completed)；回调只是通知「结束了」，成功与否还得看 status 和 error")
    expect(exp.progress == 1.0, "completed 时 progress 读回 \(f4(Double(exp.progress)))")
    expect(exportBytes > 1000, "导出的 mp4 有内容")
    line("  （注）exp.estimatedMaximumDuration / estimatedOutputFileLength 是 **async throws** 的估算属性；")
    line("  在本文件的顶层（main actor）里读它们，编译器会报 non-sendable type 'AVAssetExportSession' exiting main actor-isolated")
    line("  context … cannot cross actor boundary。本章要求零告警，所以这里不调用，探针记录见 docs。")
} else {
    line("  AVAssetExportSession(asset:presetName:) 返回了 nil")
}
line("  -- 用音频资产再问一次档位 --")
let audioPresets = AVAssetExportSession.exportPresets(compatibleWith: wavAsset)
line("  wav 兼容档位=\(audioPresets.sorted())")
expect(audioPresets.contains(AVAssetExportPresetAppleM4A) && !compatiblePresets.contains(AVAssetExportPresetAppleM4A),
       "同一段 PCM 的 wav 让 AppleM4A 出现在兼容表里，视频 mp4 的表里却没有 —— 档位可用性由**资产内容**决定，不是全局常量")

// ============================================================
// 14. AVAssetImageGenerator —— 抓一帧出来
// ============================================================
line("== 14. AVAssetImageGenerator：缩略图 ==")
let gen = AVAssetImageGenerator(asset: asset)
line("  默认：appliesPreferredTrackTransform=\(gen.appliesPreferredTrackTransform) maximumSize=\(gen.maximumSize) apertureMode=\(String(describing: gen.apertureMode))")
line("  默认容差：requestedTimeToleranceBefore.isIndefinite=\(gen.requestedTimeToleranceBefore.isIndefinite) after=\(gen.requestedTimeToleranceAfter.isIndefinite)")
expect(gen.appliesPreferredTrackTransform == false && gen.maximumSize == .zero,
       "默认不套用轨的 preferredTransform（手机竖拍的视频抓出来会是横的），maximumSize=(0,0) 表示原始尺寸")
gen.appliesPreferredTrackTransform = true
gen.maximumSize = CGSize(width: 160, height: 120)
if #available(iOS 16.0, *) {
    let at5 = CMTimeMake(value: 5, timescale: FPS)
    do {
        let result = try await gen.image(at: at5)
        line("  await image(at: 5/30) -> CGImage \(result.image.width)x\(result.image.height)，actualTime=\(cm(result.actualTime))")
        expect(result.image.width == 160 && result.image.height == 120,
               "maximumSize 是「装进这个框」，160x120 恰好等比例，所以输出就是 160x120")
        expect(CMTimeGetSeconds(result.actualTime) == 0.0,
               "只要了 5/30 秒但默认容差极宽，实际给的是 0 秒那一帧 —— 要精确就得把 tolerance 设成 .zero")
    } catch {
        line("  抓帧抛错：\((error as NSError).domain)/\((error as NSError).code)")
    }
    let exactGen = AVAssetImageGenerator(asset: asset)
    exactGen.requestedTimeToleranceBefore = .zero
    exactGen.requestedTimeToleranceAfter = .zero
    do {
        let r2 = try await exactGen.image(at: CMTimeMake(value: 7, timescale: FPS))
        line("  容差设成 zero 后抓 7/30 秒：actualTime=\(cm(r2.actualTime)) 尺寸=\(r2.image.width)x\(r2.image.height)")
        expect(CMTimeGetSeconds(r2.actualTime) == 7.0/Double(FPS),
               "tolerance=.zero 之后 actualTime 就是请求的那一帧（\(f4(CMTimeGetSeconds(r2.actualTime)))），尺寸回到原始 \(W)x\(H)")
    } catch {
        line("  精确抓帧抛错：\((error as NSError).domain)/\((error as NSError).code)")
    }
    let farTime = CMTimeMake(value: 99, timescale: 1)
    if let far = try? await gen.image(at: farTime) {
        line("  越界时间（99 秒，资产只有 \(f4(durSync)) 秒）抓帧**没有**抛错，反而给了 actualTime=\(cm(far.actualTime)) 的 \(far.image.width)x\(far.image.height)")
        expect(CMTimeGetSeconds(far.actualTime) == 0.0,
               "超出范围的请求不报错、不返回 nil，而是给你最近的一帧（这里是第 0 帧）—— 靠返回值判断时间合法性是判断不出来的")
    } else {
        line("  越界时间抓帧抛错")
    }
    do {
        _ = try await AVAssetImageGenerator(asset: wavAsset).image(at: .zero)
        line("  纯音频资产抓帧居然成功了")
    } catch {
        let ns = error as NSError
        line("  纯音频（没有视频轨）资产抓帧抛错：domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
        expect(ns.domain == "AVFoundationErrorDomain" && ns.code == -11869,
               "没有视频轨时是 -11869 'Cannot Open'，不是返回 nil")
    }
    let ghostURL = tmp("24-不存在.mp4")
    do {
        _ = try await AVAssetImageGenerator(asset: AVURLAsset(url: ghostURL)).image(at: .zero)
        line("  文件不存在居然也成功了")
    } catch {
        let ns = error as NSError
        line("  文件不存在时抛错：domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
        expect(ns.code == -11800, "「文件打不开」是 -11800，和「没有视频轨」的 -11869 是两个码 —— 报错信息一样，code 才是区分依据")
    }
} else {
    line("  iOS 16 以下只有已废弃的 copyCGImage(at:actualTime:)，这里跳过")
}

// ============================================================ 15
line("")
line("== 15) AVAudioEngine：手动（offline）渲染 —— 把音频图变成可复现的纯函数 ==")
line("  前面 AVAudioPlayer 那一节只能告诉你「它在播」，采样到底长什么样你看不见。")
line("  AVAudioEngine 是一条**数据流图**：节点（node）+ 连线（connection），引擎按时间推进，")
line("  每个渲染周期把图从头算到尾。真机上这件事由音频线程按 44100 分之一秒的节奏自动做；")
line("  headless 环境既没有扬声器也不该依赖墙钟，所以本章把它切到**手动渲染模式**：")
line("  你不推进时间，引擎一个采样都不算；你调 renderOffline(要多少帧)，它就算多少帧。")
line("  同样的图、同样的输入 → 逐字节相同的输出，于是波形峰值可以写进 expect。")

/// 非交织立体声：手动渲染最常用的目标格式（15.4 用交织版本演示读取陷阱）
let stereoNI = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: SR, channels: 2, interleaved: false)!

/// DispatchSemaphore.wait 在 async 上下文里会被编译器拒绝（顶层是 async main），
/// 同样包一层非 async 的函数：这里等的是引擎内部队列，和主 runloop 无关，await 之后也能用
func waitBriefly(_ sema: DispatchSemaphore, _ seconds: Double) -> Bool {
    sema.wait(timeout: .now() + seconds) == .success
}

/// completion 回调由引擎内部队列投递，不保证在主线程、也不保证顺序。
/// 本章要求 debug/release 的 stdout 逐字节一致，所以用一个带锁的小盒子收日志。
final class CBBox {
    private let lock = NSLock()
    private var items: [String] = []
    func add(_ s: String) { lock.lock(); items.append(s); lock.unlock() }
    func log() -> [String] { lock.lock(); defer { lock.unlock() }; return items }
}

/// 内存里造一段正弦（单声道非交织 Float32），完全不碰磁盘
func sineBuf(_ frames: Int, hz: Double, amp: Float) -> AVAudioPCMBuffer {
    let b = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: AVAudioFrameCount(frames))!
    b.frameLength = AVAudioFrameCount(frames)
    let d = b.floatChannelData![0]
    for i in 0..<frames { d[i] = amp * Float(sin(2 * .pi * hz * Double(i) / SR)) }
    return b
}
/// 内存里造一段直流：整块峰值恒定，讲增益时最好核对
func dcBuf(_ frames: Int, _ amp: Float) -> AVAudioPCMBuffer {
    let b = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: AVAudioFrameCount(frames))!
    b.frameLength = AVAudioFrameCount(frames)
    let d = b.floatChannelData![0]
    for i in 0..<frames { d[i] = amp }
    return b
}
/// 顶层代码在 Swift 里是 **async main**，直接调用带 completionHandler 的 API 时编译器会提示
/// "consider using asynchronous alternative function"（AVAudioPlayerNode 那几个 schedule* 都配了 async 版）。
/// 离线渲染本来就是同步的：await 下去等的是「数据被消费」，而手动模式里没有时钟在推，等不到。
/// 所以把这些调用挪进**非 async** 的函数里，警告的前提（当前是异步上下文）就不成立了。
func scheduleSync(_ node: AVAudioPlayerNode, _ buffer: AVAudioPCMBuffer,
                  at when: AVAudioTime? = nil,
                  options: AVAudioPlayerNodeBufferOptions = [],
                  completion: AVAudioNodeCompletionHandler? = nil) {
    node.scheduleBuffer(buffer, at: when, options: options, completionHandler: completion)
}
/// 带回调时机参数的版本（15.12 用它对比三种 completion 时机）
func scheduleSync(_ node: AVAudioPlayerNode, _ buffer: AVAudioPCMBuffer,
                  callbackType: AVAudioPlayerNodeCompletionCallbackType,
                  completion: @escaping (AVAudioPlayerNodeCompletionCallbackType) -> Void) {
    node.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: callbackType, completionHandler: completion)
}
/// AVAudioFile 整段排进播放队列（async 版在手动模式下等不到，理由同上）
func scheduleFileSync(_ node: AVAudioPlayerNode, _ file: AVAudioFile) {
    node.scheduleFile(file, at: nil, completionHandler: nil)
}
func scheduleFileSync(_ node: AVAudioPlayerNode, _ file: AVAudioFile,
                      startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
    node.scheduleSegment(file, startingFrame: startingFrame, frameCount: frameCount, at: nil, completionHandler: nil)
}

/// 造一台「离线渲染」引擎：playerNode → mainMixer → （手动模式没有 outputNode 什么事）。
/// **每个实验都用新建的引擎** —— 同一个引擎连着做几个实验，上一路没渲染完的数据会留在图里，
/// 探针实测会把干净的比例关系搅成 0.6844 / 0.2407 这种看不懂的数字。
func makeOffline(_ maxFrames: AVAudioFrameCount = 1024,
                 target: AVAudioFormat = stereoNI,
                 source: AVAudioFormat = monoF) -> (AVAudioEngine, AVAudioPlayerNode) {
    let e = AVAudioEngine()
    do { try e.enableManualRenderingMode(.offline, format: target, maximumFrameCount: maxFrames) }
    catch { let ns = error as NSError; line("  enableManualRenderingMode 抛错：\(ns.domain)/\(ns.code)") }
    let n = AVAudioPlayerNode()
    e.attach(n)
    e.connect(n, to: e.mainMixerNode, format: source)
    e.prepare()
    do { try e.start() } catch { let ns = error as NSError; line("  start() 抛错：\(ns.domain)/\(ns.code)") }
    return (e, n)
}
/// 渲染 blocks 块，每块 capacity 帧；返回每块的峰值（四位小数字符串）。抛错就记下错误码并停住。
func renderPeaks(_ e: AVAudioEngine, blocks: Int, capacity: AVAudioFrameCount) -> [String] {
    var out: [String] = []
    for _ in 0..<blocks {
        let b = AVAudioPCMBuffer(pcmFormat: e.manualRenderingFormat, frameCapacity: capacity)!
        do {
            let status = try e.renderOffline(capacity, to: b)
            out.append(f4(Double(peakOf(b))))
            if status.rawValue != 0 { out.append("status=\(status.rawValue)"); break }
        } catch {
            let ns = error as NSError
            out.append("throw \(ns.domain)/\(ns.code)")
            break
        }
    }
    return out
}

// ---- 15.1 一台新引擎出厂时是什么样 ----
line("")
line("  -- 15.1 新引擎的默认状态 --")
do {
    let e = AVAudioEngine()
    line("  isRunning=\(e.isRunning) isInManualRenderingMode=\(e.isInManualRenderingMode) isAutoShutdownEnabled=\(e.isAutoShutdownEnabled)")
    line("  inputNode=\(type(of: e.inputNode)) outputNode=\(type(of: e.outputNode)) mainMixerNode=\(type(of: e.mainMixerNode))")
    line("  attachedNodes=\(e.attachedNodes.count) types=\(e.attachedNodes.map { String(describing: type(of: $0)) }.sorted())")
    line("  （注）上面这一行读的是**已经读过 inputNode/outputNode/mainMixerNode 之后**的引擎：探针实测只 new 完、一个属性都不碰时 attachedNodes=0，")
    line("        碰过那三个属性就变 3 —— 它们是**惰性创建**的，attachedNodes 只登记已经建出来的，不代表「图里应该有什么」")
    line("  mainMixer.numberOfInputs=\(e.mainMixerNode.numberOfInputs) numberOfOutputs=\(e.mainMixerNode.numberOfOutputs) outputVolume=\(f4(Double(e.mainMixerNode.outputVolume)))")
    line("  inputNode.inputFormat(forBus:0)  \(fmt(e.inputNode.inputFormat(forBus: 0)))")
    line("  inputNode.outputFormat(forBus:0) \(fmt(e.inputNode.outputFormat(forBus: 0)))")
    line("  mainMixer.outputFormat(forBus:0) \(fmt(e.mainMixerNode.outputFormat(forBus: 0)))")
    let hw = e.inputNode.outputFormat(forBus: 0)
    line("  硬件输入格式那个 commonFormat 打印出来是 \(hw.commonFormat) —— 本 SDK 的 Swift 枚举只有 otherFormat=0 / pcmFormatFloat32=\(AVAudioCommonFormat.pcmFormatFloat32.rawValue) / pcmFormatFloat64=\(AVAudioCommonFormat.pcmFormatFloat64.rawValue)，CoreAudio 却返回了 \(hw.commonFormat.rawValue)，于是它变成一个枚举里没有的 case")
    expect(e.mainMixerNode.outputFormat(forBus: 0).commonFormat == .pcmFormatFloat32,
           "mixer 出口永远是 Float32 非交织（commonFormat=1）；inputNode 的格式则**由设备决定**，模拟器上没有真实输入，sampleRate 直接是 \(hw.sampleRate)")
    expect(e.attachedNodes.count == 3 && !e.isRunning,
           "新引擎不 attach 任何节点也有 3 个，但 isRunning=false：attach/connect 只是画图，start() 才开始流动")
    expect(e.mainMixerNode.numberOfInputs == 8 && e.mainMixerNode.numberOfOutputs == 1,
           "mainMixer 默认 8 路进 1 路出（numberOfInputs=8 是这张图能同时挂几个源的硬上限）")
    expect(!e.outputNode.responds(to: NSSelectorFromString("outputVolume")),
           "outputVolume 只在 mixer 这类节点上有，AVAudioOutputNode 根本不响应这个 selector —— 想调总音量得找 mainMixerNode")
}

// ---- 15.2 打开手动渲染模式 ----
line("")
line("  -- 15.2 enableManualRenderingMode(.offline, …) 改写了整台引擎的时钟 --")
do {
    let e = AVAudioEngine()
    let before = e.manualRenderingSampleTime
    do {
        try e.enableManualRenderingMode(.offline, format: stereoNI, maximumFrameCount: 1024)
        line("  enable 之后：isInManualRenderingMode=\(e.isInManualRenderingMode) manualRenderingMode 原始值=\(e.manualRenderingMode.rawValue)（offline=0 realtime=1）")
        let mf = e.manualRenderingFormat
        line("  manualRenderingFormat \(fmt(mf)) maxFrameCount=\(e.manualRenderingMaximumFrameCount) sampleTime=\(e.manualRenderingSampleTime)")
        line("  inputNode.outputFormat(forBus:0) 变成 \(fmt(e.inputNode.outputFormat(forBus: 0))) —— 手动模式下 inputNode 不再是麦克风，而是你喂数据的口子")
        expect(e.manualRenderingMode == .offline && e.manualRenderingSampleTime == before,
               "打开手动模式那一刻时间轴停在 0：offline 就是「时钟归你管」")
        expect(e.manualRenderingFormat.channelCount == 2 && e.manualRenderingMaximumFrameCount == 1024,
               "你给的 format 和 maximumFrameCount 就是此后 renderOffline 的天花板，读回来一模一样")
        // 再 enable 一次：不抛错，直接换参数
        try e.enableManualRenderingMode(.offline, format: stereoNI, maximumFrameCount: 512)
        line("  重复 enable（把上限从 1024 改成 512）：没有抛错，manualRenderingMaximumFrameCount=\(e.manualRenderingMaximumFrameCount)")
        expect(e.manualRenderingMaximumFrameCount == 512,
               "enable 可以反复调，最后一次说了算 —— 它不是「已开启就报错」的那种 API")
    } catch {
        let ns = error as NSError
        line("  enableManualRenderingMode 抛错：domain=\(ns.domain) code=\(ns.code)")
    }
}

// ---- 15.3 renderOffline 的两条容量红线 ----
line("")
line("  -- 15.3 一次要太多帧：抛错，不是给你静音 --")
do {
    let (e, _) = makeOffline(1024)
    let tooBig = AVAudioPCMBuffer(pcmFormat: e.manualRenderingFormat, frameCapacity: 1024)!
    do {
        _ = try e.renderOffline(2048, to: tooBig)
        line("  要 2048 帧居然成功了")
    } catch {
        let ns = error as NSError
        line("  renderOffline(2048) 而 maximumFrameCount=1024：domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
        expect(ns.domain == "com.apple.coreaudio.avfaudio" && ns.code == -50,
               "要的帧数超过 enable 时给的 maximumFrameCount → kAudio_ParamError(-50)，**抛错**而不是给你一段静音")
    }
    let tooSmall = AVAudioPCMBuffer(pcmFormat: e.manualRenderingFormat, frameCapacity: 256)!
    do {
        _ = try e.renderOffline(1024, to: tooSmall)
        line("  往容量 256 的 buffer 里渲染 1024 帧也成功了")
    } catch {
        let ns = error as NSError
        line("  renderOffline(1024, to: 容量 256 的 buffer)：domain=\(ns.domain) code=\(ns.code)")
        expect(ns.code == -50, "第二个红线：capacity 装不下你要的帧数，同样是 -50 —— 这两条线都跟数据内容无关，纯粹是尺寸校验")
    }
}

// ---- 15.4 交织与非交织：同一块内存的两种读法 ----
line("")
line("  -- 15.4 目标格式 interleaved=true 时，floatChannelData[1] 不是右声道 --")
do {
    let stI = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: SR, channels: 2, interleaved: true)!
    for (label, target) in [("mono", monoF), ("stereo 非交织", stereoNI), ("stereo 交织", stI)] {
        let (e, n) = makeOffline(1024, target: target)
        scheduleSync(n, sineBuf(1024, hz: 311, amp: 1.0))
        n.play()
        let b = AVAudioPCMBuffer(pcmFormat: e.manualRenderingFormat, frameCapacity: 1024)!
        guard (try? e.renderOffline(1024, to: b)) != nil else { line("  \(label)：渲染失败"); continue }
        let d = b.floatChannelData!
        let chCount = Int(b.format.channelCount)
        let c0 = (0..<6).map { f4(Double(d[0][$0])) }
        line("  \(label) \(fmt(target))：frameLength=\(b.frameLength) peak=\(f4(Double(peakOf(b)))) ch0 前 6 个=\(c0)")
        if chCount < 2 {
            line("                     单声道 buffer 的 floatChannelData 只有一条，索引 [1] 是**越界读** —— 探针实测这一步直接 SIGSEGV，所以先判 channelCount")
            expect(b.format.channelCount == 1,
                   "channelCount 是声道数的唯一依据：mono 目标格式渲染出来仍然只有 1 条声道，索引 [1] 绝不能碰")
        } else {
            let c1 = (0..<6).map { f4(Double(d[1][$0])) }
            line("                     ch1 前 6 个=\(c1)")
            if target.isInterleaved {
                expect(d[1][0] == d[0][1] && d[1][1] == d[0][2],
                       "交织时 ch1 就是 ch0 整体往后挪一格：L0 R0 L1 R1 挤在同一段内存里，floatChannelData[1] 不是右声道")
            } else {
                expect(d[0][3] == d[1][3],
                       "非交织时两条声道各自独立：这里左右声道内容相同，所以第 4 个采样逐位相等")
            }
        }
        expect(peakOf(b) > 0.6 && peakOf(b) < 0.75,
               "\(label) 的峰值都是 \(f4(Double(peakOf(b))))：交织与否只改索引方式，不改数值")
    }
}

// ---- 15.5 顺序错了，图就只是一张图 ----
line("")
line("  -- 15.5 三层顺序：引擎要 start、播放器要 play、队列里还得真有帧 --")
do {
    // 第一层：引擎 start() 之前就去 render
    let e = AVAudioEngine()
    try? e.enableManualRenderingMode(.offline, format: stereoNI, maximumFrameCount: 512)
    let n = AVAudioPlayerNode()
    e.attach(n)
    e.connect(n, to: e.mainMixerNode, format: monoF)
    scheduleSync(n, sineBuf(512, hz: 440, amp: 0.5))
    n.play()
    line("  第 1 层 isRunning=\(e.isRunning) isPlaying=\(n.isPlaying)：prepare()/start() 都没调，renderPeaks=\(renderPeaks(e, blocks: 2, capacity: 512))")
    e.prepare()
    line("  只 prepare() 不 start()：isRunning=\(e.isRunning)，renderPeaks=\(renderPeaks(e, blocks: 2, capacity: 512))")
    expect(!e.isRunning, "prepare() 不改变 isRunning —— 它只是预热，别指望它让 renderOffline 能跑")
    var afterStart: [String] = []
    do {
        try e.start()
        afterStart = renderPeaks(e, blocks: 2, capacity: 512)
        line("  补上 start()：isRunning=\(e.isRunning) isPlaying=\(n.isPlaying) renderPeaks=\(afterStart)")
        expect(e.isRunning && !n.isPlaying && afterStart == ["0.0000", "0.0000"],
               "start() 之前 renderOffline 抛 com.apple.coreaudio.avfaudio/-80802（AVAudioEngine.h 的 AVAudioEngineManualRenderingErrorNotRunning），**不是**给你静音。但补上 start() 也不会自动补救：那句 play() 是在引擎没跑时叫的，已经作废，isPlaying 仍是 false、渲染仍是 0.0000 —— **得再 play() 一次**")
    } catch {
        let ns = error as NSError
        line("  start() 抛错：domain=\(ns.domain) code=\(ns.code)")
    }
    n.play()
    let revived = renderPeaks(e, blocks: 2, capacity: 512)
    line("  同一台引擎、同一个节点，再 play() 一次：isPlaying=\(n.isPlaying) renderPeaks=\(revived)")
    expect(revived[0] == "0.3536",
           "再叫一次 play() 就出数据了 —— 「全零」和「抛错」是两种完全不同的失败，修法也不同：抛错说明引擎没跑，全零说明播放器没 play 或队列没帧")
    // 第二层：引擎起来了，player 还没 play
    let (e2, n2) = makeOffline(512)
    scheduleSync(n2, sineBuf(512, hz: 440, amp: 0.5))
    let beforePlay = renderPeaks(e2, blocks: 2, capacity: 512)
    line("  第 2 层 isRunning=\(e2.isRunning) 但还没 play()：isPlaying=\(n2.isPlaying) renderPeaks=\(beforePlay)")
    expect(!n2.isPlaying && beforePlay == ["0.0000", "0.0000"],
           "引擎在跑、buffer 也排进去了，只差 play() —— 这次不抛错，直接给你 0.0000 的静音。headless 下这种失败最阴：一切都「正常」，只是没声音")
    n2.play()
    let p2 = renderPeaks(e2, blocks: 3, capacity: 512)
    line("  第 3 层 play() 之后：isPlaying=\(n2.isPlaying) renderPeaks=\(p2)")
    expect(p2[0] == "0.3536", "顺序摆正，第一个 512 帧块就是 0.3536（0.5 的源 × 1/√2）—— 刚才暂停时排进去的 buffer 还在队列里，play() 立刻把它吐出来")
    expect(p2[1] == "0.0000",
           "第二块回到 0.0000：源只有 512 帧，正好一块的量 —— **渲染块数 × capacity 必须 ≤ 你排进去的总帧数**才有得看，这不是 bug，是队列空了")
    // 正例对照：源给够两块
    let (e3, n3) = makeOffline(1024)
    scheduleSync(n3, sineBuf(2048, hz: 440, amp: 0.5))
    n3.play()
    let p3 = renderPeaks(e3, blocks: 3, capacity: 1024)
    line("  源换成 2048 帧、capacity 1024，渲染 3 块 peaks=\(p3)")
    expect(p3 == ["0.3536", "0.3536", "0.0000"],
           "2048 帧正好喂满两块，第三块归零：2048/1024=2 —— 拿这个对照能把「队列排了多少帧」和「渲染要了多少帧」这两件事彻底对上")
}

// ---- 15.6 mixer 的那一 3 dB ----
line("")
line("  -- 15.6 mainMixerNode 的 −3 dB：0.5 进去不是 0.5 出来 --")
do {
    let (e, n) = makeOffline(1024)
    scheduleSync(n, sineBuf(2048, hz: 440, amp: 1.0))
    n.play()
    let p = renderPeaks(e, blocks: 2, capacity: 1024)
    line("  源幅度 1.0000 → 渲染峰值 \(p)；1/√2 = \(f4(Double(1.0 / 2.0.squareRoot())))")
    expect(p == ["0.7071", "0.7071"],
           "outputVolume 明明还是默认的 1.0，出来却少了 3 dB —— 数据经过 mixer 的求和级就带上 1/√2，这是写断言前必须知道的固定系数")
    let (e1, n1) = makeOffline(1024)
    scheduleSync(n1, sineBuf(2048, hz: 440, amp: 0.5))
    n1.play()
    let p1 = renderPeaks(e1, blocks: 2, capacity: 1024)
    line("  源幅度 0.5000 → 渲染峰值 \(p1)（§1 那段 wav 生成时用的正是 0.5，所以本章几乎所有波形数字都以它为基准）")
    expect(p1 == ["0.3536", "0.3536"],
           "0.5 × 1/√2 = 0.35355…，四舍五入到第四位就是 0.3536 —— 后面所有峰值都要先除掉这个系数再和源幅度比对")
}

// ---- 15.7 outputVolume 是线性乘法 ----
line("")
line("  -- 15.7 mainMixerNode.outputVolume：线性增益，不是 dB --")
line("  先看「设得早晚」：同一个值，在 start() 之前设和之后设，第一个渲染块不一样")
for vol in [1.0, 0.25, 0.0] {
    let e = AVAudioEngine()
    try? e.enableManualRenderingMode(.offline, format: stereoNI, maximumFrameCount: 1024)
    let n = AVAudioPlayerNode()
    e.attach(n); e.connect(n, to: e.mainMixerNode, format: monoF)
    e.mainMixerNode.outputVolume = Float(vol)
    e.prepare()
    do { try e.start() } catch { line("  start 抛错") }
    scheduleSync(n, sineBuf(4096, hz: 440, amp: 1.0))
    n.play()
    let p = renderPeaks(e, blocks: 4, capacity: 1024)
    line("  start **之前**设 outputVolume=\(f4(vol)) → 4x1024 peaks=\(p)")
    if vol == 0.25 {
        expect(p == ["0.1768", "0.1768", "0.1768", "0.1768"],
               "0.25 就是乘 0.25：0.7071 × 0.25 = 0.1768，四块全一致 —— outputVolume 是**线性**的，不是 dB，想按 dB 调自己换算 pow(10, dB/20)")
    }
}
for vol in [1.0, 0.25, 0.0] {
    let (e, n) = makeOffline(1024)
    e.mainMixerNode.outputVolume = Float(vol)
    scheduleSync(n, sineBuf(4096, hz: 440, amp: 1.0))
    n.play()
    let p = renderPeaks(e, blocks: 4, capacity: 1024)
    line("  引擎已经跑着（makeOffline 里 start 过了）才设 outputVolume=\(f4(vol)) → 4x1024 peaks=\(p)")
    if vol == 0.0 {
        expect(p[0] == "0.6898" && p[1] == "0.0000",
               "运行中改音量，**第一个块是过渡值** 0.6898（不是原来的 0.7071，也不是目标 0.0000），从第二块起才落到目标 —— mixer 对参数做了斜坡以避免爆音。写单元测试时要么在 start 前设好，要么先丢掉一块再取数")
    }
}

// ---- 15.8 两路进 mixer：逐采样相加 ----
line("")
line("  -- 15.8 混音是「逐采样相加」：峰值既不是两路之和，也不是最大值 --")
do {
    let (e1, n1) = makeOffline(1024)
    scheduleSync(n1, sineBuf(2048, hz: 440, amp: 0.3))
    n1.play()
    let solo = renderPeaks(e1, blocks: 2, capacity: 1024)
    line("  单路 0.3 @440Hz → peaks=\(solo)（0.3 × 1/√2 = \(f4(0.3 / 2.0.squareRoot()))）")
    let (e2, n2) = makeOffline(1024)
    let n3 = AVAudioPlayerNode()
    e2.attach(n3)
    e2.connect(n3, to: e2.mainMixerNode, format: monoF)
    line("  attach 第二个 playerNode 之后 attachedNodes=\(e2.attachedNodes.count) types=\(e2.attachedNodes.map { String(describing: type(of: $0)) }.sorted())")
    line("  （注）这一行的四种类型是 mainMixer + outputNode + 两个 playerNode；没有 inputNode，因为这段代码从没读过 e.inputNode —— attachedNodes 记的是**已经被创建**的节点，15.1 那个 3 是读过那三个属性之后的结果。想知道图里有什么，别拿它的个数当准")
    scheduleSync(n2, sineBuf(2048, hz: 440, amp: 0.3))
    scheduleSync(n3, sineBuf(2048, hz: 880, amp: 0.3))
    n2.play(); n3.play()
    let mix = renderPeaks(e2, blocks: 2, capacity: 1024)
    line("  两路各 0.3（440Hz + 880Hz）→ peaks=\(mix)")
    expect(solo == ["0.2121", "0.2121"], "单路那一路的峰值就是 0.3/√2")
    expect(mix == ["0.3734", "0.3734"],
           "两路相加出来 0.3734：既不是 0.2121+0.2121=0.4242（两路不会在同一时刻同时到峰），也不是 0.2121（取最大）。sin(x)+sin(2x) 的数学极大值是 1.759 倍单路幅度，0.2121×1.759≈0.373，和实测对得上 —— **混音后的峰值由相位关系决定**，指望「两路音量各降一半就不失真」是错的")
    expect(Double(mix[0])! > Double(solo[0])! && Double(mix[0])! < 2 * Double(solo[0])!,
           "混音结果落在 (单路, 2×单路) 之间 —— 判断「有没有真的混进来」用这个区间最稳")
}

// ---- 15.9 定时起播：play(at:) 与 AVAudioTime 的两种时间 ----
line("")
line("  -- 15.9 把起播点排到未来：AVAudioTime(sampleTime:atRate:) --")
do {
    let t = AVAudioTime(sampleTime: 512, atRate: SR)
    line("  AVAudioTime(sampleTime: 512, atRate: 44100)：sampleTime=\(t.sampleTime) atRate=\(t.sampleRate) isSampleTimeValid=\(t.isSampleTimeValid) isHostTimeValid=\(t.isHostTimeValid)")
    expect(t.isSampleTimeValid && !t.isHostTimeValid,
           "这个构造器造出来的是**纯采样时刻**，没有 mach 绝对时间（isHostTimeValid=false）—— 离线渲染只认 sampleTime，正好配它")
    let (e, n) = makeOffline(512)
    scheduleSync(n, sineBuf(2048, hz: 440, amp: 0.5))
    n.play(at: t)
    let p = renderPeaks(e, blocks: 4, capacity: 512)
    line("  起播点设在第 512 帧，渲染 4x512 peaks=\(p)")
    expect(p == ["0.0000", "0.3536", "0.3536", "0.3536"],
           "第一块整块静音：引擎时钟从 0 走到 512 时数据还没被放行，从第二块起才逐块吐 0.3536 —— 「定时起播」在离线渲染里就是一块可复现的空白，真机上这块空白就是你听到的开头延迟")
    let opts: [(String, AVAudioPlayerNodeBufferOptions)] = [("loops", .loops), ("interrupts", .interrupts), ("interruptsAtLoop", .interruptsAtLoop)]
    line("  AVAudioPlayerNodeBufferOptions 原始值：" + opts.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))
    expect(AVAudioPlayerNodeBufferOptions.loops.rawValue == 1 && AVAudioPlayerNodeBufferOptions.interrupts.rawValue == 2,
           "[]（空集合，普通播放）→1 loops →2 interrupts（高优先级抢占）→4 interruptsAtLoop（在循环点抢占）；传 [] 就是不循环、不打断")
}

// ---- 15.10 loops：队列循环 ----
line("")
line("  -- 15.10 options: .loops —— 一块 buffer 变成长流 --")
do {
    let (e1, n1) = makeOffline(512)
    scheduleSync(n1, sineBuf(512, hz: 440, amp: 0.5))
    n1.play()
    let plain = renderPeaks(e1, blocks: 4, capacity: 512)
    line("  不循环：4x512 peaks=\(plain)")
    let (e2, n2) = makeOffline(512)
    scheduleSync(n2, sineBuf(512, hz: 440, amp: 0.5), options: .loops)
    n2.play()
    let looped = renderPeaks(e2, blocks: 6, capacity: 512)
    line("  .loops：6x512 peaks=\(looped) 渲染之后 isPlaying=\(n2.isPlaying) sampleTime=\(e2.manualRenderingSampleTime)")
    expect(plain[0] == "0.3536" && plain[1] == "0.0000", "普通模式：一块 512 帧的 buffer 只够一块输出")
    expect(looped.allSatisfy { $0 == "0.3536" },
           ".loops 让同一个 buffer 反复回放：6 块全是 0.3536，样本号一路推进（\(e2.manualRenderingSampleTime)=6×512），却不需要你再排任何数据 —— 循环发生在**播放器队列**层，不在 mixer 层")
    n2.reset()
    let afterResetWhilePlaying = n2.isPlaying
    let afterResetPeaks = renderPeaks(e2, blocks: 1, capacity: 512)
    line("  reset() 之后**当场**读 isPlaying=\(afterResetWhilePlaying)，再渲染 1 块 peaks=\(afterResetPeaks)")
    expect(afterResetWhilePlaying && afterResetPeaks == ["0.0000"],
           "reset() 只清数据队列，**不动播放意图**：正在 .loops 的播放器 reset 之后 isPlaying 照样 true，只是再没东西可吐。对比 15.11 的 C 组（先 pause 再 reset 才读到 false）—— isPlaying 反映的是 play/pause/stop 这层，别拿它判断队列空不空")
}

// ---- 15.11 play / pause / reset / stop 的真实语义 ----
line("")
line("  -- 15.11 四个控制调用的差别，用三段直流 buffer 逐个照出来 --")
do {
    // 直流（常数）buffer：每一块峰值就是那一帧的幅度 × 1/√2，最容易被眼睛核对
    let (e, n) = makeOffline(512)
    scheduleSync(n, dcBuf(512, 0.5))
    scheduleSync(n, dcBuf(512, 0.25))
    scheduleSync(n, dcBuf(512, 0.125))
    let forget = renderPeaks(e, blocks: 3, capacity: 512)
    line("  A) 排三段、**忘记 play()**：isPlaying=\(n.isPlaying) peaks=\(forget)")
    expect(!n.isPlaying && forget == ["0.0000", "0.0000", "0.0000"],
           "全静音且没有任何报错 —— 这是最常见的「我的音频怎么没声」根因，play() 不是可选步骤")
    n.play()
    let resume = renderPeaks(e, blocks: 3, capacity: 512)
    line("  A) 补上 play()：isPlaying=\(n.isPlaying) peaks=\(resume)")
    expect(resume == ["0.3536", "0.1768", "0.0884"],
           "补 play() 之后从头把队列吐出来，三段幅度 0.5/0.25/0.125 × 1/√2 = 0.3536/0.1768/0.0884，一帧不差 —— 数据没丢，只是之前没人推它")
    let (e2, n2) = makeOffline(512)
    scheduleSync(n2, dcBuf(512, 0.5))
    scheduleSync(n2, dcBuf(512, 0.25))
    scheduleSync(n2, dcBuf(512, 0.125))
    n2.play()
    let beforePause = renderPeaks(e2, blocks: 2, capacity: 512)
    n2.pause()
    let pausedFlag = n2.isPlaying
    let duringPause = renderPeaks(e2, blocks: 2, capacity: 512)
    n2.play()
    let afterResume = renderPeaks(e2, blocks: 2, capacity: 512)
    line("  B) pause：播 2 块=\(beforePause) → pause() 当场读 isPlaying=\(pausedFlag)，再渲染 2 块=\(duringPause) → 再 play() 2 块=\(afterResume)")
    expect(duringPause == ["0.0000", "0.0000"] && !pausedFlag,
           "pause() 之后 isPlaying=false，渲染继续要帧只会拿到静音 —— 引擎的时钟不会替你把数据攒着")
    expect(afterResume[0] == "0.0884",
           "再 play() 从**暂停处**接着走：第三段 0.125×1/√2=0.0884 正好接上，说明 pause 保住了队列里的播放位置（和 reset/stop 的关键区别）")
    let (e3, n3) = makeOffline(512)
    scheduleSync(n3, dcBuf(512, 0.5))
    scheduleSync(n3, dcBuf(512, 0.25))
    n3.play()
    _ = renderPeaks(e3, blocks: 1, capacity: 512)
    n3.pause()
    n3.reset()
    let resetFlag = n3.isPlaying
    n3.play()
    let afterReset = renderPeaks(e3, blocks: 2, capacity: 512)
    line("  C) pause() → reset() 当场读 isPlaying=\(resetFlag) → play() → 渲染 2 块 peaks=\(afterReset)")
    expect(!resetFlag, "先 pause() 再 reset()：isPlaying 停在 pause 留下的 false（reset 不改它，见 15.10）—— 两个调用合起来才是「彻底归位」")
    expect(afterReset == ["0.0000", "0.0000"],
           "reset() 把**没播完的队列整段丢掉**：即使再 play() 也没有数据可吐，只剩静音 —— 想播回去得重新 schedule")
    let (e4, n4) = makeOffline(512)
    scheduleSync(n4, dcBuf(512, 0.5))
    n4.play()
    n4.stop()
    let stopFlag = n4.isPlaying
    let afterStop = renderPeaks(e4, blocks: 2, capacity: 512)
    n4.play()
    let stopThenPlay = renderPeaks(e4, blocks: 2, capacity: 512)
    line("  D) play() 之后立刻 stop()：当场读 isPlaying=\(stopFlag)，渲染 2 块 peaks=\(afterStop) → 再 play() 渲染 2 块 peaks=\(stopThenPlay)")
    expect(!stopFlag && afterStop == ["0.0000", "0.0000"] && stopThenPlay == ["0.0000", "0.0000"],
           "stop() = 清队列 + 停播放器，而且不像 pause 那样留位置：再 play() 也是空的。要「停止后从头播」必须 stop() → 重新 schedule → play()")
    let drainedPlaying = n.isPlaying
    line("  E) A 组那个队列已经吐完的播放器：isPlaying 读回来=\(drainedPlaying)")
    expect(drainedPlaying,
           "帧全吐光了 isPlaying 还是 true —— 它表示「播放器处于播放意图」，不表示「还有数据」。用 isPlaying 判断播没播完是错的，得盯 manualRenderingSampleTime 或者 completion 回调")
}

// ---- 15.12 三种 completion 时机 ----
line("")
line("  -- 15.12 completionCallbackType：离线渲染永远等不到 .dataPlayedBack --")
do {
    let types: [(String, AVAudioPlayerNodeCompletionCallbackType)] = [
        ("dataConsumed", .dataConsumed), ("dataRendered", .dataRendered), ("dataPlayedBack", .dataPlayedBack),
    ]
    line("  AVAudioPlayerNodeCompletionCallbackType 原始值：" + types.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))
    for (label, kind) in types {
        let (e, n) = makeOffline(512)
        let arrived = DispatchSemaphore(value: 0)
        let box = CBBox()
        scheduleSync(n, dcBuf(512, 0.5), callbackType: kind) { t in
            box.add("\(label) type=\(t.rawValue)")
            arrived.signal()
        }
        n.play()
        _ = renderPeaks(e, blocks: 3, capacity: 512)
        let got = waitBriefly(arrived, 1.5)
        line("  \(label)：渲染 3 块之后回调到达=\(got) 记录=\(box.log())")
        if kind == .dataPlayedBack {
            expect(!got, "\(label) 在离线渲染下**永远不来**：.dataPlayedBack 的含义是「声音真的从输出设备放出去了」，而手动模式根本没有设备。真机上能等到、测试里等不到的回调，就是这一类")
        } else {
            expect(got && box.log() == ["\(label) type=\(kind.rawValue)"],
                   "\(label) 能被 renderOffline 触发，回调参数原样带回落\(kind.rawValue)（dataConsumed=0 表示「引擎把 buffer 从队列拿走了」，dataRendered=1 表示「已经算进输出」）—— 想在无设备环境下测「播完」，只有这两个可选")
        }
    }
}

// ---- 15.13 scheduleFile / scheduleSegment：直接从文件排，不经手 buffer ----
line("")
line("  -- 15.13 让播放器自己去读 AVAudioFile --")
let shortURL = try writeTone("24-short.wav", seconds: 0.1, channels: 1, hz: 440, amp: 0.5)
let shortFile = try AVAudioFile(forReading: shortURL)
line("  shortFile.length=\(shortFile.length) 帧（0.1 秒 × 44100）fileFormat \(fmt(shortFile.fileFormat)) processingFormat \(fmt(shortFile.processingFormat))")
expect(shortFile.fileFormat.isInterleaved && !shortFile.processingFormat.isInterleaved,
       "lpcm 文件在磁盘上是**交织**的（fileFormat.interleaved=true），AVAudioFile 读出来给你的是非交织的 processingFormat —— 15.4 那套索引规则只对 processingFormat 成立")
do {
    let (e, n) = makeOffline(1024)
    scheduleFileSync(n, shortFile)
    n.play()
    let p = renderPeaks(e, blocks: 6, capacity: 1024)
    line("  scheduleFile 整段：渲染 6x1024 peaks=\(p) manualRenderingSampleTime=\(e.manualRenderingSampleTime)")
    expect(p.prefix(5).allSatisfy { $0 == "0.3536" } && p[5] == "0.0000",
           "4410 帧 ÷ 1024 = 4.3 块，实测 5 块有声、第 6 块归零：最后一块虽然不满，正弦的峰仍然落在里面。**scheduleFile 不要求文件长度是渲染块的整数倍**")
}
do {
    let (e, n) = makeOffline(1024)
    scheduleFileSync(n, shortFile, startingFrame: 1102, frameCount: 1024)
    n.play()
    let p = renderPeaks(e, blocks: 3, capacity: 1024)
    line("  scheduleSegment(startingFrame: 1102, frameCount: 1024)：渲染 3x1024 peaks=\(p)")
    expect(p == ["0.3536", "0.0000", "0.0000"],
           "只排 1024 帧就只有一块输出：startingFrame 是**文件里的帧号**，不是时间；1024 帧 ÷ capacity 1024 = 正好一块")
}
do {
    let (e, n) = makeOffline(1024)
    scheduleFileSync(n, shortFile, startingFrame: 4000, frameCount: 5000)
    n.play()
    let p = renderPeaks(e, blocks: 4, capacity: 1024)
    line("  scheduleSegment(4000, 请求 5000 帧) 而文件只有 \(shortFile.length) 帧：渲染 4x1024 peaks=\(p)")
    expect(p == ["0.3536", "0.0000", "0.0000", "0.0000"],
           "请求 5000 帧但 4000 之后只剩 \(shortFile.length - 4000) 帧可读：**不抛错、不裁剪、也不告诉你少读了** —— 第一块里那 410 帧照常出声（\(p[0])），后面三块是静音。区间合法性只能自己校验 startingFrame + frameCount ≤ length，别指望 API 报错")
}
do {
    shortFile.framePosition = 3
    let b = AVAudioPCMBuffer(pcmFormat: shortFile.processingFormat, frameCapacity: 8)!
    do {
        try shortFile.read(into: b)
        let head = (0..<8).map { f4(Double(b.floatChannelData![0][$0])) }
        line("  把 framePosition 设成 3 之后 read(8)：frameLength=\(b.frameLength) 采样=\(head) 读完 framePosition=\(shortFile.framePosition)")
        let theory = 0.5 * sin(2 * .pi * 440 * 3.0 / SR)
        expect(f4(Double(b.floatChannelData![0][0])) == f4(theory),
               "framePosition 就是「下一次 read 从哪一帧开始」，设成 3 读出来的第一个采样正是理论值 \(f4(theory))（0.5·sin(2π·440·3/44100)）—— §1 那个「read 到 EOF 抛错」也是同一根游标，**读之前**就能改起点，不用重开文件")
        expect(shortFile.framePosition == 11 && b.frameLength == 8,
               "读完游标自动前进 8（3 → \(shortFile.framePosition)）：AVAudioFile 是有状态的，同一个实例读第二次就是接着往下读")
    } catch { let ns = error as NSError; line("  read 抛错：domain=\(ns.domain) code=\(ns.code)") }
    shortFile.framePosition = shortFile.length
    do {
        let b2 = AVAudioPCMBuffer(pcmFormat: shortFile.processingFormat, frameCapacity: 8)!
        try shortFile.read(into: b2)
        line("  游标停在文件尾再 read：居然没抛错，frameLength=\(b2.frameLength)")
    } catch {
        let ns = error as NSError
        line("  游标停在文件尾再 read 抛错：type=\(type(of: error)) domain=\(ns.domain) code=\(ns.code)")
        expect(ns.domain == "Foundation._GenericObjCError",
               "和 §1 一致：AVAudioFile 的 EOF 是 Objective-C 的 BOOL 失败映射成 Swift 错误，域是 Foundation._GenericObjCError、code=0 —— **拿 code 判断错误类型在这里没意义**，只能靠 domain 加「读到尾」这个上下文")
    }
}
// 句柄没撒手时，scheduleFile 拿到的是空文件（§2 那个坑在引擎这条路上一模一样）
var heldEngineWriter: AVAudioFile? = nil
let heldEngineURL = tmp("24-held-engine.wav")
try? FileManager.default.removeItem(at: heldEngineURL)
do {
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: SR, AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true,
    ]
    let w = try AVAudioFile(forWriting: heldEngineURL, settings: settings,
                            commonFormat: .pcmFormatFloat32, interleaved: false)
    try w.write(from: sineBuf(4410, hz: 440, amp: 0.5))
    heldEngineWriter = w
    line("  写入器还攥在手里：heldWriter.length=\(heldEngineWriter?.length.description ?? "nil")（写了 4410 帧，头部还没回填所以读到的不是 4410）")
}
do {
    let opener = try AVAudioFile(forReading: heldEngineURL)
    let (e, n) = makeOffline(1024)
    scheduleFileSync(n, opener)
    n.play()
    let p = renderPeaks(e, blocks: 2, capacity: 1024)
    line("  同一时刻另开一个 AVAudioFile(forReading:)：length=\(opener.length) → scheduleFile 渲染 2x1024 peaks=\(p)")
    expect(opener.length == 0 && p == ["0.0000", "0.0000"],
           "§2 那个坑在引擎这条路上原样复现：wav 头还没落盘 → 读侧 length=0 → scheduleFile 排进去的就是空区间 → 全程静音，**一个错误都没有**")
}
heldEngineWriter = nil
do {
    let opener = try AVAudioFile(forReading: heldEngineURL)
    let (e, n) = makeOffline(1024)
    scheduleFileSync(n, opener)
    n.play()
    let p = renderPeaks(e, blocks: 4, capacity: 1024)
    line("  撒手（heldEngineWriter = nil）之后重开：length=\(opener.length) → 渲染 4x1024 peaks=\(p)")
    expect(opener.length == 4410 && p == ["0.3536", "0.3536", "0.3536", "0.3536"],
           "只是把写入器释放掉，同一个 URL 立刻读出 4410 帧并渲染出满峰值 —— **引擎不背这个锅，是文件自己还没写完**")
}

// ---- 15.14 退出手动模式：状态会整体回滚 ----
line("")
line("  -- 15.14 disableManualRenderingMode() 之后，图回到「真实设备」那一套 --")
do {
    let (e, n) = makeOffline(512)
    scheduleSync(n, dcBuf(512, 0.5))
    n.play()
    _ = renderPeaks(e, blocks: 1, capacity: 512)
    line("  disable 之前：isInManualRenderingMode=\(e.isInManualRenderingMode) isRunning=\(e.isRunning)")
    e.disableManualRenderingMode()
    let mf = e.manualRenderingFormat
    line("  disable 之后：isInManualRenderingMode=\(e.isInManualRenderingMode) isRunning=\(e.isRunning) manualRenderingFormat=\(fmt(mf)) maxFrameCount=\(e.manualRenderingMaximumFrameCount) sampleTime=\(e.manualRenderingSampleTime)")
    expect(!e.isInManualRenderingMode && !e.isRunning,
           "disable 顺手把引擎**停了**（isRunning=false）：手动模式和自动模式是互斥的两套时钟，切回去必须先 stop")
    expect(e.manualRenderingMaximumFrameCount == 0 && mf.channelCount == 0,
           "manualRenderingFormat 变成 ch=0 sr=0 的空壳、maxFrameCount 归 0：这两个属性只在手动模式下有意义，退出后读它们只会拿到占位值")
    do {
        let b = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: 512)!
        _ = try e.renderOffline(512, to: b)
        line("  退出手动模式之后 renderOffline 居然成功了")
    } catch {
        let ns = error as NSError
        line("  退出手动模式之后 renderOffline 抛错：domain=\(ns.domain) code=\(ns.code)")
        expect(ns.code == -80800, "com.apple.coreaudio.avfaudio/-80800 = AVAudioEngine.h 里的 AVAudioEngineManualRenderingErrorInvalidMode —— 和 15.5 的 -80802(NotRunning) 是**两个不同的原因**：一个是模式不对，一个是引擎没跑")
    }
    line("  inputNode.outputFormat(forBus:0) 回到 \(fmt(e.inputNode.outputFormat(forBus: 0))) —— 又变回设备格式（15.1 那个 sr=0 的硬件输入）")
    expect(e.inputNode.outputFormat(forBus: 0).sampleRate == 0 && e.inputNode.outputFormat(forBus: 0).isInterleaved,
           "退出手动模式把 inputNode 的格式也一并还原：这条路上「格式」从来不是你能定的，是设备给的")
    do {
        try e.start()
        line("  disable 之后再 start()：isRunning=\(e.isRunning)")
        n.play()
        line("  再 play()：isPlaying=\(n.isPlaying)（此时图接的是不存在的真实输出，数据出不去，但调用全部合法）")
        expect(e.isRunning, "同一台引擎可以从手动模式切回普通模式并再次 start() —— 不需要重建")
    } catch {
        let ns = error as NSError
        line("  disable 之后 start() 抛错：domain=\(ns.domain) code=\(ns.code)")
    }
    let before = e.attachedNodes.count
    e.detach(n)
    let after = e.attachedNodes.count
    line("  detach(\(type(of: n)))：attachedNodes \(before) → \(after)，节点反查自己的 engine=\(n.engine == nil ? "nil" : "还在")")
    expect(after == before - 1 && n.engine == nil,
           "方法名是 **detach**，AVAudioEngine 上没有 remove(_:)，别按名字猜。detach 之后节点自己反查 engine 就是 nil —— 这是「节点真的被摘掉了」的可靠信号。（这里没有先 disconnect 就 detach，探针实测不崩；正规顺序还是先 disconnect 再 detach，两个调用各管一件事：连线归 disconnect，节点归 detach。）")
}

// ============================================================ 16
line("")
line("== 16) 效果器与 AVAudioConverter —— 把「听上去怎样」变成一列数字 ==")
line("  效果器（AVAudioUnit 家族）也是引擎图里的节点，所以 15 章那套离线渲染照样能把它们")
line("  逐个照清楚：一块正弦进去，几块峰值出来，不靠耳朵。")
line("  这一节还有一个主题：**参数是存起来的，不是校验过的**。越界的值照样读得回来，")
line("  坏的结果出现在渲染出来的数字里，而不是一句报错。")

/// playerNode → 效果单元 → mainMixer 的三节点离线图（15 章的 makeOffline 少了一级）
/// 两处连线的 format 都给 monoF：图里跑的仍是单声道，展开成立体声是 mainMixer 的事
func makeOfflineFX(_ unit: AVAudioUnit, maxFrames: AVAudioFrameCount = 512) -> (AVAudioEngine, AVAudioPlayerNode) {
    let e = AVAudioEngine()
    do { try e.enableManualRenderingMode(.offline, format: stereoNI, maximumFrameCount: maxFrames) }
    catch { let ns = error as NSError; line("  enableManualRenderingMode 抛错：\(ns.domain)/\(ns.code)") }
    let n = AVAudioPlayerNode()
    e.attach(n)
    e.attach(unit)
    e.connect(n, to: unit, format: monoF)
    e.connect(unit, to: e.mainMixerNode, format: monoF)
    e.prepare()
    do { try e.start() } catch { let ns = error as NSError; line("  start() 抛错：\(ns.domain)/\(ns.code)") }
    return (e, n)
}
/// 一问一答：源默认 1024 帧 / 440Hz / 幅度 0.5 的正弦，渲染 blocks 块（每块 512 帧）的峰值
func fxPeaks(_ unit: AVAudioUnit, blocks: Int, frames: Int = 1024) -> [String] {
    let (e, n) = makeOfflineFX(unit)
    scheduleSync(n, sineBuf(frames, hz: 440, amp: 0.5))
    n.play()
    return renderPeaks(e, blocks: blocks, capacity: 512)
}
/// delay 的四参数一次性配好（lowPassCutoff 固定 15000，即出厂值，避免它掺进对比结果）
func delayUnit(delayTime: Double = 0, feedback: Double = 0, wet: Double = 50) -> AVAudioUnitDelay {
    let d = AVAudioUnitDelay()
    d.delayTime = delayTime; d.feedback = Float(feedback)
    d.wetDryMix = Float(wet); d.lowPassCutoff = 15000
    return d
}
/// EQ：先给几条 band，再在闭包里逐条配；闭包参数是整台单元，所以 globalGain/bypass 也能配
func eqUnit(bands: Int = 1, _ cfg: (AVAudioUnitEQ) -> Void = { _ in }) -> AVAudioUnitEQ {
    let q = AVAudioUnitEQ(numberOfBands: bands)
    cfg(q)
    return q
}

// ---- 16.1 五个内置效果单元的出厂值 ----
line("")
line("  -- 16.1 五个内置效果单元的出厂值 --")
do {
    let eq = AVAudioUnitEQ()
    let eq3 = AVAudioUnitEQ(numberOfBands: 3)
    let b0 = eq3.bands[0]
    line("  AVAudioUnitEQ() 无参构造：bands=\(eq.bands.count) globalGain=\(f4(Double(eq.globalGain))) bypass=\(eq.bypass)")
    line("  AVAudioUnitEQ(numberOfBands:3)：bands=\(eq3.bands.count)，bands[0] 和 bands[1] 是同一个对象=\(eq3.bands[1] === b0)")
    line("  band 出厂值：filterType=\(b0.filterType.rawValue) bypass=\(b0.bypass) frequency=\(f4(Double(b0.frequency))) gain=\(f4(Double(b0.gain))) bandwidth=\(f4(Double(b0.bandwidth)))")
    let d = AVAudioUnitDelay()
    line("  AVAudioUnitDelay：delayTime=\(f4(Double(d.delayTime))) wetDryMix=\(f4(Double(d.wetDryMix))) feedback=\(f4(Double(d.feedback))) lowPassCutoff=\(f4(Double(d.lowPassCutoff)))")
    let r = AVAudioUnitReverb()
    line("  AVAudioUnitReverb：wetDryMix=\(f4(Double(r.wetDryMix))) bypass=\(r.bypass)")
    let v = AVAudioUnitVarispeed()
    line("  AVAudioUnitVarispeed：rate=\(f4(Double(v.rate)))")
    let t = AVAudioUnitTimePitch()
    line("  AVAudioUnitTimePitch：rate=\(f4(Double(t.rate))) pitch=\(f4(Double(t.pitch))) overlap=\(f4(Double(t.overlap)))")
    line("  实际类型名：\(type(of: eq)) / \(type(of: d)) / \(type(of: r)) / \(type(of: v)) / \(type(of: t))")
    expect(eq.bands.count == 16 && eq3.bands.count == 3,
           "无参的 AVAudioUnitEQ() 给 **16 条频段**（默认不是 1 条），要几条就写 numberOfBands: —— 别指望数组越界替你兜住，16 条足够你把默认值当 1 条用")
    expect(b0.bypass && b0.frequency == 40 && b0.bandwidth == 0.5,
           "band 出厂就是 bypass=true，频点 40Hz、带宽 0.5 个倍频程：新建 EQ 挂上去声音一点没变。要生效必须**逐条** bypass=false，只设 frequency/gain 是不够的（16.4 用数字证明）")
    expect(r.wetDryMix == 0.5 && d.wetDryMix == 50,
           "两个单元的 wetDryMix 默认值差一百倍：reverb 是 0.5、delay 是 50（单位都是百分比，0=全干、100=全湿）。reverb 那个 0.5 等于「湿声只占半个百分点」，16.5 会看到它有多没存在感")
}
line("  EQ 的九种滤波器类型（AVAudioUnitEQFilterType 的 rawValue）：")
for (name, ft) in [("parametric", AVAudioUnitEQFilterType.parametric), ("lowPass", .lowPass), ("highPass", .highPass),
                   ("resonantLowPass", .resonantLowPass), ("resonantHighPass", .resonantHighPass),
                   ("bandPass", .bandPass), ("bandStop", .bandStop), ("lowShelf", .lowShelf), ("highShelf", .highShelf)] {
    line("    \(name) = \(ft.rawValue)")
}
line("  混响预置（AVAudioUnitReverbPreset）挑五个：")
for (name, pr) in [("smallRoom", AVAudioUnitReverbPreset.smallRoom), ("mediumHall", .mediumHall),
                   ("plate", .plate), ("cathedral", .cathedral), ("largeHall2", .largeHall2)] {
    line("    \(name) = \(pr.rawValue)")
}
line("  （注）本节写之前拿 swiftc 逐个试过名，下面这些**在 iPhoneSimulator18.2.sdk 里不存在**，")
line("        编译器原文各引一句（都是 error: …）：")
line("        value of type 'AVAudioUnitDelay' has no member 'maxDelayTime' —— 延迟上限不由这个属性给")
line("        type 'AVAudioUnitEQFilterType' has no member 'notch' —— 要陷波用 bandStop")
line("        value of type 'AVAudioUnitReverb' has no member 'componentDescription'")
line("        type 'AVAudioUnitReverbPreset' has no member 'largeChurch' —— 预置只到 largeHall2=12")
line("        value of type 'AVAudioConverter' has no member 'sampleRateConverterComplexity'")
line("        cannot find 'AVAudioConverterQuality' in scope —— 16.8 会看到质量参数其实是个裸 Int")
line("      网上教程里这些名字出镜率很高，那是旧 SDK 或者别的框架。补全会顺着旧文档提示你，编译器不会。")

// ---- 16.2 wetDryMix 是等功率混合，不是线性相加 ----
line("")
line("  -- 16.2 wetDryMix：干湿各 50% 时，峰值反而比纯干声大 --")
do {
    let p0 = fxPeaks(delayUnit(wet: 0), blocks: 2)
    let p50 = fxPeaks(delayUnit(wet: 50), blocks: 2)
    let p100 = fxPeaks(delayUnit(wet: 100), blocks: 2)
    line("  delayTime=0 feedback=0 wet=0 → \(p0)")
    line("  delayTime=0 feedback=0 wet=50 → \(p50)")
    line("  delayTime=0 feedback=0 wet=100 → \(p100)")
    let ratio = 0.4935 / 0.3536
    line("  wet=50 / wet=0 = 0.4935/0.3536 = \(f4(ratio))，而 √2 = \(f4(Double(2).squareRoot()))")
    expect(p0 == ["0.3536", "0.3536"],
           "wet=0 就是纯干声，回到 15.6 的基准 0.3536（幅度 0.5 的正弦 −3 dB）")
    expect(p50 == ["0.4935", "0.4935"] && p100 == ["0.3534", "0.3534"],
           "**delayTime=0 时干路和湿路是同一份信号**，各乘 √0.5≈0.7071 再相加 → 0.3536×√2=0.4935；wet=100 全走湿路，等于把干声乘回 0.7071，于是 0.3534 又贴回基准。中间那个点比两端都响，是**等功率交叉淡入淡出**的形状，不是「50% 就是平均」的直线。做「淡出干声」这种效果时，走到 wet=50 附近整体会鼓起来 3 dB")
}

// ---- 16.3 delay：把回声对齐到渲染块上，就数得出它落在第几块 ----
line("")
line("  -- 16.3 delay：一块 = 512 帧 = 11.610 ms，delayTime 给到这个数就能对上 --")
do {
    line("  512/44100*1000 = \(f4(512.0 / SR * 1000)) ms —— 手动模式的最大块就是「一格」的长度")
    let rows: [(Double, Double, Double)] = [(0.0, 0.0, 50.0), (0.011610, 0.0, 50.0), (0.011610, 0.5, 50.0),
                                            (0.023220, 0.5, 50.0), (0.011610, 0.9, 50.0),
                                            (0.011610, 0.0, 100.0), (0.011610, 0.0, 0.0)]
    var got: [[String]] = []
    for row in rows {
        let p = fxPeaks(delayUnit(delayTime: row.0, feedback: row.1, wet: row.2), blocks: 6)
        got.append(p)
        line("  delayTime=\(f4(row.0)) feedback=\(f4(row.1)) wet=\(f4(row.2)) → 6x512 peaks=\(p)")
    }
    line("  （源 1024 帧恰好两块，所以干声只出现在第 1、2 块，第 3 块起只剩尾巴）")
    expect(got[0] == ["0.4935", "0.4935", "0.2402", "0.0000", "0.0000", "0.0000"],
           "delayTime=0 的第一行：干湿重叠在前两块（0.4935），第 3 块 0.2402 是源尾部的交叉淡化，之后全零 —— 这就是 wet=50 的「底片」，下面几行都跟它对照")
    expect(got[1] == ["0.2500", "0.4650", "0.2499", "0.2402", "0.0000", "0.0000"],
           "delayTime=0.011610（正好一块）之后，第 1 块掉到 0.2500（它被拆成干湿各半，只剩 0.3536×0.7071），第 2 块 0.4650 = 第 1 块的回声撞上第 2 块的干声。回声确实**晚一块**出现，用峰值就能数出来")
    expect(got[2] == ["0.2500", "0.4650", "0.2508", "0.2408", "0.0012", "0.0000"] &&
           got[4] == ["0.2500", "0.4650", "0.2516", "0.2414", "0.0022", "0.0000"],
           "feedback=0.5 时第 5 块冒出 0.0012，feedback=0.9 时同一块是 0.0022：反馈量决定**回声自己再被回放几次**。0.9 的尾比 0.5 长一倍，但绝对值已经掉到千分位，听感上是「尾巴变长」而不是「变响」")
    expect(got[3] == ["0.2500", "0.2500", "0.2499", "0.2499", "0.2402", "0.0012"],
           "delayTime=0.023220（两块）时第 2 块回到 0.2500、回声挪到第 3 块之后：delayTime 每多一块，整列数字就往右挪一格。想对齐到块就把 delayTime 写成帧数/44100")
    expect(got[5][0] == "0.0000" && got[5][1] == "0.3534",
           "wet=100（全湿）的第 1 块是 0.0000：干声被完全关掉，而回声要等 delayTime 到点才有内容 —— 「第一块静音」是 wet=100 的正常形状，不是 bug")
    expect(got[6] == ["0.3536", "0.3536", "0.0000", "0.0000", "0.0000", "0.0000"],
           "wet=0（全干）与 16.2 的 wet=0 逐字节相同，delayTime 有没有都无所谓：湿路不参与的图，参数只是摆着")
}
do {
    let d = AVAudioUnitDelay()
    d.delayTime = 10
    let (e, _) = makeOfflineFX(d)
    line("  delayTime=10 赋完读回=\(f4(Double(d.delayTime)))，引擎 start 得住吗：isRunning=\(e.isRunning)")
    expect(d.delayTime == 10,
           "delayTime 的单位是**秒**（属性上没有任何提示），写 10 就是十秒回声，既不报错也不夹取。要按毫秒设得自己除 1000：0.011610 才是一块")
}

// ---- 16.4 EQ：band 要 bypass=false 才说话，+12 dB 会把峰值顶过 1.0 ----
line("")
line("  -- 16.4 EQ：默认全旁通；生效后 +12 dB 直接越过 1.0 --")
do {
    let pDefault = fxPeaks(eqUnit(), blocks: 3, frames: 1536)
    line("  1 条 band、出厂 bypass=true → \(pDefault)")
    expect(pDefault == ["0.3536", "0.3536", "0.3536"],
           "没动 band 的 EQ 就是根导线：和 16.2 的 wet=0 一模一样")

    let pZero = fxPeaks(eqUnit { $0.bands[0].filterType = .parametric; $0.bands[0].frequency = 440; $0.bands[0].gain = 0; $0.bands[0].bypass = false },
                        blocks: 3, frames: 1536)
    line("  parametric 440Hz gain=0 bypass=false → \(pZero)")
    expect(pZero == ["0.3536", "0.3536", "0.3536"],
           "把 band 打开但增益给 0 dB：数字仍然纹丝不动。gain 是**相对量**，0 就是「这条频点上不加不减」")

    let pBoost = fxPeaks(eqUnit { $0.bands[0].filterType = .parametric; $0.bands[0].frequency = 440; $0.bands[0].gain = 12; $0.bands[0].bypass = false },
                         blocks: 3, frames: 1536)
    line("  parametric 440Hz gain=+12dB bypass=false → \(pBoost)")
    expect(pBoost == ["1.3298", "1.4025", "1.4070"],
           "+12 dB 把 0.3536 顶到 1.4070 —— 峰值**超过 1.0**。Float32 的图不会自己削波（数字照样如实给你 1.4070，第一块 1.3298 是滤波器还在建立响应），但下一步写进 16 bit 文件、或者交给真实输出设备就是一段削顶。先降源电平，再给 EQ 增益")

    let pLP = fxPeaks(eqUnit { $0.bands[0].filterType = .lowPass; $0.bands[0].frequency = 200; $0.bands[0].bypass = false },
                      blocks: 3, frames: 1536)
    line("  lowPass 200Hz，源是 440Hz → \(pLP)")
    expect(pLP[1] == "0.0715" && pLP[2] == "0.0715",
           "440Hz 的正弦被 200Hz 低通压到 0.0715（不到原峰值的 1/4，第一块 0.1345 是过渡段）：类型是**每条 band 各有一个** filterType，不是整台单元一个")

    let pGlobal = fxPeaks(eqUnit(bands: 3) { $0.globalGain = 6 }, blocks: 2)
    line("  三条 band 全旁通 + globalGain=6 → \(pGlobal)")
    expect(pGlobal == ["0.7054", "0.7054"],
           "globalGain 是整台单元的增益，和 band 旁不旁通无关：+6 dB → 0.3536×1.995=0.7054（6 dB 理论是 ×2，AudioUnit 的增益曲线在满量程附近差一点点）。只想「整体响一点、别的都不动」就用它，别逐条加 gain")

    let pBypass = fxPeaks(eqUnit { $0.bypass = true; $0.bands[0].filterType = .lowPass; $0.bands[0].frequency = 200; $0.bands[0].bypass = false },
                          blocks: 3, frames: 1536)
    line("  整台单元 bypass=true（band 自己 bypass=false）→ \(pBypass)")
    expect(pBypass == ["0.3536", "0.3536", "0.3536"],
           "两级开关同时存在时**单元级 bypass 赢**：band 配得再细，只要 AVAudioUnitEQ.bypass=true 就整台旁通。做「效果开/关」对比只该动这一个，别去逐条翻 band")
}

// ---- 16.5 reverb：预置只改内部参数，干湿比得你自己设 ----
line("")
line("  -- 16.5 reverb：loadFactoryPreset 不动 wetDryMix --")
do {
    let fresh = AVAudioUnitReverb()
    line("  新建、一个预置都没加载：wetDryMix=\(f4(Double(fresh.wetDryMix))) bypass=\(fresh.bypass)")
    var afterPreset: [Double] = []
    for (name, pr) in [("smallRoom", AVAudioUnitReverbPreset.smallRoom), ("mediumHall", .mediumHall),
                       ("largeHall", .largeHall), ("cathedral", .cathedral), ("largeHall2", .largeHall2)] {
        let r = AVAudioUnitReverb()
        r.loadFactoryPreset(pr)
        afterPreset.append(Double(r.wetDryMix))
        line("  loadFactoryPreset(.\(name))（raw=\(pr.rawValue)）之后：wetDryMix=\(f4(Double(r.wetDryMix))) bypass=\(r.bypass)")
    }
    expect(afterPreset == [0.5, 0.5, 0.5, 0.5, 0.5] && Double(fresh.wetDryMix) == 0.5,
           "五个预置之后 wetDryMix 仍是 0.5000，和不加载时一字不差：**loadFactoryPreset 只换混响内部那一整套参数（衰减时间、预延迟、高频阻尼…），不碰干湿比**。这是「加了混响却听不出来」的头号原因")
}
do {
    let pDefault = fxPeaks({ () -> AVAudioUnitReverb in
        let r = AVAudioUnitReverb(); r.loadFactoryPreset(.largeHall2); return r }(), blocks: 3)
    line("  largeHall2，保持出厂 wet=0.5 → \(pDefault)")
    let pWet50 = fxPeaks({ () -> AVAudioUnitReverb in
        let r = AVAudioUnitReverb(); r.loadFactoryPreset(.largeHall2); r.wetDryMix = 50; return r }(), blocks: 3)
    line("  largeHall2 + 手动 wet=50 → \(pWet50)")
    let pWet100 = fxPeaks({ () -> AVAudioUnitReverb in
        let r = AVAudioUnitReverb(); r.loadFactoryPreset(.largeHall2); r.wetDryMix = 100; return r }(), blocks: 3)
    line("  largeHall2 + 手动 wet=100 → \(pWet100)")
    expect(pDefault == ["0.3518", "0.3512", "0.0010"],
           "出厂 wet=0.5 的三块：0.3518 / 0.3512 就是没挂混响的 0.3536 少掉一点点，第 3 块只剩 0.0010。源 1024 帧早就渲染完了，第三块本该是尾音的地盘，0.0010 说明湿声根本没起来")
    expect(pWet50 == ["0.1768", "0.1289", "0.0964"],
           "wet=50 之后第 2、3 块是 0.1289 / 0.0964 —— 源结束之后还有非零峰值，**那就是混响尾音**；第 1 块降到 0.1768 是干声被分走一半功率的结果。这一组是本章最能说明「混响是时间上的延展」的数字")
    expect(pWet100 == ["0.1014", "0.1902", "0.1928"],
           "wet=100（全湿）反而一块比一块响：0.1014 → 0.1902 → 0.1928。混响是**输入越多积累越响**的，短促正弦的干声过去了，能量还在墙之间叠 —— 别用「第一块的峰值」判断混响强度")
}
do {
    let pSmall = fxPeaks({ () -> AVAudioUnitReverb in
        let r = AVAudioUnitReverb(); r.loadFactoryPreset(.smallRoom); r.wetDryMix = 100; return r }(), blocks: 8, frames: 512)
    let pCath = fxPeaks({ () -> AVAudioUnitReverb in
        let r = AVAudioUnitReverb(); r.loadFactoryPreset(.cathedral); r.wetDryMix = 100; return r }(), blocks: 8, frames: 512)
    line("  源只有 512 帧（一块）、wet=100，渲染 8 块看尾巴：")
    line("    smallRoom  → \(pSmall)")
    line("    cathedral → \(pCath)")
    expect(pCath[0] == "0.0000" && pCath[1] == "0.0000" && pCath[2] == "0.0302",
           "cathedral 的前两块是**纯静音**，第 3 块才 0.0302，随后 0.0577 / 0.0743 慢慢往上爬：大空间预置自带 pre-delay，声音要先「走到墙」再反射回来。小空间 smallRoom 第一块就有 0.1303。所以判断混响至少渲染八块，两块就下结论一定读错")
    expect(pSmall[1] == "0.3701",
           "smallRoom 的第 2 块 0.3701 比第 1 块 0.1303 高，也比干声基准 0.3536 高：混响和干声在湿路里叠起来了。峰值超过「源」本身是混响图的常态，不是增益算错")
}

// ---- 16.6 变速：varispeed 连音高一起改，timePitch 保住音高改时长 ----
line("")
line("  -- 16.6 变速：varispeed 连着音高一起改，timePitch 保住音高改时长 --")
do {
    let pVar = fxPeaks({ () -> AVAudioUnitVarispeed in let v = AVAudioUnitVarispeed(); v.rate = 2; return v }(),
                       blocks: 4, frames: 2048)
    line("  varispeed rate=2，源 2048 帧 → 4x512 peaks=\(pVar)")
    expect(pVar == ["0.3536", "0.3536", "0.3538", "0.0000"],
           "rate=2 把 2048 帧压成约 1024 帧的输出：三块满峰值（0.3536/0.3536/0.3538，第三块是跨在边界上的那半块）之后第 4 块彻底空。峰值高度没变 —— **变速不动增益**，动的是时长（顺带把音高抬一个八度）")

    let pTP = fxPeaks({ () -> AVAudioUnitTimePitch in let t = AVAudioUnitTimePitch(); t.rate = 1.5; return t }(),
                      blocks: 4, frames: 2048)
    line("  timePitch rate=1.5，源 2048 帧 → \(pTP)")
    expect(pTP == ["0.3183", "0.3506", "0.3249", "0.0287"],
           "timePitch 的每块峰值都不齐平（0.3183 / 0.3506 / 0.3249）：它是把信号切成小片、重叠加回去的，块边界的对齐关系被打散了，最后 0.0287 是残余的叠音尾巴。**峰值参差不齐正是 timePitch 在干活的迹象**，别把它当失真")

    let pPitch = fxPeaks({ () -> AVAudioUnitTimePitch in let t = AVAudioUnitTimePitch(); t.pitch = 1200; return t }(),
                         blocks: 4, frames: 2048)
    line("  timePitch pitch=+1200 音分（升一个八度）、rate=1 → \(pPitch)")
    expect(pPitch == ["0.3215", "0.3546", "0.3582", "0.3769"],
           "rate=1 时时长不变，四块都有内容，峰值一路往上（0.3215 → 0.3769）：重叠加窗的位置随音高偏移而移动，块与块之间不再相等。想验证音高只能看**波形过零率**，峰值说明不了")

    let pOverlap = fxPeaks({ () -> AVAudioUnitTimePitch in let t = AVAudioUnitTimePitch(); t.overlap = 4; return t }(),
                           blocks: 3, frames: 1536)
    line("  timePitch overlap=4（出厂 8） → \(pOverlap)")
    expect(pOverlap == ["0.3470", "0.3535", "0.3535"],
           "overlap 是叠加的窗片数（出厂 8）。给 4 之后第 1 块 0.3470 略低于 0.3536，后面两块贴平：窗片少了，起始那段的重叠补偿就不够。这个属性只有跟 rate/pitch 一起动才看得出差别")
}
do {
    let t = AVAudioUnitTimePitch()
    t.rate = 100; t.pitch = 5000; t.overlap = 999
    line("  越界赋值（还没进引擎）：rate=\(f4(Double(t.rate))) pitch=\(f4(Double(t.pitch))) overlap=\(f4(Double(t.overlap)))")
    let (e, _) = makeOfflineFX(t)
    line("  attach+prepare+start 之后再读：rate=\(f4(Double(t.rate))) pitch=\(f4(Double(t.pitch))) overlap=\(f4(Double(t.overlap))) isRunning=\(e.isRunning)")
    line("  此时 t.engine 反查出来的就是刚 attach 的那台引擎=\(t.engine === e) —— 一个节点同一时刻只属于一台引擎")
    // t 已经归 e 所有，再把它塞进第二台引擎就是 16.11 注里那个 abort，所以照同样的越界值另造一台
    let t2 = AVAudioUnitTimePitch()
    t2.rate = 100; t2.pitch = 5000; t2.overlap = 999
    let pBad = fxPeaks(t2, blocks: 4, frames: 2048)
    line("  用这组越界值渲染 4x512 → \(pBad)")
    expect(t.rate == 100 && t.pitch == 5000 && t.overlap == 999,
           "**没有任何一层替你校验范围**：写 100 就读 100，装进正在运行的引擎之后还是 100。头文件注释里的 Range 只是文档，Swift 属性是个存值的桶")
    expect(pBad == ["0.0322", "0.0211", "0.0072", "0.0006"],
           "越界的后果长这样：0.0322 → 0.0006 一路衰减，几乎听不见。不抛错、不返回 nil，只是结果不再是你要的东西 —— 这类 bug 只能靠**断言渲染出来的数字**抓住")

    let v = AVAudioUnitVarispeed()
    v.rate = 0.0001
    let pSlow = fxPeaks(v, blocks: 4, frames: 2048)
    line("  varispeed rate=0.0001（放慢一万倍）→ \(pSlow)，属性读回=\(f4(Double(v.rate)))")
    expect(pSlow == ["0.0000", "0.0001", "0.0020", "0.2977"],
           "2048 帧被拉成两千万帧的规模，前几块都还在同一个波峰前面慢慢爬，第 4 块才到 0.2977：越界值能把「时长」这个维度玩到完全失控，而所有调用一律返回成功")
}

// ---- 16.7 inputNode 也能手动喂数：setManualRenderingInputPCMFormat(_:inputBlock:) ----
line("")
line("  -- 16.7 没有 playerNode 也能灌数据：inputNode 的手动喂数回调 --")
do {
    let e = AVAudioEngine()
    do { try e.enableManualRenderingMode(.offline, format: stereoNI, maximumFrameCount: 512) }
    catch { let ns = error as NSError; line("  enableManualRenderingMode 抛错：\(ns.domain)/\(ns.code)") }
    // 图里必须真的有一条 inputNode → mainMixer 的连线，否则回调一次都不会被调用
    e.connect(e.inputNode, to: e.mainMixerNode, format: monoF)
    let feed = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: 512)!
    let calls = CBBox()
    let ok = e.inputNode.setManualRenderingInputPCMFormat(monoF) { capacity in
        let n = AVAudioFrameCount(min(Int(capacity), 512))
        feed.frameLength = n
        let d = feed.floatChannelData![0]
        for i in 0..<Int(n) { d[i] = 0.25 }
        calls.add("capacity=\(capacity) given=\(n)")
        return feed.audioBufferList
    }
    line("  setManualRenderingInputPCMFormat 返回=\(ok)")
    line("  inputNode.outputFormat(forBus:0)=\(fmt(e.inputNode.outputFormat(forBus: 0)))")
    line("  inputNode.inputFormat(forBus:0)=\(fmt(e.inputNode.inputFormat(forBus: 0)))")
    e.prepare()
    do { try e.start() } catch { let ns = error as NSError; line("  start() 抛错：\(ns.domain)/\(ns.code)") }
    let p = renderPeaks(e, blocks: 3, capacity: 512)
    line("  喂 0.25 的直流，渲染 3x512 → peaks=\(p)")
    line("  回调共 \(calls.log().count) 次：\(calls.log())")
    let again = e.inputNode.setManualRenderingInputPCMFormat(monoF) { _ in feed.audioBufferList }
    line("  已经渲染过之后再设一次 返回=\(again)")
    expect(ok,
           "返回 true 表示「这条路通了」，但它只登记回调，不保证有数据 —— 真正的证据在下面：回调被调了 3 次、渲染出非零峰值")
    expect(p == ["0.1768", "0.1768", "0.1768"],
           "0.25 的直流出来是 0.1768 = 0.25×0.7071：**和 15.6 同一个 −3 dB**。这条 −3 dB 是 mainMixerNode 的，跟数据是谁喂进来的无关 —— playerNode 路径和 inputNode 路径撞出同一个系数，正好说明它不是播放器的怪癖")
    expect(calls.log() == ["capacity=512 given=512", "capacity=512 given=512", "capacity=512 given=512"],
           "回调参数 capacity 就是 renderOffline 要的那这么多帧；给满 512 就正好对上。少给（例如 capacity=512 只填 100 帧）也是合法的，引擎会再来要")
    expect(!again,
           "已经 start/渲染过之后再想换一个喂数闭包 —— 返回 false，旧闭包继续用。**喂数入口只有开机前那一次机会**")
    line("  （注）闭包必须返回 `UnsafePointer<AudioBufferList>`，写法是 `feed.audioBufferList`；")
    line("        直接把 AVAudioPCMBuffer 返回给它是编译不过的。buffer 本身要留在闭包捕获的范围里活着（这里用 let feed），")
    line("        引擎拷走的是那块裸内存，函数返回后 buffer 就被释放的话，读到的会是垃圾。")
}

// ---- 16.8 AVAudioConverter 的出厂值，以及三档 primeMethod 的三种「第一块」 ----
line("")
line("  -- 16.8 AVAudioConverter：默认值、质量参数是裸 Int、primeMethod 决定开头怎么接 --")
do {
    let mono48 = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    let cv = AVAudioConverter(from: monoF, to: mono48)!
    line("  inputFormat=\(fmt(cv.inputFormat)) outputFormat=\(fmt(cv.outputFormat))")
    line("  sampleRateConverterQuality：类型=\(type(of: cv.sampleRateConverterQuality)) 默认=\(cv.sampleRateConverterQuality)")
    line("  sampleRateConverterAlgorithm 默认=\(String(describing: cv.sampleRateConverterAlgorithm))")
    line("  primeInfo 默认：leadingFrames=\(cv.primeInfo.leadingFrames) trailingFrames=\(cv.primeInfo.trailingFrames)")
    line("  primeMethod 默认=\(cv.primeMethod.rawValue)（pre=0 normal=1 none=2）dither=\(cv.dither) downmix=\(cv.downmix) magicCookie=\(String(describing: cv.magicCookie))")
    line("  channelMap 默认：1→1=\(cv.channelMap.map { Int(truncating: $0) })")
    var qualityHeads: [[String]] = []
    for q: Int in [0, 32, 64, 127] {
        let c2 = AVAudioConverter(from: monoF, to: mono48)!
        c2.sampleRateConverterQuality = q
        let out = AVAudioPCMBuffer(pcmFormat: mono48, frameCapacity: 4096)!
        var fedOnce = false
        var cerr: NSError?
        let st = c2.convert(to: out, error: &cerr) { _, req in
            if fedOnce { req.pointee = .endOfStream; return nil }
            fedOnce = true; req.pointee = .haveData; return sineBuf(1024, hz: 1000, amp: 0.5)
        }
        qualityHeads.append((0..<4).map { f4(Double(out.floatChannelData![0][$0])) })
        line("  quality=\(c2.sampleRateConverterQuality) status=\(st.rawValue) out.frameLength=\(out.frameLength) head=\(qualityHeads.last!)")
    }
    expect(cv.sampleRateConverterQuality == 64,
           "质量参数在 Swift 里就是**裸 Int**，默认 64（头文件注释给的 medium 档）。没有 AVAudioConverterQuality 这个枚举可以用（16.1 注），写 0/32/64/127 都照原样读回，编译器不管越界")
    expect(qualityHeads[0] != qualityHeads[3],
           "quality=0 和 quality=127 的前四个采样就不一样（0.0019/0.0626/0.1315/0.1902 vs 0.0018/0.0624/0.1320/0.1894）：重采样算法真的换了，差别在第四位小数上。这种差异**听不出来但逐字节不相同**，所以本章所有对照实验都固定默认质量")
    var primeLens: [Int] = []
    for pm in [AVAudioConverterPrimeMethod.pre, .normal, .none] {
        let c3 = AVAudioConverter(from: monoF, to: mono48)!
        c3.primeMethod = pm
        let out = AVAudioPCMBuffer(pcmFormat: mono48, frameCapacity: 4096)!
        var fedOnce = false
        var cerr: NSError?
        let st = c3.convert(to: out, error: &cerr) { _, req in
            if fedOnce { req.pointee = .endOfStream; return nil }
            fedOnce = true; req.pointee = .haveData; return sineBuf(1024, hz: 1000, amp: 0.5)
        }
        primeLens.append(Int(out.frameLength))
        line("  primeMethod raw=\(pm.rawValue) status=\(st.rawValue) out.frameLength=\(out.frameLength) head=\((0..<5).map { f4(Double(out.floatChannelData![0][$0])) })")
    }
    line("  算术参考：1024 × 48000/44100 = \(f4(1024.0 * 48000 / 44100)) 帧")
    expect(primeLens == [1080, 1114, 1149],
           "同一份 1024 帧输入，三档 primeMethod 给出三种输出帧数：**pre=1080（少 34 帧，它拿输入去预热滤波器了，开头那段被吃掉 —— 看它的 head 是 0.4219 起步，正弦早就过了零点）；normal=1114（正好等于 1024×48000/44100 向下取整）；none=1149（比理论值还多，因为前后都按静音补，head 全是 -0.0000/0.0000）**。做转码要保证首尾不漏就得显式选档位，默认 .normal 是「零延迟」折中")
}

// ---- 16.9 分块喂：convert 一次给不满，endOfStream 才收尾 ----
line("")
line("  -- 16.9 4410 帧 44100→48000：一次 convert 给不完，得轮到 endOfStream --")
do {
    let mono48st = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: false)!
    let cv = AVAudioConverter(from: monoF, to: mono48st)!
    cv.channelMap = [0, 0]
    let src = sineBuf(4410, hz: 440, amp: 0.5)
    line("  理论输出帧数：4410 × 48000/44100 = \(f4(4410.0 * 48000 / 44100))")
    let out1 = AVAudioPCMBuffer(pcmFormat: mono48st, frameCapacity: 4800)!
    var fedOnce = false
    var cerr: NSError?
    let st1 = cv.convert(to: out1, error: &cerr) { _, req in
        if fedOnce { req.pointee = .noDataNow; return nil }
        fedOnce = true; req.pointee = .haveData; return src
    }
    line("  第一次 convert（容量给满 4800）：status=\(st1.rawValue) out1.frameLength=\(out1.frameLength) err=\(cerr == nil ? "nil" : "有")")
    let out2 = AVAudioPCMBuffer(pcmFormat: mono48st, frameCapacity: 4800)!
    let st2 = cv.convert(to: out2, error: &cerr) { _, req in req.pointee = .endOfStream; return nil }
    line("  第二次（闭包报 .endOfStream，raw=\(AVAudioConverterInputStatus.endOfStream.rawValue)）：status=\(st2.rawValue) out2.frameLength=\(out2.frameLength)")
    let out3 = AVAudioPCMBuffer(pcmFormat: mono48st, frameCapacity: 16)!
    let st3 = cv.convert(to: out3, error: &cerr) { _, req in req.pointee = .endOfStream; return nil }
    line("  第三次还问：status=\(st3.rawValue) out3.frameLength=\(out3.frameLength)")
    line("  合计=\(out1.frameLength + out2.frameLength) 帧；out1 peak=\(f4(Double(peakOf(out1))))")
    line("  out2 ch0[0]=\(f4(out2.floatChannelData![0][0])) ch1[0]=\(f4(out2.floatChannelData![1][0]))")
    expect(st1 == .inputRanDry && out1.frameLength == 4096,
           "第一次只交出 **4096 帧**（converter 自己定的块大小，跟你给的 4800 容量无关），status=inputRanDry=1 —— 意思是「我嘴里的输入不够填满你要的输出，再喂」。看到 1 不能当错误抛出，那是继续喂的信号")
    expect(out2.frameLength == 704 && st2 == .haveData && Int(out1.frameLength + out2.frameLength) == 4800,
           "第二次报 endOfStream 之后剩余 **704 帧**全部出来（4096+704=4800，正好等于理论值），status 变回 haveData=0。**endOfStream 是逼出尾巴的那一句**：不报它，最后 704 帧永远留在 converter 里")
    expect(st3 == .endOfStream && out3.frameLength == 0,
           "第三次同样调用返回 endOfStream=2、frameLength=0 —— 这就是循环该停的条件。OutputStatus 三个数：haveData=0 inputRanDry=1 endOfStream=2 error=3")
    expect(f4(Double(peakOf(out1))) == "0.5000",
           "峰值四舍五入到四位仍是 0.5000（源幅度就是 0.5）：**AVAudioConverter 不带那 −3 dB**（对比 15.6 的引擎和 16.7 的 0.1768）。它只是重采样/换声道，增益一律不碰。同一段音频走引擎出 0.3536、走 converter 出 0.5，电平差就是这么来的")
    expect(out2.floatChannelData![0][0] == out2.floatChannelData![1][0],
           "channelMap=[0,0] 把单声道复制进两个声道，所以 out2 的 ch0[0] 与 ch1[0] 完全相等")
}

// ---- 16.10 channelMap 与 downmix：合并声道时到底取谁 ----
line("")
line("  -- 16.10 channelMap / downmix：立体声压成单声道，默认只留左声道 --")
do {
    let cvMonoMono = AVAudioConverter(from: monoF, to: monoF)!
    let cvTo2 = AVAudioConverter(from: monoF, to: stereoNI)!
    let cvTo1 = AVAudioConverter(from: stereoNI, to: monoF)!
    line("  channelMap 默认：1→1=\(cvMonoMono.channelMap.map { Int(truncating: $0) }) 1→2=\(cvTo2.channelMap.map { Int(truncating: $0) }) 2→1=\(cvTo1.channelMap.map { Int(truncating: $0) })")
    func mixDown(_ cfg: (AVAudioConverter) -> Void) -> (String, Int, String) {
        let cv = AVAudioConverter(from: stereoNI, to: monoF)!
        cfg(cv)
        let inB = AVAudioPCMBuffer(pcmFormat: stereoNI, frameCapacity: 1024)!
        inB.frameLength = 1024
        let d = inB.floatChannelData!
        for i in 0..<1024 { d[0][i] = 0.8; d[1][i] = 0.2 }
        let out = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: 2048)!
        var fedOnce = false
        var cerr: NSError?
        let st = cv.convert(to: out, error: &cerr) { _, req in
            if fedOnce { req.pointee = .endOfStream; return nil }
            fedOnce = true; req.pointee = .haveData; return inB
        }
        return ("\(f4(Double(out.floatChannelData![0][10])))", Int(st.rawValue), cv.channelMap.map { Int(truncating: $0) }.description)
    }
    let plain = mixDown { _ in }
    line("  downmix=false（出厂默认）：ch0[10]=\(plain.0) status=\(plain.1) channelMap=\(plain.2)")
    let mixed = mixDown { $0.downmix = true }
    line("  downmix=true：ch0[10]=\(mixed.0) status=\(mixed.1) channelMap=\(mixed.2)")
    let swapped = mixDown { $0.channelMap = [1, 0] }
    line("  channelMap=[1,0]：ch0[10]=\(swapped.0) status=\(swapped.1) channelMap=\(swapped.2)")
    let bogus = mixDown { $0.channelMap = [5] }
    line("  channelMap=[5]（越界索引）：ch0[10]=\(bogus.0) status=\(bogus.1) 赋完读回=\(bogus.2)")
    expect(plain.0 == "0.8000" && mixed.0 == "0.5000",
           "输入是「左 0.8 / 右 0.2」的立体声：默认 downmix=false 时输出 **0.8000**，也就是 channelMap=[0] 直接取第 0 个声道，右声道整条丢掉；downmix=true 才是 0.5000 =（0.8+0.2)/2。**「压成单声道只听见左边」是这个默认值造成的**，不是 bug")
    expect(swapped.0 == "0.2000",
           "channelMap=[1,0] 之后输出 0.2000 —— 数组第 i 个元素的意思是「输出的第 i 个声道取输入的哪个声道」")
    expect(bogus.2 == "[0]" && bogus.0 == "0.8000",
           "越界索引不抛错也不 abort（和 16.6 的属性一样宽容），但**你写进去的值没保住**：赋 [5] 之后读回是 [0]。这类静默改写只能靠赋值后立刻读回来发现")
}

// ---- 16.11 一次性 convert(to:from:) 与错误出参 ----
line("")
line("  -- 16.11 一次性 convert(to:from:)：换声道可以，换采样率一律抛错 --")
do {
    let mono48 = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    var results: [(String, Int, Int)] = []
    func oneShot(_ label: String, _ cv: AVAudioConverter, cap: Int, _ inB: AVAudioPCMBuffer) {
        let out = AVAudioPCMBuffer(pcmFormat: cv.outputFormat, frameCapacity: AVAudioFrameCount(cap))!
        do {
            try cv.convert(to: out, from: inB)
            results.append((label, 0, Int(out.frameLength)))
            line("  \(label)：成功 out.frameLength=\(out.frameLength)")
        } catch {
            let ns = error as NSError
            results.append((label, ns.code, Int(out.frameLength)))
            line("  \(label)：抛错 domain=\(ns.domain) code=\(ns.code) out.frameLength=\(out.frameLength)")
        }
    }
    oneShot("同格式 44100/1→44100/1，容量=输入长度 512", AVAudioConverter(from: monoF, to: monoF)!, cap: 512, sineBuf(512, hz: 440, amp: 0.5))
    oneShot("同格式，容量 1024 > 输入 512", AVAudioConverter(from: monoF, to: monoF)!, cap: 1024, sineBuf(512, hz: 440, amp: 0.5))
    oneShot("2→1 声道（采样率不变），容量 512", AVAudioConverter(from: stereoNI, to: monoF)!, cap: 512, {
        let b = AVAudioPCMBuffer(pcmFormat: stereoNI, frameCapacity: 512)!
        b.frameLength = 512
        let d = b.floatChannelData!
        for i in 0..<512 { d[0][i] = 0.5; d[1][i] = 0.25 }
        return b
    }())
    for cap in [4410, 4801, 4802, 9000] {
        oneShot("重采样 44100→48000，容量 \(cap)", AVAudioConverter(from: monoF, to: mono48)!, cap: cap, sineBuf(4410, hz: 440, amp: 0.5))
    }
    let noRateChange = results.prefix(3).map { $0.1 }
    let rateChange = results.dropFirst(3).map { $0.1 }
    line("  汇总 code：帧数不变的三个=\(noRateChange)，要变采样率的四个=\(rateChange)")
    expect(noRateChange == [0, 0, 0],
           "帧数不发生变化的转换（同格式、以及 2→1 声道合并）用一次性 API 都成功，`try` 不抛、out.frameLength 正常落地")
    expect(rateChange == [-50, -50, -50, -50] && results[3].2 == 0,
           "**只要帧数要变（这里是 44100→48000），容量给 4410、4801、4802 还是 9000 都一律抛 NSOSStatusErrorDomain/-50（paramErr）**，而且 out.frameLength 停在 0 —— 抛错之后它没写过这个 buffer。一次性 API 的用途是打包/解包与声道合并，重采样必须用 16.9 那个闭包版；这条结论是四次真实调用换出来的，不是读文档读出来的")
}
line("  （注）一次性版本还有一个会**直接终止进程**的坑，探针实测（本文件的示例不敢留它，判定 3 要求 stderr 为空）：")
line("        输出 buffer 的 frameCapacity 小于输入 buffer 的 frameLength 时不是抛错，是 NSException：")
line("        *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:")
line("        'required condition is false: outputBuffer.frameCapacity >= inputBuffer.frameLength'")
line("        栈顶是 -[AVAudioConverter convertToBuffer:fromBuffer:error:]，exit=134（Abort trap）。")
line("        闭包版没有这个约束（它自己按块取数据），这也是选闭包版的第二个理由。")
do {
    let mono48 = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    let cv = AVAudioConverter(from: monoF, to: mono48)!
    let out = AVAudioPCMBuffer(pcmFormat: mono48, frameCapacity: 512)!
    let wrong = AVAudioPCMBuffer(pcmFormat: stereoNI, frameCapacity: 512)!
    wrong.frameLength = 512
    var cerr: NSError?
    let st = cv.convert(to: out, error: &cerr) { _, req in
        req.pointee = .haveData; return wrong
    }
    let ns = cerr as NSError?
    line("  闭包版喂 2 声道输入给期望 1 声道的 converter：status=\(st.rawValue) out.frameLength=\(out.frameLength)")
    line("  NSError domain=\(ns?.domain ?? "-") code=\(ns?.code ?? -1) desc=\(ns?.localizedDescription ?? "-")")
    expect(st == .error && ns?.domain == "NSOSStatusErrorDomain" && ns?.code == -1,
           "**喂错声道数不会 abort，但结果很难看**：status=error=3、NSError 给的是 code=-1（genericErr），描述里连格式名字都没有，而 out.frameLength 已经被改成了 512（内容是没换过的垃圾）。所以调用之前自己核对 inBuffer.format == cv.inputFormat，别指望错误信息告诉你哪里错了")
    let cv2 = AVAudioConverter(from: monoF, to: mono48)!
    let badOut = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: 512)!
    var cerr2: NSError?
    let st2 = cv2.convert(to: badOut, error: &cerr2) { _, req in req.pointee = .endOfStream; return nil }
    let ns2 = cerr2 as NSError?
    line("  输出 buffer 用了 converter 的**输入**格式（44100）：status=\(st2.rawValue) frameLength=\(badOut.frameLength)")
    line("  NSError domain=\(ns2?.domain ?? "-") code=\(ns2?.code ?? -1) 这个 code 按 FourCC 解=\(ns2 == nil ? "?" : fourcc(UInt32(truncatingIfNeeded: ns2!.code)))")
    expect(st2 == .error && badOut.frameLength == 0,
           "输出 buffer 格式不对时 frameLength 老老实实停在 0（比上一个错误干净），错误码 1718449215 用 §6 那个 fourcc 一解就是 **'fmt?'** —— CoreMedia/AudioToolbox 的很多错误码本身就是 FourCC，认得这个套路比背错误码有用")
}
line("  （注）本章示例写到这里，撞过两次「不是抛错而是 SIGABRT」，两条都在探针里复现过，")
line("        放在示例里会把整个进程带走，所以只记原文：")
line("        1) 单声道 buffer 排进输出格式是立体声的 playerNode：")
line("           reason: 'required condition is false: _outputFormat.channelCount == buffer.format.channelCount'")
line("           栈顶 -[AVAudioPlayerNode scheduleBuffer:atTime:options:completionHandler:]，exit=134。")
line("           也就是说 15 章反复强调的「连线时的 format 要和你 schedule 的 buffer 一致」，违反的代价是进程没了")
line("        2) 同一个 AVAudioUnit 实例 attach 到第二台引擎：")
line("           reason: 'required condition is false: nil == owningEngine || GetEngine() == owningEngine'")
line("           栈顶 -[AVAudioEngine attachNode:]，exit=134 —— 16.6 里那句 t.engine 反查就是在盯这个所有权")
line("        3) 想走 KVC 的捷径拿参数：AVAudioUnitTimePitch().value(forKey: \"parameterTree\")")
line("           reason: '[<AVAudioUnitTimePitch 0x…> valueForUndefinedKey:]: this class is not key value coding-compliant for the key parameterTree.'")
line("           NSUnknownKeyException → exit=134。这正好是 §8 那条规矩的另一种死法：**KVC 的键名错了不返回 nil，是抛异常**")

// ============================================================ 17
line("")
line("== 17) MediaPlayer：锁屏 / 控制中心 / 耳机线控那套「系统联动」 ==")
line("  前 16 节全是 AVFoundation 的自我封闭世界：声音从哪来、变成什么数字。")
line("  用户按锁屏上的暂停、按耳机上的下一曲，走的却是另一个框架 MediaPlayer。")
line("  这套东西在 headless 模拟器上「听不见」，但**它的默认值和键名全部可查**，")
line("  而联动的 bug 九成出在键名写错、状态没回、命令没使能这三件事上 —— 恰好都能断言。")
line("  这一节不播音乐（模拟器里没有媒体库），只做四件事：读默认值、写进去再读回来、")
line("  把常量真正等于哪个字符串打出来、看清权限被拒时各 API 的表现。")

// ---- 17.1 MPNowPlayingInfoCenter：现在正在放什么 ----
line("")
line("  -- 17.1 MPNowPlayingInfoCenter：只有一个字典和一个播放状态 --")
do {
    let npc = MPNowPlayingInfoCenter.default()
    line("  刚拿到手：nowPlayingInfo=\(String(describing: npc.nowPlayingInfo)) playbackState=\(npc.playbackState.rawValue)")
    let states: [(String, MPNowPlayingPlaybackState)] = [("unknown", .unknown), ("playing", .playing),
                                                         ("paused", .paused), ("stopped", .stopped),
                                                         ("interrupted", .interrupted)]
    line("  MPNowPlayingPlaybackState：\(states.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))")
    npc.playbackState = .playing
    line("  设成 .playing 之后读回=\(npc.playbackState.rawValue)")
    npc.nowPlayingInfo = [MPMediaItemPropertyTitle: "示例曲目",
                          MPMediaItemPropertyArtist: "示例作者",
                          MPMediaItemPropertyPlaybackDuration: 44.1,
                          MPNowPlayingInfoPropertyElapsedPlaybackTime: 3.0,
                          MPNowPlayingInfoPropertyPlaybackRate: 1.0]
    let info = npc.nowPlayingInfo!
    line("  写进去之后现在共 \(info.count) 项")
    for (name, key) in [("title", MPMediaItemPropertyTitle), ("artist", MPMediaItemPropertyArtist),
                        ("duration", MPMediaItemPropertyPlaybackDuration),
                        ("elapsed", MPNowPlayingInfoPropertyElapsedPlaybackTime),
                        ("rate", MPNowPlayingInfoPropertyPlaybackRate)] {
        line("    \(name)：键名常量本身就是字符串 \u{22}\(key)\u{22}，值=\(String(describing: info[key]))")
    }
    expect(npc.playbackState == .playing && states.map { $0.1.rawValue } == [0, 1, 2, 3, 4],
           "playbackState 是**你自己写进去的**一个枚举（unknown=0 playing=1 paused=2 stopped=3 interrupted=4），系统不会替你对着 AVPlayer 改它。写完之后锁屏转不转圈，全看你有没有在暂停时把它设成 .paused —— 这是联动 bug 的第一名")
    expect(MPMediaItemPropertyTitle == "title"
           && MPMediaItemPropertyArtist == "artist"
           && MPMediaItemPropertyPlaybackDuration == "playbackDuration"
           && MPNowPlayingInfoPropertyElapsedPlaybackTime == "MPNowPlayingInfoPropertyElapsedPlaybackTime"
           && MPNowPlayingInfoPropertyPlaybackRate == "MPNowPlayingInfoPropertyPlaybackRate",
           "字典的键**就是这些常量的字符串值**，而这两族的命名规矩完全不同：MPMediaItem 那族全小写（MPMediaItemPropertyTitle 其实是 \u{22}title\u{22}），MPNowPlayingInfoProperty 那族却等于**自己的名字**（elapsed 那一条的字符串就是 MPNowPlayingInfoPropertyElapsedPlaybackTime 整串）。写中文键、把 title 首字母大写成 \u{22}Title\u{22}、猜一个 \u{22}elapsedPlaybackTime\u{22} 都不报错，锁屏上只是一片空白 —— 把字符串本体印出来核对，是这一节唯一的价值（这条 expect 我第一版按直觉写成 \u{22}elapsedPlaybackTime\u{22}，跑出来直接 FAIL）")
    expect(info[MPMediaItemPropertyPlaybackDuration] as? Double == 44.1,
           "时长/进度/倍速这类要参与锁屏进度条推算的值必须是 NSNumber 系的标量，塞 CMTime 或字符串系统读不到。这里 44.1 秒就是 §1 那段 wav 的长度")
}
line("  （注）MPNowPlayingInfoCenter 上可以写的键远不止这五个，但**只有 iOS 版本支持的那些才生效**，")
line("        越新的键在越旧的系统上是静默忽略（不抛错、不打印）。本章只用了从头文件里当场读到名的那几个。")

// ---- 17.2 MPRemoteCommandCenter：远端命令的默认使能状态 ----
line("")
line("  -- 17.2 MPRemoteCommandCenter：命令默认全是使能的，等你接单 --")
do {
    let cc = MPRemoteCommandCenter.shared()
    let cmds: [(String, MPRemoteCommand)] = [
        ("play", cc.playCommand), ("pause", cc.pauseCommand), ("stop", cc.stopCommand),
        ("togglePlayPause", cc.togglePlayPauseCommand),
        ("previousTrack", cc.previousTrackCommand), ("nextTrack", cc.nextTrackCommand),
        ("seekForward", cc.seekForwardCommand), ("seekBackward", cc.seekBackwardCommand),
        ("skipForward", cc.skipForwardCommand), ("skipBackward", cc.skipBackwardCommand),
        ("changePlaybackRate", cc.changePlaybackRateCommand),
        ("changePlaybackPosition", cc.changePlaybackPositionCommand),
        ("like", cc.likeCommand), ("dislike", cc.dislikeCommand), ("bookmark", cc.bookmarkCommand),
        ("rating", cc.ratingCommand),
        ("changeShuffleMode", cc.changeShuffleModeCommand), ("changeRepeatMode", cc.changeRepeatModeCommand),
        ("enableLanguageOption", cc.enableLanguageOptionCommand),
        ("disableLanguageOption", cc.disableLanguageOptionCommand),
    ]
    line("  shared() 上的命令共 \(cmds.count) 条，默认 isEnabled 与实际类型：")
    for (name, cmd) in cmds {
        line("    \(name)：isEnabled=\(cmd.isEnabled) 类型=\(type(of: cmd))")
    }
    let enabledCount = cmds.filter { $0.1.isEnabled }.count
    line("  当前 isEnabled=true 的有 \(enabledCount)/\(cmds.count) 条")
    expect(enabledCount == cmds.count,
           "**命令出厂就是 isEnabled=true**，但没人 addTarget 的话，用户按下去系统得到的是「没有处理者」，锁屏上那个按钮直接不出现。也就是说：**使能≠有人接**；要屏蔽某个按钮是把它 isEnabled=false，不是「不注册」")
    expect(cc.changePlaybackRateCommand.supportedPlaybackRates.isEmpty,
           "实际类型（上面每行都印了）和直觉对不上两处：**切歌**才是子类 —— previousTrack/nextTrack 是 MPSkipTrackCommand；而**看得到进度条的** seekForward/seekBackward 反而是裸 MPRemoteCommand，参数不在命令上、在 handler 收到的事件对象里。倍速默认空数组这条 expect 顺便钉死：supportedPlaybackRates 出厂就是 []")
    let evtTypes: [AnyObject.Type] = [MPRemoteCommandEvent.self, MPSkipIntervalCommandEvent.self,
                                      MPSeekCommandEvent.self, MPRatingCommandEvent.self,
                                      MPChangePlaybackRateCommandEvent.self, MPFeedbackCommandEvent.self,
                                      MPChangePlaybackPositionCommandEvent.self]
    line("  handler 收到的事件类（只声明、不触发，用来验这些名字在本 SDK 写得出来）：\(evtTypes.map { String(describing: $0) })")
    let skip = cc.skipForwardCommand as MPSkipIntervalCommand
    line("  skipForward：preferredIntervals=\(skip.preferredIntervals.map { f4(Double(truncating: $0)) })")
    skip.preferredIntervals = [15, 30]
    line("  设成 [15,30] 之后读回=\(skip.preferredIntervals.map { f4(Double(truncating: $0)) })")
    expect(skip.preferredIntervals.map { Double(truncating: $0) } == [15, 30],
           "跳过时长是个**数组**（界面上给你一串候选档位），默认只有 10 秒这一档。旧文档里的 skipInterval 单数属性在本 SDK 不存在，写它会编译不过")
    let rate = cc.changePlaybackRateCommand
    line("  changePlaybackRate：supportedPlaybackRates=\(rate.supportedPlaybackRates.map { f4(Double(truncating: $0)) })（出厂是空的）")
    rate.supportedPlaybackRates = [0.5, 1.0, 1.5, 2.0]
    line("  给了 [0.5,1,1.5,2] 之后读回=\(rate.supportedPlaybackRates.map { f4(Double(truncating: $0)) })")
    expect(rate.supportedPlaybackRates.map { Double(truncating: $0) } == [0.5, 1.0, 1.5, 2.0],
           "倍速命令和上面那条正好相反：**默认不支持任何倍速**（空数组），必须自己声明，播放控件上才会出现倍速选项。这就是「我明明注册了倍速命令，界面上却没有」的答案")
    let like = cc.likeCommand
    let likeBefore = (like.isActive, like.localizedTitle)
    line("  like(MPFeedbackCommand)：isActive=\(like.isActive) localizedTitle=\u{22}\(like.localizedTitle)\u{22}")
    like.isActive = true
    like.localizedTitle = "收藏"
    line("  设过之后：isActive=\(like.isActive) localizedTitle=\u{22}\(like.localizedTitle)\u{22}")
    expect(!likeBefore.0 && likeBefore.1.isEmpty,
           "MPFeedbackCommand 出厂 isActive=false、localizedTitle 是**空串**（不是曲目名，也不是「喜欢」这种默认文案）。标题不设，控制中心上那个按钮就没有字；点亮与否(isActive)也完全是你自己维护的布尔值，系统不会因为用户点了一下就替你自己翻 —— 翻转要写在 handler 的返回值之后自己做")
    let rating = cc.ratingCommand
    line("  rating(MPRatingCommand)：minimumRating=\(f4(Double(rating.minimumRating))) maximumRating=\(f4(Double(rating.maximumRating)))")
    let repTypes: [(String, MPRepeatType)] = [("off", .off), ("one", .one), ("all", .all)]
    let shuTypes: [(String, MPShuffleType)] = [("off", .off), ("items", .items), ("collections", .collections)]
    line("  changeRepeatMode.currentRepeatType=\(cc.changeRepeatModeCommand.currentRepeatType.rawValue) "
         + "（MPRepeatType：\(repTypes.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))）")
    line("  changeShuffleMode.currentShuffleType=\(cc.changeShuffleModeCommand.currentShuffleType.rawValue) "
         + "（MPShuffleType：\(shuTypes.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))）")
    expect(repTypes.map { $0.1.rawValue } == [0, 1, 2] && shuTypes.map { $0.1.rawValue } == [0, 1, 2],
           "**注意这两族枚举的数值和 17.3 播放器上的 MPMusicRepeatMode/MPMusicShuffleMode 完全不同**："
           + "命令这边 off=0 one=1 all=2（压根没有 default/none 两档），播放器那边 default=0 none=1 one=2 all=3。"
           + "同一屏上 currentRepeatType=0 说的是 Off，而 sys.repeatMode 读回 1 说的是 none —— 数字长得像、含义差一档，"
           + "把一族的 rawValue 直接塞给另一族的属性，编译不拦、运行不报，界面上就是「单曲循环」和「不循环」互换")
    expect(rating.minimumRating == 0 && rating.maximumRating == 0,
           "MPRatingCommand 出厂 minimumRating 和 maximumRating **都是 0** —— 上下限相等意味着这条命令没有任何可用刻度，用户端看到的五星/星级评分根本点不动。要它生效必须自己写 maximumRating = 5（这条命令是 MPRatingCommand，handler 事件里才带 rating）")
}
do {
    var handled = ""
    let cc = MPRemoteCommandCenter.shared()
    let statusNames: [(String, MPRemoteCommandHandlerStatus)] = [("success", .success),
                                                                 ("noSuchContent", .noSuchContent),
                                                                 ("noActionableNowPlayingItem", .noActionableNowPlayingItem),
                                                                 ("deviceNotFound", .deviceNotFound),
                                                                 ("commandFailed", .commandFailed)]
    line("  MPRemoteCommandHandlerStatus 各档 rawValue：\(statusNames.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))")
    let token = cc.playCommand.addTarget { _ in handled = "play 被点了"; return .success }
    line("  addTarget 返回的 token 类型=\(type(of: token))")
    cc.playCommand.removeTarget(token)
    expect(handled == "",
           "**注册了 handler 也不等于能被调用**：这一节里没有系统去点它，handled 当然是空。能断言的只有「addTarget 给我一个 token、removeTarget(token) 能摘掉」。真实触发要在真机上按控制中心/耳机线控，或者点锁屏 —— 那属于本章的诚实边界（见文末）")
    expect(token is String,
           "token 的真实类型是 String（ObjC 侧那边是个 __NSCFString），不是你以为的 id/AnyHashable：拿错类型去 removeTarget 会摘不掉，处理者越注册越多")
}

// ---- 17.3 MPMusicPlayerController：系统播放器 vs App 队列播放器 ----
line("")
line("  -- 17.3 MPMusicPlayerController：同名的两种播放器，行为完全不同 --")
do {
    let sys = MPMusicPlayerController.systemMusicPlayer
    let app = MPMusicPlayerController.applicationQueuePlayer
    line("  systemMusicPlayer 的 Swift 类型=\(type(of: sys))")
    line("  applicationQueuePlayer 的 Swift 类型=\(type(of: app))")
    line("  老 applicationMusicPlayer 的 Swift 类型=\(type(of: MPMusicPlayerController.applicationMusicPlayer))（注意它和上面 applicationQueuePlayer **动态类型同名**，靠 type(of:) 分不出新老播放器）")
    line("  两者 playbackState=\(sys.playbackState.rawValue)/\(app.playbackState.rawValue)")
    let pbStates: [(String, MPMusicPlaybackState)] = [("stopped", .stopped), ("playing", .playing), ("paused", .paused),
                                                      ("interrupted", .interrupted),
                                                      ("seekingForward", .seekingForward), ("seekingBackward", .seekingBackward)]
    line("  MPMusicPlaybackState：\(pbStates.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))")
    line("  nowPlayingItem：sys=\(String(describing: sys.nowPlayingItem)) app=\(String(describing: app.nowPlayingItem))")
    line("  indexOfNowPlayingItem（NSUInteger）：sys=\(sys.indexOfNowPlayingItem) app=\(app.indexOfNowPlayingItem)")
    let modes: [(String, MPMusicRepeatMode)] = [("default", .`default`), ("none", .none), ("one", .one), ("all", .all)]
    line("  MPMusicRepeatMode：\(modes.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))，sys.repeatMode=\(sys.repeatMode.rawValue)")
    let shuffles: [(String, MPMusicShuffleMode)] = [("default", .`default`), ("off", .off), ("songs", .songs), ("albums", .albums)]
    line("  MPMusicShuffleMode：\(shuffles.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))，sys.shuffleMode=\(sys.shuffleMode.rawValue)")
    expect(type(of: sys) != type(of: app),
           "两个属性返回的**不是同一个类**：type(of:) 打出来 systemMusicPlayer 是 MPMusicPlayerSystemController（头文件里它的静态类型写作 MPMusicPlayerController<MPSystemMusicPlayerController>，是个「类 + 协议」组合，所以动态类型和静态类型不一样），applicationQueuePlayer 是 MPMusicPlayerApplicationController（在你自己进程里放队列）。拿错播放器时 setQueue 看着成功了，声音却在别处")
    expect(sys.playbackState == .stopped && sys.nowPlayingItem == nil,
           "模拟器里没有正在播的媒体：playbackState=stopped=0、nowPlayingItem=nil。这就是「联动看起来没生效」的真实原因 —— **不是你代码写错了，是根本没有媒体**")
    sys.prepareToPlay()
    let coll = MPMediaItemCollection(items: [])
    line("  MPMediaItemCollection(items: [])：count=\(coll.count) items.count=\(coll.items.count) representativeItem=\(String(describing: coll.representativeItem)) mediaTypes=\(coll.mediaTypes.rawValue)")
    sys.setQueue(with: coll)
    app.setQueue(with: coll)
    line("  两边都 setQueue(with: 那个空队列) 之后 playbackState=\(sys.playbackState.rawValue)/\(app.playbackState.rawValue) nowPlayingItem=\(String(describing: sys.nowPlayingItem))/\(String(describing: app.nowPlayingItem))")
    line("  刻意 repeatMode = .default、shuffleMode = .default 之后读回=\(sys.repeatMode.rawValue)/\(sys.shuffleMode.rawValue)")
    expect(coll.count == 0 && coll.representativeItem == nil,
           "空集合本身没毛病：count=0、items 是空数组（不是 nil）、representativeItem=nil —— 集合里没曲目时代表曲目就是 nil。有毛病的是它的**构造写法**，见下面那条注")
    expect(sys.playbackState == .stopped && app.playbackState == .stopped,
           "prepareToPlay()/setQueue(with:) 在「媒体库不存在」这台机器上**不报错也不抛错**（这两个方法本身都不 throws），状态仍是 stopped。MediaPlayer 的失败一律不通知你，只体现在状态值上，所以每次调用之后自己去读 playbackState 是唯一可靠的检查")
    expect(sys.indexOfNowPlayingItem == 0 && app.indexOfNowPlayingItem == 0,
           "头文件给 indexOfNowPlayingItem 的注释写着 \u{22}May return NSNotFound if the index is not valid (e.g. an empty queue…)\u{22}，可这台机器在**空队列**上给的是 0，而同一时刻 nowPlayingItem 是 nil。NSUInteger 的 NSNotFound 是 18446744073709551615，所以 `if p.indexOfNowPlayingItem == NSNotFound` 这种判法在这里永远为假，会把「没有在播」读成「正在播第 0 首」。要判有没有曲目，读 nowPlayingItem 是不是 nil，别读下标")
}
line("  （注）上一段用 MPMediaItemCollection(items: [])，**不是** MPMediaItemCollection()。后者实测直接 abort：")
line("        *** Terminating app due to uncaught exception 'MPMediaItemCollectionInitException',")
line("        reason: '-init is not supported, use -initWithItems:'，栈顶 -[MPMediaItemCollection init]，exit=134")
line("        头文件里 initWithItems: 被标成 NS_DESIGNATED_INITIALIZER，裸 init 是系统**故意禁掉**的，")
line("        但 Swift 还是把 init() 给你生成了出来 —— 编译器不拦，运行时才炸，这是 ObjC 桥接的固有缺口")
line("  （注）这一节里 `volume` 这个属性**在 Swift 里根本不可用**，编译期就拒绝：")
line("        'volume' is unavailable in iOS: Use MPVolumeView for volume control.")
line("        头文件里它写的是 deprecated，Swift 侧却被翻成了 unavailable，所以你连「试一下看会不会崩」都做不到。")

// ---- 17.4 媒体库权限与查询 ----
line("")
line("  -- 17.4 MPMediaLibrary / MPMediaQuery：被拒之权下各 API 长什么样 --")
do {
    let auth = MPMediaLibrary.authorizationStatus()
    line("  MPMediaLibrary.authorizationStatus()=\(auth.rawValue)（notDetermined=0 denied=1 restricted=2 authorized=3）")
    let lib = MPMediaLibrary.default()
    line("  MPMediaLibrary.default() 类型=\(type(of: lib))（它只提供 lastModifiedDate 和库变更通知开关，取内容不归它管）")
    let q = MPMediaQuery.songs()
    line("  MPMediaQuery.songs()：groupingType=\(q.groupingType.rawValue) filterPredicates=\(String(describing: q.filterPredicates?.count)) items=\(String(describing: q.items?.count))")
    let groupings: [(String, MPMediaGrouping)] = [("title", .title), ("artist", .artist), ("album", .album), ("composer", .composer)]
    line("  MPMediaGrouping 挑四个：\(groupings.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))")
    let noneQuery = MPMediaQuery()
    line("  裸 MPMediaQuery()：groupingType=\(noneQuery.groupingType.rawValue) items=\(String(describing: noneQuery.items))")
    expect(auth == .denied,
           "模拟器上媒体库权限是 **denied=1**，不是 notDetermined=0 —— 因为模拟器压根没有「允许访问音乐」这一步可问。这对写代码很实际：授权分支必须自己造条件测，别只在真机上跑通就算数")
    expect(q.items == nil && noneQuery.items == nil,
           "权限被拒时这些 API 一律给 **nil，不是空数组**。`items?.count ?? 0` 之类写法看着安全，却把「没权限」和「有权限但库里 0 首」压成了同一个数字；判权限要单独读 authorizationStatus()")
    expect(q.groupingType == .title && noneQuery.groupingType.rawValue == 0,
           "MPMediaQuery.songs() 的 groupingType 是 title=0（裸构造也是 0）：分组方式是查询对象的属性。MPMediaGrouping 里**没有 .song**，只有 .title —— 照着「songs() 该有 .song」的直觉写会得到编译错误")
}
line("  （注）MPMediaLibrary 在本 SDK 上没有 items(matching:) 这个方法，编译器原文：")
line("        value of type 'MPMediaLibrary' has no member 'items'。")
line("        取内容走 MPMediaQuery，云端库另有一个 cloudItems，两个都是可选值，被拒权限时都是 nil。")

// ---- 17.5 MPVolumeView 与联动通知名 ----
line("")
line("  -- 17.5 MPVolumeView：控件的子视图结构，以及通知名只能这么写 --")
do {
    let vv = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
    line("  MPVolumeView(frame: 200x40)：isHidden=\(vv.isHidden) showsVolumeSlider=\(vv.showsVolumeSlider) showsRouteButton 这个属性还在但 iOS 13 就废弃了（本节故意不读它）")
    line("  自动生成的子视图：\(vv.subviews.map { type(of: $0) })")
    expect(vv.subviews.count > 0 && vv.showsVolumeSlider,
           "MPVolumeView 一建好就有子视图（音量滑块 + 标签 + 路由按钮），这是**系统给的现成控件**，自己画音量条只会跟系统不同步。反过来：它就是 17.3 注里 volume 不可用之后**唯一**能改音量的入口")
    let names: [(String, NSNotification.Name)] = [
        ("MPMusicPlayerControllerNowPlayingItemDidChange", .MPMusicPlayerControllerNowPlayingItemDidChange),
        ("MPMusicPlayerControllerPlaybackStateDidChange", .MPMusicPlayerControllerPlaybackStateDidChange),
        ("MPMusicPlayerControllerVolumeDidChange", .MPMusicPlayerControllerVolumeDidChange),
    ]
    line("  三个通知名的 rawValue：")
    for (n, name) in names { line("    \(n) = \u{22}\(name.rawValue)\u{22}") }
    expect(names.allSatisfy { $0.1.rawValue.hasSuffix("Notification") }
           && NSNotification.Name.MPMusicPlayerControllerVolumeDidChange.rawValue == "MPMusicPlayerControllerVolumeDidChangeNotification",
           "这是最容易翻车的一处：Swift 侧的**符号名**短（`.MPMusicPlayerControllerVolumeDidChange`），可它的**字符串值带 Notification 后缀**（上面三条印得清清楚楚）。"
           + "所以拿字符串比对通知（在测试里自己拼 `NSNotification.Name("+"\u{22}…\u{22})`、或者去 Console 里 grep）认的是**带后缀**的那一串；"
           + "把短名当字符串写进去一样能编过、一样合法，只是永远匹配不到回调 —— 静默失效，不抛错也不告警，表现就是「监听没反应」。"
           + "反过来在代码里直接敲带后缀的裸常量名 `MPMusicPlayerControllerVolumeDidChangeNotification`，编译器报 has no member —— 两头别搞反")
    line("  MPNowPlayingInfoPropertyIsLiveStream 的字符串值=\u{22}\(MPNowPlayingInfoPropertyIsLiveStream)\u{22}")
    expect(MPNowPlayingInfoPropertyIsLiveStream == "MPNowPlayingInfoPropertyIsLiveStream" && MPNowPlayingInfoPropertyIsLiveStream != "isLiveStream",
           "顺手把最容易写错的那个键钉住：真名是 **MPNowPlayingInfoPropertyIsLiveStream**（MPNowPlayingInfo 那一族，不是 MPMediaItemProperty 前缀），而且和 17.1 那两条一样，它的字符串值**就是自己的名字**，不是猜得出的 isLiveStream / isLiveStreaming。两头都错过：名字写错编译器拦得住，字符串值写错编译器拦不住")
}
line("  （注）通知名在 Swift 里只能写成 `NSNotification.Name.MPMusicPlayerController…`（符号名不带后缀，")
line("        可它的 rawValue 带 —— 上面那两条 expect 就是把这两层分开钉住的）。")
line("        同理 MPRemoteCommandCenter 上的 addTargetWithHandler: 在 Swift 里")
line("        就叫 addTarget(handler:)，照着旧书敲那个名字会得到 'has no member' 的编译错误。")

// ---- 17.6 两套撞名的状态枚举 + 字典不校验键名 ----
line("")
line("  -- 17.6 MPNowPlayingPlaybackState 与 MPMusicPlaybackState：名字像，数值对不上 --")
do {
    let npcStates: [(String, MPNowPlayingPlaybackState)] = [("unknown", .unknown), ("playing", .playing),
                                                            ("paused", .paused), ("stopped", .stopped),
                                                            ("interrupted", .interrupted)]
    let muStates: [(String, MPMusicPlaybackState)] = [("stopped", .stopped), ("playing", .playing),
                                                      ("paused", .paused), ("interrupted", .interrupted),
                                                      ("seekingForward", .seekingForward),
                                                      ("seekingBackward", .seekingBackward)]
    line("  MPNowPlayingPlaybackState（§17.1 那个中心）：\(npcStates.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))")
    line("  MPMusicPlaybackState（§17.3 那个播放器）：\(muStates.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))")
    let byMu: [Int: String] = Dictionary(uniqueKeysWithValues: muStates.map { (Int($0.1.rawValue), $0.0) })
    line("  顺带一个只有真编译过一次才会知道的细节：两个枚举的 rawValue **连类型都不一样**，")
    line("  中心那边是 Int、播放器那边是 UInt，所以下面这张表每一行都得先 Int(...) 转一道；")
    line("  不转的原文报错是 cannot convert value of type 'UInt' to expected argument type 'Int'。")
    line("  把中心的 5 档**按 rawValue 硬搬到**播放器枚举上会得到：")
    for s in npcStates {
        let idx = Int(s.1.rawValue)
        let hit = byMu[idx] ?? "这一档在播放器里不存在"
        line("    \(s.0)=\(s.1.rawValue) → \(hit)")
    }
    expect(byMu[0] == "stopped" && byMu[3] == "interrupted" && byMu[4] == "seekingForward",
           "两家的 playing=1、paused=2 恰好重合，剩下的全错位：中心里 stopped=3 在播放器语义里是 interrupted，中心里 interrupted=4 在播放器里是 seekingForward。上面那张表就是「拿数值串过去」的实际结果 —— 不报错、不崩溃，只是 5 档里 3 档含义被换掉。联动 bug 的第二名，只能逐个 case 手写映射")
    expect(byMu.count == 6 && npcStates.count == 5,
           "中心只有 5 档、播放器有 6 档，可中心那 5 个数值**全都**落在播放器的合法区间（0…5）里，一个都不越界。这正是最坏的组合：按数值硬搬不会失败、不会报错，`MPMusicPlaybackState(rawValue:)` 永远给你个值出来，于是 5 档里有 3 档被悄悄换成别的含义；反过来播放器多出的 seekingBackward=5 在中心里没有对应。两边永远不可能一一对应，所以本章只并排印表、不写双向映射函数")
}
line("")
line("  -- 17.6b 把写错的键塞进 nowPlayingInfo：字典照收，系统照沉默 --")
do {
    let npc = MPNowPlayingInfoCenter.default()
    npc.nowPlayingInfo = ["Title": "首字母大写的键",
                          "isLiveStreaming": true,
                          MPMediaItemPropertyTitle: "真键"]
    let info = npc.nowPlayingInfo!
    line("  混着写三种键之后字典读出 \(info.count) 项，键集（排序）=\(info.keys.sorted())")
    line("  按真键取值=\(String(describing: info[MPMediaItemPropertyTitle]))，按错键取值=\(String(describing: info["Title"]))")
    expect(info.count == 3 && info["Title"] != nil,
           "nowPlayingInfo 的类型是 `[String: Any]?`，**它不是 API，是个普通字典**：你塞进去什么键都能原样读回来，编译器不做校验，系统不会告警，stderr 也干干净净。真键被大写成 \u{22}Title\u{22}、把 isLiveStream 多写成一步 ing（17.5 那条 expect 钉的就是它），锁屏上只是少了那一格，程序一点反应都没有")
    expect(info[MPMediaItemPropertyTitle] as? String == "真键",
           "按真键取回来的是 \u{22}真键\u{22} 那条 —— 字典的键比较用的是**字符串值**，跟你用哪个常量拼出来的无关")
    var d: [String: Any] = [:]
    d["title"] = "先写的"
    d[MPMediaItemPropertyTitle] = "后写的"
    let dTitle = d["title"]
    line("  同一个键名换两种写法先后赋值：count=\(d.count)，d[标题键]=\(String(describing: dTitle))")
    expect(d.count == 1 && d["title"] as? String == "后写的",
           "`MPMediaItemPropertyTitle` 就是 \u{22}title\u{22}（17.1 印过），所以这两行赋值打在同一个键上：**后写的静默覆盖先写的**，count 还是 1，没有报错也没有告警。分段拼装这个字典时（网络回调写一半、歌词解析写一半），同一键被谁最后碰到只能靠打字典才知道 —— 排查锁屏显示不对，先把 nowPlayingInfo 整个打出来核键名，比猜代码快")
}
line("  （注）§17 全程没有真机、也没有媒体库，所以这一节的三个 API 都只做到「读默认值 / 写进去读回来」。")
line("        还有一类只有真机才暴露的差异：§4 里 AVAudioApplication 是 iOS 17 才有的入口，")
line("        直接写在 iOS 15 目标上会得到 'AVAudioApplication' is only available in iOS 17.0 or newer；")
line("        MediaPlayer 里同样有这种带版本门槛的成员，本章的做法是**只写头文件里当场读到、")
line("        且当前 SDK 允许写进 iOS 15 目标的名字**，其余一律不碰 —— 与其抄一本旧书里的 API，")
line("        不如让编译器逐字告诉你哪个名字在这个工具链上存在。")

line("")
line("== 本章的诚实边界 ==")
line("  1) 音频的「听」这一环全部没验：headless 模拟器上没有可听输出，本章只能证明采样值、")
line("     帧数、状态机、错误码，不能证明音色、混响好听不好听、变速有没有artifact。")
line("  2) MPRemoteCommandCenter 的 handler 一次都没被真实触发过（没有系统去点它），")
line("     只能断言默认使能状态、参数数组和注册/摘除；真机上按线控/锁屏才是那条路。")
line("  3) 媒体库权限在模拟器上恒为 denied，MPMediaQuery 拿到的是 nil ——")
line("     「有权限时列表长什么样」本章没有覆盖。")
line("  4) AVPlayerViewController / Picture in Picture 只验了属性和能力查询，")
line("     画面是否真的在动、画中画窗口是否浮起来，需要真机 + 肉眼。")
line("  5) §8 那一类「主队列被 await 占住」的现象是脚本环境特有的，真机不会出现；")
line("     反过来，真机上才有的路由变化、蓝牙抢占、后台被系统回收，脚本环境一个都造不出来。")
line("==== 24 结束 ====")
exit(failures == 0 ? 0 : 1)
