;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 48 - 类型与结构：cl-defstruct、cl-assert 与 cl-print
;;;   CL 手册剩余五章一次讲完：第 4 章 Predicates（cl-typep、
;;;   cl-deftype、cl-equalp）、第 9 章 Numbers（cl-gcd、cl-floor
;;;   家族、cl-random、浮点常量）、第 12 章 Structures
;;;   （cl-defstruct 及其选项与内省）、第 2 章 Printing
;;;   （cl-prin1 与 cl-print-object 泛型）、第 13 章
;;;   Assertions and Errors（cl-assert、cl-check-type）。
;;;   每条规则都在 Emacs 31.1 上实测一遍。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "48-types-structs.el")'
;;; 运行：emacs -Q --batch -l 48-types-structs.el
;;; ============================================================
(require 'cl-lib)
(require 'cl-print)

;;; ---------- 1) cl-typep：CL 类型判定 ----------
(princ "== 1) cl-typep ==\n")
(princ (format "  (cl-typep 5 'integer) ≡ (integerp 5) → %S\n"
               (cl-typep 5 'integer)))
(princ (format "  t 是一切、nil 是空集：%S / %S\n"
               (cl-typep 'anything t) (cl-typep 'anything nil)))
(princ (format "  null ≡ nil 对象；atom ≡ 非 cons：%S / %S / %S\n"
               (cl-typep nil 'null) (cl-typep 5 'atom) (cl-typep '(1) 'atom)))
(princ (format "  character 匹配 0..255 的整数：%S / %S\n"
               (cl-typep 65 'character) (cl-typep 256 'character)))
(princ (format "  (integer 0 10) 闭区间：%S / %S / %S\n"
               (cl-typep 0 '(integer 0 10))
               (cl-typep 10 '(integer 0 10))
               (cl-typep 11 '(integer 0 10))))
(let ((exclusive '(integer 0 (5))))
  (princ (format "  单层列表上界=排他：(integer 0 (5)) 里 4 → %S、5 → %S；星号无界 → %S\n"
                 (cl-typep 4 exclusive)
                 (cl-typep 5 exclusive)
                 (cl-typep 999 '(integer 0 *)))))
(princ (format "  or 组合：(or integer (float 0 *)) 判 2.5 → %S、-1.5 → %S\n"
               (cl-typep 2.5 '(or integer (float 0 *)))
               (cl-typep -1.5 '(or integer (float 0 *)))))
(princ (format "  (member 1 2 3 4) ≡ (integer 1 4)：判 3 → %S、5 → %S\n"
               (cl-typep 3 '(member 1 2 3 4))
               (cl-typep 5 '(member 1 2 3 4))))
(princ (format "  (satisfies oddp) 调谓词：判 3 → %S、4 → %S\n"
               (cl-typep 3 '(satisfies oddp)) (cl-typep 4 '(satisfies oddp))))
(princ (format "  cl-coerce 序列互转：%S %S %S\n"
               (cl-coerce '(?a ?b) 'string)
               (cl-coerce "ab" 'list)
               (cl-coerce '(1 2) 'vector)))
(princ (format "  cl-coerce 字符与浮点：%S %S %S\n"
               (cl-coerce "x" 'character)
               (cl-coerce 'y 'character)
               (cl-coerce 3 'float)))
(princ "  类型名是符号或「符号开头」的列表；cl-typep 找名叫\n")
(princ "  类型名-p 的谓词来判定——结构类型因此能被识别（见第 9 节）。\n")

;;; ---------- 2) cl-deftype：派生类型 ----------
(princ "\n== 2) cl-deftype ==\n")
(cl-deftype unsigned-byte (&optional bits)
  (list 'integer 0 (if (eq bits '*) bits (1- (ash 1 bits)))))
(princ (format "  (unsigned-byte 8) ≡ (integer 0 255)：判 200 → %S、300 → %S\n"
               (cl-typep 200 '(unsigned-byte 8))
               (cl-typep 300 '(unsigned-byte 8))))
(princ (format "  裸符号 ≡ 不带参调用：unsigned-byte ≡ (integer 0 *)：判 -1 → %S、999 → %S\n"
               (cl-typep -1 'unsigned-byte)
               (cl-typep 999 'unsigned-byte)))
(princ (format "  未给默认值的 &optional 参数默认 *：→ %S\n"
               (cl-typep 999999999 'unsigned-byte)))
(princ "  cl-deftype 像 defmacro：遇类型名就把 body 展开成等价\n")
(princ "  类型说明符。cl-typecase、cl-check-type、cl-map 的结果\n")
(princ "  类型实参吃的都是同一套类型名。\n")

;;; ---------- 3) cl-equalp：更宽松的相等 ----------
(princ "\n== 3) cl-equalp ==\n")
(princ (format "  字符串大小写不敏感：%S（equal 是 %S）\n"
               (cl-equalp "Foo" "foo") (equal "Foo" "foo")))
(princ (format "  数字跨类型：3 vs 3.0 → %S（equal 是 %S）\n"
               (cl-equalp 3 3.0) (equal 3 3.0)))
(princ (format "  向量与 cons 递归比较：%S\n"
               (cl-equalp [1 (2 . 3) "Ab"] [1 (2 . 3) "aB"])))
(princ (format "  字符串不与整数向量比（与 CL 的差异）：%S\n"
               (cl-equalp "ab" [?a ?b])))
(princ "  手册：CL 的 equalp 还按大小写不敏感比字符——Emacs 没有\n")
(princ "  独立字符类型，这条被略去；其余对象一律按 equal 比。\n")

;;; ---------- 4) 数字小函数：cl-digit-char-p / cl-gcd / cl-lcm / cl-isqrt ----------
(princ "\n== 4) 数字小函数 ==\n")
(princ (format "  cl-digit-char-p 返回数字值：?9 十进制 → %S；?f 十六进制 → %S；?f 十进制 → %S\n"
               (cl-digit-char-p ?9)
               (cl-digit-char-p ?f 16)
               (cl-digit-char-p ?f 10)))
(princ (format "  cl-gcd 12 18 → %S；单参取绝对值 → %S；零参 → %S\n"
               (cl-gcd 12 18) (cl-gcd -12) (cl-gcd)))
(princ (format "  cl-lcm 4 6 → %S；零参 → %S\n"
               (cl-lcm 4 6) (cl-lcm)))
(princ (format "  cl-isqrt 整数平方根：17 → %S、16 → %S\n"
               (cl-isqrt 17) (cl-isqrt 16)))
(princ "  cl-digit-char-p 命中返回的是数字值而非 t——\n")
(princ "  「判字符是否为数字」与「取该数字的值」一步完成。\n")

;;; ---------- 5) 整除四兄弟：cl-floor / cl-ceiling / cl-truncate / cl-round 与 cl-mod / cl-rem ----------
(princ "\n== 5) 整除四兄弟 ==\n")
(princ (format "  cl-floor 7 2 → %S；-7 2 → %S（商向 -∞ 取整）\n"
               (cl-floor 7 2) (cl-floor -7 2)))
(princ (format "  cl-ceiling 7 2 → %S（商向 +∞ 取整，余数 ≤ 0）\n"
               (cl-ceiling 7 2)))
(princ (format "  cl-truncate -7 2 → %S（商向 0 取整）\n"
               (cl-truncate -7 2)))
(princ (format "  cl-round 平局靠偶：5 2 → %S；7 2 → %S\n"
               (cl-round 5 2) (cl-round 7 2)))
(princ (format "  单参浮点：(cl-floor -2.5) → %S（首值是整数、余值是浮点）\n"
               (cl-floor -2.5)))
(princ (format "  cl-mod ≡ cl-floor 第二值 → %S；cl-rem ≡ cl-truncate 第二值 → %S；原生 %% → %S\n"
               (cl-mod -7 2) (cl-rem -7 2) (% -7 2)))
(princ "  返回值是「商 余数」两元素列表（Emacs Lisp 没有多值）；\n")
(princ "  恒有 q*y+r=x。cl-floor x ≡ cl-floor x 1。负数取模想要\n")
(princ "  非负结果用 cl-mod，原生 %% 与 cl-rem 同号于被除数。\n")

;;; ---------- 6) cl-parse-integer ----------
(princ "\n== 6) cl-parse-integer ==\n")
(princ (format "  十进制直取 → %S；:radix 16 → %S；空白忽略 → %S\n"
               (cl-parse-integer "42")
               (cl-parse-integer "ff" :radix 16)
               (cl-parse-integer "  42  ")))
(princ (format "  :start/:end 窗口 → %S\n"
               (cl-parse-integer "xx42yy" :start 2 :end 4)))
(princ (format "  垃圾默认报错 → %S\n"
               (condition-case err
                   (cl-parse-integer "42junk")
                 (error (error-message-string err)))))
(princ (format "  :junk-allowed t 容忍尾部 → %S；全非数字 → %S\n"
               (cl-parse-integer "42junk" :junk-allowed t)
               (cl-parse-integer "junk" :junk-allowed t)))
(princ "  与 string-to-number 的差异：可换进制、可划窗口、\n")
(princ "  可严格控制「解析不出就报错」。\n")

;;; ---------- 7) 随机数：cl-random 与 cl-make-random-state ----------
(princ "\n== 7) 随机数 ==\n")
(let ((s (cl-make-random-state 42)))
  (princ (format "  种子 42（Emacs 扩展：整数直接当种子）前三发 → %S %S %S\n"
                 (cl-random 100 s) (cl-random 100 s) (cl-random 100 s))))
(let ((s1 (cl-make-random-state 7))
      (s2 (cl-make-random-state 7)))
  (princ (format "  同种子两个 state 序列相同 → %S vs %S\n"
                 (cl-random 1000 s1) (cl-random 1000 s2))))
(let ((s (cl-make-random-state 1)))
  (princ (format "  (cl-random 1.0 s) 返回同类型：[0,1) 的浮点 → %S\n"
                 (cl-random 1.0 s))))
(princ (format "  cl-random-state-p → %S / %S\n"
               (cl-random-state-p (cl-make-random-state))
               (cl-random-state-p 'nope)))
(princ "  省略 state 用全局 cl--random-state（多程序交错、不可复现）；\n")
(princ "  要可复现就显式造 state——state 可打印可 read，调试时\n")
(princ "  (cl-make-random-state t) 取时间种子后把 state 存盘即可。\n")

;;; ---------- 8) 浮点常量：cl-float-limits 一族 ----------
(princ "\n== 8) 浮点常量 ==\n")
(cl-float-limits)
(princ (format "  cl-most-positive-float → %S\n" cl-most-positive-float))
(princ (format "  cl-least-positive-float（次正规最小正数）→ %S\n"
               cl-least-positive-float))
(princ (format "  cl-least-positive-normalized-float → %S\n"
               cl-least-positive-normalized-float))
(princ (format "  cl-float-epsilon → %S\n" cl-float-epsilon))
(princ (format "  1.0 + epsilon ≠ 1.0：%S；1.0 + epsilon/2 ≡ 1.0：%S\n"
               (= 1.0 (+ 1.0 cl-float-epsilon))
               (= 1.0 (+ 1.0 (/ cl-float-epsilon 2)))))
(princ "  Emacs 只有 IEEE binary64 一种浮点，所以常量一族只有一套；\n")
(princ "  必须先调 cl-float-limits 初始化，否则值未指定。\n")

;;; ---------- 9) cl-defstruct：基础四件套 ----------
(princ "\n== 9) cl-defstruct 基础 ==\n")
(cl-defstruct person first-name (age 0) sex)
(let ((birthday-boy (make-person :first-name "Peter" :age 23 :sex "male")))
  (princ (format "  构造（31.1 默认 record 表示）→ %S\n" birthday-boy))
  (princ (format "  缺省槽：age 默认 0、其余 nil → %S\n" (make-person)))
  (princ (format "  访问子 → %S / %S\n"
                 (person-first-name birthday-boy) (person-age birthday-boy)))
  (setf (person-first-name birthday-boy) "Old Peter")
  (cl-incf (person-age birthday-boy))
  (princ (format "  setf + cl-incf 改槽后 → %S\n" birthday-boy))
  (let ((other (copy-person birthday-boy)))
    (princ (format "  copy-person：eq → %S，但槽值 eq → %S\n"
                   (eq birthday-boy other)
                   (eq (person-first-name birthday-boy)
                       (person-first-name other)))))
  (princ (format "  person-p：本尊 %S / 向量 %S / 字符串 %S\n"
                 (person-p birthday-boy) (person-p [1 2 3]) (person-p "Bogus")))
  (princ (format "  伪造 tag 的向量：%S（record 表示下骗不过；旧 vector 实现会中招）\n"
                 (person-p '[cl-struct-person counterfeit person object])))
  (princ (format "  #s 语法可 read 回来：%S\n"
                 (person-p (car (read-from-string
                                 (prin1-to-string birthday-boy))))))
  (princ (format "  cl-typep 认结构类型（靠 person-p）→ %S\n"
                 (cl-typep birthday-boy 'person))))
(princ "  cl-defstruct 自动生成：构造器 make-名、复制器 copy-名、\n")
(princ "  谓词 名-p、每个槽的访问子（可 setf 的 place）。\n")

;;; ---------- 10) cl-defstruct：选项与内省 ----------
(princ "\n== 10) cl-defstruct 选项与内省 ==\n")
(cl-defstruct (employee (:conc-name emp-)
                        (:constructor create-employee
                                      (name &optional (age 30))))
  name (age 0))
(let ((e (create-employee "Jane")))
  (princ (format "  BOA 构造器（位置参数）+ :conc-name → %S，年龄 %S\n"
                 e (emp-age e))))
(cl-defstruct point (x 0 :read-only t) (y 0))
(let ((p (make-point :x 1 :y 2)))
  (setf (point-y p) 9)
  (princ (format "  :read-only 槽：x 只能读（%S），y 可改 → %S\n" (point-x p) p)))
(cl-defstruct (astronaut (:include person (age 45)))
  helmet-size (favorite-beverage 'tang))
(let ((joe (make-person :first-name "Joe"))
      (buzz (make-astronaut :first-name "Buzz")))
  (princ (format "  :include 继承槽并覆盖默认 → %S\n" buzz))
  (princ (format "  astronaut 也是 person：%S；person 不是 astronaut：%S\n"
                 (person-p buzz) (astronaut-p joe)))
  (princ (format "  父访问子用于子类 → %S；子访问子用于父类报错 → %S\n"
                 (person-first-name buzz)
                 (condition-case err
                     (astronaut-first-name joe)
                   (error (error-message-string err))))))
(cl-defstruct (pet (:type list) :named) name)
(princ (format "  (:type list) :named 用列表表示、tag 在首位 → %S\n" (make-pet)))
(princ (format "  内省：sequence-type → %S；slot-offset age → %S\n"
               (cl-struct-sequence-type 'person)
               (cl-struct-slot-offset 'person 'age)))
(let ((b (make-person :first-name "Abe" :age 50)))
  (princ (format "  slot-info → %S\n"
                 (mapcar #'car (cl-struct-slot-info 'person))))
  (princ (format "  cl-struct-slot-value 读 → %S；" (cl-struct-slot-value 'person 'age b)))
  (setf (cl-struct-slot-value 'person 'age b) 51)
  (princ (format "setf 后 → %S\n" (person-age b))))
(princ "  :include 是「很有限的继承」：子类型继承全部槽，父谓词\n")
(princ "  认子对象。选项还有 :copier/:predicate/:noinline/:type/\n")
(princ "  :named/:initial-offset；:print-function 被忽略——想定制\n")
(princ "  打印请用 cl-print-object（下两节）。\n")

;;; ---------- 11) cl-print：面向人类读者的打印 ----------
(princ "\n== 11) cl-print ==\n")
(let ((b (make-person :first-name "Peter" :age 23 :sex "male")))
  (princ (format "  cl-prin1-to-string 结构 → %S\n" (cl-prin1-to-string b)))
  (princ (format "  原生 prin1-to-string 对照 → %S\n" (prin1-to-string b)))
  (princ (format "  cl-print-string-length=4 缩略 → %S\n"
                 (let ((cl-print-string-length 4))
                   (cl-prin1-to-string "hello world"))))
  (princ (format "  cl-print-to-string-with-limit 8 字符内 → %S\n"
                 (cl-print-to-string-with-limit #'cl-prin1 '(1 2 3 4 5) 8))))
(cl-defstruct city name (population 0))
(cl-defmethod cl-print-object ((c city) stream)
  (princ (format "#<city %s pop %d>" (city-name c) (city-population c)) stream))
(let ((c (make-city :name "Paris" :population 2100000)))
  (princ (format "  自定义 cl-print-object 后 cl-prin1 → %S\n" (cl-prin1-to-string c)))
  (princ (format "  原生 prin1 不走泛型，仍按 record 打印 → %S\n" (prin1-to-string c))))
(princ "  cl-print-object 是 cl-defgeneric：给自己的类型写\n")
(princ "  cl-defmethod 即可扩展 cl-prin1。用了省略号就该配套写\n")
(princ "  cl-print-object-contents（点省略号可展开，缓冲区里有效）。\n")

;;; ---------- 12) 断言：cl-assert 与 cl-check-type ----------
(princ "\n== 12) 断言 ==\n")
(princ (format "  cl-assert 通过返回 nil → %S\n" (cl-assert (> 3 2))))
(princ (format "  失败报错含测试式 → %S\n"
               (condition-case err
                   (cl-assert (> 2 3))
                 (error (error-message-string err)))))
(let ((x 5))
  (princ (format "  show-args=t 附带实参值 → %S\n"
                 (condition-case err
                     (cl-assert (> x 10) t "x is too small")
                   (error (error-message-string err))))))
(let ((n 5) (f 1.5))
  (princ (format "  cl-check-type 通过返回 nil → %S\n" (cl-check-type n integer)))
  (princ (format "  失败抛 wrong-type-argument → %S\n"
                 (condition-case err
                     (cl-check-type f integer)
                   (error (error-message-string err))))))
(let ((x 0))
  (princ (format "  自定义串代替类型名 → %S\n"
                 (condition-case err
                     (cl-check-type x (integer 1 *) "a positive integer")
                   (error (error-message-string err))))))
(princ "  断言只做「健全性检查」：speed=3 且 safety<3 时字节编译器\n")
(princ "  会把它们优化掉——所以断言里千万别放副作用。CL 里\n")
(princ "  check-type 首参必须是 place（可续错误），Emacs 无此概念。\n")

(princ "==== 48 结束 ====\n")
