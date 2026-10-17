# 51 形容词修饰：五分类的类型学机关

> 对应读本：罗朝晖书 3.4（形容词修饰语义的研究，含 3.4.5
> 时态讨论）。代码：`examples/51_adjectives/ex51_adjectives.v`
> （相交/下属/否定/非承诺/时态五类形容词的机制全家桶——
> Σ 记录、Π 多态、子类型空间界、不相交并、特有谓词、三段并）。

形容词修饰是 MTT 语义学的「经典案例」（书原话）——它把
现代类型论的每种类型构造算子都拉出来遛了一遍。蒙太古
语义学里所有形容词一律 `(e→t)→(e→t)`（谓词变谓词），差异
全靠**意义公设**（meaning postulate）事后补——书反复强调
这是「无奈之举」。MTT 的答案：**每类形容词有自己的类型学
机关**，推理性质直接写在类型里。

## 51.1 四分类与推理模式（书表 3.3）

逻辑语义学的传统分类，按「形-名组合 (A,N)」的推理模式分：

| 分类 | 例子 | 推理模式 | MTT 机制（表 3.4） |
|---|---|---|---|
| 相交（intersective） | 黑的 | (A,N)⇒N 且 ⇒A | 简单谓词 + Σ |
| 下属（subsective） | 小的、熟练的 | (A,N)⇒N（只保证是 N） | **多态谓词** + Σ |
| 否定性（privative） | 假的 | (A,N)⇒¬N | 多态谓词 + **不相交并** + Σ |
| 非承诺（non-committal） | 被指控的 | 无约束 | **特有谓词** |

「黑猫」：既是猫（⇒N）又是黑色的（⇒A）——相交。「小象」：
是象，但「小」相对象类而言（⇒N only）——下属。「假枪」：
**不是**枪——否定。「被指控的贼」：可能是贼可能不是——
非承诺。第五类时态形容词（「以前的」）挂否定性旗下但
有独立的时间结构（51.5）。

## 51.2 相交形容词：Σ 的本职工位（书 3.4.1）

「黑的」是简单谓词 `black : Object→Prop`，「黑猫」是
**类型** `Σx:Cat.black(x)`（式 3.62）。两条推理各就各位：

```coq
Record BCat := mkBC { cat_of :> Cat ; pBlack : black cat_of }.
Check (fun b : BCat => cat_of b) : BCat -> Cat.  (* ⇒N：π1 子类型 *)
Theorem bcat_is_black : forall be : BCat, black be.
Proof. intros be. apply be. Qed.                   (* ⇒A：π2 直接给出 *)
```

「黑猫是猫」走 48 章的投射子类型（cat_of 字段强制），
「黑猫是黑色的」走 Σ 第二投影——**意义公设零消耗**。

但书 3.4.1 末埋了伏笔：这个建模要正确，前提是**证明无关性**
（(c,p) 与 (c,q) 应相等——「怎么证明是黑的」不该制造两只
黑猫）。机器件先把公理挂上：

```coq
Lemma black_cat_pi : forall (c : Cat) (p q : black c),
  mkBC c p = mkBC c q.
Proof. intros c p q. f_equal. apply proof_irrelevance. Qed.
```

全套论证在下一章（52）展开。

## 51.3 下属形容词：多态谓词救场（书 3.4.2）

「小」的杀伤性反例（式 3.69–3.71）：若「小象」「小动物」
都写成 `Σx:A.SMALL(x)`（同一个简单谓词 SMALL），那么由
Σ 的谓词传播 (Sp)（48 章 dprop）：

> Σx:Elephant.SMALL(x) ≤ Σx:Animal.SMALL(x)

——「**小象是小动物**」，假！（小象再小也比鱼虾大。）病根
是 SMALL 与被修饰名词无关。药方：**多态谓词**——

```coq
Parameter small : forall X : CN, X -> Prop.
Record SElephant := mkSE { elph :> Elephant ; _ : small Elephant elph }.
Record SAnimal  := mkSA { anim :> Animal  ; _ : small Animal anim }.
```

`small(Elephant)` 与 `small(Animal)` 是**两个不同的谓词**——
传播规则要的 `small(Elephant) = small(Animal)` 不成立，
错误推理的路被类型堵死。Coq 侧见证（强行造出错误方向会
被拒绝）：

```coq
Fail Definition wrong : SElephant -> SAnimal :=
  fun se => mkSA (ca (elph se)) (small Elephant (elph se)).
```

书里的史料：Ranta 1994 就卡在「动词语义类型的多样化」上
（他提了三个方案都不满意），**强制性子类型**是补上的最后
一块拼图——下属形容词是这条史线的纪念碑。

**skilful 的精细化（式 3.76–3.80）**：「熟练的」用 ΠA:CN
还不够——会造出「熟练的**楼房**」。药方是 47 章的**子类型
空间** CN_H（Human 的子类型们）：

```coq
Parameter skilful : forall A : CN, (A -> Human) -> A -> Prop.
Definition skilful_doctor : Doctor -> Prop := skilful Doctor dh.
Fail Definition skilful_building : Building -> Prop :=
  skilful Building (fun _ => john_h).   (* 无 B→H 强制，被拒 *)
```

机器件把「界」实现为携带 `A→Human` 强制证据的参数——
skilful(Doctor, dh) 合法、skilful(Building, …) 类型检查
直接失败。「熟练的楼房」不是假命题，是**非法表达式**。

## 51.4 否定性形容词：不相交并的舞台（书 3.4.3）

「假枪不是（真）枪」——修饰结果**否定**被修饰名词的属性。
MTT 建模（式 3.85）：枪的类型本身是不相交并：

```coq
Definition G := sum G_R G_F.                  (* 枪 = 真枪 + 假枪 *)
Definition fake_G (x : G) : Prop :=
  match x with inl _ => False | inr _ => True end.
Record FGun := mkFG { gun_of :> G ; _ : fake_G gun_of }.
```

两条推理全是类型论定理，无意义公设：

```coq
Theorem either : forall g : G, real_G g \/ fake_G g.  (* 3.93 *)
Proof. intros g. destruct g.
  - left. cbv. trivial.
  - right. cbv. trivial.  Qed.

Theorem fake_not_real : forall f : FGun, ~ real_G f. (* 3.94 *)
Proof.
  intros [g Hfake] Hreal. destruct g.
  - cbv in Hfake. exact Hfake.   (* inl：fake=False *)
  - cbv in Hreal. exact Hreal.   (* inr：real=False *)
Qed.
```

注意 48 章的知识在此回收：不相交并让 inl/inr 分属两界，
fake/real 谓词按构造子判定——「否定性」被**编码进类型的
形状**。书还记录了学术史：Partee 认为否定性形容词其实是
下属形容词 + 类型转换——而 MTT 的模型恰好兼容此读法
（fake 也写成 ΠA:CN 多态，只是其值由 A 的并结构决定）。

## 51.5 非承诺与时态（书 3.4.4–3.4.5）

**非承诺形容词**没有推理约束——不做一般刻画，每个词配
**特有谓词**（proprietary predicate）：

> H_a : Human → Prop → Prop，H_a(h, P) ≈「h 声称 P 真」

```coq
Record AllegedMurderer := mkAM
  { am_of :> Human ; _ : exists x : Human, H_a x (murder am_of) }.
```

「被指控的杀人凶手 = 被某人指控为杀人凶手的人」（式 3.103）
——是不是凶手，类型不表态。

**时态形容词**（「以前的」）按 Dowty 属否定性，但结构是
时间的三段并（式 3.109）：

```coq
Definition PR := sum PR_current (sum PR_former PR_future).
Definition former_PR (x : PR) : Prop :=
  match x with
  | inl _ => False | inr (inl _) => True | inr (inr _) => False
  end.
Theorem former_not_current : forall f : FormerPresident,
  ~ current_PR f.
```

「他是以前的总统 ⟹ 他不是现在的总统」（式 3.104⇒3.107）
无时间模型也成立。书末的微妙提醒：「他是以前的总统，碰巧
也是这一届总统」（式 3.112）说明真实时间语义要更细的
参数化——那是开放问题，不是本章的机关能装下的。

## 51.6 一页总结（本章的三个公式）

> 相交=简单谓词+Σ；下属=ΠA:CN 多态谓词（small(E)≠small(A)
> 堵死「小象是小动物」）；skilful 的界是子类型空间 CN_H。
> 否定性=不相交并（G=Gr+Gf）：fake/real 按构造子判定，
> 「假枪不是真枪」是定理不是公设。
> 非承诺=特有谓词（H_a）；时态=三段并（PR 三代）——
> 五类形容词 = 五种类型构造算子的点名上岗。

> **坑位速记**
> ① Record 字段里引用前面的字段拿到的是**字段值**不是投影
>   ——`H_a x (am_of x)` 报「Human 不能应用于 x」（本批
>   实测）；依赖字段写 `… (murder am_of)`；
> ② 多态谓词的「不同实例不可互推」在 Coq 里体现为：两个
>   Record 字段类型 `small Elephant elph` 与 `small Animal anim`
>   结构相似但常量不同——想串门就在类型检查处失败（Fail
>   见证）；
> ③ skilful 的界若直接写 `A ≤ Human` 会重蹈 48 章覆辙
>   （Coq 无全局子类型判断）——把强制当**证据参数**
>   `(A -> Human)` 传入是可执行的替身；
> ④ match 谓词的双分支判假（fake/real）注意 inl/inr 的
>   True/False 方向——两个谓词恰好互补，写反一个「假枪
>   是真枪」就悄悄成立；
> ⑤ proof_irrelevance 从标准库 `ProofIrrelevance` 直接
>   Require（书 5.3.2 写成 Axiom——Coq 8.20 已内置）。

## 51.7 与本书其他线的接口

- 48 章 Σ 谓词传播 (Sp)、投射子类型——「小象反例」正是
  (Sp) 的误用现场，多态谓词拆掉传播的前提；
- 47 章子类型空间 U(H)——skilful 的 CN_H 界；
- 30 章自造 Σ/Sum——本章 G=sum G_R G_F 与 Record 字段
  全是它的应用面；
- 52 章（下一章）证明无关性——相交形容词正确性的最后
  一块拼图；
- 53 章 dot 类型——「以前的总统」这类时态修饰与同谓的
  组合是点类型的下一站；
- 39 章 TAPL 子类型——「宽度/深度/置换」三律是程序语言
  侧的修饰理论，两线在「结构传播」处对读。

## 51.8 章末地图（书 3.4 要点选）

- **表 3.3/3.4**——四分类的推理模式与类型机制对照，本章
  双表的底本；
- **Ranta 的三个未遂方案**（3.4 脚注）——回蒙太古/子集
  类型/显式 π 投影，最后由强制子类型收官的学术史；
- **Partee 对否定性的异议**（3.4.3）——「假毛皮」例：
  理论要容纳语言使用者的真实直觉；
- **练习 3.4.x**（意大利语的下属形容词、多种修饰叠加）——
  Chatzikyriakidis 线的论文入口。

---

上一章：[50 MTT 语义学](50-mttsem.md) · 下一章：[52 证明无关与驴句](52-donkey.md)
