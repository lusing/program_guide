;; ==========================================================================
;; 13_java_interop.clj - Java 互操作
;; ==========================================================================
;; 主题：Clojure 与 Java 的无缝互操作
;; 内容：
;;   1. 实例方法与字段（.）
;;   2. 静态方法与字段（/）
;;   3. .. 线性调用
;;   4. doto 流式调用
;;   5. 创建 Java 对象
;;   6. 异常处理
;;   7. proxy 动态代理
;;   8. gen-class AOT 编译
;;
;; 运行方式：
;;   clojure -M 13_java_interop.clj
;; ==========================================================================

(ns clojure-tutorial.13-java-interop
  (:import [java.util ArrayList HashMap Date UUID]
           [java.io File]
           [java.text SimpleDateFormat]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 实例方法与字段 ----
;; (.method obj args...) 调用实例方法
;; (.field obj) 访问字段
;; 也可以用 (. obj method args...) 形式

(section 1 "Instance Methods and Fields")

(def sb (StringBuffer. "Hello"))
(. sb (append ", World!"))
(. sb (append " Clojure!"))
(say "StringBuffer:" (.toString sb))

(def s "Hello, World!")
(say "(.length s):" (.length s))
(say "(.substring s 0 5):" (.substring s 0 5))
(say "(.toUpperCase s):" (.toUpperCase s))
(say "(.charAt s 0):" (.charAt s 0))
(say "(.equals s s):" (.equals s s))
(say "(.indexOf s \"World\"):" (.indexOf s "World"))

;; ---- 2) 静态方法与字段 ----
;; (Class/method args) 或 (Class/staticField)
;; / 是静态成员访问符号

(section 2 "Static Methods and Fields")

(say "(Math/sqrt 16):" (Math/sqrt 16))
(say "(Math/PI):" Math/PI)
(say "(Math/max 3 5):" (Math/max 3 5))
(say "(Math/min 3 5):" (Math/min 3 5))
(say "(Math/abs -5):" (Math/abs -5))
(say "(Math/ceil 3.2):" (Math/ceil 3.2))
(say "(Math/floor 3.8):" (Math/floor 3.8))
(say "(Math/round 3.5):" (Math/round 3.5))
(say "(Math/pow 2 10):" (Math/pow 2 10))
(say "(Math/random):" (Math/random))
(say "(Integer/MAX_VALUE):" Integer/MAX_VALUE)
(say "(Integer/parseInt \"42\"):" (Integer/parseInt "42"))
(say "(Integer/toString 42 16):" (Integer/toString 42 16))
(say "(System/getProperty \"java.version\"):"
     (System/getProperty "java.version"))
(say "(System/getProperty \"os.name\"):"
     (System/getProperty "os.name"))

;; ---- 3) .. 线性调用 ----
;; .. 链式调用，类似 Java 的 a.b().c()
;; (.. obj (method1) (method2) (method3))

(section 3 "Chain Calls (..)")

(def f (File. "/tmp/test.txt"))
(say "(.. f (getName)):" (.. f (getName)))
(say "(.. f (getAbsolutePath)):" (.. f (getAbsolutePath)))
(say "(.. f (getParent)):" (.. f (getParent)))
(say "(.. f (getParentFile) (getName)):"
     (.. f (getParentFile) (getName)))

;; 线程优先宏 -> 也可以做类似的事
(say "(-> f .getName):" (-> f .getName))
(say "(-> \"hello\" .toUpperCase):" (-> "hello" .toUpperCase))

;; ---- 4) doto 流式调用 ----
;; doto 对同一对象连续调用方法
;; 返回对象本身

(section 4 "doto")

(def list (doto (ArrayList.)
            (.add "first")
            (.add "second")
            (.add "third")))
(say "ArrayList:" (.toString list))
(say "Size:" (.size list))
(say "Get 0:" (.get list 0))

(def map (doto (HashMap.)
           (.put :a 1)
           (.put :b 2)
           (.put :c 3)))
(say "HashMap keys:" (vec (.keySet map)))
(say "Get :a:" (.get map :a))

;; ---- 5) 创建 Java 对象 ----
;; (Class. args) 或 (new Class args)

(section 5 "Creating Java Objects")

(def date (Date.))
(say "Date:" (.toString date))
(say "Time:" (.getTime date))

(def uuid (UUID/randomUUID))
(say "UUID:" (.toString uuid))

(def fmt (SimpleDateFormat. "yyyy-MM-dd"))
(say "Formatted date:" (.format fmt date))

;; 文件操作
(def dir (File. "/tmp"))
(say "Dir exists?:" (.exists dir))
(say "Is dir?:" (.isDirectory dir))
(say "Is file?:" (.isFile dir))
(say "List files:" (count (.listFiles dir)))

;; 数组
(def arr (int-array [1 2 3 4 5]))
(say "(alength arr):" (alength arr))
(say "(aget arr 0):" (aget arr 0))
(say "(aget arr 2):" (aget arr 2))
(aset arr 0 99)
(say "After aset:" (aget arr 0))

;; ---- 6) 异常处理 ----
;; try / catch / finally
;; Clojure 不要求 checked exception 声明

(section 6 "Exception Handling")

(defn safe-parse [s]
  (try
    (Integer/parseInt s)
    (catch NumberFormatException e
      (say "  Caught:" (.getMessage e))
      -1)
    (finally
      (say "  (finally block runs)"))))

(say "(safe-parse \"42\"):" (safe-parse "42"))
(say "(safe-parse \"abc\"):" (safe-parse "abc"))

;; 抛出异常
(defn check-age [age]
  (if (< age 0)
    (throw (IllegalArgumentException. "Age cannot be negative"))
    (str "Age: " age)))

(say "(check-age 25):" (check-age 25))
(try
  (check-age -1)
  (catch IllegalArgumentException e
    (say "Caught:" (.getMessage e))))

;; ex-info 和 ex-data
(try
  (throw (ex-info "Custom error" {:code 42 :reason "testing"}))
  (catch clojure.lang.ExceptionInfo e
    (say "ex-message:" (ex-message e))
    (say "ex-data:" (ex-data e))))

;; with-open 自动关闭资源
(defn read-file [path]
  (with-open [r (clojure.java.io/reader path)]
    (vec (line-seq r))))

;; ---- 7) proxy 动态代理 ----
;; proxy 创建实现接口或继承类的匿名对象

(section 7 "proxy")

(def comparator
  (proxy [java.util.Comparator] []
    (compare [a b]
      (cond
        (< a b) -1
        (> a b) 1
        :else 0))))

(say "(.compare comparator 1 2):" (.compare comparator 1 2))
(say "(.compare comparator 3 3):" (.compare comparator 3 3))
(say "(.compare comparator 5 3):" (.compare comparator 5 3))

;; proxy 实现 Runnable
(def runner
  (proxy [Runnable] []
    (run []
      (println "Running in proxy Runnable!"))))

(.run runner)

;; ---- 8) 实用互操作示例 ----

(section 8 "Practical Interop")

;; StringBuilder
(defn build-string [parts]
  (let [sb (StringBuffer.)]
    (doseq [p parts]
      (.append sb p))
    (.toString sb)))

(say "(build-string [\"a\" \"b\" \"c\"]):" (build-string ["a" "b" "c"]))

;; Java 集合操作
(def jlist (java.util.ArrayList. [1 2 3 4 5]))
(say "Java list (.size):" (.size jlist))
(say "Java list (.get 2):" (.get jlist 2))
(say "Java list (.contains 3):" (.contains jlist 3))
(say "Convert to Clojure seq:" (vec (.toArray jlist)))

;; 字符串格式化
(say "(format \"%s = %d, %.2f\" \"pi\" 3 3.14159):"
     (format "%s = %d, %.2f" "pi" 3 3.14159))

;; 正则表达式
(defn regex-demo []
  (let [text "Clojure 1.12.6 on JVM 26"]
    (say "re-find:" (re-find #"\d+\.\d+\.\d+" text))
    (say "re-seq:" (vec (re-seq #"\d+" text)))
    (say "re-matches:" (re-matches #"Clojure.*" text))
    (say "clojure.string/replace:"
         (clojure.string/replace text #"\d+" "#"))))

(regex-demo)

(defn -main [& args]
  (println "")
  (println "==== 13 jieshu ===="))

(-main)
