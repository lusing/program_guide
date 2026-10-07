# 32 · Practical：二进制读写与 ID3 解析（书 24–25 章）

> 配套示例：[`examples/32_pcl_binary/`](../examples/32_pcl_binary/main.lisp)（channel: both）
>
> 《Practical Common Lisp》第 24 章（二进制解析框架）+ 第 25 章（ID3 解析器）合并成一章实战。

> **本章你将学会**：把「读一个值」抽象成泛型函数（类型即语法）、syncsafe 整数、ID3v2 标签的现场合成与解析回读。
> **前置章节**：17（二进制流 `:element-type`）、19（CLOS 泛型与 eql 特化）。

## 32.1 框架：read-value / write-value

书 24 章的核心抽象——**类型说明驱动 IO**，类型是 eql 特化的符号，参数用 `&key` 传：

```lisp
(defgeneric read-value (type stream &key))

(defmethod read-value ((type (eql 'u1)) stream &key)
  (read-byte stream))

(defmethod read-value ((type (eql 'u2)) stream &key)
  ;; 大端：高字节在前
  (+ (* 256 (read-byte stream)) (read-byte stream)))

(defmethod read-value ((type (eql 'iso-8859-1-string)) stream &key length)
  (let ((buf (make-array length :element-type 'character)))
    (dotimes (i length buf)
      (setf (char buf i) (code-char (read-byte stream))))))
```

`(read-value 'u2 in)` 换成 `(read-value 'iso-8859-1-string in :length 3)`——类型变了，参数表跟着变，调用方只换一个符号。写侧 `write-value` 是完全镜像的泛型。这一层抽象的价值在书 25 章兑现：ID3 的帧、头、字段全部落在同一套词汇表上。

## 32.2 二进制流的三个纪律

1. **流必须显式 `:element-type '(unsigned-byte 8)`**——默认是字符流，`read-byte` 直接类型错。
2. **向量不能当流**：想拿内存缓冲区当二进制流（`write-byte` 进 adjustable vector）在 SBCL 和 CLISP 里都被拒——「不是 stream」。标准库里没有 with-output-to-vector，要内存缓冲就写临时文件（或上 flexi-streams 库）。
3. **临时文件自己清**：`delete-file` 收尾，与 17 章同款纪律。

## 32.3 syncsafe 整数

ID3v2 的尺寸字段每字节只用低 7 位（最高位保留作同步标志）：

```lisp
(defun read-syncsafe (stream)
  (let ((value 0))
    (dotimes (i 4)
      (setf value (+ (* 128 value) (read-byte stream))))
    value))
```

编码是镜像的模 128 / 除 128。1024 编码成 `(0 0 8 0)`——每个最高位都是 0。

## 32.4 ID3v2.3：现场合成 + 解析回读

不需要真实 MP3——示例**现场造**一个标签写进文件再解析回来，字段对账全程可见：

```text
头 10 字节：  "ID3" + 主版本(u1) + 次版本(u1) + 标志(u1) + syncsafe 尺寸(4)
帧（v2.3）：  帧id(iso-8859-1-string :length 4) + 尺寸(u4) + 标志(u2) + 内容
文本帧内容：  编码字节(0=latin-1) + 正文
```

解析循环按「头里声明的帧区总长」读满为止（节选自示例，完整版见 main.lisp）：

```text
(let ((remaining (id3-tag-size tag)))
  (loop while (> remaining 0)
     do (let* ((id (read-value 'iso-8859-1-string in :length 4))
               (fsize (read-value 'u4 in))
               (fflags (read-value 'u2 in)))
          ;; ...读 fsize 字节内容...
          (decf remaining (+ 10 fsize)))))
```

书 24 章的 `skip-value`（跳过不感兴趣的段）是同一抽象的第三个成员：读掉、不存——示例里帧标志位就是被「读掉不存」的。

## 32.5 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `write-byte` 报「不是流」 | 拿 adjustable vector 当流 | 二进制走临时文件 |
| read-value 类型错 | open 没带 `:element-type '(unsigned-byte 8)` | 读写字节流都显式声明 |
| 帧解析错位 | 帧头 10 字节记错（id4+size4+flags2） | remaining 按 `(+ 10 fsize)` 扣 |
| 文本首字节混进正文 | 文本帧内容第 0 字节是编码标记 | `subseq data 1` 再转字符串 |
| 括号数不平 | 泛型/结构/循环嵌套深 | 写完数深度（本文件实测掉过一个 `)`） |

## 自测

1. `read-value` 的类型参数为什么用 `eql` 特化而不是类特化？
2. syncsafe 编码为什么每字节留最高位为 0？
3. ID3 头尺寸字段和帧尺寸字段的编码有什么不同？（syncsafe vs 普通 u4）
4. 为什么向量不能直接当二进制流用？标准里内存缓冲的替代是什么？

---

上一章：[31 垃圾邮件过滤器](31-pcl-spam.md) · 下一章：[33 HTML 生成库](33-pcl-html.md)
