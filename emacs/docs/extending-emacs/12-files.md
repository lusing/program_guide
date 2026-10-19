# 12 · 文件与目录

> 所属部分：第 2 部分 · 编辑器数据结构
>
> 示例：`examples/12-files.el`

文件操作是扩展落地的必备能力。本章覆盖「路径运算 → 状态判断 → 读写 → 目录遍历 → 临时文件」。所有输出都是示例真跑出来的；为了可复现，示例**只打印文件名、不打印完整路径**（临时目录名每次运行都不同）。

## 12.1 【坑】相对路径相对谁

```elisp
(princ (format "default-directory 以 / 结尾: %S\n"
               (string-suffix-p "/" default-directory)))
```

```
default-directory 以 / 结尾: t
```

这是本章第一条也是最重要的一条：**相对路径是相对 `default-directory` 解析的，而它是每个 buffer 一份的 buffer-local 变量**。所以同一段代码在不同 buffer 里跑，可能读写完全不同的文件——batch 模式下它是启动目录，交互模式下它是当前 buffer 的目录。

```elisp
(princ (format "相对展开出来也是绝对路径: %S\n"
               (file-name-absolute-p (expand-file-name "data.txt"))))
(let ((default-directory "/tmp/emacs-demo/"))
  (princ (format "let 绑定 default-directory 后: %S\n"
                 (file-name-directory (expand-file-name "a.txt")))))
```

```
相对展开出来也是绝对路径: t
let 绑定 default-directory 后: "/tmp/emacs-demo/"
```

写扩展时的纪律：**只在 `default-directory` 明确的时候用相对路径**，否则一律传绝对路径，或者像上面那样显式 `let` 一下——`default-directory` 是 special 变量，动态绑定立刻生效。

## 12.2 路径运算：file-name-* 家族

这些全是**纯字符串运算，不碰磁盘**，文件不存在也能算：

```elisp
(defvar demo-path "/tmp/emacs-demo/sub/report.tar.gz")
(princ (format "目录: %S\n" (file-name-directory demo-path)))
(princ (format "文件名: %S\n" (file-name-nondirectory demo-path)))
(princ (format "扩展名: %S，去掉扩展名: %S\n"
               (file-name-extension demo-path)
               (file-name-sans-extension demo-path)))
(princ (format "换扩展名: %S\n" (file-name-with-extension demo-path "zip")))
(princ (format "拼路径: %S\n" (expand-file-name "data.txt" "/tmp/emacs-demo")))
(princ (format "取相对路径: %S\n"
               (file-relative-name "/tmp/emacs-demo/a.txt" "/tmp/emacs-demo")))
```

```
目录: "/tmp/emacs-demo/sub/"
文件名: "report.tar.gz"
扩展名: "gz"，去掉扩展名: "/tmp/emacs-demo/sub/report.tar"
换扩展名: "/tmp/emacs-demo/sub/report.tar.zip"
拼路径: "/tmp/emacs-demo/data.txt"
取相对路径: "a.txt"
```

逐个说明：

| 函数 | 作用 | 上面例子的结果 |
|---|---|---|
| `file-name-directory` | 目录部分（**带结尾斜杠**） | `"/tmp/emacs-demo/sub/"` |
| `file-name-nondirectory` | 文件名部分 | `"report.tar.gz"` |
| `file-name-extension` | 最后一个扩展名 | `"gz"` |
| `file-name-sans-extension` | 去掉最后一个扩展名 | `".../report.tar"` |
| `file-name-base` | 只去**最后一段**扩展名 | `"report.tar"`（注意不是 `"report"`！） |
| `file-name-with-extension` | 替换/添加扩展名 | `".../report.tar.zip"` |
| `file-name-as-directory` | 补上结尾斜杠 | `"/tmp/emacs-demo/"` |
| `expand-file-name` | 拼成绝对路径（会折叠 `..`） | `"/tmp/emacs-demo/data.txt"` |
| `file-relative-name` | 反向：算相对路径 | `"a.txt"` |

两个容易搞反的点：

- `file-name-extension` 只认**最后一个**点：`report.tar.gz` 的扩展名是 `gz`，不是 `tar.gz`；
- `file-name-base` 也只去掉最后一段：`report.tar.gz` 的 base 是 `report.tar`。想要 `report` 得去掉两次，或用正则自己切。

## 12.3 判断文件状态

```elisp
(princ (format "本文件存在: %S，/tmp 是目录: %S\n"
               (file-exists-p "/tmp") (file-directory-p "/tmp")))
```

```
本文件存在: t，/tmp 是目录: t
```

常用的几个谓词：

| 函数 | 问什么 |
|---|---|
| `file-exists-p` | 存在吗（**打不开的符号链接也算不存在**） |
| `file-directory-p` | 是目录吗 |
| `file-regular-file-p` | 是普通文件吗（排除目录/设备/管道） |
| `file-readable-p` / `file-writable-p` | 可读 / 可写吗 |
| `file-symlink-p` | 是符号链接吗（返回链接目标，不是 `t`） |

要区分「存在但打不开」，用 `file-symlink-p` 看它是不是个断链。

## 12.4 一次性写文件：with-temp-file

```elisp
(defvar demo-dir (make-temp-file "emacs-demo-" t))   ; t = 建目录
(defvar demo-file (expand-file-name "hello.txt" demo-dir))
(with-temp-file demo-file
  (insert "第一行\n")
  (insert (format "写于 Emacs %s\n" emacs-version)))
```

```
写入 "hello.txt"，大小 28 字节
读回内容: "第一行
写于 Emacs 31.1
"
嵌套写入成功: t
```

`with-temp-file` 新建一个临时 buffer，执行 body，然后把 buffer 内容写进文件——语义上就是「先拼好内容，再整体落盘」。

但它**不会自动创建父目录**：父目录不存在直接报错。需要自己先建：

```elisp
(make-directory (file-name-directory demo-sub) t)    ; t = 允许建多级
```

（示例里的 `嵌套写入成功: t` 就是先 `make-directory` 再 `write-region` 到 `nested/deep/note.txt` 的结果。）

## 12.5 读文件

最常见的「读成字符串」写法：

```elisp
(defvar demo-content
  (with-temp-buffer
    (insert-file-contents demo-file)
    (buffer-string)))
```

```
读回内容: "第一行
写于 Emacs 31.1
"
```

`insert-file-contents` 的签名是 `(file &optional visit beg end replace)`：后两个参数可以**只读一段字节**（大文件读前几行判断格式时很有用）。`visit` 非 nil 时才会做「标记为已访问」那套重活，纯读取场景保持默认 `nil` 最快。

## 12.6 写一段区域：write-region

```elisp
(write-region "嵌套目录里的内容\n" nil demo-sub)
(write-region "追加的一行\n" nil demo-file 'append)
```

```
追加后内容: "第一行
写于 Emacs 31.1
追加的一行
"
```

`write-region` 比 `with-temp-file` 底层：不新建 buffer，直接把指定区域写出去。`start`/`end` 传 `nil` 表示整个 buffer。**追加模式（第 5 个参数传 `append` 或 `t`）是它独有的能力**——写日志类的功能靠它。

## 12.7 遍历目录

```elisp
(princ (format "目录内容（含 . 和 ..）: %S\n" (directory-files demo-dir)))
(princ (format "只要 .txt（正则 + 不要 . ..）: %S\n"
               (mapcar #'file-name-nondirectory
                       (directory-files demo-dir t "\\.txt\\'"))))
(princ (format "递归全部文件: %S\n"
               (sort (mapcar #'file-name-nondirectory
                             (directory-files-recursively demo-dir "" t))
                     #'string<)))
```

```
目录内容（含 . 和 ..）: ("." ".." "hello.txt" "nested")
只要 .txt（正则 + 不要 . ..）: ("hello.txt")
递归全部文件: ("deep" "hello.txt" "nested" "note.txt")
```

三个函数：

| 函数 | 行为 |
|---|---|
| `directory-files dir` | 一层，**返回 `.` 和 `..`，不过滤目录** |
| `directory-files dir t regexp` | `t` = 返回绝对路径；正则按**文件名**匹配 |
| `directory-files-recursively dir regexp` | 递归；第 4 个参数 `t` 时包含目录本身 |

两个坑：

1. **`directory-files` 默认不过滤 `.` 和 `..`**，想排除点开头的，用锚定正则 `"\\`[^.]"`；
2. **递归结果的顺序依赖文件系统**，不可复现。示例里 `sort` 了一下——写测试/文档时这是必须的（否则输出每次都可能不一样）。

## 12.8 「访问文件」≠「读文件」

```elisp
(let ((buf (find-file-noselect demo-file)))
  (princ (format "buffer 名 = %S，已修改 = %S\n"
                 (buffer-name buf) (buffer-modified-p buf)))
  (kill-buffer buf))
```

```
buffer 名 = "hello.txt"，已修改 = nil
```

`find-file-noselect` 返回**与该路径关联的 buffer**——之前打开过就复用同一个（Emacs 靠 `buffer-file-name` 认亲）。它不切换窗口，是扩展里「拿到文件对应的 buffer」的正确函数；`find-file` 会真的切窗口，不适合在后台代码里调。

配套：`(buffer-file-name buf)` 拿 buffer 关联的文件路径（没关联返回 `nil`）。批处理程序用完记得 `kill-buffer`，否则 buffer 越攒越多。

## 12.9 复制、重命名、删除

```elisp
(copy-file demo-file (expand-file-name "copy.txt" demo-dir))
(rename-file (expand-file-name "copy.txt" demo-dir)
             (expand-file-name "renamed.txt" demo-dir))
(delete-file (expand-file-name "renamed.txt" demo-dir))
```

```
重命名后目录: ("hello.txt" "renamed.txt")
清理后目录还在吗: nil
```

`copy-file` / `rename-file` 的最后一个参数是「覆盖已存在的目标吗」（`ok-if-already-exists`），
`delete-directory` 的第二个参数 `t` 表示「连内容一起删」。

**规矩：自己造的临时文件必须自己删干净。** 本仓库的 `12-files.el` 和 `26-todo-demo.el` 都在最后一步清理，并且把「清理完成」也打印出来——万一清理失败，输出对不上，验证脚本立刻发现。

## 12.10 临时文件与数据目录

```elisp
(defvar demo-dir (make-temp-file "emacs-demo-" t))   ; t = 建目录
(princ (format "temporary-file-directory 是目录: %S，user-emacs-directory 是目录: %S\n"
               (file-directory-p temporary-file-directory)
               (file-directory-p user-emacs-directory)))
```

```
temporary-file-directory 是目录: t，user-emacs-directory 是目录: t
```

`make-temp-file` 返回一个**已经创建好**的唯一路径；第二个参数传 `t` 表示「建目录而不是文件」
（示例就是这么造的 `demo-dir`）。只要名字不想占位，用 `make-temp-name`（只算名字，不创建）。
这两个路径都随机器而变，示例只验证「是目录」，不打印具体值。

`user-emacs-directory`（通常是 `~/.emacs.d/`）是扩展放持久数据的标准位置——约定俗成是再套一层自己的包名：`(expand-file-name "my-package/" user-emacs-directory)`，别直接往根下扔文件。

## 12.11 本章小结

| 想干什么 | 用什么 |
|---|---|
| 拼绝对路径 | `expand-file-name` |
| 拆路径 | `file-name-directory` / `-nondirectory` / `-extension` / `-sans-extension` |
| 判存在/类型 | `file-exists-p` / `file-directory-p` / `file-regular-file-p` |
| 写整个文件 | `with-temp-file`（记得先 `make-directory`） |
| 读整个文件 | `with-temp-buffer` + `insert-file-contents` |
| 写一段/追加 | `write-region` |
| 遍历目录 | `directory-files`（注意 `.`/`..`）/ `directory-files-recursively`（记得 sort） |
| 拿文件的 buffer | `find-file-noselect`（用完 `kill-buffer`） |
| 临时文件 | `make-temp-file`（用完自己删） |

---

上一章：[11 · 文本属性与 overlay](11-text-properties.md)　｜　下一章：[13 · 交互式命令](13-interactive.md)　｜　返回：[Emacs 扩展开发指南](README.md)
