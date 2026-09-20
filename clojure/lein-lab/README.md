# lein-lab —— Leiningen 工作流实验工程

教程第 26 章的配套工程：mini 文本统计工具，演示 Leiningen 的标准工程布局与四步验证链。

```bash
lein test        # 6 tests / 15 assertions
lein run         # 调用 lein-lab.core/-main
lein uberjar     # AOT 编译 + 打 standalone jar（target/lein-lab-1.0.0-standalone.jar）
java -jar target/lein-lab-1.0.0-standalone.jar 参数...
```

统一验证入口：上级目录 `build.ps1 -Lab`（Windows）或 `./build.sh --lab`（macOS/Linux）。

要点：

- 命名空间 `lein-lab.core` ↔ 路径 `src/lein_lab/core.clj`（`-` 转 `_`，`.` 转目录）
- `:gen-class` + `:profiles {:uberjar {:aot :all}}` 让 `java -jar` 直达 `-main`
- `:profiles {:dev {:global-vars {*warn-on-reflection* true}}}` 只在开发时打开反射警告
