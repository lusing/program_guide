# 20 · CLOS II：方法组合、eql 特化与元对象

> 配套示例：[`examples/20_clos_adv/`](../examples/20_clos_adv/main.lisp)（channel: both）

## 20.1 :before / :after / :around 的完整顺序

这组顺序**必须实测一遍才记得住**（示例 20 用审计日志式输出完整演示）：

```
(around 最特化) 进入
  before（从最具体到最泛）
  primary（只执行最具体的一个；call-next-method 沿链向上）
  after（从最泛到最具体——与 before 镜像！）
(around) 退出
```

要点：

- **`before` 从最具体到最泛，`after` 正好镜像**（从最泛到最具体）；
  记法：before 像「构造链」（具体→祖先），after 像「清理链」（祖先→具体）；
- 主方法只跑**最具体**的那一个，`call-next-method` 才会走更泛的；
- `:around` 包在最外层，**可以决定要不要继续**——不调 `call-next-method`
  就等于拦下这次调用（缓存、加锁、拦截都这么做）；
- `call-next-method` 的返回值就是被包裹方法的返回值；
  `next-method-p` 先探「还有没有下一个」；
- **before/after 的返回值被丢弃**——它们只做副作用（日志、校验、失效）。

## 20.2 call-next-method 链（三层实测）

```lisp
(defclass a () ()) (defclass b (a) ()) (defclass c (b) ())
(defgeneric who (x))
(defmethod who ((x a)) "A")
(defmethod who ((x b)) (format nil "B→~A" (call-next-method)))
(defmethod who ((x c)) (format nil "C→~A" (call-next-method)))
(who (make-instance 'c))     ; => "C→B→A"
```

## 20.3 :allocation :class：类级共享槽

```lisp
(defclass hit-counter ()
  ((hits :allocation :class :initform 0 :accessor hit-counter-hits)))
(incf (hit-counter-hits c1)) (incf (hit-counter-hits c1)) (incf (hit-counter-hits c2))
(hit-counter-hits c1)      ; => 3    ← c2 也看到 3：所有实例共享同一份存储
```

对应「静态字段」。实例级槽（默认 `:allocation :instance`）各自独立。

## 20.4 eql 特化器：按值分派

```lisp
(defgeneric permission (mode resource))
(defmethod permission ((mode (eql :admin)) resource) :全权)
(defmethod permission (mode (resource (eql :公开页))) :可读)
(defmethod permission (mode resource) :无权限)
```

`(eql :admin)` 特化第一个参数——**具体这个值**才命中；任意参数位置都能特化。
模式匹配/单例分发的轻量替代，DSL 里非常好用。

## 20.5 no-applicable-method：兜住「没有方法」

```lisp
(defgeneric only-for-string (x))
(defmethod only-for-string ((s string)) ...)

(defmethod no-applicable-method ((g (eql #'only-for-string)) &rest args)
  (declare (ignore args))
  :不支持这种参数)
```

`no-applicable-method` 是标准泛型，没有可用方法时被调用（SBCL/CLISP 都支持）。
另外每个泛型隐式有个 `no-applicable-method` 错误restart 供 REPL 交互。

## 20.6 非标准方法组合

`defgeneric` 的 `:method-combination` 换掉默认的「只跑最具体」规则：

```lisp
(defclass judge () ())
(defclass strict-judge (judge) ())

(defgeneric score (x) (:method-combination +))
(defmethod score + ((j judge)) 1)
(defmethod score + ((j strict-judge)) 2)
(score (make-instance 'strict-judge))     ; => 3   ← 类链上所有 primary 相加

(defgeneric voices (x) (:method-combination list))
(defmethod voices list ((x judge)) :基类意见)
(defmethod voices list ((x strict-judge)) :子类意见)
(voices (make-instance 'strict-judge))     ; => (:子类意见 :基类意见)  ← 收集全部
```

内置组合：`+ - max min and or list append nconc progn`。
定义 `+` 组合的方法时**要写限定符**：`(defmethod score + (...) ...)`。
自定义组合机制走 MOP（下一节）。

## 20.7 MOP 的一小步（可移植子集）

「元对象协议」（MOP）让 CLOS 自己用 CLOS 描述——类、泛型、方法本身都是对象，
可以检视甚至改动。**但 MOP 的入口包名不跨实现**（SBCL 是 `SB-MOP`，
CLISP 是 `CLOS`），可移植代码只用 ANSI 面：

```lisp
(class-name (class-of obj))          ; 类名
(find-class 'circle)                 ; 类对象；存在性探测
(typep obj 'circle)                  ; 13 章 typep 对类照常工作
(make-instance (find-class 'circle)) ; 类对象也能直接实例化
(eval '(defclass late-class () ...)) ; 运行期造类（defclass 也是可调用的宏家族）
```

**坑（实测）**：`find-class` 找不到类时——SBCL 直接报错、CLISP 发 WARNING
到 stderr——想要安静的 NIL，显式传第二参数：`(find-class 'no-such nil)`。

进阶（加槽的元类、改分派机制）认准各家 MOP 或封装库
（closer-mop 是跨实现门面），本教程不展开。

## 20.8 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| before/after 输出顺序「乱」 | after 与 before 镜像 | 实测记忆（示例 20 的审计日志） |
| :+ 组合的方法报错缺限定符 | 非标准组合必须写限定符 | `(defmethod score + ...)` |
| find-class 找不到类时行为不同 | SBCL 报错 / CLISP 告警 | `(find-class x nil)` 静默版 |
| no-next-method 报错 | 链尾还调 call-next-method | 先 `next-method-p` |
| 用了 SB-MOP 换实现就崩 | MOP 包名不跨实现 | ANSI 子集或 closer-mop |
| 共享槽「串数据」 | :allocation :class 全实例共享 | 默认 :instance |
