;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 18 - Custom 系统：把配置做成「用户能看见、能改、能持久化」的选项
;;;   defgroup / defcustom / :type / :set / customize-set-variable
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "18-custom.el")'
;;; 运行：emacs -Q --batch -l 18-custom.el
;;; ============================================================

;;; 1) defgroup 建一个配置分组，M-x customize 的目录树就靠它组织。
;;;    :group 指定父分组，顶层的挂在 'emacs 下。
(defgroup demo-timer nil
  "演示扩展的配置。"
  :group 'emacs
  :prefix "demo-timer-")     ; :prefix 只是约定声明，方便 checkdoc 检查命名

;;; 2) defcustom 定义用户选项。它比 defvar 多了三样东西：
;;;      - :type    告诉 customize 界面怎么渲染（下拉框？文件选择器？）
;;;      - :group   归到哪个分组
;;;      - 能被 M-x customize 修改，并由 Emacs 自动写进 custom-file
(defcustom demo-timer-interval 25
  "专注计时的默认时长，单位是分钟。"
  :type 'integer
  :group 'demo-timer)

;;; 3) :type 决定了 customize 界面长什么样。常用类型：
;;;      integer / number / string / boolean / symbol
;;;      (choice ...)            下拉选择
;;;      (repeat ...)            列表，可增删元素
;;;      (const SYM)             固定值，配合 choice 用
;;;      file / directory        带补全的路径
;;;      face / color            face 或颜色
;;;      sexp                    任意 Lisp 表达式（兜底用）
(defcustom demo-timer-sound
  '(choice (const :tag "不响" nil) file)
  "当前写的是类型定义的**数据本身**，见第 4 节的正确写法。"
  :type 'sexp
  :group 'demo-timer)

(defcustom demo-timer-mode-line
  '(choice (const :tag "关闭" nil)
           (const :tag "剩余时间" remaining)
           (const :tag "百分比" percent))
  "mode-line 上显示什么。"
  :type '(choice (const :tag "关闭" nil)
                 (const :tag "剩余时间" remaining)
                 (const :tag "百分比" percent))
  :group 'demo-timer)

(defcustom demo-timer-history-max 10
  "最多保留多少条历史记录。"
  :type '(integer :value 10)
  :group 'demo-timer)

;;; 4) 【坑】上面的 demo-timer-sound 是**故意写错的示范**：
;;;    :type 是 sexp，默认值却写成了一个 choice 形式的数据结构。
;;;    正确写法是「默认值是数据，:type 是它的类型描述」，像这样：
(defcustom demo-timer-file nil
  "提示音文件，nil 表示不响。"
  :type '(choice (const :tag "不响" nil)
                 (file :must-match t :tag "音频文件"))
  :group 'demo-timer)

;;; 5) 【坑】defcustom 和 defvar 一样，**不会覆盖已有值**。
;;;    重新 load 文件时，用户已经改过的值会保留。这是特性不是 bug。
(setq demo-timer-interval 50)
(princ (format "5) 手动 setq 成 50 之后: %S\n" demo-timer-interval))

;;; 6) 【重点】setq 不会触发 :set 函数，customize-set-variable 才会。
;;;    如果你的选项在改动后需要「做点什么」（重启进程、刷新 UI），
;;;    就一定要写 :set，并告诉用户用 customize 或直接调 customize-set-variable。
(defvar demo-timer-applied 0 "记录 :set 被调用了多少次。")

(defcustom demo-timer-label "Focus"
  "计时器的显示名。"
  :type 'string
  :set (lambda (sym value)
         (set-default sym value)
         (setq demo-timer-applied (1+ demo-timer-applied))
         (princ (format "    [:set 触发] %s 变成 %S\n" sym value)))
  :initialize #'custom-initialize-default
  :group 'demo-timer)

(princ "6) 对比两种改法：\n")
(princ (format "   改之前 applied = %S\n" demo-timer-applied))
(setq demo-timer-label "直接 setq")
(princ (format "   setq 之后 applied = %S（没有触发 :set）\n" demo-timer-applied))
(customize-set-variable 'demo-timer-label "走 customize")
(princ (format "   customize-set-variable 之后 applied = %S\n" demo-timer-applied))

;;; 7) custom-set-variables 是 Emacs 写进 custom-file 的形式，
;;;    它内部走的也是 customize-set-variable，所以会触发 :set。
(princ "7) custom-set-variables：\n")
(custom-set-variables '(demo-timer-label "批量设置"))
(princ (format "   applied = %S，当前值 = %S\n"
               demo-timer-applied demo-timer-label))

;;; 8) custom-declare-variable / custom-variable-p：判断某个符号是不是用户选项。
;;;    【坑】custom-variable-p 返回的不是 t，而是「类型表达式」，
;;;    当成布尔用之前记得转一下。
(princ (format "8) demo-timer-interval 是用户选项吗: %S\n"
               (and (custom-variable-p 'demo-timer-interval) t)))
(princ (format "   普通 defvar 的: %S\n"
               (and (custom-variable-p 'demo-timer-applied) t)))

;;; 9) 读取「类型定义」和「默认值」。
;;;    类型存在符号的 custom-type 属性里；默认值存在 standard-value 属性里
;;;    （注意它是个「待求值的表达式」的列表，要 car 再 eval）。
(princ (format "9) demo-timer-interval 的 :type = %S\n"
               (get 'demo-timer-interval 'custom-type)))
(princ (format "   它的标准值（未改过的默认值）= %S\n"
               (eval (car (get 'demo-timer-interval 'standard-value)))))

;;; 10) defface 定义可定制的 face，用法和 defcustom 类似，
;;;     但它的默认值只在 **Emacs 26 之前** 是「值」，现在要写成规范形式。
(defface demo-timer-face
  '((t :inherit warning :weight bold))
  "计时器显示用的 face。"
  :group 'demo-timer)
(princ (format "10) face 定义好了: %S\n" (and (facep 'demo-timer-face) t)))

;;; 11) 打包建议：一个正式扩展里，把所有 defcustom 集中放在文件靠前的位置，
;;;     共用一个 defgroup，:prefix 保持一致。用户按 M-x customize-group
;;;     就能一次看到全部选项 —— 这比散落在 README 里的 setq 友好得多。
(princ (format "11) 本示例共有 %S 个自定义选项\n"
               (length (seq-filter (lambda (s) (custom-variable-p s))
                                   '(demo-timer-interval demo-timer-sound
                                     demo-timer-mode-line demo-timer-history-max
                                     demo-timer-file demo-timer-label)))))

(princ "==== 18 结束 ====\n")
