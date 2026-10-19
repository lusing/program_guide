# 25 · 测试

> 所属部分：第 5 部分 · 工程化

> 示例：`examples/25-tests.el`

`ert`（Emacs Regression Testing）是 Emacs **内置**的测试框架，不用装任何东西。本章用一组真实的用例讲清：怎么写断言、怎么隔离 buffer、怎么 mock、怎么在 CI 里跑。

示例自己带了一点被测代码——一个极简的「标题层级」解析器和一个单词计数器：

```elisp
(defun demo-heading-level (line)
  "返回 LINE 的标题层级；不是标题则返回 nil。"
  (if (string-match "\\`\\(#+\\) " line)
      (length (match-string 1 line))
    nil))

(defun demo-count-words (text)
  "统计 TEXT 里的单词数（按空白切分，忽略空串）。"
  (length (split-string text "[ \t\n]+" t)))
```

## 25.1 跑测试要自己接统计

在讲断言之前，先解决一个工程问题：**ERT 的默认输出是给人看的，不是给程序读的**。

`ert-run-tests-batch-and-exit` 把结果写到 **stderr**：

```bash
$ emacs -Q --batch -l t25.el 2>/dev/null
      # ← stdout 是空的

$ emacs -Q --batch -l t25.el -f ert-run-tests-batch-and-exit 2>&1 1>/dev/null
Running 1 tests (2026-10-19 22:18:06+0800, selector ‘t’)
   passed  1/1  t-ok (0.000112 sec)

Ran 1 tests, 1 results as expected, 0 unexpected (2026-10-19 22:18:06+0800, 0.000269 sec)
```

（时间戳和耗时每次都不同；上面是实测的一次。）

在「stderr 必须为空」的判定下这会失败，而且那些文字也没法直接拿去统计。所以示例用了底层 API：**传一个什么都不做的 listener**，让 ERT 全程零输出，结果从返回的 stats 对象里读。

```elisp
;; 本示例要自己统计测试结果（原因见第 7 节），所以先准备两样东西：
;; 一个「什么都不做」的 listener（让 ERT 全程零输出），
;; 和一个「跑一批用例并返回统计」的小工具。
(defvar demo-silent-listener (lambda (&rest _args) nil)
  "一个什么都不做的 listener，用来静默运行测试。")

(defun demo-run-tests (selector)
  "静默运行 SELECTOR 选中的用例，返回 (通过数 . 总数)。"
  (let ((stats (ert-run-tests selector demo-silent-listener)))
    (cons (ert-stats-completed-expected stats) (ert-stats-total stats))))
```

这是通用的经验：**要把测试结果接进自己的流水线，就用 `ert-run-tests` + 自己的 listener + `ert-stats-*`。**

## 25.2 ERT 基础与 should 家族

```elisp
;; 最基本的用例。ert-deftest 的名字约定以包名开头，方便按前缀筛选用例。
(ert-deftest demo-test-heading-level ()
  (should (= 1 (demo-heading-level "# 一级")))
  (should (= 3 (demo-heading-level "### 三级")))
  (should (= 6 (demo-heading-level "###### 六级"))))

;; should 家族：
;;      should         断言为真（失败时打印原表达式和各个子表达式的值）
;;      should-not     断言为假
;;      should-error   断言会报错（第二个参数可指定错误类型）
(ert-deftest demo-test-not-heading ()
  (should-not (demo-heading-level "普通的一行"))
  (should-not (demo-heading-level "#没有空格的一级"))
  (should (null (demo-heading-level ""))))

(ert-deftest demo-test-error-is-signalled ()
  ;; 类型不对就该报错
  (should-error (demo-heading-level 42))
  ;; 也可以指定期望的错误类型
  (should-error (demo-heading-level 42) :type 'wrong-type-argument))
```

三条要点：

- `ert-deftest` 定义一个用例，名字是**符号**；约定以包名开头（`demo-test-...`），这样才能按前缀批量筛选；
- `should` / `should-not` / `should-error` 覆盖了绝大多数需求；`should-error` 可以带 `:type` 精确要求错误类型；
- **`should` 比 `(unless ... (error ...))` 强得多**：失败时它会记录 `:form`（原始表达式）、`:value`（实际值）、`:explanation`（为什么不等），不用你自己拼诊断信息。

边界值单独一个用例，是很好的习惯：

```elisp
;; demo-count-words 的用例：注意「多个连续空白」和「全空白」这两种边界。
(ert-deftest demo-test-count-words ()
  (should (= 3 (demo-count-words "hello emacs world")))
  (should (= 3 (demo-count-words "hello   emacs\tworld")))
  (should (= 0 (demo-count-words "   "))))
```

## 25.3 【重点】测试 buffer 相关代码要隔离

```elisp
;; 【重点】测试与 buffer 有关的代码时，用 with-temp-buffer 隔离。
;; 每个用例都该是独立的：不依赖执行顺序，不留下脏 buffer。
(ert-deftest demo-test-in-buffer ()
  (with-temp-buffer
    (insert "hello emacs world")            ; 17 个字符
    (should (= 18 (point-max)))             ; point-max 是「末尾 + 1」
    (goto-char (point-min))
    (should (looking-at "hello"))
    ;; 测试插入之后 buffer 变长了
    (goto-char (point-max))
    (insert "!")
    (should (= 19 (point-max)))))
;; 【坑】point-max 不是「字符数」而是「末尾之后的那个位置」，所以比长度大 1。
;; 写死数字时很容易差一个 —— 更稳的写法是先用 (length "hello emacs world") 反推。
(princ (format "3) buffer 相关用例: 通过 %S / 共 %S\n"
               (car (demo-run-tests 'demo-test-in-buffer))
               (cdr (demo-run-tests 'demo-test-in-buffer))))
```

```text
3) buffer 相关用例: 通过 1 / 共 1
```

**每个用例都必须是独立的**：不依赖执行顺序，不留下脏 buffer。不用 `with-temp-buffer` 就会破坏用户正在编辑的东西；在 CI 里则是破坏别的测试的状态——造成「单独跑能过、一起跑就挂」的诡异现象。

> 【坑】`(point-max)` 是「末尾**之后**的位置」，比字符数大 1。写断言时手数字符数最容易差一个——上面那句注释里给了更稳的写法：用 `(length ...)` 反推，而不是硬编码。

## 25.4 mock：cl-letf

```elisp
;; 用 cl-letf 临时改写函数，做「mock」。
;; 这是测「依赖外部状态的代码」最省事的办法，见 09-sequences.el 第 10 节。
(ert-deftest demo-test-with-mock ()
  (cl-letf (((symbol-function 'current-time)
             (lambda () '(0 0 0 0))))
    (should (equal '(0 0 0 0) (current-time)))))
(princ (format "4) mock 用例: 通过 %S / 共 %S\n"
               (car (demo-run-tests 'demo-test-with-mock))
               (cdr (demo-run-tests 'demo-test-with-mock))))
```

```text
4) mock 用例: 通过 1 / 共 1
```

`cl-letf` 临时换掉函数实现，**出了 `let` 自动恢复** —— 所以不会污染其他测试。测试网络、时间、外部进程这类「不可控依赖」时必须 mock。

## 25.5 构造测试场景：let 动态绑定

```elisp
;; 用 let 临时改写变量（动态绑定）来构造测试场景
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
(princ (format "5) 动态绑定构造场景: 通过 %S / 共 %S\n"
               (car (demo-run-tests 'demo-test-threshold))
               (cdr (demo-run-tests 'demo-test-threshold))))
```

```text
5) 动态绑定构造场景: 通过 1 / 共 1
```

利用第 3.4 节的规则：对 `defvar` 过的变量，`let` 是临时改全局值、退出自动恢复。这是构造「不同配置下」测试的标准手段。最后那句 `(let ((demo-threshold 1)) (should (demo-is-big 5)))` 是点睛之笔——它证明 `demo-is-big` 真的读了那个变量，而不是碰巧算对的。

## 25.6 skip-unless

```elisp
;; skip-unless：某些环境不满足时跳过，而不是失败。
(ert-deftest demo-test-skip-on-demand ()
  (skip-unless (executable-find "echo"))
  (should (string-match-p "ok"
                          (shell-command-to-string "echo ok"))))
(princ (format "6) skip-unless 用例: 通过 %S / 共 %S（echo 不存在时会被跳过，不算失败）\n"
               (car (demo-run-tests 'demo-test-skip-on-demand))
               (cdr (demo-run-tests 'demo-test-skip-on-demand))))
```

```text
6) skip-unless 用例: 通过 1 / 共 1（echo 不存在时会被跳过，不算失败）
```

环境不满足（没有网络、不是某个平台、缺某个外部工具）时**跳过**而不是失败 —— 这样在别人的机器和 CI 上不会出现假的红色。

## 25.7 运行测试

```elisp
;; 【坑】ert-run-tests-batch 会把结果打到 **stderr**（它内部用 message）。
;; 本仓库要求 stderr 为空，所以这里用底层的 ert-run-tests，
;; 并传一个「什么都不做」的 listener，这样全程零输出，
;; 结果从返回的 stats 对象里读。
;;
;; 真实项目里用命令行跑就好（输出会走 stderr，那才是给人看的）：
;;     emacs -Q --batch -l ert -l my-tests.el -f ert-run-tests-batch-and-exit
(let* ((stats (ert-run-tests 't demo-silent-listener))
       (expected (ert-stats-completed-expected stats))
       (unexpected (ert-stats-completed-unexpected stats))
       (total (ert-stats-total stats)))
  (princ (format "7) 跑完全部用例：共 %S 个，符合预期 %S 个，不符合 %S 个\n"
                 total expected unexpected))
  (princ (format "   （要看每条用例的详情，就用命令行跑 -f ert-run-tests-batch-and-exit）\n")))
```

```text
7) 跑完全部用例：共 8 个，符合预期 8 个，不符合 0 个
   （要看每条用例的详情，就用命令行跑 -f ert-run-tests-batch-and-exit）
```

| 入口 | 用途 |
|---|---|
| `M-x ert` | 交互式，能看到每条用例和失败详情，可重跑 |
| `M-x ert-run-tests-batch-and-exit` / `-f` 命令行 | CI，退出码反映成败（**输出走 stderr**） |
| `(ert-run-tests SELECTOR LISTENER)` | 程序化调用，自己控制输出 |

`ert-stats-*` 里常用的三个：`ert-stats-total`（总数）、`ert-stats-completed-expected`（符合预期数）、`ert-stats-completed-unexpected`（不符合预期数）。

## 25.8 按选择器筛选

```elisp
;; 只跑一部分用例：ert-run-tests 的第一个参数是 selector。
;;      t                    全部
;;      'demo-test-heading   按名字
;;      "heading"            按名字的正则
;;      :new / :failed / :passed  按上次运行结果
;; 在 Emacs 里用 M-x ert 时也可以输入 selector。
(let ((stats (ert-run-tests "heading" demo-silent-listener)))
  (princ (format "8) 只跑名字含 heading 的用例：%S 个\n"
                 (ert-stats-total stats))))
```

```text
8) 只跑名字含 heading 的用例：2 个
```

| selector | 含义 |
|---|---|
| `t` | 全部 |
| `'symbol` | 按用例名（符号） |
| `"regexp"` | 按名字的正则（示例里 `"heading"` 命中 2 个） |
| `'(member a b)` | 指定的几个 |
| `'(tag :slow)` | 带某个 tag 的 |
| `:new` / `:failed` / `:passed` | 按**上次运行结果**（改完代码只重跑失败的那批，很快） |

## 25.9 故意失败与 :failed

```elisp
;; 失败时看什么：should 失败会记录
;;      :form    —— 断言的原始表达式
;;      :value   —— 实际求出的值
;;      :explanation —— 对「为什么不等」的解释（比如列表第几个元素不同）
;; 这比 (unless (equal a b) (error "not equal")) 有用得多，
;; 因为不用自己拼诊断信息。
(ert-deftest demo-test-intentional-failure ()
  :expected-result :failed          ; 告诉 ERT「我就是故意让它失败的」
  (should (= 1 2)))

(let ((stats (ert-run-tests 'demo-test-intentional-failure demo-silent-listener)))
  (princ (format "9) 故意失败的用例被标记为 :failed，ERT 记录为「符合预期」: %S\n"
                 (= 0 (ert-stats-completed-unexpected stats)))))
```

```text
9) 故意失败的用例被标记为 :failed，ERT 记录为「符合预期」: t
```

`ert-deftest` 支持 `:expected-result :failed`，意思是「这个用例本来就该失败」。用于**记录已知 bug**：它不会让构建变红，但你也没忘记它——等哪天它被修好了，ERT 会反过来报告「意外的成功」，提醒你把标记删掉。

## 25.10 断言的粒度

```elisp
;; 断言的粒度：一个用例里多个 should 是可以的，
;; 但第一个失败就会中断后面的。想一次看到所有问题就拆成多个用例 ——
;; 代价是重复的 setup 代码，可以用宏或 helper 函数抽出来。
(princ "10) 一个 ert-deftest 里第一个 should 失败就停，想全看就拆用例\n")
```

```text
10) 一个 ert-deftest 里第一个 should 失败就停，想全看就拆用例
```

一个用例里**第一个** `should` 失败，后面的就不再执行了。所以：

- 想一次看到所有问题 → 拆成多个小用例；
- 一个用例测「一件事」→ 更容易定位失败原因；
- 拆开后重复的 setup → 用宏或 helper 函数抽出来。

## 25.11 测试文件放哪

```elisp
;; 测试文件放哪：
;;      - 单文件包   -> 同目录下的 foo-tests.el
;;      - 多文件包   -> test/ 目录
;;     CI 里的一行（Emacs 官方包的做法）：
;;      emacs -Q --batch -L . -l test/foo-tests.el -f ert-run-tests-batch-and-exit
(princ "11) 测试文件命名：foo-tests.el，放 test/ 目录下\n")
```

```text
11) 测试文件命名：foo-tests.el，放 test/ 目录下
```

约定：

```text
my-package/
├── my-package.el
└── test/
    └── my-package-tests.el
```

命名用 `-tests.el` 后缀，这样 `M-x ert` 的默认选择器和各种构建工具都能识别。CI 里的一行就够：

```bash
emacs -Q --batch -L . -l test/my-package-tests.el -f ert-run-tests-batch-and-exit
```

`-L .` 把当前目录加进 `load-path`，这样测试文件里的 `(require 'my-package)` 才找得到包本体。

## 25.12 坑位清单

1. 用 `ert-run-tests-batch-and-exit` 还想保持 stdout/stderr 纯净 —— 它的输出**走 stderr**；要程序化统计就用 `ert-run-tests` + 自己的 listener。
2. 测 buffer 代码不用 `with-temp-buffer` —— 污染用户 buffer / 别的测试，出现「单独跑能过、一起跑就挂」。
3. 断言里硬编码 `point-max` —— 它是「末尾 + 1」，比字符数大 1；用 `(length ...)` 反推更稳。
4. mock 完不恢复 —— 用 `cl-letf`（自动恢复），别用 `defun` 硬改。
5. 构造场景时用 `setq` 改配置变量 —— 退出后不恢复；对 `defvar` 变量用 `let` 动态绑定。
6. 环境不满足就让测试失败 —— 用 `skip-unless` 跳过。
7. 用例名不带包名前缀 —— 没法按前缀批量筛选，也会和别的包撞名。
8. 一个用例塞十几个 `should` —— 第一个失败就停，看不到后面的问题；拆开。
9. 忘了 `:expected-result :failed` 的反向语义 —— 已知 bug 修好后它会报「意外的成功」，提醒你删标记。
10. 测试文件和包本体放一起却没 `-L .` —— CI 里 `require` 找不到包。

---

上一章：[24 · 模块、加载与打包](24-packages.md)　｜　下一章：[26 · 完整示例：一个 todo 扩展](26-todo-demo.md)　｜　返回：[Emacs 扩展开发指南](README.md)
