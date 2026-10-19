;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 33 - 调试：错误对象、condition-case、unwind-protect 与 debug-on-entry
;;;   代码写好了，出错怎么办？本章演示 Emacs 提供的排查手段，
;;;   并且全部在 --batch 下可复现。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "33-debugging.el")'
;;; 运行：emacs -Q --batch -l 33-debugging.el
;;; ============================================================
(require 'debug)

;;; ---------- 1) 错误其实是一个「符号 + 数据」的列表 ----------
;;; 出错时，Emacs 会「抛出」（signal）一个错误对象，形如 (符号 . 数据)。
;;; condition-case 的变量接到的就是它。
(princ "== 1) 错误对象的数据形状 ==\n")
(princ "错误对象 = (错误符号 . 附加数据)\n\n")

(dolist (thunk (list (cons "显式抛出" (lambda () (error "boom")))
                     (cons "类型不符" (lambda () (car 5)))
                     (cons "除零"     (lambda () (/ 1 0)))
                     (cons "主动 signal" (lambda () (signal 'wrong-number-of-arguments '(+ 1))))))
  (condition-case err
      (funcall (cdr thunk))
    (error (princ (format "%-10s 错误对象=%-38S 变成一句话=%S\n"
                          (car thunk) err (error-message-string err))))))

;;; ---------- 2) 自定义错误符号要用 define-error 登记 ----------
;;; 直接 (signal 'my-error ...) 会得到一个「Invalid error symbol」错误，
;;; 因为 Emacs 不认识这个符号。用 define-error 注册后它才是一个合法错误。
(princ "\n== 2) 自定义错误符号 ==\n")
(define-error 'my-config-error "配置文件有误")
(princ (format "登记后 error-conditions = %S（含 error，所以也能被通用处理器接住）\n"
               (get 'my-config-error 'error-conditions)))
(condition-case err
    (signal 'my-config-error '("缺少 field: name" 42))
  (my-config-error
   (princ (format "精确捕获： 错误对象=%S\n" err))))
(condition-case err
    (signal 'my-config-error '("缺少 field: name" 42))
  (error
   (princ (format "通用捕获： 一句话=%S\n" (error-message-string err)))))

;;; ---------- 3) condition-case：精确 / 通用 / 重新抛出 ----------
;;; 处理器从左到右匹配。列表里可以写多个错误符号；error 是所有错误的祖先。
(princ "\n== 3) condition-case 的三种用法 ==\n")

;; (a) 精确匹配 + 兜底
(princ (format "(a) 精确匹配: %S\n"
               (condition-case _err
                   (signal 'my-config-error '("坏值"))
                 (my-config-error 'handled-specific)
                 (error 'handled-generic))))

;; (b) 处理器里没匹配上的错误会继续往外抛
(princ (format "(b) 不匹配则外抛: %S\n"
               (condition-case outer
                   (condition-case nil
                       (car 5)                 ; 抛 wrong-type-argument
                     (arith-error 'never))     ; 接不住，继续抛
                 (error (list 'outer-caught (car outer))))))

;; (c) 重新抛出：包装一句上下文，再抛给上层
(princ (format "(c) 重新抛出: %S\n"
               (condition-case err
                   (condition-case e
                       (/ 1 0)
                     (arith-error
                      ;; 保留原错误符号和数据，只加一句上下文
                      (signal (car e) (cons "在计算平均值时" (cdr e)))))
                 (arith-error (error-message-string err)))))

;;; ---------- 4) unwind-protect：清理一定执行，且在处理器之前 ----------
(princ "\n== 4) unwind-protect 的执行顺序 ==\n")
(princ (format "顺序 = %S\n"
               (let (log)
                 (condition-case err
                     (unwind-protect
                         (progn
                           (push 'body log)     ; 1) 正体
                           (car "notalist"))    ; 正体里出错
                       (push 'cleanup log))     ; 2) 清理，无论出错与否都跑
                   (error (push (list 'handler (car err)) log))) ; 3) 处理器
                 (nreverse log))))
(princ "=> 先 body，再 cleanup，最后 handler。清理代码永远有机会收尾。\n")

;;; ---------- 5) 走一遍调用栈 ----------
;;; backtrace-frame 按帧号取栈帧，从 0（最内层）往外数。
(defun my-call-stack ()
  "收集当前调用栈里属于本示例的那几帧，从外到内返回。"
  (let ((n 0) acc done)
    (while (not done)
      (let ((frame (backtrace-frame n)))
        (if frame
            (progn
              (when (memq (cadr frame) '(my-level-1 my-level-2 my-call-stack))
                (push (cadr frame) acc))
              (setq n (1+ n)))
          (setq done t))))
    acc))

(defun my-level-2 () (my-call-stack))
(defun my-level-1 () (my-level-2))

(princ "\n== 5) 走一遍调用栈 ==\n")
(princ (format "调用栈（外 -> 内）= %S\n" (my-level-1)))

;;; ---------- 6) debug-on-entry：让某个函数一被调用就停下 ----------
;;; 本机实现：给函数挂一个 :before 建议（advice）。
;;; 真正进入调试器这件事在 --batch 下不好演示，所以我们把变量 debugger
;;; 换成一个「桩」，就能看清它在什么时候、带着什么参数被调用。
(princ "\n== 6) debug-on-entry 的机制 ==\n")
(defun my-add (a b) (+ a b))
(defvar my-debug-log nil)

(debug-on-entry 'my-add)
(princ (format "加了断点？ %S\n"
               (not (null (advice-member-p #'debug--implement-debug-on-entry 'my-add)))))
(princ (format "当前设了断点的函数： %S\n" (debug--function-list)))

(let ((debugger (lambda (&rest args) (push args my-debug-log) 'stubbed)))
  (princ (format "照常调用 my-add(3,4)，结果 = %S（函数体照跑）\n" (my-add 3 4))))
(princ (format "debugger 被调用时的实参： %S\n" (car my-debug-log)))

(cancel-debug-on-entry 'my-add)
(princ (format "取消后还有断点？ %S\n"
               (not (null (advice-member-p #'debug--implement-debug-on-entry 'my-add)))))

;;; ---------- 7) edebug：交互式单步 ----------
;;; edebug 是「单步调试器」，靠读你的按键来走：在源码里对函数按 C-u C-M-x
;;; （M-x edebug-defun RET）即可插桩，之后调用会出现一个 *edebug* 窗口，
;;; s 单步、n 下一个表达式、q 退出。它必须交互，--batch 里跑不了，
;;; 所以这里只打印它的两个开关，证明它已就绪。
(princ "\n== 7) edebug 的开关 ==\n")
(require 'edebug)
(princ (format "edebug 已加载： edebug-on-error=%S  edebug-on-quit=%S\n"
               edebug-on-error edebug-on-quit))
(princ "在源码里用 C-u C-M-x 插桩，再交互运行即可单步。\n")

(princ "==== 33 结束 ====\n")
