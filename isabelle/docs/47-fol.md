# 47 · FOL：一阶逻辑对象逻辑

对应示例：`../examples/T47_fol.thy`（IsaFOL 会话，父堆 FOL）

## 47.1 一句话概括

Isabelle 是**逻辑框架**：HOL 只是一种对象逻辑。FOL 家族是
logics 手册（doc/logics.pdf）的第一站——`IFOL`（直觉主义）+
经典公理 = `FOL`。对 HOL 用户的价值：看清哪些定理依赖经典逻辑
（`P ∨ ¬ P` 在 HOL 里白给，在 IFOL 里**不存在**证明），
并体会"同一内核，随便换逻辑"。

## 47.2 自然演绎核心与经典分界

```isabelle
lemma lem_fol: "P ∨ ¬ P"
  by blast

lemma dn_dn: "¬ ¬ (P ∨ ¬ P)"
  by iprover
```

`blast` 在 FOL 里可用（表推演机，经典）；`iprover` 是直觉主义
证明器（dn_dn 用它证——构造性成立）。IFOL 里证经典命题
**不会报错，只会永远证不出**。

## 47.3 量词四件套的手动挡

```isabelle
lemma all_implies:
  fixes P Q :: "'a ⇒ o"
  assumes A: "∀x. P(x) ⟶ Q(x)" and B: "∀x. P(x)"
  shows "∀x. Q(x)"
proof (rule allI)
  fix x
  from A have "P(x) ⟶ Q(x)" by (rule spec)
  moreover from B have "P(x)" by (rule spec)
  ultimately show "Q(x)" by (rule mp)
qed
```

两个实测语法雷：

- 谓词要显式声明个体类型 `fixes P :: "'a ⇒ o"`——**现代 FOL
  没有老教程里的 `i` 类型**（实测 `Undefined type name: "i"`）；
- **`P(x)` 函数式写法**：官方公理全这么写。`P x` 空格应用在
  量词体里直接解析失败（实测 Inner syntax error，位置从 x 开始
  ——极具误导性）。

## 47.4 与 HOL 的对照表

| 命题 | HOL | FOL |
|---|---|---|
| P ⟶ P | by (rule impI) | 同左（最小逻辑层） |
| P ∧ Q ⟷ Q ∧ P | by blast | by blast |
| P ∨ ¬ P | 一步 | by blast（经典公理）|
| (∀x. P(x)) ⟶ P(a) | by auto | 手动 allI/spec |

工程代价：HOL-Library/Eisbach 全不可用，`datatype` 等包也没有
（那些是 HOL 的）；`metis` 在 FOL 里不可用（实测），
`blast`/`iprover` 可用。

## 47.5 坑位清单（实测）

1. `i` 类型不存在——个体用默认 sort 的类型变量，谓词 `'a ⇒ o`。
2. **`P x` 空格应用解析失败**——用 `P(x)`（ZF 同款，第 48 章）。
3. IFOL 里经典命题永远证不出（不报错）；要经典规则换 FOL。
4. `metis` 不可用；`blast` 可用。
5. 多方法串联 `by m1 m2` 之后**另起一行的括号**是 outer syntax
   错误（keyword ( expected）——用 apply 脚本分行。

## 47.6 与其他章的接口

- 第 50 章自然演绎：IFOL 是它最纯的舞台。
- 第 48 章 ZF：FOL 之上的公理集合论。
- 第 31 章 inductive：FOL 里也有（谓词变元版本）。
