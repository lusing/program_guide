# 10 · buffer 与 point

> 所属部分：第 2 部分 · 编辑器数据结构
>
> **本部分导读**：到这里语言部分讲完了。接下来是 Emacs 的三个核心对象 —— **buffer**、**文本属性/overlay**、 **文件**。写扩展和写普通 Lisp 程序最大的分界就在这儿：这些对象有状态、有生命周期、 有「当前」的概念（`current-buffer`、`current-local-map`……），必须理解透彻。

> 示例：`examples/10-buffers.el`

## 10.1 buffer 是一等公民

**Emacs 里文本不是「在文件里」，而是在 buffer 里**。文件只是 buffer 的一个可选关联（第 12 章）。
这个观念转换很重要 —— 扩展操作的对象绝大多数是 buffer。

```elisp
(with-temp-buffer
  (insert "hello\n")
  (buffer-string))
```

```
当前 buffer: "*scratch*"，所有 buffer 数: 4
```

`with-temp-buffer` 造一个用完即焚的临时 buffer，是所有扩展测试代码的标配。它保证：

- 不污染用户正在编辑的 buffer；
- 退出时自动 kill、自动恢复原来的 `current-buffer`；
- 可以嵌套。

## 10.2 point：位置是一个 1 开始的整数

```
插入后 point = 7（停在新文本之后）
point-min = 1, point-max = 7, bobp = t
到末尾: point = 7, eobp = t
```

- **point 从 1 开始**（不是 0）。`(point-min)` 是 1，`(point-max)` 是 `(buffer-size) + 1`；
- 插入文本后 point 停在**新插入内容之后**；
- `bobp` / `eobp` 判「在开头/结尾」。

「位置」和「字符」的区别：`point-max` 是个合法位置但**没有字符**（它是末尾之后）。
所以访问 `(char-after (point-max))` 是 `nil`。

## 10.3 移动

```
下移一行后 point = 5，当前行 = "bbb"
```

```elisp
(goto-char 5)              ; 绝对位置
(forward-char 2)           ; 相对移动
(forward-line 1)           ; 下移一行，返回「还剩几行没移动」（0 表示成功）
(line-beginning-position)  ; 行首
(line-end-position)        ; 行尾
```

`forward-line` 的返回值是「剩余行数」，比它移动的位置更有用 —— 判「有没有真的移动成功」靠它。

## 10.4 取内容

```elisp
(buffer-string)                    ; 整个 buffer
(buffer-substring 1 6)             ; 区间 [1,6)
(buffer-substring-no-properties 1 6) ; 不带文本属性（第 11 章）
```

```
buffer-substring 1..6 = "hello"
```

## 10.5 查找替换

```elisp
(goto-char (point-min))
(when (re-search-forward "THIS")
  (replace-match "that"))     ; 替换「刚匹配的那段」
```

```
re-search-forward 找到 id="42"，point 现在在 6
looking-at 从当前位置匹配: t
```

关键点：`re-search-forward` **把 point 移到匹配的末尾**，`replace-match` 替换的正是这段。
所以两者天然配对。要拿匹配位置用 `(match-beginning 0)` / `(match-end 0)`。

其他搜索函数：

| 函数 | 行为 |
|---|---|
| `search-forward` | 找字面字符串 |
| `re-search-forward` | 找正则，point 停在匹配末尾 |
| `re-search-backward` | 往回找，point 停在匹配开头 |
| `looking-at` | 从**当前位置**试匹配，**不移动** point |
| `looking-back` | 往回试匹配（有性能注意点） |

`replace-match` 的坑：替换字符串里 `\` 和 `\&` 有特殊含义（引用捕获组），
想要字面反斜杠要写 `\\\\`。安全做法是用第 4 个参数：

```elisp
(replace-match "字面\\文本" t t)     ; 第 4 个参数 t = 不当正则处理替换串
```

## 10.6 【核心】save-excursion

```elisp
(save-excursion
  (goto-char (point-min))
  ...)                  ; 退出时 point 自动还原
```

```
save-excursion 之后 point 还原到 8
```

这是写扩展时**最常用的宏**。它保存的不只是 point：

- **point 和 mark**；
- **当前 buffer**（所以里面 `set-buffer` 也会被还原）；
- **narrowing 状态**（下一节）。

所以「我要跳到别处做点事然后回来」一律用 `save-excursion`，不要手工记位置 —— 出错时（比如中途
signal 了错误）手工方案不会还原，`save-excursion` 会。

## 10.7 narrowing

把 buffer 逻辑上「裁」成一段，之后所有读写都只看这一部分：

```elisp
(save-restriction
  (narrow-to-region start end)
  ...)                 ; 退出自动恢复
```

```
narrow 之后 point-min=7 point-max=13 只看到="B1
还原之后又能看全: "A1
```

`save-restriction` 保存/恢复 narrowing。`save-excursion` 也会还原 narrowing，
但**语义上更明确的写法是 `save-restriction`** —— 两者嵌套时可以写得更清楚。

> narrowing 期间 `point-min` / `point-max` 会变，所以任何依赖绝对位置的代码在 narrowing 下都可能出错。
> 这也是为什么很多扩展会先 `(widen)`。

## 10.8 在别的 buffer 里干活

```elisp
(with-current-buffer "some-buffer"
  (buffer-string))                 ; 这里的「当前 buffer」是它

(let ((buf (get-buffer-create "demo")))
  (with-current-buffer buf
    (erase-buffer)
    (insert "内容"))
  buf)                             ; 返回 buffer 对象
```

```
名字="demo-work" 内容="工作在别的 buffer"
回到主 buffer: "*scratch*"，它还在吗: t
新建 buffer: "*demo-scratch*"，再取一次同一个对象: t
```

- `with-current-buffer` 是**宏**，退出自动恢复，优先用它；
- 对应地 `set-buffer` 是**函数**，不恢复 —— 只有在你确定后面要一直待在那儿时才用；
- `get-buffer` 找不到返回 `nil`，**`get-buffer-create` 会新建**。这个区别很重要：
  用错了会意外创建一堆垃圾 buffer。

## 10.9 小结表

| 需求 | 用什么 |
|---|---|
| 临时干活不污染 | `with-temp-buffer` |
| 跳到别处做完再回来 | `save-excursion` |
| 只看一段 | `narrow-to-region` + `save-restriction` |
| 在另一个 buffer 里干活 | `with-current-buffer` |
| 拿全部文本 | `buffer-string` |
| 拿一段文本 | `buffer-substring`（不去属性）/ `buffer-substring-no-properties` |

---

上一章：[09 · 序列与 cl-lib](09-sequences.md)　｜　下一章：[11 · 文本属性与 overlay](11-text-properties.md)　｜　返回：[Emacs 扩展开发指南](README.md)
