// 探针 r05：KVO 挂在纯 Swift 属性上，编译器只警告 —— 运行时到底给什么
//
// 主线 §19 用 `observe(\.score)` 量「谁在这次数变化时被叫到」，而 QuizViewController
// 里那个属性写成了 `@objc dynamic var score`。探针 e06 量的是「不写那两个词」的一半：
// 编译器**并不拒绝**，它给一条 warning（`passing reference to non-'@objc dynamic'
// property ... may lead to unexpected behavior or runtime trap`）然后编译通过。
// 于是真正的问题落到运行时：这一支把它跑出来。
//
// 两种可能的「不给」是很不一样的两件事：
//   A) 当场崩（trap / NSException）—— 至少它让你知道有问题；
//   B) 一句都不报、观察者一条都不收 —— 这才是架构上最贵的一种：
//      你写了一个「Model 变了界面就该跟着变」的机制，它安静地不存在。
// 这一支的判据就是分清这两者。
//
// 跑法：bash probes/run.sh r05
import UIKit

setvbuf(stdout, nil, _IONBF, 0)

final class PlainQuiz: UIViewController {
    var score: Int = 0
    @objc dynamic var strictScore: Int = 0
}

let vc = PlainQuiz()
var hits: [String] = []

// 先跑对照：同一个对象上那个 @objc dynamic 属性，注册与命中都正常。
// 它排在前面是**必须**的 —— 下面那一句会让进程当场结束，写在它后面的都读不到。
let strictToken = vc.observe(\.strictScore, options: [.old, .new]) { _, change in
    hits.append("strict \(change.oldValue ?? -1)→\(change.newValue ?? -1)")
}
vc.strictScore = 1
vc.strictScore = 2
print("对照（@objc dynamic）：改两次命中 \(hits.count) 次 → \(hits.joined(separator: " "))")

print("下面这一句是注册那个**纯 Swift** 属性的观察者，进程还活着：")
let plainToken = vc.observe(\.score, options: [.old, .new]) { _, change in
    hits.append("plain \(change.oldValue ?? -1)→\(change.newValue ?? -1)")
}
print("跑不到这里：\(plainToken)")
strictToken.invalidate()
print("==== r05 结束 ====")
