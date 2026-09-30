// 探针 r02：scaler 这种「逐元素」的模型参数，对多维输入怎么说
//
// 为什么不进主线：这一格量的是**校验器的原话**。主线 §8 用一维数组跑通了 scaler
// （(x+offset)*scale 逐个元素算），而「换成二维会怎样」的答案要么是一句 throw，
// 要么是一次崩溃 —— 前者会让主线多一条与书本无关的分支，后者直接把主线打死。
// 所以放这里：编好、放进模拟器、把 stdout / stderr / 退出码全抄下来。
//
// 结论（本探针的输出）：一维的对照组一路跑通；二维连 MLModel.compileModel(at:) 都过不去，
// 校验器把话直接摔在 error 里 —— domain=com.apple.CoreML code=3，原文一句就说明白了：
// 「Only 1 dimensional arrays input features are supported by the scaler.」
// 也就是说「规格能不能被收下」这一关是在**编译期**判的，不是等到预测时才判。
import CoreML
import Foundation

typealias Bytes = [UInt8]

enum PB {
    static func varint(_ n: Int) -> Bytes {
        var v = n, out: Bytes = []
        while true {
            let b = UInt8(v & 0x7F); v >>= 7
            out.append(b | (v == 0 ? 0 : 0x80))
            if v == 0 { return out }
        }
    }
    static func tag(_ field: Int, _ wire: Int) -> Bytes { varint((field << 3) | wire) }
    static func vint(_ field: Int, _ n: Int) -> Bytes { tag(field, 0) + varint(n) }
    static func text(_ field: Int, _ s: String) -> Bytes {
        let b = Bytes(s.utf8); return tag(field, 2) + varint(b.count) + b
    }
    static func msg(_ field: Int, _ body: Bytes) -> Bytes {
        tag(field, 2) + varint(body.count) + body
    }
    static func dbl(_ field: Int, _ x: Double) -> Bytes {
        var bits = x.bitPattern
        var out = tag(field, 1)
        withUnsafeBytes(of: &bits) { out.append(contentsOf: Bytes($0)) }
        return out
    }
    static func packedInts(_ field: Int, _ vals: [Int]) -> Bytes {
        let body = vals.flatMap { varint($0) }
        return tag(field, 2) + varint(body.count) + body
    }
}

func ftMultiArray(_ shape: [Int], _ dtype: Int = 65568) -> Bytes {
    PB.msg(3, PB.msg(5, PB.packedInts(1, shape) + PB.vint(2, dtype)))
}
func feature(_ name: String, _ type: Bytes) -> Bytes { PB.text(1, name) + type }
func modelSpec(inputs: [(String, Bytes)], outputs: [(String, Bytes)], predicted: String?) -> Bytes {
    var d: Bytes = []
    for (n, t) in inputs { d += PB.msg(1, feature(n, t)) }
    for (n, t) in outputs { d += PB.msg(10, feature(n, t)) }
    if let p = predicted { d += PB.text(11, p) }
    // 字段号 604 = scaler；它的两个 double：字段 1 是要加的数、字段 2 是要乘的数（主线 §5 反推的）
    return PB.vint(1, 1) + PB.msg(2, d) + PB.msg(604, PB.dbl(1, 10.0) + PB.dbl(2, 2.0))
}

setvbuf(stdout, nil, _IONBF, 0)
let work = FileManager.default.temporaryDirectory.appendingPathComponent("ch34r02")
try? FileManager.default.removeItem(at: work)
try! FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)

func tryScaler(_ shape: [Int]) {
    let dims = shape.count
    print("-- shape = \(shape)（\(dims) 维）")
    let spec = modelSpec(inputs: [("m", ftMultiArray(shape))], outputs: [("o", ftMultiArray(shape))], predicted: "o")
    let url = work.appendingPathComponent("s\(dims).mlmodel")
    try! Data(spec).write(to: url)
    let compiled: URL
    do { compiled = try MLModel.compileModel(at: url) }
    catch { print("  compileModel 就失败：domain=\((error as NSError).domain) code=\((error as NSError).code) \((error as NSError).localizedDescription)"); return }
    print("  compileModel 过了（产物 \(compiled.lastPathComponent)）")
    let model: MLModel
    do { model = try MLModel(contentsOf: compiled) }
    catch { print("  载入失败：\(error)"); return }
    print("  载入过了，约束读回来：\(String(describing: model.modelDescription.inputDescriptionsByName["m"]?.multiArrayConstraint))")
    let arr = try! MLMultiArray(shape: shape.map { NSNumber(value: $0) }, dataType: .float32)
    for i in 0..<arr.count { arr[i] = NSNumber(value: Float32(i)) }
    do {
        let inputs = try MLDictionaryFeatureProvider(dictionary: ["m": MLFeatureValue(multiArray: arr)])
        let out = try model.prediction(from: inputs)
        let o = out.featureValue(for: "o")!.multiArrayValue!
        print("  预测成功：输出形状 \(o.shape.map { $0.intValue })，前两个元素 \(o[0].doubleValue)、\(o[1].doubleValue)")
    } catch {
        let ns = error as NSError
        print("  预测失败：domain=\(ns.domain) code=\(ns.code) 「\(ns.localizedDescription)」")
        print("  userInfo 的键 = \(ns.userInfo.keys.map { String(describing: $0) }.sorted())")
    }
}

tryScaler([6])   // 主线 §8 那一维的对照组
tryScaler([2, 3]) // 二维：这里才是本探针要量的那一句
