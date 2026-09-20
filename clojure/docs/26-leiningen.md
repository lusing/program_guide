# 26 · Leiningen 项目实战

> 对应工程：`lein-lab/`（验证链：`lein test` → `lein run` → `lein uberjar` → `java -jar`，`build.ps1 -Lab` 一键跑）

> 脚本时代到工程时代：源码按命名空间进目录、测试独立、
> 依赖有版本、最后打成"给一个 JVM 就能跑"的 standalone jar。

## 26.1 工程布局：ns 名 → 路径的物化

```text
lein-lab/
├── project.clj                    工程描述
├── src/lein_lab/
│   ├── core.clj                   命名空间 lein-lab.core（:main 入口）
│   └── text.clj                   命名空间 lein-lab.text
└── test/lein_lab/
    └── core_test.clj              命名空间 lein-lab.core-test
```

17 章的硬规则落地：`lein-lab.core` → `src/lein_lab/core.clj`（**点变目录、连字符变下划线**）。`lein test` 自动发现 `test/` 下所有 `*-test` 命名空间。

## 26.2 project.clj 逐行

```clojure
(defproject lein-lab "1.0.0"                    ; 组名/版本（组名也是默认 artifactId）
  :description "Leiningen 工作流实验"            ;  进 pom.xml 的元数据
  :dependencies [[org.clojure/clojure "1.12.6"]] ; Maven 坐标向量
  :main lein-lab.core                            ; lein run / jar 的入口 ns
  :profiles {:dev     {:global-vars {*warn-on-reflection* true}}   ; 开发期开反射警告
             :uberjar {:aot :all}}               ; 打包前全量 AOT
  :target-path "target")                         ; 构建产物目录（不入库）
```

常用键还有：`:source-paths`/`:test-paths`（默认就是 src/test）、`:plugins`（lein 插件）、`:jvm-opts`（启动参数）、`:resource-paths`（io/resource 找的地方）。

## 26.3 profile：按场景叠加配置

```
lein test           隐式激活 :dev + :test
lein uberjar        隐式激活 :uberjar（AOT 在这里配才不影响日常）
lein with-profile +prod run    显式叠加
```

**profile 是"维度"不是"分支"**——`:dev` 配的东西（反射警告、测试依赖）不会泄漏进生产 jar；`:uberjar` 的 AOT 不拖慢日常开发。这是它与"配置文件分支"的根本差异。

## 26.4 四步验证链

```bash
lein test
# Ran 6 tests containing 15 assertions. 0 failures, 0 errors.

lein run                       # 调用 lein-lab.core/-main（可 lein run -- 参数...）

lein uberjar                   ; AOT 编译 + 打包
# Created .../target/lein-lab-1.0.0-standalone.jar

java -jar target/lein-lab-1.0.0-standalone.jar 参数...
# 只要有 JVM 就能跑 —— 交付形态
```

**AOT 与 gen-class**：`:aot :all` 把命名空间编译成 `.class`；core.clj 里的 `(:gen-class)` 让 ns 生成真正的 Java 类、`Main-Class` 落在它头上。两个普通 jar 与 standalone jar：前者只有你的代码，后者**内嵌全部依赖**（解压+重打包）——`java -jar` 用 standalone。

入口的样子：

```clojure
(ns lein-lab.core
  (:require [lein-lab.text :as text])
  (:gen-class))                       ; AOT 时生成 Java 类

(defn -main [& args]                  ; main 方法 = 这个函数
  (println "lein-lab | Clojure" (clojure-version))
  ...)
```

## 26.5 多命名空间协作

```clojure
;; src/lein_lab/text.clj —— 工具 ns
(ns lein-lab.text)
(defn words [s] (vec (re-seq #"[a-z]+" (clojure.string/lower-case s))))

;; src/lein_lab/core.clj —— 入口 ns，require 引用
(ns lein-lab.core (:require [lein-lab.text :as text]))
(text/words "Hello World")            ; => ["hello" "world"]
```

工程感 = **每个 ns 一件事**，入口 ns 只做"装配 + CLI"。测试同样跨 ns：`(:require [lein-lab.core :as core])` 直接测公共函数（18 章）。

## 26.6 lein vs Clojure CLI：怎么选

| 场景 | 选择 |
|---|---|
| 一次性脚本/库开发 | CLI（deps.edn 轻量） |
| 传统工程（test/uberjar 内置） | lein |
| 混合部署（同事用啥） | 跟团队 |
| 本教程 | **两个都在用**：根目录 deps.edn（CLI）+ lein-lab（lein）共存无冲突 |

`lein.bat` 会**向上搜索 project.clj** 决定工程根——所以在本教程根目录跑 lein 用的是 clojure-guide 工程，进 lein-lab/ 才是 lab 工程（这个行为本身值得知道）。

## 26.7 常用命令速查

```bash
lein new app my-app          ; 脚手架（app/默认/lib/plugin/template）
lein repl                    ; 工程 classpath 的 REPL
lein deps                    ; 拉依赖到 ~/.m2
lein check                   ; 编译期警告检查
lein clean                   ; 清 target/
lein jar                     ; 薄 jar（不带依赖）
lein install                 ; 装进本地 .m2 供别的工程依赖
lein deploy clojars          ; 发布（配凭据后）
```

## 26.8 坑位清单

1. **Windows 上 lein 2.13 需要 JDK 16+ 且只认 `JAVA_CMD`**（02 章实测坑）——`lein.bat` 不读 JAVA_HOME。
2. **`:aot :all` 直接放顶层**会让每次 `lein test`/`repl` 都全量编译——放 `:uberjar` profile 里（26.3 的正解）。
3. **改名 ns 忘改文件路径**：编译"找不到类/文件"的九成原因（17 章规则）。
4. **standalone jar 里 `io/resource` 照常工作**、`slurp "文件路径"` 失效——资源用 resource、外部配置用环境变量/绝对路径。
5. **`lein run` 的参数要 `--` 分隔**：`lein run -- --port 8080`；直接写会被 lein 自己吃掉。
6. **依赖版本冲突**：两个库传递依赖不同版本——`lein deps :tree` 看 谁 拉 的 谁。
7. **`(defproject ...)` 是宏**：里面能写表达式（`(defproject x (version-fn) ...)`），但配置求值发生在**读取工程时**——别放依赖它运行期的东西。

---

上一章：[25 Web 开发实战：Ring](25-ring-web.md) · 下一章：[27 生态与工具](27-ecosystem.md)
