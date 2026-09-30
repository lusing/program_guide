// e06：公开 API 的**签名里**带着另一个模块的类型，用的人要不要 import 那个模块。
//
// WeatherKit 里那一行是 `public func preferredUnit() -> TemperatureUnit`，
// 而 `TemperatureUnit` 属于 ClimateCore。这一支只 import WeatherKit：
//   第一半：拿到返回值、调用它的方法 —— 看 Swift 让不让过；
//   第二半：把类型名写出来（显式标注 / 枚举 case）—— 看 Swift 在哪一步拦。
//
// 这两半的差别就是书 10.3 那种「照抄示例代码却报一个看不懂的错」的形状：
// 能用、能传，就是**写不出名字**；要写名字必须自己把那个包也 import 上。
//
// 跑法：bash probes/run.sh e06
import WeatherKit

let unit = preferredUnit()
let viaMember = unit.convert(20)
print("只用返回值：\(unit) / \(viaMember)")

let explicit: TemperatureUnit = .celsius
print("写出类型名：\(explicit)")
