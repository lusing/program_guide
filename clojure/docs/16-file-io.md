# 16 · 文件与 I/O

> 对应示例：`examples/14_file_io.clj`

> `slurp`/`spit` 两把快刀 + `with-open` 资源纪律 + **EDN**——Clojure
> 原生的数据序列化格式（比 JSON 更 Clojure：关键字、集合、比值全能装）。

## 16.1 slurp / spit：一把梭读写

```clojure
(spit "out.txt" "Line 1\n")                    ; 整串写入（覆盖）
(spit "out.txt" "more\n" :append true)          ; 追加
(slurp "out.txt")                               ; 整个读成 String
(slurp "out.txt" :encoding "UTF-8")             ; 指定编码
(slurp "https://example.com")                   ; URL 也能 slurp！（io/reader 通吃）
```

适合小文件（配置、报文）。大文件走 16.3 的流式。

## 16.2 clojure.java.io：统一入口

```clojure
(require '[clojure.java.io :as io])

(io/file "build" "tmp" "a.txt")          ; File 对象（拼路径，跨平台分隔符）
(.exists (io/file "x"))                  ; File 谓词
(io/reader "x.txt")                      ; Reader（文件/URL/流通吃）
(io/writer "x.txt" :append true)
(io/copy src dst)                        ; 复制（文件→文件/流）
(io/resource "config.edn")               ; 从 classpath 找（打包进 jar 的资源！）
```

`io/resource` 是"配置文件别用文件路径找"的答案——开发时在目录里、打包后在 jar 里，`resource` 都找得到。

**跨平台临时目录**：`(System/getProperty "java.io.tmpdir")`；或像本教程示例一样放项目内 `build/tmp`。别硬编码 `/tmp`（Windows 没有）。

## 16.3 with-open + line-seq：流式读

```clojure
(with-open [r (io/reader "big.log")]
  (count (line-seq r)))                  ; 行数：惰性逐行，不整载
```

`with-open` 结束自动 close（try/finally 的语法糖）。**铁律：惰性 seq 别逃出 with-open**（10 章坑 5）——`line-seq` 的"读下一行"发生在消费时，作用域外消费 = 读已关闭的流：

```clojure
(with-open [r (io/reader f)]
  (doall (line-seq r)))                  ; 域内压实，安全带出
;; 或直接域内"reduce 掉"（推荐：一次遍历出结果）
(with-open [r (io/reader f)]
  (reduce (fn [acc line] (if (.contains line "ERROR") (inc acc) acc))
          0 (line-seq r)))
```

大文件处理模板 = `with-open` + `reduce`（或 transduce，20 章）。

## 16.4 写文件的三档

```clojure
(spit f "整串")                            ; 档1：小内容
(with-open [w (io/writer f)]               ; 档2：逐行（百万行级别）
  (doseq [line lines]
    (.write w (str line "\n"))))
(with-open [w (io/writer f)]               ; 档3：clojure.pprint/美化（结构化输出）
  (binding [*out* w] (clojure.pprint/pprint data)))
```

## 16.5 EDN：Clojure 的 JSON+

EDN（Extensible Data Notation）：Clojure 字面量语法子集就是序列化格式——**往返无损**。

```clojure
(require '[clojure.edn :as edn])

(def data {:name "Alice" :age 30
           :roles [:admin :user]
           :score 3.14 :ratio 1/3})

(pr-str data)                ; "{:name \"Alice\", :age 30, ...}"   写出（带关键字/比值）
(spit "d.edn" (pr-str data))

(edn/read-string (slurp "d.edn"))     ; 读回 => 与 data 完全相等（= data 为 true）
(edn/read-string "{:a 1}")            ; => {:a 1}
(edn/read-string "#inst \"2026-09-21\"")   ; => #inst "..."   标签字面量原生支持
(edn/read-string "#uuid \"...\"")
```

| | JSON | EDN |
|---|---|---|
| 关键字 | ✘（字符串键） | ✔ `:kw` |
| 集合 | ✘ | ✔ vector/set |
| 比值/大数 | ✘ | ✔ `1/3` `42N` |
| 注释 | ✘ | ✔ `;` |
| 生态 | 万物互联 | Clojure 圈；JVM/JS 双端同构 |

**写**用 `pr-str`/`spit`，**读必须用 `clojure.edn/read-string`**——不是 `read-string`！后者是读**代码**的（能执行任意函数 = 反序列化漏洞）：

```clojure
(read-string "(#=(eval (System/exit 1))")   ; 危险！read-string 会 eval
(edn/read-string "(+ 1 2)")                 ; => (+ 1 2)  只是数据，安全
```

JSON 互操作（对接外部系统）用 `cheshire`/`clojure.data.json`（27 章），内部持久化无脑 EDN。

## 16.6 文件系统走查

```clojure
(.listFiles (io/file dir))                       ; File[]
(mapv #(.getName %) (.listFiles (io/file dir)))  ; 文件名列表
(file-seq (io/file "src"))                       ; 惰性递归遍历整棵树（目录在前）
(filter #(.isFile %) (file-seq (io/file "src"))) ; 只留文件
(.mkdirs (io/file "a/b/c"))                       ; 建多级目录
(.delete (io/file "a.txt"))
```

`file-seq` + `filter` + `map` = 函数式 `find`：

```clojure
(->> (file-seq (io/file "src"))
     (filter #(-> % .getName (.endsWith ".clj")))
     (mapv #(.getAbsolutePath %)))
```

## 16.7 坑位清单

1. **`slurp` 整文件进内存**——2GB 日志别 slurp；流式 reduce（16.3）。
2. **`spit` 不建目录**：目录不存在直接 FileNotFoundException——先 `(.mkdirs (io/file parent))`。
3. **`read-string` 读外部数据 = 远程代码执行**：永远 `clojure.edn/read-string`。
4. **`line-seq` 逃逸 with-open**：拿到域外的惰性行序列，消费时流已关。域内 doall/reduce。
5. **相对路径看当前目录**：脚本在哪跑，`"out.txt"` 就在哪——要稳定就锚定项目根（`(io/file (System/getProperty "user.dir") ...)`）或用 `io/resource`。
6. **EDN 读不到的引用**：读到没定义的 tag（`#foo/bar ...`）抛异常——带 `:default` 处理器：`(edn/read-string {:default tagged-literal} s)`。
7. **Windows 编码**：`spit` 默认 UTF-8，但老 Windows 程序要 GBK——`(:encoding "GBK")` 显式给。
8. **`(io/resource "x")` 可能返回 nil**（找不到时），直接 slurp 会 NPE——先判或 `some->`。

---

上一章：[15 Java 互操作](15-java-interop.md) · 下一章：[17 命名空间](17-namespaces.md)
