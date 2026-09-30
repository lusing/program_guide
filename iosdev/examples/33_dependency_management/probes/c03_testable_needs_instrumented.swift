// c03：`@testable` 那道门开在**产物**上，不在配置名上 —— 同一份源码，两个配置一对一错。
//
// e04 现跑给的是一个和直觉相反的结果：主线链的那份 `swift build -c debug` 产物，
// 里面每个 target 都是带 `-enable-testing` 编的（看 s04 的 ps 输出即知），
// 所以 `@testable import WeatherKit` + 直接调 internal 的 `internalTag()` **编译通过**。
// 光有这一半，「@testable 不是权限关键字」就只是一句口号：得让 internal 可见性
// 在某一趟里真的拒绝一次，才看得出拒绝的理由不是访问级别，而是那份 .swiftmodule
// 有没有为测试而编。
//
// 于是这一支拿同一份源码链两套包产物（.args 一个字不改，@MODULES@ 由 run.sh 按配置换）：
//   debug   → 编译通过、放进模拟器照常打印；
//   release → 同一行 @testable，编译器给出的是「这份模块没为测试编」。
// 两边差的就那一行 -enable-testing，而访问级别、模块名、源码全都相同。
//
// 跑法：bash probes/run.sh c03（两个配置各编一遍，能跑的那个再进模拟器）
@testable import WeatherKit

print("internalTag() = \(internalTag())")
