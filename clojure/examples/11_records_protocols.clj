;; ==========================================================================
;; 11_records_protocols.clj - 记录与协议
;; ==========================================================================
;; 主题：Clojure 的记录（Record）和协议（Protocol）
;; 内容：
;;   1. defrecord 定义记录
;;   2. 记录的字段与方法
;;   3. defprotocol 定义协议
;;   4. extend-protocol / extend-type
;;   5. reify 创建匿名类型
;;   6. 记录 vs 映射
;;
;; 运行方式：
;;   clojure -M 11_records_protocols.clj
;; ==========================================================================

(ns clojure-tutorial.11-records-protocols
  (:import [java.util Date]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) defrecord 定义记录 ----
;; 记录是带有命名字段的不可变数据类型
;; 类似映射但更高效，且可以有类型

(section 1 "defrecord")

(defrecord Person [name age email])
(defrecord Point [x y])
(defrecord Rectangle [width height])

;; 创建记录
(def p1 (->Person "Alice" 30 "alice@example.com"))
(def p2 (map->Person {:name "Bob" :age 25 :email "bob@example.com"}))

(say "p1:" p1)
(say "p2:" p2)
(say "(.name p1):" (.name p1))
(say "(:name p1):" (:name p1))
(say "(:age p1):" (:age p1))

;; 记录是映射
(say "(map? p1):" (map? p1))
(say "(get p1 :name):" (get p1 :name))
(say "(assoc p1 :phone \"123\"):" (assoc p1 :phone "123"))
(say "(dissoc p1 :email):" (dissoc p1 :email))

;; ---- 2) 记录与协议结合 ----
;; defprotocol 定义一组方法签名
;; 记录可以实现协议

(section 2 "defrecord with Protocol")

(defprotocol Shape
  (area [this])
  (perimeter [this])
  (describe [this]))

(defrecord Circle [radius]
  Shape
  (area [this] (* Math/PI radius radius))
  (perimeter [this] (* 2 Math/PI radius))
  (describe [this] (str "Circle with radius " radius)))

(defrecord Square [side]
  Shape
  (area [this] (* side side))
  (perimeter [this] (* 4 side))
  (describe [this] (str "Square with side " side)))

(def c1 (->Circle 5))
(def s1 (->Square 4))

(say "(area c1):" (area c1))
(say "(perimeter c1):" (perimeter c1))
(say "(describe c1):" (describe c1))
(say "(area s1):" (area s1))
(say "(perimeter s1):" (perimeter s1))
(say "(describe s1):" (describe s1))

;; 多态
(def shapes [(->Circle 3) (->Square 4) (->Circle 1)])
(doseq [shape shapes]
  (say (describe shape) "area =" (area shape)))

;; ---- 3) defprotocol 独立定义 ----
;; 协议可以独立定义，然后扩展到已有类型

(section 3 "defprotocol standalone")

(defprotocol Drawable
  (draw [this])
  (render [this ctx]))

;; extend-type 为已有类型实现协议
(extend-type String
  Drawable
  (draw [this] (str "Drawing text: " this))
  (render [this ctx] (str "Render text in " ctx ": " this)))

(extend-type Number
  Drawable
  (draw [this] (str "Drawing number: " this))
  (render [this ctx] (str "Render number in " ctx ": " this)))

(say "(draw \"hello\"):" (draw "hello"))
(say "(render \"hello\" \"canvas\"):" (render "hello" "canvas"))
(say "(draw 42):" (draw 42))
(say "(render 42 \"canvas\"):" (render 42 "canvas"))

;; ---- 4) extend-protocol ----
;; extend-protocol 一次性为多个类型实现协议

(section 4 "extend-protocol")

(defprotocol Stringifiable
  (to-string [this]))

(extend-protocol Stringifiable
  java.lang.String
  (to-string [this] this)

  java.lang.Number
  (to-string [this] (str "Number: " this))

  java.lang.Boolean
  (to-string [this] (str "Boolean: " this))

  nil
  (to-string [_] "null")

  java.util.Date
  (to-string [this] (str "Date: " (.getTime this)))

  clojure.lang.PersistentVector
  (to-string [this] (str "Vector: " (count this) " items")))

(say (to-string "hello"))
(say (to-string 42))
(say (to-string true))
(say (to-string nil))
(say (to-string (Date.)))
(say (to-string [1 2 3]))

;; ---- 5) reify 创建匿名类型 ----
;; reify 创建一个实现协议的匿名对象
;; 类似于 Java 的匿名内部类

(section 5 "reify")

(defn make-counter-shape
  "Create a shape with a counter using reify."
  [label]
  (let [count (atom 0)]
    (reify Shape
      (area [this] (swap! count inc) (* @count @count))
      (perimeter [this] (* 4 (swap! count inc)))
      (describe [this] (str label " (calls: " @count ")")))))

(def cs (make-counter-shape "Dynamic"))
(say (describe cs) "area:" (area cs))
(say (describe cs) "area:" (area cs))
(say (describe cs) "perimeter:" (perimeter cs))

;; reify 实现多个协议
(defn make-logger [name]
  (let [logs (atom [])]
    (reify
      Drawable
      (draw [this] (swap! logs conj "draw") (str name " drawn"))
      (render [this ctx] (swap! logs conj "render") (str name " in " ctx))

      clojure.lang.IDeref
      (deref [_] @logs))))

(def logger (make-logger "Widget"))
(say (draw logger))
(say (render logger "page"))
(say "Logs:" @logger)

;; ---- 6) 记录 vs 映射 ----
;; 记录：有类型、有字段声明、更高效、可参与协议
;; 映射：无类型、灵活、通用

(section 6 "Records vs Maps")

(def person-map {:name "Alice" :age 30})
(def person-record (->Person "Alice" 30 "alice@example.com"))

(say "Map type:" (type person-map))
(say "Record type:" (type person-record))
(say "Map? (map? person-map):" (map? person-map))
(say "Map? (map? person-record):" (map? person-record))
(say "Record? (instance? Person person-record):"
     (instance? Person person-record))
(say "Record class:" (.getName (class person-record)))

;; 记录可以用 -> 和 map-> 构造
(say "(->Person \"X\" 20 \"x@x.com\"):" (->Person "X" 20 "x@x.com"))
(say "(map->Person {:name \"Y\" :age 21}):"
     (map->Person {:name "Y" :age 21}))

(defn -main [& args]
  (println "")
  (println "==== 11 jieshu ===="))

(-main)
