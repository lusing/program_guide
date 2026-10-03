# 09 DPLL 与 SAT

> 对书：Ben-Ari 3e Ch6 / Huth&Ryan §1.5-1.6

子句集 = 文字的表；DPLL 三板斧：

1. **冲突检测**——出现空子句即回溯；
2. **单元传播**——单文字子句逼出赋值；
3. **分裂**——取首文字，真/假两路递归。

化简 `fmlStep` 一石二鸟：真文字 → 删子句；假文字 → 删文字。

## 实现的关键反转（07/08 章教训的结晶）

赋值**不在过程里累积，而在返回时用 upd 复合装配**：

```
dpll k (fmlStep F n s) 返回 Some e  ⟹  整体返回 Some (upd e n s)
```

从根上消灭 07 章那种「lookup 遮蔽/一致性问题」——化简式无该变元文字
（`fmlStep_var_free`）保证 upd 不碰已满足的子句语义。

## 旗舰三定理（Coq 通道，零公理）

```
dpll_sound     报 Some e 则 e 真满足
dpll_complete  有模型且 msize F < fuel 则不报 None
dpll_decides   dpll (S (msize F)) F = None ⟺ 全体 e 不可满足
```

度量 = 文字总数 `msize`：每次单元/分裂都删掉至少一个文字
（`fmlStep_size`：决定变元在子句中有出现）。complete 的分裂分支
按模型落点反证：`e n = negb s ∨ e n = s`，哪路 None 就用哪路的
化简式 + IH 逼出矛盾——**无须重排尝试顺序**。

## 三家分工

| 通道 | 内容 |
|---|---|
| Coq | 完整三定理链（clauseStep/fmlStep 的 sat_back/sat_fwd/var_free/size 四组引理 + upd 不变性） |
| Lean | 同构实现 + native_decide 现场（模型可直接 #eval 读出验证） |
| Isabelle | 同构实现 + eval 现场；化简引理手动 Isar 六轮未收口——如实记边界 |

## 坑位速记（本章实测）

- **Coq**：
  - `xorb_false_iff` 不存在——xorb 的真/假分解在 8.20 里要走
    `destruct (fst l0); destruct s` 布尔四路 bash；
  - match-on-option 的假设先 destruct 内层（eqb/xorb/递归值）才可用；
  - `clauseStep_size_le` 的 apply 会撞目标 `S (csize rest)`——
    改 `pose proof` + lia；
  - `Nat.eqb (e n) s` 里两边是 bool——要先 `destruct (e n)`；
  - `dpll_sound _ _ E` 的下划线数 = 显式参数数（fuel/F/e 三个）。
- **Isabelle**：
  - 字面 Unicode（× ⇒ ≠ ∧ ∨ ¬ λ）在本机词法层 **Inner lexical error
    二次实锤**——全部 ASCII/`\<xxx>` 转义；
  - `has_conflict` 的 `∃c ∈ set F` 让 eval 代码生成报
    Ill-typed instantiation——改 `list_ex is_empty F`；
  - `rule: clause_step.induct` 与 `arbitrary:` 相互打架；
  - lit_val 展开后的 `if s then s else ¬s`（s 是变量）卡死
    simp/auto——这是六轮未收口的根因。
- **Lean**：`l.1 != s` 是 Bool 的异或语义（`≠` 是 Prop 不能用在
  代码分支）；嵌套 match 的 option 层层展开 Lean 比 Coq 温顺。
