// e09：四类输入里第 3 类（各 target 的 .o）少给**一个** —— 链接期才红，而且红得指名道姓。
//
// 主线 §1 把 run-all.sh 多吃的四类输入列成清单，§21 说「三个 target 的 .o 都在链接输入里，
// 缺任何一个都到不了运行这一步」。这一支就是那句话的原文凭据：
//   -I 照给（所以类型检查全过：`report(for:)`、`Reading` 都认得）
//   CLIBrain 的 module.modulemap 照给（所以 `import` 链上也过）
//   .o 给四个、**单独扣掉 brain.c.o**
// 于是编译器一路点到链接那一步才停，报的是「哪个符号没人实现」——
// 这一类错和「找不到模块」完全不同：它不给文件名不给行号，只给一张符号清单。
//
// 为什么这一支值得单独有：它是本章唯一一类**编译通过、链接失败**的缺失。
// 「No such module」那种红（书 10.8 的提示）在这里不会出现，
// 出现的是 `Undefined symbols for architecture x86_64`。
//
// 跑法：bash probes/run.sh e09
import WeatherKit

print(report(for: Reading(city: "北京", celsius: 20)))
