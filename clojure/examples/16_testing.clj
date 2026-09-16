;; ==========================================================================
;; 16_testing.clj - 测试
;; ==========================================================================
;; 主题：使用 clojure.test 进行单元测试
;; 内容：
;;   1. deftest / is / are
;;   2. testing 上下文标签
;;   3. 异常测试
;;   4. 集合测试
;;   5. run-tests 执行测试
;;   6. 自定义断言
;;
;; 运行方式：
;;   clojure -M 16_testing.clj
;; ==========================================================================

(ns clojure-tutorial.16-testing
  (:require [clojure.test :as t :refer [deftest is are testing run-tests]]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 被测函数 ----
(defn factorial [n]
  (if (zero? n) 1 (* n (factorial (dec n)))))

(defn fib [n]
  (cond
    (= n 0) 0
    (= n 1) 1
    :else (+ (fib (dec n)) (fib (- n 2)))))

(defn safe-div [a b]
  {:pre [(not= b 0)]}
  (/ a b))

(defn classify [n]
  (cond
    (neg? n) :negative
    (zero? n) :zero
    :else :positive))

;; ---- 1) deftest / is ----
;; deftest 定义一个测试
;; is 断言，失败时报告

(section 1 "deftest / is")

(deftest test-factorial
  (is (= 1 (factorial 0)))
  (is (= 1 (factorial 1)))
  (is (= 2 (factorial 2)))
  (is (= 6 (factorial 3)))
  (is (= 24 (factorial 4)))
  (is (= 120 (factorial 5)))
  (is (= 720 (factorial 6))))

(run-tests)

;; ---- 2) are（参数化测试）----
;; are 可以同时测试多个输入/输出

(section 2 "are (Parameterized Tests)")

(deftest test-fib
  (are [n expected] (= expected (fib n))
    0 0
    1 1
    2 1
    3 2
    4 3
    5 5
    6 8
    7 13))

(run-tests)

;; ---- 3) testing 上下文标签 ----
;; testing 为一组断言提供上下文描述

(section 3 "testing Context")

(deftest test-classify
  (testing "negative numbers"
    (is (= :negative (classify -1)))
    (is (= :negative (classify -100))))
  (testing "zero"
    (is (= :zero (classify 0))))
  (testing "positive numbers"
    (is (= :positive (classify 1)))
    (is (= :positive (classify 100)))))

(run-tests)

;; ---- 4) 异常测试 ----
;; (is (thrown? ExceptionType body))
;; (is (thrown-with-msg? ExceptionType #regex body))

(section 4 "Exception Tests")

(deftest test-safe-div
  (is (= 2 (safe-div 10 5)))
  (is (= 5 (safe-div 25 5)))
  (is (thrown? AssertionError (safe-div 10 0))))

(run-tests)

;; ---- 5) 更多断言形式 ----

(section 5 "More Assertion Forms")

(deftest test-collections
  (testing "vector assertions"
    (is (= [1 2 3] [1 2 3]))
    (is (= [1 2 3] (range 1 4)))
    (is (not (= [1 2 3] [1 2 4]))))

  (testing "map assertions"
    (is (= {:a 1 :b 2} {:a 1 :b 2}))
    (is (contains? {:a 1 :b 2} :a)))

  (testing "set assertions"
    (is (contains? #{1 2 3} 2))
    (is (not (contains? #{1 2 3} 4))))

  (testing "nested assertions"
    (is (= {:name "Alice"
            :scores [90 85 92]}
           {:name "Alice"
            :scores [90 85 92]})))

  (testing "numeric assertions"
    (is (= 3.14 3.14))
    (is (< 0 0.5 1))                 ;; between 0 and 1
    (is (= 0.1 0.1))))

(run-tests)

;; ---- 6) 自定义断言 ----
;; 编写自定义断言函数

(section 6 "Custom Assertions")

(defn roughly=
  "Assert that two numbers are approximately equal (within epsilon)."
  ([a b] (roughly= a b 0.0001))
  ([a b epsilon]
   (< (Math/abs (- a b)) epsilon)))

(deftest test-roughly
  (is (roughly= 3.14 3.14159 0.01))
  (is (roughly= 1/3 (double 1/3) 0.0001))
  (is (roughly= (Math/sqrt 2) 1.41421 0.001)))

(run-tests)

;; ---- 7) 使用 with-redefs 进行 mock ----

(section 7 "Mocking with with-redefs")

(defn get-current-time []
  (System/currentTimeMillis))

(defn format-greeting [name]
  (str "Hello " name " at " (get-current-time)))

(deftest test-greeting
  (testing "with mocked time"
    (with-redefs [get-current-time (fn [] 12345)]
      (is (= "Hello Alice at 12345" (format-greeting "Alice"))))))

(run-tests)

;; ---- 8) 测试报告 ----

(section 8 "Test Report")

;; 手动定义测试并运行
(deftest comprehensive-test
  (testing "all features"
    (is (= 6 (factorial 3)) "factorial of 3")
    (is (= 5 (fib 5)) "fib of 5")
    (is (= :positive (classify 42)) "classify positive")
    (is (= :zero (classify 0)) "classify zero")
    (is (= :negative (classify -1)) "classify negative")
    (is (thrown? AssertionError (safe-div 1 0)) "safe-div by zero")
    (is (roughly= 3.14159 Math/PI 0.01) "pi is approximately 3.14")))

;; 运行所有测试并显示结果
(let [result (t/run-tests)]
  (say "")
  (say "Test results:")
  (say "  Tests run:" (:test result))
  (say "  Assertions:" (:pass result) "passed," (:fail result) "failed"))

(defn -main [& args]
  (println "")
  (println "==== 16 jieshu ===="))

(-main)
