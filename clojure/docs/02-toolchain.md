# 02 · 工具链与运行方式

> 对应示例：无（2.1 安装是系统级命令，其余本章命令全部可直接在项目根目录执行）

> Clojure 有两条主流工具链：官方 **Clojure CLI**（`deps.edn`）与社区元老
> **Leiningen**（`project.clj`）。本教程双轨并存——两侧声明同一组依赖，
> `build.sh` / `build.ps1` 分别是两条轨的验证入口。

## 2.1 安装：先装 JDK，再装工具

唯一的硬前置是 **JDK**：Clojure 本体要求 JDK 8+，Leiningen 2.13 的启动器需要 JDK 16+（CHEATSheet W1），本教程在 JDK 26 上验证。

**Clojure CLI**（macOS/Linux 侧主力，`build.sh` 用它）：

```bash
# Linux：官方一键脚本，装到 /usr/local/bin，提供 clojure 与 clj 两个命令
curl -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
sudo bash linux-install.sh

# macOS
brew install clojure/tools/clojure
```

`clj` 包装依赖 rlwrap 做行编辑（Debian/Ubuntu：`sudo apt install rlwrap`）；只用 `clojure` 命令则不需要。发行版自带包（`apt install clojure` 之类）版本普遍陈旧，不建议用。

**Leiningen**（26 章工程链要用；发行版仓库同样滞后，直接装官方最新版）：

```bash
mkdir -p ~/bin
curl -o ~/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod +x ~/bin/lein
lein version        # 首次运行自举下载完整发行版
```

注意 `~/bin` 要在 `PATH` 里。`clojure --version` 与 `lein version` 都能打印版本号，环境即就绪。

## 2.2 Clojure CLI：三种模式

| 模式 | 命令 | 语义 |
|---|---|---|
| main | `clojure -M script.clj` | 按命令行传参跑 main（最常用） |
| exec | `clojure -X namespace/function` | 调一个函数，参数从 stdin/命令行给 EDN |
| REPL | `clojure`（无参数） | 交互式求值 |

```bash
clojure -M examples/01_hello.clj     # 跑脚本
clojure -e '(+ 1 2)'                 # 求值一个表达式 => 3
clojure                              # 进 REPL：user=>
```

`-M` 与 `--main` 缩写同源：`clojure -M -m my.ns` 跑命名空间的 `-main`。

## 2.3 deps.edn 解剖

```clojure
{:deps {org.clojure/clojure {:mvn/version "1.12.6"}
        org.clojure/core.async {:mvn/version "1.9.865"}
        ring/ring-core {:mvn/version "1.15.5"}}
 :paths ["examples"]                  ; classpath 里的源码目录
 :aliases {:test {:extra-paths ["test"]}}}
```

- 依赖坐标是 Maven 坐标 `group/artifact` + 版本；解析结果缓存在 `.cpcache/`（本地缓存目录，不入库）。
- `ring/*` 这类坐标在 **Clojars**（社区仓库）而非 Maven Central——首次拉取需要两者都可达。
- 改了 `deps.edn` 下次运行自动重算，无需显式 install 步骤。

## 2.4 Leiningen：project.clj 一览

```clojure
(defproject clojure-guide "1.0.0"
  :dependencies [[org.clojure/clojure "1.12.6"] ...]
  :source-paths ["examples"]
  :profiles {:uberjar {:aot :all}})
```

`project.clj` 本身是 Clojure 代码（`defproject` 是宏）；`deps.edn` 则是纯 EDN 数据。取舍：

| | Clojure CLI | Leiningen |
|---|---|---|
| 定位 | 轻量官方工具，组合式 | 全流程工程工具 |
| 运行脚本 | `clojure -M f.clj` | `lein run -m ns`（需工程布局） |
| 测试/打包 | 靠别名 + 额外工具 | `lein test` / `lein uberjar` 内置 |
| 生态 | 新项目默认 | 存量项目巨多 |

工程化细节（布局、profile、uberjar）见 [26 章](26-leiningen.md)。

## 2.5 本教程的实际执行方式（无 clojure CLI 时）

`build.ps1` 的做法可以单独借用——lein 只当**依赖解析器**，脚本用 JVM 直接跑：

```powershell
lein deps                          # 解析依赖到 ~/.m2
$cp = lein classpath               # 拿到完整 classpath
java -cp $cp clojure.main 脚本.clj  # 与 clojure -M 等价
```

示例是独立脚本（文件名与命名空间不对应），所以走 `clojure.main 文件` 而非 `lein run -m`。

## 2.6 REPL 工作流：程序不停，代码热换

REPL 不是"试一行就退的计算器"，而是 Clojure 的开发方式本体：

```clojure
user=> (def xs (range 10))          ; 造点数据
user=> (reduce + (filter odd? xs))  ; 试一个管线 => 25
user=> (defn f [xs] ...)            ; 改定义，立即生效
```

长会话的标准循环：在编辑器里连着 REPL（CIDER/Calva/conjure），光标所在表达式 `C-x C-e` 发过去求值——程序状态还在，函数已换新。27 章列编辑器生态。

`clojure.repl` 里有几个探索现场的利器：

```clojure
user=> (doc map)          ; 看文档字符串
user=> (source map)       ; 看源码（clojure.core 就在 classpath 里）
user=> (dir clojure.set)  ; 列命名空间公共符号
user=> (apropos "merge")  ; 按名字搜
```

## 2.7 Windows 实测坑（本教程踩过的）

1. **PATH 里的 java 是 8**：Leiningen 2.13 启动器给 JVM 传 `--enable-native-access=ALL-UNNAMED`，Java 8 直接 `Unrecognized option` 崩溃。且 `lein.bat` 只认 **`JAVA_CMD`** 环境变量（不认 `JAVA_HOME`），必须设成 JDK 16+ 完整路径。
2. **PowerShell 拆散 JVM 参数**：`java -Dfile.encoding=UTF-8 ...` 会被拆成 `-Dfile` + `.encoding=UTF-8`，报 `ClassNotFoundException: .encoding=UTF-8`。参数要逐个成串传递：`& $java '-Dfile.encoding=UTF-8' '-cp' $cp 'clojure.main' $f`。
3. **Clojars 偶发 SSL 握手失败**：重试即可，Maven 有自己的重试逻辑。

## 2.8 坑位清单

1. **`clj` vs `clojure`**：`clj` 是带 rlwrap 行编辑的包装（仅类 Unix）；Windows 上只有 `clojure`。
2. **首次启动慢是正常的**：下载依赖 + 解压；之后有 `.cpcache` 缓存，亚秒级。
3. **`-A` 已被 `-M`/`-X` 取代**：老教程里的 `clojure -A:alias` 还能用，但新代码别再写。
4. **`lein.bat` 会向上找 project.clj**：在子目录里敲 lein，行为以找到的工程根为准（`lein-lab` 正是利用这一点自成工程）。
5. **同一目录并存 `deps.edn` 与 `project.clj` 完全合法**（本教程就这么干）：两套工具各读各的，互不干扰——记得两边依赖保持同步。

---

上一章：[01 认识 Clojure](01-overview.md) · 下一章：[03 Hello World](03-hello.md)
