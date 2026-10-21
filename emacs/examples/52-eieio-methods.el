;;; 52-eieio-methods.el --- EIEIO 方法:泛型、限定符、派发 -*- lexical-binding: t; -*-
;;
;; 对应文档:docs/extending-emacs/52-eieio-methods.md
;;
;; 编译:  emacs -Q --batch -f batch-byte-compile 52-eieio-methods.el
;; 运行:  emacs -Q --batch -l 52-eieio-methods.el
;;
;; 演示:
;;   1) cl-defgeneric 与 cl-defmethod
;;   2) :before / :after 辅助方法与执行顺序
;;   3) :around 与 cl-call-next-method
;;   4) 无方法与无后继:cl-no-applicable-method / cl-no-next-method / t 兜底
;;   5) 多继承的方法派发(C3 线性化)
;;   6) initialize-instance:构造后钩子
;;   7) clone:复制对象
;;   8) (subclass 类) 特化符:挂在类上的"静态方法"
;;   9) 打印体系:#s 记录语法与 31.1 的现状

(require 'eieio)

;;; ---- 1) cl-defgeneric 与 cl-defmethod --------------------------------

(princ "== 1) cl-defgeneric 与 cl-defmethod ==\n")

(defclass animal ()
  ((name :initarg :name :initform "动物" :type string))
  "动物基类。")

(defclass dog (animal)
  ()
  "狗,继承 animal。")

(cl-defgeneric speak (x)
  "让 X 发声。文档字符串写在这里,不写进各个方法。")

(cl-defmethod speak ((a animal))
  (format "%s叫了一声" (slot-value a 'name)))

(cl-defmethod speak ((d dog))
  (format "%s汪汪叫" (slot-value d 'name)))

(princ (format "  animal → %S\n" (speak (animal :name "某动物"))))
(princ (format "  dog    → %S\n" (speak (dog :name "阿黄"))))

;;; ---- 2) :before / :after ---------------------------------------------

(princ "== 2) :before / :after 辅助方法 ==\n")

(cl-defgeneric feed (x)
  "喂食 X。")

(cl-defmethod feed :before ((_a animal))
  (princ "  [before animal] 准备食盆\n"))

(cl-defmethod feed :before ((_d dog))
  (princ "  [before dog] 摇尾巴\n"))

(cl-defmethod feed ((a animal))
  (format "%s吃完了" (slot-value a 'name)))

(cl-defmethod feed :after ((_a animal))
  (princ "  [after animal] 收拾食盆\n"))

(cl-defmethod feed :after ((_d dog))
  (princ "  [after dog] 舔嘴\n"))

(let ((r (feed (dog :name "阿黄"))))
  (princ (format "  返回值 → %S\n" r)))

;;; ---- 3) :around 与 cl-call-next-method --------------------------------

(princ "== 3) :around 与 cl-call-next-method ==\n")

(cl-defgeneric area (x)
  "返回 X 的面积。")

(cl-defmethod area ((_a animal))
  10)

(cl-defmethod area :around ((_a animal))
  ;; cl-call-next-method 调用下一层(这里是 primary),可包装其返回值
  (* 2 (cl-call-next-method)))

(princ (format "  primary 10 经 around 翻倍 → %S\n" (area (animal))))

;;; ---- 4) 无方法、无后继与 t 兜底 ---------------------------------------

(princ "== 4) 无方法 / 无后继 / t 兜底 ==\n")

(cl-defgeneric greet (x)
  "问候 X。")

(cl-defmethod greet ((a animal))
  (format "你好,%s" (slot-value a 'name)))

(princ (format "  无匹配方法     → %S\n"
               (condition-case err
                   (progn (greet 42) nil)
                 (error (car err)))))

(cl-defmethod greet ((x t))
  (format "兜底:%s" (type-of x)))

(princ (format "  定义 t 兜底之后 → %S\n" (greet 42)))

(cl-defgeneric solo (x)
  "只有一个方法的泛型。")

(cl-defmethod solo ((_a animal))
  ;; 没有更一般的方法,cl-call-next-method 无路可走
  (condition-case err
      (cl-call-next-method)
    (error (car err))))

(princ (format "  next 无后继     → %S\n" (solo (animal))))

;;; ---- 5) 多继承的派发顺序(C3) ------------------------------------------

(princ "== 5) 多继承派发:前位父类优先 ==\n")

(defclass wings ()
  ()
  "翅膀能力。")

(defclass fur ()
  ()
  "毛发能力。")

(defclass bat (wings fur)
  ()
  "蝙蝠:先 wings 后 fur。")

(cl-defgeneric feature (x)
  "返回 X 的标志性能力。")

(cl-defmethod feature ((_w wings)) "会飞")
(cl-defmethod feature ((_f fur)) "有毛")

(cl-defmethod feature ((_b bat))
  (concat "蝙蝠(" (cl-call-next-method) ")"))

(princ (format "  bat 沿 C3 链先找到 wings → %S\n" (feature (bat))))

;;; ---- 6) initialize-instance -------------------------------------------

(princ "== 6) initialize-instance 构造后钩子 ==\n")

(defclass rect ()
  ((w :initarg :w :initform 0 :type number)
   (h :initarg :h :initform 0 :type number)
   (a :initform 0 :type number))
  "矩形:w、h 由构造给定,a 是派生面积。")

(cl-defmethod initialize-instance ((r rect) &rest _slots)
  ;; 先让标准构造完成填槽,再算派生槽
  (cl-call-next-method)
  (setf (slot-value r 'a) (* (slot-value r 'w) (slot-value r 'h))))

(princ (format "  rect :w 3 :h 4 → 派生槽 a = %S\n"
               (slot-value (rect :w 3 :h 4) 'a)))

;;; ---- 7) clone ----------------------------------------------------------

(princ "== 7) clone 复制对象 ==\n")

(let* ((r1 (rect :w 5 :h 6))
       (r2 (clone r1))
       (r3 (clone r1 :w 9)))
  (setf (slot-value r2 'w) 99)
  (princ (format "  原对象 w       → %S(克隆是独立副本)\n" (slot-value r1 'w)))
  (princ (format "  克隆后改 r2    → %S\n" (slot-value r2 'w)))
  (princ (format "  clone 带 initarg → w=%S h=%S(覆写 w,其余照抄)\n"
                 (slot-value r3 'w) (slot-value r3 'h))))

;;; ---- 8) (subclass 类) 特化符 -------------------------------------------

(princ "== 8) (subclass 类) 特化符:类方法 ==\n")

(cl-defgeneric describe-class (c)
  "描述类 C。")

(cl-defmethod describe-class ((c (subclass animal)))
  (format "类 %s 属于 animal 家族" c))

(princ (format "  传类符号 → %S\n" (describe-class 'dog)))

;;; ---- 9) 打印体系 --------------------------------------------------------

(princ "== 9) 打印:默认 record 语法 ==\n")

(let ((r (rect :w 3 :h 4)))
  (princ (format "  %%S / prin1 → %S\n" r))
  (princ (format "  %%s / princ  → %s\n" r)))

(cl-defmethod describe ((r rect))
  (format "矩形 %dx%d" (slot-value r 'w) (slot-value r 'h)))

(princ (format "  自定义普通方法 → %S\n" (describe (rect :w 3 :h 4))))

(princ "==== 52 结束 ====\n")
