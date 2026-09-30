#ifndef CLI_BRAIN_H
#define CLI_BRAIN_H

/// 这个 C target 对外只有一张头文件。主线 §10 量的就是它：SwiftPM 会给每个 C target
/// 生成一份 module.modulemap（umbrella header 的路径是**绝对路径**，写在构建目录里），
/// 而 Swift 侧要 import 它，命令行必须把这份 modulemap 递过去
/// （`-Xcc -fmodule-map-file=…`）—— Xcode 里这一步是自动的。两个函数在 Swift 侧都是
/// 「C 的拼写 + 可选指针」，名字的翻译表在主线 §10 那一段。
const char *cliBrainVersion(void);
double cliDewPoint(double celsius, double relativeHumidity);

#endif
