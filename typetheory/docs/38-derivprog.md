# 38 程序推导：类型论即程序设计方法学

> 对应读本：Nordström 书第 22 章（程序推导——推导方法、基本
> 策略、导出策略、Dijkstra 荷兰国旗分割问题全程）。
> 代码：`examples/38_derivprog/ex38_derivprog.agda`——策略
> 机制的对照件 + 荷兰国旗规格说明与推导树的完整机器化
>（三桶分色 Compute 见证 + 置换引理组 postulate）。

书名里的「程序设计」到本章兑现。论纲一句话：**类型论中的
程序设计 = 数学中的定理证明**——规格说明是被证命题、程序由
证明综合而得（34 章四合一判断的操作化）。本章把它做成了
一套**可执行的方法学**。

## 38.1 从上至下：规则倒读成策略

形式推导的教科书方向是「公理→结论」，但程序设计要的是
**从上至下**（Dijkstra 结构程序设计 [32]）：从规格说明出发、
分裂成子规格说明、综合子问题的解得到原问题的解。书 22.1 的
观察：**把类型论的规则从下至上读，每条规则就是一个策略**：

```text
合取引入规则（前提 A true, B true / 结论 A&B true）
  倒读 ⟶ 策略：目标 A&B 分裂成子目标 A 与 B
×-引入  倒读 ⟶ 目标 A×B 分裂成「找 a:A」与「找 b:B」，
                 程序是 ⟨a,b⟩
×-消去   倒读 ⟶ 目标 C(p) 分裂成「证 p:A×B」与
                 「假设 x,y 下证 C(⟨x,y⟩)」，程序 split(p,e)
Π-引入   倒读 ⟶ 目标 (Πx:A)B(x) 分裂成「假设 x∈A 下证
                 B(x)」，程序 λ(b)
List-消去 倒读 ⟶ 目标 C(l) 分裂成三支（l 的形状、C(nil)、
                 归纳步 C(cons)），程序 listrec(l,a,b)
```

推导用树形记法（书 22.1.1 的 `厂` 形缩进）书写——**未完成的
推导同样可读**：它同时给出「迄今的推导结构」与「此阶段所得
的程序结构」。这正是 LCF 的目标制导证明（34 章谱系）的类型
论版。

**导出策略**（22.1.2）：任何已证判断的另一读法——证过
`fst(p) ∈ A[p∈A×B]`（一行：split(p,(x,y)x)），它就变成策略
`×-elim1`：「目标 A 由 ×-elim1，子目标 A×B」。机械证明检验
器上**导出策略免检**——「由判断的构作我们知道用它必得证明」。
tactic 宏、自定义 induction 原理、`By` 归纳——三大助手的
衍生策略机制全部站在这个观察上。

Agda 件里策略对照段的最小样本（判断即策略的一行版）：

```agda
×-elim1 : {A B : Set} (p : A × B) → proj₁ p ≡ proj₁ p
×-elim1 p = refl        -- 判断 fst(p) ∈ A 的证明即策略
```

## 38.2 荷兰国旗：规格说明先行

书 22.2 的旗舰问题（Dijkstra [87] 的分割问题）：任给红白蓝
三色对象序列，**重排**成国旗色序。类型论的步骤不是「先写
程序再想性质」，而是**先立规格说明**：

```text
假设   A set（对象集）、colour : A → Colour、
       eqd : A×A → Bool（可判定相等——置换定义需要）
定义   Colouredlist(s) = List({x∈A | colour(x)=s})   三桶类型
       append(l₁,l₂) = listrec(l₁, l₂, (x,y,z)x·z)
       occin(x,l)    = l 中 x 的出现次数（eqd 计数）
       l₁ ≈p l₂      ≜ (∀x∈A) Id(N, occin(x,l₁), occin(x,l₂))
规格   S = (Πl ∈ List(A)) Flag(l)
       Flag(l) = {⟨l',l'',l'''⟩ ∈ Reds×Whites×Blues |
                  l ≈p l'@l''@l'''}
```

**规格说明是集合、程序是它的元素**——S 的居留项就是「对每个
输入输出正确分桶三元组」的程序。注意 ≈p 用**子集合**表达
（约束部分），Flag 的居留项即「计算无关的证据只写不读」——
33 章的设计原则在此落位。

Agda 件的对应物（教学件取 A = Colour、置换以引理组实现——
见 38.3）：

```agda
data All (c : Colour) : List Colour → Set where
  all-[]  : All c []
  all-∷   : ∀ {x xs} → x ≡ c → All c xs → All c (x ∷ xs)

Flag : List Colour → Set
Flag l = Σ[ r ∈ List Colour ] Σ[ w ∈ List Colour ] Σ[ b ∈ List Colour ]
         (All red r × All white w × All blue b × ≈p l (r ++ w ++ b))
```

## 38.3 推导树：三策略合演

书 22.2 的推导树（读法：目标 ← 策略 ← 子目标）：

```text
(Πl∈List(A))Flag(l)        由 Π-引入（子目标带假设 l）
  Flag(l)                  由 List-消去（对 l 归纳）
    List(A)                由假设 ⟹ 3 l
    奠基 Flag(nil)         由 引理 2（nil 三元组 + ≈p 自反）
                           ⟹ ⟨nil,nil,nil⟩
    [x∈A, y∈List, z∈Flag(y)]
    归纳 Flag(x·y)         由 Colour-消去（对 colour(x) 三分）
      红：⟨x·r', l'', l'''⟩    （x 挂红桶头）
      白：⟨l', x·l'', l'''⟩    （x 插白桶头）
      蓝：⟨l', l'', x·l'''⟩    （x 挂蓝桶头）
```

奠基用引理 1/2（@ 的 nil 单位元 + ≈p 自反）；归纳步用置换
引理（x 从序列头搬进桶里保持多重集）——书里明说：「在此推导
中，我们将**假设少许置换的基本性质**而且把这些性质明显地
表述成引理」。机器件同样处理（postulate 引理组 + 分桶部分
完整证明）：

```agda
flag : (l : List Colour) → Flag l
flag []       = [] , [] , [] , all-[] , all-[] , all-[] , ≈p-refl []
flag (c ∷ cs) with c | flag cs
... | red   | r , w , b , hr , hw , hb , hp =
      (red ∷ r) , w , b , all-∷ refl hr , hw , hb , ≈p-head {red} {cs} {r} {w} {b} hp
... | white | r , w , b , hr , hw , hb , hp =
      r , (white ∷ w) , b , hr , all-∷ refl hw , hb , ≈p-mid {white} {cs} {r} {w} {b} hp
... | blue  | r , w , b , hr , hw , hb , hp =
      r , w , (blue ∷ b) , hr , hw , all-∷ refl hb , ≈p-end {blue} {cs} {r} {w} {b} hp
```

with-模式匹配把书里的推导树写成三段缩进——**同一棵树的
两种记法**。程序提取一眼可见（fst 投影剥掉证明分量）：

```agda
flagOf : List Colour → List Colour × (List Colour × List Colour)
flagOf l with flag l
... | r , w , b , _ = r , w , b

_ : flagOf (white ∷ red ∷ blue ∷ []) ≡ ((red ∷ []) , (white ∷ []) , (blue ∷ []))
_ = refl                                    -- 荷兰国旗色序，Compute 见证
```

**一次推导、三份产出**：程序（flagOf）、正确性证明（Flag
的居留）、以及两者绑定的规格说明（Flag 的类型）——「证明
即程序」的完整闭环。书 22.2 末的注记也搬过来：这个解**不**
满足 Dijkstra 的空间效率要求（列表 vs 数组、原地重排）——
类型论给的是**最简单的正确程序**，效率工程是另一门课
（[87] 的数组版解法）。

## 38.4 方法论的地图

书 22 章开头把本章放在更大的谱系里：Manna–Waldinger 的
演绎综合 [63]、Takasu [106]、Cornell 的 Constable 组
（Nuprl 的 proofs-as-programs）——**程序综合**作为证明搜索
的副产品。配套的文献指针（书 ch.1）：Goto [45]、Paulin-
Mohring [80]（Coq 提取的理论源头——41 章）、Sato [93]、
Hayashi [49]——「把证明中的计算无关信息删除」的提取技术；
Goad [41,42] 证明**证明变换**与高效计算的对应（证明加工
学）。41 章的 extraction 与本章首尾相接：38 章手工做的事
（推导→程序），41 章机器做（Coq Extraction/Lean 的
extractGoal）。

> **坑位速记**
> ① 自造中缀操作符（如 _mem_）**必须声明 fixity**
>   （`infix 4 _mem_`）——无声明时比 `→` 松，`x mem xs → y`
>   被解析成 `x mem (xs → y)`、报「List 应为 sort」的天书
>   （本件定位三轮才见真身：最小重现法立功）；
> ② **双层 with 的抽象重影**：`with flag cs` 再 `with c` 后
>   构造子分支里的项被二次抽象、refl 失明——合并成
>   `with c | flag cs` 单层双模式；
> ③ Σ/× 的函数式定义（All 用 `x ≡ c × All c xs`）在期望
>   推导里偶尔不展开——**谓词改 data 声明**（构造子
>   all-∷）后 elaboration 顺风顺水，可读性还更好；
> ④ postulate 引理组的隐式参数在用点**显式喂**
>   （`≈p-mid {white} {cs} {r} {w} {b} hp`）——`++` 非单射，
>   `R++W++B ≡ r++w++b` 的元变量统一会 blocked on _r 挂死；
> ⑤ 置换引理走「成品组合形」（≈p-head/mid/end 一步到位）
>   ——cons+trans+插位的分步组合在 postulate 世界统一不了
>   中间类型（occin 计数的完整引理组才是正路，进阶功课）。

---

上一章：[37 杂例三讲](37-examples.md) · 下一章：[39 ADT 规格说明](39-adtspec.md)
