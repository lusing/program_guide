// e02：给了 `-I Modules`，但**少给 `-Xcc -fmodule-map-file=<CLIBrain 的 modulemap>`**。
//
// 这是本章最反直觉的一支：源码里一个字都没提 CLIBrain（主线只 `import WeatherKit`），
// 却照样要那份 modulemap。原因是 `.swiftmodule` 里存的是**符号级**的依赖 ——
// WeatherKit 的 `report(for:)` 在实现里调了 C 函数 `cliDewPoint`，这个引用留在
// 模块里，swiftc 载入模块时就得把 CLIBrain 这个 Clang 模块也建起来；而 CLIBrain 的
// modulemap 是 SwiftPM **生成在构建目录里**的（不在源码树里，见 s12），不递过去就没人知道
// `CLIBrain` 是哪张头文件。Xcode 里这一步是自动的，命令行上它是 run-all.sh 里的一行。
//
// 跑法：bash probes/run.sh e02
import WeatherKit

let text = report(for: Reading(city: "北京", celsius: 20))
print(text)
