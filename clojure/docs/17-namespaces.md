# 17 · 命名空间

> 对应示例：`examples/15_namespaces.clj`

> `ns` 宏是每个文件的第一行，也是 Clojure 的"模块系统"。核心只有一句：
> **命名空间名 → 文件路径**（点变目录、连字符变下划线），其余都是声明。

## 17.1 ns 全解剖

```clojure
(ns my-app.core                         ; 声明当前 ns（文件必须对应 my_app/core.clj）
  "可选的 ns 文档字符串。"
  (:require [clojure.string :as str]            ; require：加载别的 ns
            [clojure.set :as set]
            [clojure.pprint :refer [pprint]])   ; refer：拉特定符号进当前域
  (:import [java.util Date UUID]                ; import：Java 类短名
           [java.io File]))
```

四个 clause 的分工：

| Clause | 作用 | 用了之后 |
|---|---|---|
| `:require` | 加载 Clojure ns | `str/upper-case`（带 :as 别名） |
| `:refer` | 把符号直接引入 | `pprint` 裸用（慎用，`[... :refer :all]` 更慎） |
| `(:require ... :refer :all)` | 全量引入 | 社区不推荐（命名冲突+难溯源） |
| `:import` | Java 类短名 | `Date.` 而非 `java.util.Date.` |
| `:refer-clojure :exclude [...]` | 排除 core 符号 | 极少用（重定义 core 名字时） |
| `:use`（旧） | 等价 require+refer :all | 新代码禁用 |

**社区风格**：`:as` 别名优先，`:refer` 只拉高频小函数（`[clojure.test :refer [deftest is]]` 是可接受的例外）。

## 17.2 名字 → 路径：硬规则

```
命名空间            文件路径（classpath 相对）
my-app.core     ->  my_app/core.clj
my-app.util-x   ->  my_app/util_x.clj      连字符 - 变下划线 _
a.b.c           ->  a/b/c.clj              点 . 变目录分隔
```

`(require 'my-app.core)` 时 Clojure 在 classpath 找 `my_app/core.clj`（或编译过的 class）。**文件名与 ns 不匹配 → 找不到**（26 章的 lein-lab 工程布局就是按这个规则摆的）。

## 17.3 两种调用姿势

```clojure
;; 完全限定（一次性用）
(clojure.string/upper-case "a")

;; 别名（require :as 后）——99% 的写法
(str/upper-case "a")
```

命名空间关键字与 ns 自动联动（04 章 `::`）：

```clojure
(ns my-app.core)
::id                     ; => :my-app/id      —— spec 的键防撞车靠它（19 章）
(require '[other.ns :as o])
::o/id                   ; => :other.ns/id    别名也能定位
```

## 17.4 REPL 里的 ns 操作

```clojure
(in-ns 'my-app.core)     ; 切过去（不 require —— 常配合 (require ...) 或引用失败时补救）
(ns my-app.core)         ; 切 + 重声明（ns 宏 REPL 里可重复执行，clause 重放）
*ns*                     ; 当前 ns
(find-ns 'my-app.core)   ; ns 对象（可能 nil）
(ns-name *ns*)
(all-ns)                 ; 已加载的全部 ns
(remove-ns 'my-app.core) ; 卸载（调试用）
```

`ns` 在 REPL 重复执行是安全惯例——改了 require 直接重跑 ns 行，比重启 REPL 温和。

## 17.5 查找与内省

```clojure
(require '[clojure.repl :refer [doc source dir apropos find-doc]])

(doc map)                     ; 文档
(source map)                  ; 源码（stdlib 都在 classpath）
(dir clojure.set)             ; 列公共符号
(apropos "merge")             ; 名字模糊搜
(find-doc "frequencies")      ; 文档全文搜
(ns-resolve *ns* 'map)        ; 符号 → Var（#'clojure.core/map）
(ns-publics my.ns)            ; ns 公共符号表（map）
```

REPL 探索四件套 `doc/source/dir/apropos` 值得练成肌肉记忆（02 章 REPL 工作流）。

## 17.6 重新定义与热加载

```clojure
(defn f [] 1)
(defn f [] 2)            ; 重定义——REPL 里随时发生，立即对后续调用生效
(require 'my-app.core :reload)      ; 重载一个 ns（文件改了）
(require 'my-app.core :reload-all)  ; 连依赖一起重载
```

`:reload` 是"改了源文件想让 REPL 里的世界跟上"的钥匙。注意重载**不清理**旧定义（删掉的函数还在）——要彻底干净 `(remove-ns ...)` 后重新 require。

## 17.7 坑位清单

1. **文件名/路径与 ns 不匹配**：`src/myapp/core.clj` 里写 `(ns my-app.core)`——require 时找不到 `my_app/core.clj`。报错样子：`FileNotFoundException: Could not locate my_app/core.clj`。
2. **ns 名里的连字符必须下划线到文件**——`lein new app my-app` 生成的骨架自动是对的，手建目录容易翻车。
3. **`(:require ...)` 不加向量**：`(ns foo (:require clojure.string))` 合法但没别名没 refer——只能全限定调用；想用 `str/x` 要 `[clojure.string :as str]`。
4. **单引号**：`(require 'my-app.core)` 里的 quote——ns 名是符号，不 quote 会被求值成 Var 查找然后报错（REPL 手动 require 的高频错误）。`ns` 宏内部不需要（宏不吃求值）。
5. **循环依赖**：A require B、B require A → 死循环加载错。共享的东西抽第三个 ns。
6. **`:refer` 冲突**：两个 ns refer 同名符号 → `IllegalArgumentException: f already refers to...`。解法：改别名，或 `:refer-clojure :exclude`。
7. **ns 是全局加载一次**：两个文件写同一个 ns 名 = 后加载覆盖前者的定义，诡异难查——一个文件一个 ns 是铁律。

---

上一章：[16 文件与 I/O](16-file-io.md) · 下一章：[18 测试](18-testing.md)
