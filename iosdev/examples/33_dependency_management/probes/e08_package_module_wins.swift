// e08：源码与 e07 逐字相同，**只有 .args 不同**（这一支走 default.args，即 -I 给全）。
// 两兄弟放在一起读才有意义：同一行 `import WeatherKit`，加了 -I 之后报错的那两个名字
// 换了人 —— 说明绑定的模块换了。
//
// 跑法：bash probes/run.sh e07 e08

import WeatherKit

_ = WeatherService()
print(report(for: Reading(city: "北京", celsius: 20)))
