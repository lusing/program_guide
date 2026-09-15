;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 20 - 外部进程：同步调用、异步子进程、filter 与 sentinel
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "20-processes.el")'
;;; 运行：emacs -Q --batch -l 20-processes.el
;;; ============================================================

;;; 0) 【跨平台提示】不要写死 cmd.exe / /bin/sh。
;;;    shell-file-name 和 shell-command-switch 会给出当前平台正确的组合，
;;;    本示例统一用它们，所以 Windows 和 Unix 上都能跑。
(princ (format "0) shell = %S, switch = %S\n"
               shell-file-name shell-command-switch))

;;; 1) 同步调用（会等到进程结束）：call-process。
;;;    第 3 个参数是「输出去哪」：t = 当前 buffer，nil = 丢弃，
;;;    也可以是 (REAL-DESTINATION STDERR-DESTINATION) 让两者分开。
;;;    返回值是进程的退出码。
(with-temp-buffer
  (let ((rc (call-process shell-file-name nil t nil
                          shell-command-switch "echo sync-hello")))
    (princ (format "1) call-process 退出码 = %S，输出 = %S\n"
                   rc (string-trim (buffer-string))))))

;;; 2) 只想要输出字符串：shell-command-to-string。
;;;    【坑】它**不返回退出码**，命令失败时你拿到的是空串 + stderr 混在里面。
;;;    要判断成败就用 call-process。
(princ (format "2) shell-command-to-string: %S\n"
               (string-trim (shell-command-to-string "echo from-shell"))))

;;; 3) 把输出直接写进文件：call-process 的 destination 可以是文件名或 (file . name)。
(defvar demo-proc-dir (make-temp-file "emacs-proc-" t))
(defvar demo-proc-out (expand-file-name "out.txt" demo-proc-dir))
(call-process shell-file-name nil (list :file demo-proc-out) nil
              shell-command-switch "echo written-to-file")
(princ (format "3) 文件里的结果: %S\n"
               (string-trim
                (with-temp-buffer (insert-file-contents demo-proc-out) (buffer-string)))))

;;; 4) 【坑】命令和参数必须分开传，不要拼成一个字符串再交给 shell ——
;;;    既慢（多起一个 shell），又会引入注入问题，还会踩各家 shell 的引号差异。
;;;    正确： (call-process "git" nil t nil "log" "--oneline")
;;;    错误： (call-process shell-file-name nil t nil "-c" "git log --oneline")

;;; 5) 找可执行文件：executable-find。写扩展时启动外部程序之前一定要先查一次，
;;;    找不到就给用户一个明确的错误，而不是让它抛个莫名其妙的异常。
(princ (format "5) executable-find \"echo\" = %S\n" (executable-find "echo")))
(princ (format "   找一个不存在的: %S\n" (executable-find "definitely-not-here-xyz")))

;;; 6) 异步进程：make-process。它立刻返回，不阻塞 Emacs。
;;;    :sentinel 在进程状态变化（结束、被杀）时被调用；
;;;    :filter  在有输出时被调用（拿到的是**原始字节串**，可能一次给一段）。
;;;    注意 batch 模式下没有事件循环，要手动 accept-process-output 推动。
(let* ((chunks nil)
       (done nil)
       (proc (make-process
              :name "demo-async"
              :command (list shell-file-name shell-command-switch "echo async-hello")
              :buffer nil                     ; nil = 不用 buffer 收集输出
              :connection-type 'pipe
              :filter (lambda (_proc text)
                        (push text chunks))
              :sentinel (lambda (_proc _event)
                          (setq done t)))))
  ;; 等到进程结束（或超时）
  (let ((waited 0))
    (while (and (not done) (< waited 50))
      (accept-process-output proc 0.05)
      (setq waited (1+ waited))))
  (princ (format "6) 异步收到: %S，进程还活着吗: %S\n"
                 (string-trim (apply #'concat (nreverse chunks)))
                 (process-live-p proc))))

;;; 7) 【坑】sentinel 收到的 event 字符串末尾**带换行**，
;;;    而且它可能在进程「停止 / 继续 / 结束」时被多次调用。
;;;    判断真正结束要用 (process-live-p proc) 或匹配 "finished"，
;;;    不要简单地「sentinel 被调用 == 结束了」。
(let* ((events nil)
       (proc (make-process
              :name "demo-evt"
              :command (list shell-file-name shell-command-switch "echo x")
              :buffer nil
              :filter #'ignore
              :sentinel (lambda (_proc event) (push event events)))))
  (while (process-live-p proc)
    (accept-process-output proc 0.05))
  (princ (format "7) sentinel 收到的 event: %S\n" (nreverse events)))
  (princ (format "   退出码 = %S\n" (process-exit-status proc))))

;;; 8) 老 API：start-process（把输出收进一个 buffer）+ set-process-sentinel。
;;;    新代码推荐 make-process，但读老包时会遇到这套。
(let* ((buf (generate-new-buffer " *demo-proc*"))
       (proc (start-process "demo-old" buf shell-file-name
                            shell-command-switch "echo old-api")))
  (while (process-live-p proc)
    (accept-process-output proc 0.05))
  (princ (format "8) start-process 输出: %S\n"
                 (string-trim (with-current-buffer buf (buffer-string)))))
  (kill-buffer buf))

;;; 9) 给进程发输入：process-send-string。用完要 process-send-eof 关掉 stdin，
;;;    否则对端会一直等输入。
(let* ((out nil)
       (proc (make-process
              :name "demo-cat"
              :command (list "cat")
              :buffer nil
              :filter (lambda (_p s) (push s out))
              :sentinel #'ignore)))
  (process-send-string proc "通过 stdin 喂进去的一行\n")
  (process-send-eof proc)
  (while (process-live-p proc)
    (accept-process-output proc 0.05))
  (princ (format "9) cat 回显: %S\n" (string-trim (apply #'concat (nreverse out))))))

;;; 10) 超时与杀进程。外部工具挂住是很常见的，一定要有兜底：
;;;     (delete-process proc)      发信号让它退出
;;;     (kill-process proc)        更强硬一点
;;;     (process-live-p proc)      判活
(let ((proc (make-process :name "demo-sleep"
                          :command (list "sleep" "30")
                          :buffer nil :filter #'ignore :sentinel #'ignore)))
  (accept-process-output proc 0.05)
  (princ (format "10) 启动 sleep 30: 活着 = %S\n" (process-live-p proc)))
  (delete-process proc)
  (accept-process-output proc 0.05)
  (princ (format "    delete-process 之后: 活着 = %S\n" (process-live-p proc))))

;;; 11) 清理
(delete-directory demo-proc-dir t)
(princ (format "11) 临时目录已清理: %S\n" (not (file-exists-p demo-proc-dir))))

(princ "==== 20 结束 ====\n")
