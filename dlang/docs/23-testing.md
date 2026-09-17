# 23 · 测试与工具链

> 对应示例：`examples/23_testing/`

## 23.1 unittest 深入

```d
double cToF(double c) { return c * 9 / 5 + 32; }

unittest { assert(cToF(0) == 32); }          // 一个函数可以挂多块
unittest { assert(cToF(-40) == -40); }       // 按主题分组：基础/边界/异常
```

**运行语义**（2.113 实测，02 章坑位的完整版）：

| 方式 | 行为 |
|---|---|
| `dmd -unittest -run x.d` | 只跑 unittest（**main 不执行**） |
| `dmd -unittest x.d` + 运行 exe | 同上：跑完测试即退 |
| `dmd x.d` + 运行 | 只跑 main |
| `dub test` | 生成测试 main，跑全部模块单测 |

所以"测试 + main 都要验"就得编译两次（build.ps1 的两层验证）。

## 23.2 断言家族

```d
assert(cToF(0) == 32);                          // 布尔（-release 剥离）
assertThrown!Exception(parseTemp("36.6X"));     // 期待抛
assertNotThrown!Exception(parseTemp("36.6C"));  // 期待不抛
assert(isClose(parseTemp("98.6F"), 37.0, 1e-3));// 浮点近似（approxEqual 已弃用）
```

没有 expectEqual/expectThrows 那套——**assert 一把梭**。数组/结构体直接 `==`（元素级/字段级比较是内建语义）。

## 23.3 模板旁的测试：按实例化生成

```d
struct Box(T) {
    T value;
    T doubled() const { return value + value; }
    unittest { assert(Box!int(21).doubled == 42); }   // 随模板实例化
}
```

写在模板声明**内部**的 unittest 会为每个用到的 `T` 实例化一份——泛型库的标准测试姿势。

## 23.4 文档注释（ddoc）

```d
/// 摄氏转华氏。
///
/// Params:
///   celsius = 摄氏温度
/// Returns:
///   对应华氏温度
double cToF(double celsius) { ... }
```

`dmd -D -o- source.d` 生成 HTML 文档——ddoc 是内建的，注释即文档（Phobos 全靠它）。

## 23.5 覆盖率与基准

```bash
dmd -cov -unittest main.d && ./main     # 生成 main.d.lst：逐行命中统计
```

```d
import std.datetime.stopwatch : StopWatch;
StopWatch sw; sw.start();
...; 
sw.peek.total!"msecs";                  // 毫秒（还有 nsecs/usecs/seconds）
```

基准数字**别写进断言**（机器相关），跑出来看即可。

## 23.6 工具链清单

| 工具 | 用途 | 本机 |
|---|---|---|
| `rdmd x.d` | 编译+缓存+运行（脚本/单文件） | 随 DMD |
| `dub test` | 工程级全量单测 | ✅ |
| `dmd -cov` | 覆盖率 | ✅ |
| `dmd -D` | ddoc 文档生成 | ✅ |
| dfmt | 官方格式化器 | ❌ 未装（要装：dub 生态 install） |
| DScanner | 静态检查/lint | ❌ 未装 |
| unit-threaded | 第三方增强测试库 | 未用（内建够教程用） |
| `dmd -g` + WinDbg/VS | 调试（PDB 原生） | ✅ |

调试崩溃栈：默认异常会打模块+偏移；`-g` 编译后有符号。Windows 下 DMD 产物是标准 PDB——VS/WinDbg 直接调。

## 23.7 坑位清单

1. **`-unittest` 不跑 main**（02 章讲过，这里复习：它不是 bug 是设计——测试入口独立）。
2. **`approxEqual` 已弃用**：用 `isClose`（std.math）——Deprecation 在 -w 下当错误，老代码迁移必改。
3. **assert 在 -release 下消失**：想发布版也保留的检查用 `enforce`（09 章，它抛 Exception 不受影响）。
4. StopWatch 是 struct 直接声明，`sw.peek.total!"msecs"` 的 `!"msecs"` 别写成 `.msecs`。
5. `assertThrown!类型` 要求异常类型精确或为其**子类**；`assertThrown!Exception` 是万金油。
6. `-cov` 的 .lst 报告"行覆盖"——模板未实例化的行标 0，别误读成"没测到"（没实例化压根不存在）。
7. ddoc 的 `Params:`/`Returns:`/`Throws:` 是约定关键字——`dmd -D` 按它们排版，写错只是排版丑不影响编译。

---
