;; lein-lab/test/lein_lab/core_test.clj
;; lein test 会自动发现并运行 test/ 下所有 *-test 命名空间里的 deftest。
(ns lein-lab.core-test
  (:require [clojure.test :refer [deftest is testing]]
            [lein-lab.core :as core]
            [lein-lab.text :as text]))

(deftest normalize-test
  (testing "trim + lower-case"
    (is (= "hello" (text/normalize "  HeLLo ")))
    (is (= "abc def" (text/normalize "ABC DEF")))))

(deftest words-test
  (is (= ["the" "quick" "the"] (text/words "The quick, THE!")))
  (is (= [] (text/words "123 456 !!!")))
  (is (= ["a"] (text/words "a"))))

(deftest word-freq-test
  (testing "frequencies over words"
    (is (= {"the" 2 "dog" 1} (text/word-freq "the dog the")))
    (is (= {} (text/word-freq "")))))

(deftest sentence-count-test
  (is (= 3 (text/sentence-count "One. Two? Three!")))
  (is (= 0 (text/sentence-count ""))))

(deftest top-words-test
  (testing "sorted by count desc"
    (is (= [["b" 4] ["c" 3]] (core/top-words 2 "b a b c b c c b d"))))
    ;; d 只出现 1 次，取前 2 名不受并列影响
  (is (= [] (core/top-words 3 ""))))

(deftest palindrome-test
  (is (true? (core/palindrome? "racecar")))
  (is (true? (core/palindrome? "  A man a plan a canal Panama ")))
  (is (false? (core/palindrome? "fox")))
  (is (true? (core/palindrome? ""))))
