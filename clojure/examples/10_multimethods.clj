;; ==========================================================================
;; 10_multimethods.clj - 多方法（Multimethods）
;; ==========================================================================
;; 主题：Clojure 的多方法与层级关系
;; 内容：
;;   1. defmulti / defmethod
;;   2. 分发函数
;;   3. 层级关系（derive / isa?）
;;   4. 多维度分发
;;   5. 默认方法
;;   6. 多方法 vs 协议
;;
;; 运行方式：
;;   clojure -M 10_multimethods.clj
;; ==========================================================================

(ns clojure-tutorial.10-multimethods)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) defmulti / defmethod ----
;; 多方法允许根据分发函数的结果选择不同的实现
;; 类似于其他语言的方法重载，但更灵活

(section 1 "defmulti / defmethod")

;; 定义一个多方法，按 :shape 分发
(defmulti area :shape)

;; 为每种形状定义方法
(defmethod area :rectangle [{:keys [width height]}]
  (* width height))

(defmethod area :circle [{:keys [radius]}]
  (* Math/PI radius radius))

(defmethod area :triangle [{:keys [base height]}]
  (/ (* base height) 2))

(say "(area {:shape :rectangle :width 3 :height 4}):"
     (area {:shape :rectangle :width 3 :height 4}))
(say "(area {:shape :circle :radius 5}):"
     (area {:shape :circle :radius 5}))
(say "(area {:shape :triangle :base 4 :height 3}):"
     (area {:shape :triangle :base 4 :height 3}))

;; ---- 2) 分发函数 ----
;; 分发函数可以是任何函数
;; 甚至可以使用多个属性组合

(section 2 "Dispatch Functions")

;; 按 :type 和 :material 组合分发
(defmulti describe-shape (fn [shape] [(:type shape) (:material shape)]))

(defmethod describe-shape [:box :wood]
  [_] "A wooden box")
(defmethod describe-shape [:box :metal]
  [_] "A metal box")
(defmethod describe-shape [:sphere :glass]
  [_] "A glass sphere")
(defmethod describe-shape :default
  [shape] (str "Unknown shape: " (:type shape) " made of " (:material shape)))

(say (describe-shape {:type :box :material :wood}))
(say (describe-shape {:type :box :material :metal}))
(say (describe-shape {:type :sphere :material :glass}))
(say (describe-shape {:type :cone :material :plastic}))

;; ---- 3) 层级关系 ----
;; Clojure 有关键字的层级关系系统
;; derive 建立关系，isa? 检查关系
;; 多方法可以利用层级关系进行分发

(section 3 "Hierarchy (derive / isa?)")

;; 建立层级关系（derive 要求关键字有命名空间）
;; ::dog 和 ::cat 都是 ::animal
;; ::animal 是 ::creature
(derive ::dog ::animal)
(derive ::cat ::animal)
(derive ::animal ::creature)
(derive ::bird ::creature)

;; isa? 检查关系
(say "(isa? ::dog ::animal):" (isa? ::dog ::animal))
(say "(isa? ::dog ::creature):" (isa? ::dog ::creature))
(say "(isa? ::cat ::animal):" (isa? ::cat ::animal))
(say "(isa? ::bird ::animal):" (isa? ::bird ::animal))
(say "(isa? ::bird ::creature):" (isa? ::bird ::creature))

;; parents / ancestors / descendants
(say "(parents ::dog):" (parents ::dog))
(say "(ancestors ::dog):" (ancestors ::dog))
(say "(descendants ::creature):" (descendants ::creature))

;; ---- 4) 利用层级关系的多方法 ----

(section 4 "Multimethods with Hierarchy")

(defmulti speak :species)

(defmethod speak ::dog [_] "Woof!")
(defmethod speak ::cat [_] "Meow!")
;; ::dog 和 ::cat 是 ::animal，所以这里处理所有动物
(defmethod speak ::animal [_] "Some animal sound")
;; ::creature 是所有生物的父级
(defmethod speak ::creature [_] "...")

(say "(speak {:species ::dog}):" (speak {:species ::dog}))
(say "(speak {:species ::cat}):" (speak {:species ::cat}))
;; ::bird 不是 ::animal 但是 ::creature
(say "(speak {:species ::bird}):" (speak {:species ::bird}))

;; ---- 5) 默认方法 :default ----
;; 当没有匹配的方法时，使用 :default

(section 5 "Default Methods")

(defmulti classify-size :size)
(defmethod classify-size :small [_] "Small item")
(defmethod classify-size :medium [_] "Medium item")
(defmethod classify-size :large [_] "Large item")
(defmethod classify-size :default [item]
  (str "Unknown size: " (:size item)))

(say (classify-size {:size :small}))
(say (classify-size {:size :medium}))
(say (classify-size {:size :large}))
(say (classify-size {:size :extra-large}))

;; ---- 6) remove-method / prefer-method ----
;; 当多个方法匹配时，可以用 prefer-method 指定优先级

(section 6 "prefer-method")

;; 创建一个新的多方法演示 prefer-method
(defmulti process (fn [x] (class x)))

(defmethod process java.lang.String [_] "Processing string")
(defmethod process java.lang.Number [_] "Processing number")
(defmethod process java.lang.Object [_] "Processing object")

(say "(process \"hello\"):" (process "hello"))
(say "(process 42):" (process 42))
(say "(process true):" (process true))

;; ---- 7) 多方法 vs 协议 ----
;; 多方法：开放、灵活、按值分发、运行时开销略大
;; 协议：封闭、类型驱动、编译时优化、性能更好

(section 7 "Multimethods vs Protocols")

;; 多方法优势：
;; - 可以按任意属性分发
;; - 支持层级关系
;; - 可以为已有类型添加方法
;; - 不需要定义新类型

;; 多方法劣势：
;; - 性能比协议稍差
;; - 分发逻辑分散

;; 协议优势：
;; - 性能好（编译时优化）
;; - 类型安全
;; - 更好的工具支持

;; 协议劣势：
;; - 只能按类型分发
;; - 需要定义新类型（record/type）

(defn -main [& args]
  (println "")
  (println "==== 10 jieshu ===="))

(-main)
