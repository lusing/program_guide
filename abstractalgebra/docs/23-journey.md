# 23 一个数学旅程：拉丁方、幻方、设计与射影平面

**对应原书 §3.9（pp. 305-320）。**

---

## 23.1 代数的娱乐场

原书以"数学旅程"收束第三篇——四个组合对象全部由**群与域的语言**
统一描述。这不是消遣：拉丁方是实验设计的引擎（Fisher 的统计革命），
射影平面是有限几何的门厅，幻方连接数论与算法。**组合结构 = 群论
的离轴应用**是本节的论点。

## 23.2 拉丁方

> **定义** n 阶拉丁方是 n×n 数表，每行每列恰含符号 1..n 各一次。

**群论视角**：任何群的凯莱表都是拉丁方（消去律保证行列无重复）！
循环群给出"标准"拉丁方 L(i,j) = i+j mod n。反之，满足结合律的
拉丁方是群表（拟群/幺半群的分类话题——凯莱表的"结合性检查"
第 09 章已机器化）。

> **命题 3.9x** 存在 n 阶拉丁方对任何 n ≥ 1（ℤ_n 表）。
> **正交对（MOLS）** 两拉丁方 L, M 正交：序对 (L(i,j), M(i,j))
> 遍历全部 n² 个组合恰好一次。

**欧拉 36 军官问题的翻案**：欧拉猜不存在正交的 6 阶拉丁方对
（"两个 6 阶拉丁方正交不可能"）——1900 年 Tarry 手工穷举证实；
但 n = 2, 6 之外**全部存在**（Bose–Shrikhande–Parker 1960 反欧拉）。
机器通道（下节）用 CLPFD 复现 6 阶不存在（受控规模）与 5 阶存在。

**有限域的礼物**：GF(q) 上 L_a(i,j) = ai + j 对 a ≠ 0 两两正交
——素数幂阶 q 一次拿到 q − 1 个两两正交的拉丁方族。36 军官的
6 = 非 2 非 3 的"非素幂"身份不是巧合。

## 23.3 幻方

> **定义** n 阶幻方：1..n² 填入 n×n，每行每列每对角线和 =
> n(n²+1)/2（幻和）。

奇数阶的**暹罗法**（de la Loubère，1687）：从顶行中央出发，
"右上→撞墙回绕→撞占左移"——n = 5 十五行内手推。群论视角：
暹罗法是 ℤ_n × ℤ_n 上的线性枚举（步向量 (1,1) 与破撞向量 (0,−1)），
幻和 = 行和的 n 倍平均 = n·(n²+1)/2。幻方存在性（n ≥ 3）与
构造的机械化为机器通道的主菜。

## 23.4 试验设计与区组

> **定义** (v, k, λ)-设计：v 点集上的区组族（每块 k 点），任两
> 点恰同现于 λ 块。特别地 **Steiner 三元系** STS(v) = (v, 3, 1)。

**存在性**（Kirkman 1847）：STS(v) 存在 ⟺ v ≡ 1, 3 (mod 6)。
**Fano 平面** = STS(7)：7 点 7 线每线 3 点每点 3 线——最小射影
平面的化身。**从域造设计**：GF(q) 上仿射点集 {(x,y)} 的直线族
给出 2-(q², q, 1) 设计——素数幂再次批量供货。

## 23.5 射影平面

> **定义** n 阶射影平面：n² + n + 1 点与同样多线，每线 n+1 点、
> 每点 n+1 线、两线恰交一点。

n = 2：Fano 平面（7 点 7 线）；素数幂阶由 GF(q) 齐次坐标构造
（PG(2,q)）。**n = 6 不存在**（Bruck–Ryser 1949 的数论障碍 +
Lam 1989 计算机证明 n = 10 不存在）——与 36 军官的 6 呼应，
"非素幂阶的存在性"至今是组合学的最大悬案之一（n = 12 未决）。

**结构统一**：Fano 平面 = STS(7) = PG(2,2)；GF(q) 同时生产
正交拉丁方族、设计与射影平面——**域是组合建筑的预制件工厂**。

## 23.6 机器验证一：Julia——构造与穷举的交响

**文件：`examples/julia/23_designs.jl`**：

```julia
"""暹罗法造奇数阶幻方。"""
function siam_magic(n::Int)
    n % 2 == 1 || error("奇数阶")
    M = zeros(Int, n, n)
    i, j = 1, (n + 1) ÷ 2
    for k in 1:n^2
        M[i, j] = k
        i2, j2 = mod1(i - 1, n), mod1(j + 1, n)      # 右上（回绕）
        if M[i2, j2] != 0
            i2, j2 = mod1(i + 1, n), j               # 撞占：下移
        end
        i, j = i2, j2
    end
    M
end

"""GF(q) 正交拉丁方族：L_a(i,j) = ai + j。"""
mols(q, a1, a2, i, j) = (a1 * i + j) % q, (a2 * i + j) % q
```

断言组：(1) n = 3, 5, 7 幻方全查（行列对角线和 = 幻和）；
(2) **GF(5) 的 4 个 MOLS 两两正交**（25 个序对无重复逐族验证）；
**GF(4)（第 22 章实现）同样给出 3 个 MOLS**——域算术的复用；
(3) ℤ₆ 上"线性构造"的正交性破产（a = 1: 序对重复）——36 军官
阴影的机器侧写；(4) **STS(7) = Fano 平面**：手工线表
{{1,2,3},...} 验证每对点恰共一线；STS(9)（仿射平面 AG(2,3) 的
12 条线）由 ℤ₃² 直线族程序生成并验证；(5) 5 阶射影平面
PG(2,5) = 31 点 31 线由 ℤ₅ 齐次坐标生成，每线 6 点核对。

## 23.7 机器验证二：Python 与 Prolog

**文件：`examples/python/23_designs.py`**：复算幻方/MOLS/设计；
补充**拉丁方正交性搜索**：对 4 阶，随机化贪心 + 全量判定找到
正交对；对 6 阶，给出受控规模的不存在演示（CLPFD 思路的
列剪枝版本，或直接引 Tarry 结论的引用式断言——如实标注）。

**文件：`examples/prolog/23_designs.pl`**——CLPFD 主场：

```prolog
% n 阶拉丁方：all_different 约束行列
latin_square(N, L) :-
    length(L, N * N),
    L ins 1..N,
    findall(R, (between(1, N, I), slice(L, N, I, R)), Rows),
    maplist(all_distinct, Rows),
    findall(C, (between(1, N, J), cslice(L, N, J, C)), Cols),
    maplist(all_distinct, Cols),
    label(L).

% 幻方：拉丁方约束 + 行列对角线和 = 幻和 + 全元素不同
magic(N, L) :- ... sum(R, #=, S) 诊断每行 ...
```

文件断言：3 阶幻方求解（CLPFD 直接解出 8 个旋转版本中的全部
解并按幻和核对）；4 阶拉丁方生成 + 与给定 M 正交的对搜索
（all_different on 序对编码）；STS(7) 的每对共线检查。

## 23.8 机器验证三：Lean——幻和的等式

**文件：`examples/lean/Abstractalgebra/Ch23Designs.lean`**。
组合穷举不是 Lean 的主场；文件验证**幻和的数论内核**：

```lean
-- 幻和 = n(n²+1)/2 是整数（n(n²+1) 恒偶：n 与 n²+1 一奇一偶）
example (n : ℕ) : 2 ∣ n * (n ^ 2 + 1) := by
  rcases Nat.even_or_odd n with h | h
  · exact Nat.even_mul.mpr ⟨h, by decide⟩
  · -- n 奇 ⟹ n² + 1 偶
    have : Nat.Even (n ^ 2 + 1) := by
      have h2 := h.pow 2    -- n² 奇
      exact Nat.even_add.mpr (by rw [Nat.even_iff] at *; omega)
    exact Nat.even_mul.mpr ⟨by decide, this⟩
```

（配对技巧：n 奇时 n² 奇、n²+1 偶。）Fano 平面的 7 线 7 点 3-
入射结构以 0/1 关联矩阵的 decide 断言呈现。

## 23.9 要点回顾

1. 群表 = 拉丁方（消去律）；循环群给标准表；GF(q) 批量供应
   q−1 个两两正交的拉丁方（MOLS）。
2. 6 阶正交对不存在（Tarry）而素数幂阶全存在——欧拉猜想的
   大反例（Bose–Shrikhande–Parker）。
3. 幻方奇数阶有暹罗法的线性构造；幻和 n(n²+1)/2 的整性是
   平凡而优美的数论事实。
4. 设计（STS、区组）与射影平面共享 GF(q) 工厂；Fano = STS(7) =
   PG(2,2)；n = 6 与 n = 10 的不存在是深水区（Bruck–Ryser、Lam）。
5. 组合结构是群/域的"应用题库"——第三篇以娱乐场收尾，第四篇
   （线性代数）回到主战场。

*对应示例：`examples/lean/Abstractalgebra/Ch23Designs.lean`、
`examples/julia/23_designs.jl`、`examples/python/23_designs.py`、
`examples/prolog/23_designs.pl`。*

---

上一章：[22 商环与有限域](22-quotient-rings-finite-fields.md) · 下一章：[24 向量空间](24-vector-spaces.md)
