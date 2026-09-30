// e05：`import WeatherKit` 会不会顺手把 ClimateCore 也带进来。
//
// 依赖树是 WeatherKit → ClimateCore（包的传递依赖）。这一支**只** import WeatherKit，
// 然后直接用 ClimateCore 的公开常量 `climateCoreID`。
// 要量的问题是：符号链得上（.o 全给了，见 default.args），名字能不能落地。
//
// 这一格和第 6 章的桥接头文件那条「import 不会传染」是同一件事的两面，
// 但包这边多一层：SwiftPM 还会决定**搜索路径里有没有**那个 .swiftmodule ——
// 后者由探针 s09 在包这一层量（少写 target 依赖时，连编译都不开始）。
//
// 跑法：bash probes/run.sh e05
import WeatherKit

print(climateCoreID)
