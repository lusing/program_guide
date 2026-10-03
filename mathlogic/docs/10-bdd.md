# 10 BDD：布尔函数的图表示

> 对书：Ben-Ari 3e Ch5 / Huth&Ryan Ch6

BDD 把布尔函数编码成决策图：叶是常量，节点按变量分岔。
本章的教学表示是**深度编码**——DNode 顶是变量 0，子树配
`eshift e`（变量整体 +1），无需在节点里存变量索引。

## 旗舰三条（Coq 通道，零公理）

```
apply_correct   teval e (applyd op b1 b2) = op (teval e b1) (teval e b2)
mkvar_correct   teval e (mkvar v) = e v
mk_correct      teval e (mk f) = eval e f   ——公式→BDD 编译保语义
```

`apply` 叶/节点交叉四情形逐一收，`mapleaf` 是叶情形的统一出口；
`mkvar (S v) = DNode (mkvar v) (mkvar v)` 的「复制消歧」：
顶变量与内容无关，`if e 0 then t else t ≡ t` 把无关测试吸收掉。

## 本章最有价值的坑：坍缩与深度编码相克

想教「hi = lo 时节点坍缩」（ROBDD 的核心化简），但在深度编码下：

- 坍缩返回子树 `lo`——它在下一层，语义配 `eshift e`，变量错位；
- 正确坍缩须配 `lift` 垫回一层，而 `lift (DNode lo hi) =
  DNode (lift lo) (lift hi)` 的语义要求顶变量无关——循环依赖；
- 坍缩**安全条件**恰好是「子树语义与顶变量无关」（如 mkvar 的
  复制消歧）——Coq 教学版干脆不化简，规模公式 `2^(v+2) - 1` 直说。

## 树形 vs DAG：Lean 现场的徒劳证明

```
example : (chain 5 : DTree) = mkvaru 5 := by rfl   ← 定义相等！
#eval bsize (mkvaru 20)                             -- 4194303
```

「手工最简链」chain 在树形表示里与满树 mkvaru **逐节点相同**
（bsize 数两遍，共享不可见）——这是 ROBDD 必须做成 DAG
（节点表 + 唯一表）的根本原因，也是教学树到工业实现（CUDD）
的距离。

## 坑位速记（本章实测）

- **Coq**：`teval`/`mapleaf`/`applyd` 的语义引理全部要
  **对 e generalization**（IH 需配 `eshift e` 实例）——
  `induction b` 时把 e 放在目标之后（`forall b e f, ...`）；
  `lia` 对 `2 ^ n` 黑盒原子可用，但 `2 ^ S n` 与 `2 ^ n` 是两个
  原子——`S (v'+2)` 形状要 `two_pow_pos` 补正性后 lia 才收；
  `decide equality` 产生的目标数不定（bool 可能自动解决）。
- **Lean**：`cases h : e 0 <;> simp [...]` 后剩 `e 0 = true/false`
  ——simp 列表要加 `h` 才消；两个 def 若逐构造子相同则 `rfl`
  可证「定义相等」——正好用作「树形无共享」的机器证据。
