#include "CLIBrain.h"

/// 一个「只会算」的 C target：它不认识 Foundation，也没有 Swift 依赖。
/// 主线 §10 要看的是它编出来的 .o 与那份生成出来的 module.modulemap（§1 四类输入里的
/// 第 2、3 类），以及「Swift 侧要 import 它，命令行上还差哪一下」（少 modulemap：e02；
/// 少 .o：编译全过、红在链接，e09）。

const char *cliBrainVersion(void) { return "CLIBrain/c-1"; }

/// Magnus 公式，系数取固定值：露点只由气温与相对湿度决定，两个优化配置下必须给同一个数。
double cliDewPoint(double celsius, double relativeHumidity) {
    const double a = 17.625;
    const double b = 243.04;
    double gamma = (a * celsius) / (b + celsius) + __builtin_log(relativeHumidity / 100.0);
    return (b * gamma) / (a - gamma);
}
