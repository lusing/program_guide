# 25 · 多平台：JS、Native 与 Wasm ⭐

> 对应示例：`examples/25_multiplatform/`（同一份 common 代码 + expect/actual 编到 **4 个目标**：js / wasm-js / wasm-wasi / native——四个快照里只有 platform 一行不同）
>
> 前 24 章的 Kotlin 都活在 JVM 上。本章把同一份代码编进浏览器、node、独立二进制和 WebAssembly，
> 讲清四个目标的编译管线、互操作方式和"共享多少、各写多少"的工程经济学。
> 所有命令在本机 **kotlinc-js/kotlinc-wasm 2.4.20 + konanc 2.4.20 + JDK 21 + node 26** 实测。

## 25.1 全景：一份语言，四个后端

Kotlin 的口号是"一门语言，多平台复用"。落到编译器上是**一条前端，四个后端**：

```
                    ┌─ JVM 后端   → .class / .jar（前 24 章）
Kotlin 源码 → K2 前端 │
 (解析/类型检查/IR) ├─ JS 后端    → .js（IR 经 DCE/转译）
                    ├─ Wasm 后端  → .wasm + .mjs 胶水（WasmGC）
                    └─ Native 后端 → LLVM → 机器码 .exe/.klib
```

前端把源码降到统一的 **IR**（中间表示），后端各自做 lowering 和代码生成。这就是为什么
`fib(90)` 的 Long 运算、`fnv1a` 的 UInt 位运算在四个目标上**逐字节一致**——语义在前端定死，
后端只负责忠实执行（JS 没有原生 64 位整数，Kotlin/JS 用高/低双 32 位模拟；位运算靠校正保证不炸）。

四个目标的定位与产物：

| 目标 | 编译器 | 产物 | 宿主 | 本机实测体积* |
|---|---|---|---|---|
| JVM | kotlinc-jvm | .class + jar | JDK | （前 24 章） |
| JS | kotlinc-js | `probe.js` 单文件 | node / 浏览器 | 722 KB |
| Wasm (wasm-js) | kotlinc-wasm | `probe.wasm` + `.mjs` 胶水 | 支持 WasmGC 的 JS 引擎 | 1.10 MB |
| Wasm (wasm-wasi) | kotlinc-wasm | `probe.wasm` + `.mjs` | WASI 宿主（node 内置） | 1.09 MB |
| Native | konanc | `probe.exe` 独立二进制 | 无（裸机） | 1.65 MB |

\* 同一示例（含全部断言）的 hello-world 级产物。Web 目标的体积大头是**全量 stdlib**——CLI 编译没有死代码消除（DCE），Gradle 的 JS/Wasm 构建才会裁剪，25.3 详述。

**工具链清单**（两个入口脚本自动定位：环境变量 → 平台常见位置 → PATH）：

- kotlinc-js / kotlinc-wasm：与 kotlinc-jvm 同装。Windows `G:\scoop\apps\kotlin\current\bin\`；macOS `/opt/local/share/java/kotlin/bin/`（无 `.bat` 后缀）
- konanc：独立安装的 Native 编译器。Windows `G:\scoop\apps\kotlin-native\current\bin\konanc.bat`；**macOS 本机没有**（MacPorts 无此包）→ 脚本把 native 目标计为 `[SKIP]`，**本章 native 分支未在 macOS 实测**
- `lib/kotlin-stdlib-js.klib`、`kotlin-stdlib-wasm-js.klib`、`kotlin-stdlib-wasm-wasi.klib`：各目标的 stdlib（klib 格式，25.2 讲）
- node：JS 运行 + WasmGC 原生支持 + WASI 实验支持（Windows 本机 26，macOS 本机 22，都够用）

## 25.2 Kotlin/Native：编出独立二进制

### 25.2.1 konanc 实战

Native 不产字节码，走 **LLVM** 直接生成机器码。命令行编译器是 `konanc`：

```bash
# macOS / Linux（PowerShell 用 ` 换行，shell 用 \）
konanc -Xmulti-platform -Xseparate-kmp-compilation -Xcommon-sources=src/Common.kt \
       -o build/native/probe  src/Common.kt native/Native.kt
# 产物：Windows 上自动加 .exe（probe.exe），macOS/Linux 上是 probe.kexe
```

四条实测注意（两个入口脚本都已防御）：

1. **必须 JDK 21**：Windows 的 `run_konan.bat` 在 JDK ≥ 24 下因 `--enable-native-access=ALL-UNNAMED` 的引号解析直接崩（cmd 报"此时不应有 =ALL-UNNAMED"）。脚本全局钉 JDK 21——**版本感知**：`JAVA_HOME` 指向非 21（如 scoop openjdk 27）会被跳过，自动改用 oraclejdk-lts/microsoft-jdk 里的真 21（macOS 走 `/usr/libexec/java_home -v 21`）。
2. **首次编译自动下载 LLVM**：konanc 首跑会从 JetBrains CDN 拉 `llvm-21-*-essentials`（约 275 MB）到 `~/.konan/dependencies/`——只要 CDN 通，一次到位。
3. **输出目录要先建**：konanc 不自建 `-o` 的父目录，目录不存在时链接阶段才报 `cannot open output file`。
4. **macOS 上没有 konanc**：MacPorts 只有 `kotlin`（JVM/JS/Wasm），没有 `kotlin-native`。脚本探测不到就跳过 native 目标（`[SKIP]` 而非失败），本章 native 分支的**实测记录目前只来自 Windows**。

### 25.2.2 产物形态：exe 与 klib

Native 有两种产物（`-produce` 参数选择，默认 program）：

- **program**：`probe.exe` / `probe.kexe`——静态链接 Kotlin 运行时的独立二进制，目标机器**不需要任何 VM**。启动是进程级的（毫秒内），没有 JVM 预热。（后缀随宿主：Windows `.exe`，macOS/Linux `.kexe`，两个入口脚本都按后缀探测。）
- **library**：`probe.klib`——Kotlin 的库格式（一个 zip：IR + 元数据 + 各目标 bitcode），供其他 Kotlin/Native 编译消费，是 KMP 生态的流通货币。stdlib 本身就是 klib（`lib/kotlin-stdlib-*.klib`）。

默认目标是宿主平台（Windows 上是 `mingw_x64`，macOS 上是 `macosx_x64`，Linux 上是 `linux_x64`）。交叉编译到其他目标需 `-target linux_x64` 等——但**链接需要目标平台的 sysroot**，纯 Windows 宿主交叉编 Linux 二进制要额外准备工具链，教学环境直接编宿主目标。

> 正因为宿主三元组会变，**示例的 `platformName()` 只返回目标族 `"native (kotlin-native)"`**，把三元组信息留给 `platformProbe()`（不进快照）。旧版写死 `"native (mingw_x64)"` 在 macOS 上就是一句假话，而且快照在两个平台上不可能同时成立。

### 25.2.3 与 C 互操作：platform.posix 一瞥

Kotlin/Native 的高杠杆能力是**直接调 C**。发行版自带常见平台库的绑定（`platform.posix`、`platform.windows` 等），示例的探针就是这么写的：

```kotlin
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.toKString
import platform.posix.getenv

@OptIn(ExperimentalForeignApi::class)          // C 互操作 API 全家桶都是实验性——必须显式 opt-in
actual fun platformProbe(): String {
    // Windows 上是 USERNAME，Unix 上是 USER —— 两个都问，换平台才不会拿到 "absent"
    val user = getenv("USER")?.toKString() ?: getenv("USERNAME")?.toKString() ?: "absent"
    return "kotlin-native user=$user"
}
```

三个细节：

- `getenv` 返回 `CPointer<ByteVar>?`——C 的 `char*` 映射成指针类型，**可空**（环境变量可能不存在）；
- `toKString()` 是 `kotlinx.cinterop` 的扩展函数，把 C 字符串转 Kotlin `String`（要显式 import，不是成员）；
- 整个 `kotlinx.cinterop` 标了 `@ExperimentalForeignApi`，不 opt-in 编不过。

自己的 C 库用 `cinterop` 工具从 `.h` 生成绑定（def 文件描述头文件路径），25.6 之外的进阶话题。

### 25.2.4 GC 与内存模型（知道即可）

- **GC**：默认垃圾回收器自 1.7.20 起是新的内存管理器（new MM），摆脱了旧的严格冻结（frozen）模型；对象默认可共享，跨线程传引用不再要求 freeze。
- **与 JVM 的差异**：对象内存布局由 Native 运行时自管，没有 JIT——优化靠 LLVM 编译期（`-opt` 开优化，默认 release 关调试信息）。本示例 1.65 MB 的 exe 里塞了 stdlib 用到的全部内容。

## 25.3 Kotlin/JS：编进 JavaScript 世界

### 25.3.1 两步编译（CLI 实测心法）

kotlinc-js 的 K2 命令行把"编译"和"链接"拆成两步——这是与 kotlinc-jvm 最大的使用差异：

```bash
# macOS / Linux（Windows 把 $klib 换成 G:\scoop\apps\kotlin\current\lib\kotlin-stdlib-js.klib）
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

四条实测坑（都有点离谱，但都能绕）：

1. **第二步 exit code = 1 但产物正确**：链接完成后 zip 文件系统 dispose 阶段抛 `NoSuchFileException`（它把刚生成的 klib 删了又想去关它）——**假阳性**。判定成功要看产物存在 + node 跑得动，不能看退出码。（Windows、macOS 上都复现。）
2. **"obsolete form" 警告是假警报**：明明用 `-Xir-module-name=probe` 的 `=` 写法，仍警告让你改用 `=` 写法。白名单放行，别追。
3. **`-Xinclude` 要绝对路径**且斜杠方向无所谓，但相对路径直接 `No module found`。
4. **别 `rm -rf` 产物目录再判定"产物存在"**：一个目标 50+ 文件，批量删除可能被环境策略静默拦下（不报错也没删），旧产物残留会让这条判定变成假阳性。脚本改成只删本次要重新生成的那几个产物文件。

### 25.3.2 产物与 DCE

`probe.js` 是**单文件自包含**：整段 stdlib（polyfill + 运行时 + 你的代码）全进去——722 KB，hello world 也是这个量级。`tail` 看文件末尾有 `mainWrapper()` 调用，即程序入口。

Gradle 的 Kotlin/JS 构建会做 **DCE**（死代码消除）把没用的 stdlib 挖掉，还有 `--withCompilerArgs` 级别的优化（`-Xoptimize-generated-js`）；纯 CLI 没有这条流水线，这是 CLI 教学 vs Gradle 工程的实打实差距。`-module-kind`（plain/amd/commonjs/umd/es）决定模块封装方式，CLI 默认 plain——浏览器 `<script>` 可直接吃。

### 25.3.3 js() 互操作：external 声明

Kotlin/JS 调 JS 靠 `external`（声明在外部实现）+ `js("...")`（内联 JS 表达式）：

```kotlin
private external val process: dynamic      // node 全局对象；类型 dynamic = 不检查

actual fun platformProbe(): String = "node ${process.version}"   // 真的调到了 node 的 process.version
```

- `external` 告诉编译器"这东西在 JS 世界，别找 Kotlin 实现"；
- `dynamic` 关掉类型检查，成员访问全部运行时决议——爽和险都来自这里；
- 浏览器宿主没有 `process`，同一段代码会炸——**宿主差异被 actual 吸收**正是 KMP 的设计意图（js 目录的 actual 只该被 js 目标编译）；
- 反方向（JS 调 Kotlin）用 `@JsExport`/`@JsName`，配 `-Xgenerate-dts` 还能产 TypeScript 声明。

## 25.4 Kotlin/Wasm：WasmGC 时代的新后端

### 25.4.1 为什么要有 Wasm 后端

Kotlin/JS 的根本痛点：JS 没有 64 位整数、没有真正的类和继承、GC 语义不同——全靠模拟（Long 拆双 32 位、类降级成原型链+函数）。**WasmGC**（WebAssembly Garbage Collection 提案）让 WASM 模块直接用宿主的 GC 对象，Kotlin 的类/Long/继承可以**原样映射**：

- 启动比 JS 后端快（少了 JS 层的装配），体积/吞吐在持续改进；
- 需要 WasmGC 的运行时：浏览器要较新版本，node 22+ 原生支持（本机 node 26 实测直接跑）。

### 25.4.2 两个目标：wasm-js 与 wasm-wasi

kotlinc-wasm 用 `-Xwasm-target` 选宿主模型，**同一段代码、不同的 stdlib klib**：

| | wasm-js | wasm-wasi |
|---|---|---|
| 面向 | 浏览器/node 的 JS 引擎 | 非浏览器宿主（CLI/服务器/嵌入式） |
| 系统接口 | 走 JS 胶水（.import-object.mjs） | WASI 预览版（文件/时钟/环境变量） |
| 产物 | .wasm + .mjs + js-builtins.mjs + import-object.mjs | .wasm + .mjs（更薄） |
| 本机运行 | `node probe.mjs` | `node probe.mjs`（node:wasi 实验模块，打 ExperimentalWarning） |

```bash
# macOS / Linux（Windows：G:\scoop\apps\kotlin\current\lib\kotlin-stdlib-wasm-wasi.klib）
klib=/opt/local/share/java/kotlin/lib/kotlin-stdlib-wasm-wasi.klib
kotlinc-wasm -libraries $klib -Xwasm-target=wasm-wasi -Xmulti-platform \
    -Xseparate-kmp-compilation -Xcommon-sources=src/Common.kt \
    -Xir-module-name=probe -ir-output-name=probe -ir-output-dir=build/wasi \
    src/Common.kt wasi/WasmWasi.kt          # 第一步 klib
kotlinc-wasm ... -Xir-produce-js -Xinclude=<绝对路径>/build/wasi/probe.klib ...   # 第二步链接
node build/wasi/probe.mjs                    # WASI 宿主是 node 内置模块（实验警告无害）
```

示例里 wasm 两个目标的 actual 都是纯 Kotlin 常量——刻意的：wasm-js 的 JS 互操作语法与 Kotlin/JS **不同**（external 声明映射到 import-object，没有 `js("...")` 内联），教学示例不掺这摊水，快照也因此完全确定。

### 25.4.3 现状定位（2026）

Wasm 后端已可用于真实项目（kotlinx 库大量已支持），但生态位仍在演进：浏览器侧与 JS 后端并存（WasmGC 兼容性达标后 Wasm 是未来），服务器侧 wasi 是"Kotlin 版 Deno"式想象的载体。**选型看 25.7 的表**。

## 25.5 expect/actual：跨平台 API 的声明与实现

### 25.5.1 机制

KMP 的核心机制就一对修饰符：

```kotlin
// common（src/Common.kt）——只声明"每个平台都得有这个"
expect fun platformName(): String

// 各平台 actual——签名必须严格匹配（返回类型/参数/reified 都不能差）
actual fun platformName(): String = "js (node)"             // js/Js.kt
actual fun platformName(): String = "native (kotlin-native)" // native/Native.kt（只报目标族，见下）
```

规则要点：

1. **expect 是声明，actual 是实现**——common 代码调 expect，编译到哪个目标就用哪个 actual；
2. 签名不匹配是硬错误（包括默认参数值、可空性）；
3. expect/actual 不限于函数：类、属性、对象、 typealias、注解都可以（类在 2.x 仍是 Beta，会打警告）；
4. **同一模块里 expect 配 actual 是错误**（"declared in the same module"）——所以 common 和平台代码必须分属不同"编译单元"。
5. **actual 的返回值别写宿主相关的东西**（Windows-only 的常量、环境变量名、`File.separator` 拼出来的路径……）：快照只有一份，写进去就变成"只在作者这台机器上成立"。宿主三元组这类信息交给不进快照的 probe。

### 25.5.2 CLI 放行三件套（本章最大的实测发现）

JVM 的 kotlinc 有个正大光明的 `-Xmulti-platform`，但 **kotlinc-js/kotlinc-wasm 的 `-X` 列表里根本没有它**（隐藏 flag，传了才生效）；而"common 单独编译、expect 无 actual"在 K2 里默认是硬错误（`-Xno-check-actual` 压不住，`-Xexpect-actual-holders` 已移除）。实测能走通的组合是三个 flag 同时上：

| flag | 作用 | 缺了会怎样 |
|---|---|---|
| `-Xmulti-platform` | 打开语言层面的 expect/actual 支持（web CLI 隐藏 flag） | "can be used only in multiplatform projects" |
| `-Xseparate-kmp-compilation` | 启用分离式 KMP 编译方案（common 源集按自身依赖分析） | expect 无 actual 报错，klib 编不出来 |
| `-Xcommon-sources=<common 源>` | 标记哪些源属于 common 模块（与平台源同命令行传入） | expect/actual 被当成同模块，报"same module" |

这套组合让**单条命令**完成"common + 平台 actual + 链接"的编译——比 Gradle 的多源集流水线粗暴，但正适合教学透视。真实工程请直接上 Gradle（25.6）。

另外：konanc 认同样的三件套（`-Xmulti-platform` 在它的帮助里是明示的），所以示例四个目标用**完全一致的心法**编译。

### 25.5.3 Gradle 里的形态（对照）

Gradle 的 kotlin-multiplatform 插件把上面全部自动化：commonMain 编成带元数据的 klib → 各平台源集编成平台 klib → 链接成产物。你永远不手敲那三个 flag——这正是"CLI 透视教学"的价值：知道插件在替你做什么。

## 25.6 KMP 与 Gradle：真实工程的样子

真实多平台工程的骨架（17 章 Gradle 知识的直接延伸）：

```text
shared/
├── build.gradle.kts        kotlin { wasmJs(); mingwX64("native"); js(nodejs) ... }
├── src/
│   ├── commonMain/kotlin/  ← 25 章的 src/（expect 在这）
│   ├── jsMain/kotlin/      ← js/（js actual）
│   ├── wasmJsMain/kotlin/  ← wasmjs/
│   ├── nativeMain/kotlin/  ← 可选：所有 native 目标共享的中间层
│   └── mingwX64Main/kotlin/← native/（平台叶子 actual）
```

要点速览（细节是下一本书的事）：

- **源集层级**：commonMain → 中间层（nativeMain 等）→ 平台叶子（mingwX64Main），下游看得见上游的 expect；
- **依赖按源集配置**：`commonMain.dependencies { implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:…") }`——库必须提供对应目标的构件（.klib），JVM-only 的 jar 塞不进 commonMain；
- **applyDefaultHierarchyTemplate**：2.x 默认模板自动搭中间层，不用手写 `dependsOn`；
- **Compose Multiplatform**：UI 层也能共享（Android/iOS/Desktop/Web）——KMP 生态最大的应用场景；
- **版本对齐**：kotlin-multiplatform 插件版本 = Kotlin 版本（2.4.20），stdlib 不用显式声明。

本教程 CLI 路线的边界要说清楚：CLI 适合理解机制、单文件演示、CI 里轻量探测；**多模块、依赖解析、DCE、增量编译、测试分发**都是 Gradle 的领地——25 章示例的 build.ps1 手工编排了四目标编译，正是 Gradle 插件自动化的那部分。

## 25.7 目标选型：什么场景选什么

| 你的诉求 | 选 | 理由 |
|---|---|---|
| 服务端/Android/桌面（JVM 系） | JVM | 生态最深，前 24 章全部适用 |
| 前端 Web，渐进增强 | JS | 与 npm 生态零摩擦，DCE 后体积可控 |
| 前端 Web，重计算/要类型保真 | Wasm (wasm-js) | WasmGC 原生类与 Long，启动快 |
| 边缘/嵌入式/CLI 工具，无 VM | Native | 独立二进制，启动毫秒级 |
| 插件沙箱/跨运行时分发 | Wasm (wasm-wasi) | WASI 接口面窄，宿主中立 |
| 一套核心逻辑多端复用 | KMP（common + 多目标） | expect/actual 切平台差异 |

经验法则：**先写 common，写不下去的地方才是平台差异**。expect 的数量是设计质量的反向指标——每加一个 expect，先问能不能用接口/依赖注入代替（CLI 单目标场景往往不需要 expect）。

## 25.8 本章验证链（25 章特例）

`build.ps1 -Example 25_multiplatform` 对四个目标各做三层：

1. **编译**：`-Werror`（真警告即失败；web CLI 的 "obsolete form" 假警报白名单放行）；
2. **运行**：node / probe.exe 运行 exit 0——**断言内嵌在 main 里**（`checkSelf()` + 各处 `check`），非 JVM 目标没有 kotlin.test runner，断言失败 = 进程非零退出，这就是它们的"L2 测试层"；
3. **快照**：`expected-js.txt` / `expected-wasmjs.txt` / `expected-wasi.txt` / `expected-native.txt` 四份 golden——**八行内容四目标逐字节一致，只有 platform 行不同**，这份 diff 本身就是"多平台复用"的直观证据。

快照确定性设计（21 章纪律的多平台版）：探针值（node 版本、用户名）**不进快照**——common 里只断言其形状（非空、长度合理），输出统一 `ok (host-dependent, redacted)`。否则换台机器/升级 node 快照就崩。

## 25.9 坑位清单（全部实测）

1. **konanc + JDK ≥ 24 直接崩**：`run_konan.bat` 的 `--enable-native-access=ALL-UNNAMED` 引号解析 bug（"此时不应有 =ALL-UNNAMED"）。钉死 JDK 21。
2. **web 链接步 exit code = 1 但成功**：zip-fs dispose 的 NPE 假阳性——判定看产物与运行，别看退出码。
3. **"obsolete form" 警告假警报**：`=` 写法也报，无法消除，白名单处理。
4. **`-Xinclude` 必须绝对路径**：相对路径 `No module found`；斜杠正反都行。
5. **kotlinc-js/wasm 无 DCE**：hello world 级 722 KB / 1.1 MB，全量 stdlib 打包——体积对比要注明"CLI 产物"。
6. **expect 无 actual 是硬错误**：`-Xno-check-actual` 和已移除的 `-Xexpect-actual-holders` 都压不住——必须 `-Xmulti-platform` + `-Xseparate-kmp-compilation` + `-Xcommon-sources` 三件套（25.5.2）。
7. **`-Xmulti-platform` 在 web CLI 是隐藏 flag**：帮助里不列，传了才生效——文档找不到别慌，不是你眼花。
8. **同模块 expect/actual 报错**：common 源不标 `-Xcommon-sources` 就和平台源同模块，报 "same module"。
9. **konanc 不建输出目录**：`-o` 的父目录要先 `New-Item`，否则链接期才报 `cannot open output file`。
10. **kotlinx.cinterop 全是实验 API**：`getenv`/`toKString` 都要 `@OptIn(ExperimentalForeignApi::class)`，且 `toKString` 要显式 import（它是扩展函数不是成员）。
11. **wasi 走 node 会打 ExperimentalWarning**：node:wasi 还是实验模块，快照比对前过滤（教程 build.ps1 处理了）。
12. **WasmGC 要新运行时**：node 22+ 原生支持（本机 26 实测）；老浏览器/老 node 跑不了 wasm-js/wasi 目标产物。
13. **PATH 上的 java 是 8**（老坑新位置）：konanc 用 `%JAVA_HOME%`，build.ps1 已钉 21——手动跑命令时别忘了。
