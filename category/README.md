# 范畴论指南（category）：从范畴到层

面向**会编程、想系统学范畴论**的读者。以三本读本为骨架
（贺伟《范畴论》、《高级范畴论》、Simmons《An Introduction to
Category Theory》习题解答版【全书六节全谱消化】），横跨
**Coq / Agda / Lean 4** 三种实现讲解。

**章号 = 示例编号**——文档章之外，每章对应 `examples/NN_name/`
里经三通道（coqc 8.20.1 / WSL Agda 2.8.0+stdlib 2.3 /
Lean 4.25.0）机器验证的完整文件。

> 核心理念：**范畴论 = 泛性质的语言**。范畴（01–04）→ 函子与
> 自然变换（05–08）→ 逗号切片与子对象（09–12）→ 极限（13–14）
> → 伴随（15–18）→ 电脑科学线（19–21）→ 幺半与 Abel（22–23）
> → **序论线**（24–27：Galois 连接、量词伴随、自由/余自由三明治、
> 反变伴随）→ 层（28）→ 收束（29–30）。

## 目录结构

```text
category/
├── README.md          本文件
├── build.ps1          三通道验证（-All/-Chapter/-Lang/-File/-List/-Clean）
├── CHEATSheet.md      速查 + 精选坑位
├── docs/              30 章教程
└── examples/          23 个章目录（章号 = 示例编号）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [02 认识范畴论](docs/01-intro.md) | Category record；结构集配方（Pno）；预层一瞥 | 三家 |
| [03 反范畴与对偶](docs/02-opposite.md) | 定律互译；范畴 2 与主截面 | 三家 |
| [04 特殊态射](docs/03-arrows.md) | mono/epi 全谱；消去封闭；平衡反例 | 三家 |
| [05 图与交换图](docs/04-diagrams.md) | 图→自由范畴；**五角星绕两圈** | 三家 |
| [06 函子](docs/05-functors.md) | List/hom；**幂集三函子 ∃/I/∀** | 三家 |
| [07 自然变换](docs/06-natural.md) | Godement 积；eval 双对偶 | 三家 |
| [08 范畴等价](docs/07-equivalence.md) | 全忠实+本质满；Pfn≃Set⊥ | 三家 |
| [09 Yoneda 引理](docs/08-yoneda.md) | **旗舰**：往返双程完整机器 | 三家 |
| [10 逗号范畴](docs/09-comma.md) | (U↓L)；切片/箭头范畴/截面三合一 | 三家 |
| [11 积与余积](docs/10-products.md) | 泛性质唯一到同构；Set 余积=不交并 | 三家 |
| [12 等化子与拉回](docs/11-pullbacks.md) | 拉回保 mono；余等化子/核对全家福 | 三家 |
| [12 子对象、商对象与射影](docs/12-subobjects.md) | 良幂/收缩/**射影与单射**（提升公理化） | 三家 |
| [13 极限一般理论](docs/13-limits.md) | 线程法；**双塔：极限 1 / 余极限 D** | 双语 |
| [14 合流余极限](docs/14-confluent.md) | 块与结构搬运（R-集/幺半群） | Coq |
| [15 连续函子](docs/15-continuous.md) | Hom(c,-) 保积（Yoneda 推论） | 双语 |
| [16 伴随](docs/16-adjunctions.md) | 三副面孔 + Table 5.1 换位演算 | 双语 |
| [17 自由与遗忘](docs/17-free.md) | freeCat ⊣ U；**自由幺半群 List ⊣ U** | Coq |
| [18 伴随与极限](docs/18-adjlimits.md) | RAPL 完整叙事/AFT/反射子范畴 | 文档 |
| [19 Cartesian 闭](docs/19-ccc.md) | curry 双射；**ΛT 语法范畴**（R1-R18 全表） | Coq |
| [20 FL/FDS/ΛT 三范畴](docs/20-stlc.md) | 程序/证明/λ 项 = 态射三进料口 | 文档 |
| [21 单子](docs/21-monads.md) | Set 级单子 + List 实例（零公理） | Coq |
| [22 幺半与富范畴](docs/22-monoidal.md) | 五边形连贯性 | 文档 |
| [23 加法/Abel 范畴](docs/23-abelian.md) | 双积/矩阵演算/正合序列/蛇形 | 双语 |
| [24 完备预序与剩余](docs/24-posets.md) | 保 sup⟺右伴随；**闭包算子与闭元同构** | 三家 |
| [25 截面与三超幂函子](docs/25-sections.md) | **∃ ⊣ I ⊣ ∀**（量词的伴随身份） | 双语 |
| [26 幺半集：Σ ⊣ U ⊣ Π](docs/26-rsets.md) | 自由/余自由 R-集三明治 | 双语 |
| [27 反变伴随：Sierpiński](docs/27-contravariant.md) | ⇑/⇓/Ξ/Π 与精神分裂对象 | 文档 |
| [28 层与拓扑斯](docs/28-sheaves.md) | 粘合/stalk/**Ω 分类子**/f*⊣f₊/topos | 文档 |
| [29 压轴串联](docs/29-capstone.md) | 泛性质-唯一性-Yoneda-对偶-伴随-序论线 | 文档 |
| [30 坑位与书目](docs/30-pitfalls.md) | 总清单 + 三书导读 + Simmons 全谱对照表 | — |

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

- **record 相等三文化**（07/09 章核心）：NT 的 nlaw 字段依赖
  ncomp——Coq 止步于分量级、Agda 走 setoid（_≈NT_）、Lean 用
  结构 η+内核 PI 拿到完整 record 相等；Yoneda 往返 2 的完整版
  仅 Lean。
- Agda 的 TyCat 纤维积唯一性需证明无关性——12 章 Agda 版止步
  于抽象定理。
- 17/19/21/22/26/27 为文档章：RAPL、Beck 定理、五边形连贯性、
  反变伴随与层化的机器化需要函子范畴的完整 record 级相等 +
  极限一般机器；27.6 记录了「Sierpiński 玩具舞台」的可行路线。
- **Simmons 线的可判定红利**（24-26 章）：有限格/有限预序上的
  伴随、量词推进、R-集往返全部查表机器化（16 格/64 格/bool
  穷尽，零公理）；无限现场（ℤ 塔、ℝ 截面、拓扑空间）按
  「机器查表 + 文档讲理」双轨处理。
- funext 记账：Coq 公理 / Agda postulate / Lean 核心定理
  （[Quot.sound, propext]）——每章 Print Assumptions/#print 公示。
- 其他版本（Coq 9.x / Agda 3 / Lean 4.3x）未测。
