# 第 122 章　AD^{L(ℝ)} 与全书主线汇合

[上一章：投影集合稳赢性 II](121-pd2.md) · [返回目录](../README.md) · [下一章：全书收官](123-finale.md)

## 1. 本章要完成什么

第 120 章与第 121 章已经走完投影决定性的主要路线。

整齐树把实数集合成员资格转化为测度塔的可数完备性。

弱整齐树增加了实数见证，Martin–Steel 的交错链则处理补集与投影。

本章要回答一个更大的问题：为什么这些构造最终不仅给出投影集合的决定性，还能覆盖 \(L(\mathbb R)\) 中所有实数集合？

答案不是再作一次简单的点类归纳。

它需要把可数子模型、力迫扩张、互补树、测度塔与泛型正确性组织成一条新的表示链。

这条链的最后一步尤其值得细看。

定理 3.74 并不是直接对 \(L(\mathbb R)\) 的层次作归纳，而是先取一个假想的非确定集合，再把序数参数极小化。

这样得到的反例只需实数参数就可定义，于是定理 3.69 的广泛贝尔表示可以上场。

最后由定理 3.73 给出决定性，矛盾随之出现。

## 2. 底本范围与阅读顺序

本章主体对应冯琦《集合论导引》第三卷 PDF 500–510，即书页 480–490。

核心内容是引理 3.94–3.98，以及定理 3.69–3.74。

这些结果的依赖关系可以概括为：

泛型正确性保证扩张中的真值转移；双树表示给出广泛贝尔性；测度塔把广泛贝尔性转成弱整齐性；前面的决定性定理再把弱整齐性转成胜负确定。

因此，本章最重要的不是孤立记住“广泛贝尔”这个名词。

真正要掌握的是每一种表示负责什么，以及它在何处把任务交给下一种表示。

有限源码只检查这条理论链尾端的若干组合影子。

它们不替代任何无限证明，也不证明任何无限博弈的决定性。

## 3. 先把最终结论说准确

假设存在严格递增的武丁基数序列

\[\langle\kappa_n:n<\omega\rangle,\qquad \kappa=\sup_n\kappa_n,\]

并且存在一个可测基数高于 \(\kappa\)。

则 \(L(\mathbb R)\) 中每一个实数集合都确定。

换句话说，

\[L(\mathbb R)\models\forall A\subseteq\mathbb R\;(A\text{ 确定}).\]

这就是本章所说的 AD^{L(ℝ)}。

这里“在 \(L(\mathbb R)\) 内”不可省略。

结论不是 ZFC 的论域 \(V\) 中所有实数集合都确定，也不是从大基数假设推出了全域 AD。

它断言的是一个特定内模型满足逐集合决定性。

## 4. 为什么恰好是 L(ℝ)

\(L(\mathbb R)\) 是从全部实数出发的可构造闭包。

它的对象可以由较早阶段的对象、序数参数与实数参数逐层定义。

与 \(L\) 相比，它把实数作为初始材料，而不是只允许从空集和序数出发。

这使它与描述集合论天然相容。

解析集合、投影集合以及更一般的实数参数可定义集合，都能在这个结构中获得合适的位置。

另一方面，AD 与实数的良序不相容。

所以 \(L(\mathbb R)\) 在大基数假设下可以表现出与 \(L\) 很不同的面貌：没有可供全部实数使用的良序，却有极强的逐集合正则性。

本章结尾的“可定义秩序”对照正来自这里。

## 5. 泛型正确性：把扩张中的真值送回 V

设 \(X\) 是一个可数模型，\(\pi_X\) 是相应的折叠或运输映射。

对公式与参数组成的对 \(\langle\varphi,a\rangle\)，称 \(X\) 是 \((<\kappa)\)-泛型正确的，直观要求是：在有关的小力迫泛型扩张中，

\[M_X[g]\models\varphi[y,\pi_X(a)]
\quad\Longleftrightarrow\quad
V\models\varphi[y,a].\]

这里有两个方向，不能只记其中一半。

模型中见证的存在必须反映为 \(V\) 中的真；\(V\) 中的真也必须能在模型扩张中找到对应见证。

“泛型”也不可省略。

普通子模型可能对某些有界公式正确，却不能自动保证任意力迫扩张后继续正确。

本章的双树构造正是围绕这种扩张稳定性展开。

## 6. 引理 3.94：一对在扩张中互补的树

引理 3.94 构造两棵树 \(T,U\)。

它们在 \(V\) 中承担集合与补集的表示任务，并且在相应的 \(V[G]\) 中继续保持互补关系。

这里的“投影互补”比普通的静态补集更强。

若只在基模型中有

\[p[T]=A,\qquad p[U]=\mathbb R\setminus A,\]

还不能保证力迫后加入的新实数也被正确分类。

泛型正确性要求新实数同样落入两个投影之一，而且不会同时落入两者。

这正是树表示能够穿过力迫扩张的关键。

后面的测度塔构造会反复使用这一点。

## 7. 引理 3.95：武丁基数提供 Q 的正确性

引理 3.95 进入武丁基数的核心用途。

在武丁基数 \(\kappa\) 下，底本所设的 \(Q_{<\kappa}\) 对 \(\langle L(\mathbb R),a\rangle\) 正确。

这里的重点不是记住一个偏序名称，而是理解武丁性质怎样提供足够多的嵌入与泛型正确点。

对给定实数参数，相关模型不只是偶然计算对一条公式。

正确性覆盖构造所需的公式与参数，并能与小力迫扩张配合。

如果说互补树提供“语法上的证书”，那么泛型正确性提供“语义上的保真”。

两者结合，才能把有限前缀上的局部信息提升为整个实数集合的表示。

## 8. 引理 3.96：正确子模型不是零星例外

仅有少数正确模型还不足以进行后续构造。

引理 3.96 提供所需的 club 或滤子条件，使泛型正确的子模型在适当结构中足够多。

“足够多”在这里是技术性要求。

后续选择必须与已有树、测度、嵌入和参数相容，不能每一步都依赖一次无法延续的偶然选择。

club 条件提供连续汇聚与封闭性，滤子条件提供大集合意义上的稳定选择。

这一步保证表示构造不是对单个模型有效，而是能沿整个所需系统一致推进。

## 9. 定理 3.69：实数参数可定义集合获得广泛贝尔表示

现在来到本章第一个总装结果。

沿用严格递增武丁序列及高于其全体的可测基数假设。

若实数集合 \(A\) 在 \(L(\mathbb R)\) 中以实数为参数可定义，则 \(A\) 是 \((<\kappa)\)-广泛贝尔集合。

并且存在树 \(T,T^*\)，在小力迫扩张中持续分别表示 \(A\) 与其补集。

“广泛”不是修饰性的形容词。

它表示互补树表示在一族足够广泛的泛型扩张中都保持有效，而不是只对单独选出的一个扩张有效。

这为后面构造测度塔提供了统一证书。

定理 3.74 之所以先把任意反例归约为实数参数可定义反例，就是为了精确接上定理 3.69 的入口。

## 10. 定理 3.69 的证明怎样使用前面三条引理

证明先把目标公式与实数参数放进合适的可数模型。

引理 3.95 和引理 3.96 保证可以选到足够多的泛型正确模型。

引理 3.94 的双树构造则在每个相关扩张中给出集合与补集的投影证书。

不同模型的证书需要沿包含、折叠与嵌入保持一致。

这里不能只把若干棵树取并集就宣布完成。

必须验证投影中的分支能够穿过相应模型变化，而且新实数仍被正确分类。

广泛贝尔性正是这些一致性检查完成后的统一名称。

## 11. 引理 3.97：把树裁到可控大小

定理 3.69 给出了树，但后续测度构造还需要大小控制。

引理 3.97 把树裁成大小不超过 \(\kappa\) 的子树，同时保持泛型扩张中的投影。

裁剪不能破坏分支。

对每一个应被表示的实数，至少要保留一条见证分支；对不应被表示的实数，也不能因裁剪意外制造新分支。

第二点在普通子树中通常自动得到帮助，因为删节点不会增加分支。

真正的负担是保留所有必要见证，并在扩张中维持互补表示。

大小界则使下一步可以在指定的测度与基数范围内工作。

## 12. 引理 3.98：从持续互补到测度塔

引理 3.98 把双树表示转成测度塔。

直观上，树截段上的“可被正确延拓”被组织成测度为一的大集合。

不同长度的测度必须按前缀投影相容。

泛型扩张中的持续互补性用来排除伪分支：若各层看似都有大集合见证，却无法拼成真正的实数分支，就会在适当扩张中与互补树判据冲突。

因此测度塔不是从树形任意贴上的装饰。

它记录的是双树在力迫下的稳定分类能力。

可数完备性继续承担第 120 章已经强调的任务：把逐层的大集合变成贯穿整个塔的线程。

## 13. 定理 3.70：广泛贝尔集合成为弱整齐苏斯林集合

定理 3.70 的局部形式是：在武丁基数 \(\kappa\) 下，\(\kappa\)-广泛贝尔集合对每个 \(\gamma<\kappa\) 都是 \(\gamma\)-弱整齐苏斯林集合。

这条定理把本章的新表示接回第 121 章的旧表示。

广泛贝尔性的优势在力迫扩张中，弱整齐性的优势在测度塔与决定性定理中。

二者不是互相竞争的定义，而是证明流水线的前后两站。

对每个 \(\gamma<\kappa\) 都有表示也很重要。

后文常需要在武丁序列中向上移动，以获得足够强的测度与嵌入假设。

## 14. 定理 3.71：在序列上确界处三种表示合流

令 \(\kappa_\omega=\sup_n\kappa_n\)。

定理 3.71 说明，在这一上确界处，弱整齐、整齐与广泛贝尔三种表示等价。

从广泛贝尔到弱整齐由定理 3.70 提供。

从弱整齐到整齐需要第 121 章的补树与投影机制。

反向及广泛贝尔方向则使用本章的泛型正确构造。

所谓“合流”不是说三个定义在字面上相同。

它表示在当前大基数环境中，只要需要其中一种表示，就可以无损地转入另外两种继续证明。

## 15. 定理 3.72：去掉固定上确界后的 ∞ 形式

若存在任意大的武丁基数，则三种“∞”表示也等价。

这里不能再只盯着一个预先固定的 \(\kappa_\omega\)。

对给定集合，可以在足够高的武丁基数处取得所需表示，再使用局部等价定理。

“任意大”保证这种向上移动永远可行。

这也是为什么本章反复区分局部基数与全局假设。

局部定理说明在固定高度能做什么，全局定理则说明没有预先指定高度时仍能逐集合找到足够高的位置。

## 16. 定理 3.73：广泛贝尔表示加上决定性假设预算

定理 3.73 给出本章最后一个桥梁。

若 \(A\) 是 \(\kappa\)-广泛贝尔集合，并且存在两个不超过 \(\kappa\) 的武丁基数，则 \(A\) 确定。

证明使用定理 3.70、定理 3.65、一个可测基数，以及第 120 章的定理 3.55。

这条依赖表说明决定性并不是广泛贝尔性的自动推论。

广泛贝尔性先提供弱整齐表示，Martin–Steel 机制再处理补集与投影，最后由整齐集合的决定性定理完成胜负翻译。

可测基数也在假设预算中，不应从叙述里删掉。

## 17. 为什么需要两个武丁基数

两个武丁基数不是计数上的巧合。

一个层次的表示往往只能控制当前集合及其辅助树。

处理补集、投影或策略翻译时，需要在更高一层重新取得足够强的测度与嵌入。

第 121 章的交错链已经显示，单步归纳会消耗假设。

本章把同一原则推进到 \(L(\mathbb R)\)。

因此读定理 3.73 时，应同时记录“输入表示”“所需大基数”“输出结论”三栏，而不是只记输出“确定”。

## 18. 定理 3.74：从逐集合表示到 L(ℝ) 全体决定性

现在正式证明 AD^{L(ℝ)}。

反设 \(L(\mathbb R)\) 中存在非确定的实数集合。

在所有可能的定义中，对所需的序数参数作极小化。

由此得到一个非确定集合，它在 \(L(\mathbb R)\) 中仅以某个实数 \(a\) 为参数可定义。

这一步把问题从“任意对象”压缩到定理 3.69 能处理的形状。

随后由定理 3.69 得到该集合的广泛贝尔表示，再取 \(\kappa_5\) 应用定理 3.73。

定理 3.73 说该集合确定，与反设矛盾。

## 19. 序数参数极小化究竟做了什么

\(L(\mathbb R)\) 的一般定义可能同时含序数参数和实数参数。

定理 3.69 的入口却要求实数参数可定义。

若直接对定义复杂度归纳，会被任意序数参数挡住。

极小化利用“存在反例”这一全局假设：在所有能定义反例的序数参数中选择最小者。

这样，最小性本身可以用来消除额外的序数自由度，把反例规范化为只用实数参数的形式。

这是本章最精巧也最容易被略过的一步。

没有它，定理 3.69 与定理 3.74 之间仍有明显间隙。

## 20. 为什么底本在末步取 κ₅

定理 3.74 的证明不是随手从序列中取一个下标。

底本明确取 \(\kappa_5\)。

这为定理 3.69 的表示、定理 3.73 所需的两个武丁基数及相关可测条件留下足够空间。

取更高下标不会损害结论，因为序列严格递增，上方的假设仍然可用。

但记账时应忠实记录底本选择，而不是把“存在某个足够大的下标”与原文的具体 \(\kappa_5\) 混为一谈。

这也再次体现全书的假设消耗纪律。

## 21. AD 与 AC 的冲突发生在哪一层

在 ZFC 中，利用实数的良序可以构造非确定博弈。

因此全域 AC 与全域 AD 不能同时成立。

本章没有推翻这个事实。

它证明的是：在强大基数假设下，内模型 \(L(\mathbb R)\) 满足 AD。

在这个内模型里，实数集合的逐集合正则性压倒了为全部实数配备良序的可能。

所以正确的对照是：

ZFC 的外部论域继续服从 AC；内部的 \(L(\mathbb R)\) 则呈现 AD 世界。

若把结论简写为“ZFC 推出 AD”，就丢掉了最关键的模型边界。

## 22. 连续统假设在这里获得什么面貌

在 AD 下，每个不可数实数集合都有完美子集。

因此不存在大小恰为 \(\omega_1\) 的实数集合，也不存在把全部实数排成 \(\omega_1\) 序列的良序。

就 \(L(\mathbb R)\) 内部而言，经典形式“实数全体与 \(\omega_1\) 等势”的 CH 不成立。

这不是用大基数在 \(V\) 中直接算出连续统的数值。

它是 AD 内模型中的结构性结论：实数不能被那样良序化。

本章因此把第 93 章以来的大基数主线与连续统问题重新接上，但没有把两条问题混成同一个命题。

## 23. 可定义秩序的对照

在 Gödel 的 \(L\) 中，可构造性给出强而统一的可定义良序。

在 AD 的 \(L(\mathbb R)\) 中，全部实数的良序不可能继续存在，无论是否可定义。

这并不表示 \(L(\mathbb R)\) 缺乏定义结构。

恰恰相反，它的层次仍由定义生成，并且本章的证明正是利用定义参数作极小化。

被取消的是把这些定义组织成全体实数良序的能力。

“有层次定义”与“有实数良序”是两件事。

## 24. AD 给出的实数正则性

决定性带来的不是单纯博弈术语。

在相应的 ZF 背景中，AD 给出实数集合的完美集性质、勒贝格可测性与贝尔性质等强正则性。

完美集性质说：实数集合要么可数，要么包含一个完美子集。

这把不可数集合的最小规模直接推到连续统大小的闭结构上。

勒贝格可测性与贝尔性质则排除了用选择原则制造的典型病态集合。

本章有限完美树模型只检查一个密度界，不能冒充这些无限定理的证明。

## 25. 两条全书主线怎样汇合

一条主线从内模型与大基数出发：可构造性、可测基数、迭代、武丁基数、测度塔。

另一条主线从实数集合的结构出发：贝尔空间、苏斯林表示、投影点类、博弈与决定性。

本章的广泛贝尔表示把两条线扣在一起。

大基数不再只是很大的序数，而是为实数集合提供稳定树证书与测度证书的资源。

描述集合论也不再只是低层点类分类，而成为读取大基数结构后果的语言。

这就是 AD^{L(ℝ)} 在全书中的汇合意义。

## 26. 有限机器件的边界

以下七通道只处理有限历史、有限收益表、有限树截段和有限参数编码。

长度四博弈的全部收益表有 \(2^{16}=65536\) 张，可以穷举。

无限博弈的收益表则有不可数无穷多种可能，策略也依赖无限历史树。

有限穷举既不构造 AC 所需的非确定集，也不证明 Martin–Steel 定理、广泛贝尔表示或 AD^{L(ℝ)}。

它的作用是独立检查策略坐标、量词次序、尾等价代表、完美树密度界和参数配对。

这些底层组合关系若写错，后面的数学解释也会跟着错位。

## 27. 长度四博弈的终局坐标

张三在位置 0、2 行动，李四在位置 1、3 行动。

把四步历史 \((x_0,x_1,x_2,x_3)\) 编码为

\[k=x_0+2x_1+4x_2+8x_3.\]

因此开局动作位于最低位，最后一个动作位于最高位。

一张收益表就是 16 个布尔值，也可看成一个 16 位整数。

第 \(k\) 位为 1 表示张三在终局 \(k\) 获胜，为 0 表示李四获胜。

同一坐标约定贯穿 Lean、Julia、Python 与 Prolog，Isabelle 则直接使用四步历史列表。

## 28. 张三只有 8 个不同策略

张三先选择开局 \(a_0\)。

到位置 2 时，他只需根据实际发生的 \(a_0\) 与李四回应 \(b_0\) 行动。

由于 \(a_0\) 已由自己的开局固定，真正需要预备的是对 \(b_0=0\) 和 \(b_0=1\) 的两个回应 \(z_0,z_1\)。

所以不同策略由 \((a_0,z_0,z_1)\) 决定，共 \(2^3=8\) 个。

若用五位原始编码，会包含两个永远不会同时影响对弈的位。

原始编码数 32 不等于不同策略数 8。

Julia 与 Python 都显式检查了这个归并结果。

## 29. 李四只有 64 个不同策略

李四第一次回应要分别为张三开局 0、1 准备 \(b_{00},b_{01}\)。

第二次回应只需针对四个相关历史 \((a_0,a_2)\) 准备

\[q_{000},q_{001},q_{100},q_{101}.\]

其中第一次回应已经由 \(a_0\) 决定，不再作为独立坐标重复计数。

所以不同策略共有 \(2^6=64\) 个。

原始十位编码含不会与自身早期回应共同出现的槽位，不能直接当作 1024 个不同策略。

不同策略对总数因此是

\[8\times64=512.\]

## 30. 自底向上填表必须保持量词次序

动态规划从叶层开始。

位置 3 属于李四，对两个末步收益取最小；位置 2 属于张三，取最大；随后依次交替。

实现时不能把叶子简单按相邻两两归并。

位置 \(p\) 的两个分支在下标上相隔 \(2^p\)，所以归并步长必须是这个数，并从 \(p=n-1\) 向 0 回退。

若顺序反过来，就相当于交换张三与李四的量词，所得“决定性”即使全部通过也没有意义。

Python 通道专门使用这一算法，与 Julia 的递归对弈求值相互独立。

## 31. 全表枚举的数值结果

长度四的全部 65536 张收益表都恰有一方具有必胜策略。

张三胜的表有 22687 张，李四胜的表有 42849 张。

两者之和为 65536。

长度三的全部 256 张表中，张三胜 207 张，李四胜 49 张。

这些数字不是大基数理论中的常数，也不是 AD 的概率解释。

它们只是所选有限坐标与全部收益表下的完整分类账，用来防止策略枚举漏项或重复。

## 32. 尾等价代表与 AC 构造的有限消散

无限非确定集的经典构造会利用尾等价类与选择。

在有限截断 \(2^n\) 上，尾等价关系可以直接处理：清除前 \(n-m\) 位，只保留后 \(m\) 位。

所得代表满足幂等性，并与原点保持相同后缀。

有限类不需要无限选择，相关博弈也由有限决定性自动确定。

因此这部分程序不是把 AC 反例“缩小后仍然保留”。

它恰恰显示非确定构造所依赖的无限选择在有限截断上消散。

对 \(n=4,m=2\)，按首个差异位置奇偶性定义的尾收益集合大小为 12。

## 33. 完美树密度界的组合证明

设 \(A\subseteq2^n\) 不含深度 \(d\) 的完美子树。

把 \(2^n\) 分成 \(2^{n-d}\) 个长度为 \(2^d\) 的柱。

若某一个柱的全部叶点都属于 \(A\)，这个柱就给出所禁止的完美子树。

所以每个柱至少缺少一个叶点。

于是

\[|A|\le 2^n-2^{n-d}.\]

这个证明只使用有限柱分解，却准确展示了“没有完美子树”如何转为密度上限。

程序对 \(n=4\) 的全部集合与四个深度逐一验证。

## 34. 密度界的紧例

上界不是粗略估计。

在每个柱中只删除 \(t=0\) 的那个叶点，其余全部保留。

这样每个柱都缺叶点，所以不含完整深度 \(d\) 子树。

集合大小恰为

\[2^n-2^{n-d}.\]

四个证明与计算通道都检查了相应的紧例形式。

Julia 和 Python 还检查更大的有限 \(n\)，其中 Julia 使用任意精度整数，避免位移在机器字长上回绕。

紧例与上界同时成立，才说明证书没有只验证一个宽松不等式。

## 35. 参数编码为什么也与本章有关

定理 3.74 的极小化最终留下实数参数。

有限程序无法表示一般序数与实数，但能检查“两个参数打包后可无损还原”的组合接口。

取 \(p<8\)、\(a<16\)，定义

\[\operatorname{enc}(p,a)=16p+a.\]

解码分别为整除 16 与模 16。

全部 128 组参数往返成功，并且编码恰好覆盖 0 到 127。

Isabelle 使用有序对及 `fst`、`snd` 表达同一结构思想，不假装有序对等于整数位编码。

## 36. 七通道各自证明或计算了什么

Lean 对全部有限收益函数完成 `native_decide` 证明，并证明策略排他性、完美树密度界与参数往返。

Coq 验证代表收益表上的双方证书、一般策略排他性、尾代表、紧例和参数往返。

Agda 以可计算布尔证书验证代表收益表及全部 16 个尾终局，并检查四个深度的紧例。

Isabelle 在 ZF 中把收益表写成谓词，直接对四步历史列表验证双方策略证书。

Julia 用递归对弈求值穷举全部收益表。

Python 用独立的自底向上填表法穷举同样的表。

Prolog 再次以交替量词动态规划穷举，并检查全部有限完美树集合。

## 37. Lean：全有限收益表的机器证明

Lean 的 `Fin 16 → Bool` 精确表示一张长度四收益表。

`payAt` 用模 16 查询固定接口，避免布尔下标边界证明散落各处。

`iAny` 与 `iiAny` 分别枚举 8 个张三策略和 64 个李四策略。

`finite_determinacy_length4` 对所有收益函数作原生计算，证明至少一方有证书。

`exclusive_strategies_length4` 再证明任意双方策略不可能同时必胜。

两点合起来才是“恰一方”。

后续定理还覆盖尾代表、完美树密度界、四个紧例和 128 组参数往返。

```lean
import Mathlib.Data.Fintype.Pi

/-
  第 122 章：AD^{L(R)} 的有限影子。
  长度四的有限博弈、尾等价代表、完美树密度界与定义参数编码。
  所有定理只涉及有限对象，不证明 AD、AD^{L(R)} 或无限博弈决定性。
-/

-- 安全查表：所有已给出的下标均小于 16；模运算同时固定证明接口。
def payAt (f : Fin 16 → Bool) (k : Nat) : Bool :=
  f ⟨k % 16, Nat.mod_lt _ (by decide)⟩

-- 张三策略：(开局，位置二对 b=0 的回答，对 b=1 的回答)。
def iWins (f : Fin 16 → Bool) (a0 z0 z1 : Bool) : Bool :=
  (payAt f (a0.toNat + 4 * z0.toNat) &&
   payAt f (a0.toNat + 4 * z0.toNat + 8)) &&
  (payAt f (a0.toNat + 2 + 4 * z1.toNat) &&
   payAt f (a0.toNat + 2 + 4 * z1.toNat + 8))

-- 李四策略：(b 对 a0=0/1 的回答，b1 对四个相关历史的回答)。
def iiWins (f : Fin 16 → Bool)
    (b00 b01 q000 q001 q100 q101 : Bool) : Bool :=
  (!(payAt f (2 * b00.toNat + 8 * q000.toNat)) &&
   !(payAt f (2 * b00.toNat + 4 + 8 * q001.toNat)) &&
   !(payAt f (1 + 2 * b01.toNat + 8 * q100.toNat)) &&
   !(payAt f (1 + 2 * b01.toNat + 4 + 8 * q101.toNat)))

def iAny (f : Fin 16 → Bool) : Bool :=
  [false, true].any fun a0 => [false, true].any fun z0 =>
    [false, true].any fun z1 => iWins f a0 z0 z1

def iiAny (f : Fin 16 → Bool) : Bool :=
  [false, true].any fun b00 => [false, true].any fun b01 =>
  [false, true].any fun q000 => [false, true].any fun q001 =>
  [false, true].any fun q100 => [false, true].any fun q101 =>
    iiWins f b00 b01 q000 q001 q100 q101

-- 与 Julia/Python 相同的终局下标。
def play4 (a0 z0 z1 b00 b01 q000 q001 q100 q101 : Bool) : Nat :=
  let b0 := if a0 then b01 else b00
  let a2 := if b0 then z1 else z0
  let q := if a0 then (if a2 then q101 else q100)
           else (if a2 then q001 else q000)
  a0.toNat + 2 * b0.toNat + 4 * a2.toNat + 8 * q.toNat

-- 全部 65536 张收益表恰至少一方有必胜策略；排他性由下一定理给出。
theorem finite_determinacy_length4 (f : Fin 16 → Bool) :
    (iAny f || iiAny f) = true := by
  revert f
  native_decide

-- 任意张三/李四策略不可能同时必胜：在对弈终点收益既要真又要假。
theorem exclusive_strategies_length4
    (f : Fin 16 → Bool) (a0 z0 z1 b00 b01 q000 q001 q100 q101 : Bool) :
    (!(iWins f a0 z0 z1 && iiWins f b00 b01 q000 q001 q100 q101)) = true := by
  revert f a0 z0 z1 b00 b01 q000 q001 q100 q101
  native_decide

-- 尾等价代表：保留高两位，清除低两位；n=4、m=2。
def tailRep (x : Nat) : Nat := x / 4 * 4

theorem tailrep_idempotent (x : Fin 16) : tailRep (tailRep x.val) = tailRep x.val := by
  revert x
  decide +kernel

theorem tailrep_same_class (x : Fin 16) : tailRep x.val / 4 = x.val / 4 := by
  revert x
  decide +kernel

def tailPayoff (x : Fin 16) : Bool := decide (x.val % 4 ≠ 1)

theorem tailset_size_12 :
    ((List.finRange 16).filter tailPayoff).length = 12 := by decide

-- A 含深度 d 的完美子树：存在柱 s，其全部 2^d 个叶点都属于 A。
def hasPerfect (f : Fin 16 → Bool) (d : Nat) : Bool :=
  (List.finRange (2 ^ (4 - d))).any fun s =>
    (List.finRange (2 ^ d)).all fun t =>
      f ⟨(s.val * 2 ^ d + t.val) % 16, by omega⟩

-- 有限完美集性质：无深度 d 完美树则至多缺 2^(4-d) 个柱各留一叶之外。
theorem perfect_tree_density_bound (f : Fin 16 → Bool) (d : Fin 4) :
    hasPerfect f (d.val + 1) = false →
      ((List.finRange 16).filter f).length ≤ 16 - 2 ^ (4 - (d.val + 1)) := by
  revert f d
  native_decide

-- 紧例：每柱恰删去 t=0 的叶点。
def tightSet (d : Nat) (x : Fin 16) : Bool :=
  !(decide (x.val % (2 ^ d) = 0))

theorem perfect_bound_tight (d : Fin 4) :
    hasPerfect (tightSet (d.val + 1)) (d.val + 1) = false ∧
    ((List.finRange 16).filter (tightSet (d.val + 1))).length =
      16 - 2 ^ (4 - (d.val + 1)) := by
  revert d
  decide +kernel

-- L(R) 的每个对象可由序数参数和实数参数定义；这里验证参数配对。
def encParam (p : Fin 8) (a : Fin 16) : Fin 128 :=
  ⟨p.val * 16 + a.val, by omega⟩

def decParam (c : Fin 128) : Fin 8 × Fin 16 :=
  (⟨c.val / 16, by omega⟩, ⟨c.val % 16, by omega⟩)

theorem param_roundtrip (p : Fin 8) (a : Fin 16) :
    decParam (encParam p a) = (p, a) := by
  revert p a
  decide +kernel
```

## 38. Isabelle：ZF 中的历史列表与收益谓词

Isabelle 通道不把 ZF 函数误写成 HOL 函数应用。

它把收益表表示成谓词 `P`，`P(h)` 表示历史 `h` 归张三胜。

张三证书要求四个可达终局都满足 `P`，李四证书要求四个可达终局都满足其否定。

偶数下标表被改写为“开局动作是 0”，因为最低位就是开局。

一般布尔前提用析取明确列出，避免把任意 ZF 集合当成 0/1 动作。

尾代表直接清除列表前两位，参数打包则使用集合论有序对。

```isabelle
theory Adlr imports "ZF.List" "ZF.Arith" "ZF.equalities" begin

text \<open>第 122 章：AD 的有限影子。0/1 表示动作；只验证有限证书，
不构造无限非确定博弈，也不证明 AD^{L(R)}。\<close>

text \<open>张三在位置 0、2 行动；z0、z1 分别是对李四回应 0、1 的准备。\<close>
definition IWins where
  "IWins(P,a0,z0,z1) \<equiv>
    P([a0,0,z0,0]) & P([a0,0,z0,1]) &
    P([a0,1,z1,0]) & P([a0,1,z1,1])"

text \<open>李四只给实际可达历史指定回应，共 2^6 个不同策略。\<close>
definition IIWins where
  "IIWins(P,b00,b01,q000,q001,q100,q101) \<equiv>
    ~P([0,b00,0,q000]) & ~P([0,b00,1,q001]) &
    ~P([1,b01,0,q100]) & ~P([1,b01,1,q101])"

text \<open>终局下标的最低位就是开局动作，故开局为 0 等价于下标为偶数。\<close>
definition EvenPay where
  "EvenPay(h) \<equiv> hd(h)=0"

definition NeverPay where "NeverPay(h) \<equiv> False"

lemma even_i_certificate:
  "IWins(EvenPay,0,0,0)"
  by (simp add: IWins_def EvenPay_def)

lemma even_no_ii_strategy:
  "b00=0|b00=1 \<Longrightarrow> b01=0|b01=1 \<Longrightarrow>
   q000=0|q000=1 \<Longrightarrow> q001=0|q001=1 \<Longrightarrow>
   q100=0|q100=1 \<Longrightarrow> q101=0|q101=1 \<Longrightarrow>
   ~IIWins(EvenPay,b00,b01,q000,q001,q100,q101)"
  by (elim disjE; simp add: IIWins_def EvenPay_def)

lemma never_ii_certificate:
  "IIWins(NeverPay,0,0,0,0,0,0)"
  by (simp add: IIWins_def NeverPay_def)

lemma never_no_i_strategy:
  "a0=0|a0=1 \<Longrightarrow> z0=0|z0=1 \<Longrightarrow> z1=0|z1=1 \<Longrightarrow>
   ~IWins(NeverPay,a0,z0,z1)"
  by (elim disjE; simp add: IWins_def NeverPay_def)

text \<open>尾等价代表：清除前两位，保留后两位；在四个代表上检查幂等。\<close>
definition TailRep where
  "TailRep(h) \<equiv> [0,0,hd(tl(tl(h))),hd(tl(tl(tl(h))))]"

lemma tailrep_examples:
  "TailRep([1,0,1,1])=[0,0,1,1] & TailRep([0,1,0,1])=[0,0,0,1]"
  by (simp add: TailRep_def)

lemma tailrep_idempotent_examples:
  "TailRep(TailRep([1,0,1,1]))=TailRep([1,0,1,1]) &
   TailRep(TailRep([0,1,0,1]))=TailRep([0,1,0,1])"
  by (simp add: TailRep_def)

text \<open>完美树紧例：每个低位柱恰删去全零叶点。\<close>
definition TightOne where
  "TightOne(h) \<equiv> (if hd(h)=0 then 0 else 1)"

definition TightTwo where
  "TightTwo(h) \<equiv> (if hd(h)=0 & hd(tl(h))=0 then 0 else 1)"

lemma tight_depth_1:
  "TightOne([0,1,1,1])=0 & TightOne([1,0,0,0])=1"
  by (simp add: TightOne_def)

lemma tight_depth_2:
  "TightTwo([0,0,1,1])=0 & TightTwo([0,1,0,0])=1 &
   TightTwo([1,0,0,0])=1 & TightTwo([1,1,0,0])=1"
  by (simp add: TightTwo_def)

text \<open>L(R) 定义所需的序数参数与实数参数可由有序对打包、投影还原。\<close>
definition EncParam where "EncParam(p,a) \<equiv> <p,a>"

lemma param_roundtrip_example:
  "fst(EncParam(0,1))=0 & snd(EncParam(0,1))=1"
  by (simp add: EncParam_def)

end
```

## 39. Coq：代表收益表与一般排他性

Coq 使用 `nat -> bool` 作为收益函数接口。

`triples` 枚举张三的 8 个策略，`sextuples` 枚举李四的 64 个策略。

偶数收益表与空收益表分别给出张三、李四的代表证书。

`exclusive_strategies_length4` 对任意收益函数和任意双方策略证明不可同时必胜。

这里没有用失控的全表 `vm_compute; btauto` 冒充高效证明。

全 65536 表的穷举由 Lean、Julia、Python 和 Prolog 承担，Coq 的范围必须按实际定理陈述理解。

```coq
Require Import Bool List Btauto Arith Lia.
Import ListNotations.

(* 第 122 章：AD^{L(R)} 的有限影子。
   有限博弈、尾等价代表、完美树密度界与参数编码；不证明无限 AD。 *)

Definition b2n (b : bool) : nat := if b then 1 else 0.

Definition i_wins (f : nat -> bool) (a0 z0 z1 : bool) : bool :=
  (f (b2n a0 + 4*b2n z0) && f (b2n a0 + 4*b2n z0 + 8)) &&
  (f (b2n a0 + 2 + 4*b2n z1) && f (b2n a0 + 2 + 4*b2n z1 + 8)).

Definition ii_wins (f : nat -> bool)
    (b00 b01 q000 q001 q100 q101 : bool) : bool :=
  negb (f (2*b2n b00 + 8*b2n q000)) &&
  negb (f (2*b2n b00 + 4 + 8*b2n q001)) &&
  negb (f (1 + 2*b2n b01 + 8*b2n q100)) &&
  negb (f (1 + 2*b2n b01 + 4 + 8*b2n q101)).

Definition triples : list (bool*bool*bool) :=
  [(false,false,false); (false,false,true);
   (false,true,false); (false,true,true);
   (true,false,false); (true,false,true);
   (true,true,false); (true,true,true)].

Definition sextuples : list (bool*bool*bool*bool*bool*bool) :=
  flat_map (fun b00 => flat_map (fun b01 =>
  flat_map (fun q000 => flat_map (fun q001 =>
  flat_map (fun q100 => map (fun q101 =>
    (b00,b01,q000,q001,q100,q101)) [false;true])
    [false;true]) [false;true]) [false;true]) [false;true])
    [false;true].

Definition i_any (f : nat -> bool) : bool :=
  existsb (fun s => i_wins f (fst (fst s)) (snd (fst s)) (snd s)) triples.

Definition ii_any (f : nat -> bool) : bool :=
  existsb (fun s => ii_wins f
    (fst (fst (fst (fst (fst s)))))
    (snd (fst (fst (fst (fst s)))))
    (snd (fst (fst (fst s))))
    (snd (fst (fst s)))
    (snd (fst s)) (snd s)) sextuples.

Definition even_pay (x : nat) : bool := Nat.even x.
Definition never_pay (_ : nat) : bool := false.

Theorem even_i_wins : i_wins even_pay false false false = true.
Proof. reflexivity. Qed.

Theorem even_i_any : i_any even_pay = true.
Proof. reflexivity. Qed.

Theorem even_ii_any : ii_any even_pay = false.
Proof. reflexivity. Qed.

Theorem never_i_any : i_any never_pay = false.
Proof. reflexivity. Qed.

Theorem never_ii_any : ii_any never_pay = true.
Proof. reflexivity. Qed.

Theorem exclusive_strategies_length4 :
  forall f a0 z0 z1 b00 b01 q000 q001 q100 q101,
    negb (i_wins f a0 z0 z1 &&
          ii_wins f b00 b01 q000 q001 q100 q101) = true.
Proof.
  intros f [] [] [] [] [] [] [] [] []; vm_compute; btauto.
Qed.

(* 尾等价代表：保留高两位，清除低两位。 *)
Definition tail_rep (x : nat) : nat := (x / 4) * 4.

Theorem tailrep_idempotent : forall x, x < 16 ->
  tail_rep (tail_rep x) = tail_rep x.
Proof. intros x H; do 16 (destruct x; [reflexivity|]); lia. Qed.

Theorem tailrep_same_class : forall x, x < 16 ->
  tail_rep x / 4 = x / 4.
Proof. intros x H; do 16 (destruct x; [reflexivity|]); lia. Qed.

Definition tail_payoff (x : nat) : bool := negb (Nat.eqb (x mod 4) 1).
Theorem tailset_size_12 :
  length (filter tail_payoff (seq 0 16)) = 12.
Proof. reflexivity. Qed.

(* 深度 d 完美树：某长度 4-d 柱的全部 2^d 叶点均属于 A。 *)
Definition has_perfect (f : nat -> bool) (d : nat) : bool :=
  existsb (fun s => forallb (fun t => f (s*2^d+t)) (seq 0 (2^d)))
    (seq 0 (2^(4-d))).

Definition tight_set (d : nat) (x : nat) : bool :=
  negb (Nat.eqb (x mod (2^d)) 0).

Theorem perfect_bound_tight :
  forall d, 1 <= d <= 4 ->
    has_perfect (tight_set d) d = false /\
    length (filter (tight_set d) (seq 0 16)) = 16 - 2^(4-d).
Proof.
  intros d [H1 H4].
  assert (d=1 \/ d=2 \/ d=3 \/ d=4) as E by lia.
  destruct E as [Hd | [Hd | [Hd | Hd]]]; subst d; split; reflexivity.
Qed.

(* 定义参数编码：p<8 为序数参数，a<16 为实数参数。 *)
Definition enc_param (p a : nat) : nat := p*16+a.
Definition dec_param (c : nat) : nat*nat := (c/16,c mod 16).
Theorem param_roundtrip : forall p a, p<8 -> a<16 ->
  dec_param (enc_param p a) = (p,a).
Proof.
  intros p a Hp Ha; unfold dec_param,enc_param; f_equal.
  - rewrite Nat.div_add_l by lia. rewrite (Nat.div_small a 16 Ha). lia.
  - rewrite Nat.add_comm, Nat.mod_add by lia. apply Nat.mod_small, Ha.
Qed.
```

## 40. Agda：布尔归约证书

Agda 与 Coq 使用相同的策略坐标，但所有证书都通过定义归约和 `refl` 完成。

自建 `anyb`、`allb`、`filterb` 避免可判定版本与布尔版本混淆。

尾代表在全部 16 个终局上检查幂等和同尾类关系。

完美树紧例对四个深度分别列出，不依赖隐含的算术自动化。

参数证书检查具体往返和编码值。

这些是有限可计算定理，不是无限 AD 的形式化。

```agda
module Ch122_adlr where

open import Data.Bool using (Bool; false; true; not; _∧_; _∨_; if_then_else_)
open import Data.Nat using (ℕ; zero; suc; _+_; _∸_; _*_; _/_; _%_; _^_; _≡ᵇ_)
open import Data.List using (List; []; _∷_; map; concatMap; length)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 第 122 章：有限 AD 影子；不代表无限空间中的非确定集。

b2n : Bool → ℕ
b2n b = if b then 1 else 0

i-wins : (ℕ → Bool) → Bool → Bool → Bool → Bool
i-wins f a0 z0 z1 =
  (f (b2n a0 + 4 * b2n z0) ∧ f (b2n a0 + 4 * b2n z0 + 8)) ∧
  (f (b2n a0 + 2 + 4 * b2n z1) ∧ f (b2n a0 + 2 + 4 * b2n z1 + 8))

ii-wins : (ℕ → Bool) → Bool → Bool → Bool → Bool → Bool → Bool → Bool
ii-wins f b00 b01 q000 q001 q100 q101 =
  not (f (2 * b2n b00 + 8 * b2n q000)) ∧
  not (f (2 * b2n b00 + 4 + 8 * b2n q001)) ∧
  not (f (1 + 2 * b2n b01 + 8 * b2n q100)) ∧
  not (f (1 + 2 * b2n b01 + 4 + 8 * b2n q101))

bools : List Bool
bools = false ∷ true ∷ []

triples : List (Bool × Bool × Bool)
triples = concatMap (λ a0 → concatMap (λ z0 →
  map (λ z1 → (a0 , z0 , z1)) bools) bools) bools

sextuples : List (Bool × Bool × Bool × Bool × Bool × Bool)
sextuples = concatMap (λ b00 → concatMap (λ b01 →
  concatMap (λ q000 → concatMap (λ q001 → concatMap (λ q100 →
  map (λ q101 → (b00 , b01 , q000 , q001 , q100 , q101)) bools)
  bools) bools) bools) bools) bools

anyb : {A : Set} → (A → Bool) → List A → Bool
anyb p [] = false
anyb p (x ∷ xs) = p x ∨ anyb p xs

allb : {A : Set} → (A → Bool) → List A → Bool
allb p [] = true
allb p (x ∷ xs) = p x ∧ allb p xs

i-any : (ℕ → Bool) → Bool
i-any f = anyb (λ where (a0 , z0 , z1) → i-wins f a0 z0 z1) triples

ii-any : (ℕ → Bool) → Bool
ii-any f = anyb (λ where
  (b00 , b01 , q000 , q001 , q100 , q101) →
    ii-wins f b00 b01 q000 q001 q100 q101) sextuples

even-pay : ℕ → Bool
even-pay x = (x % 2) ≡ᵇ 0

never-pay : ℕ → Bool
never-pay _ = false

-- 代表收益表上双方胜负恰好相反；张三证书是 (0,0,0)。
even-i-wins : i-wins even-pay false false false ≡ true
even-i-wins = refl

even-i-any : i-any even-pay ≡ true
even-i-any = refl

even-ii-any : ii-any even-pay ≡ false
even-ii-any = refl

never-i-any : i-any never-pay ≡ false
never-i-any = refl

never-ii-any : ii-any never-pay ≡ true
never-ii-any = refl

-- 尾等价代表：保留高两位，清除低两位；在全部 16 个终局上检查。
tail-rep : ℕ → ℕ
tail-rep x = (x / 4) * 4

upto : ℕ → List ℕ
upto zero = []
upto (suc n) = zero ∷ map suc (upto n)

terminal16 : List ℕ
terminal16 = upto 16

tailrep-idempotent-all :
  map (λ x → tail-rep (tail-rep x)) terminal16 ≡ map tail-rep terminal16
tailrep-idempotent-all = refl

tailrep-same-class-all :
  map (λ x → tail-rep x / 4) terminal16 ≡ map (λ x → x / 4) terminal16
tailrep-same-class-all = refl

tail-payoff : ℕ → Bool
tail-payoff x = not ((x % 4) ≡ᵇ 1)

filterb : {A : Set} → (A → Bool) → List A → List A
filterb p [] = []
filterb p (x ∷ xs) = if p x then x ∷ filterb p xs else filterb p xs

tailset-size-12 : length (filterb tail-payoff terminal16) ≡ 12
tailset-size-12 = refl

-- 完美树：某长度 4-d 柱的全部 2^d 个叶点属于 A。
has-perfect : (ℕ → Bool) → ℕ → Bool
has-perfect f d =
  anyb (λ s → allb (λ t → f (s * (2 ^ d) + t)) (upto (2 ^ d)))
    (upto (2 ^ (4 ∸ d)))

tight-set : ℕ → ℕ → Bool
tight-set d x = not (anyb (λ k → x ≡ᵇ k * (2 ^ d)) terminal16)

tight-depth-1 :
  (has-perfect (tight-set 1) 1 ≡ false) ×
  (length (filterb (tight-set 1) terminal16) ≡ 8)
tight-depth-1 = refl , refl

tight-depth-2 :
  (has-perfect (tight-set 2) 2 ≡ false) ×
  (length (filterb (tight-set 2) terminal16) ≡ 12)
tight-depth-2 = refl , refl

tight-depth-3 :
  (has-perfect (tight-set 3) 3 ≡ false) ×
  (length (filterb (tight-set 3) terminal16) ≡ 14)
tight-depth-3 = refl , refl

tight-depth-4 :
  (has-perfect (tight-set 4) 4 ≡ false) ×
  (length (filterb (tight-set 4) terminal16) ≡ 15)
tight-depth-4 = refl , refl

-- 定义参数编码：序数参数 p 与实数参数 a 配对为纯位串下标。
enc-param : ℕ → ℕ → ℕ
enc-param p a = p * 16 + a

dec-param : ℕ → ℕ × ℕ
dec-param c = (c / 16 , c % 16)

param-roundtrip-example : dec-param (enc-param 5 11) ≡ (5 , 11)
param-roundtrip-example = refl

param-injective-example : enc-param 5 11 ≡ 91
param-injective-example = refl
```

## 41. Julia：递归对弈与位掩码集合

Julia 用整数的位表示收益表与策略强制终局集。

`play4` 实际按双方策略走一步完整对弈，确保策略编码与终局坐标一致。

对每张表，程序分别判断是否存在张三或李四的必胜策略，并要求二者恰有一个成立。

尾代表检查覆盖 \(n=1\) 到 6 的所有合法 \(m\)。

完美树部分穷举 \(n=4\) 的全部集合，并以 `BigInt` 构造更大的紧例。

```julia
# 第 122 章：AD^{L(R)} 的有限影子。
# 四件机器：有限决定性全枚举、尾等价代表（AC 反例的有限截断）、
# 完美集密度界（AD 正则性后果）、L(R) 定义参数编码。
# 边界：所有件都是有限对象，不证明 AD，也不构造 AC 的非确定博弈。

bit(table, k) = ((table >> k) & 1) == 1

# ---------- 件 1：长度 4 有限博弈的全表决定性 ----------
# 位置 0,2 张三行动；位置 1,3 李四行动；终局索引 x0+2x1+4x2+8x3。
# 张三策略 0..31：bit0=开局；bit(1+a0+2b0)=位置 2 回应。
imask4(s) = begin
    a0 = s & 1
    m = 0
    for b0 in (0, 1), b1 in (0, 1)
        a2 = (s >> (1 + a0 + 2 * b0)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    end
    m
end

# 李四策略 0..1023：bit a0=位置 1 回应；bit(2+a0+2b0+4a2)=位置 3 回应。
iimask4(t) = begin
    m = 0
    for a0 in (0, 1), a2 in (0, 1)
        b0 = (t >> a0) & 1
        b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    end
    m
end

play4(s, t) = begin
    a0 = s & 1
    b0 = (t >> a0) & 1
    a2 = (s >> (1 + a0 + 2 * b0)) & 1
    b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
    a0 + 2 * b0 + 4 * a2 + 8 * b1
end

mm4(table) =
    any(a0 -> all(b0 -> any(a2 -> all(b1 ->
        bit(table, a0 + 2*b0 + 4*a2 + 8*b1), (0, 1)), (0, 1)), (0, 1)), (0, 1))

emasks = [imask4(s) for s in 0:31]
fmasks = [iimask4(t) for t in 0:1023]
# 张三 5 bit 编码含 2 个不关心位（位置 2 只按自己的开局索引），实际 8 个不同策略；
# 李四位置 3 的 8 槽中 4 槽永不与自己的位置 1 回应共存，实际 64 个不同策略。
@assert length(unique(emasks)) == 8 && length(unique(fmasks)) == 64
# 排他性：任意张三/李四策略对产生唯一对弈点，同时落入双方“必胜终局集”。
for s in 0:31
    @assert count_ones(emasks[s+1]) == 4
    for t in 0:1023
        p = play4(s, t)
        @assert bit(emasks[s+1], p) && bit(fmasks[t+1], p)
    end
end
@assert all(==(4), map(count_ones, fmasks))

win_i = 0
win_ii = 0
for table in 0:65535
    iwins = any(m -> (table & m) == m, emasks)
    iiwins = any(f -> (table & f) == 0, fmasks)
    @assert iwins == mm4(table)          # 逆向归纳值与策略枚举一致
    @assert iwins !== iiwins             # 恰一方胜
    global win_i += iwins
    global win_ii += iiwins
end
@assert win_i + win_ii == 65536
@assert win_i == 22687 && win_ii == 42849

# 长度 3 的小表：256 张，207 张张三胜、49 张李四胜。
imask3(s) = begin
    a0 = s & 1
    m = 0
    for b0 in 0:1
        a2 = (s >> (1 + b0)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2)
    end
    m
end
iimask3(t) = begin
    m = 0
    for a0 in 0:1, a2 in 0:1
        b0 = (t >> a0) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2)
    end
    m
end
w3i = count(table -> any(m -> (table & m) == m, [imask3(s) for s in 0:7]), 0:255)
w3ii = count(table -> any(f -> (table & f) == 0, [iimask3(t) for t in 0:3]), 0:255)
@assert (w3i, w3ii) == (207, 49)

# ---------- 件 2：尾等价代表与 AC 反例的有限截断 ----------
tailrep(n, m, x) = x & (((1 << m) - 1) << (n - m))
firstdiff(n, m, x) = begin
    for j in 0:(n-m-1)
        bit(x, j) && return j
    end
    n
end
tailpay(n, m, x) = iseven(firstdiff(n, m, x))

gamevalue(n, pay) = begin
    function rec(k, idx)
        k == n && return pay(idx)
        iseven(k) ? any(z -> rec(k + 1, idx | (z << k)), (0, 1)) :
                    all(z -> rec(k + 1, idx | (z << k)), (0, 1))
    end
    rec(0, 0)
end

tail_sizes = Dict()
for n in 1:6, m in 1:n
    for x in 0:(1<<n)-1
        r = tailrep(n, m, x)
        @assert tailrep(n, m, r) == r                    # 代表幂等
        @assert (r >> (n - m)) == (x >> (n - m))         # 代表留在同类
    end
    sz = count(x -> tailpay(n, m, x), 0:(1<<n)-1)
    tail_sizes[(n, m)] = sz
    v = gamevalue(n, x -> tailpay(n, m, x))
    @assert v isa Bool                                   # 有限博弈必有确定值
end
@assert tail_sizes[(4, 2)] == 12

# ---------- 件 3：完美集密度界（AD 完美集性质的有限影子） ----------
hasperfect(A, n, d) =
    any(s -> all(t -> bit(A, (s << d) | t), 0:(1<<d)-1), 0:(1<<(n-d))-1)

for A in 0:65535, d in 1:4
    if !hasperfect(A, 4, d)
        @assert count_ones(A) <= 16 - (1 << (4 - d))
    end
end
# 紧性：每个长度 4-d 柱恰缺一个叶点，计数恰达界且无深度 d 完美树。
for d in 1:4
    missing = reduce(|, [1 << (s << d) for s in 0:(1<<(4-d))-1]; init=0)
    Astar = 65535 ⊻ missing
    @assert !hasperfect(Astar, 4, d)
    @assert count_ones(Astar) == 16 - (1 << (4 - d))
end
# 更大 n 值只验证紧例构造。
for n in 6:10, d in (1, 2, n)
    missing = reduce(|, [big(1) << (s << d) for s in 0:(1<<(n-d))-1]; init=big(0))
    Astar = (big(1) << (1 << n)) - 1 - missing
    @assert !hasperfect(Astar, n, d)
    @assert count_ones(Astar) == (1 << n) - (1 << (n - d))
end

# ---------- 件 4：L(R) 定义参数编码（序数参数吸收进实数参数） ----------
enc(p, a) = (p << 4) | a            # p < 8 序数参数，a < 16 实数参数
dec(c) = (c >> 4, c & 15)
seen = Set()
for p in 0:7, a in 0:15
    c = enc(p, a)
    @assert c in 0:127
    @assert dec(c) == (p, a)         # 往返
    push!(seen, c)
end
@assert length(seen) == 128          # 编码单射

println("==== 122")
println("finite determinacy length4: 65536/65536 tables, I=$win_i II=$win_ii")
println("length3: 256 tables, I=$w3i II=$w3ii; 8x64 strategy pairs exclusive")
println("tail-representative games n=1..6 all determined; |A_(4,2)|=12")
println("perfect-tree bound: 65536 sets x 4 depths, tight on every depth")
println("parameter codes: 128/128 round-trip")
println("END ====")
```

## 42. Python：独立的自底向上算法

Python 不复用 Julia 的递归对弈求值作为唯一判据。

`value_bottom_up` 从叶层开始，按正确步长逐层作 `any` 或 `all`。

每张表都要求这个值与策略枚举结果一致。

这能同时抓出策略漏项、坐标错位与量词次序错误。

程序还显式计算不同策略掩码数为 8 和 64，并检查全部 512 个不同策略对的排他结构。

```python
"""第 122 章：AD^{L(R)} 的有限影子（独立实现：自底向上填表 + 位掩码集合）。

四件机器：
1. 长度 4 的 65536 张有限博弈表全部决定性，且策略枚举与填表值一致；
2. 尾等价类显式代表（AC 非确定集构造在有限截断上消散）；
3. 完美集密度界及其紧例（AD 完美集性质的有限影子）；
4. L(R) 定义参数 (序数, 实数) 编码为纯位串。
有限枚举不证明 AD；AC 的非确定博弈只存在于无限空间。
"""


def bit(table, k):
    return bool((table >> k) & 1)


# ---------- 件 1：长度 4 全表决定性 ----------
def i_mask4(s):
    """张三策略 s 强制为胜的四个终局点。"""
    a0 = s & 1
    m = 0
    for b0 in (0, 1):
        a2 = (s >> (1 + a0 + 2 * b0)) & 1
        for b1 in (0, 1):
            m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    return m


def ii_mask4(t):
    """李四策略 t 强制为负的四个终局点。"""
    m = 0
    for a0 in (0, 1):
        b0 = (t >> a0) & 1
        for a2 in (0, 1):
            b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
            m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    return m


def play4(s, t):
    a0 = s & 1
    b0 = (t >> a0) & 1
    a2 = (s >> (1 + a0 + 2 * b0)) & 1
    b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
    return a0 + 2 * b0 + 4 * a2 + 8 * b1


def value_bottom_up(n, pay):
    """与 Julia 通道不同的算法：从叶层逐层 OR/AND 归并。"""
    # 叶下标 bit p 是位置 p 的动作；距叶最近的决策是位置 n-1，
    # 故按步长 2^p 从后向前归并（相邻对会错误地交换量词次序）。
    layer = [pay(k) for k in range(1 << n)]
    for pos in range(n - 1, -1, -1):
        stride = 1 << pos
        nxt = []
        for base in range(0, len(layer), 2 * stride):
            for j in range(stride):
                pair = (layer[base + j], layer[base + stride + j])
                nxt.append(any(pair) if pos % 2 == 0 else all(pair))
        layer = nxt
    return layer[0]


em = [i_mask4(s) for s in range(32)]
fm = [ii_mask4(t) for t in range(1024)]
assert len(set(em)) == 8 and len(set(fm)) == 64
assert all(m.bit_count() == 4 for m in em + fm)
for s in range(32):
    for t in range(1024):
        p = play4(s, t)
        assert (em[s] >> p) & 1 and (fm[t] >> p) & 1

win_i = win_ii = 0
for table in range(1 << 16):
    iwins = any((table & m) == m for m in em)
    iiwins = any((table & f) == 0 for f in fm)
    assert iwins != iiwins
    # 叶收益按终局索引查表。
    assert iwins == value_bottom_up(4, lambda k, t=table: bit(t, k))
    win_i += iwins
    win_ii += iiwins
assert win_i == 22687 and win_ii == 42849 and win_i + win_ii == 65536

em3 = [0] * 8
for s in range(8):
    a0 = s & 1
    m = 0
    for b0 in (0, 1):
        a2 = (s >> (1 + b0)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2)
    em3[s] = m
fm3 = [0, 0, 0, 0]
for t in range(4):
    m = 0
    for a0 in (0, 1):
        for a2 in (0, 1):
            m |= 1 << (a0 + 2 * ((t >> a0) & 1) + 4 * a2)
    fm3[t] = m
w3i = sum(any((tb & m) == m for m in em3) for tb in range(256))
w3ii = sum(any((tb & f) == 0 for f in fm3) for tb in range(256))
assert (w3i, w3ii) == (207, 49)

# ---------- 件 2：尾等价代表 ----------
def tail_rep(n, m, x):
    return x & (((1 << m) - 1) << (n - m))


def first_diff(n, m, x):
    for j in range(n - m):
        if (x >> j) & 1:
            return j
    return n


def tail_pay(n, m, x):
    return first_diff(n, m, x) % 2 == 0


tail_sizes = {}
for n in range(1, 7):
    for m in range(1, n + 1):
        for x in range(1 << n):
            r = tail_rep(n, m, x)
            assert tail_rep(n, m, r) == r
            assert (r >> (n - m)) == (x >> (n - m))
        size = sum(tail_pay(n, m, x) for x in range(1 << n))
        tail_sizes[(n, m)] = size
        v1 = value_bottom_up(n, lambda x, n=n, m=m: tail_pay(n, m, x))
        assert isinstance(v1, bool)
assert tail_sizes[(4, 2)] == 12

# ---------- 件 3：完美集密度界 ----------
def has_perfect(A, n, d):
    return any(all((A >> ((s << d) | t)) & 1 for t in range(1 << d))
               for s in range(1 << (n - d)))


for A in range(1 << 16):
    for d in range(1, 5):
        if not has_perfect(A, 4, d):
            assert A.bit_count() <= 16 - (1 << (4 - d))

for d in range(1, 5):
    missing = 0
    for s in range(1 << (4 - d)):
        missing |= 1 << (s << d)
    astar = 65535 ^ missing
    assert not has_perfect(astar, 4, d)
    assert astar.bit_count() == 16 - (1 << (4 - d))

for n in range(6, 11):
    for d in (1, 2, n):
        missing = 0
        for s in range(1 << (n - d)):
            missing |= 1 << (s << d)
        universe = (1 << (1 << n)) - 1
        astar = universe ^ missing
        assert not has_perfect(astar, n, d)
        assert astar.bit_count() == (1 << n) - (1 << (n - d))

# ---------- 件 4：参数编码 ----------
codes = set()
for p in range(8):
    for a in range(16):
        c = (p << 4) | a
        assert (c >> 4, c & 15) == (p, a)
        codes.add(c)
assert codes == set(range(128))

print("==== 122")
print(f"finite determinacy length4: 65536/65536 tables, I={win_i} II={win_ii}")
print(f"length3: 256 tables, I={w3i} II={w3ii}; 8x64 strategy pairs exclusive")
print("tail-representative games n=1..6 all determined; |A_(4,2)|=12")
print("perfect-tree bound: 65536 sets x 4 depths, tight on every depth")
print("parameter codes: 128/128 round-trip")
print("END ====")
```

## 43. Prolog：每个相关有限博弈的一方必胜

Prolog 的 `game_value` 直接表达交替量词。

偶数位置取两个后继值的最大值，奇数位置取最小值。

聚合查询跑完长度四与长度三的全部收益表，并核对与数值通道相同的分类数字。

`forall` 用于对已经由 `between` 生成的有限实例逐一生成并测试，不把存在性误当全称性。

完美树检查覆盖全部 65536 个集合乘四个深度，参数检查覆盖全部 128 组编码。

```prolog
:- encoding(utf8).
% 第 122 章：有限 AD 影子。有限枚举不证明无限 AD 或 AD^{L(R)}。

bit(Table, K, Bit) :- Bit is (Table >> K) /\ 1.

% 交替量词的动态规划：位置偶数归张三（max），奇数归李四（min）。
game_value(N, Table, Pos, Prefix, Value) :-
    ( Pos =:= N ->
        bit(Table, Prefix, Value)
    ; Pos1 is Pos + 1,
      game_value(N, Table, Pos1, Prefix, V0),
      Prefix1 is Prefix \/ (1 << Pos),
      game_value(N, Table, Pos1, Prefix1, V1),
      ( Pos mod 2 =:= 0 -> Value is max(V0, V1)
      ; Value is min(V0, V1)
      )
    ).

game_value(N, Table, Value) :- game_value(N, Table, 0, 0, Value).

check_determinacy(N, Last, ICount, IICount) :-
    aggregate_all(count,
        (between(0, Last, Table), game_value(N, Table, 1)), ICount),
    aggregate_all(count,
        (between(0, Last, Table), game_value(N, Table, 0)), IICount),
    Total is Last + 1,
    ICount + IICount =:= Total.

% 尾代表：清除低 n-m 位，保留高 m 位。
tail_rep(N, M, X, R) :-
    Low is N - M,
    Mask is ((1 << M) - 1) << Low,
    R is X /\ Mask.

first_diff_at(_, Limit, Pos, Pos) :- Pos >= Limit, !.
first_diff_at(X, Limit, Pos, D) :-
    ( (X >> Pos) /\ 1 =:= 1 -> D = Pos
    ; Pos1 is Pos + 1, first_diff_at(X, Limit, Pos1, D)
    ).

first_diff(N, M, X, D) :-
    Limit is N - M,
    first_diff_at(X, Limit, 0, D0),
    (D0 =:= Limit -> D = N ; D = D0).

tail_pay(N, M, X, V) :-
    first_diff(N, M, X, D),
    (D mod 2 =:= 0 -> V = 1 ; V = 0).

check_tail(N, M) :-
    Last is (1 << N) - 1,
    forall(between(0, Last, X),
        (tail_rep(N, M, X, R),
         tail_rep(N, M, R, R),
         Low is N - M,
         (R >> Low) =:= (X >> Low))),
    aggregate_all(count,
        (between(0, Last, X), tail_pay(N, M, X, 1)), Size),
    (N =:= 4, M =:= 2 -> Size =:= 12 ; true),
    game_value(N, 0, 0), % 空收益表是递归通道的边界哨兵
    Size >= 0.

% 完美树：存在柱 s，其 2^d 个叶点全在 A 中。
cylinder_full(A, D, S) :-
    Last is (1 << D) - 1,
    Base is S << D,
    forall(between(0, Last, T), bit(A, Base + T, 1)).

has_perfect(A, N, D) :-
    Last is (1 << (N-D)) - 1,
    between(0, Last, S),
    cylinder_full(A, D, S),
    !.

check_perfect :-
    forall(between(0, 65535, A),
        forall(between(1, 4, D),
            (\+ has_perfect(A, 4, D) ->
                popcount(A) =< 16 - (1 << (4-D))
            ; true))),
    forall(between(1, 4, D),
        (LastS is (1 << (4-D)) - 1,
         aggregate_all(sum(1 << (S << D)), between(0, LastS, S), Missing),
         AStar is 65535 xor Missing,
         \+ has_perfect(AStar, 4, D),
         popcount(AStar) =:= 16 - (1 << (4-D)))).

check_params :-
    forall((between(0, 7, P), between(0, 15, A)),
        (C is (P << 4) \/ A,
         P1 is C >> 4,
         A1 is C /\ 15,
         P1 =:= P, A1 =:= A)),
    aggregate_all(count, (between(0, 7, P), between(0, 15, A),
                          C is (P << 4) \/ A, C >= 0), 128).

main :-
    check_determinacy(4, 65535, I4, II4),
    I4 =:= 22687, II4 =:= 42849,
    check_determinacy(3, 255, I3, II3),
    I3 =:= 207, II3 =:= 49,
    game_value(4, 21845, 1), % 偶数下标表：张三必胜
    game_value(4, 0, 0),     % 空表：李四必胜
    forall(between(1, 6, N), forall(between(1, N, M), check_tail(N, M))),
    check_perfect,
    check_params,
    format('==== 122~n'),
    format('finite determinacy length4: 65536/65536 tables, I=~w II=~w~n', [I4,II4]),
    format('length3: 256 tables, I=~w II=~w~n', [I3,II3]),
    format('tail representatives n=1..6; |A_(4,2)|=12~n', []),
    format('perfect-tree bound: 65536 sets x 4 depths, tight~n', []),
    format('parameter codes: 128/128 round-trip~n'),
    format('END ====~n'),
    halt(0).

:- initialization(main).
```

## 44. 假设消耗总表：每个大基数负责什么

本章的大基数假设不能压缩成一句“假设有足够大的基数”。

严格递增的武丁序列为逐层表示提供可以不断向上移动的高度。

序列上确界 \(\kappa\) 给出统一记账位置，但它本身不必被误称为武丁基数。

高于整个序列的可测基数为最后的决定性步骤提供额外测度资源。

引理 3.95 在局部武丁基数处取得泛型正确性。

定理 3.69 则把整条序列及上方可测基数组织成实数参数可定义集合的表示。

定理 3.73 使用两个不超过相应 \(\kappa\) 的武丁基数，以及前面已经建立的决定性工具。

定理 3.74 取 \(\kappa_5\)，正是为了给这些局部需求留下足够空间。

因此“存在无穷多个武丁基数”本身并不是完整假设。

还必须保留位于它们全体之上的可测基数。

这一区分与第 121 章对定理 3.68(2) 的校勘完全一致。

## 45. 泛型正确性不等于一般绝对性

泛型正确性很容易被误读成“可数模型与 V 对所有公式都绝对”。

实际陈述只针对构造所选的公式、参数和力迫范围。

并且它比较的是 \(M_X[g]\) 与 \(V\) 中的相应真值，而不是任意子模型之间的真值。

映射 \(\pi_X(a)\) 也不能省略。

参数进入折叠模型后已经改变表示，直接写同一个 \(a\) 会掩盖运输过程。

从左到右的方向排除模型扩张中的假见证。

从右到左的方向保证 V 中的真见证不会全部丢失。

两者合起来，才使互补树能够同时控制成员与非成员。

这也是为什么双树比单树更适合本章。

单树擅长表示存在性，补树则把失败情形也变成可检查的投影证书。

## 46. 为什么互补性必须在扩张中持续

实数集合在力迫后可能增加新元素。

基模型中的树不会自动获得关于这些新实数的任何分类能力。

若只证明 \(V\) 中投影互补，扩张中的某个新实数可能同时避开两棵树。

也可能出现两个投影都看似包含它的坏情形。

持续互补性排除这两种缺口。

它使“有分支”与“无分支”不再只是静态树性质，而成为可在泛型扩张中反复调用的正确判据。

引理 3.98 的测度塔正需要这种反复调用。

没有持续互补，逐层大集合可能只是在不同扩张中偶然拼凑，不能形成同一个可数完备系统。

所以定理 3.69 中的 \(T,T^*\) 不是普通苏斯林树的简单加倍。

它们携带的是力迫稳定的分类信息。

## 47. 测度塔中的三个不同条件

一个可用的测度系统至少要分清集中性、相容性与可数完备性。

集中性说明测度确实把注意力放在相应树截段上，而不是任意序数集合。

相容性说明延长有限序列时，新旧测度沿投影一致。

可数完备性则说明可数多个测度为一的要求可以同时实现。

前两个条件主要属于逐层表示。

第三个条件负责从逐层走到整条实数分支。

若只保留前两个条件，可能每层都有很大的候选集合，却没有一个点能贯穿所有层。

第 120 章的有秩性论证与第 121 章的交错链都依赖这条区别。

本章没有改变它，只是用广泛贝尔证书为测度系统提供新的来源。

因此“从树到测度”不是把节点换成测度就完成了。

还必须逐项验证三种条件分别由哪一步构造保证。

## 48. 参数极小化不是可构造良序的偷偷回归

定理 3.74 对序数参数作极小化，不等于给全部实数作良序。

被排序的是用于定义的序数参数，不是实数集合本身。

序数天然具有良序，因此可以在 ZF 中作这种最小选择。

证明也没有为每一个实数指定一个统一编号。

它只在“存在非确定反例”的反设下，选出一个特别规范的反例。

随后这个反例被证明确定，反设即告失败。

所以极小化与 AD 不冲突。

相反，它展示了 AD 内模型仍可利用序数结构进行强有力证明。

不能从“没有实数良序”推出“无法最小化任何参数”。

也不能从“使用序数参数”推出“暗中使用了实数的可定义良序”。

这两个推断都混淆了参数域与实数域。

## 49. 为什么可测基数要高于整个序列

若可测基数只高于某一段武丁基数，它未必能服务后续需要向上移动的步骤。

定理 3.74 处理的是任意实数参数可定义集合，不是固定复杂度的单一集合。

不同集合可能需要序列中不同高度的表示。

把可测基数放在整个序列之上，保证无论选取哪个有限高度，上方都仍有统一的测度资源。

若它夹在序列中间，序列尾部就会超过它，原有论证无法直接覆盖这些高度。

这正是“有无穷多个武丁基数”与“另有一个高于它们全体的可测基数”的差别。

前者给出无界序列，后者给出封顶资源。

两者在证明中承担不同功能，不能互相替代。

本章所有结论都按这份完整预算陈述。

## 50. 三种表示等价后为什么仍要保留三个名字

定理 3.71 与定理 3.72 给出等价，并不使术语失去意义。

广泛贝尔性最贴近泛型扩张与互补树。

弱整齐性最贴近带额外实数见证的测度判据。

整齐性则直接接入已经证明的决定性定理。

证明时可以转换，不代表阅读时可以省略转换条件。

每次转换仍要检查基数、点类与参数是否满足局部定理。

保留三个名字，正好提醒读者当前正在使用哪一种技术接口。

这也解释了定理 3.73 的叙述顺序。

它从广泛贝尔输入出发，经弱整齐与 Martin–Steel 机制，最后才到胜负确定。

若只写“由等价性显然确定”，就会把真正的证明工作全部隐藏起来。

## 51. 正则性结论与 CH 的层次再核对

完美集性质首先是一条逐集合结论。

它并不直接给出外模型中连续统的基数等式。

但当它在一个内模型中对所有实数集合成立时，就排除了该模型内大小为 \(\omega_1\) 的实数集合。

因为这样的集合若不可数，就必须包含完美子集，而完美子集具有连续统大小。

这会产生严格的基数矛盾。

所以 AD^{L(ℝ)} 对 CH 的影响是内模型中的良序化与等势命题，而不是对外部 \(2^{\aleph_0}\) 数值的直接计算。

同样，勒贝格可测性与贝尔性质也是模型内陈述。

外部 ZFC 仍可有其他实数集合和其他力迫扩张。

把“内模型中所有集合正则”写成“V 中所有集合正则”，会重复本章最需要避免的层级错误。

## 52. 为什么全表枚举还要搭配代表证书

穷举给出很强的有限覆盖，但它不自动让证明容易维护。

代表收益表可以直观看到策略为什么获胜。

偶数下标表中，张三开局 0 就保证最低位为 0，后续动作都乘偶数权重，不会改变奇偶性。

空收益表中，李四无需复杂计算，任何对弈终点都归李四。

这两个代表证书让读者不必先接受 65536 次计算，就能检查坐标约定是否合理。

全表枚举随后再检查所有收益组合，防止只挑容易例子。

策略排他性又是另一类证书。

它说明双方不可能同时必胜，补上“至少一方”之外的“至多一方”。

三种证书分工不同，合起来才构成清楚的有限决定性账。

## 53. 四个证明通道的证明范围不能互相冒名

Lean 的全表定理以 `Fin 16 → Bool` 为任意收益函数，范围明确覆盖全部有限表。

Coq 与 Agda 的代表定理只针对指定收益表，不应改写成它们也完成了全表穷举。

Coq 的一般排他性定理则确实对任意收益函数成立，这是另一项独立范围。

Isabelle 的双方证书使用谓词与历史列表，重点在 ZF 语法和可达历史表达。

这四个通道不是同一定理的四次复制。

它们分别检查全表计算、代表归约、排他性和集合论语义接口。

Julia、Python、Prolog 的全枚举再为有限账提供三种计算实现。

正文按这些实际范围报告，避免“七通道全绿”被误读成七份 AD 形式化证明。

## 54. 常见误读清单

第一，AD^{L(ℝ)} 不是全域 AD。

第二，广泛贝尔不是“在任意意义下都很广泛”，它有精确的泛型表示条件。

第三，弱整齐不是不要可数完备性，只是投影判据中多了实数见证。

第四，树的大小裁剪不是删除不必要分支的形式手续，必须保留所有必要见证。

第五，三种表示等价不是定义相同，而是在特定大基数环境中可以互相转换。

第六，序数参数极小化不是实数良序。

第七，有限 65536 张表全确定不是 AD 的数值证据。

第八，完美树密度界不是完美集性质的无限证明。

第九，128 组参数往返不是 \(L(\mathbb R)\) 层次构造。

第十，七通道通过只说明所列源码与文档检查通过，不表示本章没有运行过的其他测试也自动通过。

## 55. 不能把哪些话说大

本章没有形式化 Martin–Steel 定理。

本章没有机器证明武丁基数存在、可测基数存在或泛型正确性。

本章没有在证明助理中构造广泛贝尔树、测度塔或 \(L(\mathbb R)\) 的完整层次。

本章没有从有限穷举推出任何无限博弈的决定性。

本章更没有构造 ZFC 中的非确定博弈。

正确结论是：无限数学正文给出 AD^{L(ℝ)} 的证明路线，有限机器件独立核验若干底层组合证书，并明确停在有限边界内。

## 56. 本章小结

定理 3.69 把实数参数可定义集合变成广泛贝尔集合。

引理 3.97 与引理 3.98 控制树的大小并构造测度塔。

定理 3.70–3.72 让广泛贝尔、弱整齐与整齐表示在适当武丁背景下合流。

定理 3.73 把表示转成决定性。

定理 3.74 通过序数参数极小化，把任意 \(L(\mathbb R)\) 反例归约为实数参数可定义反例，最终得到 AD^{L(ℝ)}。

这条结论与全域 AC 不冲突，因为它始终限定在 \(L(\mathbb R)\) 内。

它也使全书的大基数、内模型、描述集合论、正则性与博弈主线在同一个结构中汇合。
