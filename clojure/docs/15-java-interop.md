# 15 · Java 互操作

> 对应示例：`examples/13_java_interop.clj`

> Clojure 不"封装"JVM，而是**直连**：点语法调方法、斜杠取静态、
> `new` 随手造对象。整个 Maven 生态都是 Clojure 的标准库。

## 15.1 调用四式

```clojure
;; 实例方法：(.method obj args)
(.length "hello")                  ; => 5
(.substring "hello" 0 3)           ; => "hel"

;; 静态方法/字段：Class/member
(Math/sqrt 16)                     ; => 4.0
(Integer/parseInt "42")            ; => 42
Math/PI                            ; => 3.14159...   静态字段（不带括号）

;; 构造对象：(Class. args) 或 (new Class args)
(StringBuffer. "hi")
(java.util.UUID/randomUUID)

;; 全限定名（没 import 时）
(java.util.Date.)                  ; => #inst "2026-..."
```

`Class.` 的点尾巴是"构造"的 reader 语法糖。import 之后短名可用（17 章讲 `(:import ...)`）：

```clojure
(ns my.ns (:import [java.util Date UUID]))
(Date.)                            ; 短名直用
```

## 15.2 链式调用三件套

```clojure
;; .. 宏：链式调用的直译
(.. "hello" .toUpperCase (.substring 1 3))       ; => "EL"

;; -> 线程宏同样能干（09 章），且更通用
(-> "hello" .toUpperCase (.substring 1 3))       ; => "EL"

;; doto：对同一对象连续调用，返回对象本身（builder 风格）
(doto (StringBuffer.)
  (.append "a")
  (.append "b")
  (.append "c"))
;; => 内容为 "abc" 的 StringBuffer
```

`doto` 是 Java 里 `new X().setA(a).setB(b)` 链的对应物——setXxx 返回 void 的场景专用。

## 15.3 数组：性能互操作

```clojure
(int-array [1 2 3])                ; 原生 int[]
(make-array String 10)             ; 引用数组
(aget arr 0)                       ; 读
(aset arr 0 99)                    ; 写（原地！这是真可变区域）
(alength arr)                      ; 长度
(amap arr i ret (* 2 (aget arr i)))     ; 映射到新数组（宏）
(areduce arr i ret 0 (+ ret (aget arr i)))  ; 折叠（宏）
(into-array [1 2 3])               ; Object[]（类型取首元素）
(vec arr) (seq arr)                ; 数组 → Clojure 集合
```

数组是**可变的**——Clojure 里少数能原地改的东西，热路径优化用（23 章实测 26 倍）。`amap`/`areduce` 是编译宏，吃 `^ints` 提示后是纯原生循环。

## 15.4 异常与资源

```clojure
(try
  (Integer/parseInt "abc")
  (catch NumberFormatException e
    (ex-message e))                       ; => "For input string: \"abc\""
  (finally (println "cleanup")))

(throw (IllegalArgumentException. "bad"))   ; Java 异常直接造
```

- Clojure **不检查受检异常**：不声明 `throws`，想 catch 就 catch。
- 自己抛异常优先 `ex-info`（07 章）——带数据可检索。
- `with-open` 管自动关闭（16 章）。

## 15.5 实现 Java 接口：proxy / reify

```clojure
;; proxy：继承 Java 类/接口的匿名子类（有 Java 类可用）
(def r (proxy [Runnable] []
         (run [] (println "running"))))
(.run r)                            ; => running
(.start (Thread. r))                ; 直接喂给 Thread

;; reify：只实现接口（推荐，13 章）——还能闭包捕获
(def r2 (reify Runnable
          (run [_] (println "via reify"))))
```

能 reify 就 reify（编译更干净）；要**继承带状态的基类**才 proxy。

## 15.6 类型提示：掐灭反射

```clojure
(set! *warn-on-reflection* true)         ; 打开反射警告（dev profile 常开）

(defn len [s] (.length s))               ; Reflection warning!
(defn len ^long [^String s] (.length s)) ; 直接 invokevirtual

(defn sum [^longs arr] (areduce arr i r 0 (+ r (aget arr i))))
```

提示加在**使用处最近的绑定**上：参数位、`let` 局部。全局靠 `*warn-on-reflection*` 找出来再逐个点杀（23 章有 537 倍实测）。

## 15.7 转换与工具

```clojure
(Long/parseLong "42")              ; String → long
(Integer/toString 255 16)          ; => "ff"
(int \a)                           ; => 97    char → int
(char 97)                          ; => \a
(String/valueOf 42)                ; => "42"
(bean javaObj)                     ; JavaBean → map（按 getter 展开）
(memfn length)                     ; 把方法包装成函数 (map (memfn length) strs)
(System/getCurrentTimeMillis)
```

`memfn` 补"Clojure 函数世界里调 Java 方法"的缺口：`(map (memfn getName) files)`。

## 15.8 坑位清单

1. **`Math/abs` 参数类型**：`(Math/abs -2147483648)` int 溢出仍负（Java 老坑）——用 `long` 字面量或在 Clojure 侧 `(abs x)`（1.11+ 内置 `abs`）。
2. **`.length` vs `count`**：`.length` 反射+面向 String/数组；集合世界统一 `count`，字符串用 `count` 也行（内部优化）。
3. **`Date.` 每次调用一个新对象**：拿"当前时间"别在循环外 def 一次用到底——`(def now (Date.))` 是定义时刻的快照。
4. **proxy 里的 `this`**：方法体里访问字段用 `proxy-super` 调父类版本；忘记时行为诡异。
5. **可变 Java 集合逃逸**：`(java.util.ArrayList.)` 被 Clojure 代码共享时没有不可变保护——拿到手立刻 `(vec ...)` 封印。
6. **`Integer/parseInt` 静态方法**写成 `(.parseInt ...)` 会找实例方法 → 错。静态用 `/`，实例用 `.`。
7. **反射警告在运行前（编译时）打印**——看不到警告≠没反射，`set!` 要在**编译该函数之前**执行（脚本开头就打开）。
8. **数组 `aget` 返回装箱值**：热点循环里用 `^long` 提示或 `areduce`（23 章），不然装箱开销吃掉收益。

---

上一章：[14 并发与引用类型](14-concurrency.md) · 下一章：[16 文件与 I/O](16-file-io.md)
