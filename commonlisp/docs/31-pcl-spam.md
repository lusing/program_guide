# 31 · Practical：垃圾邮件过滤器（书 23 章）

> 配套示例：[`examples/31_pcl_spam/`](../examples/31_pcl_spam/main.lisp)（channel: both）
>
> 《Practical Common Lisp》第 23 章的统计核心：分词、特征计数、概率、分类。

> **本章你将学会**：纯手写分词（不依赖正则库）、哈希表特征库、拉普拉斯平滑概率、按信息量选特征、**把统计代码写成可移植示例的正路**（有理数算术）。
> **前置章节**：09（哈希表）、19 不需要、22（实现差异）。

## 31.1 骨架：分数 → 分类

```lisp
(defparameter *max-ham-score* 2/5)   ; 书里是 0.4
(defparameter *min-spam-score* 3/5)  ; 书里是 0.6

(defun classification (score)
  (cond ((<= score *max-ham-score*) 'ham)
        ((>= score *min-spam-score*) 'spam)
        (t 'unsure)))
```

阈值用**有理数**不是复古癖：书里全浮点（0.4、~f 打印），而 SBCL 与 CLISP 的浮点打印/舍入不保证逐字节一致——统计代码要做跨实现示例，有理数精确、可 `equal`、打印稳定，一步到位。

## 31.2 分词与特征库

书里 `extract-words` 用正则库（cl-ppcre）。零依赖的可移植写法是个小状态机：

```lisp
(defun ascii-letter-p (ch)
  ;; 只认 ASCII 字母——alpha-char-p 对 CJK 等宽字符两实现口径不一，别赌
  (let ((c (char-upcase ch)))
    (and (char<= #\A c) (char<= c #\Z))))

(defun extract-words (text)
  (let ((words nil) (cur nil))
    (flet ((flush ()
             (when cur
               (push (coerce (nreverse cur) 'string) words)
               (setf cur nil))))
      (loop for ch across text
         do (if (ascii-letter-p ch)
                (push (char-upcase ch) cur)
                (flush)))
      (flush))
    (nreverse words)))

(extract-words "Buy now!! cheap_viagra online")
;; => ("BUY" "NOW" "CHEAP" "VIAGRA" "ONLINE")
```

特征 = defstruct 计数 + 哈希表登记（"intern"一词是书里的原话——词第一次见就入库）：

```lisp
(defstruct word-feature
  (word "" :read-only t)
  (spam-count 0)
  (ham-count 0))

(defparameter *feature-database* (make-hash-table :test #'equal))

(defun intern-word (word)
  (or (gethash word *feature-database*)
      (setf (gethash word *feature-database*)
            (make-word-feature :word word))))
```

## 31.3 概率：拉普拉斯平滑

没见过的词**不站队**（概率 1/2），见过的按加一平滑：

```lisp
(defun word-spam-probability (feature)
  ;; +1 / +2 的平滑：spam=0,ham=0 → 1/2；证据越多越向 0 或 1 收
  (/ (+ 1 (word-feature-spam-count feature))
     (+ 2 (word-feature-spam-count feature)
        (word-feature-ham-count feature))))

(word-spam-probability (make-word-feature :word "x")) ; => 1/2
```

消息分数 = 信息量前 15 个特征的平均值（书后文升级为 Fisher 组合——统计加餐，示例留平均版）。

## 31.4 确定性：两条铁律 + 一个大坑

**铁律一**：哈希遍历必须排序——两实现的桶序不同：
`(sort (loop for k being each hash-key in *feature-database* collect k) #'string<)`

**铁律二**：排序比较器必须全序（平手按字典序），`sort` 不是稳定排序也无所谓。

**实测大坑**（值得裱起来）——这行代码在 SBCL 上**悄悄丢特征**，CLISP 上恰好正常：

```lisp
(let ((features (list 9 3 7 1 5))
      (pred #'>))
  ;; ✗ 错误示范：(length features) 在破坏性的 sort 之后才求值——
  ;;    features 变量可能已指向排序结果的中段尾巴，数出残链长度
  (subseq (sort features pred) 0 (min 15 (length features))))
;;                    ↑ 实参从左到右求值：sort 先跑残了链，length 后知后觉
```

SBCL 的 sort 重排后原列表头不再是结果头；CLISP 的 sort 恰好没挪头。修法一行：**先数长度再排序**：

```lisp
(let ((features (list 9 3 7 1 5))
      (pred #'>))
  (let ((n (min 15 (length features))))       ; ★ 长度在 sort 之前数好
    (subseq (sort features pred) 0 n)))       ; => (9 7 5 3 1)
```

这也是双通道逐字节比对的价值现场：单实现永远测不出这个 bug。

## 31.5 训练与分类

```lisp
(defun train (text type)
  (ecase type
    (spam (incf *total-spams*))
    (ham  (incf *total-hams*)))
  (dolist (feature (extract-features text))
    (increment-count feature type)))
```

示例里用固定语料（3 封垃圾 + 3 封正常）现场训练，然后四个文本分类——垃圾味的 `SPAM`、正常味的 `HAM`、两边都沾的 `UNSURE`、全生词的 `UNSURE`（每个词 1/2，平均还是 1/2 附近）。

## 31.6 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| SBCL 丢特征/分数飘 | `(length features)` 在破坏性 sort 之后求值 | 先数长度再 sort |
| SBCL stderr 有 undefined function 警告 | SBCL 逐 toplevel 编译，前向引用告警 | 定义顺序排好（被引用的先出现） |
| `~S` 打长列表两实现折行不同 | pretty printer | 关 `*print-pretty*` |
| `with-slots` 用在 defstruct 上 | defstruct 不保证 slot-value | 用访问器函数 |
| 中文/宽字符分词两实现不一致 | `alpha-char-p` 口径不一 | 只认 ASCII 字母 |

## 自测

1. 为什么阈值和分数全程用有理数？换成 float 会在哪一步破坏双通道一致？
2. 没见过的词概率是多少？平滑项（+1/+2）同时改变了什么？
3. `(subseq (sort v p) 0 (length v))` 的坑根因是什么？为什么单实现测试发现不了？
4. 特征选择的平手规则为什么必须存在？（提示：`sort` 的稳定性）

---
上一章：[30 可移植路径名库](30-pcl-pathname.md) ｜ 下一章：[32 二进制与 ID3](32-pcl-binary.md)
