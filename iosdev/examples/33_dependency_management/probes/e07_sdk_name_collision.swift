// e07 / e08 是同一份源码的两次编译，区别只在 .args：
//   e07 —— 不给 `-I <中间目录>/Modules`（于是包的 WeatherKit 不在搜索路径里）
//   e08 —— 给（default.args 那套，= 主线的全量输入）
//
// 源码里故意交错写两组名字：`WeatherService` 只存在于**苹果**的 WeatherKit，
// `report(for:)` / `Reading` 只存在于**本章这个包**的 WeatherKit。两次的报错正好互补，
// 于是「import 到的到底是哪一个模块」这件事被 swiftc 自己说了出来。
//
// 这一支要推翻的直觉是「no such module 是唯一那种没接上依赖的错」。撞了 SDK 的
// 框架名时编译器**不会**报找不到模块 —— 它找到了一个，只是不是你要的那个。
//
// 跑法：bash probes/run.sh e07 e08

import WeatherKit

_ = WeatherService()
print(report(for: Reading(city: "北京", celsius: 20)))
