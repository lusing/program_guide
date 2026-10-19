# 25 · 测试

> 所属部分：第 5 部分 · 工程化

> 示例：`examples/25-tests.el`

## 25.1 ERT 基础

`ert` 是 Emacs 内置的测试框架：

```elisp
(require 'ert)

(ert-deftest demo-math-add ()
  "加法应该正确。"
  (should (= (+ 1 1) 2))
  (should (= (+ 2 3) 5)))
```

用例名字约定**以包名开头**（`demo-math-...`），这样才能按前缀批量筛选。

## 25.2 should 家族

```elisp
(should expr)                  ; expr 为真则通过
(should-not expr)              ; expr 为假则通过
(should-error (error "x"))     ; 期待报错；可以指定错误符号
(should (equal got 'expected))
```

这四种覆盖了绝大多数断言需求。

`should-error` 可以带 `:type` 精确要求错误类型：

```elisp
(should-error (demo-fail) :type 'demo-timeout)
```

## 25.3 【重点】测试 buffer 相关代码要隔离

```elisp
(ert-deftest demo-render-test ()
  (with-temp-buffer            ; ← 一定要用这个
    (demo-mode)
    (demo-render)
    (should (string-match-p "..." (buffer-string)))))
```

原因：测试会改当前 buffer 的内容，不用 `with-temp-buffer` 就会破坏用户正在编辑的东西
（在 CI 里则是破坏别的测试的状态 —— 造成「单独跑能过、一起跑就挂」的诡异现象）。

## 25.4 mock：cl-letf

```elisp
(ert-deftest demo-uses-mock ()
  (cl-letf (((symbol-function 'demo-network-call)
             (lambda (&rest _) "fake-response")))
    (should (equal (demo-fetch) "fake-response"))))
```

```
4) 用 cl-letf 临时改写函数，做「mock」。
```

`cl-letf` 临时换掉函数实现，**出了 `let` 自动恢复** —— 所以不会污染其他测试。
测试网络、时间、外部进程这类「不可控依赖」时必须 mock。

## 25.5 构造测试场景：let 动态绑定

```elisp
(let ((demo-config '((mode . "test"))))     ; demo-config 是 defvar 的，所以这是动态绑定
  (should (equal (demo-current-mode) "test")))
```

```
5) 用 let 临时改写变量（动态绑定）来构造测试场景
```

利用第 3.4 节的规则：对 `defvar` 过的变量，`let` 是临时改全局值、退出自动恢复。
这是构造「不同配置下」测试的标准手段。

## 25.6 skip-unless

```elisp
(ert-deftest demo-needs-network ()
  (skip-unless (demo-network-available-p))
  ...)
```

```
6) skip-unless：某些环境不满足时跳过，而不是失败。
```

环境不满足（没有网络、不是某个平台、缺某个外部工具）时**跳过**而不是失败 ——
这样在别人的机器和 CI 上不会出现假的红色。

## 25.7 运行测试

```
7) 跑完全部用例：共 7 个，符合预期 6 个，不符合 1 个
   （要看每条用例的详情，就用命令行跑 -f ert-run-tests-batch-and-exit）
```

| 入口 | 用途 |
|---|---|
| `M-x ert` | 交互式，能看到每条用例和失败详情，可重跑 |
| `M-x ert-run-tests-batch-and-exit` | 命令行/CI，退出码反映成败 |
| `(ert-run-tests 't (lambda ...))` | 程序化调用，自己控制输出 |

**为什么示例里不用 `ert-run-tests-batch-and-exit`？** 因为它把结果写到 **stderr** ——
实测：

```bash
$ emacs -Q --batch -l test.el 2>/dev/null
      # ← stdout 是空的
$ emacs -Q --batch -l test.el 2>&1 1>/dev/null
Running 1 tests (2026-09-16 16:15:44+0800, selector 't-ok')
   passed  1/1  t-ok (0.000107 sec)

Ran 1 tests, 1 results as expected, 0 unexpected
```

在「stderr 必须为空」的判定下这会失败。所以示例里用了**静默监听器**，
自己统计并打印：

```elisp
(let ((stats (ert-run-tests 'demo-todo-test (lambda (&rest _args) nil))))
  (princ (format "7) 单元测试：共 %S 个用例，失败 %S 个\n"
                 (ert-stats-total stats)
                 (ert-stats-completed-unexpected stats))))
```

这算是一个通用的经验：**ERT 的默认输出是给人看的，不是给程序读的** ——
要把测试结果接进自己的流水线，就自己接 `ert-stats-*`。

## 25.8 按选择器筛选

```elisp
(ert-run-tests "^demo-todo" ...)      ; 名字匹配正则的
(ert-run-tests '(member demo-a demo-b) ...)   ; 指定的几个
(ert-run-tests '(tag :slow) ...)      ; 带某个 tag 的
```

```
8) 只跑名字含 heading 的用例：2 个
```

## 25.9 故意失败与 :failed

```
9) 故意失败的用例被标记为 :failed，ERT 记录为「符合预期」: t
```

`(should-error ...)` 之外，ERT 还支持把某个用例标记成「本来就应该失败」
（`ert-deftest` 的 `:expected-result :failed`）。用于记录已知的 bug：
它不会让构建变红，但你也没忘记它。

## 25.10 断言的粒度

```
10) 一个 ert-deftest 里第一个 should 失败就停，想全看就拆用例
```

一个用例里**第一个** `should` 失败，后面的就不再执行了。所以：

- 想一次看到所有问题 → 拆成多个小用例；
- 一个用例测「一件事」→ 更容易定位失败原因。

## 25.11 测试文件放哪

```
11) 测试文件命名：foo-tests.el，放 test/ 目录下
```

约定：

```text
my-package/
├── my-package.el
└── test/
    └── my-package-tests.el
```

命名用 `-tests.el` 后缀，这样 `M-x ert` 的默认选择器和各种构建工具都能识别。

---

上一章：[24 · 模块、加载与打包](24-packages.md)　｜　下一章：[26 · 完整示例：一个 todo 扩展](26-todo-demo.md)　｜　返回：[Emacs 扩展开发指南](README.md)
