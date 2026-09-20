# 03 · Hello World 与基本输出

> 对应示例：`examples/01_hello.clj`

> 第一个程序从输出开始。Clojure 的输出函数一桌四个（`println` / `print` /
> `prn` / `pr`），区别只有两根轴：**换不换行**、**引不引号**。理解了
> "人类可读 vs 机器可读"，剩下的都是肌肉记忆。

## 3.1 一桌四个输出函数

| 函数 | 换行 | 字符串带引号 | 定位 |
|---|---|---|---|
| `(println x)` | ✔ | ✘ | 人类可读 |
| `(print x)` | ✘ | ✘ | 人类可读、不换行 |
| `(prn x)` | ✔ | ✔ | 机器可读（读回来 = 原值） |
| `(pr x)` | ✘ | ✔ | 机器可读、不换行 |

```clojure
(println "Hello")   ; Hello          （不带引号）
(prn "Hello")       ; "Hello"        （带引号，Clojure reader 能原样读回）
(prn :a 1 [2 3])    ; :a 1 [2 3]     （关键字、向量照排）
```

**选型规则**：给人看用 `println`，落盘/传给另一个程序用 `prn`/`pr-str`——后者保证 `(read-string (pr-str x))` 回到 `x`。集合里嵌字符串时 `println` 会"裸奔"：`(println ["a"])` 打印 `[a]`，丢信息。

## 3.2 拼接与格式化

```clojure
(str "a" "b" 123 nil)          ; => "ab123"     nil 拼接为空串
(apply str (interpose ", " ["a" "b"]))  ; => "a, b"
(clojure.string/join ", " ["a" "b"])    ; => "a, b"（干这活的标准姿势）
(format "%s = %.2f" "pi" Math/PI)       ; => "pi = 3.14"（java.lang.String/format）
(count "hello")                ; => 5
```

`str` 对任何对象调 `toString`；`(str nil)` 是 `""` 不是 `"null"`——和 Java 划清界限。

## 3.3 def 与 defn：定义一切

```clojure
(def hello "Hello, Clojure!")     ; 定义一个 Var（全局命名绑定）

(defn greet                       ; 定义函数
  "给名字打招呼。"                 ;   <- 文档字符串（可选但强烈建议）
  [name]                          ;   <- 参数向量
  (str "Hello, " name "!"))

(greet "World")                   ; => "Hello, World!"
```

注意 `defn` 的每个部件都是**向量/字符串字面量**——宏只是帮你拼成 `(def greet (fn ...))`。`def` 创建的是 **Var**（可重新定义、可带元数据），不是"变量"——没有原地修改这回事（14 章）。

## 3.4 注释三件套

```clojure
;; 单行注释：分号到行尾（两个分号是段落注释的惯例）

#_(ignored expression)           ; reader 层注释：下一个表达式整个跳过
#_#_(two forms)                  ; 前缀两次 = 跳两个表达式

(comment                          ; 表达式注释：块内求值为 nil，常用来放实验代码
  (println "not printed at load"))
```

`#_` 在 reader 阶段删除代码，连位置信息都不进编译器；`(comment ...)` 里的代码**必须语法合法**（会被读入），但不会被求值执行副作用——放"可执行笔记"用。

## 3.5 -main 与命令行参数

```clojure
(defn -main [& args]        ; & 收集剩余参数为 seq
  (println "args:" (vec args))
  (println "Clojure" (clojure-version)
           "on Java" (System/getProperty "java.version")))
```

- `clojure -M 文件.clj a b` → `args` 是 `("a" "b")`（`vec` 转成向量只为打印好看）。
- 脚本式用法里也可以直接在文件尾部 `(-main)`——示例就是这么做的，方便统一跑。
- `(clojure-version)` / `(System/getProperty "java.version")` 分别报两层版本。

## 3.6 求值结果的直觉

REPL 里每个表达式都有返回值，建立这三条直觉能省很多疑惑：

1. **副作用函数返回 nil**：`println`、`swap!`（返回新值，算例外）、`spit` 都以 nil 或状态值收尾。
2. **`def`/`defn` 返回 Var 本身**：`#'user/hello`，别被吓到。
3. **最后一个表达式就是返回值**：函数体没有 `return`，天然是"表达式风格"（07 章展开）。

## 3.7 坑位清单

1. **`println` 换集合丢引号**：调试字符串集合时改用 `prn`，或 `(pr-str x)`。
2. **`print` 不换行 + REPL 混淆**：批量 `print` 后看不到输出是缓冲/没换行的观感问题，别急着怀疑逻辑。
3. **文档字符串位置写错**：`(defn f [x] "doc" ...)` 里的 "doc" 是函数体第一个表达式（返回值），文档得放在参数向量**前面**。
4. **`-main` 里的 `args` 是字符串 seq**：要数字得自己 `(Long/parseLong (first args))`。
5. **中文输出乱码**：本教程示例字符串只用 ASCII、中文进注释——绕开控制台编码差异；真要输出中文，确保 JVM `-Dfile.encoding=UTF-8` 与终端编码一致。
6. **`(comment ...)` 不是死代码**：里面的表达式会被读取，括号不闭合照样语法错。

---

上一章：[02 工具链与运行方式](02-toolchain.md) · 下一章：[04 数据类型](04-data-types.md)
