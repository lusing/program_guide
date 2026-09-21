# 26 · 性能优化（SBCL 实测）

> 配套示例：[`examples/26_perf/`](../examples/26_perf/main.lisp)（channel: sbcl）
>
> 声明部分是 ANSI 的（13 章），收益实测主要在 SBCL——它是「始终编译 + 类型推理」
> 的实现；CLISP 主要解释执行，同一份声明收益有限（22 章）。

## 26.1 优化的第一原则

**先测量，后优化。** `time` 宏是最省事的起点：

```
(time (loop for i from 1 to 1000000 sum i))
Evaluation took:
  0.002 seconds of real time
  ...
  0 bytes consed
```

**看 `bytes consed` 这一行比看时间更有用**——它告诉你这段代码有没有分配内存、
GC 压力大不大。热点函数先用 `sb-profile`（在核心里，**不用 require**）：

```lisp
(sb-profile:profile my-function)
;; … 跑负载 …
(sb-profile:report)
;;   seconds |   gc  |  consed  | calls | sec/call | name
```

**坑（实测）**：`sb-profile:report` 会先打一行
`measuring PROFILE overhead..done`——它**绕过 Lisp 流直接写控制终端**：
`--load` 方式运行时 stderr 里没有它（判定不受影响），`--script` 方式则会
落进 stderr。本仓库统一 `--load` 就是为这个。更深的分析用 contrib 的
`sb-sprof`（**要 require**）。

## 26.2 类型声明：最有效的手段

```lisp
(defun slow-add (a b) (+ a b))                     ; 通用版：全类型检查
(defun fast-add (a b)
  (declare (type fixnum a b))
  (the fixnum (+ a b)))                            ; 无装箱的机器加法
```

SBCL 的编译器**免费送你一半**：它自己做类型推理（`type-of` 返回精确区间
就是证据，04 章）。声明的作用是把「编译器不确定」的地方钉死。
诊断利器：`(disassemble #'f)` 直接看汇编——有没有装箱循环一目了然。

**两条边界**：

- `the` 是**承诺**不是检查（13 章）——错了是未定义行为；
- 别为了速度把 `safety` 降到 0 再到处 `the`——那等于关掉所有运行期检查。

## 26.3 优化级别

```lisp
(declaim (optimize (speed 3) (safety 1) (debug 1)))
```

| 质量 | 效果 |
|---|---|
| `(speed 3)` | 全力优化 |
| `(safety 0)` | 关运行期检查（危险） |
| `(debug 3)` | 保留完整栈帧——**会关掉尾调用优化**（11 章实测：互递归 1000 万层爆栈） |

调优常见组合 `(speed 3) (safety 1) (debug 1)`；开发期保持默认。

## 26.4 内联

```lisp
(declaim (inline fast-add))     ; 调用点直接展开，省调用开销
```

适合小函数；代价是重编译范围变大。编译器对已知类型的局部函数也会自己做。

## 26.5 内存与分配

- `0 bytes consed` 是好代码的勋章：复用缓冲（`map-into`、fill-pointer 向量）
  比「每次 new」快得多；
- `(sb-ext:gc)` 手动触发；长驻服务关注 `get-bytes-consed` 的增速；
- 列表 vs 向量的代价表在 08 章——按下标访问换向量是「免费的」优化。

## 26.6 数值计算优化（实测套路）

三个层层递进的版本（套路分解，对照示例 26 第 6 节的 `fixnum-sum` /
`float-sum` / 矩阵乘实测）：

```lisp
;; ① 朴素版：通用算术，全类型检查，每步可能装箱
(defun sum-01 (n) (loop for i from 1 to n sum i))

;; ② 声明版：钉死类型，编译器生成无装箱的机器加法
(defun sum-02 (n)
  (declare (type fixnum n))
  (let ((acc 0))
    (declare (type fixnum acc))
    (loop for i fixnum from 1 to n
          do (incf acc i))
    acc))

;; ③ 内联+局部声明：热循环里连循环变量的类型都钉死
(declaim (inline sum-03))
(defun sum-03 (n)
  (declare (optimize (speed 3) (safety 0))
           (type fixnum n))
  (let ((acc 0))
    (declare (type fixnum acc))
    (dotimes (i n acc)
      (incf acc (the fixnum (1+ i))))))
```

验证手段：`(disassemble #'sum-02)`——汇编里没有对
`GENERIC-+` 的调用、没有内存分配指令，就说明类型钉死了。
反例同样有教育意义：去掉声明后汇编里每步循环都是一次函数调用 + 装箱。

**safety 0 的代价要有意识**：`sum-03` 传一个 bignum 会直接产生错误结果或崩溃
（13 章「the 是承诺」）——发布版宁可 `(safety 1)`。

## 26.7 常见性能陷阱（示例 26 第 7 节全列）

| 陷阱 | 后果 | 修法 |
|---|---|---|
| 循环里 `nth` | O(n²) | 向量 + aref |
| `append` 累积 | 每次全量拷贝 | `push` + 最后 `nreverse` |
| 字符串反复 concatenate | 分配风暴 | `with-output-to-string` |
| 动态变量在热循环里 | 查找开销 | 词法变量 |
| 装箱算术 | 每步分配 | fixnum 声明 |
| `safe` 版本的神秘崩溃 | safety 0 + the 说谎 | 开回 safety 1 定位 |

## 26.8 基准的正确姿势

- 单次 `time` 是噪音——跑多轮取中位数；
- 对比优化前后用**同一函数**的热加载（REPL 里 redefine 即可，21 章的交互循环）；
- 别比较 SBCL 与 CLISP 的微基准绝对值——编译型 vs 字节码解释（01 章），
  那是「选实现」的输入，不是「写代码」的输入。

## 26.9 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| sb-profile 那行 overhead 打进 stderr | --script 模式 | 统一 --load |
| 优化后结果悄悄错了 | safety 0 + the 撒谎 | 定位时开 safety 1 |
| 尾递归突然爆栈 | debug 3 关了 TCO | 调优组合别开 debug 3 |
| `REQUIRE SB-SPROF` 没报错但 SB-PROFILE 报 | 后者在核心里 | 分清核心/contrib（23 章） |
| 微基准忽快忽慢 | 单次计时噪音 | 多轮取中位数 |
