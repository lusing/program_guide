// ============================================================
// 34 - Core ML：一个模型文件的 46 个字节、一次断言、和一条走不通的摄像头路
//
// 《跟着项目学iOS应用开发：基于Swift 4》第 15 章（机器学习和 Core-ML）是全书最后一章，
// 也是唯一一章把「别人算好的东西」放进 App。它的节次是 15.1 介绍机器学习（15.1.1 什么是
// 机器学习 / 15.1.2 监督式学习 / 15.1.3 非监督式学习 / 15.1.4 强化学习）、15.2 Core-ML
// 整合机器学习到 iOS 应用中（15.2.1 什么是 Core-ML / 15.2.2 Core-ML 能做什么 /
// 15.2.3 如何识别图像并反馈结果 / 15.2.4 判断图片中的食物）。实战项目叫 SeeFood：
// 拍一张照片，问模型「这是热狗吗」。
//
// 原书那条流水线是：
//   15.2.1 「我们将会把预先训练好的数据模型转换到 .mlmodel 文件之中，它是一个完全的开放的
//          文件格式，并且包含了所有的输入输出」；Core-ML 允许两件事 —— 载入一个预先训练好
//          的模型（并把它转换成一个能在 Xcode 里使用的类），以及在设备上用它「做一个断言
//          （Predication）」；
//   15.2.2 从 developer.apple.com/machine-learning 下载 Inception v3，把 .mlmodel 拖进工程，
//          「在项目导航中单击该文件以后……Xcode 已经为该模型创建了一个 Model Class」；
//          然后 UIImagePickerController 拍照、Info.plist 加 Privacy - Camera Usage
//          Description，否则「应用程序会发生崩溃……reason：'Source type 1 not available'」；
//   15.2.3 「我们需要将从照片获取器得到的 UIImage 对象转换为 CIImage 对象，因为在使用
//          Vision 和 Core-ML 框架中的方法时，必须要用这种特定类型」，然后三行：
//            guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else { … }
//            let request = VNCoreMLRequest(model: model) { (request, error) in
//                guard let results = request.results as? [VNClassificationObservation] …
//            }
//            let handler = VNImageRequestHandler(ciImage: image); try! handler.perform([request])
//   15.2.4 「获取其中的第一个元素……第一个元素所提供的信息是相似度最高的」，
//            if firstResult.identifier.contains("hotdog") { 标题写「热狗！」 }。
//
// 本机跑不动其中三处：**没有 Xcode 工程**（本仓库每条示例只是一次 swiftc 调用 +
// `xcrun simctl spawn`，见 run-all.sh），所以「拖进去自动出现的 Model Class」没人替你生成；
// **不联网**，所以那个几十兆的 Inception v3 下载不下来；**模拟器没有摄像头**，所以
// UIImagePickerController 那半条路在 §15 只能量成三个布尔值。
//
// 但这一章的核心其实一句话就能保住：**Core ML 吃的是磁盘上一份 protobuf，模型类只是那段
// protobuf 的 Swift 语法糖**。于是本机改成：
//   .mlmodel 从网上下载        → §1 在 Swift 里**逐字节手写**出来（46 个字节，附 hex 和
//                                一份自带的 wire 解码器，把「完全的开放的文件格式」这句
//                                话当场翻开给看）
//   Xcode 替你生成 Model Class  → §5 用同一条 `coremlcompiler generate --language Swift`
//                                生成，产物就是本目录里的 tiny_scaler.swift（原样提交，
//                                一行没改），然后真的用它跑一次断言
//   载入模型                    → §2/§3/§4 三种入口各自的边界：MLModel.compileModel(at:)、
//                                直接喂 .mlmodel 会怎样、以及 iOS 16 起那条连临时文件都不
//                                用的 MLModelAsset(specification: Data)
//   Inception v3 那种真分类器   → §13/§14 系统分区里躺着的那份 26 881 字节的真模型（只读复用），
//                                「第一名」的判决从它的概率字典里取
//   UIImage → CIImage → Vision  → §11/§12 一张自己用 UIGraphicsImageRenderer 画的三色图，
//                                走书本那三行的同一条通路
//
// 最锋利的一条发现是 §12：书本那句 `request.results as? [VNClassificationObservation]`
// 的 guard-else 并不是「以防万一」。模型不是分类器时，Vision 在执行请求的那一刻就直接把
// 一句 `Failed to create espresso context.` 摔在 error 里 —— 原书靠「跑起来看一眼」略过了
// 这一格，本章把它量成一行可断言的原文。
// ============================================================

import AVFoundation
import CoreImage
import CoreML
import CoreVideo
import Foundation
import UIKit
import Vision

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func section(_ n: Int, _ title: String) { print("\n== §\(n) \(title) ==") }

// ============================================================
// 一、最小 protobuf 编码器：只干「把字段号和字节拼起来」这一件事
// ============================================================
// .mlmodel 不是 Apple 的私有格式，它就是一份 protobuf（Protocol Buffers）序列化出来的字节。
// protobuf 的二进制规则小得惊人，每条字段只写三样东西：
//   1) tag = (字段号 << 3) | 线型（wire type），本身用 varint 编码；
//   2) 线型 0：一个 varint 整数（枚举、int32/int64/bool 都走这里）；
//   3) 线型 1：8 个字节（double 定长小端）；
//   4) 线型 2：先一个 varint 说「后面有多少字节」，再紧跟那堆字节 —— 字符串、字节数组、
//      以及**嵌套消息**全都用它（消息套消息就是 LEN 前面再套一层 LEN）。
// varint 就是「每字节低 7 位是数据，最高位说还要不要继续读下一字节」，所以 1 个字节写 0…127，
// 两个字节写 128…16383，以此类推。字段号是**规格里定的**，跟名字没有关系 —— 名字只存在于
// .proto 那份 schema 里；而 schema 在本机一个字节都拿不到（没有 coremltools，也不联网）。
// 于是本章所有字段号都只能来自两处：苹果自己的真模型（用 §1 那个解码器读出来的树），
// 以及 coremlcompiler 校验器摔回来的那句原话。下面每一个字段号旁边都标了它是哪一处来的。
typealias Bytes = [UInt8]

enum PB {
    /// varint：每字节存 7 位，最高位是「后面还有」的续读标志
    static func varint(_ n: Int) -> Bytes {
        var v = n, out: Bytes = []
        while true {
            let b = UInt8(v & 0x7F); v >>= 7
            out.append(b | (v == 0 ? 0 : 0x80))
            if v == 0 { return out }
        }
    }
    /// tag：字段号左移 3 位，再并上线型
    static func tag(_ field: Int, _ wire: Int) -> Bytes { varint((field << 3) | wire) }
    /// 线型 0 的字段：一个 varint
    static func vint(_ field: Int, _ n: Int) -> Bytes { tag(field, 0) + varint(n) }
    /// 线型 2 的字段：字符串
    static func text(_ field: Int, _ s: String) -> Bytes {
        let b = Bytes(s.utf8); return tag(field, 2) + varint(b.count) + b
    }
    /// 线型 2 的字段：嵌套消息（先写长度，再写内容）
    static func msg(_ field: Int, _ body: Bytes) -> Bytes {
        tag(field, 2) + varint(body.count) + body
    }
    /// 线型 1 的字段：8 字节小端 double
    static func dbl(_ field: Int, _ x: Double) -> Bytes {
        var bits = x.bitPattern
        var out = tag(field, 1)
        withUnsafeBytes(of: &bits) { out.append(contentsOf: Bytes($0)) }
        return out
    }
    /// repeated 标量：proto3 默认打包成一坨放在同一个 LEN 里
    static func packedInts(_ field: Int, _ vals: [Int]) -> Bytes {
        let body = vals.flatMap { varint($0) }
        return tag(field, 2) + varint(body.count) + body
    }
}

// ------------------------------------------------------------- 特征类型 --
// FeatureDescription{1 name, 2 shortDescription, 3 type}；type 那个 FeatureType 是个 oneof，
// 每个成员占一个字段号，而这些号是从真模型的 wire 树里读出来的：
//   1 = 整型（Int64FeatureType，空消息）、2 = 双精度（DoubleFeatureType，空消息）、
//   3 = 字符串、4 = 图像、5 = 数组、6 = 字典。
// 「空消息」不是占位：oneof 靠**这个字段号出现过没有**来表示类型，所以里面一个字节都不必有。
func ftDouble() -> Bytes { PB.msg(3, PB.msg(2, Bytes())) }
func ftInt64() -> Bytes { PB.msg(3, PB.msg(1, Bytes())) }
func ftString() -> Bytes { PB.msg(3, PB.msg(3, Bytes())) }
/// 图像：ImageFeatureType{1 width, 2 height, 3 colorspace}；色空间 10 灰度 / 20 RGB / 30 BGR，
/// 但运行时读回来是 'BGRA' 那个 FourCharCode —— 见 §9。
func ftImage(_ w: Int, _ h: Int, _ cs: Int = 20) -> Bytes {
    PB.msg(3, PB.msg(4, PB.vint(1, w) + PB.vint(2, h) + PB.vint(3, cs)))
}
/// 数组：MultiArrayFeatureType{1 **打包的** shape, 2 dataType}
/// dataType 用的是 MLMultiArrayDataType 那套号：双精度 65600、float32 65568、float16 65552、
/// int32 131104 —— 与 §8 从约束里读回来的 rawValue 同一个数。
func ftMultiArray(_ shape: [Int], _ dtype: Int = 65568) -> Bytes {
    PB.msg(3, PB.msg(5, PB.packedInts(1, shape) + PB.vint(2, dtype)))
}
func feature(_ name: String, _ type: Bytes) -> Bytes { PB.text(1, name) + type }

/// Model{1 specVersion, 2 ModelDescription{1 输入…, 10 输出…, 11 predictedFeatureName}}
/// 再挂一个「模型参数」字段：号由模型种类决定（scaler 604、神经网络 500、GLM 回归 300……）。
/// ModelDescription 里输入是 repeated 的字段 1、输出是 repeated 的字段 10 ——
/// 也就是说「哪个是输入哪个是输出」全写在文件里，App 代码里没有第二份表。
func modelSpec(inputs: [(String, Bytes)], outputs: [(String, Bytes)],
               predicted: String?, paramsField: Int, params: Bytes,
               specVersion: Int = 1) -> Bytes {
    var d: Bytes = []
    for (n, t) in inputs { d += PB.msg(1, feature(n, t)) }
    for (n, t) in outputs { d += PB.msg(10, feature(n, t)) }
    if let p = predicted { d += PB.text(11, p) }
    return PB.vint(1, specVersion) + PB.msg(2, d) + PB.msg(paramsField, params)
}

// ============================================================
// 二、最小 wire 解码器：不带 schema，只按 (字段号, 线型) 把字节读成树
// ============================================================
// 这就是本章读苹果真模型用的那件工具（独立取证版见探针 g01），差别是它现在写在示例**里面**：
// 于是「46 个字节」这句话不用信任何人，程序自己把它读回给自己听。
enum Wire {
    static func varint(_ buf: Bytes, _ i: Int) -> (Int, Int)? {
        var val = 0, shift = 0, j = i
        while true {
            if j >= buf.count { return nil }
            let b = buf[j]; j += 1
            val |= Int(b & 0x7F) << shift
            if b & 0x80 == 0 { return (val, j) }
            shift += 7
            if shift > 63 { return nil }
        }
    }
    /// 整段恰好按消息规则走完，才算一份嵌套消息（否则就是一坨二进制数据）
    static func parses(_ buf: Bytes) -> Bool {
        if buf.isEmpty { return false }
        var i = 0
        while i < buf.count {
            guard let (t, j) = varint(buf, i) else { return false }
            i = j
            let f = t >> 3, wt = t & 7
            if f < 1 || wt > 5 { return false }
            if wt == 0 {
                guard let (_, k) = varint(buf, i) else { return false }
                i = k
            } else if wt == 2 {
                guard let (ln, k) = varint(buf, i), k + ln <= buf.count else { return false }
                i = k + ln
            } else if wt == 5 { i += 4 } else if wt == 1 { i += 8 } else { return false }
        }
        return i == buf.count
    }
    static func printable(_ buf: Bytes) -> Bool {
        !buf.isEmpty && buf.allSatisfy { $0 >= 32 && $0 < 127 }
    }
    static func walk(_ buf: Bytes, _ depth: Int, _ out: inout [String]) {
        var i = 0
        let pad = String(repeating: "  ", count: depth)
        while i < buf.count {
            guard let (t, j) = varint(buf, i) else { return }
            i = j
            let f = t >> 3, wt = t & 7
            if wt == 0 {
                guard let (v, k) = varint(buf, i) else { return }
                i = k
                out.append("\(pad)f\(f) varint \(v)")
            } else if wt == 2 {
                guard let (ln, k) = varint(buf, i) else { return }
                i = k
                let sub = Array(buf[i..<min(i + ln, buf.count)])
                i += ln
                if printable(sub) {
                    out.append("\(pad)f\(f) str \"\(String(decoding: sub, as: UTF8.self))\"")
                } else if parses(sub) {
                    out.append("\(pad)f\(f) msg len=\(ln)")
                    walk(sub, depth + 1, &out)
                } else {
                    out.append("\(pad)f\(f) bytes len=\(ln) " +
                               sub.prefix(8).map { String(format: "%02x", $0) }.joined())
                }
            } else if wt == 1 {
                let raw = Array(buf[i..<i + 8]); i += 8
                // 8 个字节按小端拼成 UInt64（第一个字节是最低位），再让 Double 用同一串位模式
                // 解释 —— 不能在这里 load(as: Double.self)：字节流的对齐没有保证。
                var bits: UInt64 = 0
                for (k, b) in raw.enumerated() { bits |= UInt64(b) << (8 * k) }
                out.append("\(pad)f\(f) double \(Double(bitPattern: bits)) [" +
                           raw.map { String(format: "%02x", $0) }.joined() + "]")
            } else if wt == 5 {
                i += 4
                out.append("\(pad)f\(f) fixed32")
            } else {
                out.append("\(pad)f\(f) 线型 \(wt) —— protobuf 里已经没有这一档"); return
            }
        }
    }
}

func hex(_ b: Bytes) -> String { b.map { String(format: "%02x", $0) }.joined() }

// FourCharCode：一个大端拼出来的 32 位整数，四个 ASCII 码各占一字节（'BGRA' 就是 0x42475241）。
func fourCC(_ v: UInt32) -> String {
    let b: [UInt8] = [UInt8(truncatingIfNeeded: v >> 24), UInt8(truncatingIfNeeded: v >> 16),
                      UInt8(truncatingIfNeeded: v >> 8), UInt8(truncatingIfNeeded: v)]
    return String(bytes: b, encoding: .ascii) ?? "?"
}

// 错误原文的通用切法：Core ML 的错误喜欢把「模型在第几层、文件在哪」写进第二行以后，
// 而第一行才是那句判定用的话；另外**绝对路径会带模拟器容器的 UUID**，那是每台机器都不同
// 的东西，六条判定里的「debug 与 release 逐字节一致」它扛不住，所以一律只留句子。
func firstLine(_ s: String) -> String { s.split(separator: "\n").first.map(String.init) ?? s }
func errDesc(_ e: Error) -> String { (e as NSError).localizedDescription }
func errDomain(_ e: Error) -> String { (e as NSError).domain }
func errCode(_ e: Error) -> Int { (e as NSError).code }

// ============================================================
// 三、工作区：模型的字节、临时文件、编译产物
// ============================================================
let fm = FileManager.default
let work = fm.temporaryDirectory.appendingPathComponent("ch34")
try? fm.removeItem(at: work)
try! fm.createDirectory(at: work, withIntermediateDirectories: true)

/// 把一段规格字节落成一份 .mlmodel（名字就是扩展名，Core ML 只认这个扩展名）
func emit(_ bytes: Bytes, _ name: String) -> URL {
    let url = work.appendingPathComponent(name + ".mlmodel")
    try! Data(bytes).write(to: url)
    return url
}
/// 规格字节 -> 可直接载入的 .mlmodelc 目录
func compileToModel(_ bytes: Bytes, _ name: String) throws -> MLModel {
    try MLModel(contentsOf: MLModel.compileModel(at: emit(bytes, name)))
}
/// 名字→值那张表。**它会把名字拼错、类型对不上这类问题在构造那一刻就抛出来**（throws），
/// 而模型自己的描述才是那张表的 schema —— 见 §17 那四条宽容与严格。
func inputDict(_ pairs: [String: MLFeatureValue]) throws -> MLDictionaryFeatureProvider {
    try MLDictionaryFeatureProvider(dictionary: pairs)
}
/// iOS 16 起那条「内存里的规格字节 -> 模型」的异步路（load(asset:) 只有 async 版）
@available(iOS 16.0, *)
func loadFromAsset(_ asset: MLModelAsset) async throws -> MLModel {
    try await MLModel.load(asset: asset, configuration: MLModelConfiguration())
}
/// 编译产物目录里某个文件的字节数
func artifactSize(_ dir: URL, _ name: String) -> Int {
    (try? Data(contentsOf: dir.appendingPathComponent(name)).count) ?? -1
}

// scaler 那份 46 字节的规格：一个 double 进、一个 double 出，模型参数是 scaler（字段号 604），
// 里面两个 double —— 它们的**含义**不靠猜：§5 用四个组合物理量把公式反推出来。
func scalerSpec(offset: Double, scale: Double) -> Bytes {
    modelSpec(inputs: [("x", ftDouble())], outputs: [("y", ftDouble())], predicted: "y",
              paramsField: 604, params: PB.dbl(1, offset) + PB.dbl(2, scale))
}

// ============================================================
// §1 一个模型文件就是 46 个字节，而且它「完全的开放」
// ============================================================
section(1, "一个 .mlmodel 就是 46 个字节：写出来，再读回来")
let tiny = scalerSpec(offset: 10.0, scale: 2.0)
expect(tiny.count == 46, "手写规格 \(tiny.count) 个字节，一个字节不多：模型 = 规格版本 + 输入输出表 + 一个 scaler")
line("hex: " + hex(tiny))
var tree: [String] = []
Wire.walk(tiny, 0, &tree)
for t in tree { line("  " + t) }
expect(tree.first == "f1 varint 1", "第一行是 f1 varint 1 —— Model 的字段 1 就是 specificationVersion")
expect(tree.contains("    f1 str \"x\""), "输入的名字就躺在描述里（这里读回来是字符串 \"x\"）")
expect(tree.contains("  f1 double 10.0 [0000000000002440]"), "scaler 的第一个 double 是 10.0，8 字节小端，规格里没有 .proto 也能读出来")
line("  说明：oneof 的类型成员（上面那个 f2/f3 msg len=0）里一个字节都没有 —— 光看字节分不清是 double 还是 int64，")
line("        字段号到名字的映射只存在于 .proto 那份 schema 里；本机拿不到 schema，所以下面每一个号都是读真模型或读校验器原话得来的。")

// ============================================================
// §2 Core ML 收下这段字节：compileModel(at:) 与它吐出来的东西
// ============================================================
section(2, "MLModel.compileModel(at:)：把 .mlmodel 换成能载入的 .mlmodelc")
let tinyURL = emit(tiny, "tiny_scaler")
let compiledURL = try MLModel.compileModel(at: tinyURL)
let compiledEntries = (try? fm.contentsOfDirectory(atPath: compiledURL.path).sorted()) ?? []
expect(compiledEntries == ["analytics", "coremldata.bin"],
       "编译产物只有两样东西：\(compiledEntries.joined(separator: ", "))")
expect(compiledURL.path.hasSuffix(".mlmodelc"), "产物目录的后缀是 .mlmodelc —— 拖进 Xcode 时那个「自动编译」干的就是这一步")
let coreMLDataSize = artifactSize(compiledURL, "coremldata.bin")
expect(coreMLDataSize > 0, "coremldata.bin \(coreMLDataSize) 个字节，比 46 字节的规格大 —— 编译期把「规格」换成了「引擎能执行的计划」")
line("  这一步在 Xcode 里是点 Build 时偷偷做的；命令行上它就是 `xcrun coremlcompiler compile 模型.mlmodel 输出目录`，")
line("  而在**设备上**它是一条公开的类方法：MLModel.compileModel(at:)。本章全程用后者，所以一个字节都不用提交进仓库。")

// ============================================================
// §3 那 46 个字节本身是不能直接载入的
// ============================================================
section(3, "载入只吃 .mlmodelc：把 .mlmodel 直接递过去会怎样")
do {
    _ = try MLModel(contentsOf: tinyURL)
    expect(false, "裸 .mlmodel 竟然载入成功了 —— 与本机实测不符")
} catch {
    let d = errDesc(error)
    // 原文里带一句「Compile the model with Xcode or `MLModel.compileModel(at:)`」，
    // 前半截是模拟器的容器绝对路径（每台机器不一样），所以这里只留判断句、打印长度而不打印路径。
    expect(d.contains("Compile the model with Xcode") && d.contains("compileModel"),
           "错误原话直接告诉你缺了哪一步：\(firstLine(String(d.suffix(64))))")
    expect(errDomain(error) == "com.apple.CoreML" && errCode(error) == 0,
           "domain=\(errDomain(error)) code=\(errCode(error)) —— 载入失败是 Core ML 自己报的，不是文件系统")
}

// ============================================================
// §4 第二条入口：连临时文件都不写的 MLModelAsset
// ============================================================
section(4, "MLModelAsset(specification: Data)：规格字节直接在内存里变成模型")
if #available(iOS 16.0, *) {
    do {
        let asset = try MLModelAsset(specification: Data(tiny))
        var result = "任务没跑起来"
        var loaded: MLModel?
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                let m = try await loadFromAsset(asset)
                loaded = m
                result = "输入=\(m.modelDescription.inputDescriptionsByName.keys.sorted())"
            } catch { result = "抛错：\(firstLine(errDesc(error)))" }
            sem.signal()
        }
        sem.wait()
        expect(loaded != nil, "内存里的一段字节就造出了 asset，并且异步 load 成功：\(result)")
        if let m = loaded {
            let y = try m.prediction(from: inputDict(["x": MLFeatureValue(double: 0.5)]))
                .featureValue(for: "y")!.doubleValue
            expect(y == 21.0, "同一段 46 字节走第二条入口，预测照样是 \(y)")
        }
    } catch {
        expect(false, "asset 这条路在本机不通：\(firstLine(errDesc(error)))")
    }
} else {
    line("  跳过：MLModelAsset(specification:) 要 iOS 16 以上，本示例的部署目标是 iOS 15.0")
}

// ============================================================
// §5 书本的「Model Class」：46 字节进去，10 961 字节 Swift 出来
// ============================================================
section(5, "Model Class：同一条规格生成的 tiny_scaler.swift 现在被真的用起来")
// 原书 15.2.2：「在项目导航中单击该文件以后……Xcode 已经为该模型创建了一个 Model Class」。
// 那个类不是魔法：它就是下面这句命令的产物，而这条命令在 Xcode 的工具链里是公开的：
//   xcrun coremlcompiler generate --language Swift tiny_scaler.mlmodel 输出目录
// 生成的 293 行已经原样躺在本目录里（tiny_scaler.swift，一行没改），里面三个类：
//   tiny_scalerInput（有 `var x: Double` 和一个 init(x:)）、tiny_scalerOutput（`var y: Double`
// 从内部 provider 读）、tiny_scaler（`let model: MLModel` + 一堆 init + prediction）。
// 也就是说书本说的「转换成一个类」，转的是**§1 那 46 个字节的输入输出表**：
// 类里每个属性名都是描述里那两个字，一个字都不多。
// 「46 字节进去、10 961 字节 Swift 出来」是编译期的事实：源码文件不会被打进运行时的
// Bundle，所以这里只能对生成出来的类做断言，字节数取证见探针 a01。
let scaler = try tiny_scaler(contentsOf: compiledURL)
line("  这份规格的输入字节数：\(tiny.count)（生成物的字节数见探针 a01，它是主机上的编译期事实）")
let genInputNames = Array(tiny_scalerInput(x: 0.5).featureNames).sorted()
expect(genInputNames == ["x"],
       "生成类的输入表里只有 \(genInputNames) —— 属性名就是 §1 描述里那个字")
let genModelType = String(describing: type(of: scaler.model))
// 生成类里那一行声明是 `let model: MLModel`，但运行时真正装进去的对象是它的私有子类
// （这台机器上是 MLDelegateModel）—— 声明类型与运行类型不是一回事，正是第 27 章讲的那件事。
expect(genModelType.hasSuffix("Model"),
       "生成类内部那个 `let model: MLModel` 运行时给的是 \(genModelType) —— 声明是 MLModel，实际是它的私有子类；语法糖下面还是 §4 那台引擎")
line("  offset scale   x      y        期望的 (x+offset)*scale")
for (o, k) in [(0.0, 1.0), (10.0, 1.0), (0.0, 2.0), (10.0, 2.0)] {
    let m = try MLModel(contentsOf: MLModel.compileModel(at: emit(scalerSpec(offset: o, scale: k), "sc")))
    let y = try m.prediction(from: inputDict(["x": MLFeatureValue(double: 0.5)]))
        .featureValue(for: "y")!.doubleValue
    let want = (0.5 + o) * k
    expect(y == want, "offset=\(o) scale=\(k) x=0.5 -> y=\(y)  与 \(want) 相等")
}
let one = try scaler.prediction(x: 0.5)
expect(one.y == 21.0, "书本那句「使用模型去做断言」在代码里就是这么一行：scaler.prediction(x: 0.5).y = \(one.y)")

// ============================================================
// §6 批量断言：一次喂进去好几条「训练样本」
// ============================================================
section(6, "predictions(inputs:)：三行输入一次跑完")
// 书本一次只拍一张照片，所以它只需要一个 prediction。但 API 里一直有批量的那一半
// （`MLModel` 上的 predictionsFromBatch，iOS 12 起；类里就是生成的 predictions(inputs:)）。
// 「一堆样本」正是 15.1.2 说监督式学习时的那个东西：一次给很多带标签的样本。
let inputs = [tiny_scalerInput(x: 0.0), tiny_scalerInput(x: 0.5), tiny_scalerInput(x: 10.0)]
let outs = try scaler.predictions(inputs: inputs)
expect(outs.count == 3, "三条输入 -> \(outs.count) 条输出")
let ys = outs.map { $0.y }
expect(ys == [20.0, 21.0, 40.0], "批量结果 = \(ys)（还是同一个 (x+10)*2）")
let batch = MLArrayBatchProvider(array: inputs)
expect(batch.count == 3, "批量提供器自己数出 \(batch.count) 条 —— 它就是那批「样本」的容器")

// ============================================================
// §7 不要类也能跑：描述自省
// ============================================================
section(7, "modelDescription：输入输出表在运行时读回来")
let bare = try MLModel(contentsOf: compiledURL)
let desc = bare.modelDescription
expect(desc.inputDescriptionsByName.keys.sorted() == ["x"], "输入名读回来是 \(desc.inputDescriptionsByName.keys.sorted())")
expect(desc.outputDescriptionsByName.keys.sorted() == ["y"], "输出名读回来是 \(desc.outputDescriptionsByName.keys.sorted())")
expect(desc.predictedFeatureName == "y", "predictedFeatureName=\(desc.predictedFeatureName ?? "nil") —— §1 那个 f11 就是它")
let xd = desc.inputDescriptionsByName["x"]!
expect(xd.type == .double, "x 的类型 \(xd.type.rawValue) 就是 FeatureType 的 oneof 成员号")
expect(!xd.isOptional, "x 不是可选特征（规格里没写可选标记），所以少喂一个就报错 —— 见 §17")
expect(xd.name == "x", "name 读回来就是 \(xd.name) —— MLFeatureDescription 上只有 name/type/可选标记和三个约束，没有别处可藏信息")
expect(xd.multiArrayConstraint == nil && xd.imageConstraint == nil && xd.dictionaryConstraint == nil,
       "三个约束全是 nil：一个 double 特征不需要任何约束对象")
line("  类型号对照（MLFeatureType）：0 invalid / 1 int64 / 2 double / 3 string / 4 image / 5 multiArray / 6 dictionary / 7 sequence / 8 state")

// ============================================================
// §8 张量：形状和元素类型也写在文件里
// ============================================================
section(8, "多维数组特征：shape 与 dataType 是读出来的，不是代码里规定的")
// MultiArrayFeatureType{1 打包的 shape, 2 dataType}。这里给一个长度 6 的 float32 数组，
// 模型参数还是那个 scaler（所以它把每个元素各自加 10 再乘 2）。
let tensorSpec = modelSpec(inputs: [("m", ftMultiArray([6]))], outputs: [("o", ftMultiArray([6]))],
                           predicted: "o", paramsField: 604, params: PB.dbl(1, 10.0) + PB.dbl(2, 2.0))
let tModel = try compileToModel(tensorSpec, "tensor")
let c = tModel.modelDescription.inputDescriptionsByName["m"]!.multiArrayConstraint!
expect(c.shape.map { $0.intValue } == [6], "shape 读回来 \(c.shape.map { $0.intValue })")
expect(c.dataType.rawValue == 65568, "dataType rawValue \(c.dataType.rawValue) == float32（MLMultiArrayDataType 那一套号）")
expect(String(describing: c) == "Float32, 6", "约束对象自己的描述是「\(c)」—— 类型在前，形状在后")
let arr = try MLMultiArray(shape: c.shape, dataType: c.dataType)
for i in 0..<arr.count { arr[i] = NSNumber(value: Float32(i % 7) / 7.0) }
let tOut = try tModel.prediction(from: inputDict(["m": MLFeatureValue(multiArray: arr)]))
let ro = tOut.featureValue(for: "o")!.multiArrayValue!
expect(ro.shape.map { $0.intValue } == [6], "输出形状 \(ro.shape.map { $0.intValue })")
let elems = (0..<ro.count).map { ro[$0].doubleValue }
line("  输入 = 0, 1/7, 2/7, …, 5/7（float32）")
expect(elems.first == 20.0, "第一个元素 \(elems.first!) —— 加 10 再乘 2")
expect(elems.count == 6, "六个元素：\(elems)")
line("  后五个的小数尾巴（20.28571429848671 而不是 20.285714285714285）就是 float32 的精度痕迹：")
line("  2/7 这种数在 float32 里存不精确，被读成 double 之后尾巴就露出来了。")

// ============================================================
// §9 手写一层神经网络：图像进、图像出
// ============================================================
section(9, " NeuralNetwork：LayerParams 的字段号 130 是 activation")
// 神经网络在规格里是一个**层的列表**：NeuralNetwork{1 重复的 LayerParams}，
// 而 LayerParams{1 name, 2 input, 3 output, <oneof 层类型>}。
// 层类型的号也是读真模型 + 校验器原话得来的：100 convolution、120 pool、130 activation、
// 160 normalize、210 upsample、230/245 elementwise。activation 里面又是一个 oneof，
// 成员号 10 = RELU（空消息）。这里就一层：拿 §1 那张 2x2 的图做一次 RELU。
func layerParams(_ name: String, _ input: String, _ output: String, _ kindField: Int, _ body: Bytes = Bytes()) -> Bytes {
    PB.msg(1, PB.text(1, name) + PB.text(2, input) + PB.text(3, output) + PB.msg(kindField, body))
}
let nnSpec = modelSpec(inputs: [("image", ftImage(2, 2))], outputs: [("out1", ftImage(2, 2))],
                       predicted: nil, paramsField: 500,
                       params: layerParams("act0", "image", "out1", 130, PB.msg(10, Bytes())))
expect(nnSpec.count == 70, "一层 RELU 的完整模型 \(nnSpec.count) 个字节")
var nnTree: [String] = []
Wire.walk(nnSpec, 0, &nnTree)
line("  字段树里和「层」有关的那几行：")
for t in nnTree where t.contains("act0") || t.contains("image") || t.contains("out1") || t.hasPrefix("f500") {
    line("    " + t)
}
let nnURL = emit(nnSpec, "nn")
let nnCompiled = try MLModel.compileModel(at: nnURL)
let nn = try MLModel(contentsOf: nnCompiled)
let ic = nn.modelDescription.inputDescriptionsByName["image"]!.imageConstraint!
expect(ic.pixelsWide == 2 && ic.pixelsHigh == 2, "图像约束读回来 \(ic.pixelsWide)x\(ic.pixelsHigh)")
expect(fourCC(ic.pixelFormatType) == "BGRA", "色空间规格里写的是 20（RGB 一族），运行时读回来是 FourCharCode \(ic.pixelFormatType) == \"\(fourCC(ic.pixelFormatType))\"")
expect(ic.sizeConstraint.type == .enumerated, "尺寸约束类型 rawValue=\(ic.sizeConstraint.type.rawValue)（0 任意 / 2 枚举 / 3 范围）")
expect(ic.sizeConstraint.enumeratedImageSizes.count == 1, "枚举尺寸 \(ic.sizeConstraint.enumeratedImageSizes.count) 个")
line("  pixelsWideRange 是 NSRange：location=\(ic.sizeConstraint.pixelsWideRange.location) length=\(ic.sizeConstraint.pixelsWideRange.length) —— 枚举型约束下面这个范围没用，别拿它当尺寸读。")

// ============================================================
// §10 结构自省：只有编译产物有这一层
// ============================================================
section(10, "MLModelStructure：把层的名字、类型、进出张量读回来")
var rows: [String] = []
if #available(iOS 17.4, *) {
    let sem = DispatchSemaphore(value: 0)
    var loadErr = ""
    // 注意这里喂的是 **编译产物目录**（.mlmodelc）。喂 §1 那份 .mlmodel 源文件不会抛错，
    // 而是当场 abort（signal 6）：它内部按 .mlmodelc 的结构去开 coremldata.bin，
    // 打不开就抛一个 C++ 异常，Swift 的 try/catch 接不住。见探针 r01。
    __MLModelStructure.loadContents(of: nnCompiled) { st, err in
        if let layers = st?.neuralNetwork?.layers {
            rows = layers.map { "name=\($0.name) type=\($0.type) in=\($0.inputNames) out=\($0.outputNames)" }
        } else if let err = err { loadErr = firstLine(errDesc(err)) }
        sem.signal()
    }
    sem.wait()
    expect(rows.count == 1, "读到 \(rows.count) 层：\(rows.joined(separator: " ; "))")
    expect(rows.first?.contains("type=activation") == true, "层类型读回来是字符串 \"activation\"，不是枚举 —— 所以规格里那个 130 只能来自真模型")
    expect(loadErr.isEmpty, "没有报错")
} else {
    line("  跳过：MLModelStructure 要 iOS 17.4，本示例部署目标 iOS 15.0")
}

// ============================================================
// §11 书本那三行 Vision 通路：UIImage → CIImage → 请求 → 观察结果
// ============================================================
section(11, "Vision：一张自己画的图，走书本 15.2.3 那条通路")
// 原书这里从 UIImagePickerController 拿一张照片；模拟器没有摄像头（§15），
// 所以输入图像改用第 29 章那套 Quartz 2D 直接画：四个色块，240pt，scale 3。
// 关键还是那句「必须要用 CIImage 这种特定类型」，于是画完先转 CIImage 再交给 handler。
let photo = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 240)).image { rc in
    let ctx = rc.cgContext
    ctx.setFillColor(UIColor.red.cgColor);   ctx.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
    ctx.setFillColor(UIColor.green.cgColor); ctx.fill(CGRect(x: 120, y: 0, width: 120, height: 120))
    ctx.setFillColor(UIColor.blue.cgColor);  ctx.fill(CGRect(x: 0, y: 120, width: 120, height: 120))
    ctx.setFillColor(UIColor.white.cgColor); ctx.fill(CGRect(x: 120, y: 120, width: 120, height: 120))
}
let ciImage = CIImage(image: photo)
expect(ciImage != nil, "UIImage -> CIImage 这一步和原书一样：guard let ciimage = CIImage(image: …)")
expect(ciImage!.extent.size == CGSize(width: 720, height: 720),
       "点尺寸 \(photo.size) × scale \(photo.scale) = 像素 \(Int(ciImage!.extent.width))x\(Int(ciImage!.extent.height)) —— 模型说的是像素，不是点")
let vnModel = try VNCoreMLModel(for: nn)
let request = VNCoreMLRequest(model: vnModel)
let handler = VNImageRequestHandler(ciImage: ciImage!, options: [:])
try handler.perform([request])
let observations = request.results ?? []
expect(observations.count == 1, "书本那个 request.results 有 \(observations.count) 条")
expect(String(describing: type(of: observations[0])) == "VNPixelBufferObservation",
       "它的实际类型是 \(type(of: observations[0]))，不是 VNClassificationObservation")
let pbObs = observations[0] as! VNPixelBufferObservation
let pb = pbObs.pixelBuffer
let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb)
let bpr = CVPixelBufferGetBytesPerRow(pb), size = CVPixelBufferGetDataSize(pb)
expect(w == 2 && h == 2, "输出缓冲 \(w)x\(h) —— 模型的输出图像多大，观察结果就多大")
expect(fourCC(CVPixelBufferGetPixelFormatType(pb)) == "BGRA", "像素格式 \(fourCC(CVPixelBufferGetPixelFormatType(pb)))")
CVPixelBufferLockBaseAddress(pb, .readOnly)
let base = CVPixelBufferGetBaseAddress(pb)!
let raw = base.bindMemory(to: UInt8.self, capacity: size)
var byteSum = 0
for i in 0..<size { byteSum += Int(raw[i]) }
CVPixelBufferUnlockBaseAddress(pb, .readOnly)
expect(size == bpr * h, "数据 \(size) 个字节 = bytesPerRow \(bpr) × 高 \(h) —— 行是按 16 字节对齐铺的，不是 2×4")
expect(observations[0].confidence == 1.0, "confidence=\(observations[0].confidence)：图像观察结果没有「把握」这回事，它永远是 1")
line("  整块缓冲的字节和 = \(byteSum)（四个色块被缩到 2x2 之后的像素值全都落在这里，可复现，所以敢断言）")

// ============================================================
// §12 guard 那一行不是「以防万一」：模型不是分类器时
// ============================================================
section(12, "原书那句 `as? [VNClassificationObservation]` 的 guard 到底在挡什么")
// 15.2.3 里那段闭包是：
//   guard let results = request.results as? [VNClassificationObservation] else { fatalError("模型处理图像失败") }
// 原书从来没让它进过 else 分支（它用的是真分类器）。本机手写不出一个能过校验器的分类器
// （§17 把那三段原话贴全），所以 else 分支第一次真的被走到 —— 走到它有两种方式：
// (a) 类型不对：结果实际是 VNPixelBufferObservation，`as?` 直接给 nil（§11 已经量到）；
// (b) 用 Vision 自己的分类请求：它要求模型带分类头，于是**执行请求的那一刻**就失败。
let asClassifications = request.results as? [VNClassificationObservation]
expect(asClassifications == nil, "(a) 书本那个 `request.results as? [VNClassificationObservation]` 在这里给 nil —— 它的 fatalError 就是从这一步来的")
let classifyRequest = VNClassifyImageRequest()
do {
    try VNImageRequestHandler(ciImage: ciImage!, options: [:]).perform([classifyRequest])
    expect(false, "(b) 分类请求跑通了，与本机实测不符")
} catch {
    expect(errDomain(error) == "NSOSStatusErrorDomain",
           "(b) 分类请求被拒：domain=\(errDomain(error)) code=\(errCode(error))")
    line("     原文：\(firstLine(errDesc(error)))")
}
expect(request.results is [VNPixelBufferObservation], "同一条通路、同一张图，换个模型类型就换个观察结果类型 —— 「图像识别」四个字在 API 里其实是两件不同的事")

// ============================================================
// §13 系统里躺着现成的模型：书本那句「即插即用」在本机的对应物
// ============================================================
section(13, "只读复用一份真模型：26 881 个字节的决策树分类器")
// 原书 15.2.1 让人去 developer.apple.com 下 Inception v3。本机不联网，但**操作系统自带**
// 一批训练好的 .mlmodel（PowerUI 那份是电池行为的决策树模型，只有 26 KB，所以敢在示例里真跑）。
// 这条路径证明的不是「苹果有模型」，而是书本那句「载入一个预先训练好的模型」的本来面目：
// 载入 = 读一段字节；训练好的东西全在字节里，App 代码一行都不带。
let realURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/Resources/assets_251/shallow_model.mlmodel")
expect(fm.fileExists(atPath: realURL.path), "系统分区里那份模型在场，扩展名照样是 .mlmodel")
let realBytes = (try? Data(contentsOf: realURL).count) ?? -1
expect(realBytes == 26_881, "它 \(realBytes) 个字节 —— 比 §1 的 46 字节大五百多倍，但结构一模一样（探针 g01 能把它读成同一棵树）")
let realCompiled = try MLModel.compileModel(at: realURL)
let real = try MLModel(contentsOf: realCompiled)
let rdesc = real.modelDescription
let inputNames = rdesc.inputDescriptionsByName.keys.sorted()
expect(inputNames == ["battery_duration_1", "battery_duration_2", "battery_duration_3",
                      "battery_duration_4", "plugin_battery_level"],
       "五个输入特征：\(inputNames)")
expect(rdesc.predictedFeatureName == "next_discharge_is_shallow",
       "predictedFeatureName=\(rdesc.predictedFeatureName ?? "nil") —— 书本说文件「包含了所有的输入输出」，就是这些名字")
for n in inputNames { expect(rdesc.inputDescriptionsByName[n]!.type == .double, "  \(n) 是 double") }
line("  元数据（模型文件自带的说明书，运行时从描述里读）：")
let metaKeys = rdesc.metadata.keys.map { $0.rawValue }.sorted()
for k in metaKeys {
    let v = rdesc.metadata[MLModelMetadataKey(rawValue: k)]
    if let dict = v as? [String: String] {
        line("    \(k) = " + dict.keys.sorted().map { "\($0)=\(dict[$0]!)" }.joined(separator: ", "))
    } else {
        line("    \(k) = \(firstLine(String(describing: v ?? "（无）")))")
    }
}
expect(metaKeys.contains("MLModelDescriptionKey"), "描述键在场")
expect(rdesc.metadata[MLModelMetadataKey(rawValue: "MLModelDescriptionKey")] as? String == "Shallow model",
       "作者给它写的说明读回来是「\(rdesc.metadata[MLModelMetadataKey(rawValue: "MLModelDescriptionKey")] as? String ?? "nil")」")
let authorMeta = rdesc.metadata[MLModelMetadataKey(rawValue: "MLModelAuthorKey")] as? String
let licenseMeta = rdesc.metadata[MLModelMetadataKey(rawValue: "MLModelLicenseKey")] as? String
expect((authorMeta ?? "").isEmpty && (licenseMeta ?? "").isEmpty,
       "MLModelAuthorKey / MLModelLicenseKey 读回来是空串（\"\(authorMeta ?? "nil")\" /\"\(licenseMeta ?? "nil")\"）：苹果自己的模型也没填这两栏")
expect(rdesc.predictedProbabilitiesName == "classProbability",
       "predictedProbabilitiesName=\(rdesc.predictedProbabilitiesName ?? "nil") —— 书本那个「相似度最高的第一名」，规格里专门留了一个字段说概率表在哪")
let classLabels = (rdesc.classLabels ?? []).map { String(describing: $0) }
expect(classLabels.count == 2, "classLabels 有 \(classLabels.count) 项：\(classLabels) —— 类别名确实写进了文件里")
expect(Set(classLabels).count == 2, "两项不一样，所以「第 0 类」「第 1 类」各有自己的名字：\(classLabels)")
expect(!rdesc.isUpdatable, "isUpdatable=\(rdesc.isUpdatable) —— 设备端只做推断；书本 15.1 那套「不断的训练」不在 Core ML 的运行时代码里")

// ============================================================
// §14 「相似度最高的第一名」：热狗判决在本机的形状
// ============================================================
section(14, "概率字典与第一名")
// 15.2.4 的全部逻辑就两句：取 results.first（相似度最高的那个），看它的 identifier 里
// 有没有 "hotdog"。书本看不到那个数组是怎么排出来的；一份真分类器的概率字典把它摊开了：
// 输出是一个整数标签 next_discharge_is_shallow + 一张 类别序号 -> 概率 的字典。
let cpDesc = rdesc.outputDescriptionsByName["classProbability"]!
expect(cpDesc.type == .dictionary, "classProbability 是字典特征")
expect(cpDesc.dictionaryConstraint?.keyType == .int64, "它的键类型读回来是 int64（rawValue \(cpDesc.dictionaryConstraint?.keyType.rawValue ?? -1)）")
let sample = ["plugin_battery_level": 100.0, "battery_duration_1": 1.0, "battery_duration_2": 1.0,
              "battery_duration_3": 1.0, "battery_duration_4": 1.0]
func verdict(_ dict: [String: Double]) -> (Int64, [Int64: Double]) {
    let out = try! real.prediction(from: inputDict(dict.mapValues { MLFeatureValue(double: $0) }))
    let label = out.featureValue(for: "next_discharge_is_shallow")!.int64Value
    let probs = out.featureValue(for: "classProbability")!.dictionaryValue as! [Int64: Double]
    return (label, probs)
}
let (label0, prob0) = verdict(sample)
let keys = prob0.keys.sorted()
expect(keys == [0, 1], "类别键是 \(keys) —— 两类的分类器")
let sum = keys.reduce(0.0) { $0 + prob0[$1]! }
expect(abs(sum - 1.0) < 1e-12, "概率求和 \(sum) == 1：所谓「相似度」是归一化过的，不是原始得分")
let top = keys.max(by: { prob0[$0]! < prob0[$1]! })!
expect(top == label0, "字典里的第一名 \(top) 与 next_discharge_is_shallow=\(label0) 是同一个 —— 书本那个 results.first 就是它")
line("  第一名 \(top) 的概率 \(prob0[top]!)，第二名 \(keys.first { $0 != top }!) 的概率 \(prob0[keys.first { $0 != top }!]!)")
// 键是整数，而 §13 那张类别名表里存的是「0」「1」两个字符串（这位作者没给类别起名字）。
// 运行时能直接拿到的只有整数序号，名字要自己按序号去查表 —— 书本的 hotdog / nohotdog
// 之所以能直接是字符串，是因为它的模型把 classLabel 那一头声明成了字符串特征。
line("  查 §13 那张表：第 \(top) 类在这里写作「\(classLabels[Int(exactly: top)!])」")
let (label1, prob1) = verdict(["plugin_battery_level": 5.0, "battery_duration_1": 9.0,
                               "battery_duration_2": 9.0, "battery_duration_3": 9.0,
                               "battery_duration_4": 9.0])
expect(abs(prob1.values.reduce(0.0, +) - 1.0) < 1e-12, "换一组输入，概率照样加成 1")
line("  换输入之后：第一名=\(prob1.keys.max(by: { prob1[$0]! < prob1[$1]! })!) 标签=\(label1) 各项=\(prob1.keys.sorted().map { "\($0): \(prob1[$0]!)" })")
expect(label0 == 0, "样本判决「不是浅放电」—— 换到书本的比喻就是一句「不是热狗！」")

// ============================================================
// §15 摄像头那一半在模拟器里：只有三个布尔值
// ============================================================
section(15, "UIImagePickerController 那半条路：原书为什么要「必须运行在真机上」")
// 原书 15.2.2 步骤 6~7：imagePicker.sourceType = .camera，然后 present 出去；
// 它自己也记下了不写权限描述时的崩溃：「reason：'Source type 1 not available'」。
// 那半条路在这里量成三个能力判断 —— 注意是**能力**判断，不是 UI：本仓库从头到尾没有窗口。
let cameraOn = UIImagePickerController.isSourceTypeAvailable(.camera)
let libraryOn = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
let albumOn = UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
expect(!cameraOn, "sourceType = .camera 在模拟器里不可用（\(cameraOn)）—— 那句 'Source type 1 not available' 就是它的崩溃现场")
expect(libraryOn && albumOn, "照片库/已存相册可用（\(libraryOn)/\(albumOn)）—— 原书那条「技巧：把 sourceType 改成 .photoLibrary 就能在模拟器里跑」是真的")
expect(AVCaptureDevice.default(for: .video) == nil, "AVCaptureDevice.default(for: .video) 是 nil")
expect(AVCaptureDevice.DiscoverySession(deviceTypes: [], mediaType: .video, position: .unspecified).devices.isEmpty,
       "枚举出来的视频设备 0 台")
let auth = AVCaptureDevice.authorizationStatus(for: .video)
// 这个枚举的原始值顺序很容易记错：0 未决定 / 1 受限 / 2 拒绝 / 3 已授权。
// 模拟器给的是 2 —— 拒绝，不是「已授权」。书本靠 Info.plist 里那行 Privacy - Camera Usage
// Description 换来的弹窗在模拟器里根本不会出现，因为压根没有摄像头设备可授权。
expect(auth == .denied, "授权状态 rawValue=\(auth.rawValue) == .denied（枚举顺序：0 未决定 / 1 受限 / 2 拒绝 / 3 已授权）—— 模拟器里相机是「被拒绝」的，不是「已授权」")

// ============================================================
// §16 计算设备：GPU/CPU 在场，神经引擎缺席
// ============================================================
section(16, "computeUnits 与 availableComputeDevices：ANE 在模拟器里不存在")
if #available(iOS 17.0, *) {
    let devs = MLModel.availableComputeDevices
    expect(devs.count == 2, "本机可用计算设备 \(devs.count) 个")
    // Swift 侧把两种设备都装进同一个 MLComputeDevice（ObjC 那层的 MLGPUComputeDevice /
    // MLCPUComputeDevice 在 Swift 里 cast 不过去，编译器还会警告「永远失败」），而它的
    // description 里带指针地址 —— 那是每台机器每轮都不同的东西，六条判定扛不住。
    // 于是这里用 Mirror 读它的存储标签：GPU 那个是 "gpu"，CPU 那个是 "cpu"，不含地址。
    let labels = devs.flatMap { Mirror(reflecting: $0).children.compactMap { $0.label } }.sorted()
    expect(labels == ["cpu", "gpu"], "设备标签读回来 \(labels)")
    expect(!labels.contains { $0.lowercased().contains("neural") || $0 == "ne" },
           "里面没有任何「神经引擎」标签 —— 书本反复强调的那块专用电路（Apple Neural Engine）在模拟器里不存在")
} else {
    line("  跳过：availableComputeDevices 要 iOS 17")
}
// 四种 computeUnits 都跑同一份模型，看概率字典是否逐字节一致。
// 这条断言的真正用处不是「模型正确」，而是**这条示例的输出可以既不依赖优化配置、
// 也不依赖跑在哪块芯片上** —— run-all.sh 要比对 debug/release 两份 stdout，靠的就是这个。
var unitProbs: [(String, String)] = []
for (label, unit) in [("cpuOnly", MLComputeUnits.cpuOnly), ("cpuAndGPU", MLComputeUnits.cpuAndGPU),
                      ("all", MLComputeUnits.all)] {
    let cfg = MLModelConfiguration(); cfg.computeUnits = unit
    let m = try MLModel(contentsOf: realCompiled, configuration: cfg)
    let p = try m.prediction(from: inputDict(sample.mapValues { MLFeatureValue(double: $0) }))
    let d = p.featureValue(for: "classProbability")!.dictionaryValue as! [Int64: Double]
    unitProbs.append((label, d.keys.sorted().map { "\($0): \(d[$0]!)" }.joined(separator: ", ")))
}
if #available(iOS 16.0, *) {
    let cfg = MLModelConfiguration(); cfg.computeUnits = .cpuAndNeuralEngine
    let m = try MLModel(contentsOf: realCompiled, configuration: cfg)
    let p = try m.prediction(from: inputDict(sample.mapValues { MLFeatureValue(double: $0) }))
    let d = p.featureValue(for: "classProbability")!.dictionaryValue as! [Int64: Double]
    unitProbs.append(("cpuAndNeuralEngine", d.keys.sorted().map { "\($0): \(d[$0]!)" }.joined(separator: ", ")))
}
line("  " + unitProbs.map { "\($0.0)[\($0.1)]" }.joined(separator: "  "))
expect(Set(unitProbs.map { $0.1 }).count == 1, "\(unitProbs.count) 种 computeUnits 出来的概率字典完全一致 —— 选哪块芯片是性能问题，不是结果问题")

// ============================================================
// §17 输入侧：哪些宽容、哪些严格
// ============================================================
section(17, "喂进去的东西：多余的被忽略，窄化的被接受，类型跨不过去")
do {
    _ = try bare.prediction(from: inputDict(["x": MLFeatureValue(double: 1.0), "zzz": MLFeatureValue(double: 2.0)]))
    expect(true, "多喂一个描述里没有的特征 zzz：**没报错**，被静默忽略 —— 拼错特征名不会有任何提示")
} catch { expect(false, "多余特征被拒：\(firstLine(errDesc(error)))") }
do {
    let p = try bare.prediction(from: inputDict(["x": MLFeatureValue(int64: 7)]))
    expect(p.featureValue(for: "y")!.doubleValue == 34.0, "int64 喂给 double 特征：被接受并自动加宽，\(7 + 10) × 2 = \(p.featureValue(for: "y")!.doubleValue)")
} catch { expect(false, "int64 喂 double 被拒：\(firstLine(errDesc(error)))") }
do {
    _ = try nn.prediction(from: inputDict(["image": MLFeatureValue(double: 1.0)]))
    expect(false, "double 喂给图像特征居然被接受 —— 与本机实测不符")
} catch {
    let d = firstLine(errDesc(error))
    expect(errDomain(error) == "com.apple.CoreML" && errCode(error) == 1 && d.contains("expects input feature image to be an image"),
           "跨到图像这一族就拦住了：\(d)")
}
do {
    _ = try real.prediction(from: inputDict(["plugin_battery_level": MLFeatureValue(double: 100.0)]))
    expect(false, "少喂四个特征居然被接受 —— 与本机实测不符")
} catch {
    // 这句错误原文就在 localizedDescription 里：这个 NSError 的 userInfo 里没有
    // NSLocalizedFailureReason 那一项（下一行把它整个键表打出来），别照着 AppKit 的习惯找它。
    let ns = error as NSError
    let reasonKeys = ns.userInfo.keys.map { String(describing: $0) }.sorted()
    line("  userInfo 的键 = \(reasonKeys)")
    let msg = firstLine(ns.localizedDescription)
    expect(ns.domain == "com.apple.CoreML" && ns.code == 0 && msg.hasPrefix("Feature '") && msg.hasSuffix("' not provided."),
           "缺特征报的是「\(msg)」—— domain=\(ns.domain) code=\(ns.code)，它只点名五个缺失特征里的第一个")
}

// ============================================================
// §18 边界：校验器原话圈出来的三堵墙
// ============================================================
section(18, "手写不出来 / 跑不起来的东西：把墙的位置钉死")
// 墙一：这不是「任何文本文件都能改一改」。递一份不是 protobuf 的字节进去，解析器给出的
// 错误连字段号都报了 —— 它真的在按 protobuf 走。
do {
    _ = try compileToModel(Bytes("this is not protobuf".utf8), "junk")
    expect(false, "畸形字节编过了 —— 与本机实测不符")
} catch {
    line("  墙一 畸形 protobuf：\(firstLine(errDesc(error)))")
    expect(errDomain(error) == "com.apple.mlassetio" && errCode(error) == 1, "  → domain=\(errDomain(error)) code=\(errCode(error))（是「读规格」这一步就失败了）")
}
// 墙二：书本要的「图像分类器」（输出 classLabel/classProbability，让 Vision 能给
// VNClassificationObservation）在本机手写不出来。校验器一格一格地把不允许的输出类型念出来：
// 三段原文都是同一份「一层 RELU + 一个输出」的规格，只换输出类型。
for (label, outType) in [("图像", ftImage(2, 2)), ("字符串", ftString()), ("字典", PB.msg(3, PB.msg(6, PB.msg(1, Bytes()))))] {
    let spec = modelSpec(inputs: [("image", ftImage(2, 2))], outputs: [("o", outType)], predicted: "o",
                         paramsField: 303, params: layerParams("act0", "image", "o", 130, PB.msg(10, Bytes())))
    do {
        _ = try compileToModel(spec, "clf")
        line("  墙二 输出=「\(label)」：编译过了（与实测不符）")
    } catch {
        line("  墙二 输出=「\(label)」：\(firstLine(errDesc(error)))")
    }
}
// 而 303 换成 multiArray 输出**是能编过的**，只是种类被念成 regressor：
// （第一版这里编不过是自己的 bug：层 params 的输出名必须等于描述里声明的那个输出特征名，
//   写 "o" 却声明 "classProbability"，校验器只会说「Error in declaring output ... error -1」。）
do {
    let spec = modelSpec(inputs: [("image", ftImage(2, 2))],
                         outputs: [("classProbability", ftMultiArray([2]))], predicted: "classProbability",
                         paramsField: 303, params: layerParams("act0", "image", "classProbability", 130, PB.msg(10, Bytes())))
    let m = try compileToModel(spec, "clf_ok")
    expect(m.modelDescription.outputDescriptionsByName["classProbability"]?.type == .multiArray,
           "  → 只有 multiArray 输出能过：字段号 303（neuralNetworkClassifier）编过了，但输出类型仍是数组，拿不到分类观察结果")
} catch { expect(false, "  → multiArray 输出的 303 也编不过：\(firstLine(errDesc(error)))") }
// 墙三：书本那个「拖进来就有一个类」的生成命令，只认磁盘上一份已经存在的 .mlmodel 文件，
// 而且语言名要写全称（`--language swift` 会被拒），命令形式还是位置参数
// （`compile 源 目标`，写成 `--output-dir` 会报「missing destination path」）。本机的原话见
// 探针 a01。这条不是 Core ML 的墙，是本机工具链的墙；它划出了本章为什么把生成物提交进
// 仓库（§5）而不是在示例里现跑一条命令 —— 示例是**在模拟器里**跑的，而 coremlcompiler
// 是 macOS 上的主机程序。
expect(true, "  → 墙三记在探针 a01/r01：coremlcompiler 的命令行原话、以及结构自省喂 .mlmodel 会让进程当场 abort（signal 6）")

// ============================================================
// §19 收尾：把「智能」压回成一句可断言的话
// ============================================================
section(19, "本章唯一一条「模型接上了」的判据")
// 书本这一章的成功判据是「屏上导航栏写出热狗/不是热狗」。本仓库没有屏，所以判据换成
// 同一条因果链上能被卡住的那一环：一段我自己写出来的字节、一个我自己生成出来的类、
// 和一份苹果训练好的模型，三者各自跑通，而且输出不依赖优化配置、也不依赖跑在哪块芯片上。
expect(one.y == 21.0 && ys == [20.0, 21.0, 40.0], "手写的 46 字节：单条与批量断言都对")
expect(elems.first == 20.0 && rows.count <= 1, "张量与神经网络：形状/层数都按规格里写的那个数")
expect(label0 == 0 && abs(sum - 1.0) < 1e-12, "真分类器：第一名与概率和都对")
expect(observations.count == 1 && !cameraOn, "Vision 通路在，摄像头不在 —— 这就是本章能走到书本 15.2.3 的哪一步")

line("")
line("failures=\(failures)")
print("==== 34 结束 ====")
exit(failures == 0 ? 0 : 1)
