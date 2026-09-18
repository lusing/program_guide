# 17 · 工程化与 Gradle

> 对应示例：`examples/17_gradle/`（真实 Gradle 多模块工程：lib + app，JUnit5 测试，fat jar 产物）
>
> 前面 16 章用 kotlinc 直编——理解了底层，现在看真实项目怎么组织：
> 目录约定、`build.gradle.kts`、依赖管理、多模块、测试、打包。

## 17.1 从 kotlinc 到构建工具

kotlinc 单文件编译适合学习，真实项目需要：依赖解析（Maven Central 拉库）、增量编译、测试编排、多模块、产物打包。Kotlin 世界的答案是 **Gradle**（Kotlin DSL 是一等公民）——`gradle build` 一条命令完成全部。

## 17.2 工程结构与约定

```
kt-gradle-demo/
├── settings.gradle.kts        # 工程名 + 包含哪些模块 + 仓库
├── build.gradle.kts           # 根：统一插件版本（apply false）
├── lib/
│   ├── build.gradle.kts       # 模块构建脚本
│   └── src/
│       ├── main/kotlin/       # 主代码（包结构 = 目录结构）
│       └── test/kotlin/       # 测试代码
└── app/
    ├── build.gradle.kts
    └── src/main/kotlin/Main.kt
```

**约定优于配置**：`src/main/kotlin`、`src/test/kotlin` 自动成为源集（不需要声明）；`src/main/resources` 放资源文件。

## 17.3 settings.gradle.kts：工程的"户口本"

```kotlin
rootProject.name = "kt-gradle-demo"

dependencyResolutionManagement {
    repositories { mavenCentral() }        // 依赖仓库集中声明
}

include("lib", "app")                       # 多模块
```

## 17.4 build.gradle.kts 逐行精讲

```kotlin
plugins {
    kotlin("jvm") version "2.4.20" apply false   // 根：只锁版本不应用
}

// app/build.gradle.kts
plugins {
    kotlin("jvm")            // 版本继承根
    application              // 提供 run 任务 + jar 的 Main-Class
}

kotlin {
    jvmToolchain(21)         // 工具链：自动找/下载 JDK 21（与环境解耦）
}

dependencies {
    implementation(project(":lib"))          // 模块依赖
    implementation("组:artifact:版本")       // 外部库形如 "com.squareup.okhttp3:okhttp:5.1.0"（本示例未引入）
    testImplementation(kotlin("test"))       // 测试依赖
}

application { mainClass.set("MainKt") }

tasks.test { useJUnitPlatform() }            // 测试框架 = JUnit5
```

关键概念：

- **插件** = 能力包（kotlin 编译、application 打包、spring 框架……）。
- **依赖范围**：`implementation`（内部用，不泄漏给下游）vs `api`（出现在下游编译类路径，只有 java-library/库项目用）。库用 `api` 要克制——它是你 API 的一部分。
- **`kotlin("test")`** 智能选择框架：配了 `useJUnitPlatform()` 就自动解析为 kotlin-test-junit5。

## 17.5 多模块：lib 与 app

示例里 `lib` 是纯函数库（greeting/wordFreq），`app` 依赖它组装 CLI 输出。**模块 = 耦合边界**：

- lib 的 `internal` 成员对 app 不可见（07 章的可见性终于有了用武之地）；
- lib 改动只重编 lib + 下游，增量构建加速；
- 版本继承根脚本，多模块永不漂移。

## 17.6 日常命令

```powershell
gradle build                 # 编译 + 测试 + 打包（最常用）
gradle test                  # 只跑测试
gradle run                   # application 插件：跑 mainClass
gradle clean                 # 清产物
gradle :app:dependencies     # 看依赖树（排查冲突神器）
gradle --no-daemon build     # CI 环境禁守护进程
```

**Gradle Daemon**：常驻编译进程（第二次构建起快很多）。`--no-daemon` 用于 CI/一次性脚本。

## 17.7 fat jar：可直跑的产物

```kotlin
val appAllJar = tasks.register<Jar>("appAllJar") {
    archiveClassifier.set("all")                       // app-all.jar
    manifest { attributes["Main-Class"] = application.mainClass.get() }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(sourceSets.main.get().output)
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
    { exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA") }   // 签名文件必须剔
}
tasks.named("build") { dependsOn(appAllJar) }
```

普通 jar 不含依赖（跑不起来）；distribution 插件生成带启动脚本的目录；**fat jar** 把全部依赖解进一个文件——`java -jar app-all.jar` 直接跑（本教程 build.ps1 对 17 章的验证方式）。签名文件（.SF/.DSA/.RSA）不剔会报 "Invalid signature file"。

## 17.8 本教程的验证链（17 章特例）

```powershell
pwsh -File build.ps1 -Example 17_gradle
# 内部执行：gradle --no-daemon clean build（编译 + JUnit5 测试）
#           → java -jar app/build/libs/app-all.jar（运行 + 快照比对）
```

对比其他章节的 kotlinc 四层验证——同一套"编译/测试/运行/快照"骨架，工具换成 Gradle。

## 17.9 与 Maven 对照（给有 Java 背景的读者）

| | Gradle (KTS) | Maven |
|---|---|---|
| 脚本 | build.gradle.kts（代码） | pom.xml（XML） |
| 多模块 | include + project(":x") | parent + modules |
| 自定义任务 | 任务即代码，任意逻辑 | 插件 + profile |
| 增量/缓存 | 增量编译 + 构建缓存 | 有限 |
| Kotlin 官方立场 | **首选**（DSL 一等公民） | 支持但二等 |

Android/IntelliJ 新项目默认全部 Gradle。

## 17.10 坑位清单

1. **版本只写一处**（根 plugins 或 version catalog）——两个模块各写一遍 version 迟早漂移。
2. `implementation` vs `api` 用错的表现：下游突然"找不到类"（该用 api 用了 implementation）或"依赖泄漏"（滥用 api）。
3. **JDK 工具链 vs 运行 JDK**：`jvmToolchain(21)` 指编译目标；本机 JAVA_HOME 指到 JDK 8 时 Gradle 自己都起不来（Gradle 9 需要 17+）。
4. fat jar 的**签名文件不剔会运行失败**（17.7 的 exclude 三连是必备咒语）。
5. 依赖冲突（同一库两个版本）：`gradle :app:dependencies` 看树，`strictly`/`constraints` 钉版本。
6. Daemon 占内存——机器卡时 `gradle --stop` 清掉。
7. 首次构建要联网拉插件/依赖（本教程 17 章第一次 build 约 4 分钟，之后增量秒级）。
