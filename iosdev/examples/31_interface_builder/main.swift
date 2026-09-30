// ============================================================
// 31 - Interface Builder：故事板、XIB 与代码之间的接线
//
// 《跟着项目学iOS应用开发：基于Swift 4》第 2 章（Interface Builder 介绍：2.2 用故事板
// 建界面、2.3 定位元素、2.4 导入图像素材）与第 4 章（掷骰子游戏：4.2 建立代码与界面
// 元素的关联、4.3 IBOutlet/IBAction 调试、4.7 用数组换显示）讲的是同一件事：
// **一张用 XML 画出来的界面，怎么和 Swift 里的类接上线**。
//
// 那本书的判据是「Xcode 里拖一条线、跑起来看看有没有显示」，出了错就靠红点和一句
// 「this class is not key value coding-compliant for the key ...」。本章把这套东西
// 全部搬到命令行：
//   1) 界面文件（.storyboard / .xib）由本仓库的 run-all.sh 调 **ibtool** 编成
//      .storyboardc / .nib，和二进制放进同一个目录 —— 命令行可执行文件的
//      Bundle.main 就是那个目录（§1 量），所以 UIStoryboard(name:bundle:nil) 直接可用；
//   2) 「拖一条线」换成 XML 里的 <connections>/<outlet>/<action>/<segue> 三元组，
//      本章把每一条连接都在运行时验一遍（谁接上了、值是几、什么时候接上的）；
//   3) 所有「跑起来才知道错了」的写法一律不进本文件，改由 probes/ 现跑并抄原文
//      —— 六条判定要求编译日志为空、退出码 0、stderr 为空，而 Interface Builder 的
//      绝大多数错误既不在编译期（ibtool 对写错的类名零诊断，探针 b01/b02），
//      也不在 stderr 之外（UIKit 用 NSLog 把失败打到 stderr，探针 r06/r07）。
//
// 本章最值得记住的一条：**故事板的错误是运行时的、而且是静默的**。
// customClass 写错、customModule 写错、场景不可达 —— ibtool 全部 rc=0 放行，
// 前者在运行时退回 plain UIViewController（§7/§8 主线量），后者连 nib 都不生成（§3）。
// ============================================================

import Foundation
import UIKit
import SwiftUI

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
// ObjC 对象的 description 里带内存地址（<UIImage:0x600003014090 …>）。这一章要读的是
// 描述里那些字段，不是地址；而 run-all.sh 最后一条判定要求 debug 与 release 两份 stdout
// 逐字节相同 —— 两个进程各自分配的地址必然不一样。所以输出前统一把地址抹掉。
func noAddr(_ s: String) -> String {
    let chars = Array(s)
    var out = ""
    var i = 0
    while i < chars.count {
        let prevIsWord = i > 0 && (chars[i - 1].isLetter || chars[i - 1].isNumber)
        if chars[i] == "0", !prevIsWord, i + 2 < chars.count, chars[i + 1] == "x" {
            var j = i + 2
            while j < chars.count, chars[j].isHexDigit { j += 1 }
            // 只处理真地址那么长的十六进制串：'320x200' 这种尺寸写法前一个字符是数字，
            // 而 '0xdeadbeef' 才是指针。
            if j - (i + 2) >= 8 {
                out += "0x…"
                i = j
                continue
            }
        }
        out.append(chars[i])
        i += 1
    }
    return out
}
func expect(_ condition: Bool, _ parts: String...) {
    print(noAddr("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))"))
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(noAddr(s)) }
func section(_ n: Int, _ title: String) { print("\n== §\(n) \(title) ==") }

// 读一份 .storyboardc 包里的「场景标识符 → nib 名」查找表（§2 先见到它，§9/§10 拿它做账）。
// 用 Foundation 读 plist，不去手解二进制 plist 的字节格式。
func lookupTable(_ package: URL) -> [String: String] {
    let info = NSDictionary(contentsOf: package.appendingPathComponent("Info.plist"))
    return (info?["UIViewControllerIdentifiersToNibNames"] as? [String: String]) ?? [:]
}
// 包目录里的 nib 文件名，排序后比计数方便些。
func nibNames(_ package: URL) -> [String] {
    let all = (try? FileManager.default.contentsOfDirectory(atPath: package.path)) ?? []
    return all.filter { $0.hasSuffix(".nib") }.sorted()
}
// UIControl 的 target 列表在 Swift 侧被 AnyHashable 包了一层，直接打印类名会看到
// "Swift.AnyHashable"；取 .base 才是真正那个对象（§15/§17 都要读这张表）。
func targetNames(_ c: UIControl) -> [String] {
    c.allTargets.map { String(reflecting: type(of: ($0 as AnyHashable).base)) }.sorted()
}
// 沿 ObjC 运行时往上问父类名，用来量那些「没有公开头文件、只能从运行时看」的类（§17）。
func superclassChain(of value: Any) -> [String] {
    var names: [String] = []
    var current: AnyClass? = object_getClass(value as AnyObject)
    while let c = current {
        names.append(NSStringFromClass(c))
        current = class_getSuperclass(c)
    }
    return names
}
// 一个类**自己**声明的选择器清单（不含父类继承来的）。§20 用它问出「unwindAction 那一格
// 到底存进了谁身上」——这些私有模板类没有公开头文件，运行时是唯一能读它的入口。
func methodNames(of value: Any) -> [String] {
    guard let cls = object_getClass(value as AnyObject) else { return [] }
    var count: UInt32 = 0
    guard let list = class_copyMethodList(cls, &count) else { return [] }
    defer { free(list) }
    var names: [String] = []
    for i in 0..<Int(count) {
        names.append(NSStringFromSelector(method_getName(list[i])))
    }
    return names.sorted()
}

// 记录「哪个钩子在什么时刻跑了」——本章多条断言靠它，而不是靠人眼看顺序。
var hookLog: [String] = []

// ============================================================
// 被故事板引用的那些类。
//
// 故事板里的 customModule="interface_builder" 必须等于本示例的 Swift 模块名
// （run-all.sh 用 -module-name "${目录名#*_}" 传的），customClass 必须等于 Swift 类名，
// 两者拼起来是 ObjC 运行时里的类名 "interface_builder.EntryVC"。
// 拼错的后果由 §7/§8 现场量，探针 b01/b02 量的是「ibtool 根本不拦」。
// ============================================================

final class EntryVC: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tapButton: UIButton!
    @IBOutlet var segueButton: UIButton!
    @IBOutlet var pipView: UIImageView!
    @IBOutlet var titleLeading: NSLayoutConstraint!

    // @IBInspectable 不是故事板专用的语法，它就是一个「可以被写进
    // userDefinedRuntimeAttributes 的 keyPath」——§14 量它真被填进来了。
    @IBInspectable var badge: Double = 0
    @IBInspectable var caption: String = ""
    @IBInspectable var flagged: Bool = false

    var tapLog: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        // 把「这一刻属性里已经是什么」一起记下来：§5/§11/§14 就靠这些字符串判时序。
        hookLog.append("awakeFromNib：badge=\(badge) caption=\"\(caption)\" flagged=\(flagged) titleLabel=\(titleLabel?.text ?? "nil")")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        hookLog.append("viewDidLoad：titleLabel=\(titleLabel?.text ?? "nil") badge=\(badge)")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hookLog.append("viewWillAppear")
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        hookLog.append("EntryVC.prepare(\(segue.identifier ?? "无标识符"))："
            + "目的地=\(String(reflecting: type(of: segue.destination))) "
            + "目的地视图已加载=\(segue.destination.isViewLoaded) "
            + "sender=\(sender.map { "\($0)" } ?? "无")")
        // 书 4.2「建立代码与界面元素的关联」里 prepare 的唯一用途就是给目的地传值。
        if let d = segue.destination as? SecondVC { d.inherited = sender as? String ?? "没给" }
    }
    @IBAction func didTap(_ sender: UIButton) {
        tapLog.append("didTap: \(sender.currentTitle ?? "无名") sender就是那颗按钮=\(sender === tapButton)")
    }
}

final class SecondVC: UIViewController {
    @IBOutlet var messageLabel: UILabel!
    var inherited: String?
    override func awakeFromNib() {
        super.awakeFromNib()
        // 同样把「此刻有什么」写进账本：§14 用它证明 Inspector 那格在解控制器 nib 时就到位了。
        hookLog.append("Second.awakeFromNib：messageLabel=\(messageLabel?.text ?? "nil") title=\"\(title ?? "nil")\"")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        hookLog.append("Second.viewDidLoad：messageLabel=\(messageLabel?.text ?? "nil") title=\"\(title ?? "nil")\"")
    }
}

final class AlphaVC: UIViewController {
    // 这个 outlet 连的是 <navigationItem>，它是 viewController 元素的直接子对象 —— 住在**控制器 nib** 里。
    @IBOutlet var navItem: UINavigationItem!
    var seenSegues: [String] = []
    var lastSegue: UIStoryboardSegue?
    override func awakeFromNib() {
        super.awakeFromNib()
        hookLog.append("Alpha.awakeFromNib：navItem.title=\"\(navItem?.title ?? "nil")\"")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        hookLog.append("Alpha.viewDidLoad：navItem.title=\"\(navItem?.title ?? "nil")\"")
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        lastSegue = segue
        seenSegues.append("\(segue.identifier ?? "无标识符")→\(String(reflecting: type(of: segue.destination)))")
        hookLog.append("Alpha.prepare(\(segue.identifier ?? "无标识符"))："
            + "目的地=\(String(reflecting: type(of: segue.destination))) "
            + "目的地视图已加载=\(segue.destination.isViewLoaded) "
            + "sender=\(sender.map { "\($0)" } ?? "无")")
    }
    // 故事板里那条 unwind segue 的 unwindAction="unwindToAlpha:" 就指向这个方法。
    @IBAction func unwindToAlpha(_ sender: UIStoryboardSegue) {
        hookLog.append("unwindToAlpha：sender.source=\(String(reflecting: type(of: sender.source))) "
            + "sender.destination=\(String(reflecting: type(of: sender.destination)))")
    }
}

final class BetaVC: UIViewController {
    @IBOutlet var markLabel: UILabel!
    @IBOutlet var unwindButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        hookLog.append("Beta.viewDidLoad：markLabel=\"\(markLabel?.text ?? "nil")\" title=\"\(title ?? "nil")\"")
    }
    // Beta 场景里那颗按钮在 XML 里直连 <exit>（kind="unwind"）。§20 用两条路触发它：
    // 控制器上按 identifier 的 performSegue，和绕过控制器直接派发按钮表里那句 perform:。
    // 两条路都会先经过这里 —— prepare 是**发起方**（下层那个）的，不是上层那个 unwind 目标的。
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        hookLog.append("Beta.prepare(\(segue.identifier ?? "无标识符"))："
            + "目的地=\(String(reflecting: type(of: segue.destination))) "
            + "目的地视图已加载=\(segue.destination.isViewLoaded) "
            + "sender=\(sender.map { String(reflecting: type(of: $0)) } ?? "无")")
    }
}

final class ModalVC: UIViewController {}

// 故事板里 kind="custom" 的 segue 用 customClass 指定这个类；perform() 是唯一
// 由你写的那一步（§19）。
final class FadeSegue: UIStoryboardSegue {
    override func perform() {
        hookLog.append("FadeSegue.perform："
            + "\(String(reflecting: type(of: source))) → \(String(reflecting: type(of: destination)))")
    }
}

// §25 的对照组二：同一个界面用纯代码搭一遍。没有界面文件、没有 outlet、没有连接，
// 视图全在 loadView() 里手工装配。
final class CodeScreenVC: UIViewController {
    let madeLabel = UILabel()
    let madeButton = UIButton(type: .system)
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .white
        madeLabel.text = "欢迎"
        madeLabel.frame = CGRect(x: 24, y: 120, width: 200, height: 44)
        madeButton.setTitle("点我", for: .normal)
        madeButton.frame = CGRect(x: 24, y: 200, width: 120, height: 44)
        root.addSubview(madeLabel)
        root.addSubview(madeButton)
        madeButton.addTarget(self, action: #selector(didTapCode(_:)), for: .touchUpInside)
        view = root
        hookLog.append("CodeScreenVC.loadView：subviews = \(root.subviews.count)")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        hookLog.append("CodeScreenVC.viewDidLoad")
    }
    @objc func didTapCode(_ sender: UIButton) {
        hookLog.append("didTapCode：sender 就是那颗按钮 = \(sender === madeButton)")
    }
}

// §25 的对照组三：同一个界面用 SwiftUI 写一遍。它是个 struct（值），body 是算出来的。
struct MeasuredCard: View {
    let titleText: String
    var body: some View {
        bodyRuns += 1
        return Text(titleText).font(.system(size: 20))
    }
}
var bodyRuns = 0

// Card.xib 里那个标题标签自己声明的类：唯一目的就是给 nib 解码的「被解出来的对象」
// 装一个 awakeFromNib 探针，好跟 File's Owner（它不在那个名单里，§21）对照。
final class CardLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        hookLog.append("CardLabel.awakeFromNib：text=\"\(text ?? "nil")\"")
    }
}

// Card.xib 的 File's Owner 就是这个类（§21/§22）。
final class CardOwner: NSObject {
    @IBOutlet var rootView: UIView!
    @IBOutlet var titleLabel: UILabel!
    var awakeRan = false
    override func awakeFromNib() {
        super.awakeFromNib()
        awakeRan = true
        // 同样记「这一刻连接上了没有」：XIB 这条路的时序也靠这两个字（§22）。
        hookLog.append("CardOwner.awakeFromNib：rootView=\(rootView == nil ? "nil" : "已连上") titleLabel=\"\(titleLabel?.text ?? "nil")\"")
    }
}

// ============================================================
// §1 命令行可执行文件的 Bundle.main：界面文件放哪儿才找得到
// ============================================================
section(1, "命令行里的 Bundle.main：产物目录就是 bundle（本书 2.1 的 .app 对照）")
// 书 2.1 那一串 Xcode 向导的产物是一个 Hello World.app；本章的产物是一个裸可执行文件。
// 两者的 Bundle.main 语义不同，而这正是本章所有断言能跑起来的前提。
let mainBundle = Bundle.main
expect(FileManager.default.fileExists(atPath: mainBundle.bundlePath),
       "Bundle.main.bundlePath 是一个真实存在的目录：\(mainBundle.bundlePath)")
expect(mainBundle.resourcePath == mainBundle.bundlePath,
       "裸可执行文件的 resourcePath 就等于 bundlePath（.app 里 resourcePath 是 Contents/Resources）：\(mainBundle.resourcePath ?? "nil")")
expect(mainBundle.bundleIdentifier == nil,
       "bundleIdentifier 是 nil：没有 Info.plist 就没有 bundle id —— 但这一条不会在什么地方打出日志来（本章判定 3 全程 stderr 0 字节）。§24 会量到：松散 PNG 的按名字查找照常成功，找不到时也只是返回 nil，没有一句\"identifier (null)\"之类的提示")
expect((mainBundle.infoDictionary ?? [:]).isEmpty,
       "infoDictionary 是空的：书 2.1 里 Xcode 替你写的那份 Info.plist，这里一份都没有")
// 界面文件是怎么被找到的：run-all.sh 先编 Swift，再调 ibtool 把 .storyboardc/.nib
// 连同 Resources/ 的内容一起放进二进制所在目录。
let foundNib = mainBundle.url(forResource: "Main", withExtension: "storyboardc")
expect(foundNib != nil, "Bundle 能直接定位到编译好的故事板包：\(foundNib?.lastPathComponent ?? "nil")")
let cardNib = mainBundle.url(forResource: "Card", withExtension: "nib")
expect(cardNib != nil, "XIB 编出来的 .nib 也在同一个目录：\(cardNib?.lastPathComponent ?? "nil")")
// .storyboardc 不是文件而是一个包（目录），里面的东西 §2 逐个数。

// ============================================================
// §2 ibtool 做了什么：一份 XML 编出几个 nib
// ============================================================
section(2, "ibtool 做了什么：一份 XML 编出几个 nib")
// 书 2.2 的说法是「Xcode 把故事板编译进 App」。编译器是 ibtool（实际干活的是它的
// 守护进程 ibtoold），产物是一个包目录。把包里的文件名逐个数出来：
let packageURL = mainBundle.url(forResource: "Main", withExtension: "storyboardc")!
let contents = (try? FileManager.default.contentsOfDirectory(atPath: packageURL.path)) ?? []
expect(contents.contains("Info.plist"), "包里有一份 Info.plist：它是「场景标识符 → nib 名」的查找表（§9 要用它做账）")
// 3 个场景编出 6 个 nib —— 数量对不上不是漏编，是因为一个场景被拆成两条 nib
// （控制器一条、视图一条）。这条分成两半的事实到 §5 和 §11 才有运行时 payoff：
// instantiate 只解前者，loadView 才解后者。
let nibs = nibNames(packageURL)
expect(nibs.count == 6, "Main.storyboard 的 3 个场景编出 \(nibs.count) 个 nib：\(nibs)")
// 命名规则不是随手起的：控制器 nib 用「类名-objectID」，视图 nib 用「objectID-view-视图ID」。
expect(nibs.contains("UIViewController-ENT-01-001.nib"),
       "入口场景的控制器 nib 叫 UIViewController-ENT-01-001.nib —— 后半截就是 XML 里那个 id 属性")
expect(nibs.contains("ENT-01-001-view-vEnt.nib"),
       "它的视图单独一个 nib：ENT-01-001-view-vEnt.nib，尾巴上的 vEnt 是 <view id=\"vEnt\"> 的 id")
expect(nibs.contains("TheSecond.nib"),
       "有 storyboardIdentifier 的场景，nib 直接用那个标识符命名（TheSecond.nib）而不是 objectID")
// Info.plist 里一共三个键：入口点、版本号、查找表。
let mainInfo = NSDictionary(contentsOf: packageURL.appendingPathComponent("Info.plist")) as? [String: Any]
expect(mainInfo?["UIStoryboardDesignatedEntryPointIdentifier"] as? String == "UIViewController-ENT-01-001",
       "UIStoryboardDesignatedEntryPointIdentifier 记的就是 XML 里 initialViewController 指向的那个场景：\(mainInfo?["UIStoryboardDesignatedEntryPointIdentifier"] as? String ?? "nil")")
let mainMap = lookupTable(packageURL)
expect(mainMap.keys.sorted() == ["PlainScreen", "TheSecond", "UIViewController-ENT-01-001"],
       "查找表只有三项（3 个场景都在），键是 storyboardIdentifier（没有就退化成「类名-objectID」）：\(mainMap.keys.sorted())")

// ============================================================
// §3 不可达场景会被无声删掉：本章最危险的一条
// ============================================================
section(3, "不可达的场景会被 ibtool 无声删掉")
// 这个场景（PLN-03-003）既不是入口点，也没有连到任何 segue 上 —— 在 Xcode 里它就是
// 一块「孤立的原稿」。ibtool 对它的态度是：给一条 warning，然后把它的 nib 编出来
// 或者干脆不编。区别只取决于有没有 storyboardIdentifier。
let plain = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlainScreen")
expect(NSStringFromClass(type(of: plain)) == "UIViewController",
       "没有任何 customClass 的场景 → 就是 plain UIViewController：\(NSStringFromClass(type(of: plain)))")
let plainNibs = nibNames(packageURL).filter { $0.contains("PLN") || $0.contains("Plain") }
expect(plainNibs == ["PLN-03-003-view-vPln.nib", "PlainScreen.nib"],
       "加了 storyboardIdentifier 之后它的两个 nib 才出现在包里：\(plainNibs)")
// 把 storyboardIdentifier 去掉再编一次，ibtool 是 rc=0 + 一条 warning，产物里直接没有这个场景
// （探针 b03 抄了那条 warning 的原文，探针 b04 量的是「删掉之后 nib 不见了」）。
// 注意这里**没有**去碰 plain.view：UIViewController 的 view 是 get-only 且访问即触发
// loadView（§11 量的就是这条），一旦在这里加载了，§5 那条「取出来一个钩子都没跑」
// 就被自己写坏了。isViewLoaded 才是只问不碰的那一个。
expect(!plain.isViewLoaded,
       "刚取出来的场景视图还没加载：isViewLoaded = \(plain.isViewLoaded)")

// ============================================================
// §4 加载故事板：name 与 bundle 两个参数
// ============================================================
section(4, "加载故事板：UIStoryboard(name:bundle:)")
// 书里从来没写过这一行 —— 它是 Xcode 启动流程替做的（读 Info.plist 的
// UIMainStoryboardFile / UILaunchStoryboardName）。手写就两个参数。
let sb = UIStoryboard(name: "Main", bundle: nil)
expect(type(of: sb) == UIStoryboard.self, "bundle: nil 意思是「拿 Bundle.main」，类型就是 UIStoryboard")
// 名字里的 .storyboardc 后缀不写：给 "Main"，找的是 Main.storyboardc。
let sb2 = UIStoryboard(name: "Nav", bundle: nil)
expect(String(describing: sb2) != String(describing: sb),
       "同一个 bundle 里可以有多份故事板，靠名字区分：Main 与 Nav 是两个对象")
// 名字不存在时的下场不是返回 nil，是当场抛 ObjC 异常（探针 r01 抄了原文与栈）。
expect(FileManager.default.fileExists(atPath: mainBundle.bundlePath + "/NoSuch.storyboardc") == false,
       "本章不演示那次崩溃：bundle 里确实没有 NoSuch.storyboardc，取它 = 抛异常（探针 r01）")

// ============================================================
// §5 入口点：instantiateInitialViewController()
// ============================================================
section(5, "入口点：instantiateInitialViewController()")
// 书 2.2 那句「故事板左边那个箭头指着的就是入口」，在编译产物里就是 Info.plist 的
// UIStoryboardDesignatedEntryPointIdentifier（§2 已经读过它）。
// 前几节也实例化过别的对象，账本已经写过；这一节只问「这一个对象被取出来的那一刻」，
// 所以先把 hookLog 清零再取。
hookLog.removeAll(keepingCapacity: true)
let entry = sb.instantiateInitialViewController()
expect(entry != nil, "instantiateInitialViewController() 给出入口场景的控制器：\(String(describing: entry.map { NSStringFromClass(type(of: $0)) }))")
expect(hookLog.count == 1 && hookLog.first?.hasPrefix("awakeFromNib") == true,
       "取出来这一刻 awakeFromNib 已经跑完了：\(hookLog) —— 解「控制器 nib」就发生在 instantiate 里，不等视图加载")
expect(hookLog.first?.contains("badge=7") == true,
       "而且 Inspector 里那三格（§14）此时已经生效：\(hookLog.first ?? "无")")
expect(hookLog.first?.contains("titleLabel=nil") == true,
       "可 outlet 此刻还是连不上：\(hookLog.first ?? "无") —— 标签住在另一个 nib 里（§2 数的 6 个就是这么分的）")
// 「没有箭头就返回 nil」这一句本章不留在猜测里：NoEntry.storyboard 就是这样一个文件 ——
// <document> 元素上根本没有 initialViewController 属性。它的唯一场景写了
// storyboardIdentifier（不写就退化成 §3 那条：连 nib 都不生成），所以 ibtool 对它
// 零诊断（判定 1 的编译日志里一个字节都没有），产物照旧是 Info.plist + 两条 nib。
let noEntrySB = UIStoryboard(name: "NoEntry", bundle: nil)
let noEntryURL = mainBundle.url(forResource: "NoEntry", withExtension: "storyboardc")!
let noEntryMap = lookupTable(noEntryURL)
expect(nibNames(noEntryURL).count == 2,
       "没有入口点的故事板也照样编出了产物，一个场景两条 nib：\(nibNames(noEntryURL))")
expect((NSDictionary(contentsOf: noEntryURL.appendingPathComponent("Info.plist")) as? [String: Any])?["UIStoryboardDesignatedEntryPointIdentifier"] == nil,
       "而 Info.plist 里就是没有那一格（对照 §2 读到的 UIViewController-ENT-01-001）：\(String(describing: (NSDictionary(contentsOf: noEntryURL.appendingPathComponent("Info.plist")) as? [String: Any])?["UIStoryboardDesignatedEntryPointIdentifier"]))")
expect(noEntrySB.instantiateInitialViewController() == nil,
       "所以 instantiateInitialViewController() 返回 nil，不抛异常：\(String(describing: noEntrySB.instantiateInitialViewController())) —— 箭头这件事在产物里就是一格可选的键，没有它就是没有")
expect(noEntryMap.keys.sorted() == ["LonelyScreen"],
       "查找表里只有那一个场景，键是它的 storyboardIdentifier：\(noEntryMap.keys.sorted())")
expect(NSStringFromClass(type(of: noEntrySB.instantiateViewController(withIdentifier: "LonelyScreen"))) == NSStringFromClass(UIViewController.self),
       "按标识符照样取得到，只是它没有 customClass，所以就是 plain UIViewController：\(NSStringFromClass(type(of: noEntrySB.instantiateViewController(withIdentifier: "LonelyScreen")))) —— §8 那条「静默退回」在这里是合法行为")

// ============================================================
// §6 __kindof 到 Swift：为什么必须自己 downcast
// ============================================================
section(6, "签名里的 __kindof：为什么编译器不帮你转成子类")
// ObjC 声明是 `- (nullable __kindof UIViewController *)instantiateInitialViewController;`
// __kindof 在 Swift 里塌回 UIViewController —— 所以书里那句「点一下就能看到 titleLabel」
// 在代码里必须先转型。
let rawEntry: UIViewController? = sb.instantiateInitialViewController()
expect(rawEntry is EntryVC, "静态类型是 UIViewController，动态类型才是真正的子类：\(String(describing: rawEntry.map { NSStringFromClass(type(of: $0)) }))")
guard let first = rawEntry as? EntryVC else {
    line("  FAIL 转型失败，后面的节都跑不下去")
    print("==== 31 结束 ====")
    exit(1)
}
// 拿不到子类成员这件事是编译期就拦的，探针 e01 抄了那句原话：
//   error: value of type 'UIViewController' has no member 'titleLabel'
expect(first.titleLabel == nil, "downcast 之后能写 .titleLabel 了，但此刻还是 nil —— 视图没加载，连接还没发生：\(String(describing: first.titleLabel))")

// ============================================================
// §7 customClass / customModule：三段字符串要对齐
// ============================================================
section(7, "类绑定的三段字符串：customClass、customModule 与模块名")
// XML 里写的是 <viewController id="ENT-01-001" customClass="EntryVC" customModule="interface_builder">。
// UIKit 拿这两个属性去 ObjC 运行时问一个类名，问的是「模块名.类名」这一个完整字符串，
// 所以第三段其实不是 XML 写的 —— 它是 swiftc 的 -module-name 给的
// （run-all.sh 里传的是 ${目录名#*_}，31_interface_builder → interface_builder）。
// 三段对齐时，运行时类名就是这一个字符串：
let runtimeName = NSStringFromClass(type(of: first))
expect(runtimeName == "interface_builder.EntryVC",
       "绑定成功时 NSStringFromClass 给出的就是「模块名.类名」：\(runtimeName)")
// Swift 侧有两个打印类名的标准库函数，和 NSStringFromClass 各不相同，绑定时只有
// 第三个有用（它才是运行时问的那个名字）：
expect(String(reflecting: type(of: first)) == runtimeName,
       "String(reflecting:) 带模块前缀，和运行时同名：\(String(reflecting: type(of: first)))")
expect(String(describing: type(of: first)) == "EntryVC",
       "String(describing:) 只有类名，没有模块前缀 —— 拿它去比对 XML 里的 customClass 才对得上：\(String(describing: type(of: first)))")
// 反过来验证「模块前缀是运行时类名的一部分」，而不是 NSStringFromClass 加的装饰：
expect(NSClassFromString("interface_builder.EntryVC") != nil,
       "NSClassFromString(\"interface_builder.EntryVC\") 找得到 —— customModule 那一段是在问运行时")
expect(NSClassFromString("EntryVC") == nil,
       "去掉模块前缀就找不到：NSClassFromString(\"EntryVC\") = \(String(describing: NSClassFromString("EntryVC")))。所以 customModule 填错时 UIKit 不是「找错了类」，是「一个也没找到」")
// 三个字符串各写错一段会怎样 —— ibtool 一律零诊断（探针 b01/b02），运行时 §8 见分晓。

// ============================================================
// §8 绑定写错的运行时命运：全部静默
// ============================================================
section(8, "绑定写错之后：UIKit 一声不响地退回 plain UIViewController")
// 本章的三份故事板之外，另外编了三份「故意写错」的（在 probes/ 里，主线不放坏文件）。
// 这里跑的是它们唯一的**安全**部分：类名或模块名写错，取出来的对象类型。
// 探针 b01/b02 把三种写错的样子各编了一份产物、各取了一次对象，结论抄在这里：
//   customClass="GhostVC"（类不存在）        → UIViewController
//   customModule="wrong_module_name"（类存在）→ UIViewController
//   两个属性都不写                            → UIViewController
// 也就是说：绑定失败不会崩、不会打日志，只是**你的代码永远拿不到那个对象**。
// §3 里那个没有 customClass 的 PlainScreen 场景，就是这条的合法版本。
expect(NSStringFromClass(type(of: plain)) == NSStringFromClass(UIViewController.self),
       "「忘了填 customClass」和「填错了」在运行时是同一个结果：\(NSStringFromClass(type(of: plain)))")
let wrongLike = plain as? EntryVC
expect(wrongLike == nil, "拿它当 EntryVC 用就是 nil —— 这正是书 4.3 那句「为什么我的 outlet 全是空的」的根因之一")

// ============================================================
// §9 storyboardIdentifier 不等于 id：查找表就是 Info.plist
// ============================================================
section(9, "storyboardIdentifier 与 XML 的 id 是两回事")
// XML 里那个 id="SEC-02-002" 是 IB 对象图内部的编号；只有另一个属性
// storyboardIdentifier="TheSecond" 才会进 Info.plist 那张查找表。
let secondByID = sb.instantiateViewController(withIdentifier: "TheSecond")
expect(NSStringFromClass(type(of: secondByID)) == "interface_builder.SecondVC",
       "用 storyboardIdentifier 取：\(NSStringFromClass(type(of: secondByID)))")
// 用 objectID 去取会抛异常（探针 r02 抄了那句 NSInvalidArgumentException 原文，
// 里面明写着 'doesn't contain a view controller with identifier ...'）。
// 主线先只问查找表——异常那一下不留在进程里。
expect(mainMap["SEC-02-002"] == nil,
       "XML 里 SEC-02-002 那个 id 从来没进查找表：\(mainMap.keys.sorted()) 里没有它 —— 所以 it 不是一个「可以取的键」")
expect(mainMap["TheSecond"] == "TheSecond",
       "进了表的是 storyboardIdentifier，而且键值同名字同 nib：mainMap[\"TheSecond\"] = \(mainMap["TheSecond"] ?? "nil")")
let entry2 = sb.instantiateViewController(withIdentifier: "UIViewController-ENT-01-001")
expect(NSStringFromClass(type(of: entry2)) == "interface_builder.EntryVC",
       "没写 storyboardIdentifier 的场景，查找表里的键就是它的 objectID（带 UIViewController- 前缀）：\(NSStringFromClass(type(of: entry2)))")
// 除了这张查找表，iOS 13 起还有第二条取对象的路（给一个 creator 闭包）。它不属于
// 「标识符」这个话题，所以单独放到 §13 量。

// ============================================================
// §10 被 relationship 收养的场景不在查找表里
// ============================================================
section(10, "被 relationship 收养的场景：nav.storyboardc 的查找表少一项")
// Nav.storyboard 里有 4 个场景（导航控制器 + Alpha + Beta + Modal），但 Alpha 是
// 导航控制器的 rootViewController 关系目标 —— 它被编进了导航控制器那个 nib 里面。
let navSB = UIStoryboard(name: "Nav", bundle: nil)
let navURL = mainBundle.url(forResource: "Nav", withExtension: "storyboardc")!
let navNibs = nibNames(navURL)
expect(navNibs.count == 6,
       "Nav 的 4 个场景编出 \(navNibs.count) 个 nib：\(navNibs)")
// 少的那一个是 Alpha 的**控制器** nib：视图 nib（A-11-011-view-vA.nib）在，
// 却没有 UIViewController-A-11-011.nib —— 因为 Alpha 已经作为导航控制器 nib 里的
// 一个对象被一起编码进去了。
expect(navNibs.contains("A-11-011-view-vA.nib") && !navNibs.contains("UIViewController-A-11-011.nib"),
       "Alpha 只有视图 nib、没有控制器 nib：视图 nib 在 = \(navNibs.contains("A-11-011-view-vA.nib"))，控制器 nib 在 = \(navNibs.contains("UIViewController-A-11-011.nib"))")
let navMap = lookupTable(navURL)
expect(navMap.keys.sorted() == ["UINavigationController-NAV-10-010", "UIViewController-B-12-012", "UIViewController-M-14-014"],
       "查找表只有 3 项，Alpha 不在里面：\(navMap.keys.sorted()) —— 单独取不到，只能顺着关系走")
let navRoot = navSB.instantiateInitialViewController() as! UINavigationController
expect(NSStringFromClass(type(of: navRoot.viewControllers[0])) == "interface_builder.AlphaVC",
       "但顺着关系走就能拿到它：nav.viewControllers[0] = \(NSStringFromClass(type(of: navRoot.viewControllers[0])))，栈深 \(navRoot.viewControllers.count)")
expect(navRoot.viewControllers[0].navigationController === navRoot,
       "这条关系是真的接上了：子控制器的 navigationController 指回那个导航控制器")

// ============================================================
// §11 连接的时机：一个场景两条 nib，两个钩子
// ============================================================
section(11, "连接的时机：instantiate 解控制器 nib，loadView 解视图 nib")
// 书 4.2 拖完线就跑起来了，从来没说过「线是什么时候接上的」。§5 已经量到
// awakeFromNib 在 instantiate 里就跑完了，而 outlet 那时还是 nil ——
// 这一节把两半对上：连接发生在**视图 nib** 被解的那一刻，也就是 loadView。
hookLog.removeAll(keepingCapacity: true)
let fresh = sb.instantiateInitialViewController() as! EntryVC
expect(hookLog.count == 1, "实例化只跑了一个钩子：\(hookLog)")
expect(fresh.titleLabel == nil,
       "刚实例化，outlet 全 nil：\(String(describing: fresh.titleLabel)) —— 控制器对象和它的视图是两条 nib、两次解码")
fresh.loadViewIfNeeded()
expect(hookLog.count == 2 && hookLog.last?.hasPrefix("viewDidLoad") == true,
       "loadViewIfNeeded() 只多了 viewDidLoad 这一个钩子：\(hookLog)")
expect(hookLog.last?.contains("titleLabel=欢迎") == true,
       "到 viewDidLoad 里已经读得到值了，说明连接在这之前完成：\(hookLog.last ?? "无")")
expect(fresh.titleLabel?.text == "欢迎",
       "同上，事后读也一样：titleLabel.text = \(fresh.titleLabel?.text ?? "nil")")
expect(fresh.tapButton?.currentTitle == "点我",
       "按钮的连接也一样：currentTitle = \(fresh.tapButton?.currentTitle ?? "nil")")
// viewWillAppear 是「进窗口、准备显示」才跑的，headless 不挂 window 就不会有它。
expect(!hookLog.contains { $0.hasPrefix("viewWillAppear") },
       "viewWillAppear 没跑：\(hookLog) —— 没有 window 就没有 Appearance 回调，这是 §16 那条边界的根")

// ============================================================
// §12 「接上」是什么意思：连的是对象身份，机制是 KVC
// ============================================================
section(12, "连线连的是对象身份：约束也能连，而机制是 KVC")
// §11 把连接钉在了「视图 nib 被解的那一刻」，这一节量「接上」到底是什么：
// UIKit 拿 XML 里 property= 那个字符串，对 owner 做一次 KVC 赋值（setValue:forKey:）。
// 于是两件事直接跟着成立：一、连上的不是副本，是同一个对象，得用 === 才问得出来；
// 二、凡是能被 KVC 赋值的对象都能当 outlet，不限于 UIView —— 书 4.2 只连过标签和按钮。
let cLead = fresh.titleLeading
expect(cLead != nil, "outlet 也可以连到 NSLayoutConstraint（书里只连过 UILabel/UIButton）：\(String(describing: cLead))")
// NSLayoutAttribute 直接字符串插值会打印成「NSLayoutAttribute(rawValue: 5)」，既难看也难懂，
// 所以这里把本章用到的几个翻成名字。
func attrName(_ a: NSLayoutConstraint.Attribute) -> String {
    switch a {
    case .notAnAttribute: return "无属性"
    case .left: return "left"
    case .right: return "right"
    case .top: return "top"
    case .bottom: return "bottom"
    case .leading: return "leading"
    case .trailing: return "trailing"
    case .width: return "width"
    case .height: return "height"
    default: return "其他(\(a.rawValue))"
    }
}
let viewConstraints = fresh.view.constraints
line("     根视图上一共有 \(viewConstraints.count) 条约束，逐条列出来：")
for (i, c) in viewConstraints.enumerated() {
    let fi: Any? = c.firstItem
    let si: Any? = c.secondItem
    let f = fi.map { String(reflecting: type(of: $0)) } ?? "无"
    let s = si.map { String(reflecting: type(of: $0)) } ?? "无"
    line("     约束\(i + 1)  \(f).\(attrName(c.firstAttribute)) ↔ \(s).\(attrName(c.secondAttribute))  常数 = \(c.constant)")
}
// 数出来的 6 条里只有 2 条是 XML 里写的，另外 4 条是 UIKit 自己补的 —— 它把 safeArea 那个
// 布局指南钉在视图的四边上（left/right/top/bottom，常数全 0）。本书 2.3 讲「定位元素」时
// 完全没有这一层，而它解释了「为什么我一条约束都没写，视图却不肯跟着窗口走」。
let onLabel = viewConstraints.filter { ($0.firstItem as? UILabel) === fresh.titleLabel }
expect(viewConstraints.count == 6, "根视图上此刻有 \(viewConstraints.count) 条约束：2 条来自 XML + 4 条是 UIKit 给 safeArea 布局指南补的")
expect(onLabel.count == 2, "以这个标签为第一项的正好是 XML 里那 2 条（cLead、cTop）：\(onLabel.count)")
expect(onLabel.filter { $0.constant == 0 }.isEmpty, "XML 那 2 条的常数都不是 0：\(onLabel.map { $0.constant })")
let uikitOnes = viewConstraints.filter { ($0.firstItem as? UILabel) !== fresh.titleLabel }
expect(uikitOnes.count == 4 && uikitOnes.allSatisfy { $0.constant == 0 },
       "另外 \(uikitOnes.count) 条常数全是 0，第一项都不是标签 —— 它们不是界面内容，是布局基础设施：\(uikitOnes.map { attrName($0.firstAttribute) })")
let sameObject = viewConstraints.first { ($0.firstItem as? UILabel) === fresh.titleLabel && $0.firstAttribute == .leading }
expect(cLead === sameObject,
       "outlet 拿到的就是层级里那一条本身，不是它的拷贝：=== 成立 = \(cLead === sameObject)")
expect(viewConstraints.contains { $0 === cLead },
       "连着 safeArea 的约束装在公共祖先（根视图）上，不在标签自己身上：\(cLead != nil && viewConstraints.contains { $0 === cLead })")
expect(cLead?.constant == 24, "XML 里 constant=\"24\" 原样进了运行时：constant = \(cLead?.constant ?? -1)")
// 同一个 key 走两条路（属性 / KVC），拿到的是同一个对象 —— 这条是「断线为什么抛异常」的根据。
let viaKVC = fresh.value(forKey: "titleLabel") as? UILabel
expect(viaKVC === fresh.titleLabel,
       "value(forKey: \"titleLabel\") 与 .titleLabel 是同一个对象：\(viaKVC === fresh.titleLabel) —— 所以属性名写错时 UIKit 不会「静默给 nil」，它是在问一个不存在的 key")
// 名字对不上的两种下场，主线都不问（一个抛异常、一个只打 stderr，都过不了六条判定）：
//   探针 r03：outlet property="titleLabel" 而类里没这个属性 → NSUnknownKeyException，进程 abort（signal 6）
//   探针 r04：userDefinedRuntimeAttribute keyPath="caption" 而类里没这个属性 → stderr 一句
//             Failed to set (caption) user defined inspected property on ... ，程序照常跑完
// 这条硬/软的不对称是本章最有用的诊断学：**崩了通常是连线，没崩但值是默认值通常是 Inspector 里填的那一格。**
// 顺带一提：把 @IBOutlet 的类型从 UILabel! 写成 UILabel? 会怎样，是探针 r05 问的问题。

// ============================================================
// §13 第二条取对象的路：creator 闭包收到的是一台 NSCoder
// ============================================================
section(13, "creator 闭包：UIKit 把解码器交给你，但你必须拿它去 init（iOS 13 起）")
// 把 hookLog 清空，这一节要自己用它记账。
hookLog.removeAll(keepingCapacity: true)
// 看 Swift 签名就知道 UIKit 想让你干什么：闭包类型是 (NSCoder) -> UIViewController?。
// 它把「解这个场景用的那台解码器」交给你 —— 注意这不是一个「你想返回谁就返回谁」的钩子：
// 返回的对象必须是拿这台 coder 走过 super.init(coder:) 的，否则在 instantiate 那一行
// 当场抛 NSInternalInconsistencyException，原文是
//   'Custom instantiated view controller must call -[super initWithCoder:]'
// 栈顶那帧是 -[UIClassSwapper initWithCoder:]（探针 r06 抄了完整栈）。主线跑不了那一下
// （六条判定要求退出码 0），所以这里只演示合法的用法。
var coderClass = ""
var callCount = 0
let madeB = sb.instantiateInitialViewController { (coder: NSCoder) -> EntryVC? in
    callCount += 1
    coderClass = NSStringFromClass(type(of: coder))
    return EntryVC(coder: coder)
}
expect(callCount == 1, "闭包在一次取对象的过程里只被调用一次：callCount = \(callCount)")
line("     闭包收到的参数类型：\(coderClass)")
expect(coderClass == "UINibDecoder",
       "UIKit 传进来的是 UINibDecoder —— 就是解 nib 用的那台解码器，探针 r06 那条崩溃栈里反复出现的也是它：\(coderClass)")
expect(madeB != nil && NSStringFromClass(type(of: madeB!)) == "interface_builder.EntryVC",
       "交付物就是闭包返回的那个对象：\(String(describing: madeB.map { NSStringFromClass(type(of: $0)) }))")
// 和 §6 那条 instantiateInitialViewController() 的区别在这里看得最清：这个方法是泛型的，
// 闭包返回 EntryVC? 就意味着 madeB 的**静态类型**是 EntryVC? —— 下一行直接写 .titleLabel
// 就能过编译，不需要 as?。上一节 §6 抄的那句「value of type 'UIViewController' has no
// member 'titleLabel'」在这里不会出现。
expect(madeB?.titleLabel == nil,
       "静态类型对了，但连接还没发生 —— outlet 此刻仍是 nil：\(String(describing: madeB?.titleLabel))")
madeB?.loadViewIfNeeded()
expect(madeB?.titleLabel?.text == "欢迎",
       "视图加载之后故事板的一切照常生效：titleLabel.text = \(madeB?.titleLabel?.text ?? "nil")")
expect(madeB?.badge == 7, "Inspector 里那格也一样：badge = \(madeB?.badge ?? -1)")
line("     闭包取对象这一路跑过的钩子：\(hookLog)")
// 这条闭包的真实用途是「换掉故事板对象图里的某一部分」（比如把某个依赖注进控制器），
// 而不是整个绕开 nib —— 整个绕开请直接写代码，见 §25 三条路的对照。

// ============================================================
// §14 @IBInspectable 与 userDefinedRuntimeAttribute：Inspector 里那几格是什么
// ============================================================
section(14, "Inspector 里那几格：三种取值类型，和「@IBInspectable 到底管什么」")
// Main.storyboard 的 EntryVC 场景里有三格，type 各不一样：
//   type="number"  keyPath="badge"   <real key="value" value="7"/>
//   type="string"  keyPath="caption" <string key="value">故事板填进来的标题</string>
//   type="boolean" keyPath="flagged" value="YES"（这一格的取值直接写在属性上，没有子元素）
//   —— 前两种必须有 <real>/<string> 这类取值子元素；但「type 叫什么」和「子元素叫什么」
//      是两件事：探针 b05 把 number 那格的 <real> 换成 <integer>，ibtool 一句诊断都没有，
//      运行时 badge 照样是 7.0（取值子元素只是「用 XML 的类型转成对象」，转成 NSNumber 就行）。
//      真正会崩的是 type 和子元素对不上 —— 探针 b10 把 type 写成 "string" 却留着 <real>，
//      ibtoold 抛 DVTAssertion、退出码 255，连一句人话的错误消息都没有。
expect(fresh.badge == 7.0, "number 那一格进来了：badge = \(fresh.badge)")
expect(fresh.caption == "故事板填进来的标题", "string 那一格进来了：caption = \(fresh.caption)")
expect(fresh.flagged, "boolean 那一格进来了：flagged = \(fresh.flagged)")
expect(String(describing: type(of: fresh.badge)) == "Double",
       "XML 的 number 落到 Swift 侧是 Double（不是 Int、不是 CGFloat）：\(String(describing: type(of: fresh.badge)))")
// 更重要的：@IBInspectable 只决定 Xcode 的 Inspector 面板**给不给你那一格填**，
// 运行时起作用的是 KVC —— 一个没标 @IBInspectable 的普通属性照样能被填进来。
// 证据就在 TheSecond 场景里：SecondVC 一个 @IBInspectable 都没写，故事板却给它填了
// keyPath="title"，而 title 是 UIViewController 的属性，从来没人标过它。
hookLog.removeAll(keepingCapacity: true)
let secondRaw = sb.instantiateViewController(withIdentifier: "TheSecond")
expect(NSStringFromClass(type(of: secondRaw)) == "interface_builder.SecondVC",
       "取到的确实是子类（动态类型；静态类型仍然要 §6 那样自己 downcast）：\(NSStringFromClass(type(of: secondRaw)))")
let second = secondRaw as! SecondVC
// 账本里此刻已经有一条 awakeFromNib —— 把它的原文抠出来看：
expect(hookLog.first?.contains("messageLabel=nil") == true && hookLog.first?.contains("title=\"第二页的标题\"") == true,
       "instantiate 那一刻：Inspector 填的 title 已经在了，视图里的标签还没连上 → \(hookLog.first ?? "无")")
second.loadViewIfNeeded()
expect(second.title == "第二页的标题",
       "没标 @IBInspectable 的 title 也被填进来了：title = \(second.title ?? "nil")")
expect(second.messageLabel?.text == "第二页",
       "顺带确认这个场景的 outlet 也连上了：messageLabel.text = \(second.messageLabel?.text ?? "nil")")
expect(hookLog.count == 2 && hookLog.last?.contains("messageLabel=第二页") == true,
       "loadView 之后两条钩子都在账本里，值的变化就是那两条 nib 的分界：\(hookLog)")
// 反过来：这一格填错 keyPath 时不会抛异常，只在 stderr 留一行日志 —— §12 那条硬/软不对称。
// 填进来的时机也比想象早：§11 的第一个钩子里 badge 就已经是 7 了。

// ============================================================
// §15 @IBAction：拖的那条线在运行时是 UIControl 的一张表
// ============================================================
section(15, "@IBAction：那条「线」在运行时是控件表里的一个字符串选择器")
// 书 4.2 的操作是「ctrl 按住从按钮拖到代码里，起个名字」。XML 里落地成：
//   <action selector="didTap:" destination="ENT-01-001" eventType="touchUpInside" id="actTap"/>
// 三段分别是选择器名、目标、事件掩码。这张表在运行时是可以读出来的 —— 这是本章最直接的
// 「拖线到底拖出了什么」。
// 一个小坑先记下来：allTargets 的元素在 Swift 侧被 AnyHashable 包了一层，直接打印
// 类名会看到 "Swift.AnyHashable"，要取 .base 才是真正那个对象。
expect(fresh.tapLog.isEmpty, "没点之前 tapLog 是空的：\(fresh.tapLog)")
let tapTargets = Array(fresh.tapButton.allTargets)
expect(targetNames(fresh.tapButton) == ["interface_builder.EntryVC"],
       "btnTap 的 target 只有一个，就是场景里的控制器：\(targetNames(fresh.tapButton))")
expect((tapTargets.first as? EntryVC) === fresh,
       "而且是**同一个对象**，不是拷贝 —— XML 里 destination=\"ENT-01-001\" 指的正是它：\(String(describing: (tapTargets.first as? EntryVC) === fresh))")
let tapSelectors = fresh.tapButton.actions(forTarget: tapTargets.first, forControlEvent: .touchUpInside)
expect(tapSelectors == ["didTap:"],
       "表里的动作是一个 Objective-C 选择器字符串：\(tapSelectors ?? []) —— 那个冒号是名字的一部分，代表「带一个参数」")
// 目标这一侧也要真的实现了这个选择器，三样齐了这条线才算通：
expect(fresh.responds(to: NSSelectorFromString("didTap:")),
       "控制器确实实现了 didTap:（responds(to:) 为真）—— 这就是「方法名改了一个字就断线」的那个检查点")
expect(!fresh.responds(to: NSSelectorFromString("didTap")),
       "少写那个冒号就是另一个选择器，运行时查不到：\(fresh.responds(to: NSSelectorFromString("didTap")))")

// ============================================================
// §16 派发这一环在 headless 里是断的：UIApplication.shared == nil
// ============================================================
section(16, "sendActions(for:) 为什么在本章什么都不做：没有 UIApplication 就没有派发")
// §15 读出来的那张表是完整的，可「照着表把事件打一遍」这一步在裸可执行文件里永远静默 ——
// UIControl 的派发是走共享应用对象的，而它在这里根本不存在。
let app: UIApplication? = UIApplication.shared
expect(app == nil, "UIApplication.shared 在命令行可执行文件里就是 nil：\(String(describing: app))")
// 于是两种「连上去的线」都不动：故事板拖的那条不动，代码里 addTarget 加的那条**同样**不动。
// 后者是这条判定的关键对照 —— 它证明静默来自「没有派发者」，不是来自 Interface Builder。
let probeButton = UIButton(type: .system)
fresh.view.addSubview(probeButton)
probeButton.addTarget(fresh, action: NSSelectorFromString("didTap:"), for: .touchUpInside)
fresh.tapLog.removeAll(keepingCapacity: true)
fresh.tapButton.sendActions(for: .touchUpInside)
probeButton.sendActions(for: .touchUpInside)
expect(fresh.tapLog.isEmpty,
       "两条线都在这里，但 sendActions(for:) 一个都不派发：\(fresh.tapLog) —— 故事板与代码在这一条上没有区别")
// 表和选择器都没问题，缺的只是派发者 —— 手工把 (target, selector, sender) 走一遍就能证明：
_ = fresh.perform(NSSelectorFromString("didTap:"), with: fresh.tapButton)
expect(fresh.tapLog.count == 1,
       "手工派发就调用到了，说明前面那条静默不是断线：\(fresh.tapLog)")
expect(fresh.tapLog.first?.contains("sender就是那颗按钮=true") == true,
       "而且方法收到的 sender 就是那颗按钮本身，所以能当场问出它的标题：\(fresh.tapLog.first ?? "无")")
fresh.tapLog.removeAll(keepingCapacity: true)
probeButton.sendActions(for: .touchDown)
expect(fresh.tapLog.isEmpty,
       "事件掩码不匹配同样是零次调用（这一条在有派发者时才区分得开）：\(fresh.tapLog)")
// 这条边界决定了本章后面所有「触发」类断言的写法：能读表、能手递，就是不能靠手指。
// 选择器名字写错（didTapp:）时 ibtool 不拦（探针 b09），运行时在有派发者的场合是
// unrecognized selector —— 那句原文与栈在探针 r07。

// ============================================================
// §17 按钮直连 segue：同一张表，另一个 target
// ============================================================
section(17, "按钮直连 segue：还是 target-action，但 target 是那条 segue 模板")
// Main.storyboard 里第二颗按钮 btnSegue 的 <connections> 只有一条 segue，没有任何 <action>：
//   <segue destination="SEC-02-002" kind="show" identifier="byeButton" animates="NO" id="sgBtn"/>
// 它在 Xcode 里同样是「从按钮拖一条线出去」，看上去和 §15 一模一样。表读出来才知道差别：
let segueTargets = Array(fresh.segueButton.allTargets)
line("     btnSegue 的 target 列表：\(targetNames(fresh.segueButton))")
for t in segueTargets {
    line("     → 这个 target 在 touchUpInside 上的动作：\(fresh.segueButton.actions(forTarget: t, forControlEvent: .touchUpInside) ?? [])")
}
expect(targetNames(fresh.segueButton) == ["UIStoryboardShowSegueTemplate"],
       "target 不是控制器，而是那条 segue 自己：\(targetNames(fresh.segueButton)) —— XML 里 kind=\"show\" 直接写进了这个类名")
expect((segueTargets.first as? EntryVC) == nil,
       "对照 §15：那颗按钮的 target 是控制器本身，这颗的不是（as? EntryVC = \(String(describing: segueTargets.first as? EntryVC))）")
expect(fresh.segueButton.actions(forTarget: segueTargets.first, forControlEvent: .touchUpInside) == ["perform:"],
       "选择器是 perform:，不是你写的某个方法：\(fresh.segueButton.actions(forTarget: segueTargets.first, forControlEvent: .touchUpInside) ?? [])")
// 「模板」这个词是字面意思：它不是UIStoryboardSegue 对象，而是「造 segue 的配方」。
// 上一层类名可以问运行时：
if let tmpl = segueTargets.first.map({ ($0 as AnyHashable).base }) {
    let chain = superclassChain(of: tmpl)
    line("     它的继承链：\(chain)")
    expect(chain.count > 1 && chain[1] == "UIStoryboardSegueTemplate",
           "第 2 层就是 UIStoryboardSegueTemplate：\(chain) —— 换 kind 只换最下面那一层类名")
    expect(!chain.contains("UIStoryboardSegue"),
           "注意链上并没有 UIStoryboardSegue：模板不是 segue 对象本身（segue 对象 §19 才出现）")
}
// 所以「点这颗按钮」在运行时是一条完整的 target-action：派发 perform: 给模板 →
// 模板造出 segue → 实例化目的地 → 回调 prepare(for:sender:) → segue.perform()。
// 前半截在没有派发者时不会动（§16），后半截在没有容器时的下场见探针 r08，
// 在有容器的 Nav 场景里能量到完整时序 —— §18。

// ============================================================
// §18 有容器时的完整时序：perform → prepare → 目的地 viewDidLoad → segue.perform
// ============================================================
section(18, "performSegue(withIdentifier:sender:) 的完整时序（Nav 场景，有容器）")
hookLog.removeAll(keepingCapacity: true)
let nav = navSB.instantiateInitialViewController() as! UINavigationController
let alpha = nav.viewControllers[0] as! AlphaVC
line("     取整条导航栈时跑的钩子：\(hookLog)")
expect(hookLog.filter { $0.hasPrefix("Alpha.awakeFromNib") }.count == 1,
       "Alpha 是被导航控制器那条 nib 一起解出来的，它的 awakeFromNib 照样跑了一次：\(hookLog)")
expect(hookLog.first?.contains("navItem.title=\"第一层\"") == true,
       "而且连在 <navigationItem> 上的 outlet 这一刻已经有值了：\(hookLog.first ?? "无") —— 对比 §11 的 titleLabel，那一个住在视图 nib 里")
hookLog.removeAll(keepingCapacity: true)
alpha.loadViewIfNeeded()
expect(hookLog.count == 1 && hookLog.first?.hasPrefix("Alpha.viewDidLoad") == true,
       "视图加载只多出 viewDidLoad 这一条：\(hookLog)")
// 跳转：书 4.2 的做法是在代码里调 performSegue，sender 是想带过去的任何东西。
hookLog.removeAll(keepingCapacity: true)
alpha.performSegue(withIdentifier: "showB", sender: "手工给的 sender")
line("     perform 之后的完整账本：\(hookLog)")
expect(hookLog.first?.hasPrefix("Alpha.prepare(showB)") == true,
       "第一步是源控制器的 prepare(for:sender:)：\(hookLog.first ?? "无")")
expect(hookLog.first?.contains("目的地视图已加载=false") == true,
       "进 prepare 时目的地的视图还没加载 —— 所以这一格里赋值才是安全的：\(hookLog.first ?? "无")")
expect(hookLog.first?.contains("sender=手工给的 sender") == true,
       "performSegue 给什么 sender，prepare 就收到什么（走按钮时是那颗按钮，§17）：\(hookLog.first ?? "无")")
let beta = nav.topViewController as! BetaVC
expect(!hookLog.contains { $0.hasPrefix("Beta.viewDidLoad") },
       "整条链跑完，目的地的 viewDidLoad 一次都没跑：\(hookLog) —— 入栈只是改栈；视图要等导航控制器的视图进了窗口、转场真跑起来才加载")
expect(!beta.isViewLoaded && beta.markLabel == nil,
       "所以此刻 beta.isViewLoaded = \(beta.isViewLoaded)，它的 outlet 也还是 nil：\(String(describing: beta.markLabel))")
expect(nav.viewControllers.count == 2, "perform 结束时已经真的入栈了：栈深 \(nav.viewControllers.count)")
expect(nav.topViewController is BetaVC,
       "栈顶换人了：\(String(describing: nav.topViewController.map { String(reflecting: type(of: $0)) }))")
expect(beta.navigationItem.title == "第二层",
       "XML 里 <navigationItem title=\"第二层\"> 落在 navigationItem 上：\(beta.navigationItem.title ?? "nil")")
expect(beta.title == nil,
       "而 vc.title 是 nil：\(String(describing: beta.title)) —— 场景顶上那个「Title」格（XML 里的 <title>场景上的名字</title>）既没进 vc.title 也没进 navigationItem")
// 这两者的耦合是单向的，代码里能验：给 title 赋值会带着 navigationItem.title 一起变。
beta.title = "代码里改的"
expect(beta.navigationItem.title == "代码里改的",
       "vc.title → navigationItem.title 是通的：\(beta.navigationItem.title ?? "nil")")
beta.navigationItem.title = "第二层"
expect(beta.title == "代码里改的",
       "反过来不通（只改了 navigationItem，vc.title 没跟着变）：\(beta.title ?? "nil") —— 这就是「改了导航条标题却还在显示旧标题」那个 bug 的形状")

// ============================================================
// §19 UIStoryboardSegue 对象：三样读得出的东西，和那个可以自己写的 perform()
// ============================================================
section(19, "UIStoryboardSegue 对象：identifier / source / destination 与 perform()")
let theSegue = alpha.lastSegue
let segClass = theSegue.map { String(reflecting: type(of: $0)) } ?? "无"
let segSource = theSegue.map { String(reflecting: type(of: $0.source)) } ?? "无"
let segDest = theSegue.map { String(reflecting: type(of: $0.destination)) } ?? "无"
expect(theSegue != nil, "prepare 收到的那个 segue 对象可以留到事后问：\(segClass)")
expect(theSegue?.identifier == "showB",
       "identifier 就是 XML 里那个属性：\(theSegue?.identifier ?? "nil")")
expect(theSegue?.source === alpha,
       "source 是发起者的那个对象本身：\(segSource)")
expect(theSegue?.destination === nav.topViewController,
       "destination 就是被推进栈的那个对象（同一个，不是第二份）：\(segDest)")
if let s = theSegue {
    let chain = superclassChain(of: s)
    line("     这个 segue 实例的继承链：\(chain)")
    expect(chain == ["UIStoryboardSegue", "NSObject"],
           "kind=\"show\" 造出来的 segue 对象本身就是 plain UIStoryboardSegue：\(chain) —— kind 只写进 §17 那个**模板**的类名，转场行为是模板配好的，不是 segue 子类的 perform()")
}
// kind="custom" 的那条：segue 的类由 XML 里的 customClass 指定，perform() 完全由你写。
hookLog.removeAll(keepingCapacity: true)
alpha.performSegue(withIdentifier: "customFade", sender: nil)
expect(hookLog.contains { $0.hasPrefix("Alpha.prepare(customFade)") },
       "自定义的这条路同样先走 prepare：\(hookLog.first ?? "无")")
expect(hookLog.contains { $0.hasPrefix("FadeSegue.perform") },
       "perform() 里就是我们自己的代码：\(hookLog.last ?? "无")")
expect(alpha.lastSegue.map { String(reflecting: type(of: $0)) } == "interface_builder.FadeSegue",
       "这一次 segue 对象的类就是 XML 里 customClass 写的那个：\(String(describing: alpha.lastSegue.map { String(reflecting: type(of: $0)) }))")
expect(nav.viewControllers.count == 2,
       "我们的 perform() 只记了一行账、没搬视图，所以栈深一点没变：\(nav.viewControllers.count)")
// 这三行合起来就是「自定义转场」的全部接口面：UIKit 只负责造对象和调 perform()，
// 剩下的都是你的 —— 而故事板里那条 kind="custom" 只是把一个类名写进了 XML。

// ============================================================
// §20 unwind segue：destination 是 XML 里那个 exit 对象
// ============================================================
section(20, "unwind segue：往回跳的线连在控件上，destination 是一个 exit 占位对象")
// Nav.storyboard 的 Beta 场景里，那颗「回到 Alpha」按钮的 <connections> 只有一条 segue：
//   <segue destination="EXIT-13-013" kind="unwind" identifier="backToAlpha" unwindAction="unwindToAlpha:"/>
// 同场景的 <objects> 里除了 Beta 还多一个 <exit id="EXIT-13-013" sceneMemberID="exit"/> —— 它就是
// Xcode 画布上那个「Exit」圆形图标。往回跳的线连的是它，动作名写在 unwindAction 属性上。
beta.loadViewIfNeeded()
let unwindTargets = Array(beta.unwindButton.allTargets)
line("     btnBack 的 target 列表：\(targetNames(beta.unwindButton))")
for t in unwindTargets {
    line("     → 它在 touchUpInside 上的动作：\(beta.unwindButton.actions(forTarget: t, forControlEvent: .touchUpInside) ?? [])")
}
expect(targetNames(beta.unwindButton) == ["UIStoryboardUnwindSegueTemplate"],
       "§17 那张表的第三兄弟：kind=\"unwind\" 把 target 换成 UIStoryboardUnwindSegueTemplate：\(targetNames(beta.unwindButton))")
expect(beta.unwindButton.actions(forTarget: unwindTargets.first, forControlEvent: .touchUpInside) == ["perform:"],
       "选择器仍是 perform:，和直连 show 的那颗一模一样：\(beta.unwindButton.actions(forTarget: unwindTargets.first, forControlEvent: .touchUpInside) ?? [])")
if let tmpl = unwindTargets.first.map({ ($0 as AnyHashable).base }) {
    let chain = superclassChain(of: tmpl)
    line("     它的继承链：\(chain)")
    expect(chain.count > 1 && chain[1] == "UIStoryboardSegueTemplate",
           "它和 §17 那个模板同住一个父类，kind 换掉的只有最下面一层类名：\(chain)")
    let names = methodNames(of: tmpl)
    line("     这个类自己声明的方法：\(names)")
    expect(names.contains("action") && names.contains("setAction:"),
           "unwindAction=\"unwindToAlpha:\" 那格存进了模板自己的 action 属性（这一对 action / setAction: 就是它的存取器）：\(names) —— 上层控制器身上没有留下任何「我是 unwind 目的地」的标记")
    expect(names.contains("instantiateOrFindDestinationViewControllerWithSender:"),
           "而这个类自己声明的这个方法名，正是普通 segue 与 unwind 的分岔口：\(names.filter { $0.hasPrefix("instantiate") }) —— 前半截是「造一个目的地」，unwind 走的是后半截「找到那个已经在栈里的」")
}
// 把「分岔口」这句落实成对照：同一条 perform:，§17 那个 show 模板的清单里没有 unwind 那几个方法。
if let showTmpl = segueTargets.first.map({ ($0 as AnyHashable).base }),
   let unwindTmpl = unwindTargets.first.map({ ($0 as AnyHashable).base }) {
    let showNames = methodNames(of: showTmpl)
    line("     §17 那个 show 模板自己声明的方法：\(showNames)")
    let onlyInUnwind = methodNames(of: unwindTmpl).filter { !showNames.contains($0) }
    line("     只在 unwind 模板上出现的方法：\(onlyInUnwind)")
    expect(onlyInUnwind.contains("instantiateOrFindDestinationViewControllerWithSender:"),
           "unwind 独有的就是这一串：\(onlyInUnwind) —— destination 那个 <exit> 在编译期就不需要是一个控制器")
}
// 动作名指向谁：只有上层那个 @IBAction。找不到实现就顺着响应链继续往上找。
let unwindSel = NSSelectorFromString("unwindToAlpha:")
expect(alpha.responds(to: unwindSel),
       "上层这个 @IBAction 是 unwind 的全部落点：responds(to:) = \(alpha.responds(to: unwindSel))")
expect(!beta.responds(to: unwindSel),
       "发起方自己没有这个方法：responds(to:) = \(beta.responds(to: unwindSel)) —— 「unwind 到某个控制器」在 XML 里其实只写成「某个方法名」")
// 触发路径一：控制器上那句最直觉的 performSegue(withIdentifier:)。本章前一版的正文在这里写的是
// 「这条线连在控件上、不在控制器的 segue 表里，所以 performSegue 查不到它」—— 那句是错的，
// 错因见本节末尾；先把实测摆出来。
hookLog.removeAll(keepingCapacity: true)
beta.performSegue(withIdentifier: "backToAlpha", sender: beta.unwindButton)
line("     performSegue(\"backToAlpha\") 之后的完整账本：\(hookLog)")
expect(hookLog.contains { $0.hasPrefix("Beta.prepare") },
       "先经过的是**发起方**的 prepare：\(hookLog.first(where: { $0.hasPrefix("Beta.prepare") }) ?? "无") —— §18 那条流水线的顺序在 unwind 上一模一样")
expect(hookLog.contains { $0.hasPrefix("unwindToAlpha") },
       "控制器的表里查得到这条 unwind 线，方法当场被调：\(hookLog.first(where: { $0.hasPrefix("unwindToAlpha") }) ?? "无")")
expect(hookLog.count == 2,
       "整条路只有这两步（prepare 在发起方、动作在上层）：\(hookLog.count) 条 —— 中间没有「实例化目的地」那一步，destination 就是栈里那个 AlphaVC 本身")
// 把这一份账本留个底，本节末尾拿它和「绕过控制器、直接派发表里那句 perform:」的账本对一遍。
let ledgerViaController = hookLog
expect(nav.viewControllers.count == 2 && nav.topViewController === beta,
       "可栈还是没动：\(nav.viewControllers.count) 个，栈顶还是 \(String(reflecting: type(of: nav.topViewController!))) —— 「顺着栈找到目的地 + 调它的方法」是模板做的，「弹」是转场做的，后一半撞在 §16 那条边界上")
// 触发路径二：绕过控制器，直接派发 §15/§17 读出来的那张表。它证明那条线确实挂在**按钮**上。
// 先按书里的操作试 UIControl 那句：
hookLog.removeAll(keepingCapacity: true)
beta.unwindButton.sendActions(for: .touchUpInside)
expect(hookLog.isEmpty,
       "先按 §16 的老路试一次：sendActions(for:) 对这条线同样一声不响：\(hookLog)")
for t in unwindTargets {
    _ = ((t as AnyHashable).base as AnyObject).perform(NSSelectorFromString("perform:"), with: beta.unwindButton)
}
line("     手工派发 perform: 之后的完整账本：\(hookLog)")
expect(hookLog.contains { $0.hasPrefix("unwindToAlpha") },
       "Alpha 的 unwindToAlpha(_:) 被调到了：\(hookLog.first(where: { $0.hasPrefix("unwindToAlpha") }) ?? "无")")
expect(hookLog.contains { $0.contains("sender.source=interface_builder.BetaVC") },
       "这条 segue 对象里 source 是发起方（下层）：\(hookLog.first(where: { $0.hasPrefix("unwindToAlpha") }) ?? "无")")
expect(hookLog.contains { $0.contains("sender.destination=interface_builder.AlphaVC") },
       "destination 是模板顺着栈**找到**的那个上层控制器，不是 XML 里的 exit：\(hookLog.first(where: { $0.hasPrefix("unwindToAlpha") }) ?? "无") —— 「往回跳」在运行时仍然是 source→destination 这条方向")
// 「找到控制器 + 调它的方法」这一半已经量完了，剩下的一半天然是「栈怎么变」。
line("     派发之后：nav.isViewLoaded=\(nav.isViewLoaded) beta.isViewLoaded=\(beta.isViewLoaded) beta.view.superview=\(String(describing: beta.view.superview.map { String(reflecting: type(of: $0)) })) 栈深=\(nav.viewControllers.count)")
expect(nav.viewControllers.count == 2 && nav.topViewController === beta,
       "方法调到了，栈却没动：现在 \(nav.viewControllers.count) 个，栈顶还是 \(String(reflecting: type(of: nav.topViewController!)))")
expect(beta.view.superview == nil,
       "这一格里有原因：Beta 的视图从没进过 nav 的视图层级（superview = \(String(describing: beta.view.superview))），可它的控制器在栈里、视图也已经加载完 —— 「在栈里」和「在屏幕上」是两件事，而弹栈是转场那一步的事")
// 那给它挂一个 UIWindow 呢？量一下这条思路的下场。
let win = UIWindow(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
win.rootViewController = nav
line("     挂上窗口之后：nav.view.window 非空=\(nav.view.window != nil) win.subviews.count=\(win.subviews.count) beta.view.superview=\(String(describing: beta.view.superview))")
expect(nav.view.window == nil && win.subviews.isEmpty,
       "挂不上：nav.view.window = \(String(describing: nav.view.window))，win.subviews.count = \(win.subviews.count) —— 没有 UIApplicationMain 的运行循环，UIWindow 就只是一个普通 UIView，§11 那句「没有 window 就没有 Appearance 回调」、§16 那句「没有派发者」和这里是同一个根")
hookLog.removeAll(keepingCapacity: true)
for t in unwindTargets {
    _ = ((t as AnyHashable).base as AnyObject).perform(NSSelectorFromString("perform:"), with: beta.unwindButton)
}
line("     第二次派发之后的完整账本：\(hookLog)")
expect(hookLog.count == 2 && hookLog.first?.hasPrefix("Beta.prepare") == true
       && hookLog.last?.hasPrefix("unwindToAlpha") == true,
       "绕过控制器的派发走出的是同一条流水线（prepare 在先、动作在后）：\(hookLog)")
expect(hookLog == ledgerViaController,
       "而且和上面那句 performSegue 的账本逐字相同：\(hookLog == ledgerViaController) —— 公开写法（控制器的 performSegue）与手工派发（模板那句 perform:）做的是同一件事，一条都没多、一条都没少")
expect(nav.viewControllers.count == 2,
       "「弹」这一步在 headless 里就是拿不到：现在 \(nav.viewControllers.count) 个，栈顶 = \(String(reflecting: type(of: nav.topViewController!)))")
// 那「弹」本身能不能量到？能 —— 它就是 UINavigationController 的一句公开 API，而真实 app 里
// 那条默认 unwind 替你做正是这件事（书 4.4「返回到某个视图控制器」）。
nav.popToViewController(alpha, animated: false)
expect(nav.viewControllers.count == 1 && nav.topViewController === alpha,
       "nav.popToViewController(_:animated:) 一写就生效：现在 \(nav.viewControllers.count) 个，栈顶 = \(String(reflecting: type(of: nav.topViewController!)))")
expect(beta.navigationController == nil,
       "被弹掉的 Beta 已经脱离了容器：navigationController = \(String(describing: beta.navigationController))")
// 收尾说一句「上面那条 performSegue 为什么第一次差点没写进来」：本章前一版在这里写的是
// 「这条线连在控件上，不在控制器的 segue 表里，所以控制器的 performSegue(withIdentifier:) 查不到它，
// UIKit 会抛 NSInvalidArgumentException: Receiver (<…BetaVC: 0x…>) has no segue with identifier
// 'backToAlpha'」。那句异常消息是真的，原因却找错了：抛它的那份故事板把 <exit> 元素错放在了
// </objects> 外面（还在 <scene> 里，XML 完全合法），ibtool 一句诊断都没有（退出码 0、输出为空），
// 而后果是**整条 unwind 连接根本没编出来** —— 探针 b11 就是那份坏 XML，它读出来的按钮
// target 列表是空数组 []。把同一个 <exit> 挪进 <objects>（Nav.storyboard 的写法），表里就是
// UIStoryboardUnwindSegueTemplate + perform:，performSegue 也照上面那样查得到。
// 一句话：「has no segue with identifier」说的是「这个控制器名下没有这条 identifier 的模板」，
// 至于模板本来该挂在控件上还是控制器上，它不区分 —— 拿它当「unwind 天生不能用 performSegue」的证据是错的。

// ============================================================
// §21 XIB：一份文件一个 .nib，取它要交一个 owner 进去
// ============================================================
section(21, "XIB：Card.xib 编成 Card.nib，instantiate(withOwner:options:) 交回来的是「顶层对象」数组")
// Card.xib 的 <objects> 里只有三样东西：
//   <placeholder placeholderIdentifier="IBFilesOwner" id="-1" customClass="CardOwner"
//                customModule="interface_builder">
//       ← File's Owner。它是 placeholder、不是对象：文件里只留下「外面要交进来一个 CardOwner」
//         这句话，加上两条连在它身上的 outlet（rootView → xRoot、titleLabel → xTitle）。
//   <placeholder placeholderIdentifier="IBFirstResponder" id="-2"/>   ← 响应链的头
//   <view id="xRoot">…两个 label…</view>                            ← 唯一真正的顶层对象
// run-all.sh 用 ibtool 把它编成 build/31_interface_builder/Card.nib —— 一个文件，
// 不是 §2 那种 .storyboardc 包，也没有查找表：一个 XIB 就一个名字。
line("     §1 里那句 url(forResource:withExtension:) 取到的就是它：\(cardNib?.path ?? "取不到")")
expect(cardNib != nil, "而且它是 bundle 根目录下的一个文件，不是包：\(cardNib?.lastPathComponent ?? "nil") 的父目录 = \(cardNib?.deletingLastPathComponent().lastPathComponent ?? "nil")")
let cardUINib = UINib(nibName: "Card", bundle: nil)
expect(String(reflecting: type(of: cardUINib)) == "UINib",
       "故事板那边是 UIStoryboard(name:bundle:)（§4），XIB 这边是 UINib(nibName:bundle:)：\(String(reflecting: type(of: cardUINib))) —— bundle: nil 同样是 Bundle.main，名字既不带 .xib 也不带 .nib")
hookLog.removeAll(keepingCapacity: true)
let owner = CardOwner()
let topLevel = cardUINib.instantiate(withOwner: owner, options: nil)
line("     交回来的数组：\(topLevel.map { String(reflecting: type(of: $0)) })")
expect(topLevel.count == 1,
       "XIB 里只有 1 个顶层对象（那个 <view>），数组就 1 项：\(topLevel.count) 项 —— 故事板一次能交一整栈（§10），XIB 一次只交它自己的顶层对象")
expect(!(topLevel.contains { ($0 as AnyObject) === owner }),
       "数组里没有 owner 自己：File's Owner 不是被解出来的对象，是你交进去的那个 \(String(reflecting: type(of: owner)))")
let cardView = topLevel[0] as! UIView
expect(cardView.subviews.count == 2,
       "两个 <label> 都在它的 subviews 里：\(cardView.subviews.map { String(reflecting: type(of: $0)) })")
line("     两个子视图的 frame：\(cardView.subviews.map { "\($0.frame)" })（XML 里那两格是 16,16,248,28 和 16,52,248,20）")
line("     顶层视图的 frame = \(cardView.frame)，translatesAutoresizingMaskIntoConstraints = \(cardView.translatesAutoresizingMaskIntoConstraints)，它自己身上的约束数 = \(cardView.constraints.count)（XML 那格写的是 0,0,280,120）")
expect(cardView.subviews.map { $0.frame } == [CGRect(x: 16, y: 16, width: 248, height: 28),
                                              CGRect(x: 16, y: 52, width: 248, height: 20)],
       "子视图的 frame 逐格等于 XML 里那两格 <rect>：\(cardView.subviews.map { "\($0.frame)" })")
expect(cardView.frame != CGRect(x: 0, y: 0, width: 280, height: 120),
       "可顶层这一个不是：设计稿上的 280×120 没跟着出来，交回来的是 \(cardView.frame) —— 「按 XIB 设计的尺寸把卡片摆出来」这件事在 iOS 上从来不是自动的（§23 清点这一格）")
expect(owner.rootView === cardView,
       "File's Owner 那两条 outlet 连的就是刚交出来的这个对象本身（§12 的「对象身份」在这儿同样成立）：=== 成立 = \(owner.rootView === cardView)")
expect(owner.titleLabel?.text == "卡片标题",
       "第二个 outlet 连的是里面的标签：\(owner.titleLabel?.text ?? "nil")")
expect(owner.titleLabel is CardLabel,
       "而那个标签的类就是 XIB 里 customClass 写的那个：\(String(reflecting: type(of: owner.titleLabel!))) —— §7 那三段字符串在 XIB 里同样要对齐")
line("     这一次 instantiate 跑过的钩子：\(hookLog)，owner.awakeRan = \(owner.awakeRan)")
expect(hookLog.count == 1 && hookLog.first?.hasPrefix("CardLabel.awakeFromNib") == true,
       "被解出来的标签收到了 awakeFromNib：\(hookLog)")
expect(!owner.awakeRan,
       "可 File's Owner 的一次都没跑：awakeRan = \(owner.awakeRan)，账本里也没有 CardOwner 那一条（\(hookLog)）—— UIKit 只把这条通知发给「从 nib 里解出来的对象」，owner 是外面交进来的，不在那个名单里。「在 File's Owner 的 awakeFromNib 里做初始化」是 AppKit 的习惯，搬到 iOS 就是静默失效")

// ============================================================
// §22 同一个 XIB 生产两次，和 owner 交错的下场
// ============================================================
section(22, "XIB 是配方不是单例；owner 交错不是静默，是 §12 那句 KVC 异常")
// XIB 不是单例：每 instantiate 一次就重新解一遍 nib、重新造一套对象、也重新做一遍连接。
let owner2 = CardOwner()
hookLog.removeAll(keepingCapacity: true)
let secondTop = cardUINib.instantiate(withOwner: owner2, options: nil)
let card2 = secondTop[0] as! UIView
expect(card2 !== cardView,
       "第二次 instantiate 交回来的是另一个 UIView：!== 成立 = \(card2 !== cardView) —— 界面文件是配方，instantiate 才是生产")
expect(owner2.rootView === card2,
       "这一趟的连接落在这一趟的 owner 上：owner2.rootView === 刚交出来的视图 = \(owner2.rootView === card2)")
expect(owner.rootView === cardView,
       "§21 那一套也还原封不动在第一趟的 owner 手里：\(owner.rootView === cardView) —— 「当前 Card」这种全局状态并不存在，连接是每次各做一遍（§12）")
expect(hookLog.count == 1 && hookLog.first?.hasPrefix("CardLabel.awakeFromNib") == true && !owner2.awakeRan,
       "第二趟整批重做：标签的 awakeFromNib 又跑了一次（\(hookLog)），owner2 的照旧不跑（awakeRan = \(owner2.awakeRan)）—— 解 nib 不是「共享一份对象」，是每次从头解一遍")
// 书里 XIB 一章用的是 Bundle 上那句 shorthand：名字从「已经建好的 UINib」退回一个字符串，
// 返回值从数组变成可选数组。走的是同一条路，只是少写一行。
let owner3 = CardOwner()
hookLog.removeAll(keepingCapacity: true)
let viaBundle = Bundle.main.loadNibNamed("Card", owner: owner3, options: nil)
expect(viaBundle?.count == 1,
       "Bundle.main.loadNibNamed(_:owner:options:) 交回来的形状一样（可选数组，1 项）：\(viaBundle?.count ?? -1)")
let card3 = viaBundle?[0] as! UIView
expect(owner3.rootView === card3 && card3 !== cardView && card3 !== card2,
       "第三个 owner 拿到第三个对象：三套彼此独立 = \(owner3.rootView === card3)/\(card3 !== cardView)/\(card3 !== card2)")
expect(owner3.titleLabel?.text == "卡片标题",
       "两条 outlet 同样是这一趟现做的：titleLabel.text = \(owner3.titleLabel?.text ?? "nil")")
expect(hookLog.count == 1 && hookLog.first?.hasPrefix("CardLabel.awakeFromNib") == true,
       "shorthand 也是整批重解：这一趟的钩子账本 \(hookLog)")
// options 那一格传空字典与传 nil 在这一份 XIB 里等价（它是留给外部对象与本地化的）。
let owner4 = CardOwner()
expect(cardUINib.instantiate(withOwner: owner4, options: [:]).count == 1,
       "options: [:] 与 options: nil 一样出 1 个顶层对象：\(cardUINib.instantiate(withOwner: owner4, options: [:]).count)")
// 那么 owner 传 nil 呢？「连接静默落空」是常见的猜想，实测正相反：UIKit 会拿一个 plain NSObject
// 顶替 File's Owner，然后照 §12 那条 KVC 去 setValue:forKey:"rootView"，当场抛
// NSUnknownKeyException —— 崩溃原文是
//   '[<NSObject 0x…> setValue:forUndefinedKey:]: this class is not key value coding-compliant
//    for the key rootView.'
// 栈里 -[UIRuntimeOutletConnection connect] 那一帧就在 -[UINib instantiateWithOwner:options:] 上面。
// 交一个「类型对不上」的对象（比如 NSObject()）是同一句话，因为连接问的是 key、不是类型声明。
// 两句原文与退出码在探针 r11、r12；主线里不重演 —— 一次未捕获异常会把 §23 之后的输出全部带走
// （本章最初就是这么死的：rc=134、stderr 1266 字节，判定 2、3 同时红）。


// ============================================================
// §23 设计值那一格 <rect>：它在运行时到底值多少
// ============================================================
section(23, "设计值 <rect key=\"frame\"> 与运行时 frame：界面文件里那些尺寸有几格真生效")
// §21 里已经撞见过一次：XIB 顶层视图那格写的是 280×120，交回来却是 600×600。
// 那 600×600 的来历在探针 r13/r14：同一份 XIB 只差 `<device id="retina6_1" …/>` 那一行，
// 有它顶层视图交回来是 414×896（那台设备的高），没有它是 600×600 —— Card.xib 正是没有那一行，
// 所以 XML 里 280×120 那格根本没被读过，ibtool 直接按「没有目标设备」的默认画布盖章。
// 这一节把「设计值到底生不生效」分成三种情形量干净。
let screenBounds = UIScreen.main.bounds
line("     UIScreen.main.bounds = \(screenBounds)，scale = \(UIScreen.main.scale)")
// —— 情形一：控制器的根视图。Main.storyboard 那格是 0,0,414,896（设计画布）。
expect(fresh.view.frame == screenBounds,
       "运行时它等于屏幕，不是设计画布：frame = \(fresh.view.frame)，XML 那格是 414×896 —— 加载视图控制器时 UIKit 按屏幕把它重摆了一次")
expect(fresh.view.autoresizingMask == [.flexibleWidth, .flexibleHeight],
       "可 XML 那行 <autoresizingMask widthSizable=\"YES\" heightSizable=\"YES\"> 原样进了运行时：\(fresh.view.autoresizingMask)（rawValue = \(fresh.view.autoresizingMask.rawValue)，也就是 2|16）")
// —— 情形二：XIB 里的子视图。它们那两格是 16,16,248,28 和 16,52,248,20。
let labelFrames = cardView.subviews.map { $0.frame }
expect(labelFrames == [CGRect(x: 16, y: 16, width: 248, height: 28), CGRect(x: 16, y: 52, width: 248, height: 20)],
       "逐格照搬：\(labelFrames) —— 顶层那一个被换成 600×600，子视图这一格却完完整整跟着对象出来")
expect(cardView.subviews.allSatisfy { $0.autoresizingMask == [.flexibleRightMargin, .flexibleBottomMargin] },
       "两个标签的 <autoresizingMask flexibleMaxX=\"YES\" flexibleMaxY=\"YES\"> 也在：\(cardView.subviews.map { $0.autoresizingMask.rawValue })（4|32 = 36：右边距与下边距可伸缩，位置与尺寸固定）")
expect(cardView.frame.size.width == 600 && cardView.subviews.map { $0.frame.width } == [248.0, 248.0],
       "父视图从 320 加宽到 600、再布局一遍，标签一点没动：卡片宽 = \(cardView.frame.size.width)，标签宽还是 \(cardView.subviews.map { $0.frame.width }) —— 多出来的宽度全落进它们右边那条可伸缩边距里，这就是书里那几张 Struts 图在运行时的样子")
expect(cardView.constraints.isEmpty && cardView.translatesAutoresizingMaskIntoConstraints,
       "而卡片自己一条约束都没有（\(cardView.constraints.count) 条），TAMIC 还是 \(cardView.translatesAutoresizingMaskIntoConstraints) —— 它靠 autoresizing 活着；§12 那种约束型的界面文件是另一套机制")
// —— 情形三：故事板里同时给了 <rect> 和 <constraints> 的那个标签（lblTitle：24,120,200,44；约束 leading 24 / top 100）。
line("     fresh.view.safeAreaInsets = \(fresh.view.safeAreaInsets)")
expect(fresh.view.safeAreaInsets == UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
       "安全区在这一章是全 0：\(fresh.view.safeAreaInsets) —— 视图从没进过窗口（§11、§20 同一条边界），所以 UIKit 给 safeArea 加的那 4 条约束把布局指南摆成了整个视图")
let beforeLayout = fresh.titleLabel?.frame ?? .zero
fresh.view.setNeedsLayout()
fresh.view.layoutIfNeeded()
expect(fresh.titleLabel?.frame == beforeLayout,
       "跑一次布局，标签仍然停在设计值上：\(String(describing: fresh.titleLabel?.frame)) —— XML 里 <constraints> 那两条此刻什么都没做")
expect(fresh.titleLeading.map { $0.constant == 24 && $0.isActive } == true,
       "可那两条约束是真装着的：\(String(describing: fresh.titleLeading.map { "constant=\($0.constant) active=\($0.isActive)" })) —— 不是「没编进来」，是这个标签不归引擎管")
expect(fresh.titleLabel?.translatesAutoresizingMaskIntoConstraints == true,
       "关键就在这一格：\(String(describing: fresh.titleLabel?.translatesAutoresizingMaskIntoConstraints)) —— 它为「维持原 frame」自动生成一组约束，于是设计值和 <constraints> 各说各话，运行时看到的是设计值")
if let lbl = fresh.titleLabel {
    lbl.translatesAutoresizingMaskIntoConstraints = false
    fresh.view.setNeedsLayout()
    fresh.view.layoutIfNeeded()
    line("     把这一格改成 false 之后立刻重布局：frame = \(lbl.frame)，intrinsicContentSize = \(lbl.intrinsicContentSize)")
    expect(lbl.frame.minX == 24 && lbl.frame.minY == 100,
           "引擎一句话就把标签挪到约束说的那个位置：x = \(lbl.frame.minX)（leading 24）、y = \(lbl.frame.minY)（top 100）—— 那两条 <constraints> 一直都在，只是没人听它")
    expect(lbl.frame.size == lbl.intrinsicContentSize,
           "尺寸也换成了内容自己报的那个：\(lbl.frame.size)，不再是设计那格的 200×44 —— 「约束明明加了，frame 却还是设计稿那一格」这个 bug 就出在这一个 flag 上")
}
// 纯代码 Auto Layout 作对照组：同样的 24/100，一次布局就到位 —— 证明上面那些「停在设计值」
// 不是布局引擎在 headless 里罢工，而是界面文件那一格与那个 flag 的事。
let box = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
let inner = UIView()
inner.translatesAutoresizingMaskIntoConstraints = false
box.addSubview(inner)
NSLayoutConstraint.activate([
    inner.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 24),
    inner.topAnchor.constraint(equalTo: box.topAnchor, constant: 100),
    inner.widthAnchor.constraint(equalToConstant: 120),
    inner.heightAnchor.constraint(equalToConstant: 40),
])
box.setNeedsLayout()
box.layoutIfNeeded()
expect(inner.frame == CGRect(x: 24, y: 100, width: 120, height: 40),
       "纯代码那四条约束算出来的 frame：\(inner.frame) —— 没有窗口也一样算")
// 顺手把「改安全区」这条路也量掉，免得读者以为 headless 里也能摆出刘海留白：
fresh.additionalSafeAreaInsets = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
fresh.view.setNeedsLayout()
fresh.view.layoutIfNeeded()
expect(fresh.view.safeAreaLayoutGuide.layoutFrame == screenBounds,
       "additionalSafeAreaInsets.top = 50 之后指南纹丝不动：\(fresh.view.safeAreaLayoutGuide.layoutFrame) —— 安全区归容器与窗口管，视图不在窗口里就轮不到它")
fresh.additionalSafeAreaInsets = .zero

// ============================================================
// §24 图像素材：界面文件里那一格 image="pip" 是谁来兑现
// ============================================================
section(24, "图像：XML 里 image=\"pip\"、松散 PNG 与 @2x/@3x 查表")
// Main.storyboard 的入口场景里有一个 <imageView id="imgPip" image="pip">，它连到 EntryVC.pipView。
// 本章没有 Images.xcassets：run-all.sh 只跑 ibtool，不跑 actool，所以示例目录里的 Resources/
// 被原样拷进 build/<示例>/（§1 那个「可执行文件自己所在的目录就是 Bundle.main」）。
// 于是书 2.4 那套素材工作流在这里换成松散文件：pip.png（4×4 像素）、pip@2x.png（8×8）、
// pip@3x.png（12×12），外加一份没有兄弟变体的 bare.png（4×4）作对照。
let pipURL = Bundle.main.url(forResource: "pip", withExtension: "png")
line("     bundle 根目录里的图像文件：\(pipURL?.deletingLastPathComponent().path ?? "?")/pip.png、pip@2x.png、pip@3x.png、bare.png")
expect(pipURL != nil && Bundle.main.url(forResource: "bare", withExtension: "png") != nil,
       "松散 PNG 用 Bundle.main.url(forResource:withExtension:) 就取到：\(pipURL?.path ?? "无")")
let carURL = Bundle.main.url(forResource: "Assets", withExtension: "car")
expect(carURL == nil,
       "而这个 bundle 里没有 Assets.car：\(String(describing: carURL)) —— 素材目录那条路（Xcode 用 actool 编成一份 .car）在命令行管线里不存在，松散文件是它的替身；反过来说，任何「只有 Assets.car 才有」的东西在这儿都取不到")
// —— 一、界面文件里那一格是谁兑现的
expect(fresh.pipView.image != nil,
       "XML 那格 image=\"pip\" 在解视图 nib 的时候被兑现了：\(String(describing: fresh.pipView.image)) —— 注意它印的是 anonymous，而 §24 下面代码里取到的印的是 named(...)；两条路各给各的对象")
let nibImage = fresh.pipView.image
expect(nibImage?.size == CGSize(width: 4, height: 4) && nibImage?.scale == 3
       && nibImage?.cgImage?.width == 12,
       "点数 4×4、倍率 3、像素 12×12：size = \(String(describing: nibImage?.size)) scale = \(String(describing: nibImage?.scale)) 像素 = \(String(describing: nibImage?.cgImage.map { "\($0.width)x\($0.height)" })) —— 故事板里那个名字走的也是「按屏幕倍率挑文件」这套查表，不是硬绑 pip.png")
// —— 二、代码里的三种取法
let namedPip = UIImage(named: "pip")
expect(namedPip?.size == CGSize(width: 4, height: 4) && namedPip?.scale == 3 && namedPip?.cgImage?.width == 12,
       "UIImage(named: \"pip\")（不带扩展名，书 2.4 的写法）给出同一个数：size = \(String(describing: namedPip?.size)) scale = \(String(describing: namedPip?.scale)) 像素 = \(String(describing: namedPip?.cgImage.map { "\($0.width)x\($0.height)" }))")
expect((namedPip as AnyObject?) !== (fresh.pipView.image as AnyObject?),
       "可它和故事板那一张不是同一个对象：\(String(describing: (namedPip as AnyObject?) === (fresh.pipView.image as AnyObject?))) —— 而同一个名字再取一次就是同一个：\(String(describing: (namedPip as AnyObject?) === (UIImage(named: "pip") as AnyObject?)))（UIImage(named:) 那侧有一层按名字的缓存，nib 解码那侧没有）")
let namedExt = UIImage(named: "pip.png")
expect(namedExt != nil && namedExt?.scale == 3,
       "名字带扩展名在这台 iOS 上也取得到：\(String(describing: namedExt?.description)) —— 「named 只能不带扩展名」是老文档的说法，别把它当判据")
let rawPip = UIImage(contentsOfFile: pipURL?.path ?? "/dev/null")
expect(rawPip?.cgImage?.width == 12 && rawPip?.scale == 3,
       "更意外的一格：路径明明指着 pip.png，UIImage(contentsOfFile:) 拿到的却是 12×12 那一份（像素 = \(String(describing: rawPip?.cgImage.map { "\($0.width)x\($0.height)" })) scale = \(String(describing: rawPip?.scale))）—— 倍率替换发生在 UIKit 装载图片的地方，不是 imageNamed 的专利；要拿到确凿那 4×4 个像素得绕开 UIImage，走 ImageIO 的 CGImageSource")
// —— 三、那个 3 是文件名给的，不是屏幕给的
let bareImage = UIImage(named: "bare")
expect(bareImage?.scale == 1 && bareImage?.cgImage?.width == 4 && bareImage?.size == CGSize(width: 4, height: 4),
       "同一块 3× 屏上，只有一份 bare.png（没有 @2x/@3x 兄弟）时：scale = \(String(describing: bareImage?.scale))，像素 = \(String(describing: bareImage?.cgImage.map { "\($0.width)x\($0.height)" }))，size = \(String(describing: bareImage?.size)) —— 所以那个 3 不是屏幕给的，是文件名里 @3x 那三个字给的")
// —— 四、找不到的时候，什么声音都没有
expect(UIImage(named: "NoSuchImage") == nil,
       "名字写错就是 nil：\(String(describing: UIImage(named: "NoSuchImage"))) —— 不抛异常，也不往 stderr 写一个字（本章判定 3 全程 0 字节）。「图标怎么是空的」这类问题在现场没有任何日志")
expect((fresh.pipView.image as AnyObject?) === (nibImage as AnyObject?),
       "ImageView 上那个 image 是普通属性，不是每次读都重新查表：现在再读一次，还是 §24 开头记下那张 = \(String(describing: (fresh.pipView.image as AnyObject?) === (nibImage as AnyObject?)))")
// —— 五、框和图是两回事
line("     pipView.frame = \(String(describing: fresh.pipView.frame))，contentMode rawValue = \(String(describing: fresh.pipView?.contentMode.rawValue))")
expect(fresh.pipView.frame == CGRect(x: 24, y: 330, width: 48, height: 48)
       && fresh.pipView.contentMode == .scaleAspectFit,
       "框是 XML 那格 48×48 pt（§23 情形三里那种「子视图照搬设计值」），contentMode = \(fresh.pipView.contentMode.rawValue)（scaleAspectFit）—— 4 pt 见方的图放进 48 pt 的框里，运行时是放大 12 倍摆出来的：这就是「图标糊了」最常见的形状")

// ============================================================
// §25 同一个界面的三条路
// ============================================================
section(25, "同一个界面的三条路：界面文件 / loadView 里手工装配 / SwiftUI 的 body")
// 本章前面所有断言都走在第一条路上（故事板）。这里把另外两条摆到同一张桌子上。
// 不比审美、不比代码行数，只量四件读得出来的事：跑过哪些钩子、根视图的框是多少、
// 子视图的 frame 从哪来、界面上的东西是**什么时候**被造出来的。
// —— 路二：纯代码 UIKit。类在上面（CodeScreenVC），界面在 loadView 那六行里。
hookLog.removeAll(keepingCapacity: true)
let byCode = CodeScreenVC()
byCode.loadViewIfNeeded()
line("     纯代码那条路的账本：\(hookLog)")
expect(hookLog == ["CodeScreenVC.loadView：subviews = 2", "CodeScreenVC.viewDidLoad"],
       "跑过的钩子只有这两个：\(hookLog) —— 对照 §5/§11：故事板那条路多出来的是 awakeFromNib，因为它的对象是「从 nib 里解出来的」；代码 new 出来的控制器没有这一站")
expect(byCode.view.frame == CGRect(x: 0, y: 0, width: 0, height: 0),
       "根视图是零框：\(byCode.view.frame) —— §23 情形一那句「根视图等于屏幕」在这一路上不成立。原因就在 loadView 的 `view = UIView()`：一个新建 UIView 的 frame 默认就是零，而这条路上没有谁去改它。两个对照组：")
let bareVC = UIViewController()
bareVC.loadViewIfNeeded()
line("     · 什么都不写、让 UIKit 自己造视图：\(String(reflecting: type(of: bareVC.view!))) 的 frame = \(bareVC.view.frame)（屏幕是 \(UIScreen.main.bounds)）")
let holdParent = UIView()
let holdChild = UIView(frame: CGRect(x: 0, y: 0, width: 123, height: 45))
holdParent.addSubview(holdChild)
expect(holdChild.frame == CGRect(x: 0, y: 0, width: 123, height: 45) && holdParent.frame == .zero,
       "再对照一条通则：装进去的那一刻谁也没动谁 —— 子视图还是 \(holdChild.frame)，父视图还是 \(holdParent.frame)（addSubview 不改子视图的框）—— 所以下面那颗标签的 (24,120) 能一路活到挂窗口之后")
let smallWin = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
smallWin.rootViewController = byCode
smallWin.makeKeyAndVisible()
let smallWin2 = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
smallWin2.rootViewController = bareVC
smallWin2.makeKeyAndVisible()
line("     · 各挂进一个 300×600 的窗口之后：纯代码 = \(byCode.view.frame)，默认 = \(bareVC.view.frame)")
expect(byCode.view.frame == CGRect(x: 0, y: 0, width: 300, height: 600)
       && bareVC.view.frame == CGRect(x: 0, y: 0, width: 300, height: 600),
       "两条路一起被改成窗口那一格：\(byCode.view.frame) / \(bareVC.view.frame) —— 所以「根视图 = 屏幕尺寸」不是加载视图的通则，而是「根视图被放进窗口那一刻由窗口盖章」；本章量到的场景根视图是屏幕尺寸，只是因为窗口就是屏幕")
expect(byCode.madeLabel.frame == CGRect(x: 24, y: 120, width: 200, height: 44)
       && byCode.madeButton.frame == CGRect(x: 24, y: 200, width: 120, height: 44),
       "盖的是根视图的章，子视图原封不动：\(byCode.madeLabel.frame)、\(byCode.madeButton.frame) —— 代码里写的那两格；没有 XML 那格 <rect> 参与，也就没有 §23 情形三那种「设计值与约束各说各话」")
expect(byCode.madeButton.superview === byCode.view && byCode.madeLabel.superview === byCode.view,
       "两个子视图都直接挂在根视图上：\(byCode.view.subviews.count) 个，按钮的 superview 是根视图 = \(byCode.madeButton.superview === byCode.view)")
expect(targetNames(byCode.madeButton) == ["interface_builder.CodeScreenVC"],
       "§15 那张 target-action 表在这儿是同一套机制，只是这张表由 addTarget 填：\(targetNames(byCode.madeButton))")
expect(byCode.madeButton.actions(forTarget: byCode, forControlEvent: .touchUpInside) == ["didTapCode:"],
       "表里的动作名来自 #selector：\(byCode.madeButton.actions(forTarget: byCode, forControlEvent: .touchUpInside) ?? []) —— 写错一个字母编译期就报错，这是界面文件那条路没有的保护（对照探针 b09：XML 里的选择器写错，ibtool 一声不响）")
byCode.madeButton.sendActions(for: .touchUpInside)
expect(hookLog.count == 2,
       "派发这一环同样过不去：sendActions 之后账本还是 \(hookLog) —— §16 那条边界跟界面文件无关，是「没有 UIApplication」")
expect(byCode.madeLabel.isDescendant(of: byCode.view) && fresh.titleLabel.isDescendant(of: fresh.view),
       "两条路最后都落在同一件事上：视图挂在根视图的某个后代位置（代码 \(byCode.madeLabel.isDescendant(of: byCode.view))，故事板 \(fresh.titleLabel.isDescendant(of: fresh.view))） —— 分别是那两行 addSubview 与 §11 那次视图 nib 解码；而代码这条路没有 outlet 要连，那两个视图是类里声明的存储属性，\(String(reflecting: type(of: byCode.madeLabel))) 直接可读")
// —— 路三：SwiftUI。界面是一个值（struct），body 是算出来的。
bodyRuns = 0
let card = MeasuredCard(titleText: "欢迎")
expect(String(reflecting: type(of: card)) == "interface_builder.MeasuredCard",
       "它的类型是本模块里的一个 struct：\(String(reflecting: type(of: card))) —— §7 那三段字符串的绑定问题在这一路上不存在：没有 XML 要写类名，也没有模块名字符串要和 target 对上")
expect(Mirror(reflecting: card).children.map { $0.value as? String } == ["欢迎"],
       "值里的字段直接读得到，不需要连接、不需要等谁：\(Mirror(reflecting: card).children.map { "\($0.label ?? "?")=\($0.value)" })")
expect(bodyRuns == 0,
       "刚造出这个值，body 一次都没算：bodyRuns = \(bodyRuns) —— 界面文件那条路在 instantiate 那一刻就把对象全解出来了（§5），这一条连「界面」都还不存在，只有一个 struct 的实例")
let hostCard = UIHostingController(rootView: card)
expect(bodyRuns == 0,
       "连 UIHostingController(rootView:) 都还没算：bodyRuns = \(bodyRuns)")
line("     hostCard.view 的实际类 = \(String(reflecting: type(of: hostCard.view!)))，frame = \(hostCard.view.frame)")
expect(String(reflecting: type(of: hostCard.view!)).contains("MeasuredCard"),
       "宿主里面那层视图的类名里就带着 MeasuredCard：\(String(reflecting: type(of: hostCard.view!))) —— 类型是编译期从泛型参数推出来的，不是运行时按字符串去找的")
expect(String(reflecting: type(of: hostCard.view)) == "Swift.Optional<__C.UIView>",
       "顺带一个测量上的坑：UIViewController 的 view 声明成 UIView!（隐式解包可选），直接 type(of:) 拿到的是 \(String(reflecting: type(of: hostCard.view))) —— 上一行末尾那个 ! 不是笔误，是必须解包才量得到真身")
let fitSize = hostCard.sizeThatFits(in: CGSize(width: 320, height: 200))
line("     sizeThatFits(320×200) 返回 \(fitSize)，bodyRuns = \(bodyRuns)")
expect(bodyRuns == 1 && abs(fitSize.width - 38.333333) < 0.001 && abs(fitSize.height - 24) < 0.001,
       "第一次算 body 是被「你要多大尺寸」问出来的：bodyRuns = \(bodyRuns)，返回 \(fitSize) —— 320×200 的提议没被接受，Text 按自己的字宽回了 \(fitSize)；界面文件那条路没人问尺寸，对象是解出来的")
let offHost = UIHostingController(rootView: MeasuredCard(titleText: "不上屏"))
offHost.view.setNeedsLayout()
offHost.view.layoutIfNeeded()
expect(bodyRuns == 1 && offHost.view.subviews.isEmpty,
       "另一条路试过了：不给窗口、只手工布局，body 一次都不算（bodyRuns = \(bodyRuns)，宿主视图的子视图 \(offHost.view.subviews.count) 个）—— 这一路上的「上屏」和 §16 的派发一样，得先把视图放进窗口")
let fullWin = UIWindow(frame: UIScreen.main.bounds)
fullWin.rootViewController = hostCard
fullWin.makeKeyAndVisible()
line("     挂上屏幕尺寸的窗口：bodyRuns = \(bodyRuns)，hostCard.view.frame = \(hostCard.view.frame)")
expect(bodyRuns == 1 && hostCard.view.frame == UIScreen.main.bounds,
       "放上屏幕这一刻只改框、不算 body：\(hostCard.view.frame)（bodyRuns 仍是 \(bodyRuns)）—— 跟上面纯代码那条对照组同一个机制")
hostCard.view.setNeedsLayout()
hostCard.view.layoutIfNeeded()
line("     布局一轮之后：bodyRuns = \(bodyRuns)，子视图 = \(hostCard.view.subviews.map { "\(String(reflecting: type(of: $0)))@\($0.frame)" })")
let drawnFirst = hostCard.view.subviews.first!.frame
expect(bodyRuns == 1 && hostCard.view.subviews.count == 1
       && String(reflecting: type(of: hostCard.view.subviews[0])) == "SwiftUI.CGDrawingView",
       "屏幕上第一次出现东西：\(String(reflecting: type(of: hostCard.view.subviews[0]))) @ \(hostCard.view.subviews[0].frame)，而 body 没有再算一次（\(bodyRuns)）—— 布局用的是 sizeThatFits 那一轮算好的结果；注意它不是 UILabel，本章前面 §15 那张 target-action 表、§24 那个 image 属性在这一路上都没有落脚的地方")
expect(drawnFirst.size == fitSize,
       "画出来的那一格大小就是 sizeThatFits 的答复：\(drawnFirst.size) == \(fitSize) —— 布局没有另算一份尺寸，它把问出来的答案原样用了；代码那条路上没有这一问，(24,120,200,44) 是写死的")
line("     宿主视图的 safeAreaInsets = \(hostCard.view.safeAreaInsets)，bounds = \(hostCard.view.bounds)，那一格 = \(drawnFirst)")
let centerInSafeArea = hostCard.view.safeAreaInsets.top
    + (hostCard.view.bounds.height - hostCard.view.safeAreaInsets.top - hostCard.view.safeAreaInsets.bottom - drawnFirst.height) / 2
expect(drawnFirst.minY == centerInSafeArea,
       "竖直方向是「安全区正中」，不是「整屏正中」：整屏正中该是 \((hostCard.view.bounds.height - drawnFirst.height)/2)，实测 \(drawnFirst.minY) = \(hostCard.view.safeAreaInsets.top) + (\(hostCard.view.bounds.height) − \(hostCard.view.safeAreaInsets.top) − \(hostCard.view.safeAreaInsets.bottom) − \(drawnFirst.height)) ÷ 2 = \(centerInSafeArea) —— 一个字没提安全区的 Text，位置是被安全区推着走的")
let centerExactX = (hostCard.view.bounds.width - drawnFirst.width) / 2
expect(drawnFirst.minX > centerExactX && drawnFirst.minX * UIScreen.main.scale == (drawnFirst.minX * UIScreen.main.scale).rounded()
       && abs(drawnFirst.minX - (centerExactX * UIScreen.main.scale).rounded(.up) / UIScreen.main.scale) < 1e-9,
       "水平方向差一点，差得有名堂：正中间该是 \(centerExactX)，实测 \(drawnFirst.minX) —— 多出来的 \(drawnFirst.minX - centerExactX) 是往上贴到一个像素：屏幕 scale = \(UIScreen.main.scale)，1 px = 1/\(UIScreen.main.scale) pt，\(drawnFirst.minX) × \(UIScreen.main.scale) = \(drawnFirst.minX * UIScreen.main.scale) 刚好是整数（\((centerExactX * UIScreen.main.scale).rounded(.up)) px）")
line("     三个视图的安全区：没上屏的 fresh = \(fresh.view.safeAreaInsets)，挂在 300×600 窗口的 byCode = \(byCode.view.safeAreaInsets)，整屏窗口的 hostCard = \(hostCard.view.safeAreaInsets)")
expect(fresh.view.safeAreaInsets.top == 0 && fresh.view.safeAreaInsets.bottom == 0
       && byCode.view.safeAreaInsets.top == 62 && byCode.view.safeAreaInsets.bottom == 0
       && hostCard.view.safeAreaInsets.bottom == 34,
       "安全区是窗口给的，不是界面文件写的（XML 里没有一行写 62 或 34）：没挂进任何窗口的 fresh 四项全零，所以 §23 那条「顶边 = 安全区顶 + 100」的约束量出来 y 正好是 100.0（那一刻 safeAreaLayoutGuide = \(fresh.view.safeAreaLayoutGuide.layoutFrame)，就是整块 bounds）；同一个界面上屏，62 与 34 立刻出现 —— 而 300×600 那种小窗口只有上边 62、下边 0，因为它的底还没碰到 Home 指示条那一带")
hostCard.rootView = MeasuredCard(titleText: "第二个值，比方才长")
expect(bodyRuns == 1 && hostCard.view.subviews[0].frame == drawnFirst,
       "换掉 rootView 这一行执行完，body 还是 \(bodyRuns) 次、屏幕上那一格的 frame 一模一样（\(hostCard.view.subviews[0].frame)）—— 值换了，什么都还没发生；对照 §16：界面文件那条路上换了 target 表也不会自己派发")
hostCard.view.setNeedsLayout()
hostCard.view.layoutIfNeeded()
line("     再布局一轮：bodyRuns = \(bodyRuns)，子视图 = \(hostCard.view.subviews.map { "\(String(reflecting: type(of: $0)))@\($0.frame)" })")
let drawnSecond = hostCard.view.subviews.first!.frame
expect(bodyRuns == 2 && drawnSecond.width > drawnFirst.width,
       "这一次 body 被重算了（\(bodyRuns)），而且新的字真的变了大小：\(drawnFirst.width) → \(drawnSecond.width)，x 也跟着挪 \(drawnFirst.minX) → \(drawnSecond.minX) —— 「改了值看不见」不是 SwiftUI 不重算，是还没走到布局那一轮")
hostCard.view.setNeedsLayout()
hostCard.view.layoutIfNeeded()
expect(bodyRuns == 2,
       "什么也没改，再布局一轮还是不涨：bodyRuns = \(bodyRuns) —— body 不是每帧重算的；这一路上「算了几个」和「布局了几轮」是两个数")
line("     宿主控制器自己的父链：\(superclassChain(of: hostCard).prefix(4).map { $0 })")
expect(superclassChain(of: hostCard).contains("UIViewController"),
       "它本身就是一个 UIViewController（父链里找得到）—— 所以本章前面每一条 UIKit 缝隙（导航栈、outlet、segue、§23 的框）它都塞得进去，两条路混用不需要桥")
// —— 三条路的「界面上到底有几个东西」收个尾。
line("     路一：Main.storyboard 入口场景 → §2 那 6 个 nib；路二：CodeScreenVC.loadView() 里那两行 addSubview；路三：MeasuredCard.body 里的一次 Text 调用")
line("     清点 fresh.view.subviews：\(fresh.view.subviews.map { "\(String(reflecting: type(of: $0)))@\($0.frame)" })")
expect(fresh.view.subviews.count == 5 && byCode.view.subviews.count == 2,
       "故事板那个场景跑起来是 \(fresh.view.subviews.count) 个子视图，纯代码那个是 \(byCode.view.subviews.count) 个 —— 别按 XML 数：那份 <subviews> 里只有 4 个（标签、两颗按钮、一个 imageView），第 5 个 UIButton 是 §16 用代码 addSubview 加进去的（那个零框的）。运行时数出来的是「XML 解出来的 + 代码加的」，只看 XML 会数少")

// ============================================================
// §26 收尾：同一份配方第三次开锅，以及哪些数字只是这台机器的脾气
// ============================================================
section(26, "收尾：第三次实例化同一份 XML，然后把本章的数字分成「结构性」与「这台机器的」两堆")
// 本章从头到尾都在做同一件事：拿一份 XML，读它在运行时变成了什么。收尾先做一次
// 「再拿一次」—— §22 已经对 XIB 量过「配方不是单例」，故事板这条路同样要钉一遍。
hookLog.removeAll(keepingCapacity: true)
let third = sb.instantiateInitialViewController() as! EntryVC
third.loadViewIfNeeded()
expect(third !== fresh && third.view !== fresh.view,
       "第三次开锅还是全新的一组对象：控制器与 §11 那个 = \((third === fresh) ? "同一个" : "不是同一个")，视图与它 = \((third.view === fresh.view) ? "同一个" : "不是同一个") —— 每次 instantiate 都重新解一遍 nib，没有缓存好的那一份「界面」在等着被复用")
expect(third.badge == 7.0 && third.caption == "故事板填进来的标题" && third.flagged
       && third.titleLabel?.text == "欢迎",
       "而 XML 那几格一字不差地重现：badge = \(third.badge)、caption = \"\(third.caption)\"、flagged = \(third.flagged)、titleLabel.text = \(third.titleLabel?.text ?? "nil") —— 「跑起来看看」难复制就在这两件事同时成立：对象每次都是新的，值每次都是准的")
expect(hookLog.count == 2 && hookLog.first?.hasPrefix("awakeFromNib") == true && hookLog.last?.hasPrefix("viewDidLoad") == true,
       "钩子也每趟都重跑：\(hookLog) —— §5/§11 那张时序表不是这一进程的偶然，任何一次 instantiate 都走这两站")
expect(nibNames(packageURL).count == 6 && lookupTable(packageURL).keys.sorted() == ["PlainScreen", "TheSecond", "UIViewController-ENT-01-001"],
       "顺带确认本章的证据链没在中途变过：磁盘上还是 §2 那 \(nibNames(packageURL).count) 个 nib、查找表还是那 \(lookupTable(packageURL).count) 项（\(lookupTable(packageURL).keys.sorted())）—— 中途没有任何一步「运行时把界面文件改了」")
// —— 然后把数字分成两堆。这一节只做登记，不做新测量。
let device = UIDevice.current
line("     跑这一份输出的机器：\(device.systemName) \(device.systemVersion)（\(ProcessInfo.processInfo.operatingSystemVersionString)），"
     + "UIScreen.main.bounds = \(UIScreen.main.bounds)，scale = \(UIScreen.main.scale)")
line("")
line("  【只在这台机器上成立的数字】—— 换设备/换 iOS 版本请重跑，别照抄：")
line("    · 屏幕 \(UIScreen.main.bounds.width)×\(UIScreen.main.bounds.height) pt、scale \(UIScreen.main.scale)：§23 把 XML 的 414×896 改成屏幕值、§25 把根视图改成窗口值、")
line("      §24 拿 @2x/@3x 时用的都是它；§25 里 182.0 那个 x 是贴到 1/\(UIScreen.main.scale) pt 的像素格上得到的。")
line("    · 安全区 62 / 34（§25）：刘海机才有的数；XML 里没有这两个数，§23 那条 top = 安全区顶 + 100 的约束在没上屏时量到 100.0、")
line("      挂上 300×600 的小窗口时底部变成 0，都是这一条的推论。")
line("    · 38.33…×24（§25）：那是系统字体 20 pt 排「欢迎」两个字的字宽，换文案、换字体、换 Dynamic Type 全都变。")
line("    · §2 那 6 个 nib、§10 查找表少一项：场景数一变，数目跟着变；结构（一个场景两条 nib）才是要记的。")
line("    · ObjC description 里的内存地址：每进程重新分配，所以本章所有输出前统一走了一次脱敏（把 0x 后面的长十六进制串换成 0x…）——")
line("      这是 run-all.sh 最后那条「debug 与 release 逐字节一致」能过的原因之一。")
line("")
line("  【与这台机器无关的结构性结论】：")
line("    · 一份 XML → 一个场景两条 nib（控制器一条、视图一条），标识符决定 nib 名（§2/§9/§10）。")
line("    · customClass/customModule 三段字符串写错，ibtool 零诊断，运行时静默退回 plain UIViewController（§7/§8，原文见探针 b01/b02）。")
line("    · 不可达的场景 ibtool 直接不生成 nib（§3，探针 b03）—— 本章最危险的一条，因为它连报错都没有。")
line("    · 连接是视图 nib 被解的那一刻做的一次 KVC 赋值：对象身份（===）能连、约束也能连（§11/§12）。")
line("      问错 key 分两种下场：outlet 的 property 名在类里不存在 → NSUnknownKeyException 直接 abort（探针 r03），")
line("      File's Owner 交错（nil 或类型不含那个 key）是同一句话（探针 r11/r12）；")
line("      而 userDefinedRuntimeAttribute 的 keyPath 写错只往 stderr 打一句 NSLog、进程 rc=0 跑完（探针 r04）—— 软失败与硬失败的分界就在这儿。")
line("    · @IBInspectable 只管 Xcode 给不给那一格，运行时起作用的是 KVC（§14：SecondVC 一个都没标，title 照样被填）。")
line("    · @IBAction 落到运行时是控件表里的一个字符串选择器；kind=\"unwind\" 那条线的 target 是 segue 模板而不是控制器（§15/§17/§20）。")
line("      可控制器的 performSegue(withIdentifier:) 照样查得到那条 identifier，它和手工派发模板那句 perform: 的账本逐字相同（§20）。")
line("      「has no segue with identifier」说的是那条连接根本没编出来 —— 例如 <exit> 放错了位置（探针 b11），不是 unwind 天生不能用 performSegue。")
line("")
line("  【三条 headless 边界】—— 不是界面文件的问题，是「没有 UIApplication」的问题：")
line("    · §16：sendActions(for:) 表读得出、事件不派发；")
line("    · §20：手工 perform: 能调到 segue 模板，模板自己 perform 完但栈不弹，得自己 popToViewController；")
line("    · §25：SwiftUI 那条路 body 不挂窗口就不会算，只有 sizeThatFits 问得出（挂上窗口 + 布局一轮才看见 CGDrawingView 落地）。")
line("    同一个根：§11 那句「没有 window 就没有 Appearance 回调」。")
line("")
line("  【本章刻意没量的】：actool 与 Assets.car（产物目录里只有松散 PNG，§24 走的是那条查表通路）；@IBDesignable 的画布渲染")
line("     （那是 Xcode 进程里的事，不在运行时）；UITabBarController / UICollectionView / UITableView 的故事板 wiring；")
line("     Auto Layout 的优先级、content hugging、stack view（§23 只量了 translatesAutoresizingMaskIntoConstraints 这一开关）；")
line("     trait variations 与 size classes；state restoration；launch storyboard；xcodeproj 里 MAIN_STORYBOARD 那类工程设置")
line("     （本书 2.1 的向导产物是 .app，本章产物是裸可执行文件，两边「界面从哪来」的机制不同，§1 量了差别）。")
line("")
line("  一句话：这一章把「一张 XML 画出来的界面怎么和 Swift 接上线」拆成了三段可查的账——编译产物里有什么（§1–§3）、")
line("  运行时解出什么、什么时候解（§4–§14）、线和 segue 在运行时是谁（§15–§22）、框与尺寸有几格真生效（§23–§25）。")
line("  凡是「Xcode 里拖一条线、跑起来看看」的问题，在这儿都能换成一句能跑、能读、能断言的话。")

if failures == 0 {
    line("\n全部断言通过。")
} else {
    line("\n有 \(failures) 条断言失败。")
}
print("==== 31 结束 ====")
exit(failures == 0 ? 0 : 1)
