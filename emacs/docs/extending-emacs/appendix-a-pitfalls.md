# 附录 A · 常见坑速查

按「症状 → 原因 → 解法」排列。这些全部来自本仓库示例的开发过程。

## A.1 编译/验证类

| 症状 | 原因 | 解法 |
|---|---|---|
| batch 模式跑了但什么都没输出 | 用了 `message`，它走 stderr | 改用 `(princ (format ...))` |
| 「stderr 为空」判定失败 | 字节编译产生了警告 | 看 `.compile.err`，逐条消掉 |
| 输出里有乱码/控制字符 | `%S` 打印了键序列或 advice 对象 | 用 `key-description` / `(and x t)` |
| 编译报 Cannot open load file | 顶层 `require` 一个运行期才存在的东西 | 挪进函数体 / `declare-function` |
| 编译报 Unused lexical variable | `dotimes` 的 RESULT 表达式没用循环变量 | 让结果式引用它，或改用 `let` |
| 编译报 reference to free variable | 用了编译器不认识的错误符号（如 `no-catch`） | 用 `error` 兜 |
| batch 里定时器不触发 | 没有事件循环 | 用 `sleep-for` 推进 |
| batch 里 idle timer 不触发 | 没有「空闲」概念 | 无解，改交互式测 |

## A.2 语义类

| 症状 | 原因 | 解法 |
|---|---|---|
| `(eq 1.0 1.0)` 是 nil | `eq` 比对象身份 | 数字用 `=`，结构用 `equal` |
| `alist-get` 对字符串 key 总返回 nil | 它默认用 `eq` 比 | `(alist-get k a nil nil #'equal)` |
| `assq` 查不到字符串 key | 同上 | 用 `assoc` |
| `(if x ...)` 里 0 走了 then | 0 在 Elisp 里是真 | 显式判 `(/= x 0)` |
| `(substring "abc" 0 99)` 没报错 | 越界被截断 | 自己检查范围 |
| `(string-to-number "abc")` 是 0 | 转换失败不报错 | 用正则先校验 |
| `split-string` 把空字段吃掉了 | 默认丢空串 | 第 3 个参数传 `t` |
| `(delete x list)` 后 `list` 还是旧的 | `delete` 可能返回新头 | 接收返回值 `(setq list (delete ...))` |
| 改了 `y` 的 `x` 也变了 | `setq` 共享结构 | `copy-tree`（深）或 `copy-sequence`（浅） |
| closure 全都捕获到同一个值 | 循环变量是 `defvar` 过的 special 变量 | 别 `defvar` 循环变量 |

## A.3 编辑器对象类

| 症状 | 原因 | 解法 |
|---|---|---|
| 相对路径写到了奇怪的地方 | `default-directory` 是 buffer 局部的 | 传绝对路径或 `let` 指定 |
| `directory-files` 结果里有 `"."` `".."` | 默认不过滤 | 用锚定正则 `"\\`[^.]"` |
| font-lock 设了但不生效 | 父类是 `special-mode`，不自动开 | body 里显式 `(font-lock-mode 1)` |
| `search-forward` 之后替换了错的地方 | point 停在匹配**末尾** | 配合 `replace-match`，或先取 `match-beginning` |
| `invisible` 的文本还能被搜索到 | 它只是不显示 | 处理 `buffer-invisibility-spec` |
| `derived-mode-parent` 是 nil | parent 是 `fundamental-mode` | 用 `derived-mode-p` 判断 |
| `equal` 认为带 face 的字符串相等 | `equal` 忽略文本属性 | `equal-including-properties` |
| 「按键不生效」 | 被更优先的 keymap 覆盖 | 按 minor → local → global 顺序查 |

## A.4 扩展机制类

| 症状 | 原因 | 解法 |
|---|---|---|
| `M-x` 里找不到自己的函数 | 忘了 `(interactive)` | 加上 |
| hook 执行顺序和预期相反 | `add-hook` 默认插到最前面 | 第 3 个参数传 `t`，或用 DEPTH |
| 摘不掉 hook 里的函数 | 加的是 lambda | 一律用具名函数 |
| 关掉 mode 后别的 buffer 受影响 | hook 装成了全局的 | `(add-hook ... nil t)` |
| `advice-remove` 删不掉 | advice 是 lambda | 用具名 `defun` |
| advice 摘不掉 / 卸载后还生效 | 没用 `unwind-protect` | 包在 `unwind-protect` 里 |
| `setq` 改了 `defcustom` 但没生效 | `:set` 只有 customize 路径才触发 | 用 `customize-set-variable` |
| `:set` 里 `set-default` 忘了写 | 只执行了副作用 | 先 `set-default` |
| `cancel-timer` 取消不掉 | 没存 timer 对象 | `(setq timer (run-with-timer ...))` |
| `require` 不存在的库把整个加载搞挂 | 默认会报错 | `(require 'x nil t)` |

## A.5 进程/异步类

| 症状 | 原因 | 解法 |
|---|---|---|
| sentinel 里判断状态失败 | event 末尾带换行 | 用 `process-exit-status` |
| 子进程一直不返回 | 没发 EOF | `process-send-eof` |
| Emacs 卡住 | 用了同步 `call-process` | 改 `make-process` 异步 |
| 参数里的空格被拆开了 | 整串交给了 shell | 命令和参数分开传 |
| 定时器里的错看不到 | 错误被 Emacs 吃掉 | 自己 `condition-case` 并打印 |
| 找不到外部命令时错误难懂 | 没预检查 | `(executable-find ...)` 先查 |

## A.6 语言细节类（第 10 部分）

第 36–40 章补的这批主题，坑的共同特点是**不报错、静默给错结果**，所以单独列一节。

| 症状 | 原因 | 解法 |
|---|---|---|
| 哈希表 `puthash` 进去 `gethash` 取不出来 | 默认 `:test` 是 `eql`，两个字符串永不 `eql` | 键是字符串/列表就写 `:test 'equal` |
| `maphash` 里新增键，Emacs 卡死 | 新键会被同一次遍历看到 | 先 `maphash` 收集键，再对快照 `dolist` |
| 想用 `hash-table-keys` 报 void-function | Emacs 31 没这个函数 | 自己 `maphash` 收集；判空用 `(zerop (hash-table-count h))` |
| `:rehash-size` 设了没效果 | 它和 `:rehash-threshold`、`:purecopy` 已废弃被忽略 | 别传；`:size` 也只是提示 |
| 自定义 `:test` 的表存盘后读回来不对 | `#s(hash-table test my-test …)` 里的符号下次未必注册过 | 存盘前转 alist 或换回 `equal` 表 |
| `gethash` 给默认值也区分不出「值是 nil」 | 默认值只在键不存在时生效 | 别存 `nil`，或 `maphash` 确认 |
| `(/ 7 2)` 得到 3 不是 3.5 | 两个整数相除是整除 | 写成 `(/ 7.0 2)` |
| `round` 把 2.5 舍成 2 | 银行家舍入（取偶） | 要「四舍五入」用 `(floor (+ x 0.5))` |
| 符号的 plist 里冒出 `variable-documentation` | `defvar` 带了 docstring | 演示四格时用不带 docstring 的 `defvar` |
| `unintern` 报参数个数错 | 它需要两个参数 | `(unintern sym obarray)` |
| 未 intern 的符号打印出来和 intern 过的一样 | 默认 `print-gensym` 为 nil | 设 `print-gensym` 打成 `#:foo` |
| 环形结构打印出 `#N`，读不回来 | 默认 `print-circle` 为 nil | 要存盘/还原共享关系就开 `print-circle` |
| `format` 拼完的字符串自带字体 | `%s` 会把文本属性一起粘走 | 先 `substring-no-properties` |
| `read` 一段文本后什么都没发生 | `read` 只读不执行 | 要执行再套一层 `eval` |
| `read` 循环读到末尾报 End of file | 空内容报的是错，不是返回 nil | 循环终止条件判「到末尾」，别判 nil |
| 拼字符串时 `%` 报错 | `%` 是转换符前缀 | 写 `%%` |
| `format` 参数多了没报错、结果却不对 | 多余参数静默忽略 | 参数个数要对齐（只有少了才报错） |
| 打印中文/换行时输出跨行 | `prin1` 默认不转义 | 设 `print-escape-newlines`；`pp` 默认就转义 |
| 浮点数打印只剩两位 | 全局设了 `float-output-format` | 在拼接那一步用 `(format "%.2f" x)` |

## A.7 压不住的字节编译警告

有两条警告**用 `with-no-warnings` 也压不住**（实测于 Emacs 31.1），只能改代码：

| 警告 | 为什么压不住 | 怎么办 |
|---|---|---|
| `pcase pattern X shadowed by previous pcase pattern` | 由 C 层的 `macroexp-warn-and-return` 发出；`with-no-warnings` 只在字节编译时有效，解释执行（`-l` 加载）时照样报，`byte-compile-log-warning-function` 也拦不住它打 stderr | 别写裸符号打头的多子句 `pcase`，改用 `(and (pred ...) VAR)` |
| `quoted with ' rather than with #'` | 同上 | lambda 一律用 `#'` |

（能压住的那些——比如 `avoid ‘lsh’; use ‘ash’ instead`——正常用 `with-no-warnings` 包住即可。）

---

上一章：[40 · 读取与打印：read、prin1、princ 与那一堆 print-* 开关](40-reading-printing.md)　｜　下一章：[附录 B · 命令与变量速查](appendix-b-cheatsheet.md)　｜　返回：[Emacs 扩展开发指南](README.md)
