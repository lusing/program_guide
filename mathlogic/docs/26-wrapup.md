# 26 收官：SAT→SMT→MC→ITP 图景 + 总坑位清单 + 八书导读

> 本教程的终点站（本轮 H&R 扩充后覆盖 34 章）。25/30 章走完
> 命题→谓词→元理论→程序验证，27-34 章补全 H&R 独有的时态/
> 模态/符号线——这一章把碎片拼回全景：自动化频谱、六通道总
> 坑位、八书导读与 H&R 章节映射。

## 一、自动推理的频谱（SAT→SMT→MC→ITP）

```
完全自动              ─────────────►           交互证明
SAT          SMT              模型检查        ITP
DPLL(09)     presburger(21)   CTL(24/28)      Coq/Lean/Isabelle/HOL4/Agda/HoTT
Horn(09)     Nelson-Oppen     LTL(27)         25/30 霍尔+变体
BDD(10)                       CTL*(29)        不完备性(22)住最右
归结(19)                      符号MC+μ(34)    泥孩子(33)
```

**模型检查三站式**（本轮扩充新增）：显式标记（24）→ 工作流与
公平性（28：反例轨+饥饿+宣告过滤）→ 符号 μ 演算（34：preE+
不动点编码）——表达力在 29（CTL*）处再分一档，与 21 章 ESO
天梯同构。模态线（31-33）则是「逻辑工程」的完整案例：K →
对应理论选型 → KT45n 知识应用。

**频谱的本质是「表达能力 vs 自动化程度」的交易**：

- **SAT**（09 章 DPLL）：命题逻辑，NP 完全但工程上惊人地快。
  单元传播 = `upd` 复合装配——本教程把它做成零公理定理。
- **BDD**（10 章）：同态压缩的命题语义——树形 vs DAG 的坍缩
  在现场实录里裸奔。
- **SMT**（21 章）：SAT 骨架 + 理论求解器（等式、算术、数组）。
  presburger 在 Isabelle 里是 `by presburger` 一行——但它的
  可判定性证明本身住在元理论那侧。
- **模型检查**（24 章）：时序逻辑 + 有限状态空间 = 算法。
  AG/EU 的不动点刻画（Knaster-Tarski）是 20 章 T_P 单调性的
  亲兄弟。
- **ITP**（全部 25 章）：任意数学，人类出点子机器查证明。
  22 章的不完备性定理恰好是这个频谱的「宪章」——没有任何
  自动系统捕获全部真理，所以交互证明永有一席之地。

23 章的完备性（Henkin 构造）是另一头的宪章：一阶逻辑的证明
系统不多不少刚好够用——SAT/SMT/归结/MC 的**可靠性**都从它
的证明侧借来合法性。

## 二、总坑位清单（六通道 26 章精选）

### Coq（Rocq 9.1）

- `apply (proj1 (iff…)) in H` 会 shelve 前提目标——Qed 爆
  open goals（ch01）；解法 destruct + pose proof
- `destruct eqn:` 分支序 = 模式序（ch05）；destruct 会替换
  目标里的 scrutinee（ch15）
- `lia` 把 2^S n 与 2^n 当两个原子（ch08）；`hd` 与 stdlib
  类型冲突（ch24）；Python 转义的字符串 `/\` 被吃（ch17）
- remember + revert 让方程进归纳动机（ch25 的 while 规则）

### HoTT（Rocq 9.1 + Coq-HoTT）

- 顶层无 Prelude——`Require Import HoTT.HoTT`（旧版布局）
- False_ind/Empty_rect 双失败 → set + destruct Empty（ch04）
- 截断当「丢标签」读——析取性质的直觉主义证法（ch12）

### Lean 4（core 无 Mathlib）

- `lemma` 不是命令关键字（ch25）——全用 `theorem`
- `while` 是 do 记法保留字（ch25）
- induction 拒绝构造子头索引（ch25）；`induction … with`
  构造子字段全在前、IH 在后（ch17）；doc comment 后不能接
  #print axioms（ch13）；`‹_›` 求解器会挂死（ch13，等式 OK
  ch25）；构造子头索引的守卫 elaboration 分叉（ch25 的
  decide 统一法）
- 冒号前参数、纯 Nat 减法截断（typetheory 教程的坑在此复用）

### Agda（2.8 + stdlib 2.3）

- with 定义的函数在引理处卡 with-under-with（ch25）——换
  Bool-if + cong
- `⌊ _≟_ ⌋` 的 because/Reflects 构造不做定义性归约（ch25）
  ——`_≡ᵇ_` 纯 Bool
- with 抽象 `s x` 留悬空约束 `_s _x = s x`（ch25）——with
  抽象判定本身或换 ≡ᵇ
- where 块的隐式元变量在组装位悬空（ch25）——构件提顶层
- case-tree 互卡边界（ch08）；with 只作用于子句目标（ch05）

### Isabelle/HOL（2025-2 Windows）

- 字面 Unicode 词法坑（ch04 二次实锤）；`∃c∈set` 害 eval
  （ch24）；induction 与 arbitrary 打架（ch24）
- `lemma[of a b]` 实参按变量出现顺序（ch01）
- 构造子头索引要显式实例化 + arbitrary（ch25）；auto 深度
  不够换 blast（ch25）

### HOL4（develop + Poly/ML 5.9.2）

- `bin/hol run` 是唯一可信入口（REPL 管道假绿）；metis
  爆炸时 hol run **静默中止**（exit 0 无错误输出，ch25）
- 战术位引文是静态上下文 elaboration——目标绑定变量看不见
  （ch25 全类型注解救命；`!s1 s2.` 注解版反而解析失败）
- REPEAT STRIP_TAC 双向工作（前件 ∨ 分情况、目标 ∧ 拆开，
  ch03）；DISJ1/DISJ2 签名不对称（ch03）
- Hol_reln 返回 3 元组、strongind/cmd_11 要 fetch（ch25）；
  弱 ind 案例 Exec' 没有 exec 副推导——strongind 才能用
  （ch25）；exec 反演只能一层（级联污染，ch25）

### 工具链层

- build.ps1：switch($true) 里 `$_` 是被匹配值不是管道项
  （$tool 全 null 静默失败）；/cygdrive 路径 Substring(2)
- autocrlf 把 .sh/.agda 弄成 CRLF——.gitattributes 兜底
- PowerShell 后台命令的工作目录不持久——显式 cd

## 三、八书导读（按本教程使用方式）

| 书 | 用法 | 对应章 |
|---|---|---|
| Huth & Ryan《Logic in Computer Science》2e | **全教程主纲**（本轮扩充后 34 章全覆盖其 ch1-6） | 全书 |
| 同书中文版（哈斯/瑞安） | 术语对照（对照表见 CHEATSheet） | 同上 |
| Ben-Ari 3e《Mathematical Logic for CS》 | 演算主线：G 矢列/Hilbert/tableau/验证 | 05/06/07/24/25 |
| Mints《直觉主义逻辑简论》 | 直觉主义三连章 | 11-13 |
| EFT《数理逻辑讲义》 | 元理论正统：Henkin/紧致性 | 15/22/23 |
| Mendelson 6e | 完备性/不完备性细节 | 22/23 |
| 《面向计算机科学的数理逻辑》（德） | 语义与可满足性的工程视角 | 02/09 |
| Prawitz《Natural Deduction 文集》 | NJp/NJ 的证明论视角 | 03/12/16 |

**读法建议**：第一遍跟本教程走（每章先文档后代码），第二遍
按表索书补证明细节（尤其 22/23 两章的元理论），第三遍挑一条
通道（推荐 Lean 或 Coq）把 25 章的零公理旗舰亲手重写一遍。

### H&R 章节映射（本轮扩充的完整账本）

| H&R 原书 | 主题 | 本教程章 |
|---|---|---|
| ch1 命题逻辑 | ND/范式/SAT 求解器 | 01-04、08-09 |
| ch2 谓词逻辑 | ND/等式/不可判定/表达力 | 14-16、21 |
| ch3 模型检查 | LTL/CTL/CTL*/算法/公平性 | 24、27-29 |
| ch4 程序验证 | 部分与完全正确性/契约 | 25、30 |
| ch5 模态逻辑 | K/对应理论/KT45n/泥孩子 | 31-33 |
| ch6 BDD | OBDD/restrict/exists/符号 MC/μ 演算 | 10、34 |

## 四、下一步（这不是终点）

- **SAT/SMT 工程化**：minisat/cvc5 源码 + 09/19 章的算法骨架
- **证明论**：Prawitz 规范形 + 强规范化（12 章的自然延伸）
- **构造性数学**：HoTT 书（12 章的截断直觉直接可用）
- **程序验证实战**：VST/Verified SCC——25/30 章的霍尔规则
  （含变体方法）配分离逻辑
- **动态认知逻辑**：33 章的「宣告即过滤」的正式版（PAL/DEL）
- **μ 演算深水区**：34 章的带名器/嵌套 μν 与正规模语义

34 章全部验证单元（109 个）零公理或显式公理记账——这是本
教程对「机器可靠」的最低承诺。
