# 52 · 方法与调用：特化、限定符与方法链

> 所属部分：第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

> 示例：`examples/52-eieio-methods.el`

方法是 EIEIO 的灵魂——`defclass` 只搭了骨架，多态全靠泛型函数。本章对应手册的 Writing Methods 与 Method Invocation 两章，把方法系统讲透：`cl-defgeneric`/`cl-defmethod` 的完整用法、`:before`/`:after`/`:around` 三种**辅助方法**的执行顺序、`cl-call-next-method` 的链式语义、无方法与无后继两个信号、多继承下的派发顺序（C3 线性化）、构造后钩子 `initialize-instance`、对象复制 `clone`、类方法特化符 `(subclass 类)`，最后是对象的**打印体系**及其 31.1 现状。

先亮三条实测结论：其一，辅助方法的顺序是**`:before` 最特化优先、`:after` 最特化最后**，返回值永远取自 primary 方法——这与 CLOS 标准一致，但与直觉（after 也子类先行）相反，务必看一遍输出；其二，`cl-call-next-method` 在「没有下一个方法」时抛的是独立信号 `cl-no-next-method`，不是 `cl-no-applicable-method`；其三，手册推荐的打印定制方式（给 `cl-print-object` 写方法）**在 31.1 上对 EIEIO 类注册即崩溃**——本章如实记录崩溃形态并给出可行替代。

## 52.1 `cl-defgeneric` 与 `cl-defmethod`：派发基础

49 章已见过基本写法，这里把派发规则钉死：**运行时按实参类型选「最特化」的方法**。示例第 1 节定义 `animal` 与子类 `dog`，泛型 `speak` 对两类各写一个方法：

示例第 1 节：

```elisp
(defclass animal ()
  ((name :initarg :name :initform "动物" :type string))
  "动物基类。")

(defclass dog (animal)
  ()
  "狗,继承 animal。")

(cl-defgeneric speak (x)
  "让 X 发声。文档字符串写在这里,不写进各个方法。")

(cl-defmethod speak ((a animal))
  (format "%s叫了一声" (slot-value a 'name)))

(cl-defmethod speak ((d dog))
  (format "%s汪汪叫" (slot-value d 'name)))

(princ (format "  animal → %S\n" (speak (animal :name "某动物"))))
(princ (format "  dog    → %S\n" (speak (dog :name "阿黄"))))
```

运行结果：

```
  animal → "某动物叫了一声"
  dog    → "阿黄汪汪叫"
```

逐点读：

**最特化优先。** 对 `dog` 实例，两个方法在类型上都匹配（dog 是 animal 的子类），选中的是 `dog` 版本——最具体的赢。这个「applicable 方法集合 + 按特化度排序」的两步是 CLOS 派发的核心算法，后面限定符、多继承都建立在它之上。

**文档字符串集中写在 `cl-defgeneric`。** 方法体前的字符串是方法的文档（`cl-defmethod` 也接受），但惯例是把面向用户的文档写在泛型声明里——`M-x describe-function` 看的是泛型。泛型声明里还能写 `(:arguments …)`、`(:method-combination …)` 等进阶选项，日常用不到。

**参数列表必须形状一致。** 所有方法的参数个数、可选性必须与泛型声明兼容（特化不改变形状，只给参数「贴类型标签」）。cl-generic 支持 `&optional`、`&rest`，`&key` 不支持派发——要对关键字参数分派请改为传一个对象。

## 52.2 `:before` 与 `:after`：辅助方法与执行顺序

方法名和参数列表之间可以插一个**限定符**（qualifier）：不写是 **primary**（主方法），`:before`、`:after` 是**辅助方法**——它们不返回业务值，只在主方法前后自动执行副作用（日志、资源准备、收尾）。同一次调用里，类层次上**所有**匹配的辅助方法都会执行。示例第 2 节给 `feed` 同时挂 animal 级和 dog 级的 before/after：

示例第 2 节：

```elisp
(cl-defgeneric feed (x)
  "喂食 X。")

(cl-defmethod feed :before ((_a animal))
  (princ "  [before animal] 准备食盆\n"))

(cl-defmethod feed :before ((_d dog))
  (princ "  [before dog] 摇尾巴\n"))

(cl-defmethod feed ((a animal))
  (format "%s吃完了" (slot-value a 'name)))

(cl-defmethod feed :after ((_a animal))
  (princ "  [after animal] 收拾食盆\n"))

(cl-defmethod feed :after ((_d dog))
  (princ "  [after dog] 舔嘴\n"))

(let ((r (feed (dog :name "阿黄"))))
  (princ (format "  返回值 → %S\n" r)))
```

运行结果：

```
  [before dog] 摇尾巴
  [before animal] 准备食盆
  [after animal] 收拾食盆
  [after dog] 舔嘴
  返回值 → "阿黄吃完了"
```

逐点读：

**`:before` 最特化优先，`:after` 反过来。** 对 `dog` 实例的完整执行序是：before(dog) → before(animal) → primary(animal) → after(animal) → after(dog)。助记：before 从子类向父类「向下扎根」，after 从父类向子类「向上回卷」——像一个嵌套结构，最内层是 primary。

**返回值只取自 primary。** 辅助方法的返回值被丢弃（示例里它们 `princ` 纯属演示副作用），`(feed …)` 的值是 primary 的 `"阿黄吃完了"`。想在返回值上做文章要用 `:around`（52.3）。

**没用到的参数记得加下划线前缀。** 辅助方法常常只做副作用、不用实参，但参数列表形状必须与泛型一致——参数照写、名字前加下划线（`_a`、`_d`）告诉字节编译器「我有意不用」，否则会收获一串 `Unused lexical argument` 警告。这是本例编译零警告的关键细节。

## 52.3 `:around` 与 `cl-call-next-method`

第三种限定符 `:around` 是「包在最外层」的方法：它**取代** primary 成为执行入口，方法体内用 `cl-call-next-method` 调下一层（更特化的 around，或最终的 before/primary/after 组合），拿到结果后可以任意包装。示例第 3 节：

示例第 3 节：

```elisp
(cl-defgeneric area (x)
  "返回 X 的面积。")

(cl-defmethod area ((_a animal))
  10)

(cl-defmethod area :around ((_a animal))
  ;; cl-call-next-method 调用下一层(这里是 primary),可包装其返回值
  (* 2 (cl-call-next-method)))

(princ (format "  primary 10 经 around 翻倍 → %S\n" (area (animal))))
```

运行结果：

```
  primary 10 经 around 翻倍 → 20
```

逐点读：

**`:around` 是装饰器模式的语言内置版。** 缓存（命中则不调 next 直接返回）、日志计时、加锁、动态绑定——一切「包住原行为」的需求都走 around。与 advice（19 章）相比它是**一等公民**：参与派发、能特化、可叠加多层。

**`cl-call-next-method` 是链式语义。** 它把控制权交给「按特化度排序的下一个方法」：在 around 里是下一层，在 primary 里是父类版本。调用零次（around 直接返回缓存值）、一次、甚至多次（少见但合法，每次都重新走下一层）都可以。还有一个搭档谓词 `cl-next-method-p`，先问再调可避开 52.4 的 `cl-no-next-method`。

## 52.4 无方法、无后继与 `t` 兜底

派发失败的两种形态各有独立信号；补救手段是写一个兜底方法。示例第 4 节把三个场景一次跑完：

示例第 4 节：

```elisp
(cl-defgeneric greet (x)
  "问候 X。")

(cl-defmethod greet ((a animal))
  (format "你好,%s" (slot-value a 'name)))

(princ (format "  无匹配方法     → %S\n"
               (condition-case err
                   (progn (greet 42) nil)
                 (error (car err)))))

(cl-defmethod greet ((x t))
  (format "兜底:%s" (type-of x)))

(princ (format "  定义 t 兜底之后 → %S\n" (greet 42)))

(cl-defgeneric solo (x)
  "只有一个方法的泛型。")

(cl-defmethod solo ((_a animal))
  ;; 没有更一般的方法,cl-call-next-method 无路可走
  (condition-case err
      (cl-call-next-method)
    (error (car err))))

(princ (format "  next 无后继     → %S\n" (solo (animal))))
```

运行结果：

```
  无匹配方法     → cl-no-applicable-method
  定义 t 兜底之后 → "兜底:integer"
  next 无后继     → cl-no-next-method
```

逐点读：

**两个信号管两件事。** `cl-no-applicable-method`：没有任何方法认领这个实参（`greet` 收到 `42`）；`cl-no-next-method`：方法存在，但方法体内 `cl-call-next-method` 发现没有下一层（`solo` 只有最特化一级）。排查时先分清是哪个——前者是「调用点传错类型」，后者是「方法链断在半路」。

**`(x t)` 兜底是标准惯用法。** `t` 匹配一切类型，特化度最低，永远排在方法链末尾。给它一个合理行为（上例回 `"兜底:integer"`），泛型就永远不会「无人认领」。这也是替代「特化 `cl-no-applicable-method` 泛型」的正解——49.7 说过，那条 CLOS 标准拦截路径在 31.1 上不可行（运行时传入的第一实参是内部 `#s(cl--generic …)` 结构，与 `#'greet` 包装函数不相等，`(eql #'greet)` 特化永远匹配不上）。

## 52.5 多继承的派发顺序：C3 线性化

50 章讲过「多继承同名槽前位父类赢」。方法派发走同一条规则，背后是**类线性化**：EIEIO 用 C3 算法把继承图压成一条链，`defclass` 父类列表里**靠前的父类在链上靠前**，派发沿链找第一个有方法的类。示例第 5 节：

示例第 5 节：

```elisp
(defclass wings ()
  ()
  "翅膀能力。")

(defclass fur ()
  ()
  "毛发能力。")

(defclass bat (wings fur)
  ()
  "蝙蝠:先 wings 后 fur。")

(cl-defgeneric feature (x)
  "返回 X 的标志性能力。")

(cl-defmethod feature ((_w wings)) "会飞")
(cl-defmethod feature ((_f fur)) "有毛")

(cl-defmethod feature ((_b bat))
  (concat "蝙蝠(" (cl-call-next-method) ")"))

(princ (format "  bat 沿 C3 链先找到 wings → %S\n" (feature (bat))))
```

运行结果：

```
  bat 沿 C3 链先找到 wings → "蝙蝠(会飞)"
```

逐点读：

**`(bat wings fur)` 的线性化是 `bat → wings → fur`。** `bat` 的 primary 里 `cl-call-next-method` 取到的是 `wings` 的 `"会飞"`——父类列表里 `wings` 在 `fur` 前面。把定义改成 `(bat (fur wings))` 结果就会变成 `"蝙蝠(有毛)"`。**父类顺序是语义的一部分**，写多继承时别随手排。

**混类（mixin）模式由此而来。** `wings`、`fur` 这种「只提供能力、不独立实例化」的类是 CLOS 风格的 mixin：子类按需组合，前位 mixin 优先。需要菱形继承（共同祖先）时 C3 保证祖先只出现一次且位置一致，不必担心「方法被执行两遍」。

## 52.6 `initialize-instance`：构造后钩子

构造一个实例时，EIEIO 先按 initarg/initform 填槽，然后调泛型 `initialize-instance`——这是官方的「构造后钩子」，用于算派生槽、建索引、注册到全局表。标准写法是**先 `cl-call-next-method` 再干自己的事**（让标准填槽逻辑先跑完）。示例第 6 节给 `rect` 自动算面积：

示例第 6 节：

```elisp
(defclass rect ()
  ((w :initarg :w :initform 0 :type number)
   (h :initarg :h :initform 0 :type number)
   (a :initform 0 :type number))
  "矩形:w、h 由构造给定,a 是派生面积。")

(cl-defmethod initialize-instance ((r rect) &rest _slots)
  ;; 先让标准构造完成填槽,再算派生槽
  (cl-call-next-method)
  (setf (slot-value r 'a) (* (slot-value r 'w) (slot-value r 'h))))

(princ (format "  rect :w 3 :h 4 → 派生槽 a = %S\n"
               (slot-value (rect :w 3 :h 4) 'a)))
```

运行结果：

```
  rect :w 3 :h 4 → 派生槽 a = 12
```

逐点读：

**签名要点：`&rest _slots` 不可少。** `initialize-instance` 被调用时会收到全部构造 initarg（作为多余实参传入），方法参数列表必须用 `&rest` 吃掉它们，否则报参数不匹配。下划线前缀同理——通常用不到它们。

**先 next 再加工是铁律。** `cl-call-next-method` 执行标准填槽（initarg 赋值、initform 求值）；在它之前读槽，读到的可能是未绑定。53 章的 `eieio-instance-tracker` 用 `initialize-instance :after` 做「构造即注册」，是本钩子的又一个标准用法——那种写法连 `cl-call-next-method` 都不用自己调。

## 52.7 `clone`：复制对象

`clone` 是 EIEIO 的对象复制器：**浅拷贝**全部槽值生成独立副本，还可附带 initarg 覆写指定槽。示例第 7 节：

示例第 7 节：

```elisp
(let* ((r1 (rect :w 5 :h 6))
       (r2 (clone r1))
       (r3 (clone r1 :w 9)))
  (setf (slot-value r2 'w) 99)
  (princ (format "  原对象 w       → %S(克隆是独立副本)\n" (slot-value r1 'w)))
  (princ (format "  克隆后改 r2    → %S\n" (slot-value r2 'w)))
  (princ (format "  clone 带 initarg → w=%S h=%S(覆写 w,其余照抄)\n"
                 (slot-value r3 'w) (slot-value r3 'h))))
```

运行结果：

```
  原对象 w       → 5(克隆是独立副本)
  克隆后改 r2    → 99
  clone 带 initarg → w=9 h=6(覆写 w,其余照抄)
```

逐点读：

**独立副本指「槽值层面」的独立。** 改 `r2` 的 `w` 不影响 `r1`。但浅拷贝意味着：槽里装的列表、哈希表等**引用型值是两对象共享的**——改 `r2` 某槽里的列表内容，`r1` 看同一个列表也会变。要深拷贝得自己写（对引用槽先复制再 setf）。

**带 initarg 的 clone 是「以原对象为底的构造」。** `(clone r1 :w 9)` 等于「照抄 r1 的全部槽，再按 `:w 9` 覆写」——适合「原型 + 微调」的配置对象场景。`clone` 是泛型，可以给自己的类写方法定制复制行为（比如复制时重新生成 id 槽）；53 章会看到 `eieio-named` 与 `eieio-instance-inheritor` 都这么干了。

## 52.8 `(subclass 类)` 特化符：挂在类上的「静态方法」

cl-generic 的特化符不止「实例类型」一种。`(subclass 类)` 匹配的不是实例，而是**类符号本身**——于是方法可以对「传进来的是 dog 这个类（而非 dog 的对象）」分派，等价于 Java 的静态方法。示例第 8 节：

示例第 8 节：

```elisp
(cl-defgeneric describe-class (c)
  "描述类 C。")

(cl-defmethod describe-class ((c (subclass animal)))
  (format "类 %s 属于 animal 家族" c))

(princ (format "  传类符号 → %S\n" (describe-class 'dog)))
```

运行结果：

```
  传类符号 → "类 dog 属于 animal 家族"
```

逐点读：

**特化的是「符号」，匹配的是「类血统」。** `(describe-class 'dog)` 传入符号 `dog`，`(subclass animal)` 判断「`dog` 这个类是不是 `animal` 的子类（含自身）」——是，方法命中。类方法的经典用途：工厂（`make-instance` 之外按类定制构造）、元信息查询（按类查表名、版本号）、注册协议（子类定义后自动登记）。

**cl-generic 还有其他特化符。** `(eql 值)` 按值精确匹配（`(cl-defmethod f ((x (eql 42))) …)`）、`(head 值)` 匹配 car 为某值的 cons——它们与 EIEIO 类特化可自由混用，这是 25 之后方法系统统一带来的红利。完整列表见 `cl-generic.el` 的注释；日常九成场景用「类特化 + t 兜底 + 偶尔 eql」就够了。

## 52.9 打印体系：默认 record 语法与 31.1 现状

49 章已知对象 `%S` 打印为 `#s(rect 3 4 12)`。关于「自定义打印」，手册与老代码里有三个名字，必须分清它们在 31.1 的处境。先看默认行为与可行替代：

示例第 9 节：

```elisp
(let ((r (rect :w 3 :h 4)))
  (princ (format "  %%S / prin1 → %S\n" r))
  (princ (format "  %%s / princ  → %s\n" r)))

(cl-defmethod describe ((r rect))
  (format "矩形 %dx%d" (slot-value r 'w) (slot-value r 'h)))

(princ (format "  自定义普通方法 → %S\n" (describe (rect :w 3 :h 4))))
```

运行结果：

```
  %S / prin1 → #s(rect 3 4 12)
  %s / princ  → #s(rect 3 4 12)
  自定义普通方法 → "矩形 3x4"
```

逐点读：

**默认打印：`%S` 与 `%s` 都是 record 语法。** EIEIO 没有给 princ/prin1 挂钩子，两个格式符输出一致，且都**不带槽名**（按槽定义顺序排值）。想要带槽名的可读形式，用 `cl-prin1-to-string`（48 章讲过，它走 `cl-print-object` 泛型，对结构会打印 `#s(rect :w 3 :h 4 :a 12)` 风格）或 `object-write`（50 章）。

**手册时代的 `object-print` 方法已废弃。** 老代码里给类写 `object-print` 方法定制打印的做法自 Emacs 26 起过时，31.1 完全无效，写了也不会被调用。

**手册推荐的继任者 `cl-print-object`，在 31.1 对 EIEIO 类不可用。** 这是本章最反直觉的实测结论，值得完整交代：手册说「定制打印就给 `cl-print-object` 写方法」，48 章也验证过它对 `cl-defstruct` 有效。但把 `cl-defmethod` 特化到一个 **EIEIO 类**上时，**方法注册的那一刻**就触发 `Wrong type argument: number-or-marker-p, #s(point 0 0)` 的 early error（EIEIO 为派发预先生成的「原型实例」被送进了 `cl-print` 内部一个数值函数），批处理直接以退出码 255 收场——方法根本注册不上，更谈不上调用。`&optional stream` 变体同样崩溃。结论：**31.1 上给 EIEIO 类定制打印，不要走 `cl-print-object`**；这个边界已实测钉死，等上游修复前都有效。

**可行替代：自定义普通方法。** 像示例里那样定义 `describe` 方法返回可读字符串，调用处显式调用——没有魔法，但可靠、可派发、可继承，这正是大量真实 EIEIO 代码的做法。

## 52.10 小结：一张表

| 主题 | 机制 | 一句话备忘 |
| --- | --- | --- |
| 派发 | `cl-defgeneric` / `cl-defmethod` | 最特化优先；文档写在 generic；参数形状必须一致 |
| 辅助方法 | `:before` / `:after` | before 最特化优先、after 最特化最后；返回值取自 primary；未用参数加下划线 |
| 包装 | `:around` + `cl-call-next-method` | 装饰器模式内置版；`cl-next-method-p` 先问再调 |
| 失败信号 | `cl-no-applicable-method` / `cl-no-next-method` | 前者无人认领、后者链断；惯用 `(x t)` 兜底；特化 no-applicable 拦截不可行 |
| 多继承 | C3 线性化 | 父类列表前位优先；mixin 模式由此而来 |
| 构造钩子 | `initialize-instance` | 签名带 `&rest _slots`；先 next 再加工 |
| 复制 | `clone` | 浅拷贝独立副本；可带 initarg 覆写；引用型槽共享 |
| 类方法 | `(subclass 类)` 特化符 | 传类符号分派；工厂与元信息的挂点 |
| 打印 | `#s(类 值…)` / `cl-prin1-to-string` / 自定义方法 | object-print 已废弃；cl-print-object 对 EIEIO 类 31.1 注册即崩溃 |

方法系统至此完整：**派发选型（特化）→ 执行编排（限定符）→ 链式复用（call-next-method）→ 失败兜底（t 方法与两信号）**——CLOS 方法组合的精华都在了。下一章换个角度：EIEIO 自带的五个**预定义基类**——给对象起名字、单例、实例追踪、原型链继承、持久化——全是开箱即用的设计模式。

上一章：[51 · 槽与访问：slot-value、oref 与绑定状态](51-eieio-slots.md)　｜　下一章：[53 · 预定义基类：named、singleton、tracker、inheritor 与 persistent](53-eieio-base-classes.md)　｜　返回：[Emacs 扩展开发指南](README.md)
