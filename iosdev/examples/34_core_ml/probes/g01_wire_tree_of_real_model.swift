// 探针 g01：把两份 .mlmodel 读成同一棵树
//
// 为什么不进主线：主线要打印的东西必须逐字节可复现（六条判定里 debug 与 release 要一致），
// 而这份真模型的树有几百行、里面全是浮点数尾巴；主线只取了自己需要的那几行（§1、§13）。
// 这里做的是**取证**：把苹果那份 26 881 字节的模型整个摊开，看清它的顶层字段号和 §1 那
// 46 字节是不是同一套 schema —— 这是本章每一个字段号的来源（本机没有 .proto，也没有
// coremltools；号只能从真模型的字节里读，或从校验器的原话里读）。
//
// 它和主线的 Wire.walk 是同一段逻辑，多了三样主线用不上的东西：深度上限、行数预算，
// 以及「把全文里所有能读成 ASCII 的字段收集起来」那一趟（特征名就是这么露出来的）。
//
// 跑法：在**模拟器里**跑（真模型躺在设备侧的 /System 分区里，主机上那条路径不存在，
// 见 run.sh 顶部的说明）。
import Foundation

typealias Bytes = [UInt8]

func varint(_ buf: Bytes, _ i: Int) -> (Int, Int)? {
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

func parses(_ buf: Bytes) -> Bool {
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

func printable(_ buf: Bytes) -> Bool {
    !buf.isEmpty && buf.allSatisfy { $0 >= 32 && $0 < 127 }
}

// 一份文件的解码结果：树（受预算约束）+ 全文里露出来的 ASCII 串
struct Decoded {
    var tree: [String] = []
    var strings: [String] = []
    var truncated = false
}

func walk(_ buf: Bytes, _ depth: Int, _ capDepth: Int, _ d: inout Decoded) {
    var i = 0
    let pad = String(repeating: "  ", count: depth)
    while i < buf.count {
        if d.tree.count >= 120 { d.truncated = true; return }
        guard let (t, j) = varint(buf, i) else { d.truncated = true; return }
        i = j
        let f = t >> 3, wt = t & 7
        if wt == 0 {
            guard let (v, k) = varint(buf, i) else { return }
            i = k
            d.tree.append("\(pad)f\(f) varint \(v)")
        } else if wt == 2 {
            guard let (ln, k) = varint(buf, i) else { return }
            i = k
            let sub = Array(buf[i..<min(i + ln, buf.count)])
            i += ln
            if printable(sub) {
                let s = String(decoding: sub, as: UTF8.self)
                d.tree.append("\(pad)f\(f) str \"\(s)\"")
                if !d.strings.contains(s) { d.strings.append(s) }
            } else if parses(sub) && depth < capDepth {
                d.tree.append("\(pad)f\(f) msg len=\(ln)")
                walk(sub, depth + 1, capDepth, &d)
            } else {
                d.tree.append("\(pad)f\(f) \(parses(sub) ? "msg" : "bytes") len=\(ln) "
                              + sub.prefix(8).map { String(format: "%02x", $0) }.joined()
                              + (parses(sub) ? "（到深度上限，不再深入）" : ""))
            }
        } else if wt == 1 {
            guard i + 8 <= buf.count else { return }
            let raw = Array(buf[i..<i + 8]); i += 8
            var bits: UInt64 = 0
            for (k, b) in raw.enumerated() { bits |= UInt64(b) << (8 * k) }
            d.tree.append("\(pad)f\(f) double \(Double(bitPattern: bits)) ["
                          + raw.map { String(format: "%02x", $0) }.joined() + "]")
        } else if wt == 5 {
            i += 4
            d.tree.append("\(pad)f\(f) fixed32")
        } else {
            d.tree.append("\(pad)f\(f) 线型 \(wt) —— protobuf 里已经没有这一档"); return
        }
    }
}

func report(_ title: String, _ bytes: Bytes, capDepth: Int) {
    print("== \(title)（\(bytes.count) 个字节）==")
    print("hex 前 96 字节: " + bytes.prefix(96).map { String(format: "%02x", $0) }.joined())
    var d = Decoded()
    walk(bytes, 0, capDepth, &d)
    print("字段树（前 \(d.tree.count) 行\(d.truncated ? "，已按预算截断" : "")）:")
    for t in d.tree { print("  " + t) }
    print("全文里露出来的 ASCII 串（前 \(min(d.strings.count, 40)) 个，按出现顺序）:")
    print("  " + d.strings.prefix(40).map { "\"\($0)\"" }.joined(separator: ", "))
    print("  共 \(d.strings.count) 个不同的串")
    print("")
}

// 主线 §1 那份 46 字节，从它自己的 hex 表示还原回来 —— 两边喂给同一个解码器，
// 「结构一模一样」这句话就不用信任何人。
let tinyHex = "080112150a070a01781a02120052070a01791a0212005a0179e22512090000000000002440110000000000000040"
var nibbles: [UInt8] = []
for ch in tinyHex { nibbles.append(UInt8(String(ch), radix: 16)!) }
var tiny = Bytes()
var i = 0
while i + 1 < nibbles.count { tiny.append((nibbles[i] << 4) | nibbles[i + 1]); i += 2 }
print("46 字节的 hex 还原出来是 \(tiny.count) 个字节：" + (tiny.count == 46 ? "对得上" : "对不上"))
report("手写规格 scaler（字段号 604）", tiny, capDepth: 8)

// 主线 §13 那份苹果训练好的模型。设备侧路径；主机上同名的运行时目录里**没有**这个文件
// （PowerUI.framework 在主机侧只剩 .lproj），所以这支探针必须在模拟器里跑。
let realPath = "/System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/Resources/assets_251/shallow_model.mlmodel"
if let data = try? Data(contentsOf: URL(fileURLWithPath: realPath)) {
    report("苹果真模型 \(realPath)", Array(data), capDepth: 3)
} else {
    print("读不到 \(realPath) —— 这支探针要在模拟器里跑（run.sh 负责这件事）")
    exit(2)
}
