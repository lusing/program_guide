;; ==========================================================================
;; 14_file_io.clj - 文件与 I/O
;; ==========================================================================
;; 主题：Clojure 的文件读写与数据持久化
;; 内容：
;;   1. slurp / spit（简单读写）
;;   2. with-open（资源管理）
;;   3. 行读写（line-seq）
;;   4. clojure.java.io
;;   5. EDN 读写
;;   6. 临时文件
;;   7. 文件系统操作
;;
;; 运行方式：
;;   clojure -M 14_file_io.clj
;; ==========================================================================

(ns clojure-tutorial.14-file-io
  (:require [clojure.java.io :as io]
            [clojure.edn :as edn])
  (:import [java.io File BufferedWriter FileWriter PushbackReader]
           [java.nio.file Files]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) slurp / spit ----
;; slurp：读取整个文件为字符串
;; spit：将字符串写入文件

(section 1 "slurp / spit")

(def tmp-dir "/tmp/clojure-tutorial")
(.mkdirs (File. tmp-dir))

(def text-file (str tmp-dir "/test.txt"))

;; 写入
(spit text-file "Line 1\nLine 2\nLine 3\n")
(say "Wrote to" text-file)

;; 读取
(say "slurp:" (slurp text-file))

;; 追加写入
(spit text-file "Line 4 (appended)\n" :append true)
(say "After append:" (slurp text-file))

;; ---- 2) with-open ----
;; with-open 确保资源自动关闭
;; 用于需要更精细控制的场景

(section 2 "with-open")

(defn write-lines [path lines]
  (with-open [w (io/writer path)]
    (doseq [line lines]
      (.write w line)
      (.write w "\n"))))

(write-lines (str tmp-dir "/lines.txt")
             ["Alpha" "Beta" "Gamma" "Delta"])

(say "Read back:" (slurp (str tmp-dir "/lines.txt")))

;; ---- 3) line-seq ----
;; line-seq 惰性读取文件的行
;; 适合大文件

(section 3 "line-seq")

(defn count-lines [path]
  (with-open [r (io/reader path)]
    (count (line-seq r))))

(defn read-first-n [path n]
  (with-open [r (io/reader path)]
    (vec (take n (line-seq r)))))

(say "Line count:" (count-lines (str tmp-dir "/lines.txt")))
(say "First 2 lines:" (read-first-n (str tmp-dir "/lines.txt") 2))

;; ---- 4) clojure.java.io ----
;; io/reader / io/writer / io/file
;; 更灵活的 I/O 操作

(section 4 "clojure.java.io")

(say "(io/file path):" (io/file tmp-dir))
(say "(.exists (io/file tmp-dir)):" (.exists (io/file tmp-dir)))
(say "(.isDirectory (io/file tmp-dir)):" (.isDirectory (io/file tmp-dir)))

;; io/copy 复制文件
(io/copy (io/file (str tmp-dir "/lines.txt"))
         (io/file (str tmp-dir "/lines-copy.txt")))
(say "Copied file content:" (slurp (str tmp-dir "/lines-copy.txt")))

;; io/resource 从 classpath 读取
;; (io/resource "clojure/core.clj") 在 classpath 中查找

;; ---- 5) EDN 读写 ----
;; EDN (Extensible Data Notation) 是 Clojure 的数据格式
;; 类似 JSON，但支持 Clojure 的所有数据类型

(section 5 "EDN Read/Write")

(def data {:name "Alice"
           :age 30
           :roles [:admin :user]
           :address {:city "NYC" :zip "10001"}
           :active true
           :score 3.14})

(def edn-file (str tmp-dir "/data.edn"))

;; 写入 EDN
(spit edn-file (pr-str data))
(say "EDN content:" (slurp edn-file))

;; 读取 EDN
(def loaded-data (edn/read-string (slurp edn-file)))
(say "Loaded name:" (:name loaded-data))
(say "Loaded roles:" (:roles loaded-data))
(say "Loaded address:" (:address loaded-data))
(say "Equal to original? =" (= data loaded-data))

;; 使用 PushbackReader 更安全地读取
(with-open [r (PushbackReader. (io/reader edn-file))]
  (say "Read with PushbackReader:" (edn/read r)))

;; ---- 6) 临时文件 ----

(section 6 "Temporary Files")

(def tmp-file (File/createTempFile "clojure-tut" ".tmp"))
(say "Temp file:" (.getAbsolutePath tmp-file))
(spit tmp-file "temporary content")
(say "Temp content:" (slurp tmp-file))
(.delete tmp-file)
(say "Deleted? (not exists):" (not (.exists tmp-file)))

;; ---- 7) 文件系统操作 ----

(section 7 "Filesystem Operations")

;; 列出目录内容
(defn list-dir [path]
  (let [f (File. path)]
    (if (.isDirectory f)
      (map #(.getName %) (.listFiles f))
      [])))

(say "Listing" tmp-dir ":" (vec (list-dir tmp-dir)))

;; 递归遍历
(defn walk-dir [path]
  (let [f (File. path)]
    (cond
      (.isFile f) [path]
      (.isDirectory f)
      (mapcat walk-dir
              (map #(.getAbsolutePath %) (.listFiles f)))
      :else [])))

(say "Walk:" (vec (walk-dir tmp-dir)))

;; 文件信息
(def f (io/file text-file))
(say "File size:" (.length f))
(say "Can read?:" (.canRead f))
(say "Can write?:" (.canWrite f))
(say "Last modified:" (java.util.Date. (.lastModified f)))

;; 删除目录
(doseq [f (.listFiles (File. tmp-dir))]
  (.delete f))
(.delete (File. tmp-dir))
(say "Cleanup done, dir exists?" (.exists (File. tmp-dir)))

(defn -main [& args]
  (println "")
  (println "==== 14 jieshu ===="))

(-main)
