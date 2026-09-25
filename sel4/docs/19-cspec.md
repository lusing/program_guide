# 19 · C 规范与堆

对应示例：`../examples/S19_cspec.thy`

## 19.1 把 C 代码搬进 Isabelle

第 18 章的"具体层"到底是什么？在 seL4 里它是 **C 规范（cspec）**：
把内核的 C 源码翻译成 Isabelle 里的项，入口目录是 `l4v/spec/cspec/`。
这一层的关键特征是：**状态是字节堆，不是记录**。
抽象层与设计层里"这个地址上有一个 CTE"那样的陈述，到了这里都变成
"某些字节，按某个类型的布局，落在某个地址上"。

翻译是自动的，`l4v/spec/cspec/README.md` 第 15--17 行讲的就是流程：

<!-- 源码块：l4v/spec/cspec/README.md 第 15--17 行 -->
```text
The C semantics of the kernel is produced by first configuring and
preprocessing the C sources for a specific platform and then parsing it into
Isabelle using the C parser in `l4v/tools/c-parser`.
```

先配置、预处理，再用 `l4v/tools/c-parser`（本树里是
`l4v/tools/c-parser/`，一堆 ML 源码）解析。
被解析的 C 源码树**不在**版本库里：`l4v/spec/cspec/c/` 只有
`Makefile`、`kernel.mk`、`overlays/`、`gen-config-thy.py` 这些脚本，
`.c` 是构建时从 `seL4/` 那棵树生成、预处理出来的产物。

顶层理论有两个，README 第 26--27 行分得很清楚：

<!-- 源码块：l4v/spec/cspec/README.md 第 26--27 行 -->
```text
The top-level theory file for this module is `Kernel_C` for the bare
translation of seL4 into Isabelle, and `KernelInc_C` for additional automatic
```

* `Kernel_C`：裸翻译产物；
* `KernelInc_C`：在裸翻译之上再叠**自动生成的位段证明**。

后者在本树里只有 16 行，它做的事就是 import：

<!-- 源码块：l4v/spec/cspec/KernelInc_C.thy 第 7--14 行 -->
```text
theory KernelInc_C
imports
  "Substitute"
  "structures_defs"
  "structures_proofs"
  "shared_types_defs"
  "shared_types_proofs"
begin
```

`structures_defs`/`structures_proofs`/`shared_types_defs`/`shared_types_proofs`
四个都不在版本库里，是位段代码生成器的输出。
成本也写在 README 里，第 44--46 行：

<!-- 源码块：l4v/spec/cspec/README.md 第 44--46 行 -->
```text
Expect this build to take about 30 min on a modern machine and to require
close to 4GB of memory. For further sessions building on top of `CSpec`,
usually at least 16GB of main memory are required together with a 64-bit setup
```

两个 session：`CKernel`（裸翻译）与 `CSpec`（加上自动位段证明）。

## 19.2 堆模型与几条基本定律

模型里把堆写成一个部分函数（实测）：

```text
consts
  load :: "nat \<Rightarrow> (nat \<Rightarrow> nat option) \<Rightarrow> nat option"
```

三条最基础的定律（实测）：

```text
theorem load_after_store: load ?a (store ?a ?v ?h) = Some ?v
```

```text
theorem
  load_other_after_store: ?b \<noteq> ?a \<Longrightarrow> load ?b (store ?a ?v ?h) = load ?b ?h
```

```text
theorem store_twice: store ?a ?v2.0 (store ?a ?v1.0 ?h) = store ?a ?v2.0 ?h
```

写了就能读到、写别处不影响、重复写覆盖。
真实证明里用得同样频繁的还有一对"两次写、两个地址"的：

```text
theorem
  store_at_diff_addrs_commute:
    ?a \<noteq> ?b \<Longrightarrow>
    store ?a ?v1.0 (store ?b ?v2.0 ?h) = store ?b ?v2.0 (store ?a ?v1.0 ?h)
```

```text
theorem
  load_the_other_after_two_stores:
    ?a \<noteq> ?b \<Longrightarrow> load ?b (store ?a ?v2.0 (store ?b ?v1.0 ?h)) = Some ?v1.0
```

前一条是 frame 条件的来源（两处写可以随便交换），
后一条是"写完 A 还能读回 B"。它们的证明都要多一个 `rule ext`——
两条堆相等必须逐点相等，这是 `heap` 是函数的直接后果。

真实那一份的 `cstate` 与两个缩写长这样（`l4v/spec/cspec/KernelState_C.thy`
第 21--33 行）：

<!-- 源码块：l4v/spec/cspec/KernelState_C.thy 第 21--33 行 -->
```text
type_synonym cstate = "globals myvars"
type_synonym rf_com = "cstate c_com"

abbreviation
  "cslift (s :: cstate) \<equiv> clift (t_hrs_' (globals s))"

lemma cslift_def: "is_an_abbreviation" by (simp add: is_an_abbreviation_def)

(* Add an abbreviation for the common case of hrs_htd (t_hrs_' (globals s)) \<Turnstile>\<^sub>t p *)
abbreviation
  "c_h_t_valid" :: "cstate \<Rightarrow> 'a::c_type ptr \<Rightarrow> bool"  ("_ \<Turnstile>\<^sub>c _" [99,99] 100)
where
  "s \<Turnstile>\<^sub>c p == hrs_htd (t_hrs_' (globals s)),c_guard \<Turnstile>\<^sub>t p"
```

两点要看：

1. `cslift` 是"从 C 状态里读一个**类型化**的值"，它把字节堆
   （`t_hrs_' (globals s)`）交给 `clift` 去按类型布局解释。
   模型里 `load a h` 那种"一个地址一个字"的读取，在这里是
   "一段字节 + 一个类型"。
2. `c_h_t_valid`（打印成 `s ⊨⇩c p`）是一个**前提**，不是运算。
   它就是模型里 `h p ≠ None` 那一类条件的真实形态，
   只是还多背了对齐、类型良好、无重叠。

`clift`、`hrs_htd`、`t_hrs_'` 的定义都在 CLib/CParser 那套外部依赖里，
本树只 import 名字——所以本章只到"形状对得上"为止。
本树里能看到的一份真实证明是
`l4v/spec/cspec/TypHeapLimits.thy` 第 36--41 行：

<!-- 源码块：l4v/spec/cspec/TypHeapLimits.thy 第 36--41 行 -->
```text
lemma states_all_but_typs_eq_clift:
  "\<lbrakk> states_all_but_typs_eq names hrs hrs';
      \<forall>x \<in> td_names (typ_info_t TYPE('a)). x \<notin> names;
      typ_name (typ_info_t TYPE('a)) \<noteq> pad_typ_name \<rbrakk>
     \<Longrightarrow> (clift hrs :: (_ \<rightharpoonup> ('a :: c_type))) = clift hrs'"
  apply (rule ext, simp add: lift_t_def)
```

结论正是"写别处不影响"的严谨版：两个堆只在 `names` 这批类型的字节上
不同，那么读**别的**类型（前提里排掉了 `names`）读出来一样。
注意它的证明第一步也是 `rule ext`。

## 19.3 一个 C 函数的翻译形态

模型里模拟"读/写能力结构体的一个字段"（实测的类型就是堆上的读法）：

```text
consts
  cap_get_rights :: "nat \<Rightarrow> (nat \<Rightarrow> cap_struct option) \<Rightarrow> nat option"
```

三条性质（实测）：

```text
theorem
  get_after_set:
    ?h ?p \<noteq> None \<Longrightarrow> cap_get_rights ?p (cap_set_rights ?p ?v ?h) = Some ?v
```

```text
theorem get_unmapped_is_none: ?h ?p = None \<Longrightarrow> cap_get_rights ?p ?h = None
```

```text
theorem
  set_preserves_other_field:
    ?h ?p = Some ?c \<Longrightarrow>
    cap_word0 (the (cap_set_rights ?p ?v ?h ?p)) = cap_word0 ?c
```

`set_preserves_other_field` 值得停一下：在记录层"改一个字段不动其他字段"
是定义免费的，在堆层它要单独证明（而且左边那个 `the` 要求
`h p = Some c` 这个前提）。

`get_unmapped_is_none` 对应 C 里的空指针解引用。
在 Isabelle 里它不会崩，而是返回 `None`，于是"这段 C 代码合法"
变成"证明这个 `None` 分支不会出现"。这是把 C 翻译进逻辑之后
最本质的一个转变：**未定义行为变成了必须被排除的分支**。
功能正确性定理顺带给出的承诺，写在 `seL4/CAVEATS.md` 第 69--71 行：

<!-- 源码块：seL4/CAVEATS.md 第 69--71 行 -->
```text
Overall, the functional correctness proof shows that the seL4 C code implements
the formal [abstract API specification][ASpec] of seL4 and is free from standard
C implementation defects such as buffer overruns or NULL pointer dereferences.
```

## 19.4 位段：一个字里塞两个字段

上面假设"一个字段占一个字"。真实内核不是这样：ARM 的权利被压进
一个字的低 4 位。`l4v/proof/crefine/ARM/SR_lemmas_C.thy`
第 1681--1687 行就是那份展开：

<!-- 源码块：l4v/proof/crefine/ARM/SR_lemmas_C.thy:1681-1688 -->
```text
definition
  cap_rights_from_word_canon :: "word32 \<Rightarrow> seL4_CapRights_CL"
  where
  "cap_rights_from_word_canon wd \<equiv>
    \<lparr> capAllowGrantReply_CL = from_bool (wd !! 3),
      capAllowGrant_CL = from_bool (wd !! 2),
      capAllowRead_CL = from_bool (wd !! 1),
      capAllowWrite_CL = from_bool (wd !! 0)\<rparr>"
```

读写位段用的是 C 的位运算，所以每个访问器都要一堆定理——
这就是 `KernelInc_C` 那批生成物存在的理由，也是 `SORRY_BITFIELD_PROOFS`
（`l4v/spec/cspec/README.md` 第 62--65 行）存在的理由：

<!-- 源码块：l4v/spec/cspec/README.md 第 62--65 行 -->
```text
To speed up interactive development, the bitfield code generator can be
configured to skip the corresponding proofs and produce sorried
(unproven) property statements only. To achieve this, set the
environment variable `SORRY_BITFIELD_PROOFS` to `TRUE`.
```

"可以跳过证明"反过来说明：这批引理**本来是要证的**。

模型里把"一个字塞两个字段"简化成低 8 位放权利、高位放 badge：
那个字长 `w * 256 + r` 这样。要证的三条（实测）：

```text
theorem rights_of_packed: ?r < 256 \<Longrightarrow> rights_of (?w * 256 + ?r) = ?r
```

```text
theorem badge_of_packed: ?r < 256 \<Longrightarrow> badge_of (?w * 256 + ?r) = ?w
```

```text
theorem
  set_rights_on_packed:
    \<lbrakk>?r < 256; ?r' < 256\<rbrakk> \<Longrightarrow> set_rights (?w * 256 + ?r) ?r' = ?w * 256 + ?r'
```

第三条的 `set_rights` 定义是"减掉旧低位、加上新低位"
（`w - rights_of w + r`），和 C 里 clear-then-set 的写法一致。
每一条都带 `r < 256`：这个前提不是保险丝，是**结论本身**。
写成定理再看一遍"改低位不动高位"（实测）：

```text
theorem
  badge_untouched_by_set_rights:
    \<lbrakk>?r < 256; ?r' < 256\<rbrakk> \<Longrightarrow> badge_of (set_rights (?w * 256 + ?r) ?r') = ?w
```

越界写会同时坏掉两个字段，而且坏得很安静（实测）：

```text
theorem
  set_rights_out_of_range_breaks_both:
    rights_of (set_rights 0 257) = 1 \<and> badge_of (set_rights 0 257) = 1
```

本该只改低位的一次写，把高位也从 0 变成 1。
在 C 里这类 bug 叫"位段溢出"，在 Isabelle 里它是
**一条没有前提就用不上的定理**。

## 19.5 从 C 回到设计规范：ccorres

C 层与设计层之间的对应叫 `ccorres`。它是第 18 章那个
`corres_underlying` 的**另一个实例**，不是同一个：本树里能看到的样子是
`ccorres_cases`（`l4v/proof/crefine/lib/Corres_C.thy` 第 17--24 行）——

<!-- 源码块：l4v/proof/crefine/lib/Corres_C.thy:17-23 -->
```text
lemma ccorres_cases:
  assumes "P \<Longrightarrow> ccorres_underlying srel Ga rrel xf arrel axf G G' hs a b"
  assumes "\<not>P \<Longrightarrow> ccorres_underlying srel Ga rrel xf arrel axf H H' hs  a b"
  shows "ccorres_underlying srel Ga rrel xf arrel axf
                            (\<lambda>s. (P \<longrightarrow> G s) \<and> (\<not>P \<longrightarrow> H s))
                            ({s. P \<longrightarrow> s \<in> G'} \<inter> {s. \<not>P \<longrightarrow> s \<in> H'}) hs
                            a b"
```

参数是 `srel Ga rrel xf arrel axf G G' hs a b`，比设计规范那份多了
C 侧特有的三项：异常分支的关系 `arrel`、异常转换 `xf`，
以及一个"堆 `hs` 有效"的额外参数。
真正的定义在 `l4v/lib/clib/Corres_UL_C.thy`，它的前件已抄在第 18 章 18.8 节，
`lib/clib/CCorresLemmas.thy` 是把那一族引理打包起来的入口，
`proof/crefine/lib/Corres_C.thy` 通过 `CLib.CCorresLemmas` import 进来。

单个 C 函数的证明是 `rightsFromWord_spec`
（`l4v/proof/crefine/ARM/CSpace_RAB_C.thy` 第 521--523 行）：

<!-- 源码块：l4v/proof/crefine/ARM/CSpace_RAB_C.thy 第 521--523 行 -->
```text
lemma rightsFromWord_spec:
  shows "\<forall>s. \<Gamma> \<turnstile> {s} \<acute>ret__struct_seL4_CapRights_C :== PROC rightsFromWord(\<acute>w)
  \<lbrace>seL4_CapRights_lift \<acute>ret__struct_seL4_CapRights_C = cap_rights_from_word_canon \<^bsup>s\<^esup>w \<rbrace>"
```

一条 Hoare 三元式：跑 C 的那个 `PROC rightsFromWord`，
后置条件说返回值 lift 出来的结构体等于 19.4 那份
`cap_rights_from_word_canon`。紧接着
`cap_rights_to_H_from_word_canon`（`l4v/proof/crefine/ARM/CSpace_RAB_C.thy`
第 535--536 行）把两层的算法接上：

<!-- 源码块：l4v/proof/crefine/ARM/CSpace_RAB_C.thy 第 535--536 行 -->
```text
lemma cap_rights_to_H_from_word_canon [simp]:
  "cap_rights_to_H (cap_rights_from_word_canon wd) = rightsFromWord wd"
```

"先按位段读、再转成设计层的权利"等于"直接按设计层的算法算"——
这一条才是 `ccorres` 的原料。模型里把两步合成一条（实测）：

```text
theorem
  c_bitfield_matches_dcap:
    \<lbrakk>?r < 256; ?r' < 256\<rbrakk>
    \<Longrightarrow> word_to_dcap (set_rights (?w * 256 + ?r) ?r') =
       \<lparr>d_rights = ?r', d_badge = ?w\<rparr>
```

字段投影那种更简单的对应（实测）：

```text
theorem
  c_matches_d:
    ?h ?p = Some ?c \<Longrightarrow>
    cap_get_rights ?p ?h = Some (d_get_rights (dcap_of ?c))
```

最后把它们接成链的是顶层定理，
`l4v/proof/crefine/ARM/Refine_C.thy` 第 993--1005 行：

<!-- 源码块：l4v/proof/crefine/ARM/Refine_C.thy 第 993--1005 行 -->
```text
theorem refinement2:
  "ADT_C uop \<sqsubseteq> ADT_H uop"
  unfolding ADT_C_def
  by (rule refinement2_both)

theorem fp_refinement:
  "ADT_FP_C uop \<sqsubseteq> ADT_H uop"
  unfolding ADT_FP_C_def
  by (rule refinement2_both)

theorem seL4_refinement:
  "ADT_C uop \<sqsubseteq> ADT_A uop"
  by (blast intro: refinement refinement2 refinement_trans)
```

`refinement2` 说 C 精化设计规范，`seL4_refinement` 用
`refinement_trans` 把它和规范层那条 `refinement` 接起来，
于是"C 代码实现了抽象规范"成为一条定理。

## 19.6 翻译不是"信它没错"

`seL4/CAVEATS.md` 第 64--67 行的原话：

<!-- 源码块：seL4/CAVEATS.md 第 64--67 行 -->
```text
This proof covers the functional behaviour of the C code of the kernel. It does
not cover machine code, compiler, linker, boot code, cache or TLB management.
The compiler and linker can be removed from this list by additionally running the
binary verification tool chain for seL4 for AArch32 or RISC-V.
```

拆开来是三件事：

* C 解析器与位段生成物在被证明的范围**之外**，属于工具信任基；
  `SORRY_BITFIELD_PROOFS` 那个开关正说明这批引理是需要被证的，
  只是可以选择先 sorried。
* 缩小机器码那一块的是 `l4v/proof/asmrefine/`：从 ELF 二进制往回精化，
  只对 AArch32 与 RISC-V 做，不是所有架构都有。
* 硬件模型在 `l4v/spec/machine/`，本身也是假设。

读证明之前先看 `seL4/CAVEATS.md`，它比任何教程都权威。

## 19.7 C 层证明的骨架：官方笔记里那座塔

前面六节讲的是"原料"：翻译出来的 C、堆模型、位段、`ccorres` 的定义。
把它们组织成一条证明的形状，官方有一篇专门写这件事——
`l4v/docs/crefine-notes.md`，标题就叫 "Notes on C refinement proof in practice"。

### 一条引理的形状

它开头就把本章每条 `ccorres` 引理的骨架摆出来：

<!-- 源码块：l4v/docs/crefine-notes.md:17-17 -->
```text
ccorres r xf P P' hs (op arguments) (Call op_'proc)
```

七个参数各有分工，笔记里逐条列了：`r` 是返回值关系、`xf` 从具体状态里把返回值
摘出来、`P` 与 `P'` 分别是 Haskell 侧和 C 侧的前置条件、`hs` 是 handler 栈，
最后两项一个是设计层的函数、一个是 C 过程的实现。这份表里最值得记住的是
**结果藏在状态里**这件事：C 函数没有"返回值"这个独立东西，结果就是某个变量，
所以 `xf` 这一整类参数（19.5 那条 `rightsFromWord_spec` 里的 lift 也是同一件事）
存在的唯一理由是把结果搬回抽象侧能比较的形状。

### 证明的形状

一条完整的证明长这样（同文件的图，缩进和星号都是原样）：

<!-- 源码块：l4v/docs/crefine-notes.md:52-63 -->
```text
cinit	                  *
   ctac/csymbr...         +
     ctac/csymbr...       +
       ctac/csymbr...     +
         ...
        wp                x
       vcg                x
      wp                  x
     vcg                  x
    wp                    x
   vcg                    x
  <proof of last big subgoal>
```

它自己的解释：

<!-- 源码块：l4v/docs/crefine-notes.md:66-72 -->
```text
The `*` line is the proof initialisation.

The + lines are the proof of ccorres subgoal.

The `x` lines are the hoare triple proofs (both from Haskell and C).

The final line is where we prove that the conjunction of all the preconditions accumulated along the proof is implied by the original precondition of the lemma.
```

把这三段合起来读，`CRefine` 会话里那些看起来玄乎的方法其实只做两件事：
**先把一条 `ccorres` 拆成一串霍尔三元组**（`+` 那几行），
**再从最后一条三元组倒推回去把前件填满**（`x` 那几行，成对出现是因为
Haskell 侧与 C 侧各一条）。最底下那一行是"攒出来的所有前件被原始前件推出"。

`cinit` 是塔顶那一步，而它不是一个原子操作——官方把它的展开式写下来了：

<!-- 源码块：l4v/docs/crefine-notes.md:126-133 -->
```text
unfolding op_def                             -- "unfolds the Haskell function body"
  apply (rule ccorres_Call)                    -- "replaces the C side by a schematic function body,
                                                   with a new subgoal for the definition of the schematic being the C function body"
   apply (rule op_impl [unfolded op_body_def]) -- "finds the C function body"
  apply (rule ccorres_rhs_assoc)+              -- "re-associates the sequence of C instructions (to be able to consider the 1st one)"
  apply (simp del: return_bind Int_UNIV_left)  -- "simplification, but keeping the returns and the (UNIV inter ...)"
  apply (cinitlift arg1_' arg2_' ...)          -- "lifts variables out of C precondition"
  apply (rule ccorres_guard_imp2)              -- "generalises the precondition (replaces by schematic and additional subgoal)"
```

紧接着那句解释值得照抄进笔记本："It is worth knowing the sequence that `cinit`
abbreviates in case `cinit` does not work"。方法失败时，这几行就是可直接手写的
替代脚本。其中 `op_impl` 那条也值得单独记：它是"这个 `Call` 等于那个 C 过程的
函数体"，命名规则是 `<函数名>_impl`，与 `<函数名>_body_def` 成对出现——
`l4v/proof/crefine/ARM/Delete_C.thy` 里那条
`finaliseSlot_impl[unfolded finaliseSlot_body_def]` 就是现成的例子。
这两条引理都**搜不到定义**，它们和 `.c` 一样是构建产物（19.1 说过）。

`ctac` 做的事是把当前 `ccorres` 目标换成三条：

<!-- 源码块：l4v/docs/crefine-notes.md:159-163 -->
```text
1. ccorres r xf (?Q0 ...) (?Q0' ...) hs
	   (do y1 ← f1 x1; ... od)
           (y1':== f1' x1';; ...)
2. {?Q} y0 ← f0 x0 {?Q0}
3. Γ ⊢ (?Q') y0':== f0' x0'(?Q0')
```

也就是"这条指令对应了、剩下的继续证、两侧各留一条霍尔三元组"。
这三条形在库里有名字。`l4v/proof/crefine/lib/Ctac.thy` 注册它们的那几行还留了一句提醒：

<!-- 源码块：l4v/proof/crefine/lib/Ctac.thy:40-42 -->
```text
(* Most specific to least specific.  ctac uses <base> ^ "_novcg" so the suffic is important for the
 * ctac_splits lemmas *)
lemmas ctac_splits_non_call = ccorres_split_nothrowE [where F = UNIV] ccorres_split_nothrow  [where F = UNIV]
```

`_novcg` 这个后缀不是注释而是**接口**——`ctac` 是按 `<base> ^ "_novcg"` 拼名字去找规则的。
两侧指令对不齐时有三味药，官方按"谁多出来"分得很清：C 侧多出来的用 `csymbr`
（只符号执行 C 一侧），底层引理是 `ccorres_symb_exec_r`，它会多生两条子目标；
Haskell 侧多出来的用 `ccorres_symb_exec_l`，同样多生两条；
`ctac` 完全匹配不上时手写 `ccorres_split_nothrow`，它生**五**条子目标
（`ctac` 那三条，加上"第一条指令本身的对应"和一条 `ceqv` 目标）。
笔记里还有一条前置动作容易被忽略：用 `ccorres_split_nothrow` 之前通常要先
`ccorres_guard_imp2` 把前件泛化，因为后者要的是前件的交。

如果 `cinit`/`ctac` 莫名其妙不匹配，官方给的第一味药不是换方法而是**收掉 `if` 的拆分**：

<!-- 源码块：l4v/docs/crefine-notes.md:144-148 -->
```text
  lemma foo:
     notes if_split [split del]
     shows "ccorres ..."
   apply cinit
   ...
```

`notes if_split [split del]` 只作用于这一条引理的证明，
把 `split_if` 从 simpset 里摘出去——Haskell 侧有 `if _ then _ else` 时，
化简器会把 `ccorres` 的前件拆成一堆分支，`cinit` 就再也认不出原来的形状了。
第 8 章坑位 3 那条"`case` 在 `simp` 下不分裂、要显式给 `split`"是同一件事的另一半：
那里是把拆分**打开**，这里是在 `cinit` 之前把拆分**关掉**。

### 最底下那一行：40 个相似子目标

塔底的"last big subgoal"是全章最枯燥也最容易翻车的地方。官方的说法是：

<!-- 源码块：l4v/docs/crefine-notes.md:251-251 -->
```text
Another problem is to deal with sometimes 40 goals after expansion of this last goal, and usually very similar goals. So this idea is to 'generate' the more useful premises as possible before expanding (by `subgoal_tac` or `frule`).
```

它给的技巧是把想用的引理写成**结论里带等式**的形式，好在展开之前用 `frule` 塞进去：

<!-- 源码块：l4v/docs/crefine-notes.md:257-257 -->
```text
⟦ bla ⟧ ⟹ a = b ⟶ P
```

而不是

<!-- 源码块：l4v/docs/crefine-notes.md:263-263 -->
```text
⟦ bla; a = b ⟧ ⟹ P
```

差别在时机：后一种要等目标展开、`impI` 之后才用得上，前一种能在展开前就 `frule`，
常常顺手把子目标直接证掉。19.3 那个 `rightsFromWord_spec` 接上 19.4 的
`cap_rights_from_word_canon` 时，两边就是这类"展开前先把桥梁放进去"的写法。

## 19.8 VCG：什么时候故意不给 C 侧生成义务

`ctac` 与 `vcg` 有一批"no-VCG"变体（`ctac(no_vcg)`、
`ccorres_split_nothrow_novcg`）。官方笔记给的理由很实在：

<!-- 源码块：l4v/docs/crefine-notes.md:304-304 -->
```text
The ccorres rules are all designed so there should be as little to prove as possible on the C side. Most ccorres rules only assume UNIV or a property about local arguments. Local arguments will mostly be bound by ceqv, and information about them available globally. So it may be possible to prove the C assumptions on the spot and skip the VCG work of passing them backwards. This is when the no-VCG variants can be used.
```

然后是它承认真正原因的那一段：

<!-- 源码块：l4v/docs/crefine-notes.md:310-310 -->
```text
OK, the hard part. The real reason the no-VCG variants exist is because the VCG sometimes generates over-strong assumptions. Here's why. Norbert's Simpl language and VCG are designed for a verification approach in which one true Hoare triple is proven for every function. If a lemma exists with the name f\_spec, the VCG will attempt to use it as a specification for the function f, ignoring f's actual definition. If that spec rule has a precondition, e.g. the pointer validity precondition in the spec rules for the \_ptr\_ variants of the bitfield functions, that precondition must be established. Even if we're proving the weak version of the Hoare triple where we can assume rather than prove the pointer guards.
```

这段的结论是一句"Yuck."，接着给了三种止损办法：

<!-- 源码块：l4v/docs/crefine-notes.md:314-314 -->
```text
So, something to look out for. Running the VCG over a function whose spec has preconditions may create work for you that you don't really need. Also watch out for the VCG inlining functions when you didn't need that either. One solution is to use the no-VCG rule variants, but it can be tricky to ensure this is safe. The most involved and effective option is the `apply (vcg exspec=getSyscallArg_modifies)` form you will see in the proofs. These "extra spec" (exspec) rules override the usual spec rules, and the modifies rules produced by the parser are ideal for this purpose since they have no precondition. But you have to be careful to override all the spec rules that were used.
```

`exspec=` 这个写法在本仓库里是真在用的，例如
`l4v/proof/crefine/ARM/Tcb_C.thy` 里就有：

<!-- 源码块：l4v/proof/crefine/ARM/Tcb_C.thy:1204-1204 -->
```text
   apply (vcg exspec=getSyscallArg_modifies)
```

——`*_modifies` 规则由解析器生成、**没有前置条件**，正好适合顶掉 `*_spec`。

失败位上的坑另有专页：`l4v/docs/vcg-debugging.md`。它开头处理的就是
"前件里莫名出现 `False`"这种病，症状是你根本看不到 `False`：

<!-- 源码块：l4v/docs/vcg-debugging.md:42-42 -->
```text
  supply simp_thms(19)[simp del]
```

第一步是把 `(P ⟶ False) = (¬ P)` 这条 simp 规则摘掉，好让 `False` 现形；
第二步是把可疑的那次 `vcg` 换成：

<!-- 源码块：l4v/docs/vcg-debugging.md:49-49 -->
```text
  apply (rule conseqPre, vcg, rule subset_refl)
```

这一串在"好目标"上会成功并留下一条**假设里没有 schematic** 的目标；
失败就说明 `vcg` 生成的目标依赖了比 `?P` 允许的更多的参数。它给的四种解法
（`wpfix`、在 schematic 引入之前先引入参数、保住 `∃y. x = Some y` 的形式不要
提前 `exE`、在 `ccorres` 目标里用 `wpc`）本质上是同一句话：
**别让 `clarsimp`/`exE` 这类"看着安全"的方法先把 schematic 需要的参数拆散**。
这份手册里也有一处手滑：讲"`vcg` 太慢"那一节给的建议写法是

<!-- 源码块：l4v/docs/vcg-debugging.md:108-108 -->
```text
  apply (rule conseqPre, vgc, rule subset_refl)
```

这里显然是 `vcg` 手滑成了 `vgc`——同一份文档前面那条正确写法就在上面；
抄进自己的证明之前，先分辨读到的是哪个。这一页最后三条是给"目标确实大"的现场的：

<!-- 源码块：l4v/docs/vcg-debugging.md:119-121 -->
```text
* Use `supply [[goals_limit = 1]]` if you have more than one goal
* Use the `Quick print` option in jEdit to turn off translations
* Turn off some of the Hoare package's funky syntax translations using
```

`goals_limit` 与关掉翻译都是**只影响可读性**的手段，别指望它们让证明变快。

---

## 官方教程对照

| 官方文档 / 文件 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/docs/crefine-notes.md` | `ccorres` 形状、证明骨架、`cinit`/`ctac`/`csymbr`、no-VCG | 19.7、19.8 |
| `l4v/docs/vcg-debugging.md` | `False` 前件、`vcg` 太慢、大目标可读性 | 19.8 后半 |
| `l4v/docs/conventions.md` | `corres` 与 `ccorres` 两套框架 | 第 18 章 18.8 |
| `l4v/proof/crefine/lib/Ctac.thy` | `ctac` 的规则集与 `_novcg` 后缀接口 | 19.7 |
| `l4v/proof/crefine/README.md` | 这个证明在证什么、两层 C 语义与 `Substitute.thy` | 19.5 起点、坑位 11、12 |

**1. 官方笔记里的三处路径已经过期。** 它说 `ceqv` 的规则在
"seL4-api/crefine/Corres\_UL\_C.thy"，方法"set up in seL4-api/crefine/Corres\_C.thy
and implemented in …/ctac-method.ML"。本树里方法是在 `Ctac.thy` 里 `method_setup`
的（`ctac`、`clift`、`cinitlift`、`csymbr`、`ceqv`、`cinit`、`cinit'`、`ctac_print_xf`），
ML 实现在同目录的 `ctac-method.ML`；`Corres_C.thy` 只是 import 它们的那份。
笔记里点名的辅助引理 `ccorres_tmp_lift11`、`ccorres_tmp_init_lift12`
在本树里搜不到，`cinitlift` 的说明以方法定义为准。

**2. `ceqv` 这个常量本身不在这两份树里。** 它来自 AutoCorres，
l4v 这边只有围绕它写的引理和用它做参数化的规则
（`ccorres_abstract`、`xpres`、`*_ceqv` 那一族）。`l4v/proof/crefine/lib/Ctac.thy`
里那条 `ceqv Γ xf' rv' t t' d (d' rv')` 假设就是这个形状——读到这里别去猜它的定义，
把它当"把 `xf s` 换成变量 `v`"这个关系用。

**3. 镜像里 `docs/Tutorials/` 下没有 C 精化教程。** 这一层的官方内容就是
`crefine-notes.md` 与 `vcg-debugging.md` 两篇，本节的引用全部落在 `l4v/docs/`。

---

## 本章坑位清单（实测）

1. **到 `l4v/spec/cspec/c/` 找 C 源码**：那里只有 Makefile、`kernel.mk`、
   `overlays/`、生成脚本；`.c` 是构建时从 `seL4/` 生成并预处理的产物。
2. **把 `Kernel_C` 当顶层理论**：README 第 26--27 行说得很清——
   `Kernel_C` 是裸翻译，`KernelInc_C` 才额外带自动生成的位段证明。
3. **分不清两个 session**：`CKernel`（裸翻译）与 `CSpec`（+位段证明），
   下游 session 还要 16GB。
4. **以为结构体字段更新是免费的**：在堆层"改一个字段不动其他字段"
   要单独证明（模型里的 `set_preserves_other_field`）。
5. **忽略地址可能未映射**：读取要带 `h p ≠ None`；真实那一份是
   `s ⊨⇩c p`（`c_h_t_valid`），还多背对齐、类型良好、无重叠。
6. **把 `the (…)` 当安全操作**：它在 `None` 上未定义，用的时候必须带前提。
7. **把字节当结构化值**：`clift` 才是"字节 + 类型布局"的解释器，
   类型化视图是叠加在字节上的解释。
8. **以为位段访问器不用证**：每个访问器一堆定理，
   这正是 `structures_proofs`/`shared_types_proofs` 的用处。
9. **写位段不带范围前提**：`r < 256` 是结论的一部分，
   越界写会安静地毁掉相邻字段。
10. **把 `ccorres` 与 `corres` 当同一个东西**：C 层那份是
    `ccorres_underlying srel Ga rrel xf arrel axf G G' hs a b`，
    多了异常关系与堆有效性；定义在 CLib，不在 `Corres_UL.thy`。
11. **找 C→设计的证明找错地方**：在 `l4v/proof/crefine/`
    （`ARM/Refine_C.thy`、`ARM/CSpace_RAB_C.thy`、`lib/Corres_C.thy`、
    `README.md` 说明两层 C 语义与 `Substitute.thy`），
    不是 `l4v/proof/refine/`（那是设计↔抽象）。
12. **以为 C 解析器是被验证的**：它不是；CAVEATS 第 64--67 行
    列出的机器码/编译器/链接器缺口要靠 `l4v/proof/asmrefine/` 才补上一部分。
13. **`cinit` 不成就换方法**：它只是一段七行脚本的缩写（`l4v/docs/crefine-notes.md` 把展开式写全了）；
    先按那段手写一遍看卡在第几步，再决定要 `notes if_split [split del]` 还是 `ccorres_rhs_assoc`。
14. **把 `_novcg` 后缀当风格**：`ctac` 是按 `<base> ^ "_novcg"` 拼名字找规则的，
    少这条后缀它就悄悄退回带 VCG 的那条形；no-VCG 的代价见 19.8——前件会变成 `UNIV` 或局部参数性质。
15. **在 `ccorres` 证明里随手 `clarsimp`/`exE`**：`vcg` 的 schematic 前件一旦被拆出多余参数就统一不上，
    症状是塔底冒出带 `False` 的不可证目标；先 `supply simp_thms(19)[simp del]` 让它现形，
    再用 `rule conseqPre, vcg, rule subset_refl` 定位是哪一次 `vcg` 干的。

---

上一章：[18 · 精化关系](18-corres.md) ｜ 下一章：[20 · 精化链与信任基](20-refine-chain.md) ｜ 返回：[README](../README.md)
