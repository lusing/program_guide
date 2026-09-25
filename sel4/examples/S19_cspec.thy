theory S19_cspec
  imports Main
begin

section \<open>19.1 把 C 代码搬进 Isabelle\<close>

text \<open>
  设计规范之下还有一层：C 代码本身。l4v 的做法是把 C
  \emph{自动翻译}进 Isabelle，入口目录是 @{verbatim "l4v/spec/cspec/"}。
  @{verbatim "l4v/spec/cspec/README.md"} 第 15--17 行说得很直白：
  先按平台配置、预处理内核的 C 源码，再用 C 解析器
  @{verbatim "l4v/tools/c-parser"} 解析进 Isabelle。
  顶层理论有两个：@{verbatim "Kernel_C"}
  （@{verbatim "l4v/spec/cspec/README.md"} 第 26--27 行）是"裸翻译"，
  在它之上再加\emph{自动生成的位段证明}的是 @{verbatim "KernelInc_C"}；
  对应的 Isabelle session 是 @{verbatim "CKernel"} 与 @{verbatim "CSpec"}
  （@{verbatim "l4v/spec/cspec/README.md"} 第 34--35 行讲的就是这两者的差别）。
  预处理与生成的脚本都在 @{verbatim "l4v/spec/cspec/c/"}，
  这个目录本树\emph{只有} Makefile、@{verbatim "kernel.mk"}、
  @{verbatim "overlays"} 这些脚本，@{verbatim ".c"} 源码树是构建产物。

  本章建一个最小的"C 风格堆"，说明翻译之后要证明的东西长什么样。
\<close>

ML \<open>writeln "==== 19 开始 ===="\<close>

type_synonym addr = nat
type_synonym word = nat
type_synonym heap = "addr \<Rightarrow> word option"

definition empty_heap :: heap where "empty_heap \<equiv> \<lambda>_. None"

definition load :: "addr \<Rightarrow> heap \<Rightarrow> word option" where
  "load a h \<equiv> h a"

definition store :: "addr \<Rightarrow> word \<Rightarrow> heap \<Rightarrow> heap" where
  "store a v h \<equiv> h(a \<mapsto> v)"

subsection \<open>19.2 最基础的几条堆定律\<close>

lemma load_after_store: "load a (store a v h) = Some v"
  by (simp add: load_def store_def)

lemma load_other_after_store:
  "b \<noteq> a \<Longrightarrow> load b (store a v h) = load b h"
  by (simp add: load_def store_def)

lemma store_twice: "store a v2 (store a v1 h) = store a v2 h"
  by (rule ext) (simp add: store_def)

text \<open>
  前三条是模型版的"写了就能读到、写别处不影响、重复写覆盖"。
  真实内核的 C 代码里有成千上万次结构体字段访问，全靠这类定律压下去。
  还有一类用得同样频繁：\emph{不同地址}的两次写互不干扰
  （@{text "a \<noteq> b"} 就是真实证明里的 frame 条件），
  以及连着写两处之后，每个地址读到的都是\emph{自己}那一次的写。
\<close>

lemma store_at_diff_addrs_commute:
  "a \<noteq> b \<Longrightarrow> store a v1 (store b v2 h) = store b v2 (store a v1 h)"
  by (rule ext) (simp add: store_def)

lemma load_after_two_stores:
  "load a (store a v2 (store b v1 h)) = Some v2"
  by (simp add: load_def store_def)

lemma load_the_other_after_two_stores:
  "a \<noteq> b \<Longrightarrow> load b (store a v2 (store b v1 h)) = Some v1"
  by (simp add: load_def store_def)

text \<open>
  真实那一份的堆在 CLib/CParser 里，本树看不到它们的定义，
  只看得到几个缩写。
  @{verbatim "cslift"}（@{verbatim "l4v/spec/cspec/KernelState_C.thy"}
  第 24--25 行）把"从 C 状态里读某个类型的值"写成 @{verbatim "clift"}
  作用在 @{verbatim "t_hrs_' (globals s)"} 上。
  @{verbatim "c_h_t_valid"}
  （@{verbatim "l4v/spec/cspec/KernelState_C.thy"} 第 30--33 行）
  把"这个指针在当前堆上有效"缩写成 @{text "s \<Turnstile>\<^sub>c p"}。
  它是一条\emph{前提}，不是运算——这就是模型里
  @{text "h p \<noteq> None"} 那条的真实来源，只是它同时要求对齐、
  类型良好成立、没有重叠。
  @{verbatim "states_all_but_typs_eq_clift"}
  （@{verbatim "l4v/spec/cspec/TypHeapLimits.thy"} 第 36--41 行）
  则给出"写别处不影响"在真实堆上的形态：只要动的字节不属于这个类型，
  @{verbatim "clift"} 的读法就不变。
\<close>

subsection \<open>19.3 一个 C 函数的翻译形态\<close>

text \<open>
  下面这段模拟 seL4 里读写能力权利字段的 C 函数。
  C 里它是一次结构体字段访问，翻译成 Isabelle 之后变成
  "读某个地址上的某个偏移"，并且带上一个
  \emph{该地址确实被映射}的前提条件。
\<close>

record cap_struct =
  cap_word0 :: word
  cap_word1 :: word

type_synonym c_heap = "addr \<Rightarrow> cap_struct option"

definition cap_get_rights :: "addr \<Rightarrow> c_heap \<Rightarrow> word option" where
  "cap_get_rights p h \<equiv> case h p of None \<Rightarrow> None | Some c \<Rightarrow> Some (cap_word1 c)"

definition cap_set_rights :: "addr \<Rightarrow> word \<Rightarrow> c_heap \<Rightarrow> c_heap" where
  "cap_set_rights p v h \<equiv> case h p of
      None \<Rightarrow> h
    | Some c \<Rightarrow> h(p \<mapsto> c\<lparr> cap_word1 := v \<rparr>)"

lemma get_after_set:
  "h p \<noteq> None \<Longrightarrow> cap_get_rights p (cap_set_rights p v h) = Some v"
  by (auto simp: cap_get_rights_def cap_set_rights_def split: option.splits)

lemma get_unmapped_is_none:
  "h p = None \<Longrightarrow> cap_get_rights p h = None"
  by (simp add: cap_get_rights_def)

lemma set_preserves_other_field:
  "h p = Some c \<Longrightarrow> cap_word0 (the (cap_set_rights p v h p)) = cap_word0 c"
  by (auto simp: cap_set_rights_def)

text \<open>
  @{thm get_unmapped_is_none} 对应 C 里"空指针解引用"：
  在 Isabelle 里它不会崩，而是返回一个 @{verbatim "None"}，
  于是"这段 C 代码合法"变成了"证明这个 @{verbatim "None"} 分支不会出现"。
  这是把 C 翻译进逻辑之后最本质的一个转变：
  \emph{未定义行为变成了必须被排除的分支}。
  @{verbatim "seL4/CAVEATS.md"} 第 69--71 行正是这么承诺的——
  功能正确性定理顺带保证了代码"没有缓冲区越界、没有空指针解引用"。
\<close>

subsection \<open>19.4 位段：一个字里塞两个字段\<close>

text \<open>
  上一节假设"一个字段占一个字"。真实内核不是这样：ARM 的权利被压进
  一个字的低 4 位（第 0 位 write、第 1 位 read、第 2 位 grant、
  第 3 位 grantReply）。
  @{verbatim "cap_rights_from_word_canon"}
  （@{verbatim "l4v/proof/crefine/ARM/SR_lemmas_C.thy"} 第 1682--1687 行）
  就是把这四个位摊成一个 C 记录的定义。
  读写位段用的是 C 的位运算，翻译工具得为每个访问器\emph{生成}一批定理：
  @{verbatim "structures_proofs"} 与 @{verbatim "shared_types_proofs"}
  在 @{verbatim "l4v/spec/cspec/KernelInc_C.thy"} 第 7--14 行被 import 进来。
  构建的代价写在 README 里——@{verbatim "CSpec"}
  （@{verbatim "l4v/spec/cspec/README.md"} 第 44--46 行）这一句说的是
  30 分钟左右、近 4GB 内存，在它之上再搭 session 通常要 16GB。
  @{verbatim "SORRY_BITFIELD_PROOFS"}
  （@{verbatim "l4v/spec/cspec/README.md"} 第 62--65 行）
  把证明换成 sorried 的性质语句，图交互式开发方便；
  反过来说明这批引理\emph{本来是要证的}。

  模型里把"一个字里塞两个字段"简化成 @{text "mod 256"}/@{text "div 256"}：
  低 8 位是权利，高位是 badge，那个字长 @{text "w * 256 + r"} 这样。
  下面几条说明\emph{为什么}位段访问器需要证明。
\<close>

definition rights_of :: "word \<Rightarrow> word" where
  "rights_of w \<equiv> w mod 256"

definition badge_of :: "word \<Rightarrow> word" where
  "badge_of w \<equiv> w div 256"

definition set_rights :: "word \<Rightarrow> word \<Rightarrow> word" where
  "set_rights w r \<equiv> w - rights_of w + r"

text \<open>
  要证的\emph{不是}任意字，而是"高位 @{text "w"} 和低位 @{text "r"} 拼出来的
  那个字"读回什么——生成的位段定理就是这个形状。
\<close>

lemma rights_of_packed:
  "r < 256 \<Longrightarrow> rights_of (w * 256 + r) = r"
  by (simp add: rights_of_def)

lemma badge_of_packed:
  "r < 256 \<Longrightarrow> badge_of (w * 256 + r) = w"
  by (simp add: badge_of_def)

lemma set_rights_on_packed:
  "r < 256 \<Longrightarrow> r' < 256 \<Longrightarrow> set_rights (w * 256 + r) r' = w * 256 + r'"
  by (simp add: rights_of_def set_rights_def)

text \<open>
  每一条都带 @{text "r < 256"}。这个前提不是保险丝，是\emph{结论本身}：
   @{text "set_rights"} 用的是"减掉旧低位、加上新低位"，
  新值一旦溢出 8 位就进到高位里去了，两个字段同时坏掉，而且坏得很安静。
\<close>

lemma badge_untouched_by_set_rights:
  "r < 256 \<Longrightarrow> r' < 256 \<Longrightarrow> badge_of (set_rights (w * 256 + r) r') = w"
  by (simp add: rights_of_def badge_of_def set_rights_def)

lemma set_rights_out_of_range_breaks_both:
  "rights_of (set_rights 0 257) = 1 \<and> badge_of (set_rights 0 257) = 1"
  by (simp add: rights_of_def badge_of_def set_rights_def)

subsection \<open>19.5 从 C 回到设计规范：ccorres\<close>

text \<open>
  C 层与设计层之间的对应叫 @{verbatim "ccorres"}，
  它是第 18 章那个 @{verbatim "corres_underlying"} 的\emph{另一个实例}，
  不是同一个。本树里能看到的样子是
  @{verbatim "ccorres_cases"}
  （@{verbatim "l4v/proof/crefine/lib/Corres_C.thy"} 第 18--24 行），
  它的参数是 @{verbatim "srel Ga rrel xf arrel axf G G' hs a b"}：
  比设计规范那份多了 C 侧特有的几项——返回值关系之外还要对齐
  异常分支（@{verbatim "arrel"} 与 @{verbatim "xf"}），
  而且整条关系多一个"堆 @{verbatim "hs"} 有效"的参数。
  真正的定义在 CLib 的 @{verbatim "CCorresLemmas"} 里，本树只 import 名字。

  顶层定理在 @{verbatim "l4v/proof/crefine/ARM/Refine_C.thy"}：
  @{verbatim "refinement2"}（@{verbatim "l4v/proof/crefine/ARM/Refine_C.thy"}
  第 993--995 行）说 C 精化设计规范，
  结论是 @{verbatim "ADT_C uop"} @{text "\<sqsubseteq>"} @{verbatim "ADT_H uop"}；
  @{verbatim "seL4_refinement"}（@{verbatim "l4v/proof/crefine/ARM/Refine_C.thy"}
  第 1003--1005 行）再把它与规范层那条 @{verbatim "refinement"}
  用 @{verbatim "refinement_trans"} 接起来。
\<close>

text \<open>
  真实的一份"单个 C 函数的证明"长这样——
  @{verbatim "rightsFromWord_spec"}
  （@{verbatim "l4v/proof/crefine/ARM/CSpace_RAB_C.thy"} 第 521--523 行）
  是一条 Hoare 三元式：跑 C 的那个 @{verbatim "PROC rightsFromWord"}，
  后置条件说返回值 lift 出来的结构体等于
  @{verbatim "cap_rights_from_word_canon"}。
  紧接着 @{verbatim "cap_rights_to_H_from_word_canon"}
  （同一个文件第 535--536 行）说"先按位段读、再转成设计层的权利"
  等于直接按设计层的算法算——这一条才是 @{verbatim "ccorres"} 的原料。
  模型里把这两步合成一条定理。
\<close>

record dcap =
  d_rights :: word
  d_badge  :: word

definition dcap_of :: "cap_struct \<Rightarrow> dcap" where
  "dcap_of c \<equiv> \<lparr> d_rights = cap_word1 c, d_badge = cap_word0 c \<rparr>"

definition d_get_rights :: "dcap \<Rightarrow> word" where
  "d_get_rights c \<equiv> d_rights c"

lemma c_matches_d:
  "h p = Some c \<Longrightarrow> cap_get_rights p h = Some (d_get_rights (dcap_of c))"
  by (simp add: cap_get_rights_def dcap_of_def d_get_rights_def)

text \<open>
  @{thm c_matches_d} 是一次对应证明的极小形态：
  C 侧读出来的字 == 设计侧记录里的字段。
\<close>

definition word_to_dcap :: "word \<Rightarrow> dcap" where
  "word_to_dcap w \<equiv> \<lparr> d_rights = rights_of w, d_badge = badge_of w \<rparr>"

lemma c_bitfield_matches_dcap:
  "r < 256 \<Longrightarrow> r' < 256 \<Longrightarrow>
   word_to_dcap (set_rights (w * 256 + r) r') = \<lparr> d_rights = r', d_badge = w \<rparr>"
  by (simp add: word_to_dcap_def set_rights_def rights_of_def badge_of_def)

text \<open>
  @{thm c_bitfield_matches_dcap} 就是位段版的同一件事：
  C 那边改了低 8 位，设计层的记录里 @{verbatim "d_rights"} 变成新值、
  @{verbatim "d_badge"} 一动不动。真实内核里这样的定理有成千上万条，
  覆盖每一个 C 函数。
\<close>

subsection \<open>19.6 翻译不是"信它没错"\<close>

text \<open>
  最后要说清可信基础。@{verbatim "seL4/CAVEATS.md"} 第 64--67 行的原话是：
  证明覆盖的是内核 C 代码的\emph{功能行为}，
  \emph{不}覆盖机器码、编译器、链接器、启动代码、cache 与 TLB 管理；
  编译器和链接器可以靠"额外跑一遍二进制验证工具链"从这份清单里去掉。
  也就是说：

  \begin{itemize}
    \item C 解析器与位段生成物在被证明的范围\emph{之外}，是工具信任基；
          第 19.4 节那个 @{verbatim "SORRY_BITFIELD_PROOFS"} 开关
          正说明这批引理是\emph{需要}被证的，只是可以选择先 sorried。
    \item 缩小机器码那一块的是 @{verbatim "l4v/proof/asmrefine/"}，
          它对 AArch32 与 RISC-V 做从 ELF 二进制的精化，不是所有架构都有。
    \item 硬件模型在 @{verbatim "l4v/spec/machine/"}，本身也是假设。
  \end{itemize}

  读证明之前先看 @{verbatim "seL4/CAVEATS.md"}，它比任何教程都权威。
\<close>

ML \<open>
  writeln (@{make_string} @{thm load_after_store});
  writeln (@{make_string} @{thm load_other_after_store});
  writeln (@{make_string} @{thm store_at_diff_addrs_commute});
  writeln (@{make_string} @{thm load_after_two_stores});
  writeln (@{make_string} @{thm load_the_other_after_two_stores});
  writeln (@{make_string} @{thm get_after_set});
  writeln (@{make_string} @{thm get_unmapped_is_none});
  writeln (@{make_string} @{thm set_preserves_other_field});
  writeln (@{make_string} @{thm rights_of_packed});
  writeln (@{make_string} @{thm badge_of_packed});
  writeln (@{make_string} @{thm set_rights_on_packed});
  writeln (@{make_string} @{thm badge_untouched_by_set_rights});
  writeln (@{make_string} @{thm set_rights_out_of_range_breaks_both});
  writeln (@{make_string} @{thm c_matches_d});
  writeln (@{make_string} @{thm c_bitfield_matches_dcap})
\<close>

ML \<open>writeln "==== 19 结束 ===="\<close>

end
