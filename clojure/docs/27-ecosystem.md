# 27 · 生态与工具

> 对应示例：无（本章是地图：编辑器、库、ClojureScript、脚本神器 babashka）

> Clojure 社区小而精，库的哲学是**组合小件**而不是"全家桶框架"。
> 记住地图，按需取用。

## 27.1 编辑器：REPL 集成是灵魂

| 编辑器 | 插件 | 特点 |
|---|---|---|
| Emacs | CIDER | 最完整的 REPL 驱动体验（Jack-in、调试、文档） |
| VS Code | **Calva** | 上手最快，新人的默认推荐 |
| IntelliJ | Cursive | 商业（免费非商业授权），静态分析最强 |
| Vim/Neovim | conjure / vim-jack-in | 轻量流派 |

无论哪个，核心动作都一样：**把编辑器连到运行中的 REPL**（jack-in），然后逐表达式求值（`eval-defun` / `Ctrl+Alt+C Enter`）、看结果在编辑器内联显示。写 Clojure 不用 REPL 集成 ≈ 写 Python 不用解释器。

辅助工具（编辑器无关）：

- **clj-kondo**：静态 linter（未用绑定、错误 arity、风格）——CI 必装，VS Code/Emacs 均集成。
- **clojure-lsp**：跳转/重构/引用查找（LSP 协议）。

## 27.2 核心库地图（按用途）

| 领域 | 库 | 一句话 |
|---|---|---|
| Web 抽象 | **Ring** | request/response map（25 章） |
| 路由 | **Reitit** | 数据驱动路由，快、带 coercion |
| JSON | cheshire / clojure.data.json | 编解码（配 muuntaja 自动内容协商） |
| 数据库 | **next.jdbc** | 直译 JDBC、execute! 批量、甜但不藏 SQL |
| 数据库 | HoneySQL | SQL 即 EDN 数据（组合查询） |
| HTTP 客户端 | http-kit / clj-http | 前者自带高并发服务端 |
| 数据校验 | **Malli** | 数据驱动 schema（spec 的现代对手，快、可序列化） |
| 属性测试 | test.check | QuickCheck 风格（19 章 spec.check 的底座） |
| CSP | core.async | 24 章 |
| 调度/管线 | integrant / mount / component | 系统组件启停（连接池生命周期） |
| 日志 | tools.logging + logback | 门面 + 实现（Slf4j 思路） |
| 日期时间 | java-time | java.time 直译（than `clj-time`，后者进维护期） |
| Datomic 系 | xtdb / datahike / datascript | 不可变数据库思想（datascript 浏览器端） |

**选库直觉**：Clojure 库多数小而组合（Ring + Reitit + next.jdbc 拼起来 ≈ 一个"框架"）；看到巨型框架先想想是不是三四个小件就够。

## 27.3 ClojureScript：同一门语言写前端

ClojureScript 把 Clojure 编译到 JavaScript：

- **语法/标准库几乎同一套**——05 章的 map/set、09 章的管线、11 章的宏全部通用。
- 差异集中在**宿主互操作**：`js/console`（代替 Java 互操作）、`#js {...}` 可变对象字面量。
- UI 主流：**Reagent**（React 的极简包装，组件就是返回 hiccup 的函数）→ **re-frame**（加事件/订阅架构）。
- 构建：**shadow-cljs**（无缝接 npm 生态，热重载开箱即用）。

```clojure
(defn button [label on-click]
  [:button {:on-click on-click} label])       ; hiccup：HTML 即数据
```

全栈同构（一个语言 + EDN 传输）是 Clojure 独有的舒服。

## 27.4 babashka：脚本世界的 Clojure

**babashka**（bb）——原生镜像打包的 Clojure 解释器：

- 启动 **~10ms**（JVM 版冷启动秒级）——`bb script.clj` 当 bash 用。
- 内置常用库（cheshire、clj-http-lite、tools.cli...），任务定义用 `bb.edn`。
- `bb task-name` 跑 `tasks` 里的函数——Makefile 的函数式替代。

写"本来该用 Python/Shell"的运维脚本，但用 Clojure 的数据结构——这是近年社区最实用的发明之一。

## 27.5 构建与发布

| 工具 | 用途 |
|---|---|
| Clojure CLI + **tools.build** | 官方程序化构建（写 Clojure 描述构建步骤） |
| Leiningen | 26 章全流程 |
| **depstar** / uberjar | CLI 生态的打包工具 |
| **GraalVM native-image** | 编译成原生可执行（毫秒启动、免 JVM 部署）——CLI 工具发布形态 |
| Clojars | 社区包仓库（`lein deploy clojars`） |

## 27.6 学习资源

- **Clojure for the Brave and True**——最友好的入门书（免费在线）。
- **ClojureDocs**——每个 core 函数带社区示例（REPL 里 `(doc f)` 之外的第一站）。
- **4Clojure / Exercism (Clojure track)**——练习场。
- Rich Hickey 演讲：*Simple Made Easy*（设计哲学）、*The Value of Values*（01 章的心智模型来源）、*Are We There Yet*（并发模型来源）。
- ClojureTV（YouTube）、r/Clojure、ClojureVerse 论坛。

## 27.7 坑位清单

1. **别急着上框架**：Luminus/Pedestal 是"脚手架 + 一堆库"，先懂 Ring/组件思想再上，否则全是黑盒。
2. **core 的 lazy 版本和急切版本成对出现**（map/doall、for/doseq、line-seq/reduce）——选错语义是 bug 不是风格问题（10 章）。
3. **clj-kondo 报的不只是风格**——未用 binding、错误 arity 常是真 bug；CI 里 `-d` 当错误处理。
4. **ClojureScript 的宏在编译期跑在 JVM 上**（reader 条件 `#?(:clj ...)`/`#?(:cljs ...)`）——跨平台的 ns 要用 reader conditionals 分叉宿主部分。
5. **版本地狱的解药是 lock**：CLI 用 `prep`/`sync-deps` 或 lein 的 `:pedantic?`——传递依赖悄悄升级是"昨天还好好的"的常见原因。
6. **社区库看维护度**：Clojure 圈库稳定期极长（10 年老库正常在用），但看 GitHub 最后提交 + issue 响应再选型。

---

上一章：[26 Leiningen 项目实战](26-leiningen.md) · 下一章：[28 压轴：MiniLisp 解释器](28-minilisp.md)
