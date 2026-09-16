;; ==========================================================================
;; 17_spec.clj - clojure.spec
;; ==========================================================================
;; 主题：使用 clojure.spec.alpha 进行数据验证和函数规范
;; 内容：
;;   1. s/def 定义 spec
;;   2. s/valid? / s/conform
;;   3. 组合 spec（s/and / s/or / s/keys）
;;   4. s/fdef 函数规范
;;   5. s/explain 数据解释
;;   6. 自定义谓词 spec
;;
;; 运行方式：
;;   clojure -M 17_spec.clj
;; ==========================================================================

(ns clojure-tutorial.17-spec
  (:require [clojure.spec.alpha :as s]
            [clojure.spec.test.alpha :as stest]
            [clojure.string :as str]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) s/def 定义 spec ----
;; spec 是对数据的描述
;; s/def 注册一个命名 spec（关键字必须是 namespaced）

(section 1 "s/def")

;; 基本类型 spec
(s/def ::id pos-int?)
(s/def ::name string?)
(s/def ::age (s/and int? #(>= % 0) #(< % 150)))
(s/def ::email (s/and string? #(re-find #"@" %)))
(s/def ::active boolean?)

(say "s/def registered specs:")
(say "  ::id:" ::id)
(say "  ::name:" ::name)
(say "  ::age:" ::age)

;; ---- 2) s/valid? / s/conform ----
;; s/valid? 返回布尔值
;; s/conform 返回符合 spec 的数据（可能变换）

(section 2 "s/valid? / s/conform")

(say "(s/valid? ::id 42):" (s/valid? ::id 42))
(say "(s/valid? ::id -1):" (s/valid? ::id -1))
(say "(s/valid? ::name \"Alice\"):" (s/valid? ::name "Alice"))
(say "(s/valid? ::age 30):" (s/valid? ::age 30))
(say "(s/valid? ::age -5):" (s/valid? ::age -5))
(say "(s/valid? ::age 200):" (s/valid? ::age 200))
(say "(s/valid? ::email \"a@b.com\"):" (s/valid? ::email "a@b.com"))
(say "(s/valid? ::email \"no-at-sign\"):" (s/valid? ::email "no-at-sign"))

(say "(s/conform ::age 30):" (s/conform ::age 30))
(say "(s/conform ::age -5):" (s/conform ::age -5))

;; ---- 3) 组合 spec ----
;; s/and：所有 spec 都满足
;; s/or：满足任意一个（返回 tagged value）
;; s/keys：验证映射的键

(section 3 "Combining Specs")

;; 映射 spec
(s/def ::person
  (s/keys :req [::id ::name ::age]
          :opt [::email ::active]))

(def valid-person {::id 1 ::name "Alice" ::age 30})
(def invalid-person {::id -1 ::name 42 ::age 30})

(say "(s/valid? ::person valid-person):" (s/valid? ::person valid-person))
(say "(s/valid? ::person invalid-person):" (s/valid? ::person invalid-person))

;; s/or：返回 tagged value
(s/def ::num-or-str (s/or :num number? :str string?))
(say "(s/conform ::num-or-str 42):" (s/conform ::num-or-str 42))
(say "(s/conform ::num-or-str \"hello\"):" (s/conform ::num-or-str "hello"))
(say "(s/conform ::num-or-str true):" (s/conform ::num-or-str true))

;; s/and：组合多个谓词
(s/def ::even-pos (s/and pos-int? even?))
(say "(s/valid? ::even-pos 2):" (s/valid? ::even-pos 2))
(say "(s/valid? ::even-pos 3):" (s/valid? ::even-pos 3))
(say "(s/valid? ::even-pos -2):" (s/valid? ::even-pos -2))

;; 集合 spec
(s/def ::tags (s/coll-of keyword? :kind set? :count 3))
(say "(s/valid? ::tags #{:a :b :c}):" (s/valid? ::tags #{:a :b :c}))
(say "(s/valid? ::tags #{:a :b}):" (s/valid? ::tags #{:a :b}))

;; ---- 4) s/explain ----
;; s/explain 解释为什么数据不符合 spec

(section 4 "s/explain")

(say "s/explain for invalid person:")
(s/explain ::person invalid-person)

(say "")
(say "s/explain for invalid age:")
(s/explain ::age 200)

;; ---- 5) s/fdef 函数规范 ----
;; s/fdef 定义函数规范
;; :args 参数 spec, :ret 返回值 spec, :fn 关系约束

(section 5 "s/fdef")

(defn add-numbers [a b]
  {:pre [(number? a) (number? b)]}
  (+ a b))

(s/fdef add-numbers
  :args (s/cat :a number? :b number?)
  :ret number?
  :fn (fn [{{:keys [a b]} :args ret :ret}]
        (= ret (+ a b))))

(say "add-numbers spec defined")
(say "(s/valid? (s/cat :a number? :b number?) [1 2]):"
     (s/valid? (s/cat :a number? :b number?) [1 2]))

;; ---- 6) 自定义谓词 spec ----
;; 使用函数作为 spec

(section 6 "Custom Predicate Specs")

(defn palindrome? [s]
  (let [s (str/lower-case (str s))]
    (= s (str/reverse s))))

(s/def ::palindrome palindrome?)

(say "(s/valid? ::palindrome \"radar\"):" (s/valid? ::palindrome "radar"))
(say "(s/valid? ::palindrome \"hello\"):" (s/valid? ::palindrome "hello"))
(say "(s/valid? ::palindrome \"level\"):" (s/valid? ::palindrome "level"))
(say "(s/valid? ::palindrome \"A\"):" (s/valid? ::palindrome "A"))

;; s/nilable：允许 nil
(s/def ::optional-name (s/nilable string?))
(say "(s/valid? ::optional-name \"hello\"):"
     (s/valid? ::optional-name "hello"))
(say "(s/valid? ::optional-name nil):"
     (s/valid? ::optional-name nil))

;; ---- 7) 生成器（简述）----
;; spec 也可以生成测试数据（需要 test.check）
;; 这里仅展示 spec 的查询能力

(section 7 "Spec Introspection")

(say "(s/form ::age):" (s/form ::age))
(say "(s/form ::person):" (s/form ::person))
(say "(s/form ::num-or-str):" (s/form ::num-or-str))
(say "(s/form ::even-pos):" (s/form ::even-pos))

;; ---- 8) 实际应用 ----

(section 8 "Practical Example")

(s/def ::config
  (s/keys :req [::port ::host]
          :opt [::debug ::timeout]))

(s/def ::port (s/and int? #(> % 0) #(< % 65536)))
(s/def ::host string?)
(s/def ::debug boolean?)
(s/def ::timeout pos-int?)

(defn validate-config [cfg]
  (if (s/valid? ::config cfg)
    {:status :ok :config cfg}
    {:status :error :problems (s/explain-str ::config cfg)}))

(say "(validate-config {::port 8080 ::host \"localhost\"}):"
     (validate-config {::port 8080 ::host "localhost"}))

(say "(validate-config {::port -1 ::host \"localhost\"}):"
     (validate-config {::port -1 ::host "localhost"}))

(defn -main [& args]
  (println "")
  (println "==== 17 jieshu ===="))

(-main)
