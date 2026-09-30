// e01：主线那条 swiftc 命令里，**少掉 `-I <中间目录>/Modules`** 会怎样。
//
// `import X` 在 Xcode 里是一个自动出现的答案，命令行上它依赖一件具体的东西：一份
// `.swiftmodule`（不是源码、不是 .o），而 swiftc 只会去 -I 给的目录里找它。
// 这一支连 -I 都不给，所以期望「这个模块根本不存在」的那种错。
//
// 为什么这里挑 ClimateCore 而不是 WeatherKit：模拟器 SDK 里**正好有一个
// System/Library/Frameworks/WeatherKit.framework**，`import WeatherKit` 少给 -I 也不会
// 报「找不到模块」，它会安静地绑到苹果那个模块上 —— 那是 e07/e08 两兄弟量的东西。
// 名字不撞车的模块才能证明「-I 是唯一的那道门」，撞了名字的那个证明的是另一件事。
//
// 跑法：bash probes/run.sh e01
import ClimateCore

print(climateCoreID)
