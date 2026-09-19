# macOS 应用开发教程（Xcode / Swift / Objective-C / Cocoa）

用**本机 Xcode 16.2（Swift 6.0.3）+ Command Line Tools** 讲 macOS 原生应用开发：
AppKit、Objective-C、XIB/nib、Cocoa Bindings、打包签名。

20 章正文放在 [`docs/`](./docs)（目录页见 [`macOS开发指南.md`](./macOS开发指南.md)），每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例。
全部示例都不打开 Xcode —— 只用 `swiftc` / `clang` / `ibtool` 在终端里编出来跑，
因为这样你才知道 Xcode 到底替你做了什么。

## 快速开始

```bash
cd macosdev

./run-all.sh                       # 跑全部 20 个示例（双工具链 × 六条判定）
./run-all.sh 14                    # 只跑第 14 章（XIB / nib）
./run-all.sh 01 07 14              # 跑指定的几个

/opt/local/bin/pwsh ./build.ps1 -All           # 等价的 PowerShell 入口
/opt/local/bin/pwsh ./build.ps1 -Only 14       # 只跑 14
/opt/local/bin/pwsh ./build.ps1 -Clean         # 清空 build/
```

两个入口做的事情**完全等价**。这不是重复劳动，是**互证**：
同一份示例在两条脚本下结论一致，才能说明判定的不是脚本自己的 bug。

## 本机工具链

| 项目 | 值 |
| --- | --- |
| macOS | 14.8.9（Darwin 23.6.0，x86_64） |
| Xcode | 16.2（Build 16C5032a，`/Applications/Xcode.app`） |
| Swift | 6.0.3（两套工具链同版本） |
| Apple clang | 16.0.0（clang-1600.0.26.6） |
| Xcode SDK | `.../Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`（macOS 15.2） |
| Command Line Tools | `/Library/Developer/CommandLineTools` |
| CLT SDK | `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`（macOS 15.2） |
| 部署目标 | `x86_64-apple-macos12.0`（刻意钉得比本机低，让误用新 API 在编译期暴露） |

**本机有两套可用的 Swift**（`/usr/bin/swiftc` 与 Xcode.app 里那套），
验证脚本**两条都跑**并逐字节比对输出。

> `ibtool` / `actool` / `xcodebuild` **只在装了 Xcode.app 的机器上存在**，
> Command Line Tools 里没有。所以第 14、17 章（XIB / nib）需要 Xcode.app。

## 目录结构

```
macosdev/
├── README.md                 本文件
├── macOS开发指南.md           教程目录页（指向 docs/ 各章）
├── run-all.sh                shell 入口
├── build.ps1                 PowerShell 入口（等价）
├── docs/                     20 章正文
│   ├── 01-toolchain.md
│   ├── ...
│   └── 20-pasteboard-undo.md
├── examples/                 20 个示例目录（NN_topic）
│   ├── 01_toolchain/main.swift
│   ├── 04_objc_language/     (Person.h/.m、NSString+Extras.h/.m、Speaker.h)
│   ├── 07_objc_swift_mix/    (OC + Swift 混编，含 Bridging.h)
│   ├── 14_xib_and_nib/       (MainView.xib + main.swift)
│   └── 17_packaging/         (AppWindow.xib + main.swift)
├── tools/
│   └── check_xib.py          XIB 静态一致性检查（编译前跑）
└── build/                    编译产物（stdout/stderr/日志，不入库）
```

## 各章索引

| 章 | 标题 | 示例 | 要点 |
| --- | --- | --- | --- |
| 01 | 工具链 | `01_toolchain` | xcrun / 两套 SDK / ibtool / 部署目标 / 六条判定 |
| 02 | 第一个 AppKit 应用 | `02_hello_appkit` | NSApplication / NSWindow / 左下角原点 / 自测模式 |
| 03 | AppKit 架构 | `03_appkit_architecture` | 响应链 / 委托可选方法 / target-action / MVC |
| 04 | Objective-C 语言基础 | `04_objc_language` | 消息发送 / nil / SEL / 协议分类 / block / NSError |
| 05 | Foundation（OC 篇） | `05_objc_foundation` | NSString length / NSNotFound / NSNumber / JSON |
| 06 | Foundation（Swift 篇） | `06_swift_foundation` | String↔NSString / Range↔NSRange / Codable / 值语义 |
| 07 | OC 与 Swift 混编 | `07_objc_swift_mix` | bridging header / 生成的 Swift 头 / nullability |
| 08 | 窗口、sheet、模态 | `08_window_and_modals` | frame vs contentRect / level / NSAlert / NSSavePanel |
| 09 | 布局 | `09_layout` | autoresizingMask / Auto Layout / NSStackView / NSScrollView |
| 10 | 常用控件 | `10_controls` | NSButton 四种类型 / NSTextField / NSPopUpButton / Stepper |
| 11 | KVC / KVO / Bindings | `11_kvo_bindings` | @objc dynamic / Bindings 双向 / NSArrayController |
| 12 | 表格与大纲 | `12_table_outline` | view-based vs cell-based / NSOutlineView 的 item 模型 |
| 13 | 富文本与 TextKit | `13_attributed_text` | 属性串共享引用 / 字体度量 / storage-layout-container |
| 14 | XIB 与 nib | `14_xib_and_nib` | ibtool / File's Owner / outlet / customModule |
| 15 | 绘图 | `15_drawing` | NSRect / NSBezierPath / 语义色 / bitmapData / NSImage |
| 16 | 持久化 | `16_persistence` | UserDefaults 域 / plist / 文件 / 本地化 / 沙箱 |
| 17 | 打包 | `17_packaging` | .app 结构 / Info.plist / .lproj / 签名公证 |
| 18 | 并发 | `18_concurrency` | GCD / concurrentPerform / OperationQueue / 主线程规则 |
| 19 | 菜单、状态栏、工具栏 | `19_menus` | NSMenu / target=nil 走响应链 / NSStatusItem / NSToolbar |
| 20 | 剪贴板、拖放、撤销 | `20_pasteboard_undo` | NSPasteboard 多类型 / 拖放协商 / NSUndoManager 分组 |

## 建议阅读顺序

从零开始：01 → 02 → 03 → 09 → 10 → 14 → 11 → 12 → 16 → 17

要写 Objective-C / 维护老项目：04 → 05 → 07 → 13

专项：06（Swift 侧桥接）、08（窗口）、15（绘图）、18（并发）、19（菜单）、20（拖放撤销）

## 验证状态（全部通过）

```
通过 40   失败 0   输出差异 0   示例 20   通道 2
```

- **20 个示例 × 2 条工具链通道 = 40 次运行，全部 PASS**
- **双通道输出逐字节一致**（`[cmp]` 全绿）
- `tools/check_xib.py`：2 个 XIB 的类名 / 模块名 / 连线与源码一致

### 六条判定标准

一个示例「通过」要同时满足：

1. **编译日志为空** —— 零告警，含 `ibtool` 的
2. **退出码为 0**
3. **stderr 为空**
4. **stdout 非空** —— 防止进程根本没执行到业务代码却返回 0
5. **stdout 无多余控制字符**（0..31 除 TAB/LF/CR）
6. **stdout 有结束标记** `==== NN 结束 ====` —— 防止输出被截断

**这六条都做过反向验证**：故意造出「未使用的局部变量（告警）」、
「往 stderr 写一行并 exit 3」、「不打印结束标记」、「输出里塞 `\u{07}`」、
「什么都不打印」五个坏样例，确认每一条都会真的判 FAIL。
只判退出码会漏掉一整类假阳性（比如进程被 LaunchServices 当文档「打开」时
退出码仍是 0）；只判 stderr 会漏掉编译告警。

### 示例的自测约定

每个 AppKit 示例都支持 `--selftest`：不弹窗、不建窗口、只跑断言然后退出。
要点：

- `setActivationPolicy(.accessory)` —— 不出 Dock 图标
- 建完窗口**绝不** `makeKeyAndOrderFront`
- 需要 run loop 时用 `NSApp.stop(nil)` + **补投一个事件**（只 stop 不够，`run()` 卡在等事件）
- **不要用 `NSApp.terminate(nil)`** —— 它直接 `exit()`，之后的代码（含结束标记）来不及执行
- 环境相关的数字（并发计数、时间戳、线程 id、系统语言顺序）**不打印**，只打印性质

### Objective-C 示例为什么用 printf

`NSLog` 写的是**系统日志（stderr）**，而判定标准要求「stderr 为空」。
生产代码用 `NSLog` 没问题，自测代码一律 `printf`。

## 已知差异与环境事实

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `ibtool` 很慢（30 秒 ~ 3 分钟） | 它要加载 Interface Builder 的 Cocoa 插件 | 脚本给 180 秒超时，别以为卡死 |
| `rowHeight` 默认值 24（旧版 macOS 是 17） | 没有写死的标准值 | 只断言「> 0」 |
| `NSBezierPath.elementCount` 本机是 5（某些版本是 6） | 不是 API 契约的一部分 | 只断言「>= 4」 |
| `NSBezierPath(ovalIn:).bounds` 原点带 `1e-16` 噪声（甚至 `-0.0`） | 椭圆用四段三次贝塞尔逼近，bounds 由拍平曲线算出 | 不能写 `==`，按 epsilon 断言（`nearlySameRect`） |
| `systemRed` 转 sRGB 后绿分量是 0.2（旧系统是 0.3） | 系统调色板随 macOS 版本微调 | 只断言「红分量高、绿 < 红」，不写死具体值 |
| 文本限宽后的具体宽度随系统字体版本漂移（本机 39.8，旧系统 26.5） | 换行点由字体度量决定 | 只断言「不超过限制」，不写死数字 |
| `en_US_POSIX` 下 `.decimal` 无千位分隔符 | 输出是 `12345.678` 不是 `12,345.678` | 不照抄书本，往返断言 |
| `NSBitmapImageRep.setColor(_:atX:y:)` 写不进去 | deviceRGB 位图上的已知问题 | 直接写 `bitmapData` |
| `NSApp` 在 `NSApplication.shared` 之前是 nil | `NSApplication!` 隐式解包 | 每个示例第一句建 shared |
| 并发计数每次不同 | 竞态本身 | 数字**和**「是否丢了更新」的布尔值都不打印（后者同样不稳定） |

## 与 Xcode 工程的对照

| Xcode 里 | 命令行等价物 |
| --- | --- |
| Deployment Target | `-target x86_64-apple-macos12.0` |
| SDKROOT | `-sdk` / `-isysroot` |
| Link Binary With Libraries | `-framework X` |
| Product Module Name | `-module-name` |
| 编译 .xib | `ibtool --compile` |
| 编译 .xcassets | `actool` |
| Bridging Header | `-import-objc-header` |
| 生成的 Swift 头文件 | `-emit-objc-header-path` |

本教程没有 `.xcodeproj`：理解了命令行版本，你就能读懂 Xcode 的
Build Settings（它们本质上就是这些参数的一张表）。要在 Xcode 里跑同样的代码，
建一个 " macOS → Command Line Tool " 模板，把 `examples/NN_x/` 里的源文件拖进去，
再在 Build Phases 里加一条 `ibtool` 的 Run Script（第 14、17 章需要）。

## 维护

- 改了判定函数 → **必须重做反向验证**
- 新增示例 → 同步本文件的「各章索引」+ `docs/` 下加一章
- 新增/修改 XIB → `python3 tools/check_xib.py examples` 必须过
- 两个入口**不要并行跑**（它们共用 `build/<示例>/stdout.txt`，会互相覆盖）
