# 偏微分方程：Evans 理论全景与机器验证教程

以 Lawrence C. Evans《Partial Differential Equations》第 2 版
（AMS Graduate Studies in Mathematics 19，高教社影印）为纲的中文
教程——全书核心自包含：只读 docs 即可学习，不需要回看原书；每章
开头给"对应书 §x.y"定位锚。

与姊妹篇《偏微分方程数值解法》（pdenum，陆金甫/关治）互补：那本
讲"怎么算"，这本讲"解是什么、何时存在、多光滑"。

四通道机器验证：

- **Lean 4 + mathlib4**（主证明：单 lake 工程，mathlib 4.33.1 钉版
  路径依赖——叠加原理、调和性、能量恒等式、特征线表示、
  Lax–Milgram 的核、Legendre 变换凸性等代数核与完整小证明）
- **Julia / Python (scipy)**（数值对表：制造解残差、激波形成、
  平均值公式数值核对、能量单调曲线、Turing 增长率、消失粘性极限、
  孤子碰撞——双实现交叉验证）
- **Prolog (SWI)**（规则：方程分类库、适定性判据、特征 ODE 构造、
  熵可容许对、方法选择树）
- **Fortran (flang)**（经典内核：热核卷积、波能量监测、
  Lax–Friedrichs、Galerkin 谱）

## 全书目录

### 第一篇 预备（书第 1 章，B0 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 导言 | 方程动物园、制造解对表、叠加原理完整机器证明 |
| [01](docs/01-wellposed.md) | 适定性与 Hadamard 反例 | 三判据、逆热放大、sin·sinh 边值趋零解爆炸 |

（后续批次推进中，收尾时此目录补全。）

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
    pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01' # 单章
    pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道
