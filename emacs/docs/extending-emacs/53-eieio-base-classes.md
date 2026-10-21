# 53 · 预定义基类：named、singleton、tracker、inheritor 与 persistent

> 所属部分：第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

> 示例：`examples/53-eieio-base-classes.el`

手册的 Base Classes 一章介绍了 EIEIO 自带的六个基类：所有类的隐式父类 `eieio-default-superclass`，加上五个「继承即用」的成品——`eieio-named`（对象有名字）、`eieio-singleton`（单例）、`eieio-instance-tracker`（自动维护实例列表）、`eieio-instance-inheritor`（实例级原型链继承）、`eieio-persistent`（对象存盘/读回）。每一个都对应一个经典设计模式，是 EIEIO「 batteries included 」的部分。

开工前必须亮**四个 31.1 与手册的实测差异**，每个都踩过才写得出来：其一，除 `eieio-default-superclass` 外的五个基类都定义在 **`eieio-base.el`**，必须 `(require 'eieio-base)`——只 require `eieio` 就继承它们会报 `Given parent class eieio-named is not a class`；其二，`eieio-named` 的构造 initarg 是 **`:object-name`**，手册和老代码里的 `:name` 写法早已不存在；其三，`eieio-instance-tracker` 的用法是**覆写类槽 `tracking-symbol` 的 `:initform`**，手册写的类选项 `:tracker-symbol` 在 31.1 里没有效果；其四，`(eieio-class-parents 'plain)` 对一个「没写父类」的普通类返回 **`nil`**——31.1 不在这条函数结果里列出默认父类（但 `child-of-class-p` 仍认这层血统）。下面逐类展开。

## 53.1 `eieio-default-superclass`：所有类的隐式父类

`defclass` 的父类列表留空 `()` 时，类自动继承 `eieio-default-superclass`——EIEIO 类树的根。它定义了所有对象共享的基础方法（`clone`、`slot-unbound`、`initialize-instance` 的默认实现等）。示例第 1 节验证这层隐式血统：

示例第 1 节：

```elisp
(defclass plain ()
  ((x :initarg :x :initform 1 :type number))
  "不写父类的普通类。")

(princ (format "  class-parents(31.1 不列出默认父类)→ %S\n"
               (eieio-class-parents 'plain)))
(princ (format "  child-of-class-p                  → %S\n"
               (child-of-class-p 'plain 'eieio-default-superclass)))
```

运行结果：

```
  class-parents(31.1 不列出默认父类)→ nil
  child-of-class-p                  → t
```

逐点读：

**两个函数，两种答案，都对。** `eieio-class-parents` 回答「**显式**声明了哪些父类」——`plain` 没写，所以是 `nil`；`child-of-class-p` 回答「血统上是不是后代」——默认父类这层是算数的，所以是 `t`。写反射代码时用哪个，取决于你要「声明面」还是「血统面」。（`eieio-class-parents` 的返回值是**类对象**列表，不是符号列表，不能直接 `%S` 打印——54 章还会遇到它。）

**永远不要继承 `eieio-default-superclass` 本身，也不要实例化它。** 它是框架内部件；你写的每个类都已经在它之下。想知道「这个对象是不是 EIEIO 对象」用 49 章的 `eieio-object-p`。

## 53.2 `eieio-named`：给对象一个名字

继承 `eieio-named` 后，类多出一个 `object-name` 槽，配套 initarg `:object-name` 与读取函数 `eieio-object-name-string`。示例第 2 节：

示例第 2 节：

```elisp
(defclass person (eieio-named)
  ((age :initarg :age :initform 0 :type number))
  "带名字的人。")

(let ((p (person :object-name "张三" :age 30)))
  (princ (format "  initarg 是 :object-name → 槽 %S\n" (slot-value p 'object-name)))
  (princ (format "  eieio-object-name-string → %S\n" (eieio-object-name-string p))))
(princ (format "  缺 :object-name           → 槽 %S\n"
               (slot-value (person) 'object-name)))
```

运行结果：

```
  initarg 是 :object-name → 槽 "张三"
  eieio-object-name-string → "张三"
  缺 :object-name           → 槽 nil
```

逐点读：

**initarg 是 `:object-name`，不是手册的 `:name`。** 这是 31.1 上继承 `eieio-named` 最容易踩的坑：手册示例写 `(person :name "张三")`，照抄会报 `Invalid slot name: :name`。槽名同样叫 `object-name`（与「名字」冲突的业务槽比如 `full-name` 可以和平共存）。

**`eieio-object-name-string` 是显示层。** 有名字返回名字；**缺名字时不报错**，回退成一串由 `sxhash` 算出的十六进制标识（与对象地址相关，输出不确定，示例因此不演示）。缺名时 `object-name` 槽本身是 `nil`（输出第三行）——需要「必须有名字」约束时自己加校验。

**两个与打印相关的注记。** named 对象的 `%S` 打印会变成 `#<person 地址>` 形式（含堆地址，输出不可复现），教程因此一律只打印槽值不打印对象整体；另外 named 的 `make-instance` 仍兼容旧式「裸名首参」写法 `(person "李四")`，但与 49.2 讲的全局兼容机制一样——运行期 `message` 警告（`eieio-backward-compatibility` 默认 `'warn`），且**编译期 compiler-macro 无条件警告**，新代码一律写 `:object-name`。

## 53.3 `eieio-named` 与 `clone`：自动改名

`eieio-named` 定制了 `clone`（52.7 讲过 clone 可写类方法），解决「副本与原件同名」的歧义。三种调用形态三种结果。示例第 3 节：

示例第 3 节：

```elisp
(let ((p (person :object-name "原")))
  (princ (format "  clone 无参         → %S(自动加 -1)\n"
                 (slot-value (clone p) 'object-name)))
  (princ (format "  clone \"新\"(首参)   → %S\n"
                 (slot-value (clone p "新") 'object-name)))
  (princ (format "  clone :object-name → %S\n"
                 (slot-value (clone p :object-name "指名") 'object-name))))
```

运行结果：

```
  clone 无参         → "原-1"(自动加 -1)
  clone "新"(首参)   → "新"
  clone :object-name → "指名"
```

逐点读：

**无参 clone 自动改名加 `-1`。** 名字是唯一性语义时这是合理默认（再 clone 得 `-2`，依此类推）。**首参是字符串时直接作新名**——这是 named 专属的 clone 便利重载；与 49.2 的「裸名构造」兼容层不是一回事，clone 的这个用法是**当前支持的**，不产生警告。`:object-name` 关键字形式与通用 clone 语义一致（52.7），指名覆写。

## 53.4 `eieio-singleton`：单例

继承 `eieio-singleton` 的类只允许存在一个实例：`make-instance` 第一次真正构造，之后**任何**构造调用都返回同一个对象，且传入的 initarg 被忽略。示例第 4 节：

示例第 4 节：

```elisp
(defclass config (eieio-singleton)
  ((debug :initarg :debug :initform nil :type boolean))
  "全局配置,只允许一个实例。")

(let ((c1 (make-instance 'config :debug t))
      (c2 (make-instance 'config :debug nil)))
  (princ (format "  两次构造同一对象   → %S\n" (eq c1 c2)))
  (princ (format "  第二次 initarg 无效 → %S\n" (slot-value c2 'debug))))
```

运行结果：

```
  两次构造同一对象   → t
  第二次 initarg 无效 → t
```

逐点读：

**单例状态存在类槽里。** `eieio-singleton` 的实现是特化 `make-instance`：检查本类的 `singleton` 类槽，已存在就直接返回。所以第二次 `(make-instance 'config :debug nil)` 拿到的 `c2` 与 `c1` 是**同一个对象**（`eq` 为 `t`），`debug` 槽保持第一次的 `t`——第二次的 `:debug nil` 静默丢弃。这正是单例的经典语义，也意味着「想重配置」要走显式的 setter，不能靠再构造。

**适用场景：全局配置、连接池门面、注册中心。** 凡是「全进程一个」的对象，继承它比手写「defvar 存实例 + 空判断」干净。注意单例跨 `clone` 不适用——clone 是另一条构造路径，别用它造第二个。

## 53.5 `eieio-instance-tracker`：跟踪全部实例

继承 `eieio-instance-tracker` 后，**每构造一个实例就自动加入一个全局列表**，`delete-instance` 时自动移出——「我造过哪些连接/任务/窗口」从此不用手工维护。示例第 5 节：

示例第 5 节：

```elisp
(defvar my-connections nil
  "conn 类全部实例的列表,由跟踪器自动维护。")

(defclass conn (eieio-instance-tracker)
  ((tracking-symbol :initform 'my-connections)
   (host :initarg :host :initform "" :type string))
  "可跟踪的连接:覆写类槽 tracking-symbol 指向列表变量。")

(let ((a (conn :host "alpha"))
      (_b (conn :host "beta")))
  (princ (format "  构造即入列        → %S\n"
                 (mapcar (lambda (o) (slot-value o 'host)) my-connections)))
  (princ (format "  tracker-find beta → %S\n"
                 (slot-value
                  (eieio-instance-tracker-find "beta" 'host 'my-connections)
                  'host)))
  (delete-instance a)
  (princ (format "  delete-instance 后 → %S\n"
                 (mapcar (lambda (o) (slot-value o 'host)) my-connections))))
```

运行结果：

```
  构造即入列        → ("alpha" "beta")
  tracker-find beta → "beta"
  delete-instance 后 → ("beta")
```

逐点读：

**31.1 的用法：覆写类槽 `tracking-symbol` 的 `:initform`。** 手册写的是类选项 `:tracker-symbol`，31.1 上无效；正确做法是在槽列表里重声明 `(tracking-symbol :initform 'my-connections)`——这个类槽（基类已声明为 `:allocation :class`）装着「列表变量的符号名」。配套地，你得先 `defvar` 一个列表变量接住实例。类被设计为抽象基类（50.8 的 `:abstract`），直接实例化基类本身会报错——必须继承后覆写。

**自动入列/出列靠两个钩子。** 基类写了 `initialize-instance :after`（构造完成即 push 入列，52.6 讲过的钩子用法）和 `delete-instance`（从列表移除）。`delete-instance` 是 EIEIO 对象的「主动销毁」协议—— tracker 之外它主要是个钩子点，对象本身仍会被 GC 回收，但列表不清理就会泄漏引用，所以 tracker 类的实例不用了记得 `delete-instance`。

**`eieio-instance-tracker-find` 按键查实例。** 签名 `(eieio-instance-tracker-find 键 槽 列表符号)`：在列表里找「指定槽 `equal` 等于键」的第一个对象（底层就是 54 章的 `object-assoc`）。上例按 `host` 槽找到 beta 连接。这是「按名字找对象」的现成实现。

## 53.6 `eieio-instance-inheritor`：实例级原型链继承

类继承是「类与类」的关系；`eieio-instance-inheritor` 提供的是「**对象与对象**」的继承（JavaScript 原型链那种）：clone 出一个子实例后，子实例**未绑定的槽**会沿 `parent-instance` 链向父实例取值，自己赋过值的槽用自值。示例第 6 节：

示例第 6 节：

```elisp
(defclass proto (eieio-instance-inheritor)
  ((color :initarg :color :initform "红" :type string)
   (size :initarg :size :initform 10 :type number))
  "原型对象,克隆体未设置的槽向原型取值。")

(let* ((parent (proto :color "蓝" :size 20))
       (kid (clone parent)))
  (princ (format "  未绑定槽向父取值 → %S %S\n"
                 (slot-value kid 'color) (slot-value kid 'size)))
  (setf (slot-value kid 'size) 99)
  (princ (format "  覆写后用自值     → %S %S\n"
                 (slot-value kid 'color) (slot-value kid 'size)))
  (princ (format "  父对象不受影响   → %S %S\n"
                 (slot-value parent 'color) (slot-value parent 'size)))
  (princ (format "  inheritor-boundp → %S(沿父链)\n"
                 (eieio-instance-inheritor-slot-boundp kid 'color)))
  (princ (format "  普通 slot-boundp → %S(只看自身)\n"
                 (slot-boundp kid 'color))))
```

运行结果：

```
  未绑定槽向父取值 → "蓝" 20
  覆写后用自值     → "蓝" 99
  父对象不受影响   → "蓝" 20
  inheritor-boundp → t(沿父链)
  普通 slot-boundp → nil(只看自身)
```

逐点读：

**实现手法是 51.3 的 `slot-unbound` 钩子。** 基类定制了 `clone`：克隆时把子实例**全部槽 `slot-makeunbound`**（51.3 的「打回未绑定」），并把 `parent-instance` 槽设为原对象；又写了 `slot-unbound` 方法：读未绑定槽时沿 `parent-instance` 递归取值。于是 `kid` 出生「一无所有」，读 `color` 落回父亲的「蓝」；一旦给 `kid` 的 `size` 赋 99，该槽变成「自有」，从此用自值——父亲那边始终不变。CSS 层叠、配置profile 继承就是这套语义。

**两个 boundp 的分工要分清。** `eieio-instance-inheritor-slot-boundp` 沿父链查（`kid` 的 `color` 自身未绑定，但父亲有值 → `t`）；普通 `slot-boundp` 只看自身（→ `nil`）。写「这个属性最终有没有着落」的判断用前者，写「这层覆写了没有」的判断用后者。

## 53.7 `eieio-persistent`：把对象写进文件

50.4 讲过 `object-write` 只写 `standard-output`；真正的「存盘/读回」由 `eieio-persistent` 基类完成：子类获得 `file` 槽（存路径）与 `eieio-persistent-save`/`eieio-persistent-read` 一对函数。它常与 `eieio-named` 多继承搭配（存档文件里有名字更好认）。示例第 7 节完整走一遍写→读：

示例第 7 节：

```elisp
(defclass save-me (eieio-persistent eieio-named)
  ((data :initarg :data :initform 0 :type number))
  "可持久化的命名对象。")

(let ((s (save-me :object-name "存档一" :data 42
                  :file "/tmp/eieio-53-save.el")))
  (eieio-persistent-save s)
  (princ "  --- 写出的文件内容 ---\n")
  (with-temp-buffer
    (insert-file-contents "/tmp/eieio-53-save.el")
    (princ (buffer-string)))
  (princ "  --- 文件完 ---\n")
  (let ((r (eieio-persistent-read "/tmp/eieio-53-save.el" 'save-me)))
    (princ (format "  读回 → name %S data %S\n"
                   (slot-value r 'object-name) (slot-value r 'data)))
    (princ (format "  file 槽被设为读取路径 → %S\n" (slot-value r 'file)))))
```

运行结果：

```
  --- 写出的文件内容 ---
;; Object 存档一
;; EIEIO PERSISTENT OBJECT
(save-me "存档一"
  :file "eieio-53-save.el"
  :object-name "存档一"
  :data 42)
  --- 文件完 ---
  读回 → name "存档一" data 42
  file 槽被设为读取路径 → "/tmp/eieio-53-save.el"
```

逐点读：

**写文件的入口是 `eieio-persistent-save`，不是 `object-write`。** 它内部用 `with-temp-buffer` 收集 `object-write` 的输出再 `write-region` 落盘。文件内容三段：对象名注释行（`;; Object 存档一`）、标记行（`;; EIEIO PERSISTENT OBJECT`）、重构指令——就是 50.4 讲的「构造函数调用形式」。两个细节：`file` 槽落盘时被写成**相对文件名**（`file-name-nondirectory`），读回时再还原；构造形式用的是旧式裸名调用（`(save-me "存档一" …)`）——这正是 49.2 说的向后兼容层仍在服役的地方，**读回路径由框架自己消化，你写代码别模仿这个形式**。

**读回用 `(eieio-persistent-read 路径 类)`。** 它 `eval` 文件里的重构指令重建对象，并把 `file` 槽 `oset` 成读取时的**绝对路径**（输出最后一行）——于是「从哪读的还存回哪去」成立，`save` 不指定路径时默认写回 `file` 槽。第二参类名起校验作用，文件里重构出来的类不符会报错。

**持久化的边界记在 50.4 的老话里：** 只写「有 initarg 且值 ≠ initform」的槽，未绑定槽、无 initarg 的内部状态都不会落盘。设计可持久化类时，把「需要被记住的」槽都开 `:initarg`；槽值必须是可打印可读回的类型（数字、字符串、列表、结构），buffer、process、窗口这类活体引用存不了——存重建所需的「原料」（比如文件路径），读回后在 `initialize-instance` 里重建。

## 53.8 小结：一张表

| 基类 | 模式 | 一句话备忘 |
| --- | --- | --- |
| `eieio-default-superclass` | 类树根 | 隐式父类；class-parents 不列它、child-of-class-p 认它 |
| `eieio-named` | 命名对象 | initarg 是 `:object-name`（非 :name）；clone 自动加 `-1`，首参字符串即新名 |
| `eieio-singleton` | 单例 | 二次构造返回同一对象，initarg 被忽略 |
| `eieio-instance-tracker` | 实例注册表 | 覆写 `(tracking-symbol :initform '变量)`（非 :tracker-symbol）；构造即入列，delete-instance 出列 |
| `eieio-instance-inheritor` | 原型链 | clone 后未绑定槽向父实例取值；两个 boundp 一沿链一只看自身 |
| `eieio-persistent` | 对象存盘 | `eieio-persistent-save` / `-read`；只写有 initarg 且非默认的槽；常与 named 多继承 |

共同前提再强调一次：**`(require 'eieio-base)`**。五个基类到此讲完——它们各自把一种经典设计模式做成了「继承即用」，写扩展时先翻翻有没有现成的，比重新发明轮子划算。下一章收尾本部分：**内省**（类与对象的相互查询、槽描述符、object-assoc 家族）、交互工具（`eieio-browse`、`customize-object`）与一份 31.1 废弃清单。

上一章：[52 · 方法与调用：特化、限定符与方法链](52-eieio-methods.md)　｜　下一章：[54 · 内省与工具：谓词族、object-assoc 与废弃清单](54-eieio-introspection.md)　｜　返回：[Emacs 扩展开发指南](README.md)
