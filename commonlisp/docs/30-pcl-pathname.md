# 30 · Practical：可移植路径名库（书 15 章）

> 配套示例：[`examples/30_pcl_pathname/`](../examples/30_pcl_pathname/main.lisp)（channel: both）
>
> 《Practical Common Lisp》第 15 章——一本教"写可移植 Lisp"的书的压轴可移植性章。

> **本章你将学会**：路径名的目录/文件两种形态及互转、`directory` 通配在两实现上的真实差异与统一法、`probe-file` 对目录的态度、递归走树。
> **前置章节**：17（流与文件）、22（实现对比）。

## 30.1 两种形态与互转

路径名的 name/type 都为空 = 目录形态。互转就是搬 name 进 directory：

```lisp
(defun component-present-p (value)
  (and value (not (eql :unspecific value))))

(defun directory-pathname-p (p)
  (and (not (component-present-p (pathname-name p)))
       (not (component-present-p (pathname-type p)))
       p))

(defun pathname-as-directory (path)
  (let ((pathname (pathname path)))
    (if (directory-pathname-p pathname)
        pathname
        (make-pathname
         :directory (append (pathname-directory pathname)
                            (list (pathname-name pathname)))
         :name nil :type nil :defaults pathname))))

(defun pathname-as-file (path)
  (let ((pathname (pathname path)))
    (if (not (directory-pathname-p pathname))
        pathname
        (make-pathname
         :directory (butlast (pathname-directory pathname))
         :name (car (last (pathname-directory pathname)))
         :type nil :defaults pathname))))

(namestring (pathname-as-directory #p"foo/bar.txt")) ; => "foo/bar/"
(namestring (pathname-as-file #p"foo/bar/"))         ; => "foo/bar"
```

## 30.2 实测差异账本（SBCL 2.6.8 vs CLISP 2.49.95）

这是本教程「diff 出可移植性」方法论的集中营，四个新条目：

| 行为 | SBCL | CLISP | 统一法 |
|---|---|---|---|
| `(directory "dir/*.*")` | 文件 + **子目录** | 只有文件 | 文件集 `remove-if #'directory-pathname-p` |
| `(directory "dir/*/")` | 子目录 | 子目录 | 直接可用 ✓ |
| `probe-file` 问目录 | 给真值 | **沉默的 NIL**（书年代是报错） | 见下 |
| `merge-pathnames "*/" dir` | 拼出预期 wildcard | **相对目录整个被换掉**，查询跑到 cwd | 拼 wildcard 一律 `make-pathname` + `:directory append` |

**实测大坑①**（merge 拼 wildcard）：`(merge-pathnames "*/" #p"p30/")` 在 CLISP 里把 `(:RELATIVE "P30")` 整个换成 `(:RELATIVE :WILD)`——前缀丢了，目录列举匹配出 cwd 下的 `p30/` 自己。书里的 `directory-wildcard` 用 `make-pathname` 是唯一稳法：

```lisp
(defun subdirs-wildcard (dirname)
  (let ((d (pathname-as-directory dirname)))
    (make-pathname :name nil :type nil
                   :directory (append (pathname-directory d) (list :wild))
                   :defaults d)))
```

存在性检测同理分家：

```lisp
(defun file-exists-p (path)
  ;; 别拿它问目录——CLISP 给 NIL
  #+sbcl (and (probe-file path) t)
  #+clisp (and (probe-file (pathname-as-file path)) t))

(defun directory-exists-p (path)
  ;; truename 对存在的目录两实现都干活；不存在都报错 → ignore-errors
  #+sbcl (and (probe-file (pathname-as-directory path)) t)
  #+clisp (and (ignore-errors (truename (pathname-as-directory path))) t))
```

## 30.3 list-directory：并集 + 排序

```lisp
(defun list-directory (dirname)
  (let* ((d (pathname-as-directory dirname))
         (files (remove-if #'directory-pathname-p
                           (directory (directory-wildcard d))))
         (subdirs (directory (subdirs-wildcard d))))
    (sort (append (mapcar #'file-namestring files)
                  (mapcar (lambda (p)
                            (concatenate 'string (entry-name p) "/"))
                          subdirs))
          #'string<)))
```

输出纪律有两条：**只打构件**（file-namestring、directory 尾）——`directory` 返回的是绝对真名，双通道 cwd 不同，绝对 namestring 一露脸输出必炸；**先排序**——返回顺序 ANSI 未规定。

## 30.4 walk-directory：递归走树

**实测大坑②**：文件和子目录必须**分开收集**——文件名拼个 "/" 就能骗过 `directory-pathname-p`，混在一个列表里递归必炸（SBCL 悄悄丢结果，CLISP 报错）。起点先 `truename` 成绝对路径，回调拿到的全是同源真名，好统一剥前缀：

```lisp
(defun walk-directory (dirname fn &key directories-p)
  (labels ((walk (dir)
             (let* ((files (sort (mapcar #'file-namestring
                                         (remove-if #'directory-pathname-p
                                                    (directory (directory-wildcard dir))))
                                 #'string<))
                    (subdir-names (sort (mapcar (lambda (p) (car (last (pathname-directory p))))
                                                (directory (subdirs-wildcard dir)))
                                        #'string<)))
               (dolist (f files)
                 (funcall fn (merge-pathnames f dir)))
               (dolist (sub subdir-names)
                 (walk (make-pathname
                        :name nil :type nil
                        :directory (append (pathname-directory dir) (list sub))
                        :defaults dir))))))
    (walk (truename (pathname-as-directory dirname)))))
```

细节：文件路径用 `merge-pathnames` 拼而不是 `make-pathname :name`——SBCL 对「name 含点 + type 空」的 namestring 会转义点号（`a\.txt`）。

## 30.5 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| CLISP 列目录列出目录自己 | merge 拼 wildcard 丢了前缀 | `make-pathname` + `:directory append` |
| SBCL 打印 `p30/a\.txt` | name 含点 + type 空的转义 | 文件路径用 `merge-pathnames` 拼纯文件名 |
| `(truename ".")` CLISP 报错 | 它按文件形态解析 "." | 用树根真名 `butlast` 推 cwd 前缀 |
| 走树把文件当目录递归 | 文件名拼 "/" 骗过 directory-pathname-p | 文件/子目录分开收集分别处理 |
| 双通道输出不一致 | 打印了 directory 返回的绝对真名 | 只打构件，或剥掉 cwd 前缀 |

## 自测

1. `directory-pathname-p` 判定的依据是什么？`:unspecific` 为什么要特判？
2. 为什么拼 wildcard 不能用 `merge-pathnames`？两种实现各自的症状？
3. `file-exists-p` 与 `directory-exists-p` 为什么必须分成两个函数（CLISP 的行为）？
4. 输出纪律两条（构件/排序）分别防的是什么炸法？

---
上一章：[29 单元测试框架](29-pcl-testfw.md) ｜ 下一章：[31 垃圾邮件过滤器](31-pcl-spam.md)
