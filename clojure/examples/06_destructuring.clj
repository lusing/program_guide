;; ==========================================================================
;; 06_destructuring.clj - 解构
;; ==========================================================================
;; 主题：Clojure 的解构绑定
;; 内容：
;;   1. 顺序解构（向量/列表）
;;   2. 关联解构（映射/记录）
;;   3. 混合解构
;;   4. :as / :or / :keys
;;   5. 嵌套解构
;;   6. 函数参数中的解构
;;
;; 运行方式：
;;   clojure -M 06_destructuring.clj
;; ==========================================================================

(ns clojure-tutorial.06-destructuring)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 顺序解构 ----
;; 将集合按位置绑定到变量
;; 使用向量 [...] 进行绑定

(section 1 "Sequential Destructuring")

;; 基本顺序解构
(let [[a b c] [1 2 3]]
  (say "a:" a "b:" b "c:" c))

;; 不足的元素绑定为 nil
(let [[a b c] [1 2]]
  (say "a:" a "b:" b "c:" c))

;; 多余的元素被忽略
(let [[a b] [1 2 3 4 5]]
  (say "a:" a "b:" b))

;; :as 绑定整个集合
(let [[a b :as all] [1 2 3 4 5]]
  (say "a:" a "b:" b "all:" all))

;; :when 过滤（保持位置）
(let [[a b & rest :as all] [1 2 3 4 5]]
  (say "a:" a "b:" b "rest:" rest "all:" all))

;; 字符串也可以解构（按字符）
(let [[c1 c2 c3] "abc"]
  (say "c1:" c1 "c2:" c2 "c3:" c3))

;; ---- 2) 关联解构 ----
;; 将映射按键绑定到变量
;; 使用映射 {key1 val1 key2 val2 ...} 进行绑定

(section 2 "Associative Destructuring")

(def person {:name "Alice"
             :age 30
             :email "alice@example.com"
             :city "NYC"})

;; 基本关联解构
(let [{:keys [name age]} person]
  (say "name:" name "age:" age))

;; 使用 :as 绑定整个映射
(let [{:keys [name] :as p} person]
  (say "name:" name "all:" p))

;; :or 提供默认值
(let [{:keys [name phone] :or {phone "N/A"}} person]
  (say "name:" name "phone:" phone))

;; :keys 简写（当键是关键字时）
(let [{:keys [name age email]} person]
  (say "name:" name "age:" age "email:" email))

;; :strs 用于字符串键
(let [{:strs [name age]} {"name" "Bob" "age" 25}]
  (say "name:" name "age:" age))

;; :syms 用于符号键
(let [{:syms [x y]} '{x 1 y 2}]
  (say "x:" x "y:" y))

;; 直接用关键字作为绑定键
(let [{n :name a :age} person]
  (say "name:" n "age:" a))

;; ---- 3) 混合解构 ----
;; 顺序解构和关联解构可以嵌套

(section 3 "Mixed Destructuring")

(def data {:user {:name "Alice"
                  :roles [:admin :user]}
          :count 42})

(let [{[r1 r2] [:user :roles]} data]
  (say "r1:" r1 "r2:" r2))

;; 更复杂的嵌套
(let [{:keys [user count]} data
      {:keys [name roles]} user
      [r1 r2] roles]
  (say "name:" name "r1:" r1 "r2:" r2 "count:" count))

;; ---- 4) 嵌套顺序解构 ----

(section 4 "Nested Sequential Destructuring")

(def nested [[1 2 3] [4 5 6] [7 8 9]])

(let [[[a1 a2 a3]
       [b1 b2 b3]
       [c1 c2 c3]] nested]
  (say "a1:" a1 "b2:" b2 "c3:" c3))

;; 只取需要的元素
(let [[[x] _ [z _ _]] nested]
  (say "x:" x "z:" z))

;; ---- 5) :or 与 :keys 组合 ----

(section 5 ":or with :keys")

(defn greet-user
  "Greet a user with optional fields."
  [{:keys [name title greeting] :or {title "Mr." greeting "Hello"}}]
  (str greeting ", " title " " name))

(say (greet-user {:name "Smith"}))
(say (greet-user {:name "Jones" :title "Dr."}))
(say (greet-user {:name "Brown" :greeting "Hi" :title "Ms."}))

;; ---- 6) 函数参数中的解构 ----
;; 解构可以直接用在函数参数中

(section 6 "Destructuring in Function Params")

(defn distance
  "Calculate distance between two points."
  [[x1 y1] [x2 y2]]
  (let [dx (- x2 x1)
        dy (- y2 y1)]
    (Math/sqrt (+ (* dx dx) (* dy dy)))))

(say "(distance [0 0] [3 4]):" (distance [0 0] [3 4]))

(defn make-url
  "Build URL from options map."
  [{:keys [host port path] :or {port 80 path "/"}}]
  (str "http://" host ":" port path))

(say (make-url {:host "example.com"}))
(say (make-url {:host "example.com" :port 8080}))
(say (make-url {:host "example.com" :port 443 :path "/api/v1"}))

;; ---- 7) 实用示例 ----

(section 7 "Practical Examples")

;; 交换变量
(let [[a b] [1 2]
      [a b] [b a]]
  (say "swapped: a=" a "b=" b))

;; 从函数返回的映射中解构
(defn parse-date [s]
  (let [[y m d] (clojure.string/split s #"-")]
    {:year y :month m :day d}))

(let [{:keys [year month day]} (parse-date "2024-03-15")]
  (say "year:" year "month:" month "day:" day))

;; rest 参数解构
(defn process-items
  "First item special, rest processed together."
  [[first & rest]]
  {:first first :rest rest :count (inc (count rest))})

(say (process-items [:a :b :c :d]))

(defn -main [& args]
  (println "")
  (println "==== 06 jieshu ===="))

(-main)
