theory S15_retype
  imports Main
begin

section \<open>15.1 Untyped：内存的唯一来源\<close>

text \<open>
  seL4 里所有的内核对象都由 @{verbatim "Untyped"} 内存"改类型"而来
  （retype）。Untyped 能力长这样
  （@{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 104 行）：

  @{verbatim "UntypedCap bool obj_ref nat nat"}

  四个字段依次是：是否设备内存、起始地址、\emph{大小位数}、
  以及 @{verbatim "freeIndex"}。最后这个\emph{不是地址}，
  而是相对基址的偏移——@{verbatim "l4v/spec/abstract/Retype_A.thy"} 第 132 行的
  @{verbatim "get_free_index"} 写的就是这件事：
  @{verbatim "get_free_index base free \<equiv> unat $ (free - base)"}。

  但要小心单位：抽象规范里这个偏移按\emph{字节}算
  （第 128 行的 @{verbatim "get_free_ref"} 只做 @{verbatim "base + of_nat free_index"}），
  C 侧那个位字段却按 @{verbatim "2 ^ seL4_MinUntypedBits"} 一块地数，
  换算靠 @{verbatim "FREE_INDEX_TO_OFFSET"} 左移。
  第 104 行那句注释 @{verbatim "freeRef = obj_ref + (freeIndex * 2^4)"}
  说的是 C 的表示，不是这个记录的表示。
\<close>

ML \<open>writeln "==== 15 开始 ===="\<close>

type_synonym obj_ref = nat

record untyped =
  ut_base  :: obj_ref
  ut_bits  :: nat        \<comment> \<open>大小 = 2^bits 字节\<close>
  ut_free  :: nat        \<comment> \<open>freeIndex：相对基址的偏移\<close>

definition ut_size :: "untyped \<Rightarrow> nat" where
  "ut_size u \<equiv> 2 ^ ut_bits u"

definition ut_end :: "untyped \<Rightarrow> obj_ref" where
  "ut_end u \<equiv> ut_base u + ut_size u"

text \<open>
  "用到头了"在规范里有一个具体数值：@{verbatim "l4v/spec/abstract/CSpace_A.thy"}
  第 76 行的 @{verbatim "max_free_index"} 定义为 @{verbatim "2 ^ magnitude_bits"}，
  也就是整块大小。
\<close>

definition max_free_index :: "nat \<Rightarrow> nat" where
  "max_free_index b \<equiv> 2 ^ b"

definition fully_used :: "untyped \<Rightarrow> bool" where
  "fully_used u \<equiv> ut_free u = max_free_index (ut_bits u)"

lemma max_free_index_is_size: "max_free_index (ut_bits u) = ut_size u"
  by (simp add: max_free_index_def ut_size_def)

lemma fully_used_means_watermark_at_end:
  "fully_used u \<Longrightarrow> ut_base u + ut_free u = ut_end u"
  by (simp add: fully_used_def ut_end_def max_free_index_is_size)

subsection \<open>15.2 分配：水位前进，基址不动\<close>

definition alloc_chunk :: "nat \<Rightarrow> untyped \<Rightarrow> (obj_ref \<times> untyped) option" where
  "alloc_chunk n u \<equiv>
     if n = 0 \<or> ut_free u + n > ut_size u then None
     else Some (ut_base u + ut_free u, u\<lparr> ut_free := ut_free u + n \<rparr>)"

lemma alloc_zero_rejected: "alloc_chunk 0 u = None"
  by (simp add: alloc_chunk_def)

lemma alloc_beyond_end_rejected:
  "ut_free u + n > ut_size u \<Longrightarrow> alloc_chunk n u = None"
  by (simp add: alloc_chunk_def)

lemma alloc_returns_free_pointer:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> p = ut_base u + ut_free u"
  by (auto simp: alloc_chunk_def split: if_splits)

lemma alloc_advances_free_index:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> ut_free u' = ut_free u + n"
  by (auto simp: alloc_chunk_def split: if_splits)

lemma alloc_never_moves_base:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> ut_base u' = ut_base u"
  by (auto simp: alloc_chunk_def split: if_splits)

lemma alloc_keeps_bits:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> ut_bits u' = ut_bits u"
  by (auto simp: alloc_chunk_def split: if_splits)

subsection \<open>15.3 分配出来的块互不重叠\<close>

lemma chunks_do_not_overlap:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow>
   alloc_chunk m u' = Some (q, u'') \<Longrightarrow>
   p + n \<le> q"
proof -
  assume h1: "alloc_chunk n u = Some (p, u')"
    and h2: "alloc_chunk m u' = Some (q, u'')"
  have p_def: "p = ut_base u + ut_free u"
    using h1 by (rule alloc_returns_free_pointer)
  have q_def: "q = ut_base u' + ut_free u'"
    using h2 by (rule alloc_returns_free_pointer)
  have free': "ut_free u' = ut_free u + n"
    using h1 by (rule alloc_advances_free_index)
  have base': "ut_base u' = ut_base u"
    using h1 by (rule alloc_never_moves_base)
  show "p + n \<le> q"
    by (simp add: p_def q_def free' base')
qed

lemma chunks_stay_inside:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> p + n \<le> ut_end u"
proof -
  assume h: "alloc_chunk n u = Some (p, u')"
  then have "ut_free u + n \<le> ut_size u"
    by (auto simp: alloc_chunk_def split: if_splits)
  then show "p + n \<le> ut_end u"
    by (auto simp: ut_end_def alloc_returns_free_pointer[OF h])
qed

subsection \<open>15.4 回收：水位能\emph{倒退}，但是分块倒的\<close>

text \<open>
  @{verbatim "l4v/spec/abstract/Retype_A.thy"} 第 143 行的
  @{verbatim "reset_untyped_cap"} 把"回收"做成了\emph{逐块}回退。
  它先问一句 @{verbatim "free_index_of cap = 0"}（第 149 行）——
  已经在水位起点上就什么都不做；否则先 @{verbatim "delete_objects"}，
  然后分两条路：
  @{verbatim "dev \<or> sz < resetChunkBits"}（第 155 行）时一次清完整块
  @{verbatim "2 ^ sz"} 字节、把 freeIndex 写成 0，设备内存连清都不清；
  不然就从第 160 行那个 @{verbatim "mapME_x"} 开始，沿着第 166 行那个
  被 @{verbatim "rev"} 倒过来的下标表，每轮清 @{verbatim "2 ^ resetChunkBits"} 字节、
  把 freeIndex 设成刚清完的位置 @{verbatim "i * 2 ^ resetChunkBits"}、
  再插一个 @{verbatim "preemption_point"}。
  C 侧的同一个函数叫 @{verbatim "resetUntypedCap"}，在
  @{verbatim "seL4/src/object/untyped.c"} 第 234 行；同样的分支写在第 253 行，
  那个倒着走的 for 循环在第 259--267 行。

  分块的理由是实时性：清零一整块 1GiB 的内存不能把系统锁在那里。
  也正因为可以中途被抢占，freeIndex 必须\emph{每一步}都停在合法位置上——
  这就是"倒的是偏移、而且是一块一块倒"的原因。
\<close>

text \<open>
  模型把"一块"抽象成一个字节数 @{verbatim "s"}。真实内核里它是
  C 侧的 @{verbatim "BIT(chunk)"}（@{verbatim "chunk"} 取自
  @{verbatim "CONFIG_RESET_CHUNK_BITS"}），
  Isabelle 侧写的是 @{verbatim "2 ^ resetChunkBits"}。
\<close>

definition reset_chunk :: "nat \<Rightarrow> untyped \<Rightarrow> untyped" where
  "reset_chunk s u \<equiv>
     u\<lparr> ut_free := (if ut_free u \<le> s then 0 else ut_free u - s) \<rparr>"

primrec reset_steps :: "nat \<Rightarrow> nat \<Rightarrow> untyped \<Rightarrow> untyped" where
  "reset_steps s 0 u = u"
| "reset_steps s (Suc k) u = reset_steps s k (reset_chunk s u)"

lemma reset_chunk_keeps_base_and_bits:
  "ut_base (reset_chunk c u) = ut_base u \<and> ut_bits (reset_chunk c u) = ut_bits u"
  by (simp add: reset_chunk_def)

lemma reset_chunk_never_grows: "ut_free (reset_chunk c u) \<le> ut_free u"
  by (simp add: reset_chunk_def split: if_splits)

text \<open>
  第 149 行那句 @{verbatim "if free_index_of cap = 0 then returnOk ()"}
  在模型里就是这条：水位已经是 0 时"再清一块"是空转，能力一字未动。
\<close>

lemma reset_chunk_of_zero_is_a_no_op: "ut_free u = 0 \<Longrightarrow> reset_chunk s u = u"
  by (simp add: reset_chunk_def)

lemma reset_chunk_is_strict_progress:
  "0 < s \<Longrightarrow> 0 < ut_free u \<Longrightarrow> ut_free (reset_chunk s u) < ut_free u"
  by (simp add: reset_chunk_def split: if_splits)

lemma reset_steps_keeps_base: "ut_base (reset_steps s k u) = ut_base u"
  by (induction k arbitrary: u) (simp_all add: reset_chunk_def)

lemma reset_steps_keeps_bits: "ut_bits (reset_steps s k u) = ut_bits u"
  by (induction k arbitrary: u) (simp_all add: reset_chunk_def)

lemma reset_steps_reach_zero:
  "ut_free u \<le> s * n \<Longrightarrow> ut_free (reset_steps s (Suc n) u) = 0"
proof (induction n arbitrary: u)
  case 0
  then show ?case by (simp add: reset_chunk_def split: if_splits)
next
  case (Suc n)
  have "ut_free (reset_chunk s u) \<le> s * n"
  proof (cases "ut_free u \<le> s")
    case True
    then show ?thesis by (simp add: reset_chunk_def)
  next
    case False
    with Suc.prems show ?thesis by (simp add: reset_chunk_def)
  qed
  with Suc.IH have ih: "ut_free (reset_steps s (Suc n) (reset_chunk s u)) = 0" .
  then show ?case by simp
qed

text \<open>
  @{thm reset_steps_reach_zero} 说的是"回退一定会停"：清过的水位不超过
  @{verbatim "s * n"} 字节，那最多 @{verbatim "n"} 步就回到 0。
  这就是那个 for 循环\emph{有穷}的理由——内核不能在一个可抢占的
  循环里无限转下去。
\<close>

text \<open>
  整体回退就是"把偏移直接写成 0"，但\emph{内存是否清零}要看是不是设备内存：
  设备寄存器不能被内核清零，所以那条分支只改能力、不碰内存。
\<close>

definition reset_untyped :: "bool \<Rightarrow> untyped \<Rightarrow> untyped \<times> bool" where
  "reset_untyped dev u \<equiv> (u\<lparr>ut_free := 0\<rparr>, \<not> dev)"

lemma reset_puts_watermark_at_start: "ut_free (fst (reset_untyped dev u)) = 0"
  by (simp add: reset_untyped_def)

lemma device_memory_is_not_cleared: "\<not> snd (reset_untyped True u)"
  by (simp add: reset_untyped_def)

lemma ram_is_cleared: "dev = False \<Longrightarrow> snd (reset_untyped dev u)"
  by (simp add: reset_untyped_def)

lemma reset_is_idempotent: "fst (reset_untyped dev (fst (reset_untyped dev u))) = fst (reset_untyped dev u)"
  by (simp add: reset_untyped_def)

lemma alloc_right_after_reset_lands_on_base:
  "0 < n \<Longrightarrow> n \<le> ut_size u \<Longrightarrow> alloc_chunk n (u\<lparr>ut_free := 0\<rparr>) = Some (ut_base u, u\<lparr>ut_free := n\<rparr>)"
  by (simp add: alloc_chunk_def ut_size_def)

subsection \<open>15.5 有没有子孙，决定的是"能不能回退"\<close>

text \<open>
  C 侧那段判定写在 @{verbatim "seL4/src/object/untyped.c"} 里
  @{verbatim "decodeUntypedInvocation"} 的中段（第 182--189 行）：

  \begin{itemize}
    \item @{verbatim "ensureNoChildren"} \emph{失败}（确实有子孙）时才沿用
          能力里记着的 @{verbatim "freeIndex"}，且 @{verbatim "reset = false"}；
    \item @{verbatim "ensureNoChildren"} \emph{成功}（没有子孙）时
          @{verbatim "freeIndex = 0; reset = true"}——注释写得很明白：
          即使能力里记的水位不为 0，也可以从头开始用，
          因为之前分出去的对象可能都已经被删掉了。
  \end{itemize}

  也就是说"有子孙"\emph{不}阻止 retype，它只阻止回退。
  另一条同名谓词 @{verbatim "ensure_no_children"} 出现在
  @{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 106 行的
  @{verbatim "derive_cap"} 里（那个 @{verbatim "UntypedCap"} 分支在第 110 行），
  那里挡的是\emph{拷贝/传送}这个能力。
  同一个问题，两处闸门，别混。
\<close>

type_synonym cslot = nat

definition has_children :: "cslot set \<Rightarrow> bool" where
  "has_children ds \<equiv> ds \<noteq> {}"

definition ensure_no_children :: "cslot set \<Rightarrow> bool" where
  "ensure_no_children ds \<equiv> \<not> has_children ds"

lemma empty_means_no_children: "ensure_no_children {}"
  by (simp add: ensure_no_children_def has_children_def)

lemma child_blocks_children_free: "\<not> ensure_no_children {s}"
  by (simp add: ensure_no_children_def has_children_def)

definition decode_retype_start :: "cslot set \<Rightarrow> untyped \<Rightarrow> obj_ref \<times> bool" where
  "decode_retype_start ds u \<equiv> if ensure_no_children ds then (0, True) else (ut_free u, False)"

lemma no_children_restart_from_zero:
  "decode_retype_start {} u = (0, True)"
  by (simp add: decode_retype_start_def ensure_no_children_def has_children_def)

lemma children_keep_the_watermark:
  "\<not> ensure_no_children ds \<Longrightarrow> fst (decode_retype_start ds u) = ut_free u"
  by (simp add: decode_retype_start_def)

lemma children_forbid_reset:
  "\<not> ensure_no_children ds \<Longrightarrow> \<not> snd (decode_retype_start ds u)"
  by (simp add: decode_retype_start_def)

lemma reset_flag_means_no_children:
  "snd (decode_retype_start ds u) \<Longrightarrow> ensure_no_children ds"
  unfolding decode_retype_start_def by (cases "ensure_no_children ds") auto

lemma retype_still_works_with_children:
  "0 < n \<Longrightarrow> ut_free u + n \<le> ut_size u \<Longrightarrow> alloc_chunk n u \<noteq> None"
  by (auto simp: alloc_chunk_def split: if_splits)

subsection \<open>15.6 把 untyped 切成子 untyped 时，父亲被置为"满"\<close>

text \<open>
  @{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 95 行的
  @{verbatim "set_untyped_cap_as_full"} 由第 762 行的 @{verbatim "cap_insert"}
  在第 770 行调用：
  如果这次插入的\emph{新}能力和 @{verbatim "src"} 槽里的能力是同一个
  untyped 区域（同基址、同位数），就把 src 那一份的 freeIndex 直接推到
  @{verbatim "max_free_index"}，即整块大小。
\<close>

definition set_parent_as_full :: "untyped \<Rightarrow> untyped" where
  "set_parent_as_full p \<equiv> p\<lparr>ut_free := max_free_index (ut_bits p)\<rparr>"

lemma parent_becomes_fully_used: "fully_used (set_parent_as_full p)"
  by (simp add: set_parent_as_full_def fully_used_def)

lemma full_parent_allocates_nothing:
  "0 < n \<Longrightarrow> alloc_chunk n (set_parent_as_full p) = None"
  by (simp add: alloc_chunk_def set_parent_as_full_def max_free_index_def ut_size_def)

lemma making_a_parent_full_touches_nothing_else:
  "ut_base (set_parent_as_full p) = ut_base p \<and> ut_bits (set_parent_as_full p) = ut_bits p"
  by (simp add: set_parent_as_full_def)

lemma full_is_the_only_state_that_allocates_nothing_of_any_size:
  "fully_used p \<Longrightarrow> \<forall>n > 0. alloc_chunk n p = None"
  by (auto simp: fully_used_def max_free_index_is_size alloc_chunk_def ut_size_def)

ML \<open>
  writeln (@{make_string} @{thm chunks_do_not_overlap});
  writeln (@{make_string} @{thm reset_chunk_is_strict_progress});
  writeln (@{make_string} @{thm reset_steps_reach_zero});
  writeln (@{make_string} @{thm no_children_restart_from_zero});
  writeln (@{make_string} @{thm full_parent_allocates_nothing})
\<close>

ML \<open>writeln "==== 15 结束 ===="\<close>

end
