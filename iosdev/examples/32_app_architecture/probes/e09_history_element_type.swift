// 探针 e09：`NSArray` 少写了元素类型，Swift 侧就只知道它是一堆 Any
//
// 主线 §30 读 HUD 那本账时写的是
//     let hudLines: [Any] = ProgressHUD.history()
// 并且每个元素都过一次 `as? String`。这一支抄的是「为什么不写成 [String]」的原文：
// 头文件里那句 `+ (NSArray *)history` 没有尖括号，元素类型在**桥的另一侧**就已经丢了，
// Swift 拿到的是 `[Any]!`。
//
// 第二行是对照，而且是这一支的重点：`ProgressHUDStrict.history` 在 .m 里走的是**同一个**
// hud_record（实现完全一样），头文件写成 `NSArray<NSString *> *` 之后 Swift 就给 `[String]`。
// 所以「桥这一侧看到什么类型」是头文件决定的，不是实现决定的 —— §30 那条结论的凭据。
//
// 跑法：bash probes/run.sh e09
import UIKit

let loose: [String] = ProgressHUD.history()
let strict: [String] = ProgressHUDStrict.history()
print(loose, strict)
