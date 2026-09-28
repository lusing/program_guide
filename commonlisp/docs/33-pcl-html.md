# 33 · Practical：HTML 生成库——解释器与编译器（书 30–31 章）

> 配套示例：[`examples/33_pcl_html/`](../examples/33_pcl_html/main.lisp)（channel: both）
>
> 《Practical Common Lisp》第 30 章（FOO 解释器）+ 第 31 章（FOO 编译器）合并成压轴实战。

> **本章你将学会**：S 表达式当 HTML 的 DSL 设计、转义的语义位置（数据 vs 标记）、**解释器与宏编译器输出逐字节对账**、编译期转义这个核心优化。
> **前置章节**：14–15（宏两连）、16（format）。

## 33.1 DSL：S 表达式即 HTML

书里 FOO 库的子集——标签是关键字，属性是随后的关键字-值对，子节点混排字符串与嵌套标签：

```lisp
;; 数据形态（quote 住——它是数据，不是可执行代码）
'(:p :id "first" "1 < 2 & 3 > 2" (:b "加粗"))
;; → <p id="first">1 &lt; 2 &amp; 3 &gt; 2<b>加粗</b></p>
```

转义的语义边界一开始就要画对：**字符串是数据，要转义；标记是我们生成的，不转义**。`(:print expr)` 是原样输出口（运行期值，比如数字 42——princ 形态，不转义）。转义底座两版共用：

```lisp
(defun escape-string (s &optional (stream *standard-output*))
  (loop for ch across s
     do (case ch
          (#\& (write-string "&amp;" stream))
          (#\< (write-string "&lt;" stream))
          (#\> (write-string "&gt;" stream))
          (t (write-char ch stream)))))

(defun escape-to-string (s)
  (with-output-to-string (out)
    (escape-string s out)))
```

## 33.2 解释器：运行时走数据树

```lisp
(defun split-attrs (items)
  ;; 关键字打头的成对项收走当属性，剩下的全是子节点
  (let ((attrs nil))
    (loop while (and (rest items) (keywordp (first items)))
       do (setf attrs (nconc attrs (list (pop items) (pop items)))))
    (values attrs items)))

(defun render-html (sexp stream)
  (cond
    ((null sexp) nil)
    ((stringp sexp) (escape-string sexp stream))
    ((atom sexp) (format stream "~a" sexp))
    (t (let ((tag (first sexp)))
         (cond
           ((eql tag :print) (format stream "~a" (second sexp)))
           ((keywordp tag)
            (multiple-value-bind (attrs children) (split-attrs (rest sexp))
              (format stream "<~(~a~)" tag)
              (loop for (k v) on attrs by #'cddr
                 do (format stream " ~(~a~)=\"" k)
                    (escape-string (format nil "~a" v) stream)
                    (write-char #\" stream))
              (write-char #\> stream)
              (dolist (child children)
                (render-html child stream))
              (format stream "</~(~a~)>" tag))))))))
```

两个 format 细节：`~(...~)` 是小写化指令（`:ID` → `id`）；属性名/值用 `on attrs by #'cddr` 两两跳。解释器的优势：数据树是**一等公民**——可存可传可程序化构造。

## 33.3 编译器：宏在展开期把字面量拼成代码

书 31 章的卖点——**字面量的转义在编译期做完**，运行时只剩一串 `write-string` 常量：

```lisp
(defun compile-node (node)
  (cond
    ((stringp node) `(write-string ,(escape-to-string node)))   ; ← 编译期转义！
    ((eql (first node) :print) `(format t "~a" ,(second node))) ; ← 运行期表达式
    ;; 标签节点：开标签串/闭标签串拼成常量，子节点递归编译（完整版见示例）
    (t (compile-tag-node node))))

(defmacro html (&body sexps)
  (cons 'progn (mapcar #'compile-node sexps)))
```

`(html (:b "a<b"))` 展开里是 `(write-string "a&lt;b")`——转义已经发生，运行期零解释、零重复转义。`(:print expr)` 是唯一的运行期成分（expr 在展开现场求值）。**编译期/运行期的分界线就是转义发生的位置**——这是两章书最想让你看见的一句话。

## 33.4 对账：两版输出必须逐字节一致

示例结尾把同一页面分别喂给解释器（数据版）与编译器（宏版），`equal` 对账。能对账的前提是两版共用同一个转义底座（`escape-string`）——**一套语义，两种求值时机**。

## 33.5 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| CLISP 报「NIL does not match lambda list」 | `(with-output-to-string () …)` 的 NIL 变量形态它不认 | `make-string-output-stream` + 重绑 `*standard-output*` |
| 捕获不到编译器输出 | `with-output-to-string` 不绑 `*standard-output*` | 显式 `let ((*standard-output* s))` |
| 宏展开打印两实现不同 | pretty printer | 打印展开前关 `*print-pretty*` |
| 属性值没转义就拼进常量 | 属性值也是数据 | 编译期 `escape-to-string` 后再拼 |
| 括号数不平（又来） | 编译器生成代码的代码嵌套最深 | 逐行看深度曲线，别靠眼力 |

## 自测

1. 解释器和编译器各自的适用场景？（提示：数据从哪来、调用频率）
2. 「转义在编译期做完」优化了什么？运行时省掉了哪些工作？
3. `(:print expr)` 在解释器版和编译器版里分别是什么语义？
4. 为什么两版能共用 `escape-string`？DSL 的语义定义在哪个组件里？

---
上一章：[32 二进制与 ID3](32-pcl-binary.md) ｜ [返回目录](../README.md)
