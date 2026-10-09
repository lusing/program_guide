# 第 71 章 密码与信任机器

> 对书：Müller-Stach《The Code of Mathematics》ch 4「Mathematics in
> Our Culture」（p60-74）。本章通道：C（`examples/71_crypto/ex71_crypto.v`）/
> L（`examples/71_crypto/ex71_crypto.lean`）/ P（`examples/71_crypto/ex71_crypto.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `powmod` | 快速模幂（Coq 朴素线性版+文档线讲平方-乘；Lean GMP 平方-乘） | C/L |
| `rsa_roundtrip` | **RSA 全流程**（n=143, e=7, d=103）：九条消息加解密回环（含 gcd≠1 边界） | C/L |
| `fermat_ledger` | 费马小定理实例账（p=5,7,11,13 的 Z_p^* 全元素） | C/L |
| `shamirRun` | **Shamir 三趟协议**四步状态机：Eve 视角只见三个公开值、末步开箱 | C/L |
| `chain3`/`tamper` | **哈希链**：整链验证+篡改级联（改一块全链断） | C/L |
| `separable`/`entangle_ledger` | 2-qubit **纠缠锥方程**检查器（Bell 态纠缠、积态可分离） | C/L |
| `andGate`/`xor_linear_impossible` | 感知器 AND/OR 整数权重+**XOR 线性不可分枚举**（9×9×19 无解） | C/L |
| `dlp_rows`/`is_gen` | DLP 回溯枚举+生成元判定（**Z₁₇* 生成元恰 8 个**） | P |

1940 年 Hardy 在《一个数学家的辩白》里自豪地宣布数论「干净而无
用」；四十年后 RSA 把它变成全球信任的底座——Müller-Stach ch 4
以这出讽刺剧开场，把模算术的单向函数（g^m mod N）一路铺到
RSA、Shamir 三趟协议、区块链、量子威胁与神经网络。本章把这条
应用长廊全部自包含展开，机器面六件套外加 Prolog 的 DLP 搜索。

## 一、单向函数：从星期到 RSA

剩余类算术 Z/NZ 的引例是星期（N=7——「三天后的两天后」=「两天
后」）。密码学的引擎是这里的**单向性**：算 g^m mod N 容易（平方-
乘 O(log m) 次），已知 g^m 反求 m（离散对数）没有已知的有效算
法——正走易、反走难。

**RSA 的机制**（书 p61-62，逐条展开）：

1. 取大素数 p、q（两百位级），N=pq 公开；
2. φ(N)=(p−1)(q−1)（**保密**——算它等价于分解 N）；
3. 选 e（如 65537），求 d 使 e·d ≡ 1 (mod φ(N))；
4. 加密 m^e mod N、解密 (m^e)^d ≡ m^(1+kφ) ≡ m (mod N)——最后
   一步是**欧拉定理**：gcd(g,N)=1 时 g^φ(N) ≡ 1。

机器面（`rsa_roundtrip`）：p=11、q=13、n=143、φ=120、e=7、d=103
（密钥方程 7·103−1=720=6·120 ✓），九条消息逐条回环——含边界
消息 142（=n−1）与 **gcd≠1 的 11、22**（与 143 有公因子，欧拉
定理的条件失效，靠 CRT 两翼分别归位——回环依然成立，这是完整
RSA 而非简化版）：

```coq
Example rsa_roundtrip :
  map (fun m => Nat.eqb (powmod (powmod m e0 n0) d0 n0) (m mod n0))
      [5; 9; 12; 42; 100; 142; 7; 11; 22]
  = [true; true; true; true; true; true; true; true; true].
Proof. reflexivity. Qed.
```

`powmod` 的实现有个诚实记录：Coq 侧用**朴素线性版**（每步乘底
即取模），平方-乘的指数减半走 `Nat.div2`——**guard 检查器第六
次拒绝**（45/46 章同家族：div2 不是结构子项）。教学件消息与指
数都小（d=103），线性版诚实够用；Lean 的 Nat 是 GMP 二进制，平
方-乘直接结构递归无此劫——同一算法在两种数表示下的实现面差异
本身就是「unary vs 二进制」的现场教学（47 章 BACH 编码的续篇）。

**素数侧**（文档线）：费马小定理的实例账（`fermat_ledger`）对
p=5,7,11,13 验证 Z_p^* 全元素 a^(p−1)≡1——它是素性测试的引擎；
**Carmichael 数 561**（3·11·17）对一切底通过费马测试却非素数
——Miller–Rabin 加二次探测拆穿它（概率测试，GRH 下确定性化）；
**AKS 2002** 证明素性判定在 P（书 p62 点名的里程碑）。分解侧只
有次指数算法（二次筛/数域筛）——**P≠NP 的密码学赌注**（43 章
千禧问题的真金白银版）。

## 二、Shamir 三趟协议：不共享密钥的传递

**手提箱比喻**（书 p62-63）：Alice 用自己的锁锁箱寄出，Bob 加
上自己的锁寄回，Alice 拆掉自己的锁再寄，Bob 开箱——两次「加锁
拆锁」依**交换律**抵消，双方从未共享密钥：

```coq
Definition shamirRun : list nat :=
  let s1 := powmod g0 mA pg in      (* Alice 上锁：g^m *)
  let s2 := powmod s1 kB pg in      (* Bob 再上锁：g^{mk} *)
  let s3 := powmod s2 m'A pg in     (* Alice 拆锁：g^{mk m'} = g^k *)
  let s4 := powmod s3 k'B pg in     (* Bob 拆锁：g^{k k'} = g *)
  [s1; s2; s3; s4].
```

参数（p=17, g=3, Alice 5/13, Bob 7/23——逆元方程 5·13≡7·23≡1
mod 16 由 `shamir3_keys` 记账）。账本（`shamir3_opens_box`）：
四步 **[5; 10; 11; 3]**——末步恰为明文 g=3，而 Eve 全程可见的三
个中间值（5、10、11）都不含 g。她要反推 m 只有解 DLP——小群
秒解（Prolog 件的现场），2048 位群指数爆炸。

Prolog 通道（`ex71_crypto.pl`）跑出两张教学表：**DLP 双基对照**
——基 2（Z₁₁ 的生成元）覆盖全部 10 行、基 3（阶 5）只覆盖其循
环子群的 5 行（可解性系于基的阶）；**Z₁₇* 生成元表** [3,5,6,7,
10,11,12,14]——恰 φ(16)=8 个，Shamir 的 g=3 选对了。`is_gen`
的实现有个精致的坑：费马说 g^(p−1)≡1 **恒真**（对一切与 p 互
素的 g）——判定生成元必须找**最小**阶再比对 p−1，直接验 g^(p−1)
会把全体元素误判为生成元（实测 15 个全中的假表）。

三趟协议的推广（书 p63）：数字签名（加密方向反转）与零知识证
明的种子——「知道秘密」可以只证不漏。

## 三、区块链：哈希链的最小信任机器

Satoshi 白皮书（书 p63-64 引文）的「hash-based proof-of-work」
拆到最小件就是**哈希链**：每块 = f(前块哈希, 数据)——历史被缝
进未来：

```coq
Definition blockHash (prev data : nat) : nat := hsh (prev * 5 + 3) (data + 1).

Fixpoint buildChain (data : list nat) (prev : nat) : list (nat * nat) := ...

Fixpoint chainOK (prev : nat) (l : list (nat * nat)) : bool :=
  match l with
  | [] => true
  | (d, h) :: rest =>
      andb (Nat.eqb h (blockHash prev d)) (chainOK h rest)
  end.
```

账本（`honest_chain` + `tampering_breaks`）：诚实链 [10;20;30]
验证通过；**篡改中间块数据（20→99）后整链立刻失配**——改任何
历史数据都要重算其后全部哈希。PoW 的作用是让「重算」贵到不划算
（每块哈希要满足难度条件，重写整条链的成本超过诚实挖矿——51%
攻击的经济门槛）。信任从「相信机构」变成「相信算术+经济」。

实现侧的实测坑（CHEATSheet 入账）：toy 哈希的模数起初取 9973
——**unary nat 的 mod 归约是 O(被除数) 步**，每次折叠三十万步
kernel 操作，整链 rfl 卡死三分钟；降到 97 后 8 秒全绿。**密码学
强度与教学机制（雪崩+链式依赖）在模数选择上互不耽误**——「机
器件的参数也是语义」的又一例。

## 四、量子一瞥：纠缠锥与 Shor 的威胁

n 个 qubit 的态空间是 C^{2^n}——**张量维数指数增长**是量子计算
的威力之源（书 p64-66）。两 qubit 纯态系数 λ=(λ₀₀,λ₀₁,λ₁₀,λ₁₁)，
**可分离**（=两个单 qubit 的张量积）当且仅当系数矩阵秩 1，即
**锥方程** λ₀₀λ₁₁ = λ₀₁λ₁₀：

```coq
Definition separable (l : nat * (nat * (nat * nat))) : bool :=
  Nat.eqb ((fst l) * (snd (snd (snd l))))
          ((fst (snd l)) * (fst (snd (snd l)))).
```

（实现坑：起初写成差式判零 `λ₀₀λ₁₁ − λ₀₁λ₁₀ =? 0`——**nat 截
断减法让积差为负的纠缠态误判**（0−1 塌成 0）；等式判定免疫。）
账本（`entangle_ledger`）六态：Bell 态 (|00⟩+|11⟩)/√2 与 (|01⟩+
|10⟩)/√2 **纠缠**（积差 ±1）；积态与全均匀态可分离。纠缠是
EPR「幽灵般超距作用」的代数面目——测量一个 qubit 立即决定另一
个。**Shor 1994**：量子 Fourier 变换+数论后处理在量子机上多项
式时间分解 N（阶发现→连分数→因子）——RSA 的远期威胁；当前工
程瓶颈在退相干（书 p66 只点到 Hadamard/CNOT 门矩阵，此处不展开）。

## 五、神经网络与 TDA（文档线收尾）

- **感知器**（机器件 `andGate`/`orGate`/`xor_linear_impossible`）：
  AND/OR 有一元整数权重解（w₁=w₂=1, θ=2/1）；**XOR 四点（对角
  同色）没有任何直线可分**——枚举 9×9×19 组 (w₁,w₂,θ) 无一实
  现四点全对。1969 Minsky–Papert 的这本判词引发了第一次 AI 寒
  冬；多层堆叠跨过边界（深度>宽度，书 p70 的要点），代价是训
  练只能走梯度下降/反向传播。
- **不可判定的深度学习**（书 p72）：神经网络的某些性质（如代
  价函数全局最优的存在形式）已被证明不可判定——「一如 Turing
  机」——43 章的不可判定性在新土壤里重现。
- **TDA**（书 p72-73）：Vietoris–Rips 复形（距离 ≤ε 连边）/
  Čech 复形（球交非空）从数据云构造单纯复形；Betti 数 b_n(ε)
  随 ε 变化画出 **barcode**——长条=真拓扑特征、短条=噪声。
  79 章（原 ch3 同调节）的 Betti 数在这里找到数据科学的应用。

## 小结

数论从 Hardy 的「无用之学」变成信任的底座，靠的是单向函数的
算术：模幂正向易反向难（RSA/DLP）、哈希链把历史缝进未来（区块
链）、素性测试有概率-确定双轨（Miller–Rabin/AKS）。机器面六件
全绿：RSA 九消息回环（含 gcd≠1 边界——CRT 的免费午餐）、Shamir
四步开箱（Eve 视角账）、篡改级联（[10;20;30]→99 即断）、纠缠
锥（Bell 态 vs 积态）、感知器边界（XOR 枚举无解）、DLP 双基表
（生成元 8 个）。Prolog 的回溯搜索与 Coq/Lean 的账本互补——
「反向走」的每一步困难都在表上现形。下一章回到集合论宇宙：计
数、幂集与无穷的阶梯。

---

上一章：[70 整除性与初等数论](docs/70-divisibility.md) · 下一章：[72 集合、幂集与计数](docs/72-setscount.md)
