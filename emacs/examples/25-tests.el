;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 25 - 测试：ERT 单元测试
;;;   ert-deftest / should / should-error / 静默运行 / 测试 buffer 代码
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "25-tests.el")'
;;; 运行：emacs -Q --batch -l 25-tests.el
;;; 正常的 CI 跑法（输出走 stderr，会打印每条用例的结果）：
;;;   emacs -Q --batch -l 25-tests.el -f ert-run-tests-batch-and-exit
;;; ============================================================

(require 'ert)
(require 'cl-lib)

;;; ------------------------------------------------------------
;;; 被测代码：一个极简的「标题层级」解析器
;;; ------------------------------------------------------------

(defun demo-heading-level (line)
  "返回 LINE 的标题层级；不是标题则返回 nil。"
  (if (string-match "\\`\\(#+\\) " line)
      (length (match-string 1 line))
    nil))

(defun demo-count-words (text)
  "统计 TEXT 里的单词数（按空白切分，忽略空串）。"
  (length (split-string text "[ \t\n]+" t)))

;;; ------------------------------------------------------------
;;; 测试用例
;;; ------------------------------------------------------------

;;; 1) 最基本的用例。ert-deftest 的名字约定以包名开头，方便按前缀筛选用例。
(ert-deftest demo-test-heading-level ()
  (should (= 1 (demo-heading-level "# 一级")))
  (should (= 3 (demo-heading-level "### 三级")))
  (should (= 6 (demo-heading-level "###### 六级"))))

;;; 2) should 家族：
;;;      should         断言为真（失败时打印原表达式和各个子表达式的值）
;;;      should-not     断言为假
;;;      should-error   断言会报错（第二个参数可指定错误类型）
(ert-deftest demo-test-not-heading ()
  (should-not (demo-heading-level "普通的一行"))
  (should-not (demo-heading-level "#没有空格的一级"))
  (should (null (demo-heading-level ""))))

(ert-deftest demo-test-error-is-signalled ()
  ;; 类型不对就该报错
  (should-error (demo-heading-level 42))
  ;; 也可以指定期望的错误类型
  (should-error (demo-heading-level 42) :type 'wrong-type-argument))

;;; 3) 【重点】测试与 buffer 有关的代码时，用 with-temp-buffer 隔离。
;;;    每个用例都该是独立的：不依赖执行顺序，不留下脏 buffer。
(ert-deftest demo-test-in-buffer ()
  (with-temp-buffer
    (insert "hello emacs world")
    (should (= 15 (point-max)))
    (goto-char (point-min))
    (should (looking-at "hello"))
    ;; 测试插入之后 point 的位置
    (goto-char (point-max))
    (insert "!")
    (should (= 16 (point-max)))))

;;; 4) 用 cl-letf 临时改写函数，做「mock」。
;;;    这是测「依赖外部状态的代码」最省事的办法，见 09-sequences.el 第 10 节。
(ert-deftest demo-test-with-mock ()
  (cl-letf (((symbol-function 'current-time)
             (lambda () '(0 0 0 0))))
    (should (equal '(0 0 0 0) (current-time)))))

;;; 5) 用 let 临时改写变量（动态绑定）来构造测试场景
(defvar demo-threshold 10
  "演示用的阈值。")

(defun demo-is-big (n)
  "判断 N 是否大于 demo-threshold。"
  (> n demo-threshold))

(ert-deftest demo-test-threshold ()
  (should-not (demo-is-big 5))
  (should (demo-is-big 20))
  ;; 临时把阈值调低，验证逻辑真的读了变量
  (let ((demo-threshold 1))
    (should (demo-is-big 5))))

;;; 6) skip-unless：某些环境不满足时跳过，而不是失败。
(ert-deftest demo-test-skip-on-demand ()
  (skip-unless (executable-find "echo"))
  (should (string-match-p "ok"
                          (shell-command-to-string "echo ok"))))

;;; 7) ------------------------------------------------------------
;;; 运行测试。
;;;
;;; 【坑】ert-run-tests-batch 会把结果打到 **stderr**（它内部用 message）。
;;;    本仓库要求 stderr 为空，所以这里用底层的 ert-run-tests，
;;;    并传一个「什么都不做」的 listener，这样全程零输出，
;;;    结果从返回的 stats 对象里读。
;;;
;;; 真实项目里用命令行跑就好（输出会走 stderr，那才是给人看的）：
;;;     emacs -Q --batch -l ert -l my-tests.el -f ert-run-tests-batch-and-exit
;;; ------------------------------------------------------------

(defvar demo-silent-listener (lambda (&rest _args) nil)
  "一个什么都不做的 listener，用来静默运行测试。")

(let* ((stats (ert-run-tests 't demo-silent-listener))
       (expected (ert-stats-completed-expected stats))
       (unexpected (ert-stats-completed-unexpected stats))
       (total (ert-stats-total stats)))
  (princ (format "7) 跑完全部用例：共 %S 个，符合预期 %S 个，不符合 %S 个\n"
                 total expected unexpected))
  (princ (format "   （要看每条用例的详情，就用命令行跑 -f ert-run-tests-batch-and-exit）\n")))

;;; 8) 只跑一部分用例：ert-run-tests 的第一个参数是 selector。
;;;      t                    全部
;;;      'demo-test-heading   按名字
;;;      "heading"            按名字的正则
;;;      :new / :failed / :passed  按上次运行结果
;;;    在 Emacs 里用 M-x ert 时也可以输入 selector。
(let ((stats (ert-run-tests "heading" demo-silent-listener)))
  (princ (format "8) 只跑名字含 heading 的用例：%S 个\n"
                 (ert-stats-total stats))))

;;; 9) 失败时看什么：should 失败会记录
;;;      :form    —— 断言的原始表达式
;;;      :value   —— 实际求出的值
;;;      :explanation —— 对「为什么不等」的解释（比如列表第几个元素不同）
;;;    这比 (unless (equal a b) (error "not equal")) 有用得多，
;;;    因为不用自己拼诊断信息。
(ert-deftest demo-test-intentional-failure ()
  :expected-result :failed          ; 告诉 ERT「我就是故意让它失败的」
  (should (= 1 2)))

(let ((stats (ert-run-tests 'demo-test-intentional-failure demo-silent-listener)))
  (princ (format "9) 故意失败的用例被标记为 :failed，ERT 记录为「符合预期」: %S\n"
                 (= 0 (ert-stats-completed-unexpected stats)))))

;;; 10) 断言的粒度：一个用例里多个 should 是可以的，
;;;     但第一个失败就会中断后面的。想一次看到所有问题就拆成多个用例 ——
;;;     代价是重复的 setup 代码，可以用宏或 helper 函数抽出来。
(princ "10) 一个 ert-deftest 里第一个 should 失败就停，想全看就拆用例\n")

;;; 11) 测试文件放哪：
;;;      - 单文件包   -> 同目录下的 foo-tests.el
;;;      - 多文件包   -> test/ 目录
;;;     CI 里的一行（Emacs 官方包的做法）：
;;;      emacs -Q --batch -L . -l test/foo-tests.el -f ert-run-tests-batch-and-exit
(princ "11) 测试文件命名：foo-tests.el，放 test/ 目录下\n")

(princ "==== 25 结束 ====\n")
