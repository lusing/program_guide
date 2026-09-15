;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 22 - 错误处理：condition-case / unwind-protect / catch-throw / signal
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "22-errors.el")'
;;; 运行：emacs -Q --batch -l 22-errors.el
;;; ============================================================

;;; 1) Emacs 的错误由「错误符号（error symbol）」+「数据」组成。
;;;    (error "格式串" ...) 会 signal 一个 'error；也可以直接 (signal 'wrong-type-argument ...)。
;;;    错误信息用 (error-message-string ERR) 取。

;;; 2) condition-case 是最常用的捕获结构：
;;;      (condition-case VAR
;;;          受保护的代码
;;;        (错误符号1 处理代码)      ; VAR 绑定到 (符号 . 数据)
;;;        (错误符号2 处理代码)
;;;        (:success 处理代码))      ; 没出错时执行
(princ (format "2) 捕获 error: %S\n"
               (condition-case e
                   (error "出错了：%s" "演示")
                 (error (list 'caught (error-message-string e))))))

;;; 3) 只处理特定错误。error 是所有错误的「父类」，
;;;    写 (error ...) 会一网打尽；写具体符号才精准。
;;;    常见的具体错误符号：wrong-type-argument、void-function、
;;;    void-variable、args-out-of-range、end-of-buffer、file-error、user-error。
(princ (format "3) 精准捕获 wrong-type-argument: %S\n"
               (condition-case e
                   (+ 1 "不是数字")
                 (wrong-type-argument (list 'caught (error-message-string e))))))
(princ (format "   不匹配的 handler 会继续往上抛: %S\n"
               (condition-case nil
                   (condition-case nil
                       (+ 1 "x")
                     (void-function 'nope))
                 (wrong-type-argument '外层接住了))))

;;; 4) 【坑】(condition-case nil ...) 用 nil 当变量时会**忽略错误详情**，
;;;    而且字节编译器对未使用的变量会警告。需要详情就给变量并用到它，
;;;    不需要就写 nil。

;;; 5) 只关心「出错没出错」时，用 ignore-errors 更简洁：
;;;    出错返回 nil，正常返回 body 的值。
(princ (format "5) ignore-errors 正常: %S，出错: %S\n"
               (ignore-errors (+ 1 2))
               (ignore-errors (+ 1 "x"))))
;;;    【坑】ignore-errors 会把「返回值恰好是 nil」和「出错」混在一起，
;;;    分不清的时候老老实实用 condition-case。

;;; 6) unwind-protect：无论是否出错都执行清理。
;;;      (unwind-protect
;;;          主体
;;;       清理代码...)
;;;    典型用途：关文件、删临时文件、移除 advice、恢复全局变量。
(defvar demo-cleanup-log nil)
(defun demo-risky ()
  "演示 unwind-protect。"
  (unwind-protect
      (progn
        (push "干活" demo-cleanup-log)
        (error "中途失败"))
    (push "清理" demo-cleanup-log)))
(princ (format "6) %S\n"
               (progn (ignore-errors (demo-risky))
                      (nreverse demo-cleanup-log))))

;;; 7) 自定义错误类型：define-error。第三个参数是「父错误符号」。
;;;    有了自己的错误符号，别人就能精准捕获你的错误。
(define-error 'demo-network-error "网络相关错误")
(define-error 'demo-timeout-error "超时" 'demo-network-error)
(princ (format "7) 自定义错误: %S\n"
               (condition-case e
                   (signal 'demo-timeout-error '("连接超时" 30))
                 (demo-network-error (list 'caught (error-message-string e))))))
;;;    注意：捕获父类型 demo-network-error 也能接住子类型 demo-timeout-error，
;;;    这就是为什么要给错误分类。

;;; 8) user-error：给用户看的错误。它**不会**进入 debug（debug-on-error 时也不弹 backtrace），
;;;    适合「用户输入不合法」这类预期内的失败。
(princ (format "8) user-error: %S\n"
               (condition-case e
                   (user-error "请先选中一段文本")
                 (user-error (error-message-string e)))))

;;; 9) catch / throw：非局部退出，是 Elisp 里唯一的「提前 return」手段。
;;;    throw 指定 tag 和值；catch 返回那个值。
(princ (format "9) catch/throw: %S\n"
               (catch 'found
                 (dolist (x '(1 2 3 4 5))
                   (when (= x 3)
                     (throw 'found (format "在 %d 处跳出" x))))
                 "没找到")))

;;; 10) 【坑】catch 的 tag 如果没被 throw，catch 返回 body 最后一个表达式的值；
;;;     而 throw 找不到对应的 catch 会报 no-catch 错误。
(princ (format "10) 没有 throw 时: %S\n"
               (catch 'nobody (progn 1 2 3))))
;;;    throw 找不到 catch 会 signal 一个 no-catch 错误 —— 内置错误符号，
;;;    但字节编译器不认识它（会报 free variable），所以这里用 error 兜住。
(princ (format "    没有 catch 时: %S\n"
               (condition-case e
                   (throw 'no-such-tag 1)
                 (error (error-message-string e)))))

;;; 11) 断言：cl-assert（来自 cl-lib）在字节编译且关闭 debug 时会被优化掉，
;;;     适合写「内部不变量」；给用户看的校验用 user-error。
(require 'cl-lib)
(princ (format "11) cl-assert 通过: %S\n"
               (progn (cl-assert (= 1 1)) "ok")))
(princ (format "    cl-assert 失败: %S\n"
               (condition-case nil
                   (cl-assert (= 1 2))
                 (error '断言失败))))

;;; 12) 调试开关：
;;;     debug-on-error = t  出错时进入调试器（开发时开）
;;;     debug-on-quit  = t  C-g 时进入调试器（排查卡死很有用）
;;;     toggle-debug-on-error  M-x 里直接切
;;;     【坑】写交互式扩展时，把错误直接抛给用户是很差的体验；
;;;     预期内的失败用 user-error，意外失败用 condition-case 兜住并给出提示。
(princ "12) 开发期建议 M-x toggle-debug-on-error\n")

(princ "==== 22 结束 ====\n")
