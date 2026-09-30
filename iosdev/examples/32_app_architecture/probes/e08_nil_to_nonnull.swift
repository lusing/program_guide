// 探针 e08：同一句 `showError(nil)`，在两个类上一个是合法的、一个是编译期错误
//
// 主线 §30 的断言：把 nil 递给 `ProgressHUD.showError(_:)`（头文件里那个
// `_Null_unspecified`）Swift 编译器一个字都不说；同一件事写在
// `ProgressHUDStrict`（NS_ASSUME_NONNULL 包住的那个）上是**编译期**错误。
// 这两句话只差头文件里那两行宏，而 §30 的结论「nil 能不能进来不是由类型决定的，
// 是由另一侧有没有防决定的」全靠这一条原文撑着。
//
// 对照用不着另一支探针：下面第一行是主线里跑过的那一句（合法、无告警），
// 第二行是这一支要的 error。同名 .h 就是主线的 ProgressHUD.h。
//
// 跑法：bash probes/run.sh e08
import UIKit

ProgressHUD.showSuccess(nil)          // 合法：Swift 侧的类型是 String!
ProgressHUDStrict.showSuccess(nil)    // ← 这一行才是这一支要量的：编译器拒绝
