# 附录 B · 命令与变量速查

## B.1 交互式命令

| 命令 | 作用 |
|---|---|
| `M-x eval-buffer` | 重新加载当前 buffer 的代码 |
| `M-x eval-defun` / `C-M-x` | 重新求值当前函数 |
| `M-x toggle-debug-on-error` | 出错时弹 backtrace |
| `M-x checkdoc` | 检查 docstring/注释规范 |
| `M-x package-lint-current-buffer` | 检查打包规范（需装包） |
| `M-x ert` | 交互式跑测试 |
| `M-x profiler-start` / `profiler-report` | 性能分析 |
| `M-x list-faces-display` | 看所有 face 长什么样 |
| `M-x describe-key` / `C-h k` | 看某个键绑了什么 |
| `M-x describe-function` / `C-h f` | 看某个函数（含它的 advice） |
| `M-x describe-variable` / `C-h v` | 看某个变量的值和文档 |
| `M-x byte-compile-file` | 手动编译一个文件 |

## B.2 batch 命令行

```bash
# 加载文件
emacs -Q --batch -l file.el

# 求值一个表达式
emacs -Q --batch --eval '(princ "hi\n")'

# 字节编译（会检查警告）
emacs -Q --batch --eval '(byte-compile-file "file.el")'

# 跑 ERT 测试（结果写 stderr，退出码反映成败）
emacs -Q --batch -l file.el -f ert-run-tests-batch-and-exit

# 编译出的 .elc 直接加载
emacs -Q --batch -l file.elc
```

## B.3 常用变量

| 变量 | 含义 |
|---|---|
| `load-path` | `require` / `load` 的搜索路径 |
| `user-emacs-directory` | 用户配置目录（默认 `~/.emacs.d/`） |
| `temporary-file-directory` | 系统临时目录 |
| `default-directory` | 当前 buffer 的相对路径基准（buffer 局部） |
| `shell-file-name` / `shell-command-switch` | 当前平台的 shell |
| `minor-mode-map-alist` / `minor-mode-alist` | minor mode 的 keymap / mode-line 显示 |
| `auto-mode-alist` | 文件后缀 → major mode |
| `features` | 已加载的 feature 列表 |
| `timer-list` / `timer-idle-list` | 活跃的定时器 |
| `emacs-major-version` / `emacs-minor-version` | 版本号 |
| `most-positive-fixnum` | 最大的 fixnum（超过会变 bignum） |
| `print-gensym` | `%S` 是否把未 interned 符号显示成 `#:x` |

## B.4 判定标准（本仓库）

跑 `./run-all.sh` 或 `.\build.ps1 -All` 时，每个示例要过四关：

1. 字节编译退出码为 0；
2. 编译 stderr 为空（等价于零警告）；
3. 运行退出码为 0，运行 stderr 为空；
4. stdout 无多余控制字符，且有结束标记 `==== NN 结束 ====`。

---

## 写完之后

到这里你已经有了写扩展需要的全部工具。接下来最好的练习是**找一件你自己每天都烦的事**，
把它做成一 `defcustom` + 一个命令 + 一个 minor mode 的小包。真实需求会逼你把上面这些机制
一个个用起来 —— 而且你会遇到本指南里没写的坑，那很正常。等你遇到的时候，
回来读一读相关的那一章，再回去改。

Emacs 的扩展生态就是这样长出来的：一个人解决自己的问题，然后分享出去。

---

上一章：[附录 A · 常见坑速查](appendix-a-pitfalls.md)　｜　下一章：（无下一章）　｜　返回：[Emacs 扩展开发指南](README.md)
