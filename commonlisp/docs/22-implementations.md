# 22 · 实现对比与可移植性：一份代码，两部发动机

> 配套示例：[`examples/22_portability/`](../examples/22_portability/main.lisp)（channel: both）
>
> 本章是全书的「差异结算章」：前面 20 章里标 ⚠️ 的双实现差异在这里汇总成军规，
> 并给出统一封装的模板。

## 22.1 双通道验证是怎么工作的

`run-all.sh` 对 `channel: both` 的示例跑两遍——SBCL 一遍、CLISP 一遍——
然后 `cmp` 两个通道的 stdout：**逐字节必须一致**。这不是抽象的「应当兼容」，
而是每个示例每次回归都在重新证明的**可判定断言**。

本章示例自己就是教学材料：每一节都演示「实现有差异的地方 → 用什么写法抹平」，
输出却两实现同文。

## 22.2 *features* 与 #+/#-：读取期的分发

`*features*` 是实现自报家门的列表；`#+`/`#-` 在**读取期**按它取舍代码：

```lisp
(defun program-arguments ()
  #+sbcl (cdr (member "--" sb-ext:*posix-argv* :test #'string=))
  #+clisp ext:*args*
  #-(or sbcl clisp) nil)

(defun portable-quit (&optional (code 0))
  #+sbcl (sb-ext:quit :unix-status code)
  #+clisp (ext:quit code)
  #-(or sbcl clisp) nil)
```

三条纪律：

1. **读取期分发，不赌运行期**——`sb-ext:*posix-argv*` 这个符号在 CLISP 里
   根本读不出来（SB-EXT 包不存在，read 阶段就报错），换运行期 `if` 是不行的；
2. 每行一个分支，最后 `#-(or ...)` 兜底；
3. 平台条件同理：`#+win32` / `#+unix` / `#+little-endian`（23 章的 shell-command）。

运行期判断用 `(member :sbcl *features*)`，结果归一成 T/NIL 再打印
（广义布尔差异，22.6）。

## 22.3 差异总账（实测，本机 SBCL 2.6.8 vs CLISP 2.49.95）

| # | 差异点 | SBCL | CLISP | 抹平写法 |
|---|---|---|---|---|
| 1 | fixnum 位宽 | 62 位 | 48 位 | 代码不依赖位宽；`most-positive-fixnum` 只做 `typep` |
| 2 | `pi` 的类型 | double `…d0` | long-float `…L0` | `(float pi 1.0d0)` 归一 |
| 3 | 浮点传染 | ANSI（取更宽） | 非 ANSI 默认（取单精度） | 显式后缀；`(float x 1.0d0)`；或置 `ext:*floating-point-contagion-ansi*` |
| 4 | `(sqrt -4)` / `(log 8 2)` / `(exp 0)` | 浮点结果 | 精确结果 | 给浮点输入或输出归一 |
| 5 | `#\Space` 的 `~S` | `#\ ` | `#\Space` | 打 `(char-name #\Space)` |
| 6 | `type-of "ab"` | `(SIMPLE-ARRAY CHARACTER (2))` | `(SIMPLE-BASE-STRING 2)` | 判断用 `typep` |
| 7 | `macroexpand-1 '(when …)` | `(IF …)` | 含 PROGN，形态不同 | 只展开自己的宏 |
| 8 | `''x` 的打印 | pretty 开才 `'X` | 恒 `'X` | 打印代码前统一绑 `*print-pretty*` |
| 9 | `~E` 单精度指数标记 | `e+4` 小写 | `E+4` 大写、位数不同 | `d0` 双精度输入 |
| 10 | `~T` 遇 CJK 的列宽 | 按字符 | 显示宽度口径不同 | ASCII 内容或 `~A` 定宽 |
| 11 | `~A` 打含换行字符串 | 原样内联 | 自动前后断行（pretty 填充） | 换行显式 `~%` |
| 12 | `delete` 作用于定长向量 | 挪动元素 | 保持不动 | `remove` 重建 / fill-pointer 向量 |
| 13 | `read-from-string` 第二值 | 指向未读首字符 | 指向已读末字符（差 1） | 不做逻辑 |
| 14 | 尾调用优化 | 默认做（debug 3 关） | 有限，约 5000 层爆栈 | 深递归改 loop |
| 15 | `fboundp` 等的返回 | 可能返回函数对象等真值 | 规矩的 T | `(if (fboundp x) t nil)` 归一 |
| 16 | 条件类名的包前缀 | `SB-INT:SIMPLE-PARSE-ERROR` | `SYSTEM::SIMPLE-PARSE-ERROR` | `(symbol-name (type-of e))` |
| 17 | 内置报错文本 | SBCL 措辞 | CLISP 措辞 | 只打印自己写的文案；捕标准父类 |
| 18 | CL 包锁 | 严（连 flet 绑 CL 名都拦） | 宽（仅警告） | 别碰 CL 包的名字 |
| 19 | 追加方法到已调用的泛型 | 无警告 | WARNING 到 stderr | 定义先于调用 |
| 20 | 带参 restart 无 :interactive | 接受 | 加载时 WARNING | 都配上 |
| 21 | `handler-case :no-error` 形参 | 宽容（可少接） | 严格（报 too many arguments） | `(:no-error (v &rest rest))` |
| 22 | `find-class` 未知类 | 直接报错 | WARNING+行为不同 | `(find-class x nil)` |
| 23 | `directory` 通配匹配子目录 | 匹配（namestring 为 `""`） | 不匹配 | 过滤 `(remove-if-not #'pathname-name …)` |
| 24 | 编译期诊断 | style-warning 进 stderr（如字面量除零、未用变量） | 部分场景静默 | 代码写到零警告 |
| 25 | ASDF | 内置 | 本构建不带 | SBCL 通道演示 / CLISP 自装 |
| 26 | 启动参数 | `--noinform --non-interactive --no-userinit --load f` | `-q -q -norc -E UTF-8 f` | 验证脚本已封装 |
| 27 | 默认字符编码 | UTF-8 | 跟 locale（ASCII 环境下中文报错） | CLISP 统一 `-E UTF-8` |

## 22.4 可移植代码五条军规

1. **平台/实现相关 → `#+/#-` 读取期分发**，绝不运行期赌；
2. **数值 → 显式后缀 / `float` 归一**；fixnum 位宽当不存在；
3. **哈希表 → 输出前排序**；遍历只遍历排序后的键；
4. **打印 → pretty 关掉、广义布尔归一、报错文案自己写**；
5. **深递归 → 改 loop**；别赌尾调用优化。

## 22.5 「当需要更多实现」时

- **bordeaux-threads**：一套线程 API，底下按 `*features**` 挑 SB-THREAD /
  CLISP 线程 / 其它——「扩展的可移植层」的标准样板；
- **cffi**：同思路的 FFI 层（25 章末尾）；
- **trivial-*** 系列（trivial-garbage、trivial-features…）：每个小差异一个微型抽象。
  自己写适配层时照这个模式：差异收进一个包，业务代码只见统一接口。

## 22.6 什么时候**不**追求可移植

SBCL 专属章（23–26）的存在就是答案：线程、FFI、精确的性能控制——
**先写对，再谈通用**。把 `SB-*` 的使用收进一个小适配层（或直接用
bordeaux-threads/cffi），将来换实现的成本就控制住了。

## 22.7 坑位清单

1. **「在我机器上是好的」**：双通道判定就是治这个的——每次回归都在第二个实现上
   重跑全部示例；
2. `(eq "a" "a")` 两实现可能不同——这不是 bug，是「未规定」；用 `equal`；
3. CLISP 忘 `-E UTF-8` 就地报错（01 章），验证脚本已内置；
4. 差异总账里的 27 条都有对应章节——写代码遇到诡异差异先查这张表。
