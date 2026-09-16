;; ==========================================================================
;; 20_project.clj - 综合实战：成绩数据分析管线
;; ==========================================================================
;; 主题：综合运用 Clojure 各特性构建数据分析管线
;; 内容：
;;   1. 数据建模（记录）
;;   2. 数据解析（字符串 -> 记录）
;;   3. 数据验证（spec）
;;   4. 数据转换（高阶函数 + 线程宏）
;;   5. 数据聚合（group-by + reduce）
;;   6. 统计分析（均值、中位数、标准差）
;;   7. 报告生成（EDN 输出 + 格式化打印）
;;
;; 运行方式：
;;   clojure -M 20_project.clj
;; ==========================================================================

(ns clojure-tutorial.20-project
  (:require [clojure.string :as str]
            [clojure.pprint :as pp]
            [clojure.spec.alpha :as s])
  (:import [java.io StringWriter]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 数据建模 ----
;; 使用 defrecord 定义数据模型

(section 1 "Data Modeling")

(defrecord Student [id name grade subjects])
(defrecord Subject [name score])

(defn make-student [id name grade & subjects]
  (->Student id name grade (mapv (fn [[n s]] (->Subject n s))
                                 (partition 2 subjects))))

(def student1 (make-student 1 "Alice" 10 :math 90 :english 85 :science 92))
(def student2 (make-student 2 "Bob" 10 :math 75 :english 80 :science 70))
(def student3 (make-student 3 "Carol" 9 :math 95 :english 92 :science 88))
(def student4 (make-student 4 "Dave" 9 :math 60 :english 65 :science 70))
(def student5 (make-student 5 "Eve" 10 :math 88 :english 90 :science 85))

(def all-students [student1 student2 student3 student4 student5])

(say "Sample student:" student1)

;; ---- 2) 数据解析 ----
;; 从 CSV 格式字符串解析学生数据

(section 2 "Data Parsing")

(defn parse-subjects [subject-str]
  (for [pair (str/split subject-str #";")
        :let [[name score] (str/split pair #":")]]
    (->Subject (keyword name) (Integer/parseInt score))))

(defn parse-csv-line [line]
  (let [[id name grade subjects] (str/split line #",")]
    (->Student
      (Integer/parseInt id)
      name
      (Integer/parseInt grade)
      (vec (parse-subjects subjects)))))

(defn parse-csv [csv-text]
  (let [lines (str/split-lines csv-text)]
    (mapv parse-csv-line (drop 1 lines)))) ;; skip header

(def csv-data
  "id,name,grade,subjects
6,Frank,10,math:70;english:75;science:80
7,Grace,9,math:85;english:90;science:88
8,Heidi,10,math:95;english:88;science:92")

(def parsed-students (parse-csv csv-data))
(say "Parsed students:" (count parsed-students))
(doseq [s parsed-students]
  (say " " (:name s) "grade:" (:grade s)))

;; ---- 3) 数据验证 ----

(section 3 "Data Validation")

(s/def ::id pos-int?)
(s/def ::name (s/and string? seq))
(s/def ::grade (s/and int? #(>= % 1) #(<= % 12)))
(s/def ::score (s/and int? #(>= % 0) #(<= % 100)))
(s/def ::valid-student
  (s/and
    (s/keys :req-un [::id ::name ::grade ::subjects])
    #(every? (fn [subj] (s/valid? ::score (:score subj)))
             (:subjects %))))

(defn validate-student [student]
  (if (s/valid? ::valid-student student)
    {:status :ok :student student}
    {:status :error :student student}))

(doseq [s all-students]
  (let [r (validate-student s)]
    (say (:name s) "->" (:status r))))

;; ---- 4) 数据转换 ----
;; 计算每个学生的平均分

(section 4 "Data Transformation")

(defn average [nums]
  (if (empty? nums)
    0
    (/ (reduce + nums) (count nums))))

(defn student-average [student]
  (->> (:subjects student)
       (map :score)
       average))

(defn student-subject-score [student subject]
  (->> (:subjects student)
       (filter #(= subject (:name %)))
       first
       :score))

(defn enrich-student [student]
  (assoc student :avg-score (student-average student)
         :passing? (>= (student-average student) 70)))

(def enriched-students (mapv enrich-student all-students))

(say "Enriched students:")
(doseq [s enriched-students]
  (say " " (:name s) "avg:" (:avg-score s)
       "passing?" (:passing? s)))

;; ---- 5) 数据聚合 ----

(section 5 "Data Aggregation")

;; 按年级分组
(def by-grade
  (->> enriched-students
       (group-by :grade)))

(say "By grade:")
(doseq [[grade students] (sort-by first by-grade)]
  (say "  Grade" grade ":"
       (count students) "students,"
       "avg score:" (average (map :avg-score students))))

;; 按科目统计
(def subject-stats
  (->> all-students
       (mapcat :subjects)
       (group-by :name)
       (map (fn [[subject subjects]]
              {:subject subject
               :count (count subjects)
               :avg (average (map :score subjects))
               :max (reduce max (map :score subjects))
               :min (reduce min (map :score subjects))}))
       (sort-by :subject)
       vec))

(say "Subject stats:")
(doseq [stat subject-stats]
  (say " " stat))

;; ---- 6) 统计分析 ----
;; 均值、中位数、标准差

(section 6 "Statistical Analysis")

(defn median [nums]
  (let [sorted (sort nums)
        n (count sorted)
        mid (quot n 2)]
    (if (odd? n)
      (nth sorted mid)
      (/ (+ (nth sorted (dec mid)) (nth sorted mid)) 2))))

(defn std-dev [nums]
  (let [avg (average nums)
        n (count nums)
        variance (/ (reduce + (map #(Math/pow (- % avg) 2) nums)) n)]
    (Math/sqrt variance)))

(def all-avg-scores (map :avg-score enriched-students))

(say "All average scores:" (vec all-avg-scores))
(say "Mean:" (average all-avg-scores))
(say "Median:" (median all-avg-scores))
(say "Std Dev:" (std-dev all-avg-scores))
(say "Min:" (reduce min all-avg-scores))
(say "Max:" (reduce max all-avg-scores))

;; 排名
(defn rank-students [students]
  (->> students
       (sort-by :avg-score >)
       (map-indexed (fn [i s] (assoc s :rank (inc i))))
       vec))

(def ranked (rank-students enriched-students))

(say "Rankings:")
(doseq [s ranked]
  (say "  #" (:rank s) (:name s) "score:" (:avg-score s)))

;; ---- 7) 报告生成 ----
;; 生成 EDN 报告和格式化文本报告

(section 7 "Report Generation")

(defn generate-edn-report [students subject-stats]
  {:report-date (str (java.util.Date.))
   :total-students (count students)
   :passing (count (filter :passing? students))
   :failing (count (remove :passing? students))
   :overall-avg (average (map :avg-score students))
   :subject-stats subject-stats
   :rankings (map #(select-keys % [:rank :name :avg-score :passing?])
                   (rank-students students))})

(def edn-report (generate-edn-report enriched-students subject-stats))

(say "EDN Report:")
(pp/pprint edn-report)

;; 格式化文本报告
(defn generate-text-report [students subject-stats]
  (let [sw (StringWriter.)
        w (java.io.PrintWriter. sw)]
    (.println w "=====================")
    (.println w "  Student Report")
    (.println w "=====================")
    (.println w "")
    (.println w (format "Total students: %d" (count students)))
    (.println w (format "Passing: %d | Failing: %d"
                         (count (filter :passing? students))
                         (count (remove :passing? students))))
    (.println w (format "Overall average: %.2f" (double (average (map :avg-score students)))))
    (.println w "")
    (.println w "Subject Statistics:")
    (.println w (format "%-10s %5s %5s %5s %5s" "Subject" "Count" "Avg" "Min" "Max"))
    (doseq [stat subject-stats]
      (.println w (format "%-10s %5d %5.1f %5d %5d"
                           (name (:subject stat))
                           (:count stat)
                           (double (:avg stat))
                           (:min stat)
                           (:max stat))))
    (.println w "")
    (.println w "Student Rankings:")
    (.println w (format "%-3s %-10s %5s %s" "#" "Name" "Avg" "Status"))
    (doseq [s (rank-students students)]
      (.println w (format "%-3d %-10s %5.1f %s"
                           (:rank s)
                           (:name s)
                           (double (:avg-score s))
                           (if (:passing? s) "PASS" "FAIL"))))
    (.println w "")
    (.println w "=====================")
    (.toString sw)))

(say "")
(say "Text Report:")
(print (generate-text-report enriched-students subject-stats))

;; ---- 8) 数据管线完整流程 ----
;; 把所有步骤串起来

(section 8 "Full Pipeline")

(defn analyze-students [csv-text]
  (let [students (->> csv-text
                      parse-csv
                      (map enrich-student)
                      (map validate-student)
                      (#(do (assert (every? (fn [x] (= :ok (:status x))) %)
                                    "All students must be valid!")
                            (map :student %))))
        ss (->> students
                (mapcat :subjects)
                (group-by :name)
                (map (fn [[subject subjects]]
                       {:subject subject
                        :count (count subjects)
                        :avg (average (map :score subjects))
                        :max (reduce max (map :score subjects))
                        :min (reduce min (map :score subjects))}))
                (sort-by :subject)
                vec)]
    (generate-edn-report students ss)))

(def full-report (analyze-students csv-data))
(say "Full pipeline report keys:" (keys full-report))
(say "Total students:" (:total-students full-report))
(say "Passing:" (:passing full-report))

(defn -main [& args]
  (println "")
  (println "==== 20 jieshu ===="))

(-main)
