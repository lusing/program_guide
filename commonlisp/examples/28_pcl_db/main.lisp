;;;; ============================================================
;;;; examples/28_pcl_db/main.lisp — Practical: 简易 CD 数据库
;;;; channel: both   （书 3 章：A Simple Database 的完整演化弧）
;;;; ============================================================
;;;;
;;;; 本例程按《Practical Common Lisp》第 3 章的推进顺序重演一遍：
;;;;   1. plist 记录 + 全局表 + add-record / dump-db
;;;;   2. save-db / load-db：print + read 的免费序列化
;;;;   3. 查询三代：闭包选择器 → where 宏（拼出 (lambda (cd) (and ...)))
;;;;   4. update：广义赋值 setf + getf 原地改字段
;;;;   5. delete-rows：remove-if 一行删
;;;; 教学主线：**同一个查询需求，宏版本为什么碾压函数版本**。
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 记录与全局表：plist 当行，列表当表
;;; ----------------------------------------------------------

(defparameter *db* nil)

(defun add-record (cd) (push cd *db*) cd)

(add-record '(:title "Lyle Lovett"        :artist "Lyle Lovett"    :rating 9  :ripped t))
(add-record '(:title "Astral Weeks"       :artist "Van Morrison"   :rating 10 :ripped t))
(add-record '(:title "Roses"              :artist "Kathy Mattea"   :rating 8  :ripped t))
(add-record '(:title "Rockin' the Suburbs" :artist "Ben Folds"     :rating 6  :ripped nil))
(add-record '(:title "Give Us a Break"    :artist "Lyle Lovett"    :rating 6  :ripped t))

;; push 是头插——最后加的在最前面。dump 前先 reverse 得到插入序
(setf *db* (reverse *db*))

;; 书里第一种 dump：dolist + ~{...~} 逐行迭代 plist（偶数个元素才合法）
(defun dump-db ()
  (dolist (cd *db*)
    (format t "~{~a:~10t~a~%~}~%" cd)))

(format t "── 1. dump-db（dolist 版）~%")
(dump-db)

;; 第二种 dump：loop 一行（书里问读者"改写成 loop 留作练习"，这里交作业）
(defun dump-db-loop ()
  (loop for cd in *db*
     do (format t "~{~a:~10t~a~%~}~%" cd)))

;;; ----------------------------------------------------------
;;; 2. save-db / load-db：print 出去的，read 读得回来
;;; ----------------------------------------------------------

(defun save-db (filename)
  (with-open-file (out filename
                       :direction :output
                       :if-exists :supersede)
    (with-standard-io-syntax
      (print *db* out))))

(defun load-db (filename)
  (with-open-file (in filename)
    (setf *db* (with-standard-io-syntax (read in)))))

(format t "~%── 2. save/load 往返~%")
(save-db "cd-db.txt")
(let ((before (copy-tree *db*)))
  (setf *db* nil)
  (load-db "cd-db.txt")
  (format t "往返后与原表 equal（浅比较）: ~A~%" (equal before *db*))
  (format t "往返后字段抽查（第 2 张的 rating）: ~A~%" (getf (second *db*) :rating)))
(delete-file "cd-db.txt")

;;; ----------------------------------------------------------
;;; 3. 查询三代：从闭包到宏
;;; ----------------------------------------------------------

;; 一代：写死的按艺术家查
(defun select-by-artist (artist)
  (remove-if-not
   (lambda (cd) (equal (getf cd :artist) artist))
   *db*))

(format t "~%── 3a. 写死的查询（select-by-artist）~%")
(format t "Lyle Lovett 有 ~A 张~%" (length (select-by-artist "Lyle Lovett")))

;; 二代：通用选择器**函数**——字段名成了参数，但每次调用都等编译器现编译闭包
(defun artist-selector (artist)
  (lambda (cd) (equal (getf cd :artist) artist)))

;; 三代：where **宏**——把 plist 里的偶数位当成字段名，展开期就拼出 lambda 源码。
(defun make-comparison-expr (field value)
  "拼一条 (equal (getf cd 字段) 值)。值在宏展开期就被嵌进闭包"
  `(equal (getf cd ,field) ,value))

(defun make-comparisons-list (fields)
  "把 (&key 参数残表) 两两配对成比较式；没有参数时返回 nil → (and) 恒真"
  (loop while fields
     collecting (make-comparison-expr (pop fields) (pop fields))))

(defmacro where (&rest clauses)
  `(lambda (cd) (and ,@(make-comparisons-list clauses))))

(defun select (selector-fn)
  (remove-if-not selector-fn *db*))

(format t "~%── 3b. where 宏展开形态（macroexpand-1）~%")
;; 打印展开式必须关 pretty——两实现的换行缩进策略不同，会破坏跨通道一致
(let ((*print-pretty* nil))
  (format t "~A~%" (macroexpand-1 '(where :artist "Lyle Lovett" :ripped t))))

(format t "~%── 3c. select + where 查询~%")
(format t "Lyle Lovett 且已抓轨: ~A 张 → ~{~a ~}~%"
        (length (select (where :artist "Lyle Lovett" :ripped t)))
        (mapcar (lambda (cd) (getf cd :title))
                (select (where :artist "Lyle Lovett" :ripped t))))
;; 空 where 会展开成 (lambda (cd) (and))——恒真但 cd 未用，SBCL 给 style-warning，
;; 生产代码里给 lambda 加 (declare (ignore cd))；这里就不演示空参形态了

;;; ----------------------------------------------------------
;;; 4. update：setf + getf 的广义赋值，改的还是 plist 本身
;;; ----------------------------------------------------------

(defun update (selector-fn &key title artist rating (ripped nil ripped-p))
  (setf *db*
        (mapcar
         (lambda (row)
           (when (funcall selector-fn row)
             (when title    (setf (getf row :title)  title))
             (when artist   (setf (getf row :artist) artist))
             (when rating   (setf (getf row :rating) rating))
             (when ripped-p (setf (getf row :ripped) ripped)))
           row)
         *db*)))

(format t "~%── 4. update：给 Lyle Lovett 全部升到 11 分~%")
(update (where :artist "Lyle Lovett") :rating 11)
(dolist (cd (select (where :artist "Lyle Lovett")))
  (format t "  ~a → rating ~a~%" (getf cd :title) (getf cd :rating)))

;;; ----------------------------------------------------------
;;; 5. delete-rows：remove-if 一行删
;;; ----------------------------------------------------------

(defun delete-rows (selector-fn)
  (setf *db* (remove-if selector-fn *db*)))

(format t "~%── 5. 删掉 rating < 8 的（注意 update 后 Lyle 已经是 11）~%")
(let ((victims (mapcar (lambda (cd) (getf cd :title))
                       (select (lambda (cd) (< (getf cd :rating) 8))))))
  (format t "被删的: ~{~a、~}~%" victims))
(delete-rows (lambda (cd) (< (getf cd :rating) 8)))
(format t "删除后剩 ~A 张 → ~{~a ~}~%"
        (length *db*)
        (mapcar (lambda (cd) (getf cd :title)) *db*))

;;; ----------------------------------------------------------
;;; 6. 收束：宏版 where 为什么赢了
;;; ----------------------------------------------------------

(format t "~%── 6. 小结~%")
(format t "函数版 artist-selector 每次调用都现造一个闭包；~%")
(format t "宏版 where 在**展开期**就把比较式拼成 lambda 源码交给编译器，~%")
(format t "没有的字段直接不出现在代码里——这就是书里说的 winning big。~%")

(format t "~%==== 28 结束 ====~%")
