# 24 · 实战：迷你 grep

> 对应示例：`examples/24_minigrep/`——**独立工程**（MinigrepCore 库 + minigrep CLI + 测试 + 固定样例）

## 24.1 需求与退出码约定

```text
用法：minigrep <pattern> [path] [--json] [-i] [-e txt,md,swift]
  递归搜索文本文件，打印高亮命中行
退出码：0 找到 / 1 未找到 / 2 用法错误
```

退出码不是装饰——grep 家族的脚本生态靠它组合（`minigrep TODO src && echo 干净`）。
三码约定贯穿整个 CLI：用法错误（2）与"跑了但没找到"（1）是不同的失败。

## 24.2 架构：库做逻辑，壳做组装

```text
examples/24_minigrep/
├── Package.swift
├── Sources/
│   ├── MinigrepCore/        ← 全部可测逻辑（库）
│   │   └── Core.swift
│   └── minigrep/            ← 薄壳（main.swift：参数解析 + 编排 + 输出）
└── Tests/
    ├── MinigrepCoreTests/   ← 8 个用例覆盖匹配/聚合/高亮/退出码/JSON 往返
    └── ../TestFixtures/     ← 固定样例（3 文件、已知命中数）
```

为什么拆库（22 章的纪律落地）：main.swift 的顶层代码 import 不到、测试够不着——
**逻辑进库才有可测试性**。Core 的函数清单：

| 函数 | 职责 | 前章知识 |
|---|---|---|
| `matchLines(in:pattern:caseInsensitive:)` | 文本 → 命中行列表 | 纯函数（无 IO） |
| `searchFile(at:…) throws` | 读文件 → `[Match]` | IO 边界（19 章） |
| `collectTextFiles(root:extensions:)` | 递归收集 + **排序保确定** | enumerator（19 章） |
| `aggregate(…) -> SearchReport` | 并发结果 → 确定性报告 | 13 章排序 |
| `highlighted(…) ` | 行内首命中包 ANSI 红 | `range(of:options:)`（14 章） |
| `exitCode(for:)` | 报告 → 退出码 | 约定 |

`SearchReport`/`Match` 是 **Codable + Sendable** struct——报告直接 `--json` 输出
（20 章），值类型跨并发域免检（18 章）。

## 24.3 数据流：并发的确定性

```swift
let files = try collectTextFiles(root: root, extensions: extensions)   // 已排序

let fileResults = await withTaskGroup(of: (URL, [Match]).self) { group in
    for file in files {
        group.addTask {
            let matches = (try? searchFile(
                at: file, pattern: needle, caseInsensitive: ignoreCase)) ?? []
            return (file, matches)
        }
    }
    var collected: [(URL, [Match])] = []
    for await result in group { collected.append(result) }   // 到达顺序不定！
    return collected
}

let report = aggregate(...)   // 内部按路径重排 + 汇总——输出与完成顺序无关
```

两层确定性设计（17 章纪律的实战版）：

1. **输入端排序**：`collectTextFiles` 返回前 sorted——任务的"编号"稳定；
2. **输出端排序**：`aggregate` 按路径重排——`for await` 的乱序到达被抹平。

所以同一目录跑十次，输出与 JSON 逐字节相同（CI 可断言）。

## 24.4 关键实现点逐个看

**行匹配（纯函数）**：

```swift
public func matchLines(in text: String, pattern: String, caseInsensitive: Bool) -> [(line: Int, text: String)] {
    let needle = caseInsensitive ? pattern.lowercased() : pattern
    for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
        let haystack = caseInsensitive ? line.lowercased() : String(line)
        if haystack.contains(needle) { hits.append((index + 1, String(line))) }
    }
}
```

大小写不敏感走"双侧 lowercase 后 contains"（简单模式够用；真要 Unicode 精确比较用
`range(of:options: .caseInsensitive)`——高亮函数就是这么写的，两种姿势都有示范）。

**ANSI 高亮**：

```swift
guard let range = line.range(of: pattern, options: options) else { return line }
return line[..<range.lowerBound] + "\u{1B}[31;1m" + line[range] + "\u{1B}[0m" + line[range.upperBound...]
```

`\u{1B}[31;1m`（红+粗）与 `\u{1B}[0m`（复位）是终端转义序列——**在原串上**找 range，
索引天然对齐（lowercase 副本的索引对不上原串，ß→ss 这类映射会错位——实测教训）。

**并发闭包的捕获纪律（Swift 6 实战坑）**：main.swift 的顶层 `var`（参数解析结果）是
MainActor 隔离的——`group.addTask` 里直接读 = "property access is 'async'"编译错误。
正解：进并发区前拷贝成本地 `let`（`needle`/`ignoreCase`）。

## 24.5 测试策略

8 个用例的分层：

1. **纯逻辑**（行匹配/空文本/高亮/退出码）——毫秒级、零 IO；
2. **IO 边界**（单文件搜索）——临时目录 + defer 清理 + **只清自己的文件**（用例并行，
   删共享目录会殃及邻居——19 章实测竞态的教训）；
3. **聚合**（乱序输入 → 排序输出）——直接构造元组，不跑真并发（并发行为由确定性
   设计保证，单测不必模拟调度）；
4. **Codable 往返**——报告编 JSON 再解码，断言键名与数值。

CLI 壳本身靠 build.ps1 的端到端验证：`swift run minigrep lorem TestFixtures` exit 0 +
结束标记；无匹配 exit 1、用法错误 exit 2 也有专路径（开发时手工验证过三码）。

## 24.6 可以继续做的事

学完本书的天然延伸（每个都是一到两章的量级）：

- **正则模式**：`-E` 开关接 14 章的 Regex（编译期字面量 → 运行期 `Regex(...)`）；
- **多模式/文件类型**：`-e` 的扩展名过滤升级为 glob；
- **流式大文件**：`FileHandle` 分块读（19.6 的伏笔）；
- **彩色开关/列对齐**：`--no-color`、终端宽度探测（WinSDK 或 Foundation）；
- **ArgumentParser**：接官方 swift-argument-parser 包（22 章的 Git 依赖示范）；
- **性能**：`-c release` + Instruments/基准测试对比 Rust 版 ripgrep（笑）。

## 24.7 坑位清单（实测收官）

1. **顶层 var 进并发闭包 = "property access is 'async'"**（本节两次出场）：拷贝成本地
   let 再捕获——MainActor 隔离是 06 章坑的并发形态。
2. **lowercase 副本的 String.Index 对不上原串**：高亮必须在原串上找（`options:
   [.caseInsensitive]`），或接受 ASCII-only 的假设并写明。
3. **`try? searchFile` 吞掉读取错误**（编码不对的文件按 0 命中处理）——教学取舍；
   严肃版应区分"读不了"与"没有匹配"（12 章分层的 CLI 场景应用）。
4. **并行测试别删共享目录**（19 章竞态的复刻教训）：清理范围 = 自己创建的东西。
5. **`for await` 结果乱序是特性不是 bug**：聚合端排序，别在收集中途做顺序敏感的
   累计（比如"上一条路径不同就打印分隔线"——会闪）。
6. **Windows 控制台 ANSI**：Windows Terminal 默认支持转义序列；老式 conhost 需要
   虚拟终端开关——教学环境（Windows Terminal + chcp 65001）无碍。

---

**全书完**。检验学习成果的方式：给 minigrep 加一个 `-c`（只输出计数）或 `-n 3`
（每文件最多 3 条）——你需要的全部知识都在前面 23 章里。

上一章：[23 · 工具链与互操作](23-tooling.md) ｜ 返回：[README](../README.md)
