;; ==========================================================================
;; 15_namespaces.clj - 命名空间
;; ==========================================================================
;; 主题：Clojure 的命名空间系统
;; 内容：
;;   1. ns 宏
;;   2. require / use / refer
;;   3. :as 别名
;;   4. :refer 引入特定符号
;;   5. def / defn 的命名空间
;;   6. 私有函数
;;   7. 命名空间切换
;;
;; 运行方式：
;;   clojure -M 15_namespaces.clj
;; ==========================================================================

(ns clojure-tutorial.15-namespaces
  (:require [clojure.string :as str]
            [clojure.set :as set]
            [clojure.java.io :as io]
            [clojure.walk :as walk]
            [clojure.pprint :as pp])
  (:import [java.util Date]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) ns 宏 ----
;; ns 是命名空间定义的主要方式
;; 代替了 require / use / import

(section 1 "ns macro")

(say "*ns*:" *ns*)
(say "*ns* name:" (ns-name *ns*))

;; ---- 2) require / :as / :refer ----
;; require 加载其他命名空间
;; :as 给命名空间起别名
;; :refer 引入特定符号

(section 2 "require with :as and :refer")

;; 使用别名的命名空间
(say "(str/upper-case \"hello\"):" (str/upper-case "hello"))
(say "(str/lower-case \"HELLO\"):" (str/lower-case "HELLO"))
(say "(str/split \"a,b,c\" #\",\"):" (str/split "a,b,c" #","))
(say "(str/join \"-\" [1 2 3]):" (str/join "-" [1 2 3]))
(say "(str/trim \"  hi  \"):" (str/trim "  hi  "))
(say "(str/replace \"hello world\" \"world\" \"Clojure\"):"
     (str/replace "hello world" "world" "Clojure"))

;; set 命名空间
(say "(set/union #{1 2} #{3 4}):" (set/union #{1 2} #{3 4}))
(say "(set/difference #{1 2 3} #{2 3}):" (set/difference #{1 2 3} #{2 3}))

;; ---- 3) clojure.walk ----
;; 遍历和转换嵌套数据结构

(section 3 "clojure.walk")

(def nested {:user {:name "Alice"
                    :roles [{:id 1 :name "admin"}
                            {:id 2 :name "user"}]}
            :count 42})

;; walk/postwalk：深度优先遍历
(def transformed (walk/postwalk
                   (fn [x]
                     (cond
                       (keyword? x) (keyword "ns" (name x))
                       (string? x) (str/upper-case x)
                       :else x))
                   nested))

(say "Postwalk transformed:" transformed)

;; walk/prewalk：先处理再遍历
(def keys-as-strings
  (walk/postwalk
    (fn [x]
      (if (map? x)
        (into {} (map (fn [[k v]] [(name k) v]) x))
        x))
    nested))
(say "Keys as strings:" keys-as-strings)

;; ---- 4) clojure.pprint ----
;; 美化打印

(section 4 "clojure.pprint")

(def data {:person {:name "Alice"
                     :age 30
                     :address {:street "123 Main St"
                               :city "NYC"
                               :zip "10001"}}
          :tags [:admin :user :premium]})

(say "pprint output:")
(pp/pprint data)

(say "cl-format (table):")
(pp/cl-format true "~{~a~^, ~}" (range 10))

;; ---- 5) 命名空间查询 ----

(section 5 "Namespace Queries")

;; 当前命名空间的公共符号
(say "ns-publics (first 5):"
     (vec (take 5 (keys (ns-publics *ns*)))))

;; 引入的别名
(say "ns-aliases:" (into {} (ns-aliases *ns*)))

;; 所有命名空间
(say "All namespaces (first 5):"
     (vec (take 5 (map ns-name (all-ns)))))

;; 查找符号
(say "(ns-resolve 'clojure.string 'upper-case):"
     (ns-resolve 'clojure.string 'upper-case))

;; ---- 6) 私有函数 ----
;; defn- 定义私有函数（带破折号后缀）
;; defmacro- 定义私有宏

(section 6 "Private Functions")

(defn- private-helper [x] (* x 2))

(defn public-fn [x]
  (private-helper x))

(say "(public-fn 5):" (public-fn 5))

;; 私有函数不能从其他命名空间直接调用
;; 但可以通过 @#' 获取（不推荐用于生产）

;; ---- 7) in-ns / create-ns ----
;; in-ns 切换到指定命名空间
;; create-ns 创建但不切换

(section 7 "Namespace Management")

;; 在当前命名空间中定义
(def x 42)
(say "x defined in" (ns-name *ns*) "is" x)

;; 查看所有公共符号
(say "All public symbols:")
(doseq [sym (sort (keys (ns-publics *ns*)))]
  (say " " sym))

;; ---- 8) 实用示例 ----

(section 8 "Practical Example")

;; 使用多个命名空间协作
(defn process-data [records]
  (->> records
       (map #(update % :name str/upper-case))
       (map #(select-keys % [:name :age]))
       (sort-by :age)
       vec))

(def sample-data [{:name "alice" :age 30 :email "a@x.com"}
                  {:name "bob" :age 25 :email "b@x.com"}
                  {:name "carol" :age 35 :email "c@x.com"}])

(say "Processed:" (process-data sample-data))

;; 使用 io 和 Date
(defn timestamp []
  (.format
    (java.text.SimpleDateFormat. "yyyy-MM-dd HH:mm:ss")
    (Date.)))

(say "Timestamp:" (timestamp))

(defn -main [& args]
  (println "")
  (println "==== 15 jieshu ===="))

(-main)
