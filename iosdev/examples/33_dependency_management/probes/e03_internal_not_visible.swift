// e03：包里的 internal 名字在模块外一律不可见 —— 三种写法各撞一次。
//
// ClimateCore 那份源码里刻意留了三个内部名字：
//   hiddenOffset()      一个 internal 函数（§「默认访问级别在跨模块这一刻才咬人」）
//   InternalReading     一个 internal 类型
//   BundleLayout        这个反而**是** public，但它的一个成员是内部算出来的
// 加上 WeatherKit 的 internalTag()。主线能引用到的只有 public 的那些，
// 这一支把边界外面的名字逐条写出来，抄 swiftc 逐条怎么回。
//
// 跑法：bash probes/run.sh e03（只编译，期望：三条「找不到」级别的诊断）
import ClimateCore
import WeatherKit

print(hiddenOffset())
print(InternalReading(celsius: 1))
print(internalTag())
