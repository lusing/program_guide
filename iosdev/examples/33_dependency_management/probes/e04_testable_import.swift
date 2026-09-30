// e04：`@testable import` 链着 `swift build -c debug` 的产物 —— **编译通过**（退出码 0）。
//
// 这一支先记录一个反直觉的读数：包是 -c debug 编的，看起来「不是给测试用的」，
// 但 SwiftPM 在 debug 配置下给每个 target 都加了 `-enable-testing`，
// 所以 internal 的 `internalTag()` 在这里就可见了 —— e03 那份「找不到」的红全数消失。
// 也就是说 `@testable` 吃的不是「这是 debug 产物」，而是「这份 .swiftmodule 有没有为测试编」。
// 两半的对照在 c03：同一行 @testable 链 -c release 的产物，编译器立刻拒绝，
// 理由写得很清楚，而且和访问级别无关。
//
// 跑法：bash probes/run.sh e04（只编译）
@testable import WeatherKit

print(internalTag())
