# 51 · 槽与访问：slot-value、oref 与绑定状态

> 所属部分：第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

> 示例：`examples/51-eieio-slots.el`

49 章讲了 `slot-value` 的基本读写，50 章把 `defclass` 的选项拆完，本章把视角切到「对象的日常操作」：构造参数的各种形态与错误信号、`oref`/`oset` 宏、槽的**绑定状态**（bound/unbound）、槽名与类型的两道运行期检查、类槽的默认值读写、`with-slots` 词法绑定、列表槽工具，以及 EIEIO 函数用在 `cl-defstruct` 结构上时的边界。这些正对应手册的 Accessing Slots 一章，外加 Constructing Objects 里 49 章没讲完的细节。

本章有三条 31.1 实测要点值得先记住：其一，槽的三个错误信号各有分工——**未知槽名**报 `invalid-slot-name`、**类型不符**报 `invalid-slot-type`、**读未绑定槽**报 `unbound-slot`，用 `condition-case` 可以精确区分；其二，`oref-default`/`oset-default` 用于非类槽会触发**字节编译警告**（`not class-allocated`），`run-all.sh` 判定标准下就是失败；其三，EIEIO 与 `cl-defstruct` 的互操作是**不对称的**——`slot-value` 通用，但 `slot-boundp`、`make-instance` 不认结构。

## 51.1 构造参数全景

构造一章的余下规则：initarg 传值、initform 兜底、未知关键字报错、`make-instance` 的实参约束。示例第 1 节把四种形态连错误一起演示：

示例第 1 节：

```elisp
(defclass emp ()
  ((name :initarg :name :initform "无名氏" :type string)
   (age :initarg :age :initform 0 :type number))
  "雇员。")
(princ (format "  给定 initarg        → %S\n"
               (emp :name "张三" :age 30)))
(princ (format "  缺省走 initform     → %S\n" (emp)))
;; 给了类里不存在的 initarg：运行期报 invalid-slot-name
(let ((sig (condition-case err
               (progn (emp :bogus 1) nil)
             (error (car err)))))
  (princ (format "  未知 initarg        → %S\n" sig)))
;; make-instance 与构造函数等价，但第一参数必须是「类符号」
(princ (format "  make-instance 类符号 → %S\n"
               (make-instance 'emp :name "李四")))
;; 传 find-class 返回的类对象不行：31.1 没有匹配它的方法
(let ((sig (condition-case err
               (progn (make-instance (find-class 'emp)) nil)
             (error (car err)))))
  (princ (format "  make-instance 类对象 → %S\n" sig)))
```

运行结果：

```
  给定 initarg        → #s(emp "张三" 30)
  缺省走 initform     → #s(emp "无名氏" 0)
  未知 initarg        → invalid-slot-name
  make-instance 类符号 → #s(emp "李四" 0)
  make-instance 类对象 → cl-no-applicable-method
```

逐点读：

**未知 initarg 与未知槽名是同一个信号。** `(emp :bogus 1)` 报 `invalid-slot-name`——构造器把 initarg 翻译成槽名，发现没有这个槽，报的错和「访问不存在的槽」一样（51.4 会看到）。这对排错很友好：搜一个信号名就能覆盖「构造传错参」和「访问写错名」两类笔误。

**`make-instance` 只认类符号。** 这是泛型派发决定的：`make-instance` 对符号特化了方法，对类对象（`find-class` 的返回值）没有方法，于是走到 `cl-no-applicable-method`。写元编程时记住转换方向：**符号 → 类对象用 `find-class`，类对象 → 符号用 `eieio-class-name`**（54 章演示）；给 `make-instance` 的永远是符号。

## 51.2 `slot-value` 与 `oref`/`oset`

`slot-value` 之外，源码里最常见的是 `oref`/`oset` 这对宏。它们没有过时，只是风格不同。示例第 2 节对照演示：

示例第 2 节：

```elisp
(let ((o (emp :name "王五" :age 25)))
  (princ (format "  slot-value 读 → %S %S\n"
                 (slot-value o 'name) (slot-value o 'age)))
  (setf (slot-value o 'age) 26)      ; slot-value 是广义变量
  (princ (format "  setf 写后     → %S %S\n"
                 (slot-value o 'name) (slot-value o 'age)))
  ;; oref/oset 是老式宏写法，31.1 依然可用（未废弃）；
  ;; 槽名不用加引号（宏自动 quote）
  (oset o age 27)
  (princ (format "  oref/oset 宏  → %S %S\n"
                 (oref o name) (oref o age))))
```

运行结果：

```
  slot-value 读 → "王五" 25
  setf 写后     → "王五" 26
  oref/oset 宏  → "王五" 27
```

逐点读：

**语法差异只有一处，但很关键：引号。** `(slot-value o 'age)` 的槽名是求值的实参，要加引号；`(oref o age)` 的槽名被宏自动 quote，**不能加引号**（写成 `(oref o 'age)` 等于找名叫 `quote` 的槽）。混用两套 API 时，一半的 `invalid-slot-name` 错误来自引号多写或少写。

**语义完全等价，选哪套看场景。** `oref` 展开后就是 `slot-value`，性能无差。槽名固定时用 `oref` 短；槽名来自变量时只能用 `slot-value`（宏 quote 会把变量名本身当槽名）。`oset` 等价于 `(setf (slot-value …) …)`；反过来 `(setf (oref o age) 27)` 也合法——`oref` 同样是广义变量。

**字节编译器会帮你查槽名。** 槽名字面量写错时，字节编译能提前报 `Unknown slot` 警告（这正是示例第 4 节要把槽名藏进变量才能演示错误的原因——见 51.4）。把警告当回事，它比运行期报错便宜得多。

## 51.3 绑定状态：`slot-boundp` 与 `slot-makeunbound`

槽不写 `:initform`、构造时又不给 initarg，就处于**未绑定**（unbound）状态——它连「值为 nil」都不是，而是「没有值」。示例第 3 节：

示例第 3 节：

```elisp
;; 没有 :initform 的槽，构造时没给 initarg 就处于「未绑定」
(defclass task ()
  ((title :initarg :title :initform "待办" :type string)
   (note :initarg :note :type string))
  "任务。")
(let ((o (task)))
  (princ (format "  未绑定槽 boundp   → %S\n" (slot-boundp o 'note)))
  (let ((sig (condition-case err
                 (progn (slot-value o 'note) nil)
               (error (car err)))))
    (princ (format "  读未绑定槽        → %S\n" sig)))
  (setf (slot-value o 'note) "周五前交")
  (princ (format "  赋值后 boundp     → %S\n" (slot-boundp o 'note)))
  (slot-makeunbound o 'note)
  (princ (format "  makeunbound 后    → %S\n" (slot-boundp o 'note))))
```

运行结果：

```
  未绑定槽 boundp   → nil
  读未绑定槽        → unbound-slot
  赋值后 boundp     → t
  makeunbound 后    → nil
```

逐点读：

**「未绑定」是与 nil 不同的第四种状态。** 一个 string 类型的槽可以装 `"x"`、可以按 `(or null string)` 装 `nil`、还可以**没装过任何东西**——读它就抛 `unbound-slot` 信号。`slot-boundp` 是唯一不触发信号的探针。这套机制是 CLOS 的标配，用途是区分「用户没填」与「用户填了空值」：表单对象里 `note` 未绑定表示「此栏未提交」，`nil` 表示「用户显式清空」。

**`slot-makeunbound` 把槽打回未绑定。** 赋过值的槽可以重新变成未绑定——「撤销赋值」的语义。53 章的 `eieio-instance-inheritor` 就靠它实现「槽未绑定时向父实例取值」的原型链继承。

**读未绑定槽其实是一次方法调用。** `unbound-slot` 信号由泛型 `slot-unbound` 抛出，你可以给自己的类写 `slot-unbound` 方法提供「懒求值」——读到未绑定槽时算一个值填回去再返回，而不是报错。53 章的 inheritor 正是这个钩子的教科书用法。

## 51.4 槽名检查：`slot-exists-p` 与 `invalid-slot-name`

反射代码（序列化器、通用检查器）需要先问「这个槽存不存在」再访问。`slot-exists-p` 就是干这个的，注意它的返回值不是 `t`。示例第 4 节：

示例第 4 节：

```elisp
;; slot-exists-p 返回槽的索引（真值）或 nil
(princ (format "  slot-exists-p → %S / %S\n"
               (slot-exists-p (task) 'title)
               (slot-exists-p (task) 'nosuch)))
;; 访问不存在的槽报 invalid-slot-name；槽名放进变量里，
;; 字节编译器就不会提前警告（演示错误时有用）
(let ((sn 'nosuch))
  (let ((sig (condition-case err
                 (progn (slot-value (task) sn) nil)
               (error (car err)))))
    (princ (format "  访问不存在槽  → %S\n" sig))))
```

运行结果：

```
  slot-exists-p → 1 / nil
  访问不存在槽  → invalid-slot-name
```

逐点读：

**返回值是索引，不是 `t`。** 存在时返回槽在实例里的数字索引（`title` 是第 1 个槽），不存在返回 `nil`。当真值用没问题，但别写 `(eq (slot-exists-p …) t)` 这种判断。

**`invalid-slot-name` 覆盖「查无此槽」的一切情形。** 构造传错 initarg、`slot-value` 写错名、`slot-boundp` 查错名，都是它。反射代码的正确顺序是：先 `slot-exists-p`，再决定走哪条路；直接 `condition-case` 捕信号也算惯用法，两条路都见到过。

**示例技巧顺带一说：** 要演示「访问不存在槽」这个错误，槽名必须藏进变量——写成字面量 `(slot-value o 'nosuch)` 时字节编译器会抢先报 `Unknown slot` 警告，等不到运行期。这是 31.1 编译器尽心尽力的又一例（50 章的定义期校验、本节的提前警告）。

## 51.5 运行期类型校验：`invalid-slot-type`

50 章见过 `:type` 在**定义期**校验 `:initform`；构造赋值与 `setf` 同样走校验。示例第 5 节两处都触发：

示例第 5 节：

```elisp
;; 50 章见过定义期校验；构造与 setf 时同样校验 :type
(let ((sig1 (condition-case err
                (progn (emp :age "三十") nil)
              (error (car err))))
      (sig2 (let ((o (emp :age 30)))
              (condition-case err
                  (progn (setf (slot-value o 'age) "三十") nil)
                (error (car err))))))
  (princ (format "  构造时类型不符 → %S\n" sig1))
  (princ (format "  setf 时类型不符 → %S\n" sig2)))
```

运行结果：

```
  构造时类型不符 → invalid-slot-type
  setf 时类型不符 → invalid-slot-type
```

逐点读：

**三个时刻，一个信号。** `:type` 的校验织在对象生命周期的三个时刻：定义期（initform 合法性）、构造期（initarg 值）、每次写入（setf/oset/访问器写）。三处都报 `invalid-slot-type`。这给了你「槽里的值永远满足 `:type`」的强保证——只要不走后门。

**后门是存在的：`eieio-oset` 之外的 C 层写入不算，真正的后门是「别声明 :type」。** 不写 `:type` 等价于 `:type t`，不校验。实务建议：对外暴露的槽一定写 `:type`，这是白捡的运行期断言；内部临时槽可以省略。

## 51.6 类槽默认值：`oref-default` 与 `oset-default`

50 章讲了 `:allocation :class` 的类槽全类共享。配套的问题是：**没有实例时怎么读写类槽？** 答案是 `oref-default`/`oset-default`——它们以类符号为操作对象。示例第 6 节：

示例第 6 节：

```elisp
;; oref-default/oset-default 读写类槽的「默认值」；字节编
;; 译器要求槽必须是 :allocation :class（实例槽会警告）
(defclass meter ()
  ((name :initarg :name :initform "m" :type string)
   (base :allocation :class :initform 0 :type number))
  "仪表。")
(princ (format "  改前默认           → %S\n" (oref-default 'meter base)))
(oset-default 'meter base 100)
(princ (format "  oset-default 写    → %S\n" (oref-default 'meter base)))
(princ (format "  新实例读到新默认   → %S\n"
               (slot-value (meter) 'base)))
```

运行结果：

```
  改前默认           → 0
  oset-default 写    → 100
  新实例读到新默认   → 100
```

逐点读：

**类符号 + 槽名（宏 quote）是这对函数的签名。** `(oref-default 'meter base)`——类要 quote、槽不要 quote，引号不对称，照抄示例即可。`oset-default` 改的是**那一份共享存储**本身，所以改完之后新构造的实例读到的是新值（输出第三行），已存在的实例同样读到新值——毕竟全类只有一份。

**只用于真正的类槽。** 对实例槽用 `oref-default` 也能跑出结果（退回读 `:initform`），但字节编译器会报 `not class-allocated` 警告。判定标准下警告即失败，所以别心存侥幸。

**典型用途：运行期调全局默认。** 比如「本类的所有实例共享一个超时值，用户改一次全类生效」——`oset-default` 就是定制变量（defcustom）之外的对象版答案。

## 51.7 `with-slots`：把槽当局部变量

要在一个函数体里反复访问同一对象的多个槽，反复写 `(slot-value o 'age)` 很啰嗦。`with-slots` 用 `symbol-macrolet` 把槽名绑成**词法变量**，读写都直达对象。示例第 7 节：

示例第 7 节：

```elisp
;; with-slots 用 symbol-macrolet 把槽名绑成词法变量，setq
;; 与 setf 都会写回对象
(let ((o (emp :name "赵六" :age 40)))
  (with-slots (name age) o
    (setq age (1+ age))
    (princ (format "  原名绑定 → %S %S\n" name age)))
  (princ (format "  写回对象 → %S\n" (slot-value o 'age))))
;; 也可以 (变量 槽) 换名绑定
(let ((o (emp :name "孙七" :age 22)))
  (with-slots ((n name) (a age)) o
    (princ (format "  换名绑定 → %S %S\n" n a))))
```

运行结果：

```
  原名绑定 → "赵六" 41
  写回对象 → 41
  换名绑定 → "孙七" 22
```

逐点读：

**不是拷贝，是别名。** `with-slots` 展开为 `symbol-macrolet`——`age` 这个符号在体內出现时就地替换成 `(slot-value o 'age)`。所以 `(setq age (1+ age))` 等价于 `(setf (slot-value o 'age) (1+ (slot-value o 'age)))`，出块后对象的槽真的变了（输出第二行）。这带来两个推论：没有「出了块变量还在」的问题；块内对同名局部变量的 `let` 会遮蔽别名。

**换名写法解决撞名。** 同时要打开两个对象的槽，或者槽名与局部变量冲突时，用 `((n name) (a age))` 形式自定义变量名。

**何时用。** 方法体内要读写本对象三个以上槽时，`with-slots` 明显清爽；只碰一两个槽就直接 `slot-value`。CLOS 同款宏，名字都没改。

## 51.8 列表槽工具：`object-add-to-list` 与 `object-remove-from-list`

「对象里有个槽装着列表」是极常见的形态（标签集合、依赖列表、监听器注册表）。EIEIO 给了两个专用函数，省去「读出来、改、写回去」的三步。示例第 8 节：

示例第 8 节：

```elisp
;; 这两个函数操作的是「对象里装着列表的那个槽」：
;; (object-add-to-list 对象 槽 元素 &optional 追加?)
(defclass bag ()
  ((items :initarg :items :initform nil))
  "口袋。")
(let ((o (bag)))
  (object-add-to-list o 'items "苹果")
  (object-add-to-list o 'items "香蕉")
  (object-add-to-list o 'items "苹果")     ; 已存在则不加
  (princ (format "  add 三次（一次重复）→ %S\n" (oref o items)))
  (object-add-to-list o 'items "栗子" t)   ; 第四参 t 追加到末尾
  (princ (format "  append 到末尾         → %S\n" (oref o items)))
  (object-remove-from-list o 'items "苹果")
  (princ (format "  remove                → %S\n" (oref o items))))
```

运行结果：

```
  add 三次（一次重复）→ ("香蕉" "苹果")
  append 到末尾         → ("香蕉" "苹果" "栗子")
  remove                → ("香蕉" "栗子")
```

逐点读：

**默认去重、头部插入。** `object-add-to-list` 用 `equal` 检查成员——`"苹果"` 第二次加不进去；新元素默认 `cons` 到**表头**（所以前两元素输出顺序是 `("香蕉" "苹果")`）。第四参传 `t` 改为追加到表尾。去重语义使它特别适合做注册表。

**`object-remove-from-list` 按 `equal` 删全部匹配项。** 两个函数都直接改写对象的槽（等价于读-改-写），列表为 nil 起步也没问题。签名再记一遍：`(object-add-to-list 对象 槽 元素 &optional append)`——槽名是实参，要 quote。

## 51.9 与 `cl-defstruct` 的互操作

EIEIO 实例底层是 record，与 `cl-defstruct` 结构同源——于是部分 EIEIO 函数也能用在结构体上。但支持是**不对称的**。示例第 9 节实测边界：

示例第 9 节：

```elisp
;; EIEIO 对象底层就是记录，slot-value/setf 也能用在
;; cl-defstruct 实例上；但并非所有 EIEIO 函数都支持
(cl-defstruct (spoint (:constructor mk-spoint)) x y)
(let ((s (mk-spoint :x 1 :y 2)))
  (princ (format "  slot-value 读 struct → %S\n" (slot-value s 'x)))
  (setf (slot-value s 'x) 10)
  (princ (format "  slot-value 写 struct → %S\n" (spoint-x s)))
  (let ((sig1 (condition-case err
                  (progn (slot-boundp s 'x) nil)
                (error (car err))))
        (sig2 (condition-case err
                  (progn (make-instance 'spoint) nil)
                (error (car err)))))
    (princ (format "  slot-boundp 不支持  → %S\n" sig1))
    (princ (format "  make-instance 不支持 → %S\n" sig2))))
```

运行结果：

```
  slot-value 读 struct → 1
  slot-value 写 struct → 10
  slot-boundp 不支持  → wrong-type-argument
  make-instance 不支持 → cl-no-applicable-method
```

逐点读：

**`slot-value`（含 setf）是通用的。** 它对 EIEIO 对象和 `cl-defstruct` 结构都能按名读写——写跨两界的通用工具（检查器、dumper）时这是安全入口。

**带 EIEIO 语义的概念不通用。** `slot-boundp` 报 `wrong-type-argument`（结构体没有「未绑定」这个概念），`make-instance` 报 `cl-no-applicable-method`（`cl-defstruct` 定义的类型不是 EIEIO 类，没有构造方法）。同理 `eieio-object-p` 对结构体返回 nil。记法：**凡是「对象模型」层面的函数（构造、绑定状态、继承、方法）都只属于 EIEIO；只有「按名访问槽」这个层面是共享的**。

## 51.10 小结：一张表

| 主题 | 函数 / 信号 | 一句话备忘 |
| --- | --- | --- |
| 构造 | `类名` / `make-instance` | make-instance 首参必须是类符号；未知 initarg 报 invalid-slot-name |
| 读写 | `slot-value`+setf / `oref` / `oset` | 语义等价；oref 槽名自动 quote 别加引号；槽名来自变量时只能 slot-value |
| 绑定状态 | `slot-boundp` / `slot-makeunbound` / `unbound-slot` | 未绑定 ≠ nil；slot-unbound 泛型是懒求值钩子 |
| 槽名检查 | `slot-exists-p` | 返回索引或 nil；字面量错名编译期就警告 |
| 类型校验 | `:type` + `invalid-slot-type` | 定义期、构造期、每次写入三处校验 |
| 类槽 | `oref-default` / `oset-default` | 只用于 :allocation :class 槽，否则字节编译警告 |
| 词法绑定 | `with-slots` | symbol-macrolet 别名，setq 写回对象；可 (变量 槽) 换名 |
| 列表槽 | `object-add-to-list` / `object-remove-from-list` | equal 去重、默认头插、第四参 t 追加 |
| 互操作 | `slot-value` 通用；其余不通用 | 结构体无绑定状态、无 make-instance |

对象的操作面到此完备。下一章进入 EIEIO 最 CLOS 的部分：**方法**——`cl-defmethod` 的全部特化符、`:before`/`:after`/`:around` 限定符与执行顺序、`cl-call-next-method` 的链式语义、多继承下的派发顺序，以及 31.1 打印体系的现状。

上一章：[50 · defclass 详解：槽选项与类选项](50-eieio-defclass.md)　｜　下一章：[52 · 方法与调用：特化、限定符与方法链](52-eieio-methods.md)　｜　返回：[Emacs 扩展开发指南](README.md)
