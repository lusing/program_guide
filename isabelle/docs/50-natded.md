# 50 · 自然演绎与证明论

对应示例：`../examples/T50_natded.thy`

## 50.1 一句话概括

Gentzen 的自然演绎是 `have/show` 背后的证明论骨架：每条逻辑
连词配**引入规则**（怎么造）与**消去规则**（怎么用）。Isar 的
`assume` 是假设开枝，`show` 是枝头结论，`obtain` 是 ∃ 消去。
本章把常用导出规则当引理证一遍——`blast` 内部的兵器谱。

## 50.2 演绎定理

"从 Γ, A 推出 B 则从 Γ 推出 A ⟶ B"在 Isabelle 里是**语法**
（assume 直接生效），对象层玩法：

```isabelle
lemma ded_style: "(A ⟹ B) ⟹ A ⟶ B"
  by (rule impI)
```

## 50.3 兵器谱两条

```isabelle
lemma disj_swap_r: "P ∨ Q ⟹ Q ∨ P"
  apply (erule disjE)
   apply (rule disjI2, assumption)
  apply (rule disjI1, assumption)
  done
```

∧E 在 Isar 里是 `obtain`；∨E 是 `cases` + 两枝 show：

```isabelle
lemma and_or_dist: "(P ∨ Q) ∧ R ⟶ (P ∧ R) ∨ (Q ∧ R)"
proof (rule impI)
  assume "(P ∨ Q) ∧ R"
  then obtain pq: "P ∨ Q" and r: "R" by blast
  from pq show "(P ∧ R) ∨ (Q ∧ R)"
  proof (rule disjE)
    assume "P"
    with r show ?thesis by (rule disjI1) simp
  next
    assume "Q"
    with r show ?thesis by (rule disjI2) simp
  qed
qed
```

## 50.4 经典等价链

```isabelle
lemma peirce_hol: "((P ⟶ Q) ⟶ P) ⟶ P" by blast
lemma dn_classical: "¬ ¬ P ⟶ P" by blast
```

Peirce 律/双非消去**依赖经典逻辑**——第 47 章的 IFOL 里证不出；
搬证明前先看逻辑。

## 50.5 坑位清单（实测）

1. `(A ⟹ B) ⟹ A ⟶ B` 的元层/对象层箭头一字之差，写反了
   impI 对不上。
2. 多方法串联写成多行括号是 outer syntax 错误——apply 脚本
   分行（第 47 章同款）。
3. 教学章手搓导出规则才有价值；工程代码直接 blast。

## 50.6 与其他章的接口

- 第 9 章逻辑规则：本体；本章是它的证明论视角。
- 第 12/13 章 Isar：ND 的语法人化。
- 第 47 章 IFOL：本章内容的构造性切片。
