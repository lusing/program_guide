# 25 · 多平台：JS、Native 与 Wasm ⭐

> 对应示例：`examples/25_multiplatform/`——**同一份** `src/Common.kt`（算法 + 断言 + main），
> 配上四个平台目录里各 6~20 行的 `actual` 实现，用 expect/actual 机制编到 **4 个目标**：
> js / wasm-js / wasm-wasi / native。四份输出快照（`expected-js.txt` 等）逐字节相同，
> 只有 platform 一行不同——这份 diff 就是"多平台复用"最直观的证据。
>
> 前 24 章的 Kotlin 都活在 JVM 上。本章把同一份代码编进 node、浏览器、
> 独立二进制和 WebAssembly，讲清四个目标的编译管线、互操作方式，
> 以及"共享多少、各写多少"的工程经济学。
> 工具链口径：Kotlin **2.4.21**（K2 编译器）家族的 kotlinc-js / kotlinc-wasm / konanc，
> **JDK 21**（konanc 的硬约束，25.3 讲原因），node 运行时跑 JS 与 Wasm 产物。
> 引用快照时有一处版本细节需要说明，见 25.9（版本行只打 major.minor 的原因）。

## 25.1 全景：一条前端，四个后端

Kotlin 的口号是"一门语言，多平台复用"。这句话落到编译器架构上，是**一条前端、四个后端**：

```text
                    ┌─ JVM 后端   → .class / .jar（前 24 章）
Kotlin 源码 → K2 前端 │
 (解析/类型检查/IR) ├─ JS 后端    → .js（IR 经转译/压缩）
                    ├─ Wasm 后端  → .wasm + .mjs 胶水（WasmGC）
                    └─ Native 后端 → LLVM → 机器码 .exe/.kexe
```

理解这张图是理解全章的钥匙。**K2 前端**负责解析源码、类型检查、
然后把程序降到统一的 **IR**（中间表示）；四个**后端**各自把 IR 做目标相关的
lowering 并生成代码。你的业务逻辑只被前端"理解"一次——这就是为什么后面会看到
`fib(90)` 的 Long 运算、`fnv1a` 的 UInt 位运算在四个目标上**结果逐字节一致**：
语义在前端定死，后端只负责忠实执行。JS 没有原生 64 位整数？
那是后端的问题，Kotlin/JS 后端用高/低两个 32 位数模拟 Long，
位运算靠校正保证不炸——你的源码一个字都不用改。

四个目标的定位与产物：

| 目标 | 编译器 | 产物 | 宿主 | 本机实测体积* |
|---|---|---|---|---|
| JVM | kotlinc（kotlinc-jvm） | .class + jar | JDK | （前 24 章） |
| JS | kotlinc-js | `probe.js` 单文件 | node / 浏览器 | 722 KB |
| Wasm (wasm-js) | kotlinc-wasm | `probe.wasm` + `.mjs` 胶水 | 支持 WasmGC 的 JS 引擎 | 1.10 MB |
| Wasm (wasm-wasi) | kotlinc-wasm | `probe.wasm` + `.mjs` | WASI 宿主（node 内置） | 1.09 MB |
| Native | konanc | `probe.exe` / `probe.kexe` 独立二进制 | 无（裸机） | 1.65 MB |

\* 同一示例（含全部断言）的 hello-world 级产物。Web 目标的体积大头是**全量 stdlib**——
纯 CLI 编译没有死代码消除（DCE），Gradle 的 JS/Wasm 构建才会裁剪，25.4 详述。
看到 722 KB 的 hello world 不要慌，那不是真实工程的体积。

**工具链清单**（示例的入口脚本按"环境变量 → 平台常见位置 → PATH"的顺序自动定位）：

- kotlinc-js / kotlinc-wasm：与 kotlinc 同一份发行版（Kotlin 2.4.21），
  Windows 在 `…\kotlin\current\bin\`，macOS 在 `/opt/local/share/java/kotlin/bin/`（无 `.bat` 后缀）。
- konanc：独立安装的 Kotlin/Native 编译器（同为 2.4.21）。
  **macOS 的 MacPorts 只有 kotlin（JVM/JS/Wasm）没有 kotlin-native**——
  探测不到 konanc 时脚本把 native 目标计为 `[SKIP]` 而不是失败。
- `lib/kotlin-stdlib-js.klib`、`kotlin-stdlib-wasm-js.klib`、`kotlin-stdlib-wasm-wasi.klib`：
  各目标的 stdlib，以 **klib** 格式发行（25.3.2 讲这个格式）。
- node：身兼三职——跑 JS 产物、用内置 WasmGC 支持跑 wasm-js 产物、
  用实验性 `node:wasi` 模块跑 wasm-wasi 产物。

## 25.2 共享代码精读：Common.kt 里有什么

在谈"怎么编"之前，先看"编的是什么"。`src/Common.kt` 是四个目标**共享的唯一源文件**，
它不含任何平台 API——这就是 KMP 里 "common 源集"的缩影。整章的快照输出
全部由这一个文件产生，值得逐段读完。

开头是两个 `expect` 声明——全章唯一的"平台差异点"：

```kotlin
expect fun platformName(): String      // 平台标识（进快照：字面常量，确定性）
expect fun platformProbe(): String     // 平台探针（不进快照：环境相关，只验证形状）
```

`expect` 的意思是"**声明一个契约：每个平台都必须提供这个函数的实现**"。
common 代码只看见签名，不知道、也不需要知道实现长什么样；
各平台目录里的 `actual` 函数负责填坑（25.6 讲机制，25.3~25.5 看四个实现）。
注意两个声明的分工注释：`platformName` 返回字面常量，确定无疑，**进快照**；
`platformProbe` 返回环境相关的探针值（node 版本、用户名），**不进快照**——
这个分工是快照跨机器成立的关键设计，25.9 展开。

往下是四个纯 Kotlin 算法，每个都暗中瞄准一个"跨平台容易出岔子"的点。

**算法一，矩阵乘法**——三重循环 + 二维数组，最朴素的数值代码：

```kotlin
/** 纯 Kotlin 算法一：矩阵乘法——三重循环 + 二维数组，任何目标都该算出同一结果。 */
fun matMul(a: Array<IntArray>, b: Array<IntArray>): Array<IntArray> {
    val n = a.size
    val m = b[0].size
    val k = b.size
    require(a[0].size == k) { "形状不合法：a 的列数 $k != b 的行数 ${a[0].size}" }
    val out = Array(n) { IntArray(m) }
    for (i in 0 until n) {
        for (j in 0 until m) {
            var acc = 0
            for (p in 0 until k) acc += a[i][p] * b[p][j]
            out[i][j] = acc
        }
    }
    return out
}
```

没有任何技巧，它就是用来回答一个朴素问题的：循环、数组下标、整数乘法，
**在四个后端上跑得一样吗**？答案写在快照里（25.9 逐行对账）。

**算法二，词频统计**——标准库行为的一致性探针：

```kotlin
/** 纯 Kotlin 算法二：词频统计——列表管道 + 分组计数，检验各目标标准库行为一致。 */
fun wordFreq(text: String): List<Pair<String, Int>> =
    text.lowercase().split(Regex("[^a-z0-9']+")).filter { it.isNotBlank() }
        .groupBy { it }.map { it.key to it.value.size }
        .sortedWith(compareByDescending<Pair<String, Int>> { it.second }.thenBy { it.first })
```

这一行管道压了六个标准库调用：`lowercase`、
[`Regex`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-regex/index.html)
切分、`filter`、
[`groupBy`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/group-by.html)、
`map`、双键排序（次数降序、单词升序）。它检验的是更深的东西：
**各目标的 stdlib 是不是同一个 stdlib**——正则语义、分组、排序稳定性，
任何目标上有一点出入，快照立刻见红。

**算法三，迭代斐波那契**——Long 语义的照妖镜：

```kotlin
/** 纯 Kotlin 算法三：迭代斐波那契——Long 溢出行为跨目标必须一致（JS 的 Long 是双 32 位拼的）。 */
fun fib(n: Int): Long {
    var a = 0L
    var b = 1L
    repeat(n) { val t = a + b; a = b; b = t }
    return a
}
```

注释点破了用意：JS 没有 64 位整数，Kotlin/JS 的 `Long` 是后端用两个 32 位数拼出来的。
`fib(90) = 2880067194370816120` 已经超过 2⁶¹——如果 JS 后端的 Long 模拟有半点不忠实，
这一行输出就是四个目标里唯一的异类。

**算法四，FNV-1a 哈希**——位运算与无符号数的一致性：

```kotlin
/** 纯 Kotlin 算法四：FNV-1a 哈希——位运算跨目标一致性（JS 目标会把 Int 运算截到 32 位）。 */
fun fnv1a(data: String): UInt {
    var h = 0x811c9dc5u
    for (c in data) {
        h = h xor c.code.toUInt()
        h = h * 0x01000193u
    }
    return h
}
```

FNV-1a 是经典的字符串哈希：从 offset basis `0x811c9dc5` 出发，
每个字符先 `xor` 再乘 FNV 质数 `0x01000193`。
[`UInt`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-u-int/index.html)
的乘法**故意依赖 32 位回绕**（乘到溢出是自然行为），这正好戳在 JS 的命门上——
JS 的 `number` 是双精度浮点，超过 2⁵³ 的整数乘法会丢精度，
Kotlin/JS 后端必须把 UInt 运算校正回 32 位语义。快照里 `fnv1a : 3289427`
（十六进制）在四个目标上相同，就是校正正确的证据。

最后是 `main` 与内嵌断言：

```kotlin
fun main() {
    println("== Kotlin Multiplatform Probe ==")
    println("platform : ${platformName()}")
    println("kotlin   : ${KotlinVersion.CURRENT}")

    // 共享算法：四目标必须逐字节一致的部分
    val a = arrayOf(intArrayOf(1, 2), intArrayOf(3, 4), intArrayOf(5, 6))
    val b = arrayOf(intArrayOf(7, 8, 9), intArrayOf(10, 11, 12))
    println("matMul   : ${matMul(a, b).joinToString("|") { it.joinToString(",") }}")

    val text = "the quick brown fox jumps over the lazy dog the end"
    println("wordFreq : " + wordFreq(text).take(4).joinToString(" ") { "${it.first}:${it.second}" })

    println("fib 90   : ${fib(90)}")
    println("fnv1a    : ${fnv1a("kotlin-multiplatform").toString(16)}")

    // 平台探针：环境相关（引擎版本/用户名），值不进快照——只断言非空，打印定性 ok
    val probe = platformProbe()
    check(probe.isNotBlank()) { "platformProbe 不能为空" }
    check(probe.length >= 8) { "探针值短得可疑：${probe.length} 字符" }
    println("probe    : ok (host-dependent, redacted)")

    // 自检断言 = 非 JVM 目标的"L2 测试层"：任何目标上失败都直接崩、exit != 0
    checkSelf()
    println("self-check: OK")
}

fun checkSelf() {
    check(matMul(a = arrayOf(intArrayOf(2, 0), intArrayOf(0, 2)), b = arrayOf(intArrayOf(1, 2), intArrayOf(3, 4)))
        .contentDeepEquals(arrayOf(intArrayOf(2, 4), intArrayOf(6, 8)))) { "matMul 单位阵乘法错" }
    check(wordFreq("a b a").first() == ("a" to 2)) { "wordFreq 排序错" }
    check(fib(10) == 55L) { "fib(10) 应为 55" }
    check(fib(90) == 2880067194370816120L) { "fib(90) Long 溢出前终值错——各目标必须一致" }
    check(fnv1a("") == 0x811c9dc5u) { "FNV offset basis 错" }
}
```

`main` 的三段结构值得学：**确定性结果直接打印**（进快照）、
**环境相关值只验形状再打印定性结论**（probe 两行
[`check`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/check.html)
挡住空值和可疑短值，输出统一为 `ok (host-dependent, redacted)`）、
**自检断言压阵**（`checkSelf` 五条 check，任何一条失败进程非零退出）。
[`KotlinVersion.CURRENT`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-kotlin-version/index.html)
是编译进二进制的 stdlib 版本号。

为什么断言要内嵌在 `main` 里？因为**非 JVM 目标没有 kotlin.test 的测试运行器**——
JVM 上习惯了"测试框架跑断言"，JS/Wasm/Native 的 CLI 产物里没有这套设施。
本章的替代方案就是 `check` 内嵌：断言失败抛异常、进程非零退出，
效果等价于测试红了。这是 25.9 验证链的第二层。

## 25.3 Kotlin/Native：编出独立二进制

### 25.3.1 konanc 实战

Native 后端不产字节码，而是走 **LLVM** 直接生成机器码。命令行编译器是 `konanc`：

```bash
# macOS / Linux（PowerShell 用 ` 换行）
konanc -Xmulti-platform -Xseparate-kmp-compilation -Xcommon-sources=src/Common.kt \
       -o build/native/probe  src/Common.kt native/Native.kt
# 产物：Windows 上自动加 .exe（probe.exe），macOS/Linux 上是 probe.kexe
```

`-o` 指定输出，两个源文件同命令行传入；开头三个 `-X` flag 是 expect/actual
在 CLI 下的"放行三件套"，25.6.2 专门讲。四条实测注意（入口脚本已全部防御）：

1. **必须 JDK 21**：konanc 的启动脚本在 JDK ≥ 24 下因
   `--enable-native-access=ALL-UNNAMED` 的引号解析直接崩（Windows 上 cmd 报
   "此时不应有 =ALL-UNNAMED"）。脚本全局钉 JDK 21，且**版本感知**：`JAVA_HOME`
   指向非 21 会被跳过，自动在已装的 LTS JDK 里找真 21
   （macOS 走 `/usr/libexec/java_home -v 21`）。这就是本教程全程钉 JDK 21 的原因。
2. **首次编译自动下载 LLVM**：konanc 首跑会从 JetBrains CDN 拉
   `llvm-21-*-essentials`（约 275 MB）到 `~/.konan/dependencies/`——
   首次编译慢是网络下载，不是编译本身。
3. **输出目录要先建**：konanc 不自建 `-o` 的父目录，目录不存在时**链接阶段**才报
   `cannot open output file`——编译几分钟才炸，很亏。
4. **macOS 上可能装不到 konanc**：MacPorts 没有 kotlin-native 包。
   脚本探测不到就跳过 native 目标（`[SKIP]` 而非失败）。

### 25.3.2 产物形态：可执行程序与 klib

Native 有两种产物（`-produce` 选择，默认 program）：

- **program**：`probe.exe` / `probe.kexe`——静态链接了 Kotlin 运行时的独立二进制，
  目标机器**不需要任何 VM**。启动是进程级的（毫秒内），没有 JVM 预热。
  本示例 1.65 MB 的 exe 里塞进了 stdlib 用到的全部内容。
- **library**：`probe.klib`——Kotlin 的库格式（一个 zip：IR + 元数据 +
  各目标 bitcode），供其他 Kotlin 编译消费。**klib 是 KMP 生态的流通货币**：
  JS/Wasm 目标的 stdlib 就是 `kotlin-stdlib-js.klib` 这种文件，
  多平台库发布的也是一组 klib。

默认编译目标是宿主平台（Windows 上 `mingw_x64`、macOS 上 `macosx_x64`、
Linux 上 `linux_x64`）。交叉编译到其他目标要 `-target linux_x64` 之类——
但链接需要目标平台的 sysroot 和工具链，教学环境直接编宿主目标。

> 正因为宿主三元组会变，**示例的 `platformName()` 只返回目标族
> `"native (kotlin-native)"`**，三元组信息留给不进快照的 `platformProbe()`。
> 写死 `"native (mingw_x64)"` 之类的值，换台机器编译就是一句假话，
> 而且快照在两个平台上不可能同时成立。

### 25.3.3 与 C 互操作：platform.posix 一瞥

Kotlin/Native 的高杠杆能力是**直接调 C**。发行版自带常见平台库的绑定
（`platform.posix`、`platform.windows` 等）。示例的 native actual 全文
（`native/Native.kt`）：

```kotlin
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.toKString
import platform.posix.getenv

actual fun platformName(): String = "native (kotlin-native)"

@OptIn(ExperimentalForeignApi::class)   // C 互操作 API 全家都要 opt-in
actual fun platformProbe(): String {
    // Windows 上是 USERNAME，Unix 上是 USER —— 两个都问，避免换平台拿到 "absent"
    val user = getenv("USER")?.toKString() ?: getenv("USERNAME")?.toKString() ?: "absent"
    return "kotlin-native user=$user"     // 固定前缀保证长度：Common.kt 断言 ≥8 字符
}
```

逐行看三个细节：

- `getenv` 就是 C 标准库的那个 `getenv`，返回类型映射为 `CPointer<ByteVar>?`——
  C 的 `char*` 变成 Kotlin 指针类型，而且**可空**（环境变量可能不存在），
  空安全直接照常吃。
- `?.toKString()` 把 C 字符串转成 Kotlin `String`。它是 `kotlinx.cinterop` 里的
  **扩展函数**（不是成员），所以要显式 `import kotlinx.cinterop.toKString`。
- 整个 `kotlinx.cinterop` 标了 `@ExperimentalForeignApi`——C 互操作 API 全家桶
  都是实验性，**不 `@OptIn` 就编不过**。这是 Kotlin 的实验 API 管理制度：
  能用，但你得签字画押表示知道它可能变。

`getenv("USER") ?: getenv("USERNAME")` 的双重询问是真实的跨平台知识：
Unix 系的用户名环境变量是 `USER`，Windows 是 `USERNAME`。
自己的 C 库可以用 `cinterop` 工具从 `.h` 头文件生成绑定（def 文件描述头文件路径），
那是 25.7 之外的进阶话题。

### 25.3.4 GC 与内存模型（知道即可）

- **GC**：自 1.7.20 起默认是新的内存管理器，摆脱了旧的严格冻结（frozen）模型；
  对象默认可在线程间共享，不再要求 freeze。
- **与 JVM 的差异**：没有 JIT——优化靠 LLVM 在编译期做（`-opt` 开优化）。
  性能特征因此不同：启动即巅峰，没有预热爬坡，但峰值优化空间也不如 JIT。

## 25.4 Kotlin/JS：编进 JavaScript 世界

### 25.4.1 两步编译（CLI 实测心法）

kotlinc-js 的 K2 命令行把"编译"和"链接"拆成**两步**——这是与 kotlinc-jvm
使用上最大的差异，也是 CLI 路线最容易迷路的地方：

```bash
# macOS / Linux（Windows 把 $klib 换成 …\kotlin\current\lib\kotlin-stdlib-js.klib）
klib=/opt/local/share/java/kotlin/lib/kotlin-stdlib-js.klib
# 第一步：编译成 klib（IR 的 zip 包）
kotlinc-js -libraries $klib -Xmulti-platform -Xseparate-kmp-compilation \
    -Xcommon-sources=src/Common.kt -Xir-module-name=probe \
    -ir-output-name=probe -ir-output-dir=build/js  src/Common.kt js/Js.kt
# 第二步：链接成可执行 JS（-Xinclude 指向上一步的 klib，必须绝对路径）
kotlinc-js -libraries $klib -Xmulti-platform -Xseparate-kmp-compilation \
    -Xcommon-sources=src/Common.kt -Xir-produce-js \
    -Xinclude=/abs/path/build/js/probe.klib -Xir-module-name=probe \
    -ir-output-name=probe -ir-output-dir=build/js  src/Common.kt js/Js.kt
node build/js/probe.js
```

第一步把源码编成 `probe.klib`（IR 包），第二步用 `-Xir-produce-js` +
`-Xinclude=<上一步的 klib>` 链接出可执行 `probe.js`。四条实测坑（都能绕）：

1. **第二步 exit code = 1 但产物正确**：链接完成后 zip 文件系统 dispose 阶段抛
   `NoSuchFileException`——**假阳性**，Windows 和 macOS 都复现。
   判定成功要看"产物存在 + node 跑得动"，不能看退出码。
2. **"obsolete form" 警告是假警报**：明明已经用 `-Xir-module-name=probe` 的 `=`
   写法，仍警告让你改用 `=` 写法。白名单放行，别追。
3. **`-Xinclude` 要绝对路径**：相对路径直接 `No module found`。斜杠方向无所谓。
4. **别用"删光产物目录再检查产物存在"做验证**：批量删除可能被环境策略静默拦下
   （不报错也没删），旧产物残留让判定变假阳性。只删本次要重新生成的那几个文件。

### 25.4.2 产物与 DCE

`probe.js` 是**单文件自包含**：整段 stdlib（polyfill + 运行时 + 你的代码）全在里面，
722 KB——hello world 也是这个量级。文件末尾有 `mainWrapper()` 调用，即程序入口。

真实工程不会这么大：Gradle 的 Kotlin/JS 构建做 **DCE**（死代码消除），
把没用到的 stdlib 挖掉，还有生成代码级优化。纯 CLI 没有这条流水线——
这是"CLI 教学 vs Gradle 工程"的实打实差距，体积对比时必须注明是 CLI 产物。
`-module-kind`（plain/amd/commonjs/umd/es）决定模块封装方式，
CLI 默认 plain，浏览器 `<script>` 标签可直接加载。

### 25.4.3 JS 互操作：external 与 dynamic

Kotlin/JS 调 JavaScript 世界的东西，靠 `external` 声明。示例的 js actual 全文
（`js/Js.kt`）：

```kotlin
private external val process: dynamic

actual fun platformName(): String = "js (node)"

actual fun platformProbe(): String = "node ${process.version}"
```

三行说尽三个概念：

- `external` 告诉编译器："这个声明在 Kotlin 侧没有实现，它存在于外部（JS）世界"——
  编译器不为它生成代码，访问时直接映射到 JS 同名全局对象。
  `process` 就是 node 的那个全局 `process`。
- `dynamic` 是 JS 目标特有的类型：**关掉静态类型检查**，成员访问全部推迟到
  运行时决议。`process.version` 编不过类型检查也能编——爽和险都来自这里：
  打错成 `process.versoin` 编译器不管，运行时才拿到 undefined。
- 浏览器宿主**没有** `process`——同一段代码在浏览器里会炸。
  但这恰恰是设计意图：**宿主差异被 actual 吸收**，`js/` 目录的 actual 只会被
  js 目标编译，browser 目标可以有自己的 actual。common 代码对此一无所知。

反方向（JS 调 Kotlin）用 `@JsExport`/`@JsName` 标注，配 `-Xgenerate-dts`
还能产 TypeScript 声明文件——Kotlin 写库、TS 项目消费的路径是通的。

## 25.5 Kotlin/Wasm：WasmGC 时代的新后端

### 25.5.1 为什么要有 Wasm 后端

Kotlin/JS 有一组绕不开的根本痛点：JS 没有 64 位整数、没有真正的类和继承、
对象模型不同——全靠后端模拟（Long 拆双 32 位、类降级成原型链加函数）。
**WasmGC**（WebAssembly 垃圾回收提案）改变了局面：WASM 模块可以直接使用
宿主的 GC 对象，Kotlin 的类、Long、继承体系**原样映射**到 WasmGC 的结构类型，
不再需要 JS 层的模拟。带来的实际好处：启动比 JS 后端快（少了 JS 层装配）、
数值代码不再为模拟付税。代价是需要支持 WasmGC 的运行时——浏览器要较新版本，
node 22+ 原生支持。

### 25.5.2 两个目标：wasm-js 与 wasm-wasi

kotlinc-wasm 用 `-Xwasm-target` 选择宿主模型。**同一段 Kotlin 代码**，
两个目标各配各的 stdlib klib：

| | wasm-js | wasm-wasi |
|---|---|---|
| 面向 | 浏览器/node 的 JS 引擎 | 非浏览器宿主（CLI/服务器/嵌入式） |
| 系统接口 | 走 JS 胶水（import-object.mjs） | WASI 预览版（文件/时钟/环境变量） |
| 产物 | .wasm + .mjs + js-builtins.mjs + import-object.mjs | .wasm + .mjs（更薄） |
| 本机运行 | `node probe.mjs` | `node probe.mjs`（node:wasi 实验模块） |

编译命令与 kotlinc-js 同款两步（第一步 klib、第二步 `-Xir-produce-js` 链接）：

```bash
# macOS / Linux（Windows：…\kotlin\current\lib\kotlin-stdlib-wasm-wasi.klib）
klib=/opt/local/share/java/kotlin/lib/kotlin-stdlib-wasm-wasi.klib
kotlinc-wasm -libraries $klib -Xwasm-target=wasm-wasi -Xmulti-platform \
    -Xseparate-kmp-compilation -Xcommon-sources=src/Common.kt \
    -Xir-module-name=probe -ir-output-name=probe -ir-output-dir=build/wasi \
    src/Common.kt wasi/WasmWasi.kt          # 第一步 klib
kotlinc-wasm ... -Xir-produce-js -Xinclude=<绝对路径>/build/wasi/probe.klib ...   # 第二步链接
node build/wasi/probe.mjs                    # node:wasi 是实验模块，打 ExperimentalWarning 无害
```

示例里两个 wasm 目标的 actual 都是**纯 Kotlin 常量**——这是刻意的教学决策。
`wasmjs/WasmJs.kt`：

```kotlin
actual fun platformName(): String = "wasm-js (WasmGC)"

actual fun platformProbe(): String = "wasm-js target, JS host present"
```

`wasi/WasmWasi.kt`：

```kotlin
actual fun platformName(): String = "wasm-wasi (WasmGC)"

actual fun platformProbe(): String = "wasi target, no JS host"
```

为什么不演示 wasm 的 JS 互操作？因为 wasm-js 的互操作语法与 Kotlin/JS **不同**
（external 声明映射到 import-object，没有 `js("...")` 内联）——把它掺进来，
一章要同时讲两套互操作模型，得不偿失。保持无互操作还有个副产品：
两个 wasm 目标的输出完全确定，快照干净。

### 25.5.3 现状定位

Wasm 后端已可用于真实项目（kotlinx 系列库大量已支持），但生态位仍在演进：
浏览器侧与 JS 后端并存（WasmGC 兼容性达标后 Wasm 是未来方向）；
服务器侧 wasi 是"宿主中立的 Kotlin 运行时"想象的载体。选型见 25.8。

## 25.6 expect/actual：跨平台 API 的声明与实现

### 25.6.1 机制

KMP 的核心机制就一对修饰符。声明在 common（`src/Common.kt`）：

```kotlin
expect fun platformName(): String
```

四个平台目录里各有一份实现，签名严格对应。比如 js 的：

```kotlin
actual fun platformName(): String = "js (node)"             // js/Js.kt
```

和 native 的：

```kotlin
actual fun platformName(): String = "native (kotlin-native)" // native/Native.kt
```

规则要点：

1. **expect 是契约，actual 是履约**——common 代码调用 expect 声明，
  编到哪个目标，调用就接到哪个 actual 上。
2. **签名必须严格匹配**：参数类型、返回类型、可空性、默认参数值都不能差，
   不匹配是硬错误。
3. expect/actual 不限于函数：类、属性、对象、typealias、注解都可以
  （类的 expect/actual 在 2.x 仍是 Beta，编译会有提示）。
4. **同一模块里 expect 配 actual 是错误**（"declared in the same module"）——
   所以 common 源和平台源必须分属不同的"编译单元"，这就是下一条 flag 存在的原因。
5. **actual 的返回值别写宿主相关的东西**（Windows-only 常量、环境变量、
   拼出来的路径）：快照只有一份，写进去就变成"只在作者这台机器上成立"。
   宿主相关信息交给不进快照的 probe——`platformName` 与 `platformProbe`
   的分工就是这条规则的落地。

### 25.6.2 CLI 放行三件套（本章最大的实测发现）

JVM 的 kotlinc 有个正大光明的 `-Xmulti-platform`；但 **kotlinc-js/kotlinc-wasm
的 `-X` 帮助列表里根本没有它**（隐藏 flag，传了才生效）。而"common 源单独出现、
expect 无 actual 可见"在 K2 里默认是硬错误——`-Xno-check-actual` 压不住，
老的 `-Xexpect-actual-holders` 已移除。实测能走通的组合是三个 flag 同时上：

| flag | 作用 | 缺了会怎样 |
|---|---|---|
| `-Xmulti-platform` | 打开语言层面的 expect/actual 支持（web CLI 隐藏 flag） | "can be used only in multiplatform projects" |
| `-Xseparate-kmp-compilation` | 启用分离式 KMP 编译方案（common 源集按自身依赖分析） | expect 无 actual 报错，klib 编不出来 |
| `-Xcommon-sources=<common 源>` | 标记哪些源属于 common 模块（与平台源同命令行传入） | expect/actual 被当成同模块，报 "same module" |

这套组合让**单条命令**完成"common + 平台 actual + 链接"——比 Gradle 的
多源集流水线粗暴，但正适合教学透视：每个 flag 负责什么一目了然。
konanc 认同样的三件套（`-Xmulti-platform` 在它的帮助里是明示的），
所以四个目标能用**完全一致的心法**编译。真实工程请直接上 Gradle（25.7）。

### 25.6.3 Gradle 里的形态（对照）

Gradle 的 kotlin-multiplatform 插件把上面全部自动化：
commonMain 编成带元数据的 klib → 各平台源集编成平台 klib → 链接成各目标产物。
你永远不需要手敲那三个 flag——这正是 CLI 透视教学的价值：
**知道插件在替你做什么**，插件出怪问题时才不至于束手无策。

## 25.7 KMP 与 Gradle：真实工程的样子

真实多平台工程的骨架（17 章 Gradle 知识的直接延伸）：

```text
shared/
├── build.gradle.kts        kotlin { wasmJs(); mingwX64("native"); js(nodejs) ... }
├── src/
│   ├── commonMain/kotlin/  ← 本章的 src/（expect 在这）
│   ├── jsMain/kotlin/      ← 本章的 js/（js actual）
│   ├── wasmJsMain/kotlin/  ← 本章的 wasmjs/
│   ├── nativeMain/kotlin/  ← 可选：所有 native 目标共享的中间层
│   └── mingwX64Main/kotlin/← 本章的 native/（平台叶子 actual）
```

要点速览（细节是下一本书的事）：

- **源集层级**：commonMain → 中间层（nativeMain 等）→ 平台叶子（mingwX64Main），
  下游看得见上游的 expect；
- **依赖按源集配置**：`commonMain.dependencies { implementation("…:kotlinx-serialization-json:…") }`——
  库必须提供对应目标的构件（klib），JVM-only 的 jar 塞不进 commonMain；
- **applyDefaultHierarchyTemplate**：2.x 默认模板自动搭中间层，不用手写 `dependsOn`；
- **Compose Multiplatform**：UI 层也能共享（Android/iOS/Desktop/Web）——
  KMP 生态最大的应用场景；
- **版本对齐**：kotlin-multiplatform 插件版本与 Kotlin 版本一致（2.4.21），
  stdlib 不用显式声明。

CLI 路线的边界要说清楚：CLI 适合理解机制、单文件演示、CI 里的轻量探测；
**多模块、依赖解析、DCE、增量编译、测试分发**都是 Gradle 的领地——
本章示例的入口脚本手工编排四目标编译，正是 Gradle 插件自动化的那部分。

## 25.8 目标选型：什么场景选什么

| 你的诉求 | 选 | 理由 |
|---|---|---|
| 服务端/Android/桌面（JVM 系） | JVM | 生态最深，前 24 章全部适用 |
| 前端 Web，渐进增强 | JS | 与 npm 生态零摩擦，DCE 后体积可控 |
| 前端 Web，重计算/要类型保真 | Wasm (wasm-js) | WasmGC 原生类与 Long，启动快 |
| 边缘/嵌入式/CLI 工具，无 VM | Native | 独立二进制，启动毫秒级 |
| 插件沙箱/跨运行时分发 | Wasm (wasm-wasi) | WASI 接口面窄，宿主中立 |
| 一套核心逻辑多端复用 | KMP（common + 多目标） | expect/actual 切平台差异 |

经验法则：**先写 common，写不下去的地方才是平台差异**。
expect 的数量是设计质量的反向指标——每加一个 expect，
先问能不能用接口/依赖注入代替（单目标场景往往根本不需要 expect）。

## 25.9 验证链与四份快照

非 JVM 目标的验证链与 JVM 章节的四层结构略有不同，是三层：

1. **编译**：`-Werror`（真警告即失败；web CLI 的 "obsolete form" 假警报白名单放行）；
2. **运行**：node / probe.exe 运行 exit 0——**断言内嵌在 main 里**（`checkSelf()` +
   各处 `check`），非 JVM 目标没有 kotlin.test runner，
   断言失败 = 进程非零退出，这就是它们的"L2 测试层"；
3. **快照**：`expected-js.txt` / `expected-wasmjs.txt` / `expected-wasi.txt` /
   `expected-native.txt` 四份 golden。

逐字引用 `expected-js.txt`（九行）：

```text
== Kotlin Multiplatform Probe ==
platform : js (node)
kotlin   : 2.4
matMul   : 27,30,33|61,68,75|95,106,117
wordFreq : the:3 brown:1 dog:1 end:1
fib 90   : 2880067194370816120
fnv1a    : 3289427
probe    : ok (host-dependent, redacted)
self-check: OK
```

第 3 行的版本号只打 **major.minor**（`KotlinVersion.CURRENT.major.minor`）——这是快照确定性设计的一条实测教训：早先版本这里打全版本号（`2.4.20`），工具链一次 patch 升级（2.4.20 → 2.4.21）就让四份快照同时翻红，而算法行为毫无变化。**不稳定信息要么消灭，要么降维成稳定断言**：整条 2.4.x 线上这一行恒为 `2.4`，跨 patch 升级零维护。`KotlinVersion` 本身在 [kotlin 包](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-kotlin-version/index.html)里，`isAtLeast(major, minor)` 是做版本门控的正规 API。

> `expected-native.txt` 的第 3 行同步为 `2.4`：本机没有 konanc（MacPorts 无 kotlin-native 包），该快照生成于 Windows 上的 konanc 2.4.x——程序改为只打 major.minor 后，任何 2.4.x 原生编译器的输出都逐字相同，这条是**按构造可推导**的，其余八行与 JS 快照逐一比对过一致。

逐行对账（每行都能指回 25.2 的代码）：

- `platform : js (node)`——四份快照**唯一**不同的一行：wasmjs 是
  `wasm-js (WasmGC)`、wasi 是 `wasm-wasi (WasmGC)`、native 是
  `native (kotlin-native)`。其余八行四目标**逐字节一致**。
- `matMul : 27,30,33|61,68,75|95,106,117`——3×2 乘 2×3 得 3×3：
  第一行 `1×7+2×10=27, 1×8+2×11=30, 1×9+2×12=33`，后两行同理。
  循环与数组语义四目标一致。
- `wordFreq : the:3 brown:1 dog:1 end:1`——`the` 出现 3 次居首，
  其余各 1 次按字母序取前三。标准库管道行为四目标一致。
- `fib 90 : 2880067194370816120`——超过 2⁶¹ 的 Long 值，
  JS 后端的双 32 位模拟忠实无差。
- `fnv1a : 3289427`——依赖 32 位回绕的无符号乘法，十六进制输出四目标一致。
- `probe : ok (host-dependent, redacted)`——探针值被断言过形状后**打码**，
  不进快照。
- `self-check: OK`——五条内嵌断言全部通过。

**八行一致 + 一行不同**，这份 diff 就是 KMP 的一句话总结：
算法与逻辑一份代码四处复用，平台差异被压缩到 actual 里的一行字符串。

快照确定性的设计纪律（21 章的多平台版）：探针值（node 版本、用户名）不进快照——
common 里只断言形状（非空、长度 ≥ 8），输出统一打码。
否则换台机器、升级一次 node，快照就无辜变红。

## 25.10 坑位清单（全部实测）

1. **konanc + JDK ≥ 24 直接崩**：启动脚本的 `--enable-native-access=ALL-UNNAMED`
   引号解析 bug（"此时不应有 =ALL-UNNAMED"）。钉死 JDK 21。
2. **web 链接步 exit code = 1 但成功**：zip-fs dispose 的假阳性——
   判定看产物与运行，别看退出码。
3. **"obsolete form" 警告假警报**：`=` 写法也报，无法消除，白名单处理。
4. **`-Xinclude` 必须绝对路径**：相对路径 `No module found`；斜杠正反都行。
5. **kotlinc-js/wasm 无 DCE**：hello world 级 722 KB / 1.1 MB，全量 stdlib 打包——
   体积对比要注明"CLI 产物"。
6. **expect 无 actual 是硬错误**：`-Xno-check-actual` 和已移除的
   `-Xexpect-actual-holders` 都压不住——必须 `-Xmulti-platform` +
   `-Xseparate-kmp-compilation` + `-Xcommon-sources` 三件套（25.6.2）。
7. **`-Xmulti-platform` 在 web CLI 是隐藏 flag**：帮助里不列，传了才生效——
   文档找不到别慌，不是你眼花。
8. **同模块 expect/actual 报错**：common 源不标 `-Xcommon-sources` 就和平台源
   同模块，报 "same module"。
9. **konanc 不建输出目录**：`-o` 的父目录要先建好，否则链接期才报
   `cannot open output file`。
10. **kotlinx.cinterop 全是实验 API**：`getenv`/`toKString` 都要
    `@OptIn(ExperimentalForeignApi::class)`，且 `toKString` 要显式 import
    （它是扩展函数不是成员）。
11. **wasi 走 node 会打 ExperimentalWarning**：node:wasi 还是实验模块，
    快照比对前要过滤掉这行 stderr 噪音。
12. **WasmGC 要新运行时**：node 22+ 原生支持；老浏览器/老 node 跑不了
    wasm-js/wasi 目标产物。
13. **PATH 上的 java 可能不是 21**（老坑新位置）：konanc 用 `JAVA_HOME`，
    手动跑命令时别忘了钉版本。

---

上一章：[24 ⭐实战：ktodo](24-todo.md) · 下一章：[26 数值与数组](26-numbers-arrays.md)
