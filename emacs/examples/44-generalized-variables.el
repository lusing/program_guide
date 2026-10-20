;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 44 - 广义变量：setf、cl-letf 与就地修改
;;;   setq 只能给变量赋值，但 Lisp 里能「存值」的位置远不止变量：
;;;   列表的 car、数组的元素、符号的属性、哈希表的槽位……这些统称
;;;   place（广义变量）。setf 把「所有可存值的位置」统一成一个语法，
;;;   cl-lib 又在它之上做了一整族就地修改宏：cl-incf、cl-pushnew、
;;;   cl-rotatef、cl-letf。本章把手册 5.1「Assignment」与 5.2
;;;   「Generalized Variables」全部实测一遍，每个结论都来自 Emacs 31.1。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "44-generalized-variables.el")'
;;; 运行：emacs -Q --batch -l 44-generalized-variables.el
;;; ============================================================
(require 'cl-lib)
(require 'gv)

(defvar ch44-sym nil)
(defvar ch44-g8 100)
(defvar ch44-cnt 0)
(defvar ch44-store (make-hash-table :test 'equal))
(defvar ch44-key-cnt 0)

;;; ---------- 1) place 是什么：setf 的内置位置 ----------
(princ "== 1) place 是什么：setf 的内置位置 ==\n")
(let ((l (list 1 2 3))
      (v (vector 10 20 30))
      (h (make-hash-table :test 'equal)))
  (princ (format "  (setf (car l) 99) 返回新值：%S\n" (setf (car l) 99)))
  (setf (nth 1 l) 77)
  (setf (aref v 0) 111)
  (setf (gethash "k" h) 'vv)
  (princ (format "  l = %S\n" l))
  (princ (format "  v = %S\n" v))
  (princ (format "  (gethash \"k\" h) = %S\n" (gethash "k" h))))
(princ "  变量、car、nth、aref、gethash……都是 place；\n")
(princ "  setf 返回刚写入的新值，这一点和 setq 相同。\n")

;;; ---------- 2) cl-lib 额外提供的可 setf 位置 ----------
(princ "\n== 2) cl-lib 额外提供的可 setf 位置 ==\n")
(let ((l (list 1 2 3 4 5)))
  (setf (cl-first l) 100)
  (setf (cl-rest l) (list 7 8))
  (princ (format "  (setf (cl-first l) 100) (setf (cl-rest l) '(7 8)) → %S\n" l)))
(let ((p (list :a 1)))
  (setf (cl-getf p :b) 2)
  (princ (format "  (setf (cl-getf p :b) 2) → %S（新键插到表头）\n" p)))
(setf (cl-get 'ch44-sym 'prop) 7)
(princ (format "  (setf (cl-get 'ch44-sym 'prop) 7) → %S\n"
               (get 'ch44-sym 'prop)))
(let ((v (vector 0 1 2 3)))
  (setf (cl-subseq v 1 3) (list 9 8))
  (princ (format "  (setf (cl-subseq v 1 3) '(9 8)) → %S\n" v)))
(defmacro ch44-2nd (l) `(car (cdr ,l)))
(let ((l (list 1 2 3)))
  (setf (ch44-2nd l) 99)
  (princ (format "  宏调用也是 place：(setf (ch44-2nd l) 99) → %S\n" l)))
(princ "  手册列出的可 setf 扩展：cl-rest、cl-subseq、cl-get、cl-getf、\n")
(princ "  cl-caaar…cl-cddddr、cl-first…cl-tenth；另外任何宏调用，\n")
(princ "  setf 会先展开宏、再对展开结果做 setf（最后一行就是例子）。\n")

;;; ---------- 3) cl-incf 与 cl-decf ----------
(princ "\n== 3) cl-incf 与 cl-decf ==\n")
(let ((n 10))
  (princ (format "  (cl-incf n)   → %S（返回新值）\n" (cl-incf n)))
  (cl-incf n 5)
  (princ (format "  (cl-incf n 5) → n = %S\n" n))
  (cl-decf n 3)
  (princ (format "  (cl-decf n 3) → n = %S\n" n)))
(princ "  incf/decf 是「就地加/减」：place 只写一次，不用先读后写。\n")

;;; ---------- 4) push/pop 与 cl-pushnew ----------
(princ "\n== 4) push/pop 与 cl-pushnew ==\n")
(let ((s nil))
  (push 1 s)
  (push 2 s)
  (princ (format "  (push 1 s)(push 2 s) → %S\n" s))
  (princ (format "  (pop s) = %S，剩下 %S\n" (pop s) s)))
(let ((l '(1 2 3)))
  (cl-pushnew 3 l)
  (princ (format "  (cl-pushnew 3 l) 已存在 → %S\n" l))
  (cl-pushnew 4 l)
  (princ (format "  (cl-pushnew 4 l) 不存在 → %S\n" l)))
(let ((l '((:id 1) (:id 2))))
  (cl-pushnew '(:id 1) l :key (lambda (e) (plist-get e :id)) :test '=)
  (princ (format "  :key/:test 比较 → %S\n" l)))
(princ "  CL 的 push/pop 在 Emacs 里就是原生 push/pop，不需要 cl- 前缀；\n")
(princ "  cl-pushnew 才是 cl-lib 新增的：按 :test/:key 判重后才插入。\n")

;;; ---------- 5) cl-psetq：并行赋值 ----------
(princ "\n== 5) cl-psetq：并行赋值 ==\n")
(let ((x 2) (y 3))
  (setq x 2 y 3)
  (setq x (+ x y) y (* x y))
  (princ (format "  (setq x (+ x y) y (* x y)) → x=%S y=%S（串行）\n" x y))
  (setq x 2 y 3)
  (princ (format "  (cl-psetq x (+ x y) y (* x y)) 返回 %S\n"
                 (cl-psetq x (+ x y) y (* x y))))
  (princ (format "  → x=%S y=%S（并行：y 用旧 x 算）\n" x y)))
(princ "  cl-psetq 先把所有右侧算完，再统一写回；永远返回 nil。\n")

;;; ---------- 6) cl-psetf / cl-rotatef / cl-shiftf ----------
(princ "\n== 6) cl-psetf / cl-rotatef / cl-shiftf ==\n")
(let ((l (list 1 2)))
  (cl-psetf (car l) (cadr l)
            (cadr l) (car l))
  (princ (format "  (cl-psetf (car l) (cadr l) (cadr l) (car l)) → %S\n" l)))
(let ((a 1) (b 2) (c 3))
  (princ (format "  (cl-rotatef a b c) 返回 %S\n" (cl-rotatef a b c)))
  (princ (format "  → a=%S b=%S c=%S（循环左移）\n" a b c)))
(let ((a 1) (b 2) (c 3))
  (princ (format "  (cl-shiftf a b c 9) 返回 %S（移出值）\n" (cl-shiftf a b c 9)))
  (princ (format "  → a=%S b=%S c=%S（左移补入 9）\n" a b c)))
(princ "  psetf = setf 版 psetq；rotatef 循环左移返回 nil；\n")
(princ "  shiftf 左移、末尾补入任意表达式、返回被移出的第一个旧值。\n")

;;; ---------- 7) cl-callf 与 cl-callf2 ----------
(princ "\n== 7) cl-callf 与 cl-callf2 ==\n")
(let ((n -5))
  (cl-callf abs n)
  (princ (format "  (cl-callf abs n) → %S\n" n))
  (cl-callf + n 7)
  (princ (format "  (cl-callf + n 7) → %S\n" n)))
(let ((l '(2 3)))
  (cl-callf2 cons 1 l)
  (princ (format "  (cl-callf2 cons 1 l) → %S\n" l)))
(princ "  cl-callf：(cl-callf f place args…) ≡ (setf place (f place args…))；\n")
(princ "  cl-callf2 把 place 放到第二个实参位，(push x place) ≡ (cl-callf2 cons x place)。\n")

;;; ---------- 8) cl-letf：给 place 临时赋值 ----------
(princ "\n== 8) cl-letf：给 place 临时赋值 ==\n")
(let ((l (list 1 2 3)))
  (princ (format "  (cl-letf (((car l) 'tmp)) …) 内 %S 外 %S\n"
                 (cl-letf (((car l) 'tmp)) (copy-sequence l)) l)))
(princ (format "  (cl-letf ((ch44-g8 1)) …) 内 %S 外 %S\n"
               (cl-letf ((ch44-g8 1)) ch44-g8) ch44-g8))
(let ((l (list 1 2)))
  (condition-case nil
      (cl-letf (((car l) 9)) (error "boom"))
    (error nil))
  (princ (format "  体内报错后 place 仍被恢复：%S\n" l)))
(let ((l (list 1 2 3)))
  (princ (format "  cl-letf* 串行绑定 → %S\n"
                 (cl-letf* (((car l) 5) ((cadr l) (car l))) (copy-sequence l)))))
(cl-letf (((symbol-value 'ch44-g8))) (setq ch44-g8 2))
(princ (format "  单元素绑定 ((place)) 只负责事后恢复：g8 = %S\n" ch44-g8))
(princ "  cl-letf 像 let，但绑定的是任意 place：进入时保存旧值、写入新值，\n")
(princ "  离开时（哪怕出错）恢复。体内返回值若是 place 本身，看到的已是\n")
(princ "  恢复后的值——所以上面体内用 copy-sequence 先拍快照。\n")

;;; ---------- 9) cl-letf 给函数定义打补丁 ----------
(princ "\n== 9) cl-letf 给函数定义打补丁 ==\n")
(defun ch44-greet () "orig")
(princ (format "  (cl-letf (((symbol-function 'ch44-greet) (lambda () \"patched\"))) (ch44-greet)) → %S\n"
               (cl-letf (((symbol-function 'ch44-greet) (lambda () "patched")))
                 (ch44-greet))))
(princ (format "  出了 letf 体 → %S\n" (ch44-greet)))
(princ "  (symbol-function 'f) 也是 place，所以 cl-letf 能临时替换函数定义——\n")
(princ "  这就是测试里「打桩/mock」的标准写法，退出时自动还原。\n")

;;; ---------- 10) setf 保证子形式只求值一次 ----------
(princ "\n== 10) setf 保证子形式只求值一次 ==\n")
(defun ch44-vec () (setq ch44-cnt (1+ ch44-cnt)) (vector 0 0 0))
(let ((ch44-cnt 0))
  (setf (aref (ch44-vec) 0) 1)
  (princ (format "  (setf (aref (ch44-vec) 0) 1)：ch44-vec 求值 %S 次\n" ch44-cnt)))
(let ((ch44-cnt 0))
  (cl-incf (aref (ch44-vec) 0))
  (princ (format "  (cl-incf (aref (ch44-vec) 0))：ch44-vec 求值 %S 次\n" ch44-cnt)))
(princ (format "  (macroexpand '(setf (car l) 1)) → %S\n"
               (macroexpand '(setf (car l) 1))))
(princ "  展开先把 place 的子形式绑给临时变量 v（只求值一次），再调 setcar。\n")

;;; ---------- 11) 自定义 place：gv-define-simple-setter ----------
(princ "\n== 11) 自定义 place：gv-define-simple-setter ==\n")
(defun ch44-elt (key) (gethash key ch44-store))
(defun ch44-put (key val) (puthash key val ch44-store) val)
(gv-define-simple-setter ch44-elt ch44-put t)
(defun ch44-bump () (setq ch44-key-cnt (1+ ch44-key-cnt)) "a")
(let ((ch44-key-cnt 0))
  (princ (format "  (macroexpand-1 '(setf (ch44-elt (ch44-bump)) 5)) → %S\n"
                 (macroexpand-1 '(setf (ch44-elt (ch44-bump)) 5))))
  (setf (ch44-elt (ch44-bump)) 5)
  (princ (format "  实参 key 求值 %S 次；(ch44-elt \"a\") 读回 %S\n"
                 ch44-key-cnt (ch44-elt "a"))))
(princ "  读函数 + 写函数 + (gv-define-simple-setter 读名 写名 t) 就得到一个 place。\n")
(princ "  手册里的 define-setf-expander 只存在于已废弃的 cl.el；31.1 的正路是 gv.el。\n")

(princ "==== 44 结束 ====\n")
