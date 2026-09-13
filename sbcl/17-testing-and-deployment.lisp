;;;; ============================================================
;;;; 17-testing-and-deployment.lisp — 测试与发布基础
;;;; ============================================================

(format t "~%=== 测试与发布基础 ===~%")

;; 使用 assert 做轻量测试
(defun safe-average (numbers)
  (assert (and (listp numbers) numbers) () "numbers 必须是非空列表")
  (/ (reduce #'+ numbers) (length numbers)))

(format t "average: ~A~%" (safe-average '(2 4 6 8)))

;; 失败捕获示例
(handler-case
    (progn
      (safe-average '())
      (format t "不会执行到这里~%"))
  (error (e)
    (format t "捕获到预期错误: ~A~%" e)))

;; 入口函数模式（用于 save-lisp-and-die）
(defun app-main ()
  (format t "App started.~%")
  (format t "Args: ~S~%" sb-ext:*posix-argv*)
  (sb-ext:quit :unix-status 0))

(format t "~%提示：可在 REPL 中执行如下表达式构建可执行映像：~%")
(format t "(sb-ext:save-lisp-and-die \"myapp.exe\" :toplevel #'app-main :executable t)~%")

(format t "~%=== 例程 17 执行完毕 ===~%")
