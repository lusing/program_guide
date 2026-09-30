// r01：一条**期望它跑绿**的探针 —— 这才是本章最阴的那一格。
//
// e07 说明了「少给 -I 之后 import WeatherKit 会绑到 SDK 那个框架」，但它至少是红的。
// 这一支把源码换成一句都不碰包里独有名字的版本，配上 e07 那份**不给 -I**的 .args：
// 结果编译日志为空、退出码 0、放进模拟器照样打印。也就是说 run-all.sh 那六条判定
// 在这一支上**全部通过**，而这个「通过」里根本没有本章那个包 ——
// 「No such module 'Alamofire'」不是接不上依赖的唯一下场，接不上而一切正常才是。
//
// 两道闸各挡住一半：
//   `#if canImport(WeatherKit)` —— 挡不住，SDK 里那份一样能 import（这一支走的就是 else 之外的那条路）；
//   主线 §2 那条 `weatherKitID == "WeatherKit/1.0"` —— 挡住了：
//     苹果那 47 个顶层 public 声明里没有这个名字，写成主线那样立刻红。
//
// 跑法：bash probes/run.sh r01（编 + 放进模拟器跑，抄 stdout / stderr / 退出码）
import WeatherKit

#if canImport(WeatherKit)
let bound = "canImport(WeatherKit) 为真 —— 但这不能说明接上了包"
#else
let bound = "canImport(WeatherKit) 为假"
#endif
print(bound)
