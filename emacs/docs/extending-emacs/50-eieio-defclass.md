# 50 · defclass 详解：槽选项与类选项

> 所属部分：第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

> 示例：`examples/50-eieio-defclass.el`

49 章用四个槽选项（`:initarg`、`:initform`、`:type`、`:documentation`）跑通了全流程，但手册的 Defining Classes 一章为槽准备了**十来个选项**，外加若干**类级选项**。本章把它们全部拆开讲清楚：槽三要素的精确定义、访问器三兄弟、服务 customize 界面的三个选项、`:printer` 与序列化、类共享槽 `:allocation :class`、继承时的覆写规则，以及 `:abstract` 等类选项。

同样先亮 31.1 与老手册的**四个差异**，全部实测确认：其一，`:type` 的校验提前到了**定义期**——`:initform` 与 `:type` 不符的类在 `defclass` 求值时就报错，等不到运行期；其二，`:protection`（`:protected`/`:private`）**不再强制任何访问控制**，只是一个文档标记；其三，老手册里的类选项 `:metaclass` 与 `:default-initargs` 不报错但**被静默忽略**；其四，公开函数 `class-option` 已被删除，读自定义类选项要用内部函数 `eieio--class-option`。老代码迁移时这四条每条都值得过一遍。

## 50.1 槽三要素：`:initarg`、`:initform`、`:type`

手册把这三个选项称为槽的「基本件」，它们分别回答三个问题：构造时怎么给我传值？不传时我是什么？我允许装什么？示例第 1 节：

示例第 1 节：

```elisp
(defclass account ()
  ((owner :initarg :owner :initform "匿名" :type string)
   (balance :initarg :balance :initform 0 :type number))
  "银行账户。")
(let ((a (account :owner "张三")))
  (princ (format "  只给 :owner，其余走默认值 → %S %S\n"
                 (slot-value a 'owner) (slot-value a 'balance))))
;; 没有 :initarg 的槽，构造时无法指定
(defclass no-key ()
  ((secret :initform 42 :type number))
  "演示无 initarg。")
(princ (format "  无 :initarg 的槽只能吃默认值 → %S\n"
               (slot-value (no-key) 'secret)))
;; 31.1 新行为：定义类时就校验 :initform 与 :type 是否匹配
(condition-case err
    (eval '(defclass bad-slot () ((n :initform "oops" :type number))))
  (error (princ (format "  initform 与 type 不符 → 定义期即报 %S\n"
                        (car err)))))
```

运行结果：

```
  只给 :owner，其余走默认值 → "张三" 0
  无 :initarg 的槽只能吃默认值 → 42
  initform 与 type 不符 → 定义期即报 invalid-slot-type
```

逐点读：

**`:initarg` 是构造时的「钥匙」。** 声明了 `:initarg :balance`，构造时才能写 `(account :balance 100)`；没声明 `:initarg` 的槽（如 `secret`）构造时根本传不进去，只能吃 `:initform` 默认值——之后想改仍可用 `setf`。这是控制「哪些属性允许在出生时被指定」的手段：内部缓存、派生状态一类的槽通常不开 initarg。还要注意 initarg 的关键字**不需要与槽同名**，写成 `:initarg :bal` 也合法，但同名是压倒性惯例。

**`:initform` 是默认值表达式。** 它在**每个实例构造时求值**（不是定义时求一次共享），所以写 `:initform (make-hash-table)` 是安全的——每个实例各得一张表。完全不写 `:initform` 的槽处于**未绑定**状态，读它会触发 `slot-unbound`（第 51 章细讲）。

**`:type` 是 CL 类型说明符，且 31.1 在定义期就校验。** 这是与老手册最大的行为差异：`(defclass bad-slot () ((n :initform "oops" :type number)))` 这个定义本身就会抛 `invalid-slot-type`——字符串 `"oops"` 不满足 `number` 约束，等不到构造实例。`:type` 接受任意 CL 类型说明符（`integer`、`(or null string)`、`(member a b)` 等），不写时默认为 `t`（一切皆可）。校验发生在两个时刻：**定义期**校验 `:initform`，**运行期**校验每次构造赋值与 `setf`。

## 50.2 文档与访问器：`:accessor`、`:reader`、`:writer`

49 章用 `slot-value` 读写槽，但业务代码里更常见的写法是**访问器**：`defclass` 可以为槽生成一个与外部世界约定的函数名。`:accessor` 生成读写两用函数；`:reader` 与 `:writer` 把它拆成只读、只写两半。示例第 2 节：

示例第 2 节：

```elisp
(defclass config-item ()
  ((key :initarg :key :initform "unnamed" :type string
        :accessor cfg-key
        :documentation "键名。")
   (value :initarg :value :initform 0 :type number
          :reader cfg-value :writer cfg-set-value))
  "配置项。")
(let ((o (config-item :key "width" :value 80)))
  (setf (cfg-key o) "height")          ; accessor 可 setf
  (cfg-set-value o 88)                 ; writer 只负责写
  (princ (format "  accessor 读回 %S；reader 读回 %S\n"
                 (cfg-key o) (cfg-value o))))
;; reader-only 的槽没有 setf 方法，setf 相当于调用不存在的
;; (setf cfg-value) 函数
(defvar tmp-cfg (config-item)
  "reader-only 演示用对象。")
(condition-case err
    (eval '(setf (cfg-value tmp-cfg) 99))
  (error (princ (format "  对 reader-only 槽 setf → %S\n" (car err)))))
```

运行结果：

```
  accessor 读回 "height"；reader 读回 88
  对 reader-only 槽 setf → void-function
```

逐点读：

**三种访问器的分工。** `:accessor cfg-key` 等价于同时声明 `:reader cfg-key` 和 `:writer (setf cfg-key)`——`(cfg-key o)` 读、`(setf (cfg-key o) v)` 写。只给 `:reader` 时，读函数存在而 `(setf 读函数)` 不存在，对它 `setf` 会报 `void-function`（试图调用不存在的 `(setf cfg-value)`）。想表达「对外只读、内部可改」就用 `:reader` 加内部 `slot-value`。

**访问器是函数，不是宏。** 它是普通的 `defun`（带编译器声明），可以 `funcall`、`apply`，可以做方法的特化目标之外的一切函数能做的事。与 `slot-value` 相比它有两个优势：**快**（编译期解析成定址访问，不做运行期按名查找）和**早错**（写错函数名字节编译期就报警告，不像槽名写错要等运行期）。代价是函数名占全局命名空间——务必带包前缀（`cfg-`），别生成 `key`、`value` 这种一撞一个准的名字。

**文档字符串与访问器一起进帮助系统。** 槽的 `:documentation` 会成为访问器函数的文档的一部分；`M-x customize-group` 风格的对象定制界面（54 章的 `customize-object`）也靠它渲染说明。

## 50.3 定制选项：`:custom`、`:label`、`:group`

这三个选项不参与任何运行期行为，它们是给 **customize 界面**看的元数据：`:custom` 指定定制控件的类型（`string`、`number`、`color` 等 widget 类型），`:label` 是显示名，`:group` 指明归属哪个定制组。它们被收进**槽描述符**的 props 里。示例第 3 节：

示例第 3 节：

```elisp
(defclass ui-field ()
  ((title :initarg :title :initform "无题" :type string
          :custom string :label "标题" :group eieio))
  "带定制信息的槽。")
(princ (format "  title 的槽描述符 → %S\n"
               (car (eieio-class-slots 'ui-field))))
```

运行结果：

```
  title 的槽描述符 → #s(cl-slot-descriptor title "无题" string ((:custom . string) (:label . "标题") (:group eieio)))
```

逐点读：

**槽描述符是 31.1 内省的入口。** `(eieio-class-slots '类名)` 返回 `cl-slot-descriptor` 结构的**列表**（注意：不是老手册时代的向量），每个描述符里能看到槽名、initform、类型和 props。上例 props 里正是 `((:custom . string) (:label . "标题") (:group eieio))`。第 54 章会系统讲内省函数族。

**不写这些选项会怎样。** 什么都不影响——它们是纯元数据。写它的唯一场景是：你的类会被 `M-x customize-object`（54 章）打开做图形化编辑。EIEIO 自己的类全都写了，这也是它们能在 customize 界面里排得整整齐齐的原因。

## 50.4 `:printer` 与 `object-write`

`object-write` 是 EIEIO 的对象序列化器：把对象以「可 `read` 回来的构造函数形式」写到 `standard-output`。槽选项 `:printer` 接受一个**单参数函数**，序列化到这个槽时对它调用 `(funcall printer 槽值)`，函数自己负责把文本 `princ` 到 `standard-output`（返回值被忽略）。示例第 4 节：

示例第 4 节：

```elisp
(defclass stamped ()
  ((label :initarg :label :initform "无" :type string)
   (year :initarg :year :initform 1970 :type number
         :printer (lambda (v) (princ (format "「%d年」" v))))
   (cache :initform nil))
  "带自定义打印的类。")
;; object-write 只写「有 :initarg 且当前值 ≠ initform」的
;; 槽；eieio-print-object-name 绑 nil 则不写名字行
(let ((eieio-print-object-name nil))
  (princ "  object-write 输出：")
  (object-write (stamped :label "纪念" :year 2024)))
;; year 保持默认 1970 与无 :initarg 的 cache 都不会写出
(let ((eieio-print-object-name nil))
  (princ "  默认值槽被跳过：  ")
  (object-write (stamped :label "纪念")))
```

运行结果：

```
  object-write 输出：(stamped  :label "纪念"  :year 「2024年」)
  默认值槽被跳过：  (stamped  :label "纪念")
```

逐点读：

**`object-write` 的输出是「重构指令」而非数据快照。** 它写的是 `(stamped :label "纪念" :year …)` 这样的构造函数调用形式——理论上把这段文本 `eval` 就能重建对象。注意它**只写两类槽**：声明了 `:initarg` 的槽，且当前值**不等于** `:initform` 的槽。第二条输出里 `year` 保持默认 1970 就被整个跳过，`cache` 没有 initarg 也从不出现。这意味着 `object-write` 不是完备的持久化方案——它是 `eieio-persistent`（53 章）的底层零件，真正的存档要走 `eieio-persistent-save`。

**`:printer` 的职责边界很窄。** 它只影响 `object-write` 这一路输出；`%S` 打印、调试器里的显示都不经过它。函数体里直接 `princ`，不要返回字符串——返回值会被丢弃。上例把 `2024` 打成 `「2024年」` 只是演示；实务用途是把不适合按字面写出的值（哈希表、buffer 引用）转成某种可重建记号。

**变量 `eieio-print-object-name` 控制是否写对象名行。** 绑 `nil` 时输出纯净的重构指令；默认 `t` 时会先写一行 `;; Object 名字` 注释（53 章的持久化文件里能看到这行）。

## 50.5 `:allocation :class`：全类共享一份

默认的槽是**实例槽**：每个对象一份存储。加 `:allocation :class` 后变成**类槽**：全类（含子类）共享同一份存储，从任何一个实例写，其他实例都能读到。示例第 5 节：

示例第 5 节：

```elisp
(defclass counted ()
  ((name :initarg :name :initform "x" :type string)
   (total :allocation :class :initform 0 :type number))
  "带类槽的类。")
(let ((a (counted :name "甲"))
      (b (counted :name "乙")))
  (setf (slot-value a 'total) 5)
  (princ (format "  从 a 写入 5，从 b 读到 → %S\n"
                 (slot-value b 'total))))
```

运行结果：

```
  从 a 写入 5，从 b 读到 → 5
```

逐点读：

**类槽的典型用途：计数器、注册表、默认值仓库。** 上例从实例 `a` 写入 5，实例 `b` 立刻读到 5——它们背后是同一格存储。「全类共享」的范围包括**子类的实例**：`counted` 的子类实例读写 `total` 看到的也是这一份（子类可以用同名类槽遮蔽，但那会另开一份）。

**类槽的读写另有一对专用入口：`oref-default` 与 `oset-default`。** `(oref-default 'counted total)` 不需要任何实例，直接对类读写（第 51 章演示）。注意一条字节编译坑：`oref-default`/`oset-default` 用在**非类槽**上能跑（退回读 initform），但字节编译器会报 `not class-allocated` 警告——`run-all.sh` 视警告为失败，所以这对函数务必只用于真正的类槽。

## 50.6 `:protection` 与 `:allow-nil-initform` 的现状

老手册把 `:protection` 描述成访问控制（`:protected` 只允许类方法内访问、`:private` 更严）。**31.1 已完全不强制执行**：它只是留在槽描述符里的文档标记。`:allow-nil-initform` 则是真实生效的**类级选项**，但语义比名字暗示的窄。示例第 6 节：

示例第 6 节：

```elisp
;; 老手册说 :protection :protected/:private 会限制外部访
;; 问；31.1 已不再强制，只当文档用
(defclass legacy ()
  ((priv :initarg :priv :initform 42 :type number
         :protection :protected))
  "老代码遗留写法。")
(princ (format "  :protection 槽仍可外部直读 → %S\n"
               (slot-value (legacy) 'priv)))
;; :allow-nil-initform 只豁免“定义期”对 nil 默认值的类
;; 型检查；注意类选项是平铺写法，不要加括号
(defclass maybe-name ()
  ((nick :initarg :nick :initform nil :type string))
  "允许 nil 默认值。"
  :allow-nil-initform t)
(princ (format "  nil initform + :allow-nil-initform → 默认 %S\n"
               (slot-value (maybe-name) 'nick)))
;; 但运行期给 nil 仍受 :type 约束
(let ((sig (condition-case err
               (progn (maybe-name :nick nil) nil)
             (error (car err)))))
  (princ (format "  构造时显式给 nil → %S（string 类型不含 nil）\n" sig)))
;; 真要让槽接受 nil，把类型写成 (or null string)
(defclass maybe-name2 ()
  ((nick :initarg :nick :initform nil :type (or null string)))
  "类型层面允许 nil。")
(princ (format "  :type (or null string) 给 nil → %S\n"
               (slot-value (maybe-name2 :nick nil) 'nick)))
```

运行结果：

```
  :protection 槽仍可外部直读 → 42
  nil initform + :allow-nil-initform → 默认 nil
  构造时显式给 nil → invalid-slot-type（string 类型不含 nil）
  :type (or null string) 给 nil → nil
```

逐点读：

**别指望 `:protection` 保护任何东西。** 输出第一行证明外部代码照常直读 `:protected` 槽。Elisp 生态的约定是靠**命名纪律**（内部槽名加 `--` 前缀或文档注明）而非语言级访问控制——这与包系统里双横线表示内部函数是同一哲学。

**`:allow-nil-initform` 只豁免「定义期」校验。** 没有它时，`(nick :initform nil :type string)` 这个**定义**就会报 `invalid-slot-type`（nil 不满足 string）；加了之后定义能过，默认值为 nil。但它**管不到运行期**：构造时显式传 `(maybe-name :nick nil)` 仍报 `invalid-slot-type`。所以它的正确用途只有一个：「允许这个槽暂时为空出生，但之后赋值必须是 string」。

**想让槽真正可空，把类型写对。** `:type (or null string)` 才是正解——定义期、运行期都接受 nil。另外注意类选项的写法是**平铺**在文档字符串之后：`:allow-nil-initform t`，**不要加括号**（写成 `(:allow-nil-initform t)` 会被当成未知选项处理）。

## 50.7 继承规则：覆写默认值、`:type` 不可改、多继承顺序

子类可以**重声明父类已有的槽**：改 `:initform`、改文档、加访问器——都合法。唯独**`:type` 不许改**，定义期直接报错。多继承出现同名槽时，排在前面的父类获胜。示例第 7 节：

示例第 7 节：

```elisp
(defclass shape ()
  ((color :initarg :color :initform "黑" :type string
          :documentation "颜色。"))
  "图形。")
(defclass red-shape (shape)
  ((color :initform "红" :documentation "覆写后的颜色。"))
  "红色图形。")
(princ (format "  子类覆写 initform → %S\n"
               (slot-value (red-shape) 'color)))
;; 改 :type 会在定义期直接报错
(condition-case err
    (eval '(defclass bad-shape (shape)
             ((color :initform 1 :type number))
             "改类型的子类。"))
  (error (princ (format "  改父类槽的 :type → %s\n" (cadr err)))))
;; 多继承出现同名槽时，排在前面的父类获胜
(defclass left () ((tag :initform "左" :type string)) "左。")
(defclass right () ((tag :initform "右" :type string)) "右。")
(defclass both (left right) () "多继承。")
(princ (format "  (both left right) 同名槽取前位父类 → %S\n"
               (slot-value (both) 'tag)))
```

运行结果：

```
  子类覆写 initform → "红"
  改父类槽的 :type → Child slot type ‘number’ does not match inherited type ‘string’ for ‘color’
  (both left right) 同名槽取前位父类 → "左"
```

逐点读：

**覆写是「重新声明同名槽」。** `red-shape` 把 `color` 的默认值从「黑」改成「红」，只写差异项即可，`:initarg`、`:type` 都从父类继承。这是模板方法模式的基础：父类定骨架，子类调默认。

**`:type` 收窄或放宽都被拒。** 报错消息很明确：子槽类型 `number` 与继承来的类型 `string` 不符。这条约束保证了「凡是父类实例出现的地方换子类实例，槽的类型承诺不变」——里氏替换原则在类型层面的落实。

**多继承同名槽：前位父类赢。** `(defclass both (left right) …)` 里 `tag` 取 `left` 的「左」。这不是就近原则，而是类线性化（C3 算法）的自然结果：`both → left → right`，`left` 在线性化序列里靠前。同名槽的 initform、type、accessor 全部从前位父类继承；想取 `right` 的版本只能显式重声明。方法派发同样沿这条线性化链走（52 章详述）。

## 50.8 类选项：`:abstract`、自定义 tag、被忽略的选项

类选项写在文档字符串**之后**，平铺排列。手册定义的类选项里真正还生效的是 `:abstract`；你还可以挂**任意自定义 tag**（EIEIO 用它们存类级元数据）；而老手册的 `:metaclass`、`:default-initargs` 已被静默忽略。示例第 8 节：

示例第 8 节：

```elisp
;; :abstract t 声明抽象类：只能被继承，不能被实例化
(defclass widget-base ()
  ((x :initarg :x :initform 0 :type number))
  "抽象基类。"
  :abstract t)
(princ (format "  实例化抽象类 → %s\n"
               (condition-case err (progn (widget-base) "没拦住")
                 (error (cadr err)))))
;; 除预定义选项外还能挂任意自定义 tag；读回要用内部函数
;; eieio--class-option（老的公开函数 class-option 已被删
;; 除）
(defclass tagged ()
  ((x :initarg :x :initform 0 :type number))
  "带自定义 tag。"
  :domain "demo")
(princ (format "  自定义类选项读回 → %S\n"
               (eieio--class-option (find-class 'tagged) :domain)))
;; 老手册里的 :metaclass 与 :default-initargs：31.1 不报
;; 错，但会被静默忽略
(defclass old-style ()
  ((x :initarg :x :type number))
  "老写法。"
  :default-initargs (:x 99)
  :metaclass standard-class)
(princ (format "  :default-initargs 生效？x 绑定 → %S\n"
               (slot-boundp (old-style) 'x)))
(princ (format "  :metaclass 生效？类对象仍是 → %S\n"
               (type-of (find-class 'old-style))))
```

运行结果：

```
  实例化抽象类 → Class widget-base is abstract
  自定义类选项读回 → "demo"
  :default-initargs 生效？x 绑定 → nil
  :metaclass 生效？类对象仍是 → eieio--class
```

逐点读：

**`:abstract t` 声明抽象类。** 抽象类只能被继承、不能被实例化，直接构造报 `Class widget-base is abstract`。用途：接口骨架（定义公共槽与方法签名，强制走子类）。EIEIO 预定义基类里的 `eieio-instance-tracker` 等就是这么设计的（53 章）。

**自定义 tag 是类级扩展点。** `:domain "demo"` 这种陌生选项不会被拒绝，而是存进类对象——这是框架作者留元数据的钩子（比如 ORM 记录表名）。读取用内部函数 `(eieio--class-option (find-class 'tagged) :domain)`；老手册里的公开函数 `class-option` 已从 31.1 删除（`fboundp` 返回 nil，54 章的废弃清单里再确认一次）。

**`:default-initargs` 与 `:metaclass` 是历史残留。** CLOS 的 `:default-initargs` 本是「类级默认构造参数」，`:metaclass` 本是「用哪个元类来解释这个类」。31.1 实测：前者**不生效**（`x` 仍是未绑定），后者**不生效**（类对象类型仍是固定的 `eieio--class`）。都不报错——静默忽略比报错更危险，迁移老代码时如果行为对不上，先查是不是踩了这两个选项。

## 50.9 小结：一张表

| 选项 | 作用域 | 一句话备忘 |
| --- | --- | --- |
| `:initarg` | 槽 | 构造时的关键字；不开则构造期无法指定 |
| `:initform` | 槽 | 默认值表达式，每实例构造时求值；不写则槽未绑定 |
| `:type` | 槽 | CL 类型说明符；31.1 定义期校验 initform，运行期校验每次赋值 |
| `:documentation` | 槽/类 | 进帮助系统与 customize 界面 |
| `:accessor` / `:reader` / `:writer` | 槽 | 生成访问器函数（记得带包前缀）；reader-only 的 setf 报 void-function |
| `:custom` / `:label` / `:group` | 槽 | customize 界面元数据，存进槽描述符 props |
| `:printer` | 槽 | object-write 时的自定义打印，函数自己 princ、返回值被忽略 |
| `:allocation :class` | 槽 | 全类共享一份；配套 oref-default/oset-default |
| `:protection` | 槽 | 31.1 不再强制，纯文档标记 |
| `:allow-nil-initform` | 类 | 只豁免定义期 nil 校验；真可空用 `:type (or null …)` |
| `:abstract` | 类 | 抽象类不可实例化 |
| 自定义 tag | 类 | 任意键值存进类对象，用 eieio--class-option 读（class-option 已删） |
| `:metaclass` / `:default-initargs` | 类 | 31.1 静默忽略，老代码迁移重点排查 |

`defclass` 的全部选项到此讲完。下一章换个视角：不看点定义，看**访问**——`slot-value` 家族的全貌、未绑定槽的三种处理、运行期类型校验的边界，以及 `with-slots`、`object-add-to-list` 这些便利宏。

上一章：[49 · EIEIO 快速上手：defclass、构造、泛型与方法](49-eieio-quickstart.md)　｜　下一章：[51 · 槽与访问：slot-value、oref 与绑定状态](51-eieio-slots.md)　｜　返回：[Emacs 扩展开发指南](README.md)
