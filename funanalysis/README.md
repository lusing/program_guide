# 泛函分析：编程与自动证明教程

以 John B. Conway《A Course in Functional Analysis》（第二版，GTM 96）为纲的
中文泛函分析教程。全书 11 章 + 附录全覆盖（48 章，已收官），每个定理
有三种化身：**机器证明**（Lean 4 + mathlib4 主证、Isabelle/HOL 对拍）、
**精确离散模型**（Prolog 有限维影子）、**数值实验**（Julia + Python/scipy）。

## 目录

- [总体规划（章表 × 通道矩阵）](PLAN.md)
- [00 导引：泛函分析与机器证明](docs/00-intro.md)
- [01 预备知识：拓扑、网、Zorn 与 Baire 纲](docs/01-prelim.md)
- [02 内积空间初步](docs/02-inner-product.md)
- [03 正交性与投影定理](docs/03-orthogonality.md)
- [04 Riesz 表示定理](docs/04-riesz.md)
- [05 标准正交集与基](docs/05-orthonormal-bases.md)
- [06 同构分类、圆周 Fourier 变换与直和](docs/06-fourier-sums.md)
- [07 有界算子与 B(ℋ)](docs/07-bounded-operators.md)
- [08 伴随算子](docs/08-adjoint.md)
- [09 投影、幂等与不变子空间](docs/09-projections.md)
- [10 紧算子](docs/10-compact-operators.md)
- [11 紧自伴算子的对角化](docs/11-diagonalization.md)
- [12 应用：Sturm-Liouville 系统](docs/12-sturm-liouville.md)
- [13 紧正规算子的谱定理与泛函演算](docs/13-compact-normal.md)
- [14 赋范空间与 Banach 空间](docs/14-banach-spaces.md)
- [15 线性泛函与 Hahn-Banach 定理](docs/15-hahn-banach.md)
- [16 应用三讲](docs/16-applications.md)
- [17 对偶理论](docs/17-duality.md)
- [18 开映射与闭图像定理](docs/18-open-mapping.md)
- [19 一致有界原理](docs/19-uniform-boundedness.md)
- [20 局部凸空间](docs/20-locally-convex.md)
- [21 几何 Hahn-Banach：分离定理](docs/21-separation.md)
- [22 归纳极限与分布](docs/22-distributions.md)
- [23 弱拓扑与 Alaoglu 定理](docs/23-weak-topology.md)
- [24 Stone-Čech 紧化](docs/24-stone-cech.md)
- [25 Krein-Milman 与 Stone-Weierstrass](docs/25-krein-milman.md)
- [26 不变子空间与不动点](docs/26-fixed-points.md)
- [27 算子的伴随与 Banach-Stone 定理](docs/27-adjoint-banach.md)
- [28 紧算子、不变子空间与弱紧算子](docs/28-compact-banach.md)
- [29 Banach 代数：理想与商](docs/29-banach-algebra.md)
- [30 谱与预解式](docs/30-spectrum.md)
- [31 Riesz 泛函演算](docs/31-riesz-calculus.md)
- [32 紧算子的谱理论](docs/32-compact-spectrum.md)
- [33 交换 Banach 代数与 Gelfand 理论](docs/33-gelfand.md)
- [34 C* 代数与 Gelfand-Naimark 定理](docs/34-cstar-algebra.md)
- [35 正元、理想、表示与 GNS 构造](docs/35-positive-elements.md)
- [36 谱测度与交换 C* 代数的表示](docs/36-spectral-measures.md)
- [37 谱定理](docs/37-spectral-theorem.md)
- [38 星循环算子、应用与 B(H) 上的拓扑](docs/38-topologies-bh.md)
- [39 von Neumann 代数与泛函演算终章](docs/39-von-neumann.md)
- [40 不变子空间与重数理论](docs/40-invariant-subspaces.md)
- [41 无界算子基础](docs/41-unbounded-basics.md)
- [42 对称、自伴与 Cayley 变换](docs/42-symmetric-selfadjoint.md)
- [43 无界谱定理与 Stone 定理](docs/43-stone-unbounded.md)
- [44 Fourier 变换、微分算子与矩问题](docs/44-fourier-moments.md)
- [45 Fredholm 算子与指标](docs/45-fredholm.md)
- [46 本质谱与谱的精细分析](docs/46-essential-spectrum.md)
- [47 CHEATSheet：全定理地图与通道速查](docs/47-cheatsheet.md)

全书 48 章（00 导引 + 01-46 正文 + 47 CHEATSheet）已收官。

## 通道与验证

| 通道 | 位置 | 工具 |
|---|---|---|
| Lean 4 | `examples/lean/`（单一 lake 工程） | Lean 4.33.1 + mathlib4 v4.33.1（H:/Lang/lean4 发布版钉版路径依赖） |
| Isabelle | `examples/isabelle/`（每章一会话） | Isabelle2025-2（HOL-Analysis） |
| Julia | `examples/julia/` | Julia 1.13 + LinearAlgebra |
| Python | `examples/python/` | Python 3.13 + numpy/scipy |
| Prolog | `examples/prolog/` | SWI-Prolog（主）+ GNU Prolog（WSL 抽查） |

全量验证：

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

对账协议：`build.ps1` 输出 章 × 通道 矩阵，任一预期单元失败即退出码非 0。

## 阅读方式

只读 `docs/` 即可完成学习：正文自包含地提炼原书内容（定理均给完整证明或
完整讲解），所有示例代码在正文中引用并逐段讲解；`examples/` 是可运行的
验证副本。原书编号（如 Conway I.3.4）仅作溯源注记。
