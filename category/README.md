# 范畴论指南（category）：从范畴到层

面向**会编程、想系统学范畴论**的读者。以三本读本为骨架
（贺伟《范畴论》、《高级范畴论》、Simmons《An Introduction to
Category Theory》习题解答版），横跨 **Coq / Agda / Lean 4**
三种实现讲解。

**章号 = 示例编号**——11–14、16、18 章（双语）与 15、17、19–22 章
（文档章）之外，每章对应 `examples/NN_name/` 里经三通道
（coqc 8.20.1 / WSL Agda 2.8.0+stdlib 2.3 / Lean 4.25.0）
机器验证的完整文件。

> 核心理念：**范畴论 = 泛性质的语言**。范畴（01–04）→ 函子与
> 自然变换（05–07）→ Yoneda（08）→ 极限（09–12）→ 伴随
> （13–15）→ 电脑科学线（16–18）→ 高级主题（19–21）→ 收束（22–23）。

## 目录结构

```text
category/
├── README.md          本文件
├── build.ps1          三通道验证（-All/-Chapter/-Lang/-File/-List/-Clean）
├── CHEATSheet.md      速查 + 精选坑位
├── docs/              23 章教程
└── examples/          15 个章目录（章号 = 示例编号）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识范畴论](docs/01-intro.md) | Category record 三家 + 四例 | 三家 |
| [02 反范畴与对偶](docs/02-opposite.md) | 定律互译的机器版；预序范畴 | 三家 |
| [03 特殊态射](docs/03-arrows.md) | mono/epi/iso + 分裂⇒单（零公理） | 三家 |
| [04 图与交换图](docs/04-diagrams.md) | 图→自由范畴；交换=方程 | 三家 |
| [05 函子](docs/05_functors.md) | List/hom 函子；真宇宙多态实锤 | 三家 |
| [06 自然变换](docs/06-natural.md) | Godement 积；record 相等三家分岔 | 三家 |
| [07 范畴等价](docs/07-equivalence.md) | 全忠实+本质满；Pfn≃Set⊥ | 三家 |
| [08 Yoneda 引理](docs/08-yoneda.md) | **旗舰**：往返双程完整机器 | 三家 |
| [09 积与余积](docs/09-products.md) | 泛性质唯一到同构（零公理） | 三家 |
| [10 等化子与拉回](docs/10-pullbacks.md) | 单态射的拉回仍是单态射 | 三家 |
| [11 极限一般理论](docs/11-limits.md) | 常值函子；二元图极限=积 | 双语 |
| [12 连续函子](docs/12-continuous.md) | Hom(c,-) 保积（Yoneda 推论） | 双语 |
| [13 伴随](docs/13-adjunctions.md) | 三角恒等式⟹hom-双射 | 双语 |
| [14 自由与遗忘](docs/14-free.md) | 图上自由范畴的泛性质 | Coq |
| [15 伴随与极限](docs/15-adjlimits.md) | RAPL/AFT/反射子范畴 | 文档 |
| [16 Cartesian 闭](docs/16-ccc.md) | curry 双射（TyCat） | Coq |
| [17 λ 演算范畴](docs/17-stlc.md) | STLC⟷CCC；演绎系统 | 文档 |
| [18 单子](docs/18-monads.md) | Set 级单子 + List 实例（零公理） | Coq |
| [19 幺半与富范畴](docs/19-monoidal.md) | 五边形连贯性 | 文档 |
| [20 加法/Abel 范畴](docs/20-abelian.md) | 贺伟第 4 章公理表 | 文档 |
| [21 层与拓扑斯](docs/21-sheaves.md) | 粘合条件/Grothendieck 拓扑 | 文档 |
| [22 压轴串联](docs/22-capstone.md) | 泛性质-唯一性-Yoneda-对偶-伴随 | 文档 |
| [23 坑位与书目](docs/23-pitfalls.md) | 总清单 + 三书导读 + 速查 | — |

## 工具链（本机实测）

| 通道 | 工具 | 判定 |
|---|---|---|
| Coq | coqc 8.20.1（Windows；拷贝 ex_ 前缀） | exit 0 + 无 Error |
| Agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | exit 0 + 无 error/warning |
| Lean | lean 4.25.0 standalone | exit 0 + 无 error:/warning: |

```powershell
cd category
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

## 已知边界（诚实清单）

- **record 相等三文化**（06/08 章核心）：NT 的 nlaw 字段依赖
  ncomp——Coq 止步于分量级、Agda 走 setoid（_≈NT_）、Lean 用
  结构 η+内核 PI 拿到完整 record 相等；Yoneda 往返 2 的完整版
  仅 Lean。
- Agda 的 TyCat 纤维积唯一性需证明无关性——10 章 Agda 版止步
  于抽象定理。
- 15/17/19/20/21/22 为文档章：RAPL、Beck 定理、五边形连贯性、
  层化的机器化需要函子范畴的完整 record 级相等 + 极限一般机器
  （README 记录的延伸路线）。
- funext 记账：Coq 公理 / Agda postulate / Lean 核心定理
  （[Quot.sound, propext]）——每章 Print Assumptions/#print 公示。
- 其他版本（Coq 9.x / Agda 3 / Lean 4.3x）未测。
