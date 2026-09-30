// c01：同一份源码分别链 debug 与 release **两套包产物**，抄两边的浮点读数。
//
// 第 30/32 章的 cNN 量的是主线自己那两个配置；这里量的是**依赖那一侧**的配置 ——
// 包里的 `cliDewPoint` 由 clang 编，`report(for:)` 由 Swift 编，`-c release` 把它们
// 全换成 -O 的产物。run-all.sh 的第六条判定要求主线两个配置 stdout 逐字节一致，
// 而这条判定**管不到包**：包是 `swift build` 编的，两个配置各一套 .o。
// 所以这里逐个把露点的原始位型打出来：如果 clang 的 -O 改了浮点（fast-math 那类），
// 位型层面就能看见，而 %.1f 的字符串看不见 —— 这就是本章为什么打位型不打字符串。
//
// 跑法：bash probes/run.sh c01（两个配置各编各跑，抄差异）
import CLIBrain
import Foundation
import WeatherKit

let cases: [(Double, Double)] = [(20, 60), (-3.5, 88), (37.7, 15), (0.1, 99.9), (100, 0.5)]
for (t, rh) in cases {
    let dew = cliDewPoint(t, rh)
    print(String(format: "%6.2f°C / %5.2f%% -> %.17g  bits=%016llx", t, rh, dew, dew.bitPattern))
}
print(report(for: Reading(city: "北京", celsius: 20)))
