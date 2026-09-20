;; lein-lab/src/lein_lab/core.clj
;; :gen-class 让 AOT 编译为这个命名空间生成 Java 类，
;; uberjar 的 Main-Class 就落在 lein-lab.core 上。
(ns lein-lab.core
  "mini 文本统计工具：lein run / java -jar 的入口。"
  (:require [lein-lab.text :as text])
  (:gen-class))

(defn top-words
  "返回 [词 次数] 的前 n 名（按次数降序）。"
  [n s]
  (vec (take n (sort-by (comp - val) (text/word-freq s)))))

(defn palindrome?
  "判断整句（忽略大小写与空白）是否回文。"
  [s]
  (let [c (clojure.string/replace (text/normalize s) #"\s+" "")]
    (= c (clojure.string/reverse c))))

(def ^:private sample
  "The quick brown fox jumps over the lazy dog.
   The dog barks and the fox runs away.")

(defn -main
  "程序入口。lein run -- args... / java -jar xxx.jar args..."
  [& args]
  (println "lein-lab" (System/getProperty "lein-lab.version" "1.0.0")
           "| Clojure" (clojure-version)
           "| Java" (System/getProperty "java.version"))
  (println "argv:" (vec args))
  (println)
  (println "-- sample text --")
  (println sample)
  (println)
  (println "word count:      " (count (text/words sample)))
  (println "unique words:    " (count (text/word-freq sample)))
  (println "sentences:       " (text/sentence-count sample))
  (println "top 3 words:     " (top-words 3 sample))
  (println "palindrome? fox: " (palindrome? "fox"))
  (println "palindrome? Anna:" (palindrome? "  Anna "))
  (println "")
  (println "==== LAB jieshu ===="))
