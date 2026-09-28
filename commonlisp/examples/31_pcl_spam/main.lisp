;;;; ============================================================
;;;; examples/31_pcl_spam/main.lisp — Practical: 垃圾邮件过滤器
;;;; channel: both   （书 23 章：A Spam Filter 的统计核心）
;;;; ============================================================
;;;;
;;;; 按《Practical Common Lisp》23 章实现统计过滤核心：
;;;;   1. 分词（extract-words：字母段的纯手写切分，不依赖正则库）
;;;;   2. 特征库（哈希表 + defstruct 计数）与训练（increment-count）
;;;;   3. 单词垃圾概率（拉普拉斯平滑：没见过的词 → 1/2）
;;;;   4. 按信息量挑特征（|p − 1/2| 排序，平手按字典序——确定性！）
;;;;   5. 分类（分数阈值 ham / spam / unsure）
;;;;
;;;; 双实现纪律：**全程有理数算术**。书里用浮点（0.4/0.6 阈值、~f 格式），
;;;; SBCL 与 CLISP 的浮点打印/舍入不保证逐字节一致——有理数精确又好读，
;;;; 是把统计代码做成可移植示例的正路。哈希表遍历一律先 sort 键。
;;;; ============================================================

(defparameter *max-ham-score* 2/5)   ; 书里是 0.4 —— 有理数版
(defparameter *min-spam-score* 3/5)  ; 书里是 0.6

(defun classification (score)
  (cond ((<= score *max-ham-score*) 'ham)
        ((>= score *min-spam-score*) 'spam)
        (t 'unsure)))

;;; ----------------------------------------------------------
;;; 1. 分词：连续字母段（大小写归一）
;;; ----------------------------------------------------------

(defun ascii-letter-p (ch)
  "只认 ASCII 字母——alpha-char-p 对 CJK 等宽字符两实现口径不一，别赌"
  (let ((c (char-upcase ch)))
    (and (char<= #\A c) (char<= c #\Z))))

(defun extract-words (text)
  "把字符串切成字母段列表。书里用正则库，这里手写状态机——零依赖可移植"
  (let ((words nil)
        (cur nil))
    (flet ((flush ()
             (when cur
               (push (coerce (nreverse cur) 'string) words)
               (setf cur nil))))
      (loop for ch across text
         do (if (ascii-letter-p ch)
                (push (char-upcase ch) cur)
                (flush)))
      (flush))
    (nreverse words)))

;;; ----------------------------------------------------------
;;; 2. 特征库与训练
;;; ----------------------------------------------------------

(defstruct word-feature
  (word "" :read-only t)
  (spam-count 0)
  (ham-count 0))

(defparameter *feature-database* (make-hash-table :test #'equal))
(defparameter *total-spams* 0)
(defparameter *total-hams* 0)

(defun intern-word (word)
  "单词 → 特征对象（没有就现造一个入库）"
  (or (gethash word *feature-database*)
      (setf (gethash word *feature-database*)
            (make-word-feature :word word))))

(defun increment-count (feature type)
  (ecase type
    (spam (incf (word-feature-spam-count feature)))
    (ham  (incf (word-feature-ham-count feature)))))

(defun word-spam-probability (feature)
  "拉普拉斯平滑的单词垃圾概率：没见过的词是 1/2（不站队）。
   定义放在 extract-features 之前——SBCL 逐 toplevel 编译，前向引用给
   undefined function 风格警告（stderr 非空 = 判定失败）"
  ;; 不用 with-slots：defstruct 不保证实现 slot-value，访问器才稳
  (/ (+ 1 (word-feature-spam-count feature))
     (+ 2 (word-feature-spam-count feature) (word-feature-ham-count feature))))


(defun extract-features (text)
  "取信息量最大的至多 15 个特征：|p−1/2| 降序，平手按字典序（确定性）"
  (let* ((words (remove-duplicates (extract-words text) :test #'string=))
         (features (mapcar #'intern-word words))
         (n (min 15 (length features))))   ; ★ 长度必须在 sort 之前数好
    ;; 实测大坑：实参从左到右求值——写 (subseq (sort features ...) 0 (length features))
    ;; 的话，破坏性的 sort 先跑，features 变量可能已指向排序结果的中段尾巴，
    ;; length 数出残链长度（SBCL 实测丢元素；CLISP 的 sort 恰好没挪头，没炸）
    (subseq (sort features
                  (lambda (a b)
                    (let ((da (abs (- (word-spam-probability a) 1/2)))
                          (db (abs (- (word-spam-probability b) 1/2))))
                      (if (= da db)
                          (string< (word-feature-word a) (word-feature-word b))
                          (> da db)))))
            0 n)))

(defun train (text type)
  (ecase type
    (spam (incf *total-spams*))
    (ham  (incf *total-hams*)))
  (dolist (feature (extract-features text))
    (increment-count feature type)))

;;; ----------------------------------------------------------
;;; 3. 概率与评分
;;; ----------------------------------------------------------


(defun score (text)
  "信息量前 15 特征的**平均值**（书后章用 Fisher 组合，那是统计课的加餐）"
  (let ((features (extract-features text)))
    (if (null features)
        1/2
        (/ (reduce #'+ (mapcar #'word-spam-probability features))
           (length features)))))

(defun classify (text)
  (classification (score text)))

;;; ----------------------------------------------------------
;;; 4. 用固定语料跑起来
;;; ----------------------------------------------------------

(format t "── 1. 分词~%")
;; ~S 打长列表会被 SBCL 的 pretty printer 折行（CLISP 不折）——关掉保一致
(let ((*print-pretty* nil))
  (format t "(extract-words \"Buy now!! cheap_viagra online\") → ~S~%"
          (extract-words "Buy now!! cheap_viagra online")))

;; 训练语料（书里从磁盘读，这里内联——示例自包含且确定）
(format t "~%── 2. 训练：3 封垃圾 + 3 封正常~%")
(dolist (spam '("Buy cheap viagra online now"
                "Win a million dollars click here cheap"
                "Cheap meds online buy now buy now"))
  (train spam 'spam))
(dolist (ham '("Meeting tomorrow about the project"
               "The project schedule looks good"
               "Lunch tomorrow with the team about work"))
  (train ham 'ham))
(format t "*total-spams* = ~A，*total-hams* = ~A~%" *total-spams* *total-hams*)
(format t "特征库大小 = ~A~%" (hash-table-count *feature-database*))

(format t "~%── 3. 抽查几个词的垃圾概率（有理数）~%")
(dolist (w '("VIAGRA" "CHEAP" "PROJECT" "MEETING" "UNSEENWORD"))
  (let ((f (gethash w *feature-database*)))
    (format t "~10A spam=~A ham=~A → p = ~A~%"
            w
            (if f (word-feature-spam-count f) 0)
            (if f (word-feature-ham-count f) 0)
            (if f (word-spam-probability f) 1/2))))

(format t "~%── 4. 分类测试（分数保持有理数，逐字节可移植）~%")
(dolist (text '("Cheap viagra buy now"
                "The meeting about the project"
                "Viagra meeting project cheap"
                "totally unseen vocabulary here"))
  (let ((s (score text)))
    (format t "~38A score=~10A → ~A~%"
            (format nil "\"~a\"" text)
            s
            (classification s))))

(format t "~%── 5. 特征选择：挑信息量最大的前几个~%")
(let ((*print-pretty* nil))
  (format t "「Cheap viagra meeting project」选中：~S~%"
          (mapcar #'word-feature-word (extract-features "Cheap viagra meeting project"))))

;;; ----------------------------------------------------------
;;; 5. 双实现纪律的两条铁律演示
;;; ----------------------------------------------------------

;; 铁律一：哈希遍历必须排序——两实现的桶序不同
(let ((keys (sort (loop for k being each hash-key in *feature-database* collect k)
                  #'string<)))
  (format t "~%── 6a. 哈希键排序后取前 5: ~S~%" (subseq keys 0 5)))

;; 铁律二：分数是有理数——equal 比较在两实现上同样成立
(let ((s1 (score "cheap viagra"))
      (s2 (score "cheap viagra")))
  (format t "── 6b. 同文本两次评分 equal: ~A（分数 ~A）~%" (equal s1 s2) s1))

(format t "~%==== 31 结束 ====~%")
