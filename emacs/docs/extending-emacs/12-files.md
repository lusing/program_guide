# 12 · 文件与目录

> 所属部分：第 2 部分 · 编辑器数据结构

> 示例：`examples/12-files.el`

## 12.1 【坑】相对路径相对谁

```
default-directory = "~/code/programming/emacs/build/"
```

这是本章第一条也是最重要的一条：**相对路径是相对 `default-directory` 解析的，而它是每个 buffer 一份的**。
所以同一段代码在不同 buffer 里跑，可能读写完全不同的文件。

```elisp
(expand-file-name "data.txt")     ; 相对当前 default-directory
(expand-file-name "data.txt" "/tmp/")   ; 相对指定目录
```

写扩展时的纪律：**只在 `default-directory` 明确的时候用相对路径**，否则一律传绝对路径，
或者显式 `let` 一下：

```elisp
(let ((default-directory "/tmp/"))
  (write-region ... "out.txt"))    ; 确定写到 /tmp/out.txt
```

## 12.2 路径运算：file-name-*

这些全是**纯字符串运算，不碰磁盘**，所以在文件不存在时也能用：

```elisp
(file-name-directory "/tmp/a/report.tar.gz")   ; → "/tmp/a/"
(file-name-nondirectory "...")                 ; → "report.tar.gz"
(file-name-extension "...")                    ; → "gz"
(file-name-sans-extension "...")               ; → "/tmp/a/report.tar"
(file-name-base "...")                         ; → "report"
(file-name-as-directory "/tmp/a")              ; → "/tmp/a/"
(file-name-relative "/tmp/a/b.txt" "/tmp/a/")  ; → "b.txt"
(expand-file-name "data.txt" "/tmp/emacs-demo") ; → "/tmp/emacs-demo/data.txt"
```

```
文件名: "report.tar.gz"
扩展名: "gz"，去掉扩展名: "/tmp/emacs-demo/sub/report.tar"
换扩展名: "/tmp/emacs-demo/sub/report.tar.zip"
拼路径: "/tmp/emacs-demo/data.txt"
取相对路径: "a.txt"
```

注意 `file-name-extension` 只取**最后一个**点之后的部分（`report.tar.gz` → `gz`）。

## 12.3 判断文件状态

```elisp
(file-exists-p path)
(file-directory-p path)
(file-regular-file-p path)
(file-readable-p path)
(file-writable-p path)
```

```
本文件存在: t，/tmp 是目录: t
```

## 12.4 一次性写文件：with-temp-file

```elisp
(with-temp-file "/tmp/x.txt"
  (insert "第一行\n")
  (insert (format "写于 Emacs %s\n" emacs-version)))
```

```
写入 ".../hello.txt"，大小 28 字节
读回内容: "第一行
写于 Emacs 31.1
"
嵌套写入成功: t
```

`with-temp-file` 新建一个临时 buffer，执行 body，然后**把 buffer 内容原子性地写进文件**
（先写临时文件再 rename，所以不会因为中途崩溃留下半个文件）。

但它**不会自动创建父目录** —— 父目录不存在就直接报错。需要自己先建：

```elisp
(make-directory (file-name-directory path) t)   ; 第二个参数 t = 递归创建
```

## 12.5 读文件

```elisp
(with-temp-buffer
  (insert-file-contents "/tmp/x.txt")     ; 读进当前 buffer
  (buffer-string))

(with-temp-buffer
  (insert-file-contents "/tmp/x.txt" nil 0 10)   ; 只读前 10 个字节
  ...)
```

`insert-file-contents` 的参数是 `(file &optional visit beg end replace)`，后两个可以只读一段。

## 12.6 写一段区域：write-region

```elisp
(write-region start end filename)          ; 写 buffer 的 [start,end) 到文件
(write-region start end filename t)        ; 第 5 个参数 t = **追加**
```

```
追加后内容: "第一行
写于 Emacs 31.1
追加的一行
"
```

`write-region` 比 `with-temp-file` 底层：它不新建 buffer，直接把**指定区域**写出去。
追加模式（第 5 个参数）是它独有的能力。

## 12.7 遍历目录

```elisp
(directory-files dir)                  ; 含 "." 和 ".."
(directory-files dir t "\\.txt\\'")    ; t = 返回绝对路径；正则匹配文件名
(directory-files-recursively dir "\\.el\\'")   ; 递归
```

```
目录内容（含 . 和 ..）: ("." ".." "hello.txt" "nested")
只要 .txt（正则 + 不要 . ..）: (".../hello.txt")
递归全部文件: ("note.txt" "deep" "nested" "hello.txt")
```

坑在默认行为：`directory-files` **不过滤 `.` 和 `..`**，也不过滤目录。所以遍历时要：

```elisp
(directory-files dir t "\\`[^.]")     ; 用锚定的正则排除点开头的
```

## 12.8 「访问文件」≠「读文件」

```elisp
(let ((buf (find-file-noselect "/tmp/x.txt")))
  ...)
```

```
buffer 名 = "hello.txt"，关联文件 = ".../hello.txt"，已修改 = nil
```

`find-file-noselect` 返回**与该路径关联的 buffer**，如果之前已经打开过就复用同一个 buffer。
它不切换窗口。这是扩展里要「拿到文件对应的 buffer」时的正确函数 ——
`find-file` 会真的切窗口，不适合在后台代码里调。

相关函数：`(buffer-file-name buf)` 拿 buffer 关联的文件，`(file-name-base ...)` 拿 buffer 名。

## 12.9 复制、重命名、删除

```elisp
(copy-file from to)              ; 第三个参数 t = 覆盖已存在的
(rename-file from to)
(delete-file path)               ; 删文件
(delete-directory path)          ; 删目录（第 2 个参数 t = 递归）
(make-directory path t)          ; 建目录（t = 递归）
```

```
重命名后目录: ("hello.txt" "renamed.txt")
清理后目录还在吗: nil
```

## 12.10 临时文件

```elisp
(make-temp-file "prefix-")       ; 返回一个新建的唯一文件路径
(temporary-file-directory)       ; 系统的临时目录
```

```
temporary-file-directory = "/var/folders/.../T/"
user-emacs-directory = "~/.emacs.d/"
```

**规矩：示例/测试自己造的临时文件必须自己删干净。** 本仓库的 `12-files.el` 和 `26-todo-demo.el`
都在最后一步清理，并且把「清理完成」也作为输出打印出来 —— 这样万一清理失败，输出对不上，
验证脚本会发现。

`user-emacs-directory` 是用户配置目录，扩展放数据的标准位置（`{user-emacs-directory}/你的包名/`）。

---

上一章：[11 · 文本属性与 overlay](11-text-properties.md)　｜　下一章：[13 · 交互式命令](13-interactive.md)　｜　返回：[Emacs 扩展开发指南](README.md)
