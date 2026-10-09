# 第 46 章 字问题与重写：Thue 系统与 Tseytin 半群

> 对书：Müller-Stach《The Code of Mathematics》ch 5「字问题」节
> （Thue 1910/Tseytin 半群原例）。本章通道：C
> （`examples/46_wordproblem/ex46_wordproblem.v`）/
> L（`examples/46_wordproblem/ex46_wordproblem.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `strip`/`replaceAt`/`rew1Once` | **一步双向重写算子**（位置×规则×方向全枚举） | C/L |
| `closureW`/`rewStar` | 深度界 BFS 闭包（带 seen 去重） | C/L |
| `rew1_ledger`/`eq_chain_cdca` | 九关系应用链账本（ca↔ac、ce↔eca、cdca↔cdcae） | C/L |
| `confl_shadow` | 两条写法（eca/ce）的闭包汇合样本 | C/L |
| `aaa_probe` | **aaa 不可达的有限影子**（三出发词深度 5 闭包全不含） | C/L |

上一章把计算装进「时间预算」；这一章换一副眼镜——**计算=
字符串重写**。这个视角比 Turing 机还早：挪威数学家 Axel Thue
1910 年就提出「字的替换系统」，比 1936 年的 Turing 机早二十
六年。Müller-Stach 在 ch 5 里给它一整个专节（p78、p84）：Thue
系统是「一切计算=项替换序列」的最早机器模型，后来经 Chomsky
（形式语言）与 Montague（形式语义）渗入语言学。而它身上长出
的**字问题**（word problem），是不可判定性在代数里的正身。

## 一、半群呈示与字问题

**呈示**（presentation）⟨A | R⟩：字母表 A 加一组关系 R——
每条关系是两个字 w₁=w₂。它定义的半群里，两个字**相等**当且
仅当可以用关系反复双向替换把一个变成另一个（自反对称传递闭
包）。**字问题**：给定呈示与两个字，判定它们相不相等。

为什么这个问题天然属于逻辑教程？因为它是「**等词逻辑**的
可判定性问题」——23 章的等式推理（群例等式链）在任意呈示下
的完全版。Turing 机可以逐字模拟呈示里的重写推导（把纸带内容
当字），反之字问题可以编码停机问题——1947 年 Post 与 Markov
（半群）、Novikov 与 Boone（群，1955-58）相继证明：**存在呈
示，其字问题不可判定**。

## 二、Tseytin 半群：九条关系的极简反例

书 p84 给出 Tseytin 的具体呈示（原例，照录）：

```
⟨a, b, c, d, e |  ac=ca, ad=da, bc=cb, bd=db,
                  ce=eca, de=edb, cdca=cdcae,
                  caaa=aaa, daaa=aaa ⟩
```

判定字 w=aaa 是否成立——不可判定。九条关系短得能抄在名片
上，却携带完整的不可判定性。机器面把它做成数据（字母
a,b,c,d,e 编码 0..4，字=数表）：

```coq
Definition RS : list (word * word) :=
  [ ([0;2], [2;0]);      (* ac = ca   交换 *)
    ([0;3], [3;0]);      (* ad = da   交换 *)
    ([1;2], [2;1]);      (* bc = cb   交换 *)
    ([1;3], [3;1]);      (* bd = db   交换 *)
    ([2;4], [4;2;0]);    (* ce = eca  换基 *)
    ([3;4], [4;3;1]);    (* de = edb  换基 *)
    ([2;3;2;0], [2;3;2;0;4]);  (* cdca = cdcae  吸收 *)
    ([2;0;0;0], [0;0;0]);      (* caaa = aaa    吞 a *)
    ([3;0;0;0], [0;0;0]) ].    (* daaa = aaa    吞 a *)
```

结构读法：前四条是 c,d 与 a,b 的**交换律**；ce→eca、de→edb
把 e 换到队首并带上一个「配字母」（c 配 a，d 配 b）；cdca 吸
收一个尾 e；最后两条在三个连排 a 面前吞掉队首的 c/d——它们
只在字已含 aaa 时才用得上，这是 aaa 探针的关键。

## 三、一步重写：位置 × 规则 × 方向

重写算子把「推导」变成可枚举的机械动作。在字 w 的**每个位
置** i，试**每条规则**的**两个方向**——左换右、右换左：

```coq
Fixpoint strip (w p : word) : option word :=   (* w 前缀剥掉 p？ *)
  match p with
  | [] => Some w
  | pc :: pt => match w with
                | [] => None
                | wc :: wt =>
                    if Nat.eqb pc wc then strip wt pt else None
                end
  end.

Definition replaceAt (w : word) (i : nat) (p q : word) : option word :=
  match strip (skipn i w) p with
  | Some rest => Some (firstn i w ++ q ++ rest)
  | None => None
  end.
```

`strip` 是「w 在位置 i 处是否以 p 开头」的选项式回答，命中则
交出剩余部分；`replaceAt` 把 p 缝回成 q。一步算子收集全部
(规则,方向,位置) 的命中：

```coq
Definition rew1Once (rs : list (word * word)) (w : word) : list word :=
  flat_map (fun r =>
    flat_map (fun i =>
      match replaceAt w i (fst r) (snd r) with
      | Some w1 => w1 :: (match replaceAt w i (snd r) (fst r) with
                          | Some w2 => [w2] | None => [] end)
      | None => match replaceAt w i (snd r) (fst r) with
                | Some w2 => [w2] | None => [] end
      end)
      (seq 0 (S (length w))))
    rs.
```

六格账本（`rew1_ledger`）：ca←ac、ac←ca、eca←ce、ce←eca、
cdcae←cdca、cdca←cdcae——九关系中三条的双向，全部一步命中。

## 四、深度界闭包：等式的搜索宇宙

等式 w₁=w₂ 成立 ⟺ 两者在无限重写图里连通。机器面只跑**深度
界 BFS**（frontier 扩散、seen 去重防爆炸）：

```coq
Fixpoint closureW (d : nat) (rs : list (word * word))
        (seen frontier : list word) : list word :=
  match d with
  | 0 => seen
  | S d' =>
      let next := filter (fun x => negb (inW x seen))
                        (flat_map (rew1Once rs) frontier) in
      closureW d' rs (seen ++ next) next
  end.

Definition rewStar (d : nat) (rs : list (word * word)) (w : word)
  : list word := closureW d rs [w] [w].
```

**等式链账本**（`eq_chain_cdca`）：cdca 与 cdcae 互在对方
深度 1 闭包里——一条规则两侧的字，BFS 双向收拢。**汇合样本**
（`confl_shadow`）：eca 与 ce 是同一元素的两种写法，它们深度
3 的闭包交集非空——两条不同路径走到同一个字，这是合流性
（Church–Rosser 性质）的最小现场：重写系统若全局合流，则每
个等价类有唯一标准形，字问题退化为「归约到标准形再比对」
（39 章词项化简对账的远亲）。Tseytin 半群**没有**这个好性质
——不可判定性正是从不合流里长出来的。

## 五、aaa 探针：不可判定性的有限影子

`aaa_probe` 从三个典型出发词（ce、de、cdca）各跑深度 5 的
闭包——**全部不含 aaa**：

```coq
Example aaa_probe :
  [ negb (inW [0;0;0] (rewStar 5 RS [2;4]));
    negb (inW [0;0;0] (rewStar 5 RS [3;4]));
    negb (inW [0;0;0] (rewStar 5 RS [2;3;2;0])) ]
  = [true; true; true].
Proof. reflexivity. Qed.
```

读这张账要分两层。**第一层（机制）**：吞 a 的规则 caaa→aaa
只在字已含三个连排 a 时才可应用；而 e/c/d 出发的字在九关系
下生不出连排 aaa——交换律只在 c,d 与 a,b 之间搬运单个字母，
换基规则 ce→eca 在队首造的是 a/c 的**混排**。闭包规模本身就是
证词：自 ce 出发深度 5 只扩散出 **3 个字**（ce、eca、eac——
`Compute` 的账），e 系词在九关系下几乎不动。**第二层（语义）**
：影子找不到 ≠ 不存在——「w=aaa 不可判定」说的是**不存在任
何算法**对全部输入给答案；深度界的搜索恰是被证明不可能的那
件事的有限余像。这与 42 章停机对角、44 章 König 左极路径是
同一家族：机器面演示「搜索的形状」，定理本身住在文档线。

## 六、字问题的族谱与表亲（文档线）

- **Thue 系统**（1910）：单向重写（只许左→右）研究终止性；
  双向版（本章）研究等式。两者都继承 Thue 之名。
- **半群字问题**：Post/Markov 1947 不可判定——本书原例的
  归属。
- **群字问题**：Novikov 1955、Boone 1958——需处理逆元，构造
  更重；Dehn 1912 为双曲群给出可解情形（组合群论开端）。
- **表亲**：56 章的 **PCP**（Post 对应问题）——多米诺对的首
  字-尾字匹配，同样是字符串重写型不可判定性，H&R 用它归约出
  FOL 不可判定。Tseytin 呈示的构造思路（用少量关系编码 Turing
  机格局转移）与 PCP 归约同源。
- **应用回响**：重写系统是**程序语言**的一等公民——λ 演算的
  β-归约、Prolog 的归结（33-34 章）、等式逻辑的 Knuth-Bendix
  完备化（合流+终止的标准形搜索——第四节的合流现场是它的
  需求侧）。Chomsky 层级（0 型文法=无限制重写=Turing 完备）
  是 Thue 思想在语言学里的制度化。

hypercomputing 的边界（书 p84-85）：Church–Turing 论题说「一
切有效计算皆 Turing 可计算」——**不可证的数学命题，只能被
物理反驳**（若造出超 Turing 的机器）。reservoir computing 等
开放架构目前都未越界；这与 49 章非标准模型的「无限元素不可
物化」互为镜像。

## 小结

字问题是不可判定性的代数正身：Thue 1910 的「计算=替换」眼镜
下，九条关系的小呈示（Tseytin）就足以藏住全部 Turing 完备
性。机器面把推导变成机械枚举（位置×规则×方向的一步算子）、
等式变成搜索宇宙（深度界 BFS 闭包）、合流性变成两张闭包的交
集、不可判定性变成 aaa 探针的三个空结果——每一层都把「逻辑
概念」兑换成「可跑账本」。下一章回到算术化（47 章）搭好的编
码舞台，进入 Gödel 第二不完备定理：理论证不出自身一致性
——而「一致性」在呈示语言里正是「0=1 无推导」，字问题的
亲侄子。

---

上一章：[45 复杂度：P 与 NP](docs/45-complexity.md) · 下一章：[47 算术化与哥德尔编码](docs/47-goedel.md)
