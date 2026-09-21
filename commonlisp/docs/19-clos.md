# 19 · CLOS I：类、泛型函数与多分派

> 配套示例：[`examples/19_clos/`](../examples/19_clos/main.lisp)（channel: both）

CLOS（Common Lisp Object System）和主流 OOP 有两处根本区别，先记住它们：

1. **方法不属于类**，而是属于**泛型函数**（generic function）——方法是独立定义，
   按参数类型「挂」到泛型函数上；
2. **方法可以按多个参数分派**（multiple dispatch），不只是第一个参数。

## 19.1 defclass：类与槽

```lisp
(defclass person ()
  ((name  :initarg :name   :initform "无名氏" :accessor person-name)
   (age   :initarg :age    :initform 0        :accessor person-age
          :type integer)
   (id    :reader person-id :initform (incf *person-counter*))))

(defparameter *person-counter* 0)   ; ⚠️ initform 引用的变量要先定义（SBCL 编译期就查）

(defvar *p* (make-instance 'person :name "张三" :age 30))
(person-name *p*)          ; => "张三"
(setf (person-age *p*) 31) ; setf 访问器即「位置」
(slot-value *p* 'age)      ; 31     ← 通用入口（绕过访问器，调试用）
```

槽选项速查：

| 选项 | 作用 |
|---|---|
| `:initarg :x` | 允许 `(make-instance 'c :x 1)` 传值 |
| `:initform v` | 没传时的初值（每次构造时求值） |
| `:accessor x` | 生成读+写泛型函数 |
| `:reader x` / `:writer x` | 只读 / 只写 |
| `:type t` | 类型声明（供优化） |
| `:allocation :class` | 类级共享槽（20 章） |

槽可以「**未绑定**」——CLOS 独有的状态，不等于「值是 nil」：

```lisp
(defclass sparse () ((x :initarg :x) (y :initarg :y)))
(defparameter *sp* (make-instance 'sparse :x 1))
(slot-boundp *sp* 'x)      ; => T
(slot-boundp *sp* 'y)      ; => NIL
(slot-value *sp* 'y)       ; 报错：slot Y is unbound
(slot-exists-p *sp* 'nope) ; => NIL
```

批量访问：`with-slots`（槽名直接当变量，底层是 symbol-macrolet——15 章伏笔）、
`with-accessors`（走访问器，名字可与槽名不同）。

## 19.2 泛型函数：方法按参数类型挂上来

```lisp
(defgeneric describe-thing (obj))
(defmethod describe-thing ((p person)) ...)
(defmethod describe-thing ((s string)) (format nil "字符串，长 ~A" (length s)))
(defmethod describe-thing ((n integer)) (format nil "整数 ~A" n))
```

**名字不能叫 `describe`**——它是 CL 标准函数，`defgeneric` 直接拒绝
（`DESCRIBE already names an ordinary function`，--non-interactive 下整个文件终止）。

**多分派**是 CLOS 的招牌——按两个参数的**类型组合**选方法：

```lisp
(defclass dog () ())
(defclass cat () ())
(defclass robot () ())

(defgeneric meet (a b))
(defmethod meet ((a dog) (b dog)) "狗和狗：摇尾巴转圈")
(defmethod meet ((a dog) (b cat)) "狗和猫：猫炸毛")
(defmethod meet (a b) "其他组合：互相打量")          ; 无特化 = 兜底
```

单分派语言里这得写成 `a.meet(b)` 再二次 instanceof/visitor——CLOS 原生支持。

**eql 特化器**按**具体值**分派（枚举/单例利器，20 章）。

没有任何方法匹配时调用 `no-applicable-method`（20 章接住它）。

## 19.3 继承与 call-next-method

```lisp
(defclass employee (person)
  ((company :initarg :company :accessor employee-company :initform "自由职业"))
  (:default-initargs :age 18))

(defmethod describe-thing ((e employee))
  (format nil "~A｜就职于 ~A"
          (call-next-method)           ; 复用 person 方法（沿类链向上）
          (employee-company e)))
```

- `call-next-method` 调用「下一个更泛的可适用方法」；没有下一个还调会报错，
  先用 `next-method-p` 探（20 章实测）；
- `typep` 对类同样工作：`(typep e 'employee)` 和 `(typep e 'person)` 都是 T
  （类型系统与类系统打通，13 章）。

**⚠️ 双实现差异（实测）**：CLISP 对「给**已经调用过**的泛型函数追加方法」发
WARNING 到 stderr（SBCL 无此检查）——方法定义放在第一次调用之前
（示例 19 专门为此调整了顺序）。

## 19.4 :default-initargs vs :initform

优先级：**显式参数 > :default-initargs > :initform**：

```lisp
(defclass config ()
  ((debug :initarg :debug :initform nil :accessor config-debug)
   (level :initarg :level :initform 1   :accessor config-level))
  (:default-initargs :level 5))

(config-level (make-instance 'config))           ; => 5  ← default-initargs 赢
(config-level (make-instance 'config :level 9))  ; => 9  ← 显式传值最优先
```

**坑（实测）**：`:default-initargs` 的表达式是普通词法形式，**不能引用同一次
构造的其他 initarg**——SBCL 报「undefined variable OWNER」，CLISP 运行期报
「variable OWNER has no value」。需要联动的默认值放进 `initialize-instance :after`。

传**未知**关键字会报错（帮你抓拼写）：`Invalid initialization argument :NOPE`。

## 19.5 print-object：自定义打印

默认打印是 `#<TRACED {地址}>`（地址每次运行都不同）。自定义：

```lisp
(defmethod print-object ((p person) stream)
  (print-unreadable-object (p stream :type t :identity nil)
    (format stream "~A/~A岁" (person-name p) (person-age p))))
; => #<PERSON 张三/30岁>
```

`print-unreadable-object` 负责 `#<>` 和类型名；`:identity nil` 不打地址。
**跨实现一致的输出全靠自定义 print-object**（地址、时间戳一律不进输出）。

## 19.6 实例化钩子

```lisp
(defmethod initialize-instance :after ((p person) &key)
  (when (> (person-age p) 150)
    (error 'simple-error :format-control "年龄 ~A 超出合理范围"
                         :format-arguments (list (person-age p)))))
```

`initialize-instance :after` 是「校验/补默认值」的标准钩子（所有槽已填好）；
更底层的 `shared-initialize` 先于它跑。示例 19 用它拦截了 `:age 999` 的构造。

## 19.7 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| defgeneric describe 直接终止文件 | 重定义 CL 标准函数名 | 换名字 |
| slot-value 报 unbound | 槽无初值也未传参 | `slot-boundp` 先判 / 加 `:initform` |
| default-initargs 引用别的 initarg | 词法形式看不到兄弟 | 挪到 initialize-instance :after |
| CLISP 告警 Adding method to called function | 调用后追加方法 | 定义先于调用 |
| equal 两个实例是 NIL | CLOS 实例默认比身份 | 自定义打印+比较，或用 defstruct（09 章） |
| 打印输出带地址，测试不稳 | 默认打印含地址 | print-object + `:identity nil` |
