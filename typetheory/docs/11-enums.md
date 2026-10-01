# 11 Π 与枚举集合：空、单、双

> 对应读本：Nordström 第 6–7 章（枚举集合；集合族的笛氏积 = Π）。
> 代码：`examples/11_enums/`——三家同构：Empty/Unit/Bool 三件套
> + 消去子 + 构造子互斥 + Π-on-Bool 的「填表」直觉。

## 11.1 枚举集合：集合由「有哪些元素」决定

Nordström 的第 6 章从最简单的集合起步——**枚举集合**：列出
全部元素，别无其他。三种规格：

| 集合 | 构造子 | 消去子 | 逻辑读法 |
|---|---|---|---|
| `⊥`（空） | 无 | 到任意目标的函数 | 假（爆炸原理的原型） |
| `⊤`（单） | `star` | 常值函数 | 真 |
| `Bool`（双） | `true`/`false` | if-then-else | （命题级即 ¬ 与 ∨ 的前身） |

**消去子（eliminator）是 MLTT 的关键字眼**：一个集合的意义 =
「怎么构造」+「怎么使用」。Bool 的使用方式就是 case 分析：

```lean
def if2 {A : Sort u} (b : Bool2) (t e : A) : A :=
  match b with
  | .true2 => t
  | .false2 => e
```

Coq 的 `match`、Agda 的两行模式、Lean 的 `match` 是同一件事的
三种拼写。逻辑连接词从这里长出来：`not`/`and`/`or` 是 Bool 上的
函数，德摩根律是四行 case 检查（三家文件里各跑了一遍）。

## 11.2 空集合与荒谬

空集合没有构造子，所以「从它出发能到任何地方」：

```lean
def absurdE {A : Sort u} : Empty2 → A
  | e => nomatch e
```

三家的拼写值得对照记：

- **Lean**：`nomatch e`（穷尽性检查发现无构造子可匹配，直接收）；
- **Agda**：荒谬模式 `absurd-any ()`——`()` 就是「此处不可能有
  构造子」的证据语法；
- **Coq**：`match e with end`（无分支的 match）。

构造子**互斥**（true ≠ false）同样机器化：Lean 用自动生成的
`noConfusion`，Coq 用 `discriminate`（底层是单射性+构造子判别），
Agda 最直白——对 `refl` 匹配直接荒谬：

```agda
true≢false : true ≡ false → ⊥
true≢false ()
```

## 11.3 Π：一族集合的笛氏积

Nordström 第 7 章的主角是 Π——集合族 `P : Bool → Set` 的笛氏积
`Π (b : Bool). P b`，元素是「给每个 b 一个 P b 的元素」的函数。
在有限枚举上，Π 就是**填表**：

```agda
bothCases : (P : Bool → Set) → P true → P false → ∀ b → P b
bothCases P pt pf true  = pt
bothCases P pt pf false = pf
```

两行 = 两个构造子 = Π 的全部居留项形状（函数外延性下唯一）。
Bool 上的依赖函数与「按构造子索引的表」是同一个数学对象——
这是后续归纳族（13 章）在最小舞台上的预演。

一个实测小坑：想要「类型随 b 变的选择函数」，**族要先立**
（`Sel : Bool → Set` 两行定义），再填表；直接写
`if2 b ⊤ Bool` 不成立——`if2` 是非依赖的，两个分支必须同型。
依赖版本的 if 叫 `bothCases`/`Bool2_rect`/大_elim——「消去子的
依赖版自动生成」正是三家归纳机制的核心服务（13 章细看）。

> **坑位速记**
> ① 非依赖 `if` 的两分支必须同型；类型要随参数变就得走
> 消去子的依赖版（族先立、再填表）；
> ② Coq 空类型要声明在 `Set`（无构造子归纳默认落 Prop，
> 禁止消去到 Type）；
> ③ Lean 的 `nomatch`、Agda 的 `()`、Coq 的空 `match ... with end`
> 是同一荒谬的三种拼写；
> ④ Lean 核心库占用 `Empty`/`Unit`/`Bool`——自定义换名避免遮蔽。
