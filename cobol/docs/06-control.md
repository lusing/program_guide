# 06 · 条件与控制流

> 示例：[`examples/06_control/06_control.cob`](../examples/06_control/06_control.cob)
> 运行：`./run-all.sh 06`

COBOL 的分支只有两个核心构造：`IF` 和 `EVALUATE`。但它的条件表达式特别"英语化"——关系
可以用符号也可以用单词，还有一批"条件类别"判断。本章把分支讲透。

## 1. IF / THEN / ELSE / END-IF

```cobol
           IF WS-SCORE >= 60
               DISPLAY "及格"
           ELSE
               DISPLAY "不及格"
           END-IF.
```

- `THEN` 可写可省（`IF cond THEN ...` 等价于 `IF cond ...`）。
- **`END-IF` 是范围终结符（scope terminator）**：现代 COBOL 强烈推荐用它明确结束 IF，
  而不是依赖句点。没有 `END-IF` 时，IF 的范围靠"下一个句点"界定，嵌套时极易出错。
- `ELSE` 可选。

实测输出：

```text
及格
```

## 2. 关系运算符：符号式与英语式完全等价

COBOL 的关系运算有两套写法，**含义一一对应**：

| 符号式 | 英语式 | 含义 |
|---|---|---|
| `=` | `IS EQUAL TO` / `EQUALS` | 等于 |
| `NOT =` 或 `<>` | `IS NOT EQUAL TO` | 不等于 |
| `<` | `IS LESS THAN` / `IS NOT GREATER THAN` | 小于 |
| `<=` | `IS NOT GREATER THAN` | 小于等于 |
| `>` | `IS GREATER THAN` | 大于 |
| `>=` | `IS NOT LESS THAN` | 大于等于 |

```cobol
           IF WS-NUM LESS THAN ZERO
               DISPLAY "WS-NUM 是负数（英语式关系运算）"
           END-IF.
```

> 字符串比较按**字节逐位**比（依字符集排序），定长 `PIC X` 会先补空格到等长再比。
> `"ABC" = "ABC   "`（X(8)）为真——尾随空格参与比较但相等。

## 3. 复合条件：AND / OR / NOT

```cobol
           IF WS-SCORE >= 80 AND WS-SCORE < 90
               MOVE "B" TO WS-GRADE
           END-IF.
```

- `AND` 优先级**高于** `OR`（和多数语言一致）；要改变顺序用括号。
- `NOT` 取反：`IF NOT (A AND B)`。
- 可以用括号分组：`IF (A OR B) AND C`。

## 4. 条件类别（Class Condition）：判断"是什么类型"

COBOL 有一批专门判断数据"类别/符号"的条件，读起来像英语：

| 条件 | 判断 |
|---|---|
| `IS NUMERIC` | 内容全是数字（对 `PIC X` 也能判，常用于校验输入） |
| `IS ALPHABETIC` | 全是字母（含空格，按字符集排序规则） |
| `IS ALPHABETIC-UPPER` | 全是大写字母/空格 |
| `IS ALPHABETIC-LOWER` | 全是小写字母/空格 |
| `IS POSITIVE` / `NEGATIVE` / `ZERO` | 数值 > 0 / < 0 / = 0 |

```cobol
           IF WS-DIGIT IS NUMERIC
               DISPLAY "WS-DIGIT 全数字（IS NUMERIC 命中）"
           END-IF.
           IF WS-STR IS ALPHABETIC-UPPER
               DISPLAY "WS-STR 全大写字母"
           END-IF.
           IF WS-NUM IS NEGATIVE
               DISPLAY "WS-NUM IS NEGATIVE 命中"
           END-IF.
```

> `IS NUMERIC` 对 `USAGE DISPLAY` 的数值项几乎恒真（它本来就只存数字）；它真正有用的
> 场景是校验 `PIC X` 输入项（如用户敲进来的字符串是不是纯数字），再决定能否 `NUMVAL`。
> `IS` 可省（`IF WS-DIGIT NUMERIC`）。

## 5. 88 层条件名（回顾）

第 03 章讲过的 `88` 条件名在这里大放异彩——它让 IF 读起来像英语：

```cobol
       01 WS-FLAG  PIC X VALUE "Y".
           88 IS-YES  VALUE "Y".
           IF IS-YES DISPLAY "确认" END-IF.     *> 等价 IF WS-FLAG = "Y"
```

## 6. EVALUATE：COBOL 的 switch，四种形态

`EVALUATE` 是多路分支，比一串嵌套 IF 清晰得多。它有四种常见形态：

### (a) 单值匹配

```cobol
           EVALUATE WS-DAY
               WHEN 1      DISPLAY "周一"
               WHEN 2      DISPLAY "周二"
               WHEN 3      DISPLAY "周三"
               WHEN OTHER  DISPLAY "其它"
           END-EVALUATE.
```

`WHEN OTHER` 是兜底分支（类似 default），强烈建议总是写。

### (b) 真值表形式：EVALUATE TRUE

```cobol
           EVALUATE TRUE
               WHEN WS-SCORE >= 90   MOVE "A" TO WS-GRADE
               WHEN WS-SCORE >= 80   MOVE "B" TO WS-GRADE
               WHEN WS-SCORE >= 60   MOVE "C" TO WS-GRADE
               WHEN OTHER            MOVE "F" TO WS-GRADE
           END-EVALUATE.
```

`EVALUATE TRUE` + `WHEN <条件>`：从上往下找**第一个为真**的 WHEN 执行，然后跳出
（不贯穿，没有 fall-through）。这是替代"else-if 链"的惯用法。

### (c) 区间、多值、列表

```cobol
           EVALUATE WS-TYPE
               WHEN "VIP"      DISPLAY "贵宾通道"
               WHEN "NORMAL"   DISPLAY "普通通道"
               WHEN OTHER      DISPLAY "未知类型"
           END-EVALUATE.

           EVALUATE WS-SCORE
               WHEN 80 THROUGH 89  DISPLAY "分数在 80-89 区间"
               WHEN OTHER          DISPLAY "不在区间"
           END-EVALUATE.
```

- `WHEN 80 THROUGH 89`：区间匹配（含端点）。
- `WHEN "A" "B" "C"`：多值列表（任一命中即可）。
- `WHEN 值 ALSO 另一列值`：多列联合判断（`EVALUATE a ALSO b` + `WHEN x ALSO y`）。

实测输出：

```text
周三
EVALUATE TRUE 评级=B
贵宾通道
分数在 80-89 区间
```

## 7. 范围终结符：END-IF / END-EVALUATE / END-PERFORM …

COBOL 85 起引入"显式范围终结符"，让嵌套结构一目了然：

| 构造 | 终结符 |
|---|---|
| `IF` | `END-IF` |
| `EVALUATE` | `END-EVALUATE` |
| `PERFORM`（内联） | `END-PERFORM` |
| `CALL` | `END-CALL` |
| `ADD`/`COMPUTE`/… | `END-ADD`/`END-COMPUTE`/… |
| `STRING`/`UNSTRING` | `END-STRING`/`END-UNSTRING` |
| `READ`/`WRITE` | `END-READ`/`END-WRITE` |

**为什么重要**：没有终结符时，语句范围靠句点结束，嵌套 IF 的"悬挂 ELSE"（dangling else）
会绑定到最近的 IF，极易写错。一律用 `END-IF`/`END-EVALUATE` 是结构化 COBOL 的纪律。

```cobol
      *  危险：没有 END-IF，ELSE 绑定不清
           IF A
               IF B DISPLAY "b"
               ELSE DISPLAY "属于哪个 IF？"     *> 绑到 IF B，不是 IF A！
      *  安全：显式 END-IF
           IF A
               IF B
                   DISPLAY "b"
               END-IF
           ELSE
               DISPLAY "明确属于 IF A"
           END-IF.
```

## 8. 完整实测输出

```text
及格
WS-NUM 是负数（英语式关系运算）
等级=B
WS-DIGIT 全数字（IS NUMERIC 命中）
WS-STR 全大写字母
WS-NUM IS NEGATIVE 命中
周三
EVALUATE TRUE 评级=B
贵宾通道
分数在 80-89 区间
==== 06 结束 ====
```

## 9. 坑位清单（实测）

1. **关系运算符号式与英语式等价**：`<` 就是 `IS LESS THAN`；`>=` 是 `IS NOT LESS THAN`
   （注意"大于等于"的英语式是"不小于"）。
2. **`AND` 优先级高于 `OR`**：要别的顺序加括号。
3. **悬挂 ELSE**：嵌套 IF 不写 `END-IF` 时，`ELSE` 绑最近的 `IF`——一律用范围终结符。
4. **`EVALUATE` 不贯穿**：命中一个 WHEN 就执行并跳出，没有 C 那样的 fall-through。
5. **`WHEN OTHER` 要写**：否则无匹配时什么都不做，容易漏情况。
6. **字符串比较按字节、定长补空格**：`"ABC"` 与 `X(8)` 的 `"ABC     "` 相等。
7. **`IS NUMERIC` 对 DISPLAY 数值项几乎恒真**：它的价值在校验 `PIC X` 输入。

---
上一章：[05 字符串处理](05-strings.md) ｜ 下一章：[07 循环：PERFORM](07-perform.md) ｜ 返回：[README](../README.md)
