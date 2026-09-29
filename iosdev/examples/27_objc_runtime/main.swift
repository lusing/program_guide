// ============================================================
// 27 - Objective-C 运行时：消息、isa、转发、KVC/KVO 与两套反射
//
// 本章的证据分两半：
//   OC 侧（RTMsg.m / RTDecl.m / RTDyn.m）负责「只有 runtime 才答得出」的部分 ——
//     选择器、nil 接收者、IMP 与 objc_msgSend、类型编码、属性三件套、ivar 偏移、
//     关联对象、四级转发、换实现、分类、协议、KVC、KVO、内省、对象通信；
//   Swift 侧（本文件）负责「同一套 runtime 从 Swift 望过去是什么样」——
//     Swift 类的真名、@objc 与 @objc dynamic 的分工、Swift 版 KVO token、
//     通知中心、Mirror 与 runtime 这两套互不相通的反射。
//
// 为什么值得单开一章：《iOS开发从入门到精通》第 5/6/7 章（类、消息和协议、对象）
// 讲的不是 API 用法，而是「ObjC 里一行方法调用到底发生了什么」。这本书成书于 ARC 早期，
// 里面不少说法已经过时（手工 retain/release 计数、两参数版 addObserver:forKeyPath:、
// 把非正式协议当主流写法），但它对「消息发送 = 按名字找实现，找不到就转发」的讲法今天依然成立，
// 而这正是读 UIKit 源码、理解 delegate / target-action / KVO / @objc dynamic 的地基。
//
// 六条判定带来的写法约束：
//   - OC 侧一次 NSLog 都没有：NSLog 走 stderr，判定 3 直接失败，全部改成 stdout 上的字符串；
//   - 不打印指针值、耗时、进程内类总数（探针里 objc_copyClassList 有 26544 个类，这个数字随系统变，
//     一次都不能进输出）；对象一律用类名或字符串内容表示；
//   - NSArray 的 description 会打出多行和 \U 转义，所以所有日志都在 OC 侧用 " | " 拼成一行；
//   - 会崩的调用（unrecognized selector、valueForUndefinedKey、给标量键塞 nil、KVO 的四种误用、
//     把 void 方法的返回值当对象用、钩子自己调自己、stret 参数顺序写错）全部只在独立探针进程里量，
//     正文以「探针记录」引用原文，示例一行都不执行；
//   - 交换 IMP 改的是整个类，所以 §9 / §19 收尾都把实现换回去，不给后面的小节留脏状态。
// ============================================================

import Foundation

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
/// 断言 + 讲解。讲解写成若干段字符串拼起来，输出一整行，方便文档逐字引用
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
/// 开一个真正的作用域：里面的对象在闭包结束时释放（顶层代码的 do{} 不会形成值生命周期边界）
func scope(_ body: () -> Void) { body() }

/// 打印 OC 侧采集好的一节证据。行内容已在 OC 里排好版，Swift 这边只加小节标题。
func showOC(_ index: Int, _ title: String, _ collected: [String]) {
    print("\n== §\(index) \(title) ==")
    for l in collected { print(l) }
}

// ============================================================
// Swift 侧用的类型
// ============================================================

/// 继承 NSObject 的 Swift 类：对 ObjC runtime 完全可见
class RTSwiftVisible: NSObject {
    var swiftStored = 1          // 纯 Swift 存储属性：runtime 看不见，KVC 也摸不到
    @objc var exposed = 2        // 标了 @objc 的属性才进 ObjC 的属性/方法表
    @objc func plainTag() -> String { "普通 @objc 方法" }
    @objc dynamic func dynamicTag() -> String { "dynamic @objc 方法" }
    func swiftOnly(_ x: Int) -> Int { x + 1 }
}

/// 不继承 NSObject 的纯 Swift 类：runtime 里根本没有它
final class RTSwiftPure {
    var a = 1
    var b = "两"
    func doThing() -> String { "纯 Swift 方法" }
}

struct RTSwiftStruct { var x = 3; var y = 4 }
enum RTSwiftEnum: String, CaseIterable { case tea, coffee }
/// Mirror 看带关联值的 case 时才用得上它
enum RTPayload { case point(x: Int, y: Int) }

/// §19 提供交换用的另一份实现（计数放在它自己这边，证明调用真的落到了补丁类）
class RTSwizzlePatch: NSObject {
    static var hits = 0
    @objc func plainTag() -> String { RTSwizzlePatch.hits += 1; return "补丁版实现" }
    @objc func dynamicTag() -> String { RTSwizzlePatch.hits += 1; return "补丁版 dynamic 实现" }
}

/// §20 Swift 侧被观察的对象：KVO 要求属性是 @objc dynamic
class RTKVOHolder: NSObject {
    @objc dynamic var count: Int = 0
    @objc dynamic var label: String = "初始"
}

/// §21 用：selector 版通知观察者，靠 deinit 验证「目标释放后自动解绑」
final class RTDeadObserver: NSObject {
    static var hits = 0
    static var dealloced = false
    @objc func ping(_ note: Notification) { RTDeadObserver.hits += 1 }
    deinit { RTDeadObserver.dealloced = true }
}

// ============================================================
// OC 侧的全部证据（§1–§17）
// ============================================================

showOC(1, "选择器与消息的形状", RTLinesSelectors())
showOC(2, "nil 接收者的返回值全表", RTLinesNilReturns())
showOC(3, "IMP、methodForSelector 与 objc_msgSend 家族", RTLinesMsgSend())
showOC(4, "self 与 _cmd 两个隐藏参数", RTLinesHiddenArgs())
showOC(5, "@encode 与方法类型编码", RTLinesEncoding())
showOC(6, "属性在 runtime 里的三件套", RTLinesProperties())
showOC(7, "ivar 反射与关联对象", RTLinesIvarsAndAssoc())
showOC(8, "消息转发的四级台阶", RTLinesForwarding())
showOC(9, "换实现：交换 IMP 与直接替换", RTLinesSwizzle())
showOC(10, "分类、+load 与 +initialize", RTLinesCategories())
showOC(11, "协议的运行时视图", RTLinesProtocols())
showOC(12, "KVC：候选顺序与集合运算符", RTLinesKVC())
showOC(13, "KVO：isa 换脸与通知时机", RTLinesKVO())
showOC(14, "内省：四个容易混的问题与类/元类", RTLinesIntrospection())
showOC(15, "对象通信：target-action、delegate、notification", RTLinesCommunication())
showOC(16, "可变/不可变的类层级与 copy 的实际结果", RTLinesMutability())
showOC(17, "异常：@try/@catch/@finally 的匹配规则", RTLinesExceptions())

// ============================================================
// §18 Swift 类在 ObjC runtime 里长什么样
// ============================================================
line("\n== §18 Swift 类在 ObjC runtime 里长什么样 ==")
scope {
    let v = RTSwiftVisible()
    let cls: AnyClass = Swift.type(of: v)
    let objcName = NSStringFromClass(cls)
    line("  Swift 的 type(of:) = \(cls)；NSStringFromClass = \(objcName)；OC 侧的 class_getName = \(String(cString: class_getName(cls)))")
    expect(objcName == "objc_runtime.RTSwiftVisible", "Swift 类的 ObjC 名字是「\(objcName)」= 模块名.类名，不是裸类名，也不是 `_TtC…` 那种 mangling："
        + "NSStringFromClass 会替普通 Swift 类把名字反解出来（class_getName 拿到的是同一串）。"
        + "但泛型和编译器合成的类型就还是原始 mangling —— 见 §22 里那个 `_TtGCs26_…$` 的字典，以及下面纯 Swift 类的隐式父类。")
    expect(NSClassFromString(objcName) === cls, "拿 NSStringFromClass 给的那整串反查 NSClassFromString 能找回来；而 NSClassFromString(\"RTSwiftVisible\") = "
        + "\(NSClassFromString("RTSwiftVisible") == nil ? "nil" : "找到了") —— 类名本身不是它的 ObjC 名，这就是「storyboard 里 Swift 类要填 模块名.类名」的根因。")
    expect(RTIsaOf(v) === cls, "OC 侧的 object_getClass（RTIsaOf）拿到的是同一个类对象：\(RTIsaOf(v) === cls)")
    expect(v.isKind(of: NSObject.self), "继承 NSObject 的 Swift 类走的就是这套消息机制：isKind(of: NSObject) = \(v.isKind(of: NSObject.self))")
    let selName = NSStringFromSelector(#selector(RTSwiftVisible.plainTag))
    expect(v.responds(to: #selector(RTSwiftVisible.plainTag)),
        "@objc 方法在 runtime 里就是一个真选标：#selector(plainTag) 的名字是 \"\(selName)\"，responds(to:) = \(v.responds(to: #selector(RTSwiftVisible.plainTag)))")
    expect(v.swiftOnly(1) == 2, "纯 Swift 方法照样能调（swiftOnly(1) = \(v.swiftOnly(1))），但它在 runtime 里不可见 —— 见下一条")
    expect(!v.responds(to: Selector(("swiftOnly:"))), "按 Swift 名字猜的选标 \"swiftOnly:\" 在 runtime 里问不到（responds = "
        + "\(v.responds(to: Selector(("swiftOnly:"))))）：没标 @objc 的方法根本不进 ObjC 方法表，KVC / perform / target-action 全都碰不到它。")
    expect(!v.responds(to: Selector(("noSuchThingAtAll"))), "问一个彻底不存在的方法：responds = \(v.responds(to: Selector(("noSuchThingAtAll"))))"
        + "（和 OC 一样只回答 NO，不崩）")
    var ivarCount: UInt32 = 0
    if let list = class_copyIvarList(cls, &ivarCount) { free(list) }
    var propCount: UInt32 = 0
    if let list = class_copyPropertyList(cls, &propCount) { free(list) }
    line("  runtime 眼里的成员：RTSwiftVisible 的 ivar 数 = \(ivarCount)，属性数 = \(propCount)，实例大小 = "
        + "\(class_getInstanceSize(cls)) 字节（NSObject 本身 \(class_getInstanceSize(NSObject.self)) 字节）")
    expect(ivarCount == 2, "Swift 的存储属性会照实变成 ObjC ivar（\(ivarCount) 个：swiftStored 与 exposed），"
        + "但只有 @objc 那个进属性表（\(propCount) 个）—— 「有 ivar」和「KVC 能读到」是两件事，§12 的候选顺序里 ivar 那一档就是给前者留的门。")
}

// ============================================================
// §19 @objc 与 @objc dynamic：交换到底改的是谁
// ============================================================
line("\n== §19 @objc 与 @objc dynamic：换实现对两种方法的影响不一样 ==")
scope {
    let cls: AnyClass = RTSwiftVisible.self
    guard let m1 = class_getInstanceMethod(cls, #selector(RTSwiftVisible.plainTag)),
          let m2 = class_getInstanceMethod(RTSwizzlePatch.self, #selector(RTSwizzlePatch.plainTag)),
          let m3 = class_getInstanceMethod(cls, #selector(RTSwiftVisible.dynamicTag)),
          let m4 = class_getInstanceMethod(RTSwizzlePatch.self, #selector(RTSwizzlePatch.dynamicTag)) else {
        expect(false, "拿不到方法，本节作废")
        return
    }
    let oldPlain = method_getImplementation(m1)
    let oldDynamic = method_getImplementation(m3)
    let v = RTSwiftVisible()
    let beforePlain = v.plainTag()
    let beforeDynamic = v.dynamicTag()
    line("  动手前：Swift 直接调 plainTag() = \(beforePlain)；dynamicTag() = \(beforeDynamic)")
    line("  动手前：从 OC 侧 objc_msgSend 进来 = \(RTCallThroughObjC(v, "plainTag")) / \(RTCallThroughObjC(v, "dynamicTag"))")

    method_exchangeImplementations(m1, m2)
    method_exchangeImplementations(m3, m4)
    let swiftPlainAfter = v.plainTag()
    let swiftDynamicAfter = v.dynamicTag()
    let objcPlainAfter = RTCallThroughObjC(v, "plainTag")
    let objcDynamicAfter = RTCallThroughObjC(v, "dynamicTag")
    line("  交换之后：Swift 直接调 plainTag() = \(swiftPlainAfter)；dynamicTag() = \(swiftDynamicAfter)")
    line("  交换之后：从 OC 侧进来 = \(objcPlainAfter) / \(objcDynamicAfter)")
    expect(swiftPlainAfter == beforePlain, "只标 `@objc`（没有 dynamic）的方法：Swift 里的直接调用**绕过 objc_msgSend**，走 Swift 自己的入口，"
        + "换 IMP 换不到它 —— 只有从 OC/runtime 进来的那条路变了。这就是「同一个 hook 有时灵有时不灵」的全部原因。")
    expect(objcPlainAfter.contains("补丁"), "同一次交换，OC 路径立刻拿到了补丁版实现：\(objcPlainAfter)")
    expect(swiftDynamicAfter != beforeDynamic, "`@objc dynamic`：编译器把这个调用直接写成 objc_msgSend，于是**两条路径一起被换**"
        + "（Swift 侧读到「\(swiftDynamicAfter)」）。代价是每个调用多一次消息发送；收益是 KVO、swizzle、CoreData 惰性加载才 work —— "
        + "那几个框架都明确要求你写 dynamic，原因就在这。")
    expect(RTSwizzlePatch.hits >= 3, "补丁类自己被命中 \(RTSwizzlePatch.hits) 次：交换后凡是走 ObjC 消息入口的调用都落进了 RTSwizzlePatch，"
        + "计数在它那一侧，说明 runtime 认的是实现指针不是名字。")

    // Method 是「方法记录」这个指针本身，交换的只是它里面的 IMP，所以 m1~m4 交换完照样能拿去换回来
    method_exchangeImplementations(m1, m2)
    method_exchangeImplementations(m3, m4)
    let restoredPlain = v.plainTag()
    let restoredDynamic = v.dynamicTag()
    let backToOld = method_getImplementation(m1) == oldPlain && method_getImplementation(m3) == oldDynamic
    expect(restoredPlain == beforePlain && restoredDynamic == beforeDynamic && backToOld,
        "再各交换一次还原：plainTag = \(restoredPlain)，dynamicTag = \(restoredDynamic)，IMP 指针回到最初那两个 = \(backToOld)"
        + "（本节不给后面的小节留脏状态；线上更稳的做法是记下旧 IMP 用 method_setImplementation 还原，见 §9）")
    expect(NSSelectorFromString("dynamicTag") == #selector(RTSwiftVisible.dynamicTag),
        "Swift 的 #selector 在编译期检查方法存在（写错编译不过），NSSelectorFromString 什么都不查 —— 和 §1 的结论一致："
        + "选标就是名字，编译器只替 #selector 这一条把关。")
    expect(v.value(forKey: "exposed") != nil, "同一个类上，@objc 属性能被 KVC 摸到（value(forKey:\"exposed\") = "
        + "\(String(describing: v.value(forKey: "exposed")))），纯 Swift 的 swiftStored 摸不到 —— 探针记录：对它调 value(forKey:) 抛 "
        + "NSUnknownKeyException，正是 §12 那两条崩溃的 Swift 版本。")
}

// ============================================================
// §20 Swift 侧的 KVO：block 版与 token
// ============================================================
line("\n== §20 Swift 侧 KVO：observe(...) 返回的 token 就是 §13 那套机制的自动版 ==")
scope {
    let holder = RTKVOHolder()
    let isaBefore = NSStringFromClass(RTIsaOf(holder) ?? NSObject.self)
    line("  注册前 isa = \(isaBefore)")
    var seen: [String] = []
    let token = holder.observe(\.count, options: [.initial, .new, .old]) { obj, change in
        var keys: [String] = []
        keys.append("kind")   // change.kind 在 Swift 侧是非可选的，永远带着
        if change.newValue != nil { keys.append("new") }
        if change.oldValue != nil { keys.append("old") }
        keys.sort()
        seen.append("count=\(obj.count) keys=\(keys.joined(separator: ","))")
    }
    let isaAfter = NSStringFromClass(RTIsaOf(holder) ?? NSObject.self)
    line("  注册后 isa = \(isaAfter)；Swift 看到的类型仍是 \(type(of: holder))；keyPath 字符串 = \(#keyPath(RTKVOHolder.count))")
    expect(isaAfter.contains("NSKVONotifying_"), "block 版 observe 走的还是同一套 KVO：isa 被换成 \(isaAfter)（原名前面拼上 NSKVONotifying_，"
        + "因为 Swift 类名本身带模块名，这一串里出现了两个点），而 Swift 侧的类型名一个字没变 —— §13 那个「偷偷生成子类」的机制在 Swift 里被完整复用。")
    holder.count = 1
    holder.count = 2
    expect(seen.count == 3, "initial + 两次赋值共通知 \(seen.count) 次：" + seen.joined(separator: " | "))
    token.invalidate()
    holder.count = 3
    expect(seen.count == 3, "invalidate 之后再赋值，通知次数仍是 \(seen.count) —— 与 OC 的 removeObserver 等价，但凭证是 token 本身，"
        + "不存在 §13 探针里「把观察者对象传错」那种用法。")
    var scopedHits = 0
    var scopedLast = "-"
    scope {
        let local = RTKVOHolder()
        let t = local.observe(\.label, options: [.new]) { _, change in
            scopedHits += 1
            scopedLast = change.newValue ?? "(nil)"
        }
        local.label = "作用域内改一次"
        _ = t
    }
    expect(scopedHits == 1 && scopedLast == "作用域内改一次", "token 和宿主一起待在作用域里：这一轮命中 \(scopedHits) 次，带回来的新值是「\(scopedLast)」；"
        + "作用域一结束 token 先被释放，KVO 自动把观察者摘掉 —— 宿主和观察者一起消失，就不会踩到 §13 探针里「宿主先走、观察者还挂着」那种崩溃。")
    var bareHits = 0
    var bareNewIsNil = false
    scope {
        let local = RTKVOHolder()
        let t = local.observe(\.label) { _, change in
            bareHits += 1
            bareNewIsNil = change.newValue == nil
        }
        local.label = "不带 options"
        _ = t
    }
    expect(bareHits == 1 && bareNewIsNil, "options 一个都不传：回调照样触发 \(bareHits) 次，可 change.newValue 是 nil（\(bareNewIsNil)）—— "
        + "「观察者明明在跑，读到的值全是空的」就是这么来的，要新值必须显式写 options: [.new]（这一条与 §13 OC 侧「change 字典里有哪些键」是同一件事，"
        + "只是 Swift 把键包成了 options）。")
    var noTokenHits = 0
    let holder2 = RTKVOHolder()
    scope {
        _ = holder2.observe(\.count) { _, _ in noTokenHits += 1 }
    }
    holder2.count = 5
    expect(noTokenHits == 0, "把 observe 的返回值直接丢掉（没接 token）：赋值之后命中 \(noTokenHits) 次 —— 通知没建立。"
        + "这是 Swift 版 KVO 最常见的「一行代码写对了却不生效」。")
}

// ============================================================
// §21 通知中心：一对多的那条路
// ============================================================
line("\n== §21 通知中心：一对多、按名字、发送方不认识接收方 ==")
scope {
    let name = Notification.Name("RT.Ch27.Ping")
    let gate = NSObject()
    let other = RTSwiftVisible()
    var aHits = 0
    var bHits = 0
    var cHits = 0
    var lastObject = "-"
    var lastKeys = "-"
    var wasMain = false
    let nc = NotificationCenter.default
    let tokenA = nc.addObserver(forName: name, object: nil, queue: nil) { note in
        aHits += 1
        lastObject = note.object.map { String(describing: type(of: $0)) } ?? "nil"
        lastKeys = (note.userInfo?.keys.map { String(describing: $0) } ?? []).sorted().joined(separator: ",")
        wasMain = Thread.isMainThread
    }
    let tokenB = nc.addObserver(forName: name, object: gate, queue: nil) { _ in bHits += 1 }
    let tokenC = nc.addObserver(forName: name, object: other, queue: nil) { _ in cHits += 1 }

    nc.post(name: name, object: other, userInfo: ["beta": 1, "alpha": 2])
    expect(aHits == 1 && bHits == 0, "object 传 nil 的观察者收到 \(aHits) 次；object 限定为 gate 的那个仍是 \(bHits) 次 —— "
        + "通知按「名字 + object 是否是同一个指针」过滤，userInfo 只是随车行李")
    expect(lastObject == "RTSwiftVisible" && lastKeys == "alpha,beta",
        "带回来的是发送方的类型名 \(lastObject)（不打印指针），userInfo 的键排序后 = \(lastKeys)；block 里 Thread.isMainThread = \(wasMain)"
        + "（queue 传 nil 表示就在发送线程上同步执行）")
    nc.post(name: name, object: gate, userInfo: nil)
    expect(aHits == 2 && bHits == 1, "换成 gate 发送：A 累计 \(aHits) 次、B 累计 \(bHits) 次、限定 other 的 C 是 \(cHits) 次 —— "
        + "同一条通知每个匹配的观察者各收一份，顺序不保证（别依赖注册先后，UIKit 自己也不依赖）")
    expect(lastKeys.isEmpty && lastObject == "NSObject", "第二次没带 userInfo：A 里的 lastKeys 被这次事件刷成空串（现在是 \"\(lastKeys)\"）、lastObject 跟着变成 \(lastObject) —— "
        + "回调里那些「记到变量里」的状态每次都被覆盖，别把上一次的残留当成这一次的内容；要判断本次有没有带数据，只能在 block 里当场看 note.userInfo 是不是 nil。")
    nc.removeObserver(tokenA)
    nc.removeObserver(tokenB)
    nc.removeObserver(tokenC)
    aHits = 0; bHits = 0; cHits = 0
    nc.post(name: name, object: gate, userInfo: nil)
    expect(aHits == 0 && bHits == 0 && cHits == 0, "全部 removeObserver 之后再发一次：三个计数都停在 0 —— "
        + "block 版（addObserver(forName:object:queue:using:)）不会自动解绑，必须自己摘（返回的那个 token 就是摘它用的凭证）。")
    scope {
        let dead = RTDeadObserver()
        nc.addObserver(dead, selector: #selector(RTDeadObserver.ping(_:)), name: name, object: nil)
        nc.post(name: name, object: nil, userInfo: nil)
        line("  selector 版观察者在场时：命中 \(RTDeadObserver.hits) 次")
    }
    let hitsAlive = RTDeadObserver.hits
    nc.post(name: name, object: nil, userInfo: nil)
    expect(hitsAlive == 1 && RTDeadObserver.hits == 1 && RTDeadObserver.dealloced,
        "同一个通知名，换成 selector 版：观察者出了作用域（deinit 跑过了 = \(RTDeadObserver.dealloced)）再发一次，命中次数停在 \(RTDeadObserver.hits) —— "
        + "既不崩也不再响，Foundation 替它自动解绑了。block 版不自动解绑、selector 版自动解绑，这两条正好记反。")
    line("  通知名就是字符串（\(name.rawValue)）：拼错编译得过、永远收不到，所以名字一律收成常量或扩展，别散着写字符串。")
    line("  和 §15 的三者对比：target-action 是「一个控件对一个方法」，delegate 是「一个对象问另一个对象拿决定/拿数据」，"
        + "notification 是「谁在听我不知道」。前两个编译期至少有名字可查，第三个连查都没得查。")
}

// ============================================================
// §22 两套反射：Mirror 管 Swift 类型，runtime 管消息表
// ============================================================
line("\n== §22 Mirror（Swift 反射）与 runtime（ObjC 反射）各管一半 ==")
scope {
    let pure = RTSwiftPure()
    var mirrorNames: [String] = []
    var mirrorValues: [String] = []
    for child in Mirror(reflecting: pure).children {
        mirrorNames.append(child.label ?? "(无标签)")
        mirrorValues.append(String(describing: child.value))
    }
    line("  Mirror 看 RTSwiftPure：\(mirrorNames.joined(separator: ",")) = \(mirrorValues.joined(separator: ","))")
    expect(mirrorNames == ["a", "b"], "Swift 的 Mirror 能读出纯 Swift 类的存储属性（\(mirrorNames.joined(separator: ","))）；"
        + "runtime 那边并不是「彻底查无此人」，而是「只查得到布局、查不到行为」—— 下面把两半边都量出来。")
    var pureIvarCount: UInt32 = 0
    var pureIvarDetail: [String] = []
    if let list = class_copyIvarList(RTSwiftPure.self, &pureIvarCount) {
        for i in 0..<Int(pureIvarCount) {
            let nm = ivar_getName(list[i]).map { String(cString: $0) } ?? "(null)"
            pureIvarDetail.append("\(nm)@\(ivar_getOffset(list[i]))")
        }
        free(list)
    }
    var pureMethodCount: UInt32 = 0
    if let list = class_copyMethodList(RTSwiftPure.self, &pureMethodCount) { free(list) }
    var purePropCount: UInt32 = 0
    if let list = class_copyPropertyList(RTSwiftPure.self, &purePropCount) { free(list) }
    let pureSuperClass: AnyClass? = class_getSuperclass(RTSwiftPure.self)
    let pureSuper = pureSuperClass.map { "\(String(describing: $0)) / \(NSStringFromClass($0))" } ?? "(nil)"
    let pureFound = NSClassFromString("objc_runtime.RTSwiftPure") != nil
    line("  runtime 看 RTSwiftPure：ivar \(pureIvarCount) 个（\(pureIvarDetail.joined(separator: " "))），方法 \(pureMethodCount) 个，属性 \(purePropCount) 个，"
        + "实例大小 \(class_getInstanceSize(RTSwiftPure.self)) 字节，父类 = \(pureSuper)，NSClassFromString(\"objc_runtime.RTSwiftPure\") 查得到 = \(pureFound)")
    expect(pureIvarCount == 2 && pureMethodCount == 0 && purePropCount == 0,
        "同一个纯 Swift 类：ivar 表读得到 \(pureIvarCount) 个（连偏移都算得出来，§7 那套 ivar_getOffset 在这也能用），"
        + "方法表 \(pureMethodCount) 个、属性表 \(purePropCount) 个 —— 「runtime 不认识 Swift」这句话的正确版本是："
        + "内存布局它是共用的，**消息表才是分家的**。")
    expect(pureFound, "NSClassFromString(\"objc_runtime.RTSwiftPure\") = \(pureFound)：连不继承 NSObject 的纯 Swift 类都能按「模块名.类名」反查到，"
        + "所以查不到的一定是裸类名（§18 那条），不是 Swift 类。")
    expect(pureSuperClass != nil && pureSuperClass !== NSObject.self, "父类不是 NSObject（\(pureSuper)）：那串 _TtC 开头的就是 Swift 自己的根类在 runtime 里的原始 mangling，"
        + "§18 说「普通 Swift 类的名字会被反解成 模块名.类名」，编译器合成的类型不在反解名单里，露出的还是底层的名字。")

    var visIvarCount: UInt32 = 0
    if let list = class_copyIvarList(RTSwiftVisible.self, &visIvarCount) { free(list) }
    var visMethodCount: UInt32 = 0
    var visMethodNames: [String] = []
    if let list = class_copyMethodList(RTSwiftVisible.self, &visMethodCount) {
        for i in 0..<Int(visMethodCount) { visMethodNames.append(NSStringFromSelector(method_getName(list[i]))) }
        free(list)
    }
    let visNames = visMethodNames.sorted().joined(separator: ",")
    expect(visIvarCount == 2 && visMethodCount == 5, "同一个文件里的两个类并排看：RTSwiftVisible 是 \(visIvarCount) 个 ivar + \(visMethodCount) 个 ObjC 方法（"
        + "\(visNames)），RTSwiftPure 是 \(pureIvarCount) 个 ivar + \(pureMethodCount) 个方法 —— "
        + "决定「KVC/KVO/swizzle/perform 能不能用」的是那张方法表，而它只在方法写上 @objc 的那一刻才有内容。")

    var structNames: [String] = []
    for c in Mirror(reflecting: RTSwiftStruct()).children { structNames.append(c.label ?? "?") }
    expect(structNames == ["x", "y"], "struct 只有 Mirror 能看（\(structNames.joined(separator: ","))）：它连类对象都没有，"
        + "ObjC runtime 侧完全不存在 —— 所以「拿 KVC 给 struct 批量赋值」这种从 OC 带过来的想法在 Swift 里必须换思路（Codable、手写 init）。")
    let enumMirror = Mirror(reflecting: RTSwiftEnum.tea)
    var enumChildren: [String] = []
    for c in enumMirror.children { enumChildren.append(c.label ?? "?") }
    let payMirror = Mirror(reflecting: RTPayload.point(x: 1, y: 2))
    var payChildren: [String] = []
    for c in payMirror.children { payChildren.append("\(c.label ?? "?")=\(c.value)") }
    line("  枚举：无关联值的 .tea -> displayStyle=\(enumMirror.displayStyle.map(String.init(describing:)) ?? "nil")，children \(enumChildren.count) 个；"
        + "带关联值的 .point(x:1,y:2) -> children [" + payChildren.joined(separator: ", ") + "]")
    expect(enumChildren.isEmpty && enumMirror.displayStyle == .enum,
        "无关联值的 case，Mirror 的 children 是 \(enumChildren.count) 个（case 名既不在 label 里也不在 value 里，String(describing:) 才给得到「\(String(describing: RTSwiftEnum.tea))」）："
        + "要遍历 case 只能自己声明 CaseIterable（\(RTSwiftEnum.allCases.map { $0.rawValue }.joined(separator: ","))）—— "
        + "这是从 OC 的枚举（§5 里 @encode 出来就是个 int，随便拿 KVC 塞进去都行）过来最容易猜错的一点。")
    expect(payChildren == ["point=(x: 1, y: 2)"], "带关联值的 case，Mirror 才给出 \(payChildren.joined(separator: ","))：label 是 case 名，value 是整个元组 —— "
        + "Swift 的枚举是「带 tag 的 union」，runtime 那一侧连这种类型都表达不了（§5 的类型编码里没有它的位置）。")
    expect(RTSwiftEnum.allCases.map { $0.rawValue } == ["tea", "coffee"], "CaseIterable 是编译期合成的表（\(RTSwiftEnum.allCases.map { $0.rawValue }.joined(separator: ","))），"
        + "和 §14 那个「运行期造类」的思路正好相反：Swift 的反射要么编译期就知道（Mirror/CaseIterable），要么根本不给。")

    let structStyle = Mirror(reflecting: RTSwiftStruct()).displayStyle
    let classStyle = Mirror(reflecting: RTSwiftVisible()).displayStyle
    let arrayStyle = Mirror(reflecting: [1, 2]).displayStyle
    line("  分类型靠 displayStyle，不用猜 children：struct=\(structStyle.map(String.init(describing:)) ?? "nil") "
        + "class=\(classStyle.map(String.init(describing:)) ?? "nil") collection=\(arrayStyle.map(String.init(describing:)) ?? "nil") enum=\(enumMirror.displayStyle.map(String.init(describing:)) ?? "nil")")
    expect(structStyle == .struct && classStyle == .class && arrayStyle == .collection && enumMirror.displayStyle == .enum,
        "这四种 displayStyle 就是 Mirror 全部的分类能力 —— 它能读值、能分类型，但没有任何写接口，也列不出「这个模块里有哪些类」；"
        + "反过来 runtime 能列类、能改实现，却看不见 struct/enum/泛型。两套反射各管一半，谁也不能替谁。")

    let arrBridged = [1, 2, 3] as AnyObject
    let dicBridged = ["k": 1] as AnyObject
    let arrName = NSStringFromClass(type(of: arrBridged))
    let dicName = NSStringFromClass(type(of: dicBridged))
    line("  桥接之后再问 runtime：Swift 数组在 `id` 位置上的实际类是 \(arrName)，字典是 \(dicName)")
    expect(arrBridged.isKind(of: NSArray.self), "Swift 的 Array/Dictionary/String 一旦落到 `id` 位置上就变成对应的 Foundation 类"
        + "（isKind(of: NSArray) = \(arrBridged.isKind(of: NSArray.self))）：所以 §16 的「copy 之后实际类」那套结论对它们同样成立，"
        + "而 §12 的 KVC 也能直接作用在一个 Swift 数组上。")
    expect(dicName.hasPrefix("_TtGC") && dicName.hasSuffix("$"), "同一个 NSStringFromClass，对泛型类就不反解了：字典的名字是 \(dicName)"
        + "（_TtGC…$ 是 Swift 泛形的原始 mangling）—— 崩溃日志里两种名字都会出现，认得前缀才知道哪条路能反解。")

    var objcSide: [String] = []
    var n: UInt32 = 0
    if let ps = class_copyPropertyList(RTSwiftVisible.self, &n) {
        for i in 0..<n { objcSide.append(String(cString: property_getName(ps[Int(i)]))) }
        free(ps)
    }
    var mirrorSide: [String] = []
    for c in Mirror(reflecting: RTSwiftVisible()).children { mirrorSide.append(c.label ?? "?") }
    line("  同一个类，两套反射各看到什么：runtime 的属性表 = \(objcSide.joined(separator: ","))；Mirror 的 children = \(mirrorSide.joined(separator: ","))")
    expect(!objcSide.contains("swiftStored") && mirrorSide.contains("swiftStored"),
        "runtime 只认 @objc 那一个（\(objcSide.joined(separator: ","))），Mirror 两个都认（\(mirrorSide.joined(separator: ","))）—— "
        + "结论：Swift 侧的通用反射用 Mirror/Codable，要和 UIKit/KVO/xib 打交道的部分才需要 runtime，两边不能互相替代。")
}

// ============================================================
// §23 本章的边界（哪些量到了、哪些只能记、哪些留给真机）
// ============================================================
line("\n== §23 本章的边界 ==")
line("  量到了的：选择器唯一性、nil 返回值表、objc_msgSend 家族（含 x86_64 的 stret 分路）、类型编码全表、属性三件套、")
line("            ivar 偏移与直写、关联对象、四级转发顺序、换实现的类级别影响、分类与 +load 顺序、协议的方法描述、")
line("            KVC 候选顺序与集合运算符、KVO 的 isa 换脸与通知时机、内省四问、target-action/delegate/通知、")
line("            copy 的实际类、@try 的匹配规则，以及 Swift 侧的名字（普通类反解成「模块名.类名」，泛型和编译器合成的类型仍是 _TtC/_TtGC…$）、")
line("            @objc vs @objc dynamic 两条调用路径、block 版 KVO（含「不传 options 时 newValue 全是 nil」）、通知中心、Mirror 与 runtime 各管哪一半。")
line("  只能记不跑的（示例一行都没执行，全部来自独立探针进程，正文以「探针记录」引用原文）：")
line("    unrecognized selector、valueForUndefinedKey、给标量键塞 nil、KVO 的四条误用（两参数接口在 iOS 上不存在、")
line("    没实现 observeValueForKeyPath、摘错观察者、重复注册）、分类里加 ivar 的编译错误、钩子自己调自己的无限递归、")
line("    把 void 方法的返回值当对象用（那次侥幸没崩的调用）、objc_msgSend_stret 参数顺序写错。")
line("  真机才量得到的：KVO 在后台线程被 UIKit 观察时的表现、+load 里调 UIKit 引起的死锁、Swift 并发检查下 perform 的告警。")
line("  这本书（第 5/6/7 章）里已经过时的写法，本章一律按今天的规则改写：手工 retain/release/autorelease 计数")
line("    （ARC 之后不该出现，§7 只讲「ARC 会在哪里插哪几条调用」）、两参数 addObserver:forKeyPath:（iOS 上根本没有）、")
line("    把非正式协议当主要手段（今天用 @optional 正式协议，§11）、把「消息转发」和「委托」混为一谈（§8 是 runtime 兜底，§15 是设计约定）。")

if failures > 0 {
    line("\n有 \(failures) 条断言失败")
} else {
    line("\n全部断言通过")
}
line("==== 27 结束 ====")
