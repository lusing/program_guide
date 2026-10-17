# 37 杂例三讲：从证明提取程序

> 对应读本：Nordström 书第 21 章（除以 2 / 偶或奇 / Bool 仅
> true 与 false / 可判定谓词 / 强消去规则）。
> 代码：`examples/37_examples/ex37_examples.agda`——half 程序
> 的证明提取全程、distr 分配律、Bool 限制、Decidable、
> 强弱消去对照。

书第四部分「例子」的开场白值得先记：前三部分的每个例子都
小而孤立，本章起「证明的内容被用于**真正的程序构作**」。三
个例子（除以 2、偶或奇、Bool 的元素）示范同一个纲领的三个
侧面——**程序 = 证明的计算内容**；两个进阶（可判定谓词、
强消去）补上工具箱。38 章把这套方法放大成荷兰国旗全程。

## 37.1 除以 2：证明里长出程序

命题：`(∃y∈ℕ)((x =ₙ 2y) ∨ (x =ₙ 2y+1))[x∈ℕ]`——每个自然数
要么偶要么奇，且**见证 y 恰是 x/2 的整数部分**。证明对 x
归纳（奠基 0=2·0；归纳步两种情形接力），然后把整个推导按
命题即集合翻译成类型论项——N-消去给出 natrec 骨架、∨-消去
给出 when、∃-消去给出 split，最后：

```text
half-proof ≜ λx. natrec(x, ⟨0,inl(id(0))⟩, (x,z)split(z, …))
half(x)   ≜ fst(half-proof · x)
```

**书里最重要的一句话**在这里：「注意，在这个类型论推导中，
我们不仅已构造出程序 half，而且同时给出此程序满足规格说明
的几乎是形式的证明……此证明元素**决不用**在程序 half 的
计算中」——when-部分来自归纳步骤的 ∨-消去，操作上可以用
if-then-else 替代。这是 41 章（提取与运行）的种子：**证明
的计算无关部分可以在提取时剥掉**。

Agda 件完整复刻（谓词用自造 double 以获得全折叠）：

```agda
double : ℕ → ℕ
double zero    = zero
double (suc y) = suc (suc (double y))

half-proof : (x : ℕ) → Σ ℕ (λ y → (x ≡ double y) ⊎ (x ≡ suc (double y)))
half-proof zero    = zero , inj₁ refl
half-proof (suc x) with half-proof x
... | y , inj₁ e = y     , inj₂ (cong suc e)      -- x=2y ⟹ suc x=2y+1
... | y , inj₂ e = suc y , inj₁ (cong suc e)      -- x=2y+1 ⟹ suc x=2(y+1)

half : ℕ → ℕ
half = proj₁ ∘ half-proof

_ : half 7 ≡ 3
_ = refl                                        -- Compute：7 的半份 3
```

`half 7 ≡ 3` 的 refl 见证整个机器可跑：归纳三层、每次 split
出见证，`proj₁` 抽取——**fst 就是提取器**。

一个书里诚实记录的细节：作者们最初想用子集合
`{y∈ℕ|(x=2y)∨(x=2y+1)}` 直接表达「只要程序不要证明」，但
「使用子集合不可能直接地把以上证明翻译到类型论中，因为
子集合-消去不是足够强去解释 ∃-消去」——于是用 Σ 证明、
再 fst 投影。**33 章的弱消去在实战里第一次咬人**：子集类型
适合当规格说明（35 章 ADT 用它），不适合当证明载体。

## 37.2 偶或奇：分配律与判定程序

第二例造 `even : ℕ → Bool`。逻辑步先证分配律：

```text
((∃x∈A)(P(x) ∨ Q(x))) ⊃ ((∃x∈A)P(x) ∨ (∃x∈A)Q(x))
```

翻译成类型论项就是 distr（件里三行）：

```agda
distr : {A : Set} {P Q : A → Set}
        → (Σ[ x ∈ A ] (P x ⊎ Q x)) → (Σ[ x ∈ A ] P x) ⊎ (Σ[ x ∈ A ] Q x)
distr (x , inj₁ p) = inj₁ (x , p)
distr (x , inj₂ q) = inj₂ (x , q)
```

然后 `even-or-odd(n) ≜ distr · half-proof · n`——最外层是
inl 当且仅当 n 偶。最后剥一层：

```agda
even : ℕ → Bool
even x with half-proof x
... | _ , inj₁ _ = true
... | _ , inj₂ _ = false

_ : even 4 ≡ true
_ = refl
_ : even 7 ≡ false
_ = refl
```

**组合子的接力**：half-proof 造证据、distr 换视角、when 折
成 Bool——三个小件拼出一个判定程序，每个都自带正确性。
这是「程序由证明组装」的最小完整样本。

## 37.3 Bool 仅有 true 与 false

第三例命题：`((∃b∈Bool)P(b)) ⊃ (P(true) ∨ P(false))`。
书里的推导有个教学关键：拿到假设 `w₂ ∈ P(w₁)` 后**不能直接**
用 Bool-消去——w₂ 的类型依赖假设变元 w₁，而 Bool-消去的分支
要求目标对固定类型成立。必须先对 w₁ 分情况构造
`P(w₁) → (P(true)+P(false))` 的函数，再应用：

```text
if w₁ then λ(inl) else λ(inr) ∈ P(w₁) → (P(true)+P(false))
apply(…, w₂) ∈ P(true)+P(false)
```

Agda 的版本「一次到位」：

```agda
bool-only : {P : Bool → Set} → (Σ Bool P) → P true ⊎ P false
bool-only (true  , p) = inj₁ p
bool-only (false , p) = inj₂ p
```

——模式匹配 `(true , p)` 同时做了三件事：对 w₁ 分情况、把
w₂ 的类型特化到 P(true)、给出等式信息。**这正是 37.5 强消
去的日常化身**：书里绕的弯，现代语法已铺平。件里同址还放
了 Σ 版的四兄弟（N/List/+/× 的同构命题），书 21.3 末的
「基本上同时可证」一组。

## 37.4 可判定谓词：Decidable 与 peano4 的用场

「B(x) 可判定」= 有机械过程对每个 a 判 B(a) 真假。形式化：

```agda
Decidable : (A : Set) (B : A → Set) → Set
Decidable A B = ∀ x → B x ⊎ (B x → ⊥)
```

**Decidable 的元素就是判定过程**——又是四合一判断（元素即
程序即证明即解）。书里例子：`(n)Id(N,0,n)` 可判定，归纳构造
natrec(n, inl(id(0)), (x,y)inr(λ(z)case(peano4·z)))——**succ
分支用 peano4 当炸弹**（31 章的 `0≠succ n)` 证明在此上岗）：

```agda
zero-decidable : Decidable ℕ (λ n → n ≡ zero)
zero-decidable zero    = inj₁ refl
zero-decidable (suc n) = inj₂ (λ ())             -- suc n ≡ zero 荒谬
```

Agda 版的 succ 分支更狠：`suc n ≡ zero` 的 refl 模式直接荒谬
（构造子不同头）——peano4 的机器等价物。**可判定性是构造
数学的算法面**（34 章 Bishop 纲领）：说「可判定」就要给出
判定程序，说「不可判定」就要证明不存在——两者都是类型论
内的命题。

## 37.5 强消去规则：split′ 与它的现代归宿

书 21.5 的收尾技术：把消去规则**加强**——在分支前提里追加
「构造形状与主参数相等」的等式假设：

```text
强 split-消去：c ∈ Σ(A,B), C(u)set[u∈Σ(A,B)],
  d(x,y) ∈ C(⟨x,y⟩)[x∈A, y∈B(x), ⟨x,y⟩=Σ(A,B)c true]
  ⟹ split′(c,d) ∈ C(c)
```

第三前提比弱版多带等式 ⟨x,y⟩=c。它是**导出规则**：

```text
split′(c,d) ≜ apply(split(c,(x,y)λz.d(x,y)), id(c))
```

——先造 `C′(u) = (u=c)→C(u)` 的族，弱消去造出 `c=c→C(c)`
的函数，再喂 `id(c)`。funsplit′/when′/if′ 同款。用途：分支
体需要「当前处理的就是主参数」的信息时（如 38 章荷兰国旗
的归纳步骤），强版省去手工搬运。

现代归宿：**模式匹配自带强消去**。件里同址两版对照：

```agda
when′ : {A B C : Set} (d : A → C) (e : B → C) (w : A ⊎ B) → C
when′ d e w = [ d , e ]′ w                       -- 弱版：消除子直用

when″ d e (inj₁ a) = d a                         -- 强版：模式匹配
when″ d e (inj₂ b) = e b                         -- （自带 inl w = w）

same d e (inj₁ a) = refl                         -- 构造子形式下
same d e (inj₂ b) = refl                         -- 两版均折叠相同
```

——Coq 的 `match ... in ... return ...`（大消去与等式上下文）、
Agda 的 `with` 抽象、Lean 的 `match` 泛化器，全部把这个
「分支体看得见主参数形状」的服务做进语法。书里的 split′ 是
它们的前身——**规则不够强就造导出规则**的工程学。

> **坑位速记**
> ① 奇偶分解的谓词要选**全折叠**形态：2y 写 `double y`（每步
>   双 suc）而不是 `y + y`——std 的 `+` 只折叠左 suc 头，
>   `y + suc n` 不折叠、要 +-suc 引理，refl 全线卡死（本件
>   实测三连败后改道）；
> ② `same` 型等式证明须**按构造子分派**——两版消除子在变量
>   w 上都是 stuck 项、语法不同形，`same d e w = refl` 不
>   过；分派到 inj₁/inj₂ 后双双折叠才 refl；
> ③ Σ 裸写（`Σ (λ y → …)`）不合法——std 的 Σ 首参是类型，
>   要 `Σ ℕ (λ y → …)` 或 `Σ[ y ∈ ℕ ] …`（后者需 import
>   Σ-syntax）；
> ④ `with … | pat , inj₁ e` 的模式里 e 直接复用时先看它在
>   目标里的**精确形态**（cong suc 差一层就报 UnequalTerms）——
>   证据搬运的层数等于构造子层数。

---

上一章：[36 单型集合 II](36-monosets.md) · 下一章：[38 程序推导](38-derivprog.md)
