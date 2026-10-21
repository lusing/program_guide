# 54 · 内省与工具：谓词族、object-assoc 与废弃清单

> 所属部分：第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

> 示例：`examples/54-eieio-introspection.el`

本部分最后一章，对应手册的 Introspection、eieio-opt（交互工具）与 obsolete 功能三部分。**内省**（introspection）是「代码在运行期查自己」的能力：谓词族回答「是不是某类」，`eieio-object-class`/`find-class`/`eieio-class-parents` 在对象与类之间互查，`eieio-class-slots` 翻开槽描述符，`object-assoc` 家族在对象列表里按槽检索。加上一批交互工具（类浏览器、customize 集成、构造帮助）和一份 **31.1 废弃清单实测**——哪些老名字还能跑、哪些已经删了、哪些挪进了 `obsolete/` 目录。

先亮四条实测要点：其一，谓词族有**七种粒度**，`类名-p`/`same-class-p` 只认本类，`cl-typep`/`object-of-class-p` 认子类，`class-p`/`child-of-class-p` 管类符号——用错粒度是最常见的 EIEIO bug 源；其二，`eieio-class-parents` 返回**类对象**列表（不能按符号打印），`eieio-class-children` 返回**直接子类符号**列表——两个函数返回形态不对称；其三，`eieio-class-slots` 只含**实例槽**（源码里挂着 FIXME 注释，类槽被刻意排除）；其四，`object-assoc-list-safe` 的「safe」真实语义是**允许对象没有该槽**，不是「容忍列表里混着非对象」——后者会照样报错。

## 54.1 谓词族：七个谓词，三种粒度

示例准备了一个三层类树：`shape` ← `circle` ← `unit-circle`（外加兄弟 `square`），然后把七个谓词全部试一遍：

示例第 1 节：

```elisp
(defclass shape ()
  ((name :initarg :name :initform "形" :type string))
  "图形基类。")
(defclass circle (shape)
  ((r :initarg :r :initform 1 :type number))
  "圆。")
(defclass square (shape)
  ((s :initarg :s :initform 1 :type number))
  "正方形。")
(defclass unit-circle (circle)
  ()
  "单位圆,circle 的子类,用于测试谓词粒度。")

(let ((c (circle :name "圆"))
      (u (unit-circle)))
  (princ (format "  class-p 类符号/对象/数字 → %S %S %S\n"
                 (class-p 'circle) (class-p c) (class-p 42)))
  (princ (format "  eieio-object-p 对象/符号  → %S %S\n"
                 (eieio-object-p c) (eieio-object-p 'circle)))
  (princ (format "  circle-p 本类/子类       → %S %S(自动谓词只认本类)\n"
                 (circle-p c) (circle-p u)))
  (princ (format "  cl-typep 认子类          → %S\n" (cl-typep u 'circle)))
  (princ (format "  same-class-p 本类/子类   → %S %S\n"
                 (same-class-p c 'circle) (same-class-p u 'circle)))
  (princ (format "  object-of-class-p 认子类 → %S\n" (object-of-class-p u 'circle)))
  (princ (format "  child-of-class-p 类名间  → %S %S\n"
                 (child-of-class-p 'unit-circle 'shape)
                 (child-of-class-p 'shape 'unit-circle))))
```

运行结果：

```
  class-p 类符号/对象/数字 → t nil nil
  eieio-object-p 对象/符号  → t nil
  circle-p 本类/子类       → t nil(自动谓词只认本类)
  cl-typep 认子类          → t
  same-class-p 本类/子类   → t nil
  object-of-class-p 认子类 → t
  child-of-class-p 类名间  → t nil
```

逐点读：

**按「操作对象」分两组。** 管**实例**的：`类名-p`（自动谓词，只认恰好本类）、`eieio-object-p`（是不是任何 EIEIO 对象）、`same-class-p`（实例与类符号同型判断，`circle-p` 内部就是它）、`cl-typep` 与 `object-of-class-p`（is-a，认子类）。管**类符号**的：`class-p`（这个符号是不是类）、`child-of-class-p`（两个类符号间的血统，含传递——unit-circle 是 shape 的孙类也算）。输出里 `class-p` 对实例返回 `nil`、`eieio-object-p` 对类符号返回 `nil`，正好演示两组互不跨界。

**选型口诀。** 业务逻辑里的类型分支（「如果是圆就算 πr²」）用 `cl-typep` 或 `object-of-class-p`——子类通常也该命中；反射与序列化里要「恰好是这个类」才用 `类名-p`/`same-class-p`；写类关系工具用 `child-of-class-p`。注意 `cl-typep` 与 `object-of-class-p` 还有个方向差异：前者是 `(cl-typep 对象 '类)`，后者是 `(object-of-class-p 对象 '类)`——参数顺序相同，随便记一个即可。

**过时的 `类名-child-p` 别再出现。** 25.1 之前的代码里每个类还有 `类名-child-p` 谓词（认子类的那种），如今是带警告的兼容定义——见到它请替换成 `object-of-class-p`。

## 54.2 对象与类互查

对象→类、符号→类对象、类→父类/子类——四个方向四个函数。示例第 2 节：

示例第 2 节：

```elisp
(let ((c (circle :name "圆")))
  (princ (format "  eieio-object-class      → %S(符号)\n" (eieio-object-class c)))
  (princ (format "  eieio-object-class-name → %S\n" (eieio-object-class-name c))))
(princ (format "  find-class 命中/未命中    → %S %S\n"
               (not (null (find-class 'circle))) (find-class 'no-such-class)))
(princ (format "  eieio-class-parents 个数  → %S(元素是类对象,不是符号)\n"
               (length (eieio-class-parents 'circle))))
(princ (format "  eieio-class-children      → %S(直接子类符号)\n"
               (eieio-class-children 'shape)))
```

运行结果：

```
  eieio-object-class      → circle(符号)
  eieio-object-class-name → circle
  find-class 命中/未命中    → t nil
  eieio-class-parents 个数  → 1(元素是类对象,不是符号)
  eieio-class-children      → (square circle)(直接子类符号)
```

逐点读：

**`eieio-object-class` 返回类符号。** 对象到类名一步直达；`eieio-object-class-name` 在 31.1 里返回值相同（存在是历史原因，老代码里它返回打印名）。拿到符号后接 `find-class` 得类对象、接 `make-instance` 造新实例——51.1 的转换链在这里闭环。

**`find-class` 是符号与类对象之间的桥。** 命中返回类对象，未命中返回 `nil`（它还有可选的 `errorp` 参数，传 `t` 时未命中直接报错）。类对象是 `#s(eieio--class …)` 大结构，**不要整体打印**——这也是示例对 `eieio-class-parents` 只演示 `length` 的原因：它的元素是类对象，`(eieio-class-parents 'circle)` 是「一个装着 shape 类对象的列表」，`%S` 打出来是几百字的内部结构。想要父类**符号**列表，`(mapcar #'eieio-class-name (eieio-class-parents …))`。

**`eieio-class-children` 返回直接子类符号。** `(square circle)`——只是**直接**子类（unit-circle 不在内），且顺序不保证（输出是定义逆序）。遍历整棵子树要自己递归。53.1 提过的不对称在此完整呈现：parents 给类对象、children 给符号，写通用遍历前先认清手头的返回形态。

## 54.3 槽内省：`eieio-class-slots` 与槽描述符

50.3 见过槽描述符的一面；这一节把槽内省函数讲全。示例第 3 节故意造一个「实例槽 + 类槽」各一的类：

示例第 3 节：

```elisp
(defclass meter ()
  ((name :initarg :name :initform "m" :type string)
   (base :allocation :class :initform 0 :type number))
  "一个实例槽加一个类槽。")

(princ (format "  class-slots 个数 → %S(只含实例槽,类槽 base 不在内)\n"
               (length (eieio-class-slots 'meter))))
(princ (format "  槽名列表        → %S\n"
               (mapcar #'eieio-slot-descriptor-name (eieio-class-slots 'meter))))
(princ (format "  描述符原样      → %S\n" (car (eieio-class-slots 'meter))))
```

运行结果：

```
  class-slots 个数 → 1(只含实例槽,类槽 base 不在内)
  槽名列表        → (name)
  描述符原样      → #s(cl-slot-descriptor name "m" string nil)
```

逐点读：

**只含实例槽——这是刻意为之。** 31.1 源码里 `eieio-class-slots` 直接委托给 `cl--class-slots`，旁边挂着 FIXME 注释说明类槽被忽略。`meter` 明明有两个槽，返回列表长度却是 1。写「遍历全部槽」的反射代码时记得类槽另算（类槽的值可以用 51.6 的 `oref-default` 读）。

**描述符是 `cl-slot-descriptor` 结构。** 字段依次是槽名、initform、类型、props（50.3 的 `:custom` 等选项在 props 里）。配套访问器 `eieio-slot-descriptor-name` 是公开入口——要槽名列表就 `(mapcar #'eieio-slot-descriptor-name (eieio-class-slots '类))`。老函数 `object-slots`（返回向量）自 25.1 起已过时，见到请换成这一套。

**返回的是列表不是向量。** 老手册和老代码按向量索引（`aref`）取描述符的写法在 31.1 会报类型错误——迁移代码时这是仅次于 `:name` 的高频坑。

## 54.4 `object-assoc` 家族：在对象列表里按槽查找

EIEIO 自带三个「对象版 assoc」：在对象列表里按某个槽的值检索。53.5 的 tracker-find 底层就是它们。示例第 4 节用「两个 circle 夹一个 square」的列表演示边界：

示例第 4 节：

```elisp
(let ((group (list (circle :name "甲" :r 1)
                   (square :name "乙" :s 2)
                   (circle :name "甲" :r 3))))
  (princ (format "  object-assoc \"甲\"  → 第一个匹配,r=%S\n"
                 (slot-value (object-assoc "甲" 'name group) 'r)))
  (princ (format "  assoc 缺槽不报错    → %S\n"
                 (object-assoc 2 's group)))
  (princ (format "  object-assoc-list   → %S\n" (object-assoc-list 'name group)))
  (princ (format "  assoc-list-safe 按槽 → %S\n"
                 (mapcar #'car (object-assoc-list-safe 's group)))))
```

运行结果：

```
  object-assoc "甲"  → 第一个匹配,r=1
  assoc 缺槽不报错    → #s(square "乙" 2)
  object-assoc-list   → (("甲" . #s(circle "甲" 1)) ("乙" . #s(square "乙" 2)) ("甲" . #s(circle "甲" 3)))
  assoc-list-safe 按槽 → (2)
```

逐点读：

**`object-assoc(键 槽 列表)`：equal 匹配，返回第一个。** 同名「甲」有两个 circle，返回 `r=1` 的那个（列表顺序的第一个）。**容忍缺槽**：`(object-assoc 2 's group)` 里只有 square 有 `s` 槽，两个 circle 被安静跳过——既不报 `invalid-slot-name` 也不报未绑定错。

**`object-assoc-list(槽 列表)`：返回 `(值 . 对象)` 的 alist。** 注意它**要求全部对象都有该槽**（上例统一用了大家都有的 `name`）。这个 alist 直接能喂给 `assoc`/`completion` 系函数——「按名字补全对象」两行代码的事。

**`object-assoc-list-safe` 的 safe 到底指什么。** 实测钉死：safe = **允许列表里的对象没有该槽**（内部先 `slot-exists-p` 再取值，没槽的跳过）——上例按 `s` 查，只剩 square 一家，car 出来是 `(2)`。但它**不能容忍非对象元素**：列表里混个符号照样 `wrong-type-argument`。所以选型很直白：列表里全是同类对象用 `object-assoc-list`，列表里混着不同类（有的类没这个槽）用 `-safe`。

## 54.5 交互工具：`eieio-browse` 与 `customize-object`

EIEIO 带了一组交互工具，批处理里没法演示界面，示例用 `fboundp` 确认它们在 31.1 都在岗：

示例第 5 节：

```elisp
(princ (format "  M-x eieio-browse       → fboundp %S\n" (fboundp 'eieio-browse)))
(princ (format "  M-x customize-object   → fboundp %S\n" (fboundp 'customize-object)))
(princ (format "  M-x eieio-help-constructor → fboundp %S\n"
               (fboundp 'eieio-help-constructor)))
```

运行结果：

```
  M-x eieio-browse       → fboundp t
  M-x customize-object   → fboundp t
  M-x eieio-help-constructor → fboundp t
```

逐点读（这批工具都是交互命令，按用途记）：

**`M-x eieio-browse`：类树浏览器。** 以 `eieio-default-superclass` 为根展开整棵类树，每个节点可点开看槽与方法——研究陌生 EIEIO 代码（比如 CEDET）时的第一站。它在 `eieio-opt.el`，autoload 已挂好，直接 `M-x` 即可。同文件还有三个助手：`eieio-build-class-alist`（把类树建成 alist，程序化浏览用）、`eieio-read-class`（带补全地读一个类名，写交互命令时用）、`eieio-display-method-list`（列出一个泛型的全部方法）。

**`M-x customize-object`：对象的图形化编辑器。** 按槽的 `:custom`/`:label`/`:group` 元数据（50.3）渲染 customize 界面，改完写回对象。在 `eieio-custom.el`。想让自家对象享受这个待遇，把 50.3 的三个定制选项填上即可。

**`M-x eieio-help-constructor`：构造参数速查。** 给一个类，弹出帮助 buffer 列出全部槽、initarg、initform 与文档——就是 49.1 说的「`:documentation` 白捡文档」的兑现处。

## 54.6 31.1 废弃清单实测

手册末尾的 obsolete 附录 + 迁移老代码的高频名字，逐一对 31.1 实测。示例第 6 节：

示例第 6 节：

```elisp
(princ (format "  fboundp class-option        → %S(函数已删)\n"
               (fboundp 'class-option)))
(princ (format "  fboundp set-slot-value      → %S(obsolete alias,勿用)\n"
               (fboundp 'set-slot-value)))
(princ (format "  fboundp object-name-string  → %S(obsolete alias)\n"
               (fboundp 'object-name-string)))
(princ (format "  fboundp object-p            → %S(obsolete alias)\n"
               (fboundp 'object-p)))
(princ (format "  boundp eieio-version        → %S(obsolete 变量)\n"
               (boundp 'eieio-version)))
(princ (format "  locate-library eieio-compat → %S(挪进 obsolete/,require 会告警)\n"
               (not (null (locate-library "eieio-compat")))))
```

运行结果：

```
  fboundp class-option        → nil(函数已删)
  fboundp set-slot-value      → t(obsolete alias,勿用)
  fboundp object-name-string  → t(obsolete alias)
  fboundp object-p            → t(obsolete alias)
  boundp eieio-version        → t(obsolete 变量)
  locate-library eieio-compat → t(挪进 obsolete/,require 会告警)
```

逐点读：

**`class-option` 已被删除（fboundp → nil）。** 50.8 讲过替代：读自定义类选项用内部函数 `eieio--class-option`。连同 50 章的 `:metaclass`/`:default-initargs` 静默忽略，这是「类选项」一节的三个迁移点。

**三个 obsolete alias 还活着（fboundp → t），但新代码勿用。** `set-slot-value`（→ `setf` + `slot-value`）、`object-name-string`（→ `eieio-object-name-string`）、`object-p`（→ `eieio-object-p`）——它们能跑，但字节编译会报 obsolete 警告。同理手册里的 `generic-p` 在 31.1 **根本不存在**（fboundp → nil），判断泛型用 `cl-generic-generalizers` 或干脆 `cl-find-method`。

**`eieio-compat` 挪进了 `lisp/obsolete/`，但还没删。** `locate-library` 找得到它；`(require 'eieio-compat)` 会打印 `Package eieio-compat is deprecated` 到 stderr——这个文件只为一群 25 之前的函数名（`eieio--` 前缀大迁移时代的旧名）提供兼容别名。新代码离它远点；老代码迁移时顺手把别名换掉就能彻底摆脱它。

**`eieio-version` 变量本身也是 obsolete。** 还在（boundp → t）但不该再用——查 Emacs 版本用 `emacs-version`，EIEIO 早已随 Emacs 同步发布，没有独立版本号的概念了。

## 54.7 小结：一张表 + 部分收束

| 主题 | 函数 | 一句话备忘 |
| --- | --- | --- |
| 实例谓词 | `类名-p` / `same-class-p` / `cl-typep` / `object-of-class-p` / `eieio-object-p` | 前两个只认本类；中间两个认子类；最后一个认一切 EIEIO 对象 |
| 类符号谓词 | `class-p` / `child-of-class-p` | 管符号不管实例；child-of 含传递 |
| 互查 | `eieio-object-class` / `find-class` / `eieio-class-parents` / `eieio-class-children` | parents 返回类对象（别整体打印），children 返回直接子类符号 |
| 槽内省 | `eieio-class-slots` / `eieio-slot-descriptor-name` | 返回列表（非向量）；只含实例槽；object-slots 已过时 |
| 对象检索 | `object-assoc` / `object-assoc-list` / `-safe` | assoc 容忍缺槽返回第一匹配；assoc-list 要求全有槽；safe=允许无槽非容忍非对象 |
| 交互 | `eieio-browse` / `customize-object` / `eieio-help-constructor` | 类树浏览、对象编辑、构造速查；配好 :custom 元数据待遇更佳 |
| 废弃 | class-option 已删；set-slot-value/object-name-string/object-p 是 alias；eieio-compat 挪进 obsolete/ | 见到旧名顺手换；require compat 会打 deprecated 警告 |

至此第 12 部分讲完。六章合起来是一份 EIEIO 的现代使用手册：**49 章**的最小闭环（defclass → 构造 → 方法 → 继承）、**50 章**的全部槽选项与类选项（含 31.1 的定义期校验与被忽略选项）、**51 章**的对象操作面（三个错误信号、绑定状态、类槽默认值）、**52 章**的方法系统（限定符顺序、call-next-method、C3 派发、cl-print-object 崩溃实测）、**53 章**的五个预定义基类（require eieio-base、:object-name、tracking-symbol 覆写）、**本章**的内省与废弃清单。手册里的 Emacs 23 时代写法——`:name` initarg、`:tracker-symbol`、defgeneric/defmethod、object-print、`[cl-struct-…]` 式输出——都已逐个替换为 31.1 的现行写法或明确标注不可行。写扩展时翻到这一部分的任何一章，抄到的都是今天就能跑通的代码。

上一章：[53 · 预定义基类：named、singleton、tracker、inheritor 与 persistent](53-eieio-base-classes.md)　｜　下一章：[附录 A · 常见坑速查](appendix-a-pitfalls.md)　｜　返回：[Emacs 扩展开发指南](README.md)
