# 49 · EIEIO 快速上手：defclass、构造、泛型与方法

> 所属部分：第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

> 示例：`examples/49-eieio-quickstart.el`

从这一部分起，我们跟随 GNU 官方的《EIEIO 手册》（`https://www.gnu.org/software/emacs/manual/html_mono/eieio.html`）把 Emacs 内置的面向对象层系统讲一遍。**EIEIO**（Enhanced Implementation of Emacs Interpreted Objects）是 Emacs 自带的 OO 设施，语法仿 Common Lisp 的 CLOS：用 `defclass` 定义类、用泛型函数加方法实现多态、支持单继承与多继承。自 Emacs 25 起，EIEIO 不再是一套独立的类型系统，而是**建立在 `cl-defstruct` 与 `cl-generic` 之上**——这个历史决定了今天的正确写法：定义类用 `defclass`（EIEIO 自己的宏），而声明泛型、写方法要用 **cl-lib 的 `cl-defgeneric` / `cl-defmethod`**。手册里还能见到的旧名字 `defgeneric` / `defmethod` 如今只是过时别名，新代码不要再用。

本部分共六章，对应手册的全部核心内容：本章（快速上手，对应手册的 Introduction 与 Quick Start）用一个最小例子走完全流程；第 50 章讲 `defclass` 的全部选项（手册的 Defining Classes）；第 51 章讲槽的读写与内省（Accessing Slots）；第 52 章讲方法的定义、限定符与调用规则（Writing Methods、Method Invocation）；第 53 章讲 EIEIO 自带的五个预定义基类（Base Classes）；第 54 章讲内省、交互工具与废弃清单（Introspection、eieio-opt、 obsolete 功能）。手册原文举的例子有不少是 Emacs 23 时代的写法，这里全部**提炼、重写并升级到 Emacs 31.1**，每章照旧配一个可验证的示例，所有输出都是 31.1 实测所得。

开工前先亮三个**实测才看得清**的事实，它们会贯穿整个部分：其一，31.1 里对象的打印形态是 **record 语法** `#s(person "张三" 30)`——可以 `read` 回来，与 `cl-defstruct` 结构的打印形式一脉相承（EIEIO 的类底层就是结构）；其二，`defclass` 自动生成的谓词 `类名-p` **只认恰好是本类的实例**，不认子类实例——想表达「是 person 或其子类」要用 `cl-typep` 或 `object-of-class-p`；其三，方法派发是 CLOS 式的**按参数类型分派**，给泛型传一个没有匹配方法的实参，会抛 `cl-no-applicable-method` 信号。每条都在下文附真实输出。

## 49.1 `defclass`：一次定义三样东西

手册 Quick Start 的第一个例子就是定义一个 `person` 类。`defclass` 的骨架是：

```elisp
(defclass 类名 (父类...)
  ((槽名 :initarg :关键字
         :initform 默认值
         :type 类型
         :documentation "说明")
   ...)
  "类的文档字符串。")
```

父类列表留空 `()` 表示单继承自默认基类（`eieio-default-superclass`，第 53 章细讲）。每个槽至少要有三样东西：**`:initarg`** 是构造时传值用的关键字参数名，**`:initform`** 是不传时的默认值，**`:type`** 是类型约束（定义期会校验 `:initform` 合不合法，运行期会校验每次赋值，第 50、51 章细讲）。示例第 1 节定义一个最小的 `person`：

示例第 1 节：

```elisp
(defclass person ()
  ((name :initarg :name :initform "无名氏" :type string
         :documentation "姓名")
   (age :initarg :age :initform 0 :type number
        :documentation "年龄"))
  "人类。")
(princ "  定义即得三样东西：构造函数 person、谓词 person-p、类对象。\n")
(princ (format "  构造函数已定义 → %S；谓词已定义 → %S\n"
               (fboundp 'person) (fboundp 'person-p)))
(princ (format "  (find-class 'person) 找到类对象 → %S\n"
               (not (null (find-class 'person)))))
```

运行结果：

```
  定义即得三样东西：构造函数 person、谓词 person-p、类对象。
  构造函数已定义 → t；谓词已定义 → t
  (find-class 'person) 找到类对象 → t
```

逐点读：

**一次 `defclass` 生成三样东西。** 第一，一个与类同名的**构造函数** `person`——它不是普通函数那么简单，背后挂着编译器宏（见 49.2 的向后兼容注记）；第二，一个**谓词** `person-p`；第三，一个**类对象**，用 `(find-class 'person)` 能取到。这与 `cl-defstruct` 的「一次定义出一窝函数」风格一致，区别是构造函数与类同名、谓词只生成一个。

**类名同时是类型名。** `defclass` 之后，`person` 这个符号在三个意义上成立：它是构造函数名、是类名（`find-class` 的键）、还是 CL 类型说明符（`cl-typep` 认识它，49.6 会用到）。给槽起名要避免与构造函数撞车：槽名 `name`、构造函数 `person` 互不干扰，但如果类叫 `name` 就麻烦了——实务上类名取得「大」一点、槽名取得「小」一点。

**文档字符串不是摆设。** 类文档和槽的 `:documentation` 都会进入帮助系统：交互下 `C-h f person` 能看到类文档与全部槽说明（这正是 54 章 `eieio-help-constructor` 做的事）。写扩展时把 `:documentation` 填上，等于白捡一份构造参数文档。

## 49.2 构造对象：构造函数与 `make-instance`

构造一个实例有两种等价写法：直接调构造函数 `(person :name "张三" :age 30)`，或者调通用入口 `(make-instance 'person :name "李四")`。两者都按「`:initarg` 关键字 + 值」成对传参；没传的关键字用 `:initform` 兜底。示例第 2 节把三种典型情形都构造出来并原样打印：

示例第 2 节：

```elisp
(let ((a (person :name "张三" :age 30))
      (b (person))                       ; 全部用 :initform 默认值
      (c (make-instance 'person :name "李四"))) ; make-instance 等价写法
  ;; 31.1 里对象的 prin1 形态是记录语法 #s(类名 槽值...)
  (princ (format "  (person :name \"张三\" :age 30) → %S\n" a))
  (princ (format "  (person) 全默认               → %S\n" b))
  (princ (format "  make-instance 等价构造        → %S\n" c)))
```

运行结果：

```
  (person :name "张三" :age 30) → #s(person "张三" 30)
  (person) 全默认               → #s(person "无名氏" 0)
  make-instance 等价构造        → #s(person "李四" 0)
```

逐点读：

**对象的打印形态是 `#s(类名 槽值…)`。** 这是 record（记录）的读取语法：井号 `s` 加一对括号，第一个元素是类型标签（类名），后面按**槽定义顺序**列出各槽的值。因为它同时是「读」语法，`(read-from-string "#s(person \"张三\" 30)")` 能把这个对象原样读回来——这一点与第 48 章讲的 `cl-defstruct` 结构完全一致，因为 EIEIO 的实例底层就是结构体。注意 `#s` 形式里**没有槽名**，只按位置对号；想打印带槽名的形式要用 `object-write`（第 50 章）或 `cl-prin1-to-string`（第 52 章）。

**两种构造入口怎么选。** 写具体类时用同名构造函数，短而明确；写「类名是运行期才知道」的通用代码时用 `make-instance`。有一条 31.1 的实测约束：`make-instance` 的**第一个实参必须是类符号**——`(make-instance (find-class 'person))` 传类对象会抛 `cl-no-applicable-method`（`make-instance` 本身是个泛型，只对符号特化了方法）。第 52 章还会看到用 `(subclass 类)` 特化符把 `make-instance` 扩展成「类方法」的技巧。

**旧式裸名构造已过时。** 手册和老代码里能见到 `(person "张三")` 这种把第一个位置实参当名字的写法（那是 EIEIO 自己一套构造协议的遗迹）。31.1 里它仍被变量 `eieio-backward-compatibility`（默认值 `'warn`）容忍：运行期会向 `message` 发一条警告，而且构造函数挂的**编译器宏在编译期无条件报** `Obsolete name argument "张三" to constructor person`。换句话说，这种写法在任何正经工程里都过不了字节编译这一关——本教程只在此说明它的存在，示例一律用关键字形式。

## 49.3 三个谓词：`类名-p`、`eieio-object-p`、`class-p`

定义类之后，最常写的三种判定是：「这是不是 person 的实例」「这是不是任何一个 EIEIO 对象」「这个符号是不是一个类」。示例第 3 节把三个谓词各试正反两例：

示例第 3 节：

```elisp
(let ((p (person)))
  (princ (format "  person-p 认实例、拒杂项：%S / %S\n"
                 (person-p p) (person-p 42)))
  (princ (format "  eieio-object-p 认一切 EIEIO 对象：%S / %S\n"
                 (eieio-object-p p) (eieio-object-p "x")))
  (princ (format "  class-p 认类符号：%S / %S\n"
                 (class-p 'person) (class-p 'nosuch))))
```

运行结果：

```
  person-p 认实例、拒杂项：t / nil
  eieio-object-p 认一切 EIEIO 对象：t / nil
  class-p 认类符号：t / nil
```

逐点读：

**三个谓词管三个层次。** `person-p` 管「实例→本类」，`eieio-object-p` 管「实例→任何类」（凡是 EIEIO 造出来的对象都认），`class-p` 管「符号→类」（对符号求值其类定义存在与否）。日常代码里 `类名-p` 用得最多，写通用工具（序列化器、检查器）时用 `eieio-object-p`，写元编程时用 `class-p`。

**`类名-p` 只认「恰好是本类」。** 输出里 `person-p` 对 `person` 实例为 `t`，但这层语义有个容易踩的坑：它**不认子类的实例**——内部实现是 `same-class-p`（严格同型）。49.6 会演示：对 `employee`（person 的子类）实例调 `person-p` 返回 `nil`。要表达「is-a person（含子类）」请用 `(cl-typep obj 'person)` 或 `(object-of-class-p obj 'person)`。另外手册时代还存在一族 `类名-child-p` 谓词，自 Emacs 25.1 起已过时，31.1 里虽然还在（带过时警告），新代码不要碰。

## 49.4 读写槽：`slot-value` 是广义变量

读槽用 `slot-value`，写槽用 `setf`——`slot-value` 是一个**广义变量**（generalized variable，第 44 章讲过这套机制），所以可以原地 `setf`、`incf`、`push`。示例第 4 节：

示例第 4 节：

```elisp
(let ((p (person :name "王五" :age 25)))
  (princ (format "  slot-value 读 → %S %S\n"
                 (slot-value p 'name) (slot-value p 'age)))
  (setf (slot-value p 'age) 26)          ; setf 直接写
  (princ (format "  setf 写后     → %S %S\n"
                 (slot-value p 'name) (slot-value p 'age))))
```

运行结果：

```
  slot-value 读 → "王五" 25
  setf 写后     → "王五" 26
```

逐点读：

**`slot-value` 是最通用的访问入口。** 它按**槽名（符号）**动态查找：`(slot-value p 'name)` 里槽名是个普通实参，所以槽名可以来自变量、来自运行期计算——这是它与访问器（accessor）的本质区别。代价是动态查找比访问器慢，且槽名写错要等运行期才报 `Invalid slot name`。

**`setf` 直接写，类型校验在运行期执行。** 写 `(setf (slot-value p 'age) "abc")` 会因为 `:type number` 约束在赋值瞬间抛 `wrong-type-argument`（第 51 章演示）。这套「广义变量 + 校验」的组合意味着你完全可以把槽当作普通变量用：`push`、`incf`、`cl-incf` 都合法。

**还有两个你会在源码里频繁遇到的名字：`oref` 与 `oset`。** `(oref p age)` 等价于 `(slot-value p 'age)`，`(oset p age 26)` 等价于 setf 写法——它们没有过时，但也不是「新风格」，只是更短。注意 `oref` 的槽名是**不求值**的（写 `age` 不写 `'age`），混用时看清引号。本教程正文统一用 `slot-value`/`setf` 讲概念，示例里两处都有出现，第 51 章对照讲。

## 49.5 `cl-defgeneric` 与 `cl-defmethod`：现代写法

EIEIO 的多态靠 CLOS 式**泛型函数**：先（可选地）用 `cl-defgeneric` 声明一个泛型及其文档，再用 `cl-defmethod` 按「特化」逐个写方法。特化写法是把参数从 `who` 换成 `(who person)`——读作「第一个实参必须是 `person` 或其子类的实例，方法体内绑到 `who`」。示例第 5 节给 `person` 写一个自我介绍方法：

示例第 5 节：

```elisp
;; 先声明泛型（可选但推荐），再按「特化」写方法
(cl-defgeneric introduce (who)
  "自我介绍。")
(cl-defmethod introduce ((who person))
  (format "我是%s，%d岁。"
          (slot-value who 'name) (slot-value who 'age)))
(princ (format "  对 person 实例调用 → %s\n"
               (introduce (person :name "赵六" :age 40))))
;; 特化写法 (who person)：第一个参数必须是 person 或其子类的实例
```

运行结果：

```
  对 person 实例调用 → 我是赵六，40岁。
```

逐点读：

**为什么用 `cl-` 前缀的名字。** Emacs 25 把 EIEIO 的方法系统换成了 `cl-generic`（cl-lib 的泛型设施），`defgeneric`/`defmethod` 从那时起成为过时别名，31.1 里仍可用但字节编译会提示。新代码一律写 `cl-defgeneric`/`cl-defmethod`——这不只是改个前缀：cl-generic 的特化符（`(eql 值)`、`(subclass 类)`、`(head 值)` 等）全部可用，EIEIO 的类名只是其中一种类型说明符。

**`cl-defgeneric` 声明是可选的，但值得写。** 你只写 `cl-defmethod` 也能工作（第一次定义方法时隐式创建泛型）。显式声明的好处：文档字符串集中在一处、`M-x describe-function` 能看到完整的参数列表与方法列表、还能在声明里写 `(:method-combination …)` 等泛型级选项。普通参数（不带特化的）照写原名即可，比如 `(cl-defgeneric greet (who &optional loudly))`。

**派发只看「特化了的」那些参数。** 上例只对第一个参数特化；CLOS 允许对任意多个参数特化（多派发），cl-generic 同样支持。没特化的参数不参与选方法。派发的完整规则（限定符、`cl-call-next-method`、多继承下的顺序）是第 52 章的主题，本章先把「按类型选方法」这件事跑通。

## 49.6 继承、覆写与 `cl-call-next-method`

继承写在 `defclass` 的第二个位置——父类列表。子类自动获得父类的全部槽与方法，可以再加自己的槽、覆写父类的方法；覆写时用 `cl-call-next-method` 调「下一个更一般的方法」（通常是父类版本）并拼上自己的增量。示例第 6 节定义 `employee` 继承 `person`，并在 `introduce` 里追加部门信息：

示例第 6 节：

```elisp
(defclass employee (person)
  ((dept :initarg :dept :initform "研发" :type string))
  "雇员。")
(cl-defmethod introduce ((who employee))
  (format "%s我在%s部门。" (cl-call-next-method) (slot-value who 'dept)))
(let ((e (employee :name "小明" :age 28 :dept "平台")))
  (princ (format "  employee 实例 → %s\n" (introduce e)))
  ;; 注意：person-p 只认“恰好是 person”的实例，不认子类实例
  (princ (format "  person-p 只认本类，对子类实例 → %S\n" (person-p e)))
  ;; 判断“是不是 person 或其子类”要用 cl-typep 或 object-of-class-p
  (princ (format "  cl-typep 认子类         → %S\n" (cl-typep e 'person)))
  (princ (format "  object-of-class-p 认子类 → %S\n" (object-of-class-p e 'person))))
```

运行结果：

```
  employee 实例 → 我是小明，28岁。我在平台部门。
  person-p 只认本类，对子类实例 → nil
  cl-typep 认子类         → t
  object-of-class-p 认子类 → t
```

逐点读：

**构造子类实例时，父类的 `:initarg` 一样能用。** `(employee :name "小明" :age 28 :dept "平台")` 里 `:name`、`:age` 来自 `person`、`:dept` 来自 `employee`，一次调用填三代槽——因为 EIEIO 的实例是一张平铺的槽表，继承只是「把父类槽定义合并进来」（合并规则与冲突仲裁见第 50 章）。

**覆写 + `cl-call-next-method` 是最常见的组合。** `employee` 的 `introduce` 先调 `cl-call-next-method` 拿到 `person` 版本的结果（`"我是小明，28岁。"`），再拼上自己的部门信息。`cl-call-next-method` 的语义是「沿方法链取下一个更一般的实现」：没有下一个时抛 `cl-no-next-method`（第 52 章演示）。它只能在方法体内调用。

**谓词陷阱在此兑现。** 输出后三行是本章开头预警的实测：`person-p` 对 `employee` 实例返回 `nil`——它只认恰好是 `person` 的对象；`(cl-typep e 'person)` 与 `(object-of-class-p e 'person)` 才是「is-a」判断，两者都返回 `t`。记住这个分工：**`类名-p` 做同型判断（反射、序列化场景用），`cl-typep`/`object-of-class-p` 做类型判断（业务逻辑用）**。

## 49.7 没有适用方法时：`cl-no-applicable-method`

泛型 `introduce` 只对 `person` 系有方法。给它一个数字会怎样？答案是抛 `cl-no-applicable-method` 信号。示例第 7 节用 `condition-case` 接住并打印信号名：

示例第 7 节：

```elisp
;; 泛型只对 person 有方法；给它一个数字，EIEIO 抛出
;; cl-no-applicable-method 信号，用 condition-case 接住看信号名
(let ((sig (condition-case err
               (progn (introduce 42) nil)
             (error (car err)))))
  (princ (format "  (introduce 42) 抛出信号 → %S\n" sig)))
```

运行结果：

```
  (introduce 42) 抛出信号 → cl-no-applicable-method
```

逐点读：

**这是 CLOS 与「消息传递式 OO」的差别。** 在 Java/Python 里调一个不存在的方法是编译期/属性查找错误；在 CLOS 里，泛型对一切实参都可调，只是「没有方法认领这个实参组合」时在运行期抛信号。信号名是 `cl-no-applicable-method`，可以用 `condition-case` 精确捕获——但更常见的做法是**给泛型写一个 `(x t)` 特化的兜底方法**（`t` 匹配一切类型），第 52 章演示这个惯用法。

**理论上还有第二条路：给 `cl-no-applicable-method` 这个泛型本身写方法。** CLOS 允许通过特化该泛型来自定义「无方法时」的行为。但 31.1 实测发现这条拦截路径**按类特化之外的写法不可行**：想用 `(eql #'introduce)` 精确匹配某个泛型时，运行时传进来的第一实参是内部的 `#s(cl--generic …)` 结构，与 `#'introduce` 包装函数并不相等，方法永远匹配不上。结论：拦截不可依赖，用 `t` 兜底。

## 49.8 小结：一张表

| 主题 | 函数 / 宏 | 一句话备忘 |
| --- | --- | --- |
| 定义类 | `defclass` | `(defclass 名 (父类) ((槽 :initarg :x :initform v :type t)) "文档")`；一次生成构造函数、谓词、类对象 |
| 构造 | `类名` / `make-instance` | 关键字传参；make-instance 首参必须是类符号；裸名构造已过时且编译期必警告 |
| 打印形态 | `#s(类名 槽值…)` | record 语法，可 `read` 回来；不带槽名，按定义顺序排 |
| 谓词 | `类名-p` / `eieio-object-p` / `class-p` | `类名-p` 只认本类；is-a 判断用 `cl-typep` 或 `object-of-class-p` |
| 读写槽 | `slot-value` + `setf`（或 `oref`/`oset`） | 广义变量；oref 的槽名不求值 |
| 泛型与方法 | `cl-defgeneric` / `cl-defmethod` | 特化写法 `((who person))`；旧的 defgeneric/defmethod 是过时别名 |
| 继承 | 父类列表 + `cl-call-next-method` | 子类实例可收父类 initarg；覆写时拼增量 |
| 无方法 | `cl-no-applicable-method` | 运行期信号；惯用法是写 `(x t)` 兜底方法 |

至此，EIEIO 的最小闭环——**定义类、造对象、读写槽、写方法、继承多态**——已经走完。但这个 `defclass` 只用了四个槽选项，手册为槽和类各准备了一整张选项表：`:accessor`、`:allocation :class`、`:protection`、`:printer`、抽象类……下一章把 `defclass` 的每个选项拆开讲清楚。

上一章：[48 · 类型与结构：cl-defstruct、cl-assert 与 cl-print](48-types-structs.md)　｜　下一章：[50 · defclass 详解：槽选项与类选项](50-eieio-defclass.md)　｜　返回：[Emacs 扩展开发指南](README.md)
