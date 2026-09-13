;;;; ============================================================
;;;; 10-format.lisp — format 格式化输出详解
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 基本指令（~A ~S ~D ~F ~% ~& ~T）
;;;;   2. 数字格式化
;;;;   3. 字符与字符串格式化
;;;;   4. 条件与迭代指令
;;;;   5. 缩进与换行控制
;;;;   6. 参数跳转与默认值
;;;;   7. 自定义 format 指令
;;;;   8. 实用格式化技巧
;;;;
;;;; 运行方式：sbcl --script 10-format.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. 基本指令
;;; ----------------------------------------------------------

(format t "~%=== 基本指令 ===~%")

;; ~A — 美学输出（人类可读，字符串不带引号）
(format t "~A~%" "hello")        ; => hello
(format t "~A~%" 42)             ; => 42
(format t "~A~%" 'symbol)        ; => SYMBOL
(format t "~A~%" nil)            ; => NIL

;; ~S — 可读输出（带引号，可被 read 读回）
(format t "~S~%" "hello")        ; => "hello"
(format t "~S~%" 'symbol)        ; => SYMBOL
(format t "~S~%" '(1 2 3))       ; => (1 2 3)

;; ~D — 十进制整数
(format t "~D~%" 42)
(format t "~D~%" -17)

;; ~F — 浮点数
(format t "~F~%" 3.14159)
(format t "~,2F~%" 3.14159)      ; 保留2位小数
(format t "~,4F~%" 3.14159)      ; 保留4位小数

;; ~% — 换行
(format t "第一行~%第二行~%")

;; ~& — 如果不在行首则换行
(format t "a~&b~&c~%")

;; ~T — 制表符（跳到指定列）
(format t "~10T姓名~20T年龄~%")
(format t "~10T张三~20T30~%")

;; ~~ — 输出波浪号本身
(format t "波浪号: ~~~%")

;; ~* — 跳过参数
(format t "~A ~* ~A~%" "first" "skipped" "second")


;;; ----------------------------------------------------------
;;; 2. 数字格式化
;;; ----------------------------------------------------------

(format t "~%=== 数字格式化 ===~%")

;; 十进制
(format t "十进制: ~D~%" 255)
(format t "带逗号: ~:D~%" 1234567890)    ; 每3位加逗号
(format t "宽度10: ~10D~%" 42)           ; 右对齐，宽度10
(format t "宽度10左对齐: ~-10D|~%" 42)   ; 左对齐
(format t "补零: ~10,'0D~%" 42)          ; 用0填充

;; 二进制
(format t "二进制: ~B~%" 255)
(format t "二进制(8位): ~8,'0B~%" 42)

;; 八进制
(format t "八进制: ~O~%" 255)

;; 十六进制
(format t "十六进制: ~X~%" 255)
(format t "十六进制(大写): ~@X~%" 255)

;; 任意进制
(format t "36进制: ~36R~%" 1234567890)

;; 英文数字
(format t "英文: ~R~%" 42)
(format t "英文序数: ~:R~%" 42)
(format t "罗马数字: ~@R~%" 42)
(format t "旧罗马数字: ~:@R~%" 42)

;; 浮点数详细控制
(format t "默认: ~F~%" 3.14159265)
(format t "2位小数: ~,2F~%" 3.14159265)
(format t "宽度10,2位: ~10,2F~%" 3.14159265)
(format t "科学计数: ~E~%" 31415.9265)
(format t "科学计数(2位): ~,2E~%" 31415.9265)
(format t "通用: ~G~%" 0.00000123)
(format t "货币: ~$~%" 1234.56)
(format t "货币(3位): ~,3$~%" 1234.56789)

;; 百分比
(format t "百分比: ~,1F%~%" (* 100 0.856))


;;; ----------------------------------------------------------
;;; 3. 字符与字符串格式化
;;; ----------------------------------------------------------

(format t "~%=== 字符/字符串格式化 ===~%")

;; ~C — 字符
(format t "字符: ~C~%" #\a)
(format t "字符名: ~:C~%" #\Newline)
(format t "字符(可读): ~:C~%" #\Space)

;; ~A 带宽度
(format t "右对齐: ~20A|~%" "hello")
(format t "左对齐: ~20@A|~%" "hello")
(format t "居中: ~20:@A|~%" "hello")

;; 大小写转换
(format t "~(~A~)~%" "HELLO WORLD")        ; 转小写
(format t "~@(~A~)~%" "hello world")        ; 首字母大写
(format t "~:(~A~)~%" "hello world")        ; 每个单词首字母大写
(format t "~:@(~A~)~%" "hello world")       ; 全大写

;; 截断
(format t "截断: ~5A~%" "hello world")      ; 只显示前5个字符


;;; ----------------------------------------------------------
;;; 4. 条件与迭代指令
;;; ----------------------------------------------------------

(format t "~%=== 条件与迭代 ===~%")

;; ~[...~] — 条件选择
(format t "~[零~;一~;二~;三~]~%" 0)
(format t "~[零~;一~;二~;三~]~%" 2)
(format t "~[零~;一~;二~;三~;其他~]~%" 99)  ; 超出范围

;; ~:[...~] — 布尔条件
(format t "~:[假~;真~]~%" t)
(format t "~:[假~;真~]~%" nil)

;; ~@[...~] — 如果参数非 nil 则使用
(format t "~@[值是: ~A~]~@[, 另一个: ~A~]~%" "hello" nil)

;; ~{...~} — 迭代列表
(format t "~{~A ~}~%" '(1 2 3 4 5))
(format t "~{~A=~A ~}~%" '(:a 1 :b 2 :c 3))

;; 迭代带分隔符
(format t "~{~A~^, ~}~%" '(apple banana cherry))
(format t "~{~A~^ → ~}~%" '(start middle end))

;; 迭代哈希表
(let ((ht (make-hash-table)))
  (setf (gethash 'name ht) "SBCL"
        (gethash 'type ht) "编译器")
  (format t "~{~A: ~A~%~}"
          (loop for k being the hash-keys of ht
                using (hash-value v)
                append (list k v))))

;; ~:{...~} — 迭代子列表
(format t "~:{姓名:~A 年龄:~A~%~}"
        '(("张三" 30) ("李四" 25) ("王五" 35)))

;; ~@{...~} — 对剩余参数迭代
(format t "~@{~A ~}~%" "a" "b" "c" "d")


;;; ----------------------------------------------------------
;;; 5. 缩进与换行控制
;;; ----------------------------------------------------------

(format t "~%=== 缩进与换行 ===~%")

;; ~I — 缩进
(format t "~4I缩进4格~%")
(format t "~8I缩进8格~%")

;; ~<...~> — 逻辑块（自动换行）
(format t "~<姓名~;年龄~;邮箱~:>~%" nil)

;; ~_ — 条件换行（在 pretty printing 模式下）
;; ~<...~:> 配合 pprint-logical-block 使用

;; 多行格式化
(format t "~%表格:~%")
(format t "~A~%" (make-string 40 :initial-element #\-))
(format t "~|~20A~|~20A~|~%" "姓名" "年龄")
(format t "~A~%" (make-string 40 :initial-element #\-))
(format t "~|~20A~|~20A~|~%" "张三" "30")
(format t "~|~20A~|~20A~|~%" "李四" "25")
(format t "~A~%" (make-string 40 :initial-element #\-))


;;; ----------------------------------------------------------
;;; 6. 参数跳转与默认值
;;; ----------------------------------------------------------

(format t "~%=== 参数控制 ===~%")

;; ~n* — 跳过 n 个参数
(format t "~A ~2* ~A~%" "a" "skip1" "skip2" "b")

;; ~:* — 回到上一个参数
(format t "~A ~:*~A~%" "重复")

;; ~n@* — 跳到第 n 个参数
(format t "~A ~0@*~A~%" "跳回")

;; V 参数 — 从参数列表获取值
(format t "~V,A~%" 10 3.14159)  ; 宽度10，精度由参数决定
(format t "~V,V,A~%" 10 2 3.14159)

;; # 参数 — 剩余参数个数
(format t "参数个数=~D, 参数列表: ~{~A ~}~%" 3 '(1 2 3))

;; 默认参数
(format t "~,2F~%" 3.14159)     ; 精度2
(format t "~,,,F~%" 3.14159)    ; 使用默认值


;;; ----------------------------------------------------------
;;; 7. 实用格式化技巧
;;; ----------------------------------------------------------

(format t "~%=== 实用技巧 ===~%")

;; 格式化表格
(defun print-table (headers rows)
  (let ((widths (mapcar (lambda (h)
                          (+ 2 (apply #'max (length (string h))
                                      (mapcar (lambda (row)
                                                (length (format nil "~A" row)))
                                              rows))))
                        headers)))
    ;; 打印表头
    (format t "~{~A~^ | ~}~%"
            (mapcar (lambda (h w)
                      (format nil "~V@A" w h))
                    headers widths))
    ;; 打印分隔线
    (format t "~{~A~^-+-~}~%"
            (mapcar (lambda (w) (make-string w :initial-element #\-))
                    widths))
    ;; 打印数据行
    (dolist (row rows)
      (format t "~{~A~^ | ~}~%"
              (mapcar (lambda (cell w)
                        (format nil "~VA" w cell))
                      row widths)))))

(print-table '("姓名" "年龄" "城市")
             '(("张三" 30 "北京")
               ("李四" 25 "上海")
               ("王五" 35 "广州")))

;; 进度条
(defun print-progress (current total &optional (width 40))
  (let* ((ratio (/ current total))
         (filled (round (* ratio width)))
         (empty (- width filled)))
    (format t "~C[~A~A] ~,1F%~%"
            #\Return
            (make-string filled :initial-element #\=)
            (make-string empty :initial-element #\Space)
            (* 100 ratio))))

(format t "~%进度条:~%")
(print-progress 30 100)
(print-progress 70 100)
(print-progress 100 100)

;; 树形输出
(defun print-tree (tree &optional (indent 0))
  (format t "~V@T~A~%" indent (first tree))
  (dolist (child (rest tree))
    (if (listp child)
        (print-tree child (+ indent 2))
        (format t "~V@T~A~%" (+ indent 2) child))))

(format t "~%目录树:~%")
(print-tree '("项目"
              ("src" "main.lisp" "utils.lisp")
              ("docs" "README.md")
              ("tests" "test-main.lisp")))

;; 格式化数字为人类可读
(defun human-readable-size (bytes)
  (cond ((< bytes 1024)        (format nil "~D B" bytes))
        ((< bytes (expt 1024 2)) (format nil "~,1F KB" (/ bytes 1024)))
        ((< bytes (expt 1024 3)) (format nil "~,1F MB" (/ bytes (expt 1024 2))))
        (t                        (format nil "~,1F GB" (/ bytes (expt 1024 3))))))

(format t "~A~%" (human-readable-size 500))
(format t "~A~%" (human-readable-size 2048))
(format t "~A~%" (human-readable-size 5242880))
(format t "~A~%" (human-readable-size 10737418240))

;; format nil — 返回字符串而不输出
(let ((str (format nil "结果是: ~,2F" 3.14159)))
  (format t "format nil 返回: ~A~%" str))

(format t "~%=== 例程 10 执行完毕 ===~%")
