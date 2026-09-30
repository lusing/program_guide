// 探针 r01：把 .mlmodel 源文件喂给结构自省 API，进程当场 abort
//
// 为什么不进主线：这一格的后果是**整个进程没顶**（signal 6），主线一旦跑到这里就再也
// 打印不出 §11~§19，六条判定全废。主线 §10 因此只喂编译产物，把这一格留在这里单独跑。
//
// 现场：__MLModelStructure.loadContents(of:) 按 .mlmodelc 的目录结构去开 coremldata.bin。
// 拿到的却是 .mlmodel 这个**文件**，于是它打开 …/ch34r01/scaler.mlmodel/coremldata.bin
// 失败，抛出一个 Swift 侧接不住的 C++ 异常（libc++abi 接管，std::terminate）。
//
// 最重要的一课是**崩溃到达的时刻**：loadContents 是异步的，它先把控制权还给你，异常在
// 之后那一拍才摔下来。本探针的第一版调用完就 exit，退出码 0、stderr 全空，看起来像
// 「它没报错」；加了等待之后才看见 signal 6。所以「Swift 的 try/catch 接不住它」这句话
// 不能靠调用点后面一句 print 来验证 —— 必须让进程真的活着。
import CoreML
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

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
}
func ftDouble() -> Bytes { PB.msg(3, PB.msg(2, Bytes())) }
func feature(_ name: String, _ type: Bytes) -> Bytes { PB.text(1, name) + type }

// 主线 §1 那 46 字节的 scaler 规格，就地重拼一遍（探针不 import 主线，两边是同一套号）
let spec: Bytes = PB.vint(1, 1)
    + PB.msg(2, PB.msg(1, feature("x", ftDouble())) + PB.msg(10, feature("y", ftDouble())) + PB.text(11, "y"))
    + PB.msg(604, PB.dbl(1, 10.0) + PB.dbl(2, 2.0))

let work = FileManager.default.temporaryDirectory.appendingPathComponent("ch34r01")
try? FileManager.default.removeItem(at: work)
try! FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
let srcURL = work.appendingPathComponent("scaler.mlmodel")
try! Data(spec).write(to: srcURL)
print("写出 \(srcURL.lastPathComponent)：\(spec.count) 个字节。它是 .mlmodel **源文件**，不是 .mlmodelc 目录")
print("规格版本字段 f1=1、输入 x / 输出 y 都是 double、模型参数是字段 604（scaler）")

// 顶层代码里 `guard #available` 不会像函数里那样收窄后面的作用域（swiftc 照样报
// "only available in iOS 17.4"），所以这里用 if 包住整段。
if #available(iOS 17.4, *) {
    // 这里**不写** do/catch：那个异常不是 Swift 的 Error，编译器会直接说 catch 不可达。
    // 「接不住」是靠下面的输出顺序证明的 —— 调用返回了、下一行 print 也打了，然后进程没了。
    print("下面调用 __MLModelStructure.loadContents(of:) —— 它会立刻返回")
    let sem = DispatchSemaphore(value: 0)
    __MLModelStructure.loadContents(of: srcURL) { st, err in
        print("   回调进来了：structure=\(st == nil ? "nil" : "有值") err=\(err == nil ? "nil" : String(describing: err!))")
        sem.signal()
    }
    print("   调用已经返回（说明异常不是在这儿摔的）。现在等回调 —— 等到的将是 abort")
    _ = sem.wait(timeout: .now() + 20)
    print("   20 秒到，居然没 abort —— 与本探针记录的行为不符")
    print("如果这句话打出来了，进程就还活着")
} else {
    print("跳过：__MLModelStructure 要 iOS 17.4")
}
