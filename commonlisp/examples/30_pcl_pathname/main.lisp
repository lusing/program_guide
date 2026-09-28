;;;; ============================================================
;;;; examples/30_pcl_pathname/main.lisp — Practical: 可移植路径名库
;;;; channel: both   （书 15 章：A Portable Pathname Library）
;;;; ============================================================
;;;;
;;;; 路径名是 Common Lisp 可移植性重灾区。本例程按书 15 章搭一套
;;;; 小库，并在 SBCL 2.6.8 / CLISP 2.49.95 上**当场实测**差异：
;;;;   1. directory-pathname-p / pathname-as-directory / pathname-as-file
;;;;   2. list-directory：统一「SBCL 的 *.* 连子目录都匹配」的差异
;;;;   3. file-exists-p / directory-exists-p：probe-file 对目录的态度
;;;;   4. pathname-parent-directory / walk-directory 递归走树
;;;;
;;;; 输出纪律（双通道逐字节一致的根基）：
;;;;   directory/probe-file 返回的是**绝对真名**，两通道 cwd 不同，
;;;;   绝对 namestring 一露脸输出必炸——只打印构件与自造相对路径。
;;;;
;;;; 两个实测大坑（写成注释纪念）：
;;;;   ① merge-pathnames 拼 wildcard："*/" 合并进 "p30/" 时 CLISP 会把
;;;;      相对目录整个换成 (:RELATIVE :WILD)——前缀丢了，查询跑到 cwd
;;;;      去匹配出 "p30/" 自己。拼 wildcard 一律 make-pathname + :directory append。
;;;;   ② 文件名拼个 "/" 会骗过 directory-pathname-p——递归走树时文件与
;;;;      子目录必须分开收集、分开走。
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 基础谓词与规范化
;;; ----------------------------------------------------------

(defun component-present-p (value)
  "路径名成分「有值」：NIL 和 :unspecific 都算没有（书里反复用）"
  (and value (not (eql :unspecific value))))

(defun directory-pathname-p (p)
  "是目录形态的路径名吗：name/type 都没有"
  (and (not (component-present-p (pathname-name p)))
       (not (component-present-p (pathname-type p)))
       p))

(defun pathname-as-directory (path)
  "任意路径 → 目录形态：把 name/type 挪进 directory 尾部"
  (let ((pathname (pathname path)))
    (when (wild-pathname-p pathname)
      (error "can't reliably convert wild pathnames."))
    (if (directory-pathname-p pathname)
        pathname
        (make-pathname
         :directory (append (pathname-directory pathname)
                            (list (pathname-name pathname)))
         :name nil
         :type nil
         :defaults pathname))))

(defun pathname-as-file (path)
  "目录形态 → 文件形态：目录尾当成文件名"
  (let ((pathname (pathname path)))
    (when (wild-pathname-p pathname)
      (error "can't reliably convert wild pathnames."))
    (if (directory-pathname-p pathname)
        (let* ((directory (pathname-directory pathname)))
          (if (null directory)
              (error "can't create file from root")
              (make-pathname
               :directory (butlast directory)
               :name (car (last directory))
               :type nil
               :defaults pathname)))
        pathname)))

(format t "── 1. 形态转换（打印的是自造相对路径，可安全 namestring）~%")
(let ((*print-pretty* nil))
  (format t "(namestring (pathname-as-directory #p\"foo/bar.txt\")): ~S~%"
          (namestring (pathname-as-directory #p"foo/bar.txt")))
  (format t "(namestring (pathname-as-file #P\"foo/bar/\")):         ~S~%"
          (namestring (pathname-as-file #p"foo/bar/")))
  (format t "(namestring (pathname-as-directory #p\"foo/\")):        ~S~%"
          (namestring (pathname-as-directory #p"foo/")))
  (format t "directory-pathname-p #p\"foo/\":   ~S~%" (not (null (directory-pathname-p #p"foo/"))))
  (format t "directory-pathname-p #p\"foo.txt\": ~S~%" (not (null (directory-pathname-p #p"foo.txt")))))

;;; ----------------------------------------------------------
;;; 2. wildcard 构造与 list-directory
;;; ----------------------------------------------------------

(defun directory-wildcard (dirname)
  "文件 wildcard：name/type 全 :wild（注意——SBCL 会连子目录一起匹配）"
  (make-pathname :name :wild :type :wild
                 :defaults (pathname-as-directory dirname)))

(defun subdirs-wildcard (dirname)
  "子目录 wildcard：directory 尾追加 :wild，name/type 留空。
   ★ 千万别用 (merge-pathnames \"*/\" dir) 拼——CLISP 的合并规则会把
   相对目录前缀整个换掉（实测坑①）"
  (let ((d (pathname-as-directory dirname)))
    (make-pathname :name nil :type nil
                   :directory (append (pathname-directory d) (list :wild))
                   :defaults d)))

(defun entry-name (p)
  "条目显示名：目录取 directory 尾，文件取 file-namestring"
  (if (directory-pathname-p p)
      (car (last (pathname-directory p)))
      (file-namestring p)))

;; 实测差异：directory 对 "*.*" 的匹配
;;   SBCL → 文件 + 子目录（子目录 file-namestring 是 ""）
;;   CLISP → 只有文件
;; 统一法：文件集（过滤目录形态）∪ 子目录集（专用 wildcard），排序后
;; 给目录名补 "/" 尾巴——两边输出自然一致
(defun list-directory (dirname)
  (let* ((d (pathname-as-directory dirname))
         (files (remove-if #'directory-pathname-p
                           (directory (directory-wildcard d))))
         (subdirs (directory (subdirs-wildcard d))))
    (sort (append (mapcar #'file-namestring files)
                  (mapcar (lambda (p)
                            (concatenate 'string (entry-name p) "/"))
                          subdirs))
          #'string<)))

;; 搭测试树（相对路径，产物落在本通道的运行目录里）
(ensure-directories-exist "p30/music/")
(ensure-directories-exist "p30/docs/")
(with-open-file (f "p30/a.txt" :direction :output :if-exists :supersede) (format f "x"))
(with-open-file (f "p30/music/song.lisp" :direction :output :if-exists :supersede) (format f "y"))
(with-open-file (f "p30/docs/readme.md" :direction :output :if-exists :supersede) (format f "z"))

(format t "~%── 2. list-directory~%")
(format t "p30 →       ~S~%" (list-directory "p30/"))
(format t "p30/music → ~S~%" (list-directory "p30/music/"))
(format t "p30/docs →  ~S~%" (list-directory "p30/docs/"))

;;; ----------------------------------------------------------
;;; 3. 存在性检测：probe-file 对目录的态度
;;; ----------------------------------------------------------

;; 实测：SBCL 的 probe-file 目录文件都给真值；CLISP 2.49.95 的 probe-file
;; 对目录**返回 NIL（不报错）**——书写作年代是报错，如今是沉默的 NIL，
;; 更阴：file-exists-p 直接套它会把存在的目录当不存在
(defun file-exists-p (path)
  "文件存在吗（**别拿它问目录**——CLISP 会给 NIL）"
  #+sbcl (and (probe-file path) t)
  #+clisp (and (probe-file (pathname-as-file path)) t)
  #-(or sbcl clisp) (and (probe-file path) t))

(defun directory-exists-p (path)
  "目录存在吗：truename 对存在的目录两实现都干活，不存在都报错→NIL"
  #+sbcl (and (probe-file (pathname-as-directory path)) t)
  #+clisp (and (ignore-errors (truename (pathname-as-directory path))) t)
  #-(or sbcl clisp) (and (ignore-errors (truename (pathname-as-directory path))) t))

(format t "~%── 3. 存在性（a.txt 文件 / music 目录 / ghost 不存在）~%")
(format t "file-exists-p a.txt:      ~S~%" (file-exists-p "p30/a.txt"))
(format t "directory-exists-p music: ~S~%" (directory-exists-p "p30/music"))
(format t "file-exists-p ghost.txt:  ~S~%" (file-exists-p "p30/ghost.txt"))
(format t "directory-exists-p nope:  ~S~%" (directory-exists-p "p30/nope"))

;;; ----------------------------------------------------------
;;; 4. 父目录与递归走树
;;; ----------------------------------------------------------

(defun pathname-parent-directory (path)
  (make-pathname :name nil :type nil
                 :directory (butlast (pathname-directory
                                      (pathname-as-directory path)))))

(format t "~%── 4. 父目录（打 :directory 构件，规避绝对真名）~%")
(let ((*print-pretty* nil))
  (format t "(pathname-directory (pathname-parent-directory #p\"a/b/c.txt\")): ~S~%"
          (pathname-directory (pathname-parent-directory #p"a/b/c.txt"))))

;; walk-directory：深度优先走整棵树，对每个**文件**调 fn。
;; 实测坑②：文件和子目录必须分开收集——文件名拼个 "/" 就能骗过
;; directory-pathname-p，混在一起递归必炸。
;; 起点先 truename 成绝对路径：fn 收到的全是同源绝对真名，调用方
;; 好统一剥前缀。
(defun walk-directory (dirname fn &key directories-p)
  (labels ((walk (dir)
             (let* ((files (sort (mapcar #'file-namestring
                                         (remove-if #'directory-pathname-p
                                                    (directory (directory-wildcard dir))))
                                 #'string<))
                    (subdir-names (sort (mapcar (lambda (p) (car (last (pathname-directory p))))
                                                (directory (subdirs-wildcard dir)))
                                        #'string<)))
               (dolist (f files)
                 ;; 用 merge-pathnames 而不是 make-pathname :name——SBCL 对
                 ;; 「name 含点 + type 空」的 namestring 会转义点号（a\.txt）
                 (funcall fn (merge-pathnames f dir)))
               (dolist (sub subdir-names)
                 (let ((child (make-pathname
                               :name nil :type nil
                               :directory (append (pathname-directory dir) (list sub))
                               :defaults dir)))
                   (when directories-p (funcall fn child))
                   (walk child))))))
    (walk (truename (pathname-as-directory dirname)))))

(format t "~%── 5. walk-directory 收集全部文件（排序，稳定跨实现）~%")
;; 真名是绝对路径——拿**相对形态**：剥掉 cwd 的目录前缀，两边剥法一致。
;; 注意 cwd 前缀别用 (truename ".")——CLISP 对它报「names a directory」；
;; 用树根真名 butlast 1 一样能得到
(let ((paths nil)
      (prefix-len (length (butlast (pathname-directory (truename "p30/"))))))
  (walk-directory "p30/"
                  (lambda (p)
                    ;; p 是文件形态：directory 本来就是它所在的目录，别再 as-directory
                    (push (concatenate 'string
                                       (format nil "~{~a/~}"
                                               (nthcdr prefix-len (pathname-directory p)))
                                       (file-namestring p))
                          paths)))
  (format t "全部文件（相对路径，排序）: ~S~%" (sort paths #'string<)))

;; 清理：删自己产出的文件（空目录留下——ANSI 没有可移植的删目录，见 17 章）
(dolist (f '("p30/a.txt" "p30/music/song.lisp" "p30/docs/readme.md"))
  (delete-file f))
(format t "~%清理完成~%")

(format t "==== 30 结束 ====~%")
