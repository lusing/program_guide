;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 24 - 模块与包：provide / require / load-path / autoload
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "24-packages.el")'
;;; 运行：emacs -Q --batch -l 24-packages.el
;;; ============================================================

;;; 本示例会在临时目录里真的造两个模块文件，再 require 它们，
;;; 所以「require 依赖的文件要等运行时才存在」——
;;; 这就带来两条真实项目里天天遇到的约束，见第 3 节和第 4 节。
;;;
;;; 【约束一】顶层 (require 'xxx) 会被字节编译器在**编译期**就尝试加载，
;;;           文件不存在会直接编译失败。所以本示例把 require 放进函数里。
;;; 【约束二】放进函数之后，字节编译器看不懂 demo-add 是什么，
;;;           会报 "not known to be defined"。正解就是 declare-function：
;;;           它只声明「这个函数存在于哪个文件」，不做任何加载动作。
(require 'package)
(require 'cl-lib)

(declare-function demo-add "demo-math")
(declare-function demo-hi  "demo-greet")

;;; 1) Elisp 的「模块」单位是 feature（特性），用符号表示。
;;;    文件末尾写 (provide 'xxx) 声明「我提供了 xxx」；
;;;    别的文件写 (require 'xxx) 表示「我需要 xxx，没有就报错」。
;;;    features 全局变量里装着当前已加载的全部 feature。
(princ (format "1) 'seq 已加载吗: %S，'cl-lib 呢: %S\n"
               (featurep 'seq) (featurep 'cl-lib)))

;;; 2) 造两个模块文件。
(defvar demo-lib-dir (make-temp-file "emacs-lib-" t))

(defvar demo-math-source
  ";;; demo-math.el --- 演示用数学模块 -*- lexical-binding: t; -*-

;;; Commentary:
;;; 一个最小的模块示例：几个函数 + 末尾的 provide。

;;; Code:

(defun demo-add (a b)
  \"返回 A + B。\"
  (+ a b))

(defun demo-mul (a b)
  \"返回 A * B。\"
  (* a b))

(provide 'demo-math)

;;; demo-math.el ends here
")

(defvar demo-greet-source
  ";;; demo-greet.el --- 演示用问候模块 -*- lexical-binding: t; -*-

;;; Code:

;;; require 要写在「用到该模块之前」。
;;; 但它有代价（要查 load-path、要 load 文件），
;;; 只在「本文件一加载就必须有」的时候才写在顶层。
(require 'demo-math)

(defun demo-hi (n)
  \"返回一句问候，数字用 demo-math 算出来。\"
  (format \"hi, %d\" (demo-add n 1)))

(provide 'demo-greet)

;;; demo-greet.el ends here
")

(with-temp-file (expand-file-name "demo-math.el" demo-lib-dir)
  (insert demo-math-source))
(with-temp-file (expand-file-name "demo-greet.el" demo-lib-dir)
  (insert demo-greet-source))
(princ (format "2) 已造好两个模块: %S\n"
               (mapcar #'file-name-nondirectory
                       (directory-files demo-lib-dir t "\\.el\\'"))))

;;; 3) load-path：require 去哪找文件。
;;;    它就是个目录列表，require 'demo-math 会依次在这些目录里找
;;;    demo-math.el（或 .elc），找到第一个就停。
;;;    【坑】往里加目录用 add-to-list（去重），别用 push（会重复添加）。
(add-to-list 'load-path demo-lib-dir)
;;;    注意这里打印的是「是不是排在最前面」而不是目录名 ——
;;;    临时目录名每次运行都不同，写进教程会变成不可复现的输出。
(princ (format "3) 刚加的目录排在最前面: %S\n" (eq (car load-path) demo-lib-dir)))

;;; 3b) 【重要】顶层表单在字节编译时会被求值 —— 所以**顶层 (require 'xxx) 会在
;;;     编译期就真的去加载**。文件不存在时编译直接失败（是 Error，不是 Warning）。
;;;     下面真编译一次，并把编译器写往 stderr 的消息截下来。
(defvar demo-bad-src (expand-file-name "demo-bad.el" demo-lib-dir))
(with-temp-file demo-bad-src
  (insert ";;; -*- lexical-binding: t; -*-\n"
          "(require 'demo-not-yet)\n"
          "(defun demo-bad-use () (demo-not-yet-add 1 2))\n"
          "(provide 'demo-bad)\n"))
(let ((msgs nil))
  (cl-letf (((symbol-function 'message)
             (lambda (fmt &rest args) (push (apply #'format fmt args) msgs))))
    (byte-compile-file demo-bad-src))
  (princ (format "3b) 编译顶层 require 一个不存在模块的文件:\n%s\n"
                 (replace-regexp-in-string
                  (regexp-quote demo-bad-src) "<临时目录>/demo-bad.el"
                  (string-trim (mapconcat #'identity (nreverse msgs) "\n"))
                  t t))))

;;; 4) 下面这段整体包在一个函数里 —— 这是本示例最重要的一条经验：
;;;    **顶层 (require 'xxx) 会被字节编译器在编译期就尝试加载。**
;;;    本示例的模块文件是运行时才生成的，编译期根本不存在，
;;;    所以顶层 require 会直接让编译失败：
;;;        Error: Cannot open load file: No such file or directory, demo-math
;;;    放进函数体里就不会在编译期求值了。
(defun demo-module-demo ()
  "演示 require / load-file / 找不到模块时的处理。"

  ;; 4) require 并调用。成功后 feature 会进 features 列表。
  ;;    【坑】require 找不到文件会**直接报错**（不是返回 nil）。
  ;;    想「有就用、没有就降级」就写 (require 'xxx nil t)，最后的 t = 不报错。
  (require 'demo-math)
  (princ (format "4) require 之后: featurep = %S, demo-add(3,4) = %S\n"
                 (featurep 'demo-math) (demo-add 3 4)))

  ;; 5) require 会自动处理传递依赖：require 'demo-greet 时，
  ;;    它内部那句 (require 'demo-math) 也会被执行（这里已加载过，直接跳过）。
  (require 'demo-greet)
  (princ (format "5) 依赖被自动处理，demo-hi(10) = %S\n" (demo-hi 10)))

  ;; 6) 找不到时的两种表现
  (princ (format "6) require 不存在的（noerror=t）: %S\n"
                 (require 'demo-nope-nope nil t)))
  (princ (format "   不加 noerror 就会报错: %S\n"
                 (condition-case nil
                     (require 'demo-nope-nope)
                   (error '确实报错了))))

  ;; 7) 只加载、不声明 feature：load / load-file。
  ;;    load       按 load-path 找（给符号名或文件名）
  ;;    load-file  按绝对路径加载
  ;;    两者都不管 provide，重复调用会重复执行 —— 调试时好用，生产代码别这么干。
  ;;    【坑】load 默认会往 stderr 打一行 "Loading xxx.el (source)..."。
  ;;    关掉它要用 load 的第三个参数 NOMESSAGE（load-file 没有这个参数，
  ;;    它等价于 (load FILE nil nil t)，一定会打消息）。
  (load (expand-file-name "demo-math.el" demo-lib-dir) nil t)
  (princ (format "7) 再 load 一次之后 featurep = %S（重复加载不影响 feature）\n"
                 (featurep 'demo-math)))
  (princ (format "   load-verbose 在 Emacs %d 里还存在吗: %S（已经没有了，别再 let 绑它）\n"
                 emacs-major-version (boundp 'load-verbose))))

(demo-module-demo)

;;; 8) autoload：让「用的时候才加载」，是 Emacs 启动快的关键。
;;;    写法是在函数定义**前**加一行注释（三个分号 + 井号 + autoload）：
;;;
;;;      ;;;###autoload
;;;      (defun my-fn () ...)
;;;
;;;    然后由包管理器扫描这些注释，生成 xxx-autoloads.el，
;;;    里面全是 (autoload 'my-fn "xxx" nil t) 这样的声明。
;;;    Emacs 启动时只 load 这个很小的 autoloads 文件，真正的代码等调用时才 load。
;;;    【坑】cookie 的写法必须是 ;;;###autoload，多一个空格都扫不到。
(princ "8) autoload cookie 写法见上面注释\n")

;;; 8b) cookie 到底生成了什么？真跑一次 loaddefs-generate 给你看。
;;;     它会扫源文件中的 ;;;###autoload，把「函数 → 文件」的声明写进 autoloads 文件。
(defvar demo-al-dir (make-temp-file "emacs-al-" t))
(defvar demo-pkg-source
  ";;; -*- lexical-binding: t; -*-

;;;###autoload
(defun demo-heavy-command ()
  \"一个很重的命令：只有用户调用了才需要它的代码。\"
  (interactive)
  (message \"重活干完了\"))

(provide 'demo-pkg)

;;; demo-pkg.el ends here
")
(with-temp-file (expand-file-name "demo-pkg.el" demo-al-dir)
  (insert demo-pkg-source))
(require 'loaddefs-gen)
;;;    loaddefs-generate 会往 stderr 打一行 "GEN xxx-autoloads.el"，
;;;    为了不污染本示例的 stderr，这里临时把 message 换成 no-op。
(cl-letf (((symbol-function 'message) #'ignore))
  (loaddefs-generate demo-al-dir (expand-file-name "demo-pkg-autoloads.el" demo-al-dir)))
(princ (format "8b) loaddefs-generate 扫出来的声明: %S\n"
               (with-temp-buffer
                 (insert-file-contents
                  (expand-file-name "demo-pkg-autoloads.el" demo-al-dir))
                 (let (found)
                   (while (re-search-forward "^(autoload " nil t)
                     (goto-char (match-beginning 0))
                     (push (read (current-buffer)) found))
                   (nreverse found)))))
(delete-directory demo-al-dir t)

;;; 9) with-eval-after-load：等某个 feature 加载完再做某件事。
;;;    这是「不改别人源码、但要在它加载后做配置」的标准手段。
(princ "9) with-eval-after-load：\n")
(with-eval-after-load 'demo-math
  (princ "    demo-math 加载完成后执行这句\n"))

;;; 10) 包管理：package.el 与 use-package
(princ (format "10) package-user-dir = %S\n" (abbreviate-file-name package-user-dir)))
(princ (format "    package-archives 有 %S 个源: %S\n"
               (length package-archives)
               (mapcar #'car package-archives)))
;;;     use-package 是一个宏，把 require / 按键绑定 / 配置 / 延迟加载整合在一处：
;;;       (use-package magit
;;;         :ensure t              ; 没装就装
;;;         :bind ("C-x g" . magit-status)
;;;         :custom (magit-diff-refine-hunk 'all)
;;;         :hook (git-commit-setup . my-setup))
;;;     注意 :ensure 需要联网；发布到 MELPA 的包才需要它。

;;; 11) 一个 .el 文件的标准头部（checkdoc / package-lint 都检查这些）：
;;;      ;;; foo.el --- 一句话简介 -*- lexical-binding: t; -*-   <- 第一行，必须有
;;;      ;; Version: 1.0
;;;      ;; Package-Requires: ((emacs "29.1"))
;;;      ;; Keywords: convenience
;;;      ;; URL: https://...
;;;      ;;; Commentary:      <- 说明段
;;;      ;; 这里写用法说明
;;;      ;;; Code:            <- 代码从这里开始
;;;      (provide 'foo)
;;;      ;;; foo.el ends here <- 结束标记，必须有
(princ "11) 文件头规范见上面注释，M-x checkdoc 会逐条检查\n")

;;; 11b) 把上面那套规范写成一个真文件，加载一次确认它确实可用。
(defvar demo-package-source
  ";;; demo-package.el --- 一句话说明这个包做什么  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <you@example.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs \"27.1\"))
;; Keywords: tools convenience
;; URL: https://example.com/demo-package

;; This file is not part of GNU Emacs.

;;; Commentary:

;; 这里是较长的说明：这个包做什么、怎么用、有什么已知限制。

;;; Code:

(defun demo-package-hello ()
  \"打个招呼。\"
  (interactive)
  (message \"hi\"))

(provide 'demo-package)

;;; demo-package.el ends here
")
(with-temp-file (expand-file-name "demo-package.el" demo-lib-dir)
  (insert demo-package-source))
(princ (format "11b) 按标准头部写的文件能正常加载并 provide: %S\n"
               (progn (load (expand-file-name "demo-package.el" demo-lib-dir) nil t)
                      (featurep 'demo-package))))

;;; 12) 清理：把 feature 摘掉、把 load-path 还原、删掉临时目录。
;;;     真实项目里不需要这一步，这里只是不想污染本进程的状态。
(setq features (delq 'demo-math (delq 'demo-greet features)))
(setq load-path (delete demo-lib-dir load-path))
(delete-directory demo-lib-dir t)
(princ (format "12) 清理完成，临时目录还在吗: %S，demo-math 还是 feature 吗: %S\n"
               (file-exists-p demo-lib-dir) (featurep 'demo-math)))

(princ "==== 24 结束 ====\n")
