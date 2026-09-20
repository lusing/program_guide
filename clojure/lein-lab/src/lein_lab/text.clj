;; lein-lab/src/lein_lab/text.clj
;; 命名空间 lein-lab.text —— 文件路径把连字符换成下划线，目录对应命名空间层级。
(ns lein-lab.text
  "文本归一化与分词工具。")

(defn normalize
  "去首尾空白、转小写。"
  [s]
  (clojure.string/lower-case (clojure.string/trim s)))

(defn words
  "提取小写单词序列（忽略标点和数字）。"
  [s]
  (vec (re-seq #"[a-z]+" (normalize s))))

(defn word-freq
  "词频统计，返回 {单词 出现次数}。"
  [s]
  (frequencies (words s)))

(defn sentence-count
  "按句号/问号/叹号粗略数句子。"
  [s]
  (count (filter seq (clojure.string/split s #"[.!?]+"))))
