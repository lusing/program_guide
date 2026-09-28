;;;; ============================================================
;;;; examples/33_pcl_html/main.lisp — Practical: HTML 生成库
;;;; channel: both   （书 30 章 解释器 + 31 章 编译器）
;;;; ============================================================
;;;;
;;;; 同一个「S 表达式 → HTML」的两种实现：
;;;;   1. 解释器 render-html：运行时走数据树，动态、可存可传
;;;;   2. 编译器 html 宏：**展开期**把字面量拼成一串 write-string——
;;;;      转义在编译期做完，属性值这种运行期成分才留到运行期
;;;; 两者输出必须逐字节一致（最后当场对账）。
;;;;
;;;; S 表达式形态（书里的 FOO 子集）：
;;;;   (:p :class "intro" "正文" (:b "加粗") (:print 42))
;;;;     - 关键字打头 = 标签；随后的关键字-值对 = 属性
;;;;     - 字符串子节点要转义；(:print x) 原样输出（不转义）
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 转义：解释器和编译器共用的底座
;;; ----------------------------------------------------------

(defun escape-string (s &optional (stream *standard-output*))
  (loop for ch across s
     do (case ch
          (#\& (write-string "&amp;" stream))
          (#\< (write-string "&lt;" stream))
          (#\> (write-string "&gt;" stream))
          (t (write-char ch stream)))))

(defun escape-to-string (s)
  (with-output-to-string (out)
    (escape-string s out)))

(format t "── 1. 转义~%")
(format t "(escape-to-string \"a<b & c>d\") → ~S~%" (escape-to-string "a<b & c>d"))

;;; ----------------------------------------------------------
;;; 2. 解释器：运行时走数据树
;;; ----------------------------------------------------------

(defun split-attrs (items)
  "把 (标签后 的剩余项) 拆成 (属性 plist . 子节点)——属性以关键字打头"
  (let ((attrs nil))
    (loop while (and (rest items) (keywordp (first items)))
       do (setf attrs (nconc attrs (list (pop items) (pop items)))))
    (values attrs items)))

(defun render-html (sexp stream)
  (cond
    ((null sexp) nil)
    ((stringp sexp) (escape-string sexp stream))
    ((atom sexp) (format stream "~a" sexp))        ; 数字等： princ 形态
    (t (let ((tag (first sexp)))
         (cond
           ((eql tag :print)
            ;; 解释器版：值已经在数据里（真实程序里是运行期求出的对象）
            (format stream "~a" (second sexp)))
           ((keywordp tag)
            (multiple-value-bind (attrs children) (split-attrs (rest sexp))
              (format stream "<~(~a~)" tag)
              (loop for (k v) on attrs by #'cddr
                 do (format stream " ~(~a~)=\"" k)
                    (escape-string (format nil "~a" v) stream)
                    (write-char #\" stream))
              (write-char #\> stream)
              (dolist (child children)
                (render-html child stream))
              (format stream "</~(~a~)>" tag)))
           (t (error "不认识的节点: ~S" sexp)))))))

(defparameter *page*
  '(:html
    (:head (:title "My & Your <Page>"))
    (:body :class "main<>"
      (:h1 "Hello")
      (:p :id "first" "1 < 2 & 3 > 2")
      (:p "嵌套：" (:b "加粗") " 与 " (:i "斜体"))
      (:ul
       (:li "苹果")
       (:li "香蕉"))
      (:p "答案是 " (:print 42)))))

(format t "~%── 2. 解释器渲染~%")
(format t "~A~%" (with-output-to-string (s) (render-html *page* s)))

;;; ----------------------------------------------------------
;;; 3. 编译器：宏在展开期生成 write-string 串
;;; ----------------------------------------------------------

(defun compile-node (node)
  "把**字面量**节点编译成一串输出代码。字符串在编译期就转义好——
   这是书 31 章的核心卖点：运行时零解释、零重复转义"
  (cond
    ((null node) nil)
    ((stringp node) `(write-string ,(escape-to-string node)))
    ((atom node) `(format t "~a" ,node))
    (t (let ((tag (first node)))
         (cond
           ((eql tag :print)
            ;; 编译器版：(:print expr) 的 expr 是**运行期表达式**——这里才求值
            `(format t "~a" ,(second node)))
           ((keywordp tag)
            (multiple-value-bind (attrs children) (split-attrs (rest node))
              (let ((open (with-output-to-string (s)
                            (format s "<~(~a~)" tag)
                            (loop for (k v) on attrs by #'cddr
                               do (format s " ~(~a~)=\"" k)
                                  ;; 属性值是字面量：编译期转义，拼进常量
                                  (write-string (escape-to-string (format nil "~a" v)) s)
                                  (write-char #\" s))
                            (write-char #\> s)))
                    (close (format nil "</~(~a~)>" tag)))
                (cons 'progn
                      (nconc (list `(write-string ,open))
                             (mapcar #'compile-node children)
                             (list `(write-string ,close)))))))
           (t (error "不认识的节点: ~S" node)))))))

(defmacro html (&body sexps)
  (cons 'progn (mapcar #'compile-node sexps)))

(format t "~%── 3. 编译器宏的展开形态（macroexpand-1 节选，关 pretty 保一致）~%")
(let ((*print-pretty* nil))
  (format t "~A~%" (macroexpand-1 '(html (:b "a<b") (:print 42)))))

;;; ----------------------------------------------------------
;;; 4. 对账：两版输出必须逐字节一致
;;; ----------------------------------------------------------

(defparameter *interpreted*
  (with-output-to-string (s) (render-html *page* s)))

(defparameter *compiled*
  ;; 别用 (with-output-to-string () …)：CLISP 不接受 NIL 变量形态。
  ;; make-string-output-stream + 重绑 *standard-output* 全程可移植，
  ;; 且能捕获编译器生成的 format t / write-string（无流参数都进 *standard-output*）
  (let ((s (make-string-output-stream)))
    (let ((*standard-output* s))
      (html
       (:html
        (:head (:title "My & Your <Page>"))
        (:body :class "main<>"
          (:h1 "Hello")
          (:p :id "first" "1 < 2 & 3 > 2")
          (:p "嵌套：" (:b "加粗") " 与 " (:i "斜体"))
          (:ul
           (:li "苹果")
           (:li "香蕉"))
          (:p "答案是 " (:print 42)))))
    (get-output-stream-string s))))

(format t "~%── 4. 对账~%")
(format t "解释器与编译器输出一致: ~A~%" (equal *interpreted* *compiled*))
(format t "编译版输出:~%~A~%" *compiled*)

(format t "==== 33 结束 ====~%")
