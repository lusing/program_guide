theory S24_capstone
  imports Main
begin

section \<open>24.1 综合案例：这条定理在仓库里有现成的原型\<close>

text \<open>
  前面二十三章都在证"内核的某一步"。最后一章要回答的是一个整体问题：

  \begin{quote}
  \emph{从两个互不可达的分区出发，任意多次合法操作之后，
  它们仍然互不可达。}
  \end{quote}

  这个问题在 l4v 里不是没有答案，而是答案就躺在规范树里：
  @{verbatim "l4v/spec/take-grant/"}，六个理论、3077 行 Isabelle 源码，
  一个抽象的 take/grant 安全模型。它的 @{verbatim "README.md"} 第 20 行起
  把分工写得很清楚：@{verbatim "System_S"} 给状态空间与操作，
  @{verbatim "Confine_S"} 证权威约束（authority confinement），
  @{verbatim "Islands_S"} 把"权威孤岛"显式定义出来，
  @{verbatim "Isolation_S"} 在孤岛之上定义信息流并证明孤岛保持隔离，
  @{verbatim "Example"} 与 @{verbatim "Example2"} 是两个具体系统。

  本章就按这条线索走：先把状态空间摆出来（24.2、24.3），
  再看八个系统调用与合法性判定（24.4），然后把权威序
  @{verbatim "\<le>cap"} 与连接关系 @{verbatim "leak"} 立起来
  （24.5、24.6），核心是 24.7 那条"单步不产生新连接"，
  最后两段（24.8、24.9）把它归纳到任意长的运行，并套出信息流形式。
  24.10 交代这个模型\emph{没有}证明什么。

  先记下 @{verbatim "README.md"} 末尾那句免责声明，它决定了本章的口吻：

  \begin{quote}
  "This specification is *not* connected with the seL4 code and does *not*
  completely describe seL4 behaviour. Instead, it is a more abstract study
  of the underlying concepts."
  \end{quote}
\<close>

ML \<open>writeln "==== 24 开始 ===="\<close>

subsection \<open>24.2 状态空间：六个权利、一条能力、一个实体\<close>

text \<open>
  @{verbatim "System_S.thy"} 第 25 行的 @{verbatim "entity_id"} 是
  @{verbatim "word32"}（注释原话："kernel objects - identified by a UID"）。
  本章用 @{verbatim "nat"} 顶替它——下面所有引理都不涉及位宽，
  换掉只会让 @{verbatim "value"} 算得动。

  权利是六个，不是第 3 章那套 @{verbatim "AllowRead/AllowWrite/AllowGrant"}：

  \begin{itemize}
    \item @{verbatim "Read"}、@{verbatim "Write"}——数据权利，
          读与写那个对象承载的信息；
    \item @{verbatim "Take"}——"把别人手里的能力拿走"；
    \item @{verbatim "Grant"}——"把能力传给别人"；
    \item @{verbatim "Create"}——"造新对象"；
    \item @{verbatim "Store"}——注释直接写着 "Simulates CNodeCap"，
          即"往这个对象里存能力"。
  \end{itemize}

  后四个是\emph{权威}，前两个不是。这个区分是整章的枢纽：
  隔离定理管的是权威，信息流定理管的才是数据。
\<close>

type_synonym entity_id = nat

datatype right = Read | Write | Take | Grant | Create | Store

record cap =
  target :: entity_id
  rights :: "right set"

datatype entity = Entity "cap set"

text \<open>
  @{verbatim "entity"} 只有一个构造子，但简化器不会自动把
  @{verbatim "case x of Entity caps \<Rightarrow> f caps"} 摊开——
  @{verbatim "System_S.thy"} 第 40 行为此写了一行
  @{verbatim "declare entity.splits [split]"}。
  少了它，本章后面的 @{verbatim "removeOperation_simpler"}、
  @{verbatim "direct_caps_of"} 一类的化简全会卡在
  @{verbatim "case"} 上。这是"仓库里的规范能编过、自己重打一遍却编不过"
  最典型的出处之一。
\<close>

declare entity.splits [split]

type_synonym state = "entity_id \<Rightarrow> entity option"
type_synonym modify_state = "state \<Rightarrow> state"
type_synonym modify_state_n = "state \<Rightarrow> state set"
type_synonym mask = "right set"

text \<open>
  四个同名的形状摆出来之后，把三样东西的型打印出来看一眼，
  本章后面所有算式都长在这个上面：
\<close>

typ cap
typ entity
typ state

definition null_entity :: "entity" where
  "null_entity \<equiv> Entity {}"

definition all_rights :: "right set" where
  "all_rights \<equiv> UNIV"

text \<open>
  真实规范里 @{verbatim "all_rights_def2"} 把 @{verbatim "UNIV"} 摊成
  六个构造子的集合，最后一步是 @{verbatim "metis right.exhaust"}——
  这正是第 17 章见过的那类"穷举有限类型"的小伎俩。
\<close>

lemma all_rights_def2: "all_rights = {Read, Write, Take, Grant, Create, Store}"
proof (rule set_eqI)
  fix x :: right
  show "x \<in> all_rights \<longleftrightarrow> x \<in> {Read, Write, Take, Grant, Create, Store}"
    unfolding all_rights_def
    by (cases x) auto
qed

definition is_entity :: "state \<Rightarrow> entity_id \<Rightarrow> bool" where
  "is_entity s e \<equiv> s e \<noteq> None"

definition direct_caps :: "entity \<Rightarrow> cap set" where
  "direct_caps e \<equiv> case e of Entity c \<Rightarrow> c"

definition direct_caps_of :: "state \<Rightarrow> entity_id \<Rightarrow> cap set" where
  "direct_caps_of s p \<equiv> case s p of
      None \<Rightarrow> {}
    | Some (Entity e) \<Rightarrow> e"

lemma no_direct_caps_of_in_nonEntity:
  "\<not> is_entity s e \<Longrightarrow> direct_caps_of s e = {}"
  by (auto simp: direct_caps_of_def is_entity_def split: option.splits)

lemma direct_caps_of_imp_is_entity:
  "c \<in> direct_caps_of s e \<Longrightarrow> is_entity s e"
  by (auto intro: classical dest: no_direct_caps_of_in_nonEntity)

text \<open>
  下一步是本章第一个"反直觉"的定义。能力指向对象，但\emph{指向}
  不等于\emph{连着}。@{verbatim "store_connected_direct"}
  （@{verbatim "System_S.thy"} 第 87 行）要求三条同时成立：
  能力在 @{verbatim "e\<^sub>x"} 手上、@{verbatim "Store"} 在权利集里、
  目标就是 @{verbatim "e\<^sub>y"}。只有带 @{verbatim "Store"} 的能力
  才产生一条边。然后 @{verbatim "store_connected"} 取闭包，
  @{verbatim "caps_of"} 把闭包 reachable 到的所有实体的能力集并起来：
  这就是"我通过层层 CNode 能看到的全部能力"。
\<close>

definition store_connected_direct :: "state \<Rightarrow> (entity_id \<times> entity_id) set" where
  "store_connected_direct s \<equiv>
     {(e\<^sub>x, e\<^sub>y). \<exists>cap. cap \<in> direct_caps_of s e\<^sub>x \<and>
                           Store \<in> rights cap \<and>
                           target cap = e\<^sub>y}"

definition store_connected :: "state \<Rightarrow> (entity_id \<times> entity_id) set" where
  "store_connected s \<equiv> (store_connected_direct s)^*"

definition caps_of :: "state \<Rightarrow> entity_id \<Rightarrow> cap set" where
  "caps_of s e \<equiv> \<Union>(direct_caps_of s ` {e'. (e, e') \<in> store_connected s})"

definition all_caps_of :: "state \<Rightarrow> cap set" where
  "all_caps_of s \<equiv> \<Union>e. direct_caps_of s e"

lemma store_connected_refl [simp]: "(e, e) \<in> store_connected s"
  by (simp add: store_connected_def)

lemma store_connected_direct_in_store_connected:
  "(x, y) \<in> store_connected_direct s \<Longrightarrow> (x, y) \<in> store_connected s"
  by (simp add: store_connected_def)

lemma direct_cap_in_cap: "c \<in> direct_caps_of s e \<Longrightarrow> c \<in> caps_of s e"
  by (auto simp: caps_of_def store_connected_def)

lemma no_caps_of_imp_not_connected [rule_format]:
  "(e, x) \<in> store_connected s \<Longrightarrow> direct_caps_of s e = {} \<longrightarrow> x = e"
  apply (unfold store_connected_def)
  apply (erule rtrancl.induct)
   apply simp
  apply (clarsimp simp: store_connected_direct_def)
  done

lemma no_direct_caps_of_no_caps_of:
  "(direct_caps_of s e = {}) = (caps_of s e = {})"
  apply (rule iffI)
   apply (clarsimp simp add: caps_of_def)
   apply (drule (1) no_caps_of_imp_not_connected)
   apply simp
  apply (clarsimp simp add: caps_of_def store_connected_def)
  done

lemma caps_of_empty: "direct_caps_of s e = {} \<Longrightarrow> caps_of s e = {}"
  by (rule no_direct_caps_of_no_caps_of [THEN iffD1])

lemma not_is_entity_imp_no_caps_of:
  "\<not> is_entity s e \<Longrightarrow> caps_of s e = {}"
  by (drule no_direct_caps_of_in_nonEntity, erule caps_of_empty)

lemma caps_of_imp_is_entity: "c \<in> caps_of s e \<Longrightarrow> is_entity s e"
  by (auto intro: classical dest: not_is_entity_imp_no_caps_of)

subsection \<open>24.3 一个算得出来的系统：三条边、两个孤岛、一张 Read 能力\<close>

text \<open>
  @{verbatim "Example.thy"} 用三个实体演示了 @{verbatim "caps_of"} 怎么算
  （它的 @{verbatim "scd"}、@{verbatim "sc"}、@{verbatim "ce0"} 三条引理
  就是把集合算成字面结果）。本章要演示的东西更多，所以自己造一个
  五实体的系统，故意让每一条"看起来该连"的边各代表一类：
\<close>

definition cA :: cap where "cA \<equiv> \<lparr>target = 1, rights = {Store}\<rparr>"
definition cB :: cap where "cB \<equiv> \<lparr>target = 2, rights = {Take, Grant}\<rparr>"
definition cC :: cap where "cC \<equiv> \<lparr>target = 5, rights = {Create}\<rparr>"
definition cD :: cap where "cD \<equiv> \<lparr>target = 3, rights = {Read, Write}\<rparr>"

text \<open>
  实体 0 手里是一条 @{verbatim "Store"} 能力（能往 1 里存东西），
  1 手里是一条 @{verbatim "Take, Grant"} 能力（指向 2），
  2 是空实体，3 手里是一条指向 5 的 @{verbatim "Create"} 能力而 5
  \emph{根本不存在}，4 手里是一条指向 3 的 @{verbatim "Read, Write"} 能力。

  这个形状刻意覆盖了四种"是不是连上了"：
  存能力的边（0→1）、只是权威但不是 Store 的边（1→2）、
  指向不存在对象的 Create 悬空能力（3⇢5）、
  纯数据权利（4⇢3）。
\<close>

definition sample_state :: state where
  "sample_state \<equiv>
     (\<lambda>e. if e = 0 then Some (Entity {cA})
             else if e = 1 then Some (Entity {cB})
             else if e = 2 then Some (Entity {})
             else if e = 3 then Some (Entity {cC})
             else if e = 4 then Some (Entity {cD})
             else None)"

lemma sample_dcaps_0: "direct_caps_of sample_state 0 = {cA}"
  by (simp add: sample_state_def direct_caps_of_def cA_def)

lemma sample_dcaps_1: "direct_caps_of sample_state 1 = {cB}"
  by (simp add: sample_state_def direct_caps_of_def cB_def)

lemma sample_dcaps_2: "direct_caps_of sample_state 2 = {}"
  by (simp add: sample_state_def direct_caps_of_def)

lemma sample_dcaps_3: "direct_caps_of sample_state 3 = {cC}"
  by (simp add: sample_state_def direct_caps_of_def cC_def)

lemma sample_dcaps_4: "direct_caps_of sample_state 4 = {cD}"
  by (simp add: sample_state_def direct_caps_of_def cD_def)

lemma sample_dcaps_exhaust [simp]:
  "direct_caps_of sample_state x =
     (if x = 0 then {cA}
      else if x = 1 then {cB}
      else if x = 2 then {}
      else if x = 3 then {cC}
      else if x = 4 then {cD}
      else {})"
  by (auto simp: direct_caps_of_def sample_state_def split: if_splits)

lemma sample_not_entity: "x \<notin> {0, 1, 2, 3, 4} \<Longrightarrow> sample_state x = None"
  by (auto simp: sample_state_def)

lemma sample_dcaps_other: "x \<notin> {0, 1, 2, 3, 4} \<Longrightarrow> direct_caps_of sample_state x = {}"
  by (drule sample_not_entity, simp add: direct_caps_of_def)

text \<open>
  先算直接的存能力边。四条能力里只有 @{verbatim "cA"} 带
  @{verbatim "Store"}，所以整个 @{verbatim "store_connected_direct"}
  恰好一条边：从 0 出发到 1。这一条等式把上面四种"看着像边"的关系
  一次说清了——@{verbatim "cB"} 有 @{verbatim "Take, Grant"} 却没有
  @{verbatim "Store"}，@{verbatim "cC"} 有 @{verbatim "Create"} 也没有
  @{verbatim "Store"}，@{verbatim "cD"} 只有数据权利。
\<close>

lemma scd_sample:
  "(x, z) \<in> store_connected_direct sample_state \<longleftrightarrow> (x = 0 \<and> z = 1)"
  by (auto simp: store_connected_direct_def cA_def cB_def cC_def cD_def)

lemma scd_sample_1_2: "(1, 2) \<notin> store_connected_direct sample_state"
  by (simp add: scd_sample)

lemma scd_sample_3_5: "(3, 5) \<notin> store_connected_direct sample_state"
  by (simp add: scd_sample)

lemma scd_sample_4_3: "(4, 3) \<notin> store_connected_direct sample_state"
  by (simp add: scd_sample)

text \<open>
  闭包因此几乎没有扩张：一条边加自反闭包，就是"原地不动，或者 0 走到 1"。
  这一步必须归纳，因为 @{verbatim "store_connected"} 是
  @{verbatim "rtrancl"}——simp 算不出闭包，只能证明"任何路径都长这样"。
\<close>

lemma sc_sample:
  "(x, z) \<in> store_connected sample_state
   \<longleftrightarrow> (x = z \<or> (x = 0 \<and> z = 1))"
proof
  assume "(x, z) \<in> store_connected sample_state"
  then show "x = z \<or> (x = 0 \<and> z = 1)"
    apply (unfold store_connected_def)
    apply (erule rtrancl.induct)
     apply simp
    apply (auto simp: scd_sample)
    done
next
  assume "x = z \<or> (x = 0 \<and> z = 1)"
  then show "(x, z) \<in> store_connected sample_state"
  proof
    assume "x = z"
    then show ?thesis by (simp add: store_connected_def)
  next
    assume "x = 0 \<and> z = 1"
    then have "(x, z) \<in> store_connected_direct sample_state" by (simp add: scd_sample)
    then show ?thesis by (simp add: store_connected_def)
  qed
qed

lemma sample_state_reachable:
  "{z. (n, z) \<in> store_connected sample_state} = (if n = 0 then {0, 1} else {n})"
  by (auto simp: sc_sample split: if_splits)

text \<open>
  @{verbatim "caps_of"} 的结果是"0 看得见 0 和 1 的全部能力，其余实体
  只看得见自己的"；5 因为根本不存在，能力集是空的。这里刻意把结论写成
  一条带 @{verbatim "n"} 的等式而不是六条带数字的等式：@{verbatim "nat"}
  的字面量在项里会以 @{verbatim "Suc"} 的形式出现，只有把
  @{verbatim "[simp]"} 挂在带模式变量的规则上，任何写法都能被重写。
\<close>

lemma caps_of_sample [simp]:
  "caps_of sample_state n =
     (if n = 0 then {cA, cB}
      else if n = 1 then {cB}
      else if n = 2 then {}
      else if n = 3 then {cC}
      else if n = 4 then {cD}
      else {})"
proof -
  have "caps_of sample_state n = \<Union>(direct_caps_of sample_state ` {z. (n, z) \<in> store_connected sample_state})"
    by (simp add: caps_of_def)
  also have "\<dots> = (if n = 0 then {cA, cB} else if n = 1 then {cB}
                        else if n = 2 then {} else if n = 3 then {cC}
                        else if n = 4 then {cD} else {})"
    by (subst sample_state_reachable) (auto split: if_splits)
  finally show ?thesis .
qed

lemma caps_of_sample_0: "caps_of sample_state 0 = {cA, cB}" by simp
lemma caps_of_sample_1: "caps_of sample_state 1 = {cB}" by simp
lemma caps_of_sample_2: "caps_of sample_state 2 = {}" by simp
lemma caps_of_sample_3: "caps_of sample_state 3 = {cC}" by simp
lemma caps_of_sample_4: "caps_of sample_state 4 = {cD}" by simp
lemma caps_of_sample_5: "caps_of sample_state 5 = {}" by simp

text \<open>
  两条型的打印，是这一段唯一的"机器回话"：一条能力集，
  一条实体对上的二元关系—— @{verbatim "caps_of"} 与
  @{verbatim "store_connected_direct"} 的差别就在这两行里。
\<close>

term "caps_of sample_state 0"
term "store_connected_direct sample_state"

text \<open>
  把四条能力各自的身份说清楚。@{verbatim "cA"} 造出了一条真正的存能力边；
  指向 2 的 @{verbatim "cB"} 没有造出边，却带着 @{verbatim "Take"} 与
  @{verbatim "Grant"}——24.6 会看到这才是"权威连接"的来源；
  指向不存在的 5 的 @{verbatim "cC"} 也一条边都不造，但它带
  @{verbatim "Create"}，而 @{verbatim "Create"} 在 24.5 会被
  @{verbatim "extra_rights"} 折算成"全部权利"。
\<close>

lemma entity_5_does_not_exist: "\<not> is_entity sample_state 5"
  by (auto simp: is_entity_def sample_state_def)

lemma sample_state_0_is_entity: "is_entity sample_state 0"
  by (auto simp: is_entity_def sample_state_def)

lemma sample_is_entities [simp]:
  "n \<in> {0, 1, 2, 3, 4} \<Longrightarrow> is_entity sample_state n"
  by (auto simp: is_entity_def sample_state_def)

lemma sample_not_entities [simp]:
  "n \<notin> {0, 1, 2, 3, 4} \<Longrightarrow> \<not> is_entity sample_state n"
  by (auto simp: is_entity_def sample_state_def)

lemma rights_cA [simp]: "rights cA = {Store}"
  by (simp add: cA_def)

lemma rights_cB [simp]: "rights cB = {Take, Grant}"
  by (simp add: cB_def)

lemma rights_cC [simp]: "rights cC = {Create}"
  by (simp add: cC_def)

lemma rights_cD [simp]: "rights cD = {Read, Write}"
  by (simp add: cD_def)

lemma target_cA [simp]: "target cA = 1" by (simp add: cA_def)
lemma target_cB [simp]: "target cB = 2" by (simp add: cB_def)
lemma target_cC [simp]: "target cC = 5" by (simp add: cC_def)
lemma target_cD [simp]: "target cD = 3" by (simp add: cD_def)

lemma rights_sample_caps:
  "rights cA = {Store} \<and> rights cB = {Take, Grant}
   \<and> rights cC = {Create} \<and> rights cD = {Read, Write}"
  by (simp add: cA_def cB_def cC_def cD_def)

lemma target_sample_caps:
  "target cA = 1 \<and> target cB = 2 \<and> target cC = 5 \<and> target cD = 3"
  by (simp add: cA_def cB_def cC_def cD_def)

ML \<open>writeln "==== 24.2/24.3 段落 ===="\<close>

subsection \<open>24.4 八个系统调用，以及"合法"到底查什么\<close>

text \<open>
  @{verbatim "sysOPs"}（@{verbatim "System_S.thy"} 第 144 行）是八个构造子。
  第 5、6 章从内核代码里认出来的 @{verbatim "CNode_Revoke"}、
  @{verbatim "CNode_Mint"}、@{verbatim "CNode_Move"} 在这里都有对应物，
  但名字是 take/grant 文献的名字：
  @{verbatim "SysTake"} 把别人手里的能力夺到自己这里（对应
  @{verbatim "Take"} 权利），@{verbatim "SysGrant"} 把自己的能力传给别人，
  @{verbatim "SysCopy"} 往一个 @{verbatim "Store"} 得住的对象里存一份，
  @{verbatim "SysRemove"} 删一条，@{verbatim "SysRemoveSet"} 删一批，
  @{verbatim "SysRevoke"} 撤销（第 6 章那棵 CDT 在这里的抽象形态），
  @{verbatim "SysDestroy"} 连对象一起消失，@{verbatim "SysCreate"} 造新对象。
\<close>

datatype sysOPs =
    SysCreate entity_id cap cap
  | SysTake   entity_id cap cap mask
  | SysGrant  entity_id cap cap mask
  | SysCopy   entity_id cap cap mask
  | SysRemove entity_id cap cap
  | SysRemoveSet entity_id cap "cap set"
  | SysRevoke entity_id cap
  | SysDestroy entity_id cap

text \<open>
  @{verbatim "legal"} 是 @{verbatim "primrec"}，八个分支各自查一件事，
  而且\emph{每一条}都先问 @{verbatim "is_entity s e"}——调用者必须存在。
  第 10 章在 C 代码里看到的 @{verbatim "decodeCapIdentifier"}
  在这里被抽象成"能力在 @{verbatim "caps_of s e"} 里"：
  不是"槽位号对不对"，而是"你有没有这个权威"。

  三个细节值得停下来看：
  \begin{itemize}
    \item @{verbatim "SysCreate"} 要求目标 @{verbatim "c\<^sub>2"}
          \emph{尚不存在}（@{verbatim "\<not> is_entity s (target c\<^sub>2)"}），
          还要一条带 @{verbatim "Write, Store"} 的能力加一条带
          @{verbatim "Create"} 的能力；
    \item @{verbatim "SysGrant"} 与 @{verbatim "SysCopy"} 的差别只在最后一条
          权利检查（@{verbatim "Grant"} 对 @{verbatim "Store"}）；
    \item @{verbatim "SysDestroy"} 是八条里唯一看\emph{全局}的：
          除了 @{verbatim "{Create} = rights c"}，还要求
          @{verbatim "target c"} 不是任何别的能力的目标——
          即"最后一个引用者消失"。这正是第 6 章
          @{verbatim "ctTeardown"} 之前那句 refcount 检查的抽象。
  \end{itemize}
\<close>

primrec legal :: "sysOPs \<Rightarrow> state \<Rightarrow> bool" where
  "legal (SysCreate e c\<^sub>1 c\<^sub>2) s =
     (is_entity s e \<and> is_entity s (target c\<^sub>1) \<and> \<not> is_entity s (target c\<^sub>2) \<and>
      {c\<^sub>1, c\<^sub>2} \<subseteq> caps_of s e \<and>
      Write \<in> rights c\<^sub>1 \<and> Store \<in> rights c\<^sub>1 \<and> Create \<in> rights c\<^sub>2)"
| "legal (SysTake  e c\<^sub>1 c\<^sub>2 r) s =
     (is_entity s e \<and> is_entity s (target c\<^sub>1) \<and>
      c\<^sub>1 \<in> caps_of s e \<and> c\<^sub>2 \<in> caps_of s (target c\<^sub>1) \<and>
      Take \<in> rights c\<^sub>1)"
| "legal (SysGrant e c\<^sub>1 c\<^sub>2 r) s =
     (is_entity s e \<and> is_entity s (target c\<^sub>1) \<and>
      {c\<^sub>1, c\<^sub>2} \<subseteq> caps_of s e \<and> Grant \<in> rights c\<^sub>1)"
| "legal (SysCopy  e c\<^sub>1 c\<^sub>2 r) s =
     (is_entity s e \<and> is_entity s (target c\<^sub>1) \<and>
      {c\<^sub>1, c\<^sub>2} \<subseteq> caps_of s e \<and> Store \<in> rights c\<^sub>1)"
| "legal (SysRemove e c\<^sub>1 c\<^sub>2) s = (is_entity s e \<and> c\<^sub>1 \<in> caps_of s e)"
| "legal (SysRemoveSet e c C) s = (is_entity s e \<and> c \<in> caps_of s e)"
| "legal (SysRevoke e c) s = (is_entity s e \<and> c \<in> caps_of s e)"
| "legal (SysDestroy e c) s =
     (is_entity s e \<and> c \<in> caps_of s e \<and> {Create} = rights c \<and>
      target c \<notin> target ` (all_caps_of s - {c}))"

text \<open>
  操作怎么改状态。@{verbatim "diminish"} 就是第 3 章的权利掩码，
  交集形式与 @{verbatim "cap_rights_of"} 那边一模一样。
  注意 @{verbatim "takeOperation"} 写的是 @{verbatim "e"} 自己，
  @{verbatim "grantOperation"} 与 @{verbatim "copyOperation"} 写的都是
  @{verbatim "target c\<^sub>1"}——"往谁的槽位里放"这件事在三个操作里
  指向不同的实体，这是它们最容易记混的地方。
\<close>

definition diminish :: "right set \<Rightarrow> cap \<Rightarrow> cap" where
  "diminish R cap \<equiv> cap \<lparr> rights := rights cap \<inter> R \<rparr>"

definition takeOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> cap \<Rightarrow> right set \<Rightarrow> modify_state" where
  "takeOperation e c\<^sub>1 c\<^sub>2 R s \<equiv>
     s (e \<mapsto> Entity (insert (diminish R c\<^sub>2) (direct_caps_of s e)))"

definition grantOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> cap \<Rightarrow> right set \<Rightarrow> modify_state" where
  "grantOperation e c\<^sub>1 c\<^sub>2 R s \<equiv>
     s (target c\<^sub>1 \<mapsto> Entity (insert (diminish R c\<^sub>2) (direct_caps_of s (target c\<^sub>1))))"

definition copyOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> cap \<Rightarrow> right set \<Rightarrow> modify_state" where
  "copyOperation e c\<^sub>1 c\<^sub>2 R s \<equiv>
     s (target c\<^sub>1 \<mapsto> Entity (insert (diminish R c\<^sub>2) (direct_caps_of s (target c\<^sub>1))))"

definition removeOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> cap \<Rightarrow> modify_state" where
  "removeOperation e c\<^sub>1 c\<^sub>2 s \<equiv>
     if is_entity s (target c\<^sub>1)
     then s (target c\<^sub>1 \<mapsto> Entity ((direct_caps_of s (target c\<^sub>1)) - {c\<^sub>2}))
     else s"

definition removeSetOfCaps :: "(entity_id \<Rightarrow> cap set) \<Rightarrow> modify_state" where
  "removeSetOfCaps cap_map s \<equiv>
     \<lambda>e. if is_entity s e then Some (Entity (direct_caps_of s e - cap_map e)) else None"

definition caps_to_entity :: "entity_id \<Rightarrow> entity_id \<Rightarrow> state \<Rightarrow> cap set" where
  "caps_to_entity e e' s \<equiv> {cap. cap \<in> direct_caps_of s e' \<and> target cap = e}"

definition revokeOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> modify_state_n" where
  "revokeOperation e c s \<equiv>
     {s'. \<exists>cap_map. \<forall>e'. cap_map e' \<subseteq> caps_to_entity (target c) e' s \<and>
                      s' = removeSetOfCaps cap_map s}"

text \<open>
  照抄真实定义时留意一个形状（@{verbatim "l4v/spec/take-grant/System_S.thy"} 第 292 行）：
  @{verbatim "\<forall>e'"} 的辖域里同时含 @{verbatim "s' = removeSetOfCaps cap_map s"}，
  而这条等式根本与 @{verbatim "e'"} 无关。括号加在别处会得到同一个集合，
  读代码时却容易误以为"每个实体的删除集还决定 s'"。
  真正要紧的是前一半：删除集必须落在
  @{verbatim "caps_to_entity (target c) e' s"} 里，
  也就是"只准删指向被回收对象的能力"。
\<close>

definition destroyOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> modify_state" where
  "destroyOperation e c s \<equiv> s(target c := None)"

definition full_cap :: "entity_id \<Rightarrow> cap" where
  "full_cap e \<equiv> \<lparr>target = e, rights = all_rights\<rparr>"

definition createOperation :: "entity_id \<Rightarrow> cap \<Rightarrow> cap \<Rightarrow> modify_state" where
  "createOperation e c\<^sub>1 c\<^sub>2 s \<equiv>
     s (target c\<^sub>1 \<mapsto> Entity (insert (full_cap (target c\<^sub>2))
                                       (direct_caps_of s (target c\<^sub>1))),
        target c\<^sub>2 \<mapsto> null_entity)"

text \<open>
  真实规范里 @{verbatim "createOperation"} 放进去的是
  @{verbatim "full_cap (target c\<^sub>2)"}，即一条带全部六个权利的能力
  （@{verbatim "System_S.thy"} 第 138 行）。新对象一诞生，
  创建者对它就有 @{verbatim "Take, Grant, Create, Store"}——
  这就是"谁造的归谁管"的形式化，也是第 23 章那张 capDL 图里
  根能力从哪来的答案。
\<close>

definition removeSetOperation ::
  "entity_id \<Rightarrow> cap \<Rightarrow> cap set \<Rightarrow> modify_state" where
  "removeSetOperation e c C s \<equiv>
     if is_entity s (target c)
     then s (target c \<mapsto> Entity ((direct_caps_of s (target c)) - C))
     else s"

text \<open>
  两个删除性操作都带 @{verbatim "is_entity"} 守卫
  （@{verbatim "l4v/spec/take-grant/System_S.thy"} 第 236 行、第 254 行）：
  目标实体不存在时整个操作退化成 @{verbatim "s"}。
  少了这个守卫，@{verbatim "removeOperation"} 会"顺手"把一个不存在的实体
  建成一个空实体的实体——那不是删除，是创建。
  守卫写成 @{verbatim "case"} 形式更好用，真实文件也给这两条起了名字
  （同文件第 242 行、第 259 行）：
\<close>

lemma removeOperation_simpler:
  "removeOperation e c\<^sub>1 c\<^sub>2 s \<equiv>
     (case s (target c\<^sub>1) of
        None \<Rightarrow> s
      | Some (Entity caps) \<Rightarrow> s (target c\<^sub>1 \<mapsto> Entity (caps - {c\<^sub>2})))"
  by (rule eq_reflection, simp add: removeOperation_def is_entity_def direct_caps_of_def
                             split: if_split_asm option.splits)

lemma removeSetOperation_simpler:
  "removeSetOperation e c caps s \<equiv>
     (case s (target c) of
        None \<Rightarrow> s
      | Some (Entity caps') \<Rightarrow> s (target c \<mapsto> Entity (caps' - caps)))"
  by (rule eq_reflection, simp add: removeSetOperation_def is_entity_def direct_caps_of_def
                             split: if_split_asm option.splits)

primrec step' :: "sysOPs \<Rightarrow> modify_state_n" where
  "step' (SysCreate    e c\<^sub>1 c\<^sub>2) s   = {createOperation e c\<^sub>1 c\<^sub>2 s}"
| "step' (SysTake      e c\<^sub>1 c\<^sub>2 R) s = {takeOperation  e c\<^sub>1 c\<^sub>2 R s}"
| "step' (SysGrant     e c\<^sub>1 c\<^sub>2 R) s = {grantOperation e c\<^sub>1 c\<^sub>2 R s}"
| "step' (SysCopy      e c\<^sub>1 c\<^sub>2 R) s = {copyOperation e c\<^sub>1 c\<^sub>2 R s}"
| "step' (SysRemove    e c\<^sub>1 c\<^sub>2)   s = {removeOperation e c\<^sub>1 c\<^sub>2 s}"
| "step' (SysRemoveSet e c C)      s = {removeSetOperation e c C s}"
| "step' (SysRevoke    e c)       s = revokeOperation e c s"
| "step' (SysDestroy   e c)       s = {destroyOperation e c s}"

text \<open>
  @{verbatim "step"} 是这条链上最"廉价"也最要紧的定义，两处都写了
  @{verbatim "{s}"}：非法调用被整个吞掉，走 @{verbatim "else"} 分支；
  合法调用则\emph{额外}把当前状态也留在结果集里，走
  @{verbatim "step' cmd s \<union> {s}"}。前者是"内核拒绝越权"，
  后者是"合法的调用也可能一事无成"——第 16、17 章反复见过的口径：
  不能凭"这一步没生效"去推翻不变式。
\<close>

definition step :: "sysOPs \<Rightarrow> modify_state_n" where
  "step cmd s \<equiv> if legal cmd s then step' cmd s \<union> {s} else {s}"

primrec execute :: "sysOPs list \<Rightarrow> state \<Rightarrow> state set" where
  "execute [] s = {s}"
| "execute (cmd # cmds) s = \<Union> (step cmd ` (execute cmds s))"

primrec actor :: "sysOPs \<Rightarrow> entity_id" where
  "actor (SysCreate    e c\<^sub>1 c\<^sub>2) = e"
| "actor (SysTake      e c\<^sub>1 c\<^sub>2 R) = e"
| "actor (SysGrant     e c\<^sub>1 c\<^sub>2 R) = e"
| "actor (SysCopy      e c\<^sub>1 c\<^sub>2 R) = e"
| "actor (SysRemove    e c\<^sub>1 c\<^sub>2) = e"
| "actor (SysRemoveSet e c C) = e"
| "actor (SysRevoke    e c) = e"
| "actor (SysDestroy   e c) = e"

lemma legal_actor_exists: "legal cmd s \<Longrightarrow> is_entity s (actor cmd)"
  by (cases cmd) auto

text \<open>
  把 @{verbatim "legal"} 在 24.3 那个系统上跑一遍，八条分支的性格就清楚了。
  先要一条全局事实：整个系统里的能力只有四条。
\<close>

lemma all_caps_of_sample_subset:
  "all_caps_of sample_state \<subseteq> {cA, cB, cC, cD}"
proof
  fix c assume "c \<in> all_caps_of sample_state"
  then obtain a where "c \<in> direct_caps_of sample_state a"
    unfolding all_caps_of_def by blast
  then show "c \<in> {cA, cB, cC, cD}" by (simp split: if_splits)
qed

text \<open>
  整个系统里只有一条能力指向 5。这句话是 @{verbatim "SysDestroy"}
  那条全局检查能否通过的关键，写成规则比写成集合等式好用。
\<close>

lemma only_cC_targets_5:
  "c \<in> all_caps_of sample_state \<Longrightarrow> target c = 5 \<Longrightarrow> c = cC"
proof -
  assume c: "c \<in> all_caps_of sample_state" and t: "target c = 5"
  from c obtain a where "c \<in> direct_caps_of sample_state a"
    unfolding all_caps_of_def by blast
  then have "c = cA \<or> c = cB \<or> c = cC \<or> c = cD"
    by (auto split: if_splits)
  then show "c = cC" using t by (auto simp: cA_def cB_def cC_def cD_def)
qed

lemma legal_remove_sample: "legal (SysRemove 0 cA cB) sample_state"
  by simp

lemma legal_copy_sample: "legal (SysCopy 0 cA cB {Grant}) sample_state"
  by simp

lemma legal_grant_sample: "legal (SysGrant 0 cB cA {Store}) sample_state"
  by simp

lemma illegal_take_sample: "\<not> legal (SysTake 1 cB cA {Take}) sample_state"
  by simp

lemma illegal_revoke_of_none: "\<not> legal (SysRevoke 5 cC) sample_state"
  by auto

lemma illegal_create_sample: "\<not> legal (SysCreate 3 cC cC) sample_state"
  by auto

lemma legal_destroy_sample: "legal (SysDestroy 3 cC) sample_state"
  by (auto dest: only_cC_targets_5)

text \<open>
  @{verbatim "SysDestroy"} 那条"全局唯一引用"的检查在这里真的起作用了：
  @{verbatim "cC"} 指向 5，而 @{verbatim "only_cC_targets_5"} 说全系统只有它
  一条指着 5，于是两条检查都过、销毁合法。
  @{verbatim "SysDestroy"} 4 @{verbatim "cD"} 立刻不合法——但挡住它的不是
  "别人还指着 3"（ @{verbatim "cD"} 把自己排除在 @{verbatim "all_caps_of s - {c}"}
  之外，那一半其实成立），而是 @{verbatim "{Create} = rights c"}：
  @{verbatim "cD"} 只有 @{verbatim "{Read, Write}"}。
  两条检查是合取关系，任一不过整体就不过。
  这台样本系统里 @{verbatim "Create"} 只出现在 @{verbatim "cC"} 一条上，
  所以"权利够、但目标被别人也指着"那一格没法在这里演示——
  要演示就得再造一条带 @{verbatim "Create"} 的能力，而那恰好会破坏
  @{verbatim "only_cC_targets_5"}，把上面这条合法销毁也一起弄掉。
\<close>

lemma illegal_destroy_wrong_rights:
  "\<not> legal (SysDestroy 4 cD) sample_state"
  by auto

text \<open>
  @{verbatim "step"} 的两处"什么都不做"值得单独记下来，
  24.8 的归纳要用到：非法调用返回 @{verbatim "{s}"}，
  合法调用也把 @{verbatim "s"} 本身留在结果集里。
\<close>

lemma step_illegal_is_skip: "\<not> legal cmd s \<Longrightarrow> step cmd s = {s}"
  by (simp add: step_def)

lemma self_in_step: "legal cmd s \<Longrightarrow> s \<in> step cmd s"
  by (simp add: step_def)

lemma step_subset_self_or_op: "s' \<in> step cmd s \<Longrightarrow> s' = s \<or> s' \<in> step' cmd s"
  by (auto simp: step_def split: if_splits)

lemma execute_singleton: "execute [cmd] s = step cmd s"
  by simp

lemma execute_two_back_to_front:
  "execute [cmd\<^sub>1, cmd\<^sub>2] s = (\<Union>s' \<in> step cmd\<^sub>2 s. step cmd\<^sub>1 s')"
  by (simp add: image_def)

text \<open>
  @{verbatim "execute_two_back_to_front"} 这条不是可有可无的细节：
  列表是\emph{从尾部往头部}执行的（@{verbatim "System_S.thy"} 第 322 行
  的注释原话是 "execution of a list of commands (from back of list)"）。
  读别人的 take-grant 证明时如果把 @{verbatim "[a, b]"} 当成
  "先 a 后 b"，几乎所有归纳假设都会反着长。
\<close>

lemma step_not_empty: "step cmd s \<noteq> {}"
  by (auto simp: step_def split: if_splits)

lemma execute_not_empty: "\<exists>s'. s' \<in> execute ops s"
proof (induction ops arbitrary: s)
  case Nil then show ?case by simp
next
  case (Cons cmd cmds s)
  then obtain s'' where hS: "s'' \<in> execute cmds s" by blast
  then obtain y where hY: "y \<in> step cmd s''"
    using step_not_empty[of cmd s''] by blast
  have hE: "y \<in> execute (cmd # cmds) s"
    unfolding execute.simps by (metis Union_iff hS hY image_eqI)
  from hE show ?case by (rule exI[of _ y])
qed

lemma execute_Cons_range:
  assumes "s' \<in> execute (cmd # cmds) s"
  shows "\<exists>s''. s'' \<in> execute cmds s \<and> s' \<in> step cmd s''"
  using assms by (auto simp: image_iff)

text \<open>
  反过来，一串越权调用是真正的"空转"：每一步都在同一个状态上被
  @{verbatim "legal"} 拒绝，状态一步也没动过。
\<close>

lemma execute_all_illegal_is_skip:
  assumes "\<forall>op \<in> set ops. \<not> legal op s"
  shows "execute ops s = {s}"
  using assms by (induction ops arbitrary: s) (auto simp: step_def)

lemma execute_two_illegal_calls_do_nothing:
  "execute [SysTake 1 cB cA {Take}, SysRevoke 5 cC] sample_state = {sample_state}"
  by (rule execute_all_illegal_is_skip,
      auto simp: illegal_take_sample illegal_revoke_of_none)

ML \<open>writeln "==== 24.4 段落 ===="\<close>

subsection \<open>24.5 权威序：把 Create 读成"全部权利"\<close>

text \<open>
  24.4 回答的是"这次调用能不能做"。剩下五节回答另一个问题：
  调用做完之后\emph{权威}落到了谁手里。这需要的不是集合相等，
  而是一个"不少于"的序。

  第一步是 @{verbatim "extra_rights"}
  （@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 17 行），
  它头上的注释只有一句："These translate Create into all_rights"。
  在这模型里，一条带 @{verbatim "Create"} 的能力被折算成对该目标的
  \emph{全权}。理由很实在：seL4 里 @{verbatim "Create"} 是 untyped
  那类对象的权利——拿着它就能在这个范围内造出新对象，
  而新对象一出生，创建者看到的就是 @{verbatim "full_cap"}
  （24.4 的 @{verbatim "createOperation"} 已经算过这件事）。
  "能造"于是等于"能拿到全部六个权利"，抽象模型就把这一步直接摊平。

  先把七条"单权利能力"摆齐。它们从 @{verbatim "read_cap"}
  （@{verbatim "l4v/spec/take-grant/System_S.thy"} 第 114 行）起，
  六个构造子一直排到第 138 行的 @{verbatim "full_cap"}——
  这一排就是 24.6 里 @{verbatim "leak"} 的字母表
  （本章因为 @{verbatim "createOperation"} 先用到，已经提前定义了最后这条）：
\<close>

definition read_cap :: "entity_id \<Rightarrow> cap" where
  "read_cap e\<^sub>x \<equiv> \<lparr>target = e\<^sub>x, rights = {Read}\<rparr>"

definition write_cap :: "entity_id \<Rightarrow> cap" where
  "write_cap e\<^sub>x \<equiv> \<lparr>target = e\<^sub>x, rights = {Write}\<rparr>"

definition take_cap :: "entity_id \<Rightarrow> cap" where
  "take_cap e\<^sub>x \<equiv> \<lparr>target = e\<^sub>x, rights = {Take}\<rparr>"

definition grant_cap :: "entity_id \<Rightarrow> cap" where
  "grant_cap e\<^sub>x \<equiv> \<lparr>target = e\<^sub>x, rights = {Grant}\<rparr>"

definition create_cap :: "entity_id \<Rightarrow> cap" where
  "create_cap e\<^sub>x \<equiv> \<lparr>target = e\<^sub>x, rights = {Create}\<rparr>"

definition store_cap :: "entity_id \<Rightarrow> cap" where
  "store_cap e \<equiv> \<lparr>target = e, rights = {Store}\<rparr>"

text \<open>
  每条都是"指向 @{verbatim "e\<^sub>x"}、只有一个权利"的抽象能力。
  有了它们，"某实体对 @{verbatim "e\<^sub>x"} 有 @{verbatim "Take"} 权威"
  就能写成一条具体的能力 @{verbatim "take_cap e\<^sub>x"} 在不在对方手里。

  现在把 @{verbatim "Create"} 摊平这件事写成定义：
\<close>

definition extra_rights :: "cap \<Rightarrow> cap" where
  "extra_rights c \<equiv>
     if Create \<in> rights c then c\<lparr>rights := all_rights\<rparr> else c"

lemma extra_rights_idem [simp]: "extra_rights (extra_rights c) = extra_rights c"
  by (clarsimp simp: extra_rights_def)

lemma target_extra_rights [simp]: "target (extra_rights c) = target c"
  by (simp add: extra_rights_def)

lemma rights_extra_rights:
  "rights (extra_rights c) = (if Create \<in> rights c then all_rights else rights c)"
  by (simp add: extra_rights_def)

text \<open>
  这条规则\emph{不能}标 @{verbatim "[simp]"}。它带假设
  @{verbatim "Create \<notin> rights c"}，而 @{verbatim "extra_rights"} 出现在
  本章几乎每一个目标里：一旦进了简化器集合，每碰到一个
  @{verbatim "extra_rights"} 实例都要先跑一遍子简化去证那个条件，
  24.7 的 @{verbatim "direct_caps_of_generalOp2"} 因此从 3 秒变成一分多钟。
  把它降级成普通引理、需要时点名使用，才是正常速度。
\<close>

lemma extra_rights_no_create: "Create \<notin> rights c \<Longrightarrow> extra_rights c = c"
  by (simp add: extra_rights_def)

lemma extra_rights_full_cap [simp]: "extra_rights (full_cap e) = full_cap e"
  by (simp add: extra_rights_def full_cap_def all_rights_def)

text \<open>
  真实文件里 @{verbatim "diminish"} 与 @{verbatim "extra_rights"} 的配合
  有两条 simp 规则（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 199 行、
  第 203 行），它们说的是同一件事：先摊平再打掩码，等于直接打掩码——
  掩码 @{verbatim "Create"} 摊平之后已经无所谓了。
  24.7 把四个操作改写成 @{verbatim "generalOperation"} 时全靠它们化简：
  少了第二条，@{verbatim "take_general"} 那种"两边写得不一样的状态等式"
  就化不到一块去。
\<close>

lemma diminish_extra_rights [simp]:
  "diminish (rights c) (extra_rights c) = c"
  by (simp add: diminish_def all_rights_def rights_extra_rights)

lemma diminish_extra_rights2 [simp]:
  "diminish (r \<inter> rights c) (extra_rights c) = diminish r c"
  apply (simp add: diminish_def extra_rights_def all_rights_def)
  apply (simp add: Int_commute)
  apply (subgoal_tac "rights c \<inter> (r \<inter> rights c) = r \<inter> rights c")
   apply simp
  apply fastforce
  done

text \<open>
  两个序。@{verbatim "cap_in_caps"}（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 52 行）
  读作"c 这条能力'算在'集合 C 里"——不要求 C 真有一条一模一样的能力，
  只要有一条指向同一对象、权利不少于它的：
\<close>

definition cap_in_caps :: "cap \<Rightarrow> cap set \<Rightarrow> bool" (infix "\<in>cap" 50) where
  "c \<in>cap C \<equiv>
     \<exists>c' \<in> C. target c = target c' \<and>
              rights (extra_rights c) \<subseteq> rights (extra_rights c')"

text \<open>
  另一个方向：一个集合整体不超过一条能力。
  @{verbatim "caps_dominated_by"}（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 71 行）
  是本章所有结论的最终形状——"@{verbatim "island_caps s x \<le>cap c"}"
  就是说孤岛 @{verbatim "x"} 里的每一条权威都被 @{verbatim "c"} 压住。
\<close>

definition caps_dominated_by :: "cap set \<Rightarrow> cap \<Rightarrow> bool" (infix "\<le>cap" 50) where
  "caps \<le>cap cap \<equiv>
     \<forall>cap' \<in> caps. target cap' = target cap \<longrightarrow>
                   rights (extra_rights cap') \<subseteq> rights (extra_rights cap)"

lemma cap_in_caps_singleton [simp]:
  "c \<in>cap {c'} =
     (target c = target c' \<and> rights (extra_rights c) \<subseteq> rights (extra_rights c'))"
  by (simp add: cap_in_caps_def)

lemma cap_in_caps_insert [simp]:
  "c \<in>cap insert c' S =
     (target c = target c' \<and> rights (extra_rights c) \<subseteq> rights (extra_rights c')
      \<or> c \<in>cap S)"
  by (simp add: cap_in_caps_def)

lemma cap_in_capsI:
  "\<lbrakk>c' \<in> C; target c = target c'; rights (extra_rights c) \<subseteq> rights (extra_rights c')\<rbrakk>
   \<Longrightarrow> c \<in>cap C"
  by (auto simp: cap_in_caps_def)

lemma cap_in_caps_mono:
  "\<lbrakk>c \<in>cap C; C \<subseteq> D\<rbrakk> \<Longrightarrow> c \<in>cap D"
  by (auto simp: cap_in_caps_def)

lemma not_in [simp]: "{} \<le>cap c"
  by (simp add: caps_dominated_by_def)

lemma caps_dominated_byI:
  "\<lbrakk>\<And>cap'. cap' \<in> caps \<Longrightarrow> target cap' = target c \<Longrightarrow>
              rights (extra_rights cap') \<subseteq> rights (extra_rights c)\<rbrakk>
   \<Longrightarrow> caps \<le>cap c"
  by (auto simp: caps_dominated_by_def)

text \<open>
  在 24.3 的系统上算几笔，这个序的脾气就清楚了。
  四条样本能力里只有 @{verbatim "cC"} 带 @{verbatim "Create"}：
\<close>

lemma extra_rights_cA [simp]: "extra_rights cA = cA"
  by (simp add: extra_rights_def)

lemma extra_rights_cB [simp]: "extra_rights cB = cB"
  by (simp add: extra_rights_def)

lemma extra_rights_cD [simp]: "extra_rights cD = cD"
  by (simp add: extra_rights_def)

lemma extra_rights_cC [simp]: "rights (extra_rights cC) = all_rights"
  by (simp add: rights_extra_rights)

text \<open>
  于是那条指向不存在的实体 5 的 @{verbatim "Create"} 能力，
  在权威序里和一条 @{verbatim "full_cap 5"} 等价——
  这是本章第二处"看着不像、算出来是"：
\<close>

lemma cC_incap_full5: "cC \<in>cap {full_cap 5}"
  by (rule cap_in_capsI [of "full_cap 5"]) (auto simp: full_cap_def extra_rights_def)

lemma full5_incap_cC: "full_cap 5 \<in>cap {cC}"
  by (rule cap_in_capsI [of cC]) (auto simp: full_cap_def extra_rights_def)

text \<open>
  反过来，两条纯数据权利的能力谁都压不住。@{verbatim "cD"}
  指向 3，可权利集是 @{verbatim "{Read, Write}"}，
  连 @{verbatim "Take"} 都不覆盖：
\<close>

lemma take_cap_not_incap_cD: "\<not> (take_cap 3 \<in>cap {cD})"
  by (simp add: take_cap_def extra_rights_def cap_in_caps_def)

lemma grant_cap_not_incap_cD: "\<not> (grant_cap 3 \<in>cap {cD})"
  by (simp add: grant_cap_def extra_rights_def cap_in_caps_def)

text \<open>
  @{verbatim "cB"} 则有两条权威：指向 2 的 @{verbatim "take_cap"}、
  @{verbatim "grant_cap"} 都算"在"它里面。
\<close>

lemma take_cap_2_incap_cB: "take_cap 2 \<in>cap {cB}"
  by (simp add: take_cap_def extra_rights_def cap_in_caps_def)

lemma grant_cap_2_incap_cB: "grant_cap 2 \<in>cap {cB}"
  by (simp add: grant_cap_def extra_rights_def cap_in_caps_def)

text \<open>
  最后一笔要小看：@{verbatim "\<le>cap"} 的定义里那条
  @{verbatim "target cap' = target cap \<longrightarrow>"} 是\emph{前件}。
  指向别的对象的能力既不帮忙也不添乱，它们只是让这条蕴含式空转。
  所以下面这条是成立的，理由却不是"@{verbatim "cA"} 比
  @{verbatim "cB"} 小"，而是"@{verbatim "cA"} 压根不指向 2"：
\<close>

lemma sample_caps_le_cB: "{cA, cB} \<le>cap cB"
  by (intro caps_dominated_byI) (auto simp: all_rights_def)

text \<open>
  这条"空转"正是 @{verbatim "island_caps"} 存在的理由：
  要谈"一个孤岛的总权威"，必须先把岛上所有实体的能力并起来
  （24.8），否则 @{verbatim "\<le>cap"} 会假装什么都没看见。
\<close>

ML \<open>writeln "==== 24.5 段落 ===="\<close>

subsection \<open>24.6 "连着"：一条泄漏就是一条边\<close>

text \<open>
  有了权威序，就可以回答"两个实体之间通不通"。真实规范用三段话答完
  （@{verbatim "shares_caps"} 在
  @{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 78 行、
  @{verbatim "leak"} 在第 82 行）：
\<close>

definition shares_caps :: "state \<Rightarrow> entity_id \<Rightarrow> entity_id \<Rightarrow> bool" where
  "shares_caps s e\<^sub>x e\<^sub>y \<equiv>
     \<exists>e\<^sub>i. (e\<^sub>x, e\<^sub>i) \<in> store_connected s \<and> (e\<^sub>y, e\<^sub>i) \<in> store_connected s"

definition leak :: "state \<Rightarrow> entity_id \<Rightarrow> entity_id \<Rightarrow> bool"
  ("_ \<turnstile> _ \<rightarrow> _") where
  "leak s e\<^sub>x e\<^sub>y \<equiv>
     take_cap e\<^sub>x \<in>cap caps_of s e\<^sub>y \<or>
     grant_cap e\<^sub>y \<in>cap caps_of s e\<^sub>x \<or>
     shares_caps s e\<^sub>x e\<^sub>y"

text \<open>
  三段各自对应一种"权威能过去"的情形：
  @{verbatim "e\<^sub>y"} 手里有指向 @{verbatim "e\<^sub>x"} 的 Take 能力
  （@{verbatim "e\<^sub>y"} 能把 @{verbatim "e\<^sub>x"} 的东西拿过来）、
  @{verbatim "e\<^sub>x"} 手里有指向 @{verbatim "e\<^sub>y"} 的 Grant 能力
  （@{verbatim "e\<^sub>x"} 能把东西塞给 @{verbatim "e\<^sub>y"}），
  或者两者能汇到同一个 @{verbatim "store_connected"} 终点
  （同一个 CNode 里存能力，谁存谁就能给别人看）。

  注意 @{verbatim "leak"} 是\emph{有方向}的：@{verbatim "e\<^sub>x \<rightarrow> e\<^sub>y"}
  说的是"权威能从 x 流向 y"，而 Take 那一段的方向恰好是反的——
  能力在 @{verbatim "e\<^sub>y"} 手里、指向 @{verbatim "e\<^sub>x"}。
  这个反向是第 6 章 CDT 里"revoke 会波及谁"的同一件事。

  把 @{verbatim "leak"} 和它的反向并起来就是边，边取闭包就是连通：
\<close>

definition directly_tgs_connected :: "state \<Rightarrow> (entity_id \<times> entity_id) set" where
  "directly_tgs_connected s \<equiv> {(e\<^sub>x, e\<^sub>y). leak s e\<^sub>x e\<^sub>y \<or> leak s e\<^sub>y e\<^sub>x}"

abbreviation in_directly_tgs_connected ::
  "state \<Rightarrow> entity_id \<Rightarrow> entity_id \<Rightarrow> bool"
  ("_ \<turnstile> _ \<leftrightarrow> _" [60, 0, 60] 61) where
  "s \<turnstile> x \<leftrightarrow> y \<equiv> (x, y) \<in> directly_tgs_connected s"

definition tgs_connected :: "state \<Rightarrow> (entity_id \<times> entity_id) set" where
  "tgs_connected s \<equiv> (directly_tgs_connected s)^*"

abbreviation in_tgs_connected ::
  "state \<Rightarrow> entity_id \<Rightarrow> entity_id \<Rightarrow> bool"
  ("_ \<turnstile> _ \<leftrightarrow>* _" [60, 0, 60] 61) where
  "s \<turnstile> x \<leftrightarrow>* y \<equiv> (x, y) \<in> tgs_connected s"

text \<open>
  先把七条构造子的两条投影写成 simp 规则。真实文件里
  @{verbatim "target"} 那条顶着早期版本遗留下来的名字，比如
  @{verbatim "heapAdd_read_cap"}
  （@{verbatim "l4v/spec/take-grant/System_S.thy"} 第 419 行起，
  七条一路排到第 467 行）。
\<close>

lemma heapAdd_read_cap [simp]: "target (read_cap e) = e" by (simp add: read_cap_def)
lemma rights_read_cap [simp]: "rights (read_cap e) = {Read}" by (simp add: read_cap_def)
lemma heapAdd_write_cap [simp]: "target (write_cap e) = e" by (simp add: write_cap_def)
lemma rights_write_cap [simp]: "rights (write_cap e) = {Write}" by (simp add: write_cap_def)
lemma heapAdd_take_cap [simp]: "target (take_cap e) = e" by (simp add: take_cap_def)
lemma rights_take_cap [simp]: "rights (take_cap e) = {Take}" by (simp add: take_cap_def)
lemma heapAdd_grant_cap [simp]: "target (grant_cap e) = e" by (simp add: grant_cap_def)
lemma rights_grant_cap [simp]: "rights (grant_cap e) = {Grant}" by (simp add: grant_cap_def)
lemma heapAdd_create_cap [simp]: "target (create_cap e) = e" by (simp add: create_cap_def)
lemma rights_create_cap [simp]: "rights (create_cap e) = {Create}" by (simp add: create_cap_def)
lemma heapAdd_store_cap [simp]: "target (store_cap e) = e" by (simp add: store_cap_def)
lemma rights_store_cap [simp]: "rights (store_cap e) = {Store}" by (simp add: store_cap_def)
lemma heapAdd_full_cap [simp]: "target (full_cap e) = e" by (simp add: full_cap_def)
lemma rights_full_cap [simp]: "rights (full_cap e) = all_rights" by (simp add: full_cap_def)

lemma entity_diminish [simp]: "target (diminish R c) = target c"
  by (simp add: diminish_def)

lemma rights_diminish [simp]: "rights (diminish R c) = rights c \<inter> R"
  by (simp add: diminish_def)

text \<open>
  连通关系本身没有技术难度，它是闭包：自反、传递，并且因为
  @{verbatim "directly_tgs_connected"} 取的是 @{verbatim "leak"} 与其反向之并，
  它也对称。三条规则在真实文件里第一条是
  @{verbatim "tgs_connected_refl"}
  （@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 255 行），
  另外两条 @{verbatim "tgs_connected_comm"} 与 @{verbatim "tgs_connected_trans"}
  在 259 和 272 行；最后一条只是把 @{verbatim "rtrancl_trans"} 实例化到
  @{verbatim "directly_tgs_connected s"} 上，连证明都没有，写成一条
  @{verbatim "lemmas"} 声明。
\<close>

lemma directly_tgs_connected_def2:
  "(e\<^sub>x, e\<^sub>y) \<in> directly_tgs_connected s =
     (leak s e\<^sub>x e\<^sub>y \<or> leak s e\<^sub>y e\<^sub>x)"
  by (simp add: directly_tgs_connected_def)

lemma shares_caps_sym [simp]: "shares_caps s y x = shares_caps s x y"
  by (auto simp: shares_caps_def)

lemma directly_tgs_connected_def4:
  "s \<turnstile> e\<^sub>x \<leftrightarrow> e\<^sub>y =
     (take_cap e\<^sub>x \<in>cap caps_of s e\<^sub>y \<or> take_cap e\<^sub>y \<in>cap caps_of s e\<^sub>x \<or>
      grant_cap e\<^sub>y \<in>cap caps_of s e\<^sub>x \<or> grant_cap e\<^sub>x \<in>cap caps_of s e\<^sub>y \<or>
      shares_caps s e\<^sub>x e\<^sub>y)"
  by (auto simp: directly_tgs_connected_def leak_def)

lemma directly_tgs_connected_comm:
  "s \<turnstile> x \<leftrightarrow> y \<Longrightarrow> s \<turnstile> y \<leftrightarrow> x"
  by (auto simp: directly_tgs_connected_def)

lemma tgs_connected_refl [simp]: "s \<turnstile> x \<leftrightarrow>* x"
  by (simp add: tgs_connected_def)

lemma tgs_connected_comm:
  "s \<turnstile> x \<leftrightarrow>* y \<Longrightarrow> s \<turnstile> y \<leftrightarrow>* x"
  apply (simp add: tgs_connected_def)
  apply (erule rtrancl_induct, simp)
  apply (case_tac "s \<turnstile> z \<leftrightarrow> y")
   apply (simp add: directly_tgs_connected_comm)
  apply (simp add: directly_tgs_connected_comm)
  done

lemma tgs_connected_comm_eq: "s \<turnstile> x \<leftrightarrow>* y = s \<turnstile> y \<leftrightarrow>* x"
  by (metis tgs_connected_comm)

lemma tgs_connected_trans:
  "\<lbrakk>s \<turnstile> x \<leftrightarrow>* y; s \<turnstile> y \<leftrightarrow>* z\<rbrakk> \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* z"
  unfolding tgs_connected_def by (rule rtrancl_trans)

lemma directly_tgs_connected_rtrancl_into_rtrancl:
  "\<lbrakk>s \<turnstile> x \<leftrightarrow>* y; s \<turnstile> y \<leftrightarrow> z\<rbrakk> \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* z"
  unfolding tgs_connected_def by (rule rtrancl_into_rtrancl)

text \<open>
  四条"有能力就有边"。它们是 @{verbatim "leak"} 的三段在能力上的直接投影，
  全部一行 @{verbatim "auto"} 就完事，但整个 24.7 都在用它们：
\<close>

lemma take_caps_directly_tgs_connected:
  "\<lbrakk>c \<in> caps_of s e; Take \<in> rights c\<rbrakk> \<Longrightarrow> s \<turnstile> e \<leftrightarrow> target c"
  by (auto simp: directly_tgs_connected_def leak_def take_cap_def cap_in_caps_def
                 extra_rights_def all_rights_def)

lemma grant_caps_directly_tgs_connected:
  "\<lbrakk>c \<in> caps_of s e; Grant \<in> rights c\<rbrakk> \<Longrightarrow> s \<turnstile> e \<leftrightarrow> target c"
  by (auto simp: directly_tgs_connected_def leak_def grant_cap_def cap_in_caps_def
                 extra_rights_def all_rights_def)

lemma create_caps_directly_tgs_connected:
  "\<lbrakk>c \<in> caps_of s e; Create \<in> rights c\<rbrakk> \<Longrightarrow> s \<turnstile> e \<leftrightarrow> target c"
  by (auto simp: directly_tgs_connected_def leak_def cap_in_caps_def
                 rights_extra_rights all_rights_def)

lemma store_connected_directly_tgs_connected:
  "(x, y) \<in> store_connected s \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  by (auto simp: directly_tgs_connected_def leak_def shares_caps_def store_connected_def)

text \<open>
  第四条值得停一下：@{verbatim "store_connected"} 是闭包，
  一条边都不需要新造——因为 @{verbatim "shares_caps"} 要求的是
  "两条 store 链汇到同一点"，而闭包自带自反性，
  取 @{verbatim "e\<^sub>i := y"} 就够了。真实文件的证明正是这一行
  @{verbatim "auto"}（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 290 行）。
\<close>

text \<open>
  现在把 24.3 那个系统的边全算出来。先说结论：三条边各代表一类，
  而 @{verbatim "Read, Write"} 那条什么都不产生——它既不在
  @{verbatim "leak"} 的三段里，也不是 @{verbatim "Store"} 边，
  于是实体 4 成了一座单人孤岛。
\<close>

lemma sample_direct_exhaust [simp]:
  "(a, b) \<in> directly_tgs_connected sample_state \<longleftrightarrow>
     (a = b \<or> (a \<in> {0, 1, 2} \<and> b \<in> {0, 1, 2})
      \<or> (a \<in> {3, 5} \<and> b \<in> {3, 5}))"
  by (auto simp: directly_tgs_connected_def leak_def shares_caps_def
                 cap_in_caps_def all_rights_def sc_sample extra_rights_no_create
                 split: if_splits)

text \<open>
  这里有一处\emph{算出来才发现}的反直觉：0 与 2 之间并没有
  @{verbatim "store_connected"} 的路（24.3 的
  @{verbatim "scd_sample_1_2"} 已经算过），可它们在
  @{verbatim "directly_tgs_connected"} 里就是\emph{直接}相连的。
  原因是 @{verbatim "leak"} 看的是 @{verbatim "caps_of"}，
  而 @{verbatim "caps_of"} 已经把 store 闭包 reachable 到的能力全并了进来：
  实体 0 通过那条 @{verbatim "Store"} 能力"看得见" @{verbatim "cB"}，
  于是 @{verbatim "take_cap 2 \<in>cap caps_of sample_state 0"} 成立。
  换句话说，@{verbatim "leak"} 三段里的前两段已经把 store 边吃掉了一次，
   @{verbatim "shares_caps"} 只是补上"同一个槽位"这一种。

  在这个系统里 @{verbatim "tgs_connected"} 恰好等于
  @{verbatim "directly_tgs_connected"}——不是普遍现象，是这三块
  都已经是等价类的缘故。
\<close>

lemma sample_tgs_exhaust [simp]:
  "(a, b) \<in> tgs_connected sample_state \<longleftrightarrow>
     (a = b \<or> (a \<in> {0, 1, 2} \<and> b \<in> {0, 1, 2})
      \<or> (a \<in> {3, 5} \<and> b \<in> {3, 5}))"
proof
  assume ab: "(a, b) \<in> tgs_connected sample_state"
  then show "a = b \<or> (a \<in> {0, 1, 2} \<and> b \<in> {0, 1, 2})
              \<or> (a \<in> {3, 5} \<and> b \<in> {3, 5})"
    apply (unfold tgs_connected_def)
    apply (erule rtrancl_induct)
     apply simp
    apply auto
    done
next
  assume "a = b \<or> (a \<in> {0, 1, 2} \<and> b \<in> {0, 1, 2})
           \<or> (a \<in> {3, 5} \<and> b \<in> {3, 5})"
  then show "(a, b) \<in> tgs_connected sample_state"
    by (auto simp: tgs_connected_def intro: rtrancl_into_rtrancl)
qed

lemma sample_tgs_eq_direct:
  "tgs_connected sample_state = directly_tgs_connected sample_state"
  apply (rule set_eqI)
  apply (case_tac x)
  by simp

text \<open>
  四条边各对应 24.3 埋下的四类关系，逐条点出来：
\<close>

lemma sample_tgs_store: "sample_state \<turnstile> 0 \<leftrightarrow> 1" by simp
lemma sample_tgs_take: "sample_state \<turnstile> 1 \<leftrightarrow> 2" by simp
lemma sample_tgs_create: "sample_state \<turnstile> 3 \<leftrightarrow> 5" by simp
lemma sample_tgs_data: "\<not> (sample_state \<turnstile> 4 \<leftrightarrow> 3)" by simp

text \<open>
  跨孤岛的两条要留神：0 与 3、2 与 5 之间连闭包之后也不通。
  这两条是本章最终结论的雏形，证明靠的是"孤岛不出门"——
  对闭包归纳，@{verbatim "simp"} 自己走不动。
\<close>

lemma sample_not_tgs_0_3: "\<not> ((0, 3) \<in> tgs_connected sample_state)" by simp
lemma sample_not_tgs_2_5: "\<not> ((2, 5) \<in> tgs_connected sample_state)" by simp

lemma sample_tgs_4 [simp]: "(4, z) \<in> tgs_connected sample_state \<longleftrightarrow> z = 4"
  by simp

text \<open>
  @{verbatim "sample_tgs_4"} 说的是"4 谁都不挨着"，
  24.8 会把它直接读成 @{verbatim "island sample_state 4 = {4}"}。
  而 0 那一块\emph{包含}那个不存在的 5 吗？不包含——
  5 只跟 3 连在一起。这一点很重要：悬空的
  @{verbatim "Create"} 能力制造的是"3 与 5 连通"这条边，
  它把不存在的东西拉进了 3 的孤岛，却拉不动 0 那边。
\<close>

lemma sample_not_tgs_0_5: "\<not> ((0, 5) \<in> tgs_connected sample_state)" by simp
lemma sample_tgs_3_5_star: "sample_state \<turnstile> 3 \<leftrightarrow>* 5" by simp
lemma sample_tgs_0_2_star: "sample_state \<turnstile> 0 \<leftrightarrow>* 2" by simp

subsection \<open>24.7 单步不产生新连接：generalOperation 与它的核心引理\<close>

text \<open>
  到现在为止，"连通"只是一个算得出来的关系。本节要证的是本章真正的定理：

  \begin{quote}
  \emph{一次合法的系统调用不会在两个原本不通的实体之间造出新连接。}
  \end{quote}

  真实规范把这件事拆成两层。第一层是抽象：四个构造性操作
  （@{verbatim "create"}、@{verbatim "take"}、@{verbatim "grant"}、
  @{verbatim "copy"}）其实是同一个模板的四次实例化，
  模板叫 @{verbatim "generalOperation"}
  （@{verbatim "generalOperation"} 本身在
  @{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 127 行）。
  第二层才是归纳：模板改状态只动一个实体，
  于是新的 @{verbatim "store_connected"} 边只能"长"在已经连通的两点之间。
\<close>

definition generalOperation ::
  "entity_id \<Rightarrow> entity_id \<Rightarrow> cap \<Rightarrow> right set \<Rightarrow> modify_state" where
  "generalOperation e\<^sub>0 e\<^sub>1 c r s \<equiv>
     s (e\<^sub>1 \<mapsto> Entity (insert (diminish r (extra_rights c)) (direct_caps_of s e\<^sub>1)))"

text \<open>
  第一条性质就要用 @{verbatim "is_entity"}：模板只往 @{verbatim "e\<^sub>1"}
  那一格写东西，所以别处的 @{verbatim "is_entity"} 不变
  （@{verbatim "Confine_S.thy"} 第 132 行，带 @{verbatim "[simp]"}）。
  这条 @{verbatim "[simp]"} 不是装饰：@{verbatim "SysCreate"}
  摊成 @{verbatim "make_entity \<circ> generalOperation"} 之后，
  简化器必须知道"新实体 @{verbatim "target c\<^sub>2"} 在
  @{verbatim "generalOperation"} 那一步还不存在"，
  否则 @{verbatim "create_general"} 的侧条件就化不掉。
\<close>

lemma is_entity_general [simp]:
  "is_entity s e\<^sub>1 \<Longrightarrow> is_entity (generalOperation e\<^sub>0 e\<^sub>1 c r s) e' = is_entity s e'"
  by (simp add: is_entity_def generalOperation_def)

definition make_entity :: "entity_id \<Rightarrow> modify_state" where
  "make_entity n s \<equiv> s (n \<mapsto> null_entity)"

text \<open>
  真实文件在 @{verbatim "generalOperation"} 上面留了一行注释：
  @{verbatim "(* Note: e\<^sub>0 is unused. *)"}。第一个参数确实不出现在
  状态里——它只出现在引理的@{verbatim "前提"}里：
  "被搬运的那条能力 @{verbatim "c"} 属于 @{verbatim "e\<^sub>0"}，
  而 @{verbatim "e\<^sub>0"} 与 @{verbatim "e\<^sub>1"} 已经连通"。
  这一对前提就是"权威不外流"的凭据，也是 24.7 全部引理的形状。

  先把后面反复要用的四条小引理摆出来。前两条是
  @{verbatim "all_rights"} 与 @{verbatim "diminish"} 的配合：
  @{verbatim "Int_all_rights"}（@{verbatim "l4v/spec/take-grant/System_S.thy"} 第 336 行）
  与 @{verbatim "no_diminish"}（同一文件的 380 行）。
  后两条说的是"带 @{verbatim "Store"} 的能力就是 @{verbatim "store_connected"}
  的边"：@{verbatim "store_caps_of_store_connected_direct"}（529 行）与
  全文件最后一条 @{verbatim "store_caps_store_connected"}（534 行）。
\<close>

lemma Int_all_rights [simp]: "c \<inter> all_rights = c"
  by (simp add: all_rights_def)

lemma no_diminish [simp]: "diminish all_rights c = c"
  by (simp add: diminish_def)

lemma store_caps_of_store_connected_direct:
  "\<lbrakk>c \<in> direct_caps_of s e; Store \<in> rights c\<rbrakk>
   \<Longrightarrow> (e, target c) \<in> store_connected_direct s"
  by (fastforce simp: store_connected_direct_def)

lemma store_caps_store_connected:
  "\<lbrakk>c \<in> caps_of s e; Store \<in> rights c\<rbrakk> \<Longrightarrow> (e, target c) \<in> store_connected s"
  apply (clarsimp simp: store_connected_def caps_of_def)
  by (frule (1) store_caps_of_store_connected_direct, simp)

text \<open>
  @{verbatim "diminish"} 打掉的 rights 可能把 @{verbatim "Create"}
  打掉，从而让 @{verbatim "extra_rights"} 不再摊平——所以
  "先摊平后的权利"只会变小。这条方向性极强的弱引理就是 @{verbatim "direct_caps_of_generalOp2"}
  （@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 329 行）的唯一非平凡处：
\<close>

lemma extra_rights_diminish:
  "x \<in> rights (extra_rights (diminish r c)) \<Longrightarrow> x \<in> rights (extra_rights c)"
  by (auto simp: rights_extra_rights all_rights_def split: if_split_asm)

text \<open>
  四个操作对模板的实例化。@{verbatim "take"} 与
  @{verbatim "grant"}/@{verbatim "copy"} 的差别只有写在哪个实体上：
  @{verbatim "take"} 写 @{verbatim "e"}，后两者写
  @{verbatim "target c\<^sub>1"}，这正是 24.4 里那三条定义的样子。
\<close>

lemma take_general:
  "takeOperation e c\<^sub>1 c\<^sub>2 r s = generalOperation (target c\<^sub>1) e c\<^sub>2 (r \<inter> rights c\<^sub>2) s"
  by (simp add: takeOperation_def generalOperation_def)

lemma grant_general:
  "grantOperation e c\<^sub>1 c\<^sub>2 r s = generalOperation e (target c\<^sub>1) c\<^sub>2 (r \<inter> rights c\<^sub>2) s"
  by (simp add: grantOperation_def generalOperation_def)

lemma copy_general:
  "copyOperation e c\<^sub>1 c\<^sub>2 r s = generalOperation e (target c\<^sub>1) c\<^sub>2 (r \<inter> rights c\<^sub>2) s"
  by (simp add: copyOperation_def generalOperation_def)

lemma create_general_alt:
  "createOperation e c\<^sub>1 c\<^sub>2 s =
     make_entity (target c\<^sub>2)
       (generalOperation e (target c\<^sub>1) (full_cap (target c\<^sub>2)) all_rights s)"
  by (simp add: createOperation_def generalOperation_def make_entity_def null_entity_def)

text \<open>
  @{verbatim "create"} 还有一步：新对象那条能力本来就是
  @{verbatim "full_cap"}，带着 @{verbatim "Create"}，
  所以 @{verbatim "extra_rights"} 一摊平它就是全权，
  于是 @{verbatim "c\<^sub>2"} 可以直接顶替 @{verbatim "full_cap (target c\<^sub>2)"}。
  这一步要条件 @{verbatim "Create \<in> rights c\<^sub>2"}，
  而它恰好是 @{verbatim "legal (SysCreate e c\<^sub>1 c\<^sub>2) s"} 的一条合取项。
\<close>

lemma create_general_helper:
  "Create \<in> rights c\<^sub>2 \<Longrightarrow>
     \<lparr>target = target c\<^sub>2, rights = UNIV\<rparr> = c\<^sub>2\<lparr>rights := UNIV\<rparr>"
  by auto

lemma create_general:
  "Create \<in> rights c\<^sub>2 \<Longrightarrow>
     createOperation e c\<^sub>1 c\<^sub>2 s =
       make_entity (target c\<^sub>2) (generalOperation e (target c\<^sub>1) c\<^sub>2 all_rights s)"
  by (simp add: createOperation_def generalOperation_def make_entity_def full_cap_def
                all_rights_def diminish_def extra_rights_def null_entity_def
                create_general_helper)

text \<open>
  模板对状态的影响可以一行写完：只有 @{verbatim "e\<^sub>1"} 那格多了一条能力，
  别的一律照旧。
\<close>

lemma direct_caps_of_generalOp:
  "direct_caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) e =
     (if e = e\<^sub>1
      then insert (diminish r (extra_rights c)) (direct_caps_of s e\<^sub>1)
      else direct_caps_of s e)"
  by (clarsimp simp: generalOperation_def direct_caps_of_def is_entity_def
                     split: option.splits if_splits)

text \<open>
  @{verbatim "make_entity"} 与 @{verbatim "generalOperation"} 正好相反：
  它把 @{verbatim "n"} 抹成 @{verbatim "null_entity"}，别处一概不动。
  于是"是不是实体"这件事只能变大不能变小—— @{verbatim "n"}
  即便原来不存在，现在也存在了（这是个算错才看清的点：
  第一版把结论写成了 @{verbatim "e \<noteq> n \<and> is_entity s e"}，
  @{verbatim "e = n"} 那一支立刻崩，因为 @{verbatim "null_entity"} 也是实体。

  能力方面真实文件给的 @{verbatim "direct_caps_of_make_entity"}（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 169 行）
  是带假设的等式：先假设 @{verbatim "n"} 还不是实体，
  那么 @{verbatim "make_entity"} 之后每个实体的直接能力集都不变。
  假设是必需的——若 @{verbatim "n"} 本来带着能力，这里会把它们清空。
  不带假设时只剩包含关系：
\<close>

lemma is_entity_make_entity:
  "is_entity (make_entity n s) e = (e = n \<or> is_entity s e)"
  by (auto simp: make_entity_def null_entity_def is_entity_def direct_caps_of_def
          split: option.splits)

lemma direct_caps_of_make_entity:
  "\<not> is_entity s n \<Longrightarrow> direct_caps_of (make_entity n s) e = direct_caps_of s e"
  by (simp add: direct_caps_of_def make_entity_def is_entity_def null_entity_def)

lemma direct_caps_of_make_entity_subset:
  "direct_caps_of (make_entity n s) e \<subseteq> direct_caps_of s e"
  by (auto simp: make_entity_def null_entity_def direct_caps_of_def is_entity_def
          split: option.splits)

text \<open>
  要把" @{verbatim "make_entity"} 无害"往上推到 @{verbatim "caps_of"}
  和 @{verbatim "leak"}，真实文件用的是四条一行长的等式传递，第一条是
  @{verbatim "direct_caps_of_store_connected_eq"}（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 141 行），
  另外三条在 147、152、158 行。
  口径只有一句：@{verbatim "direct_caps_of"} 逐点相等的两个状态，
  连通关系、@{verbatim "caps_of"}、@{verbatim "leak"} 也逐点相等。
  这就是本章反复使用的"降一层"手段——
  所有关于状态的命题最后都折算到 @{verbatim "direct_caps_of"} 这一个函数上。
\<close>

lemma direct_caps_of_store_connected_eq:
  "\<forall>e. direct_caps_of s e = direct_caps_of s' e
     \<Longrightarrow> store_connected s = store_connected s'"
  by (simp add: store_connected_def store_connected_direct_def direct_caps_of_def)

lemma direct_caps_of_caps_of_eq:
  "\<forall>e. direct_caps_of s e = direct_caps_of s' e \<Longrightarrow> caps_of s e = caps_of s' e"
  by (simp add: caps_of_def store_connected_def store_connected_direct_def
                direct_caps_of_def)

lemma direct_caps_of_caps_of_eq2:
  "\<lbrakk>\<forall>e. direct_caps_of s e = direct_caps_of s' e; c \<in>cap caps_of s e\<rbrakk>
   \<Longrightarrow> c \<in>cap caps_of s' e"
  apply (drule direct_caps_of_caps_of_eq)
  by (auto simp: cap_in_caps_def)

lemma direct_caps_of_directly_tgs_connected_eq:
  assumes H: "\<forall>e. direct_caps_of s e = direct_caps_of s' e"
  shows "s \<turnstile> x \<leftrightarrow> y = s' \<turnstile> x \<leftrightarrow> y"
  using H
  apply (simp add: directly_tgs_connected_def4 shares_caps_def)
  apply rule
   apply (erule disjE, drule (1) direct_caps_of_caps_of_eq2, clarsimp)+
   apply (drule direct_caps_of_store_connected_eq, clarsimp)
  apply (erule disjE, drule direct_caps_of_caps_of_eq2 [rotated, where s=s' and s'=s], simp+)+
  apply (drule direct_caps_of_store_connected_eq, simp)
  done

text \<open>
  四条 @{verbatim "make_entity"} 的推论，真实文件按"等式版 +
  @{verbatim "drule"} 一句搞定"的\emph{惯例}成对写：
  先给一条双向等式（@{verbatim "caps_of_make_entity"}，@{verbatim "Confine_S.thy"} 第 173 行），
  再给一条只往一个方向用的 @{verbatim "..._2"}；这样成对的四条一直排到 193 行。
  后面 @{verbatim "caps_of_create"}、@{verbatim "create_directly_tgs_connected"}
  用的正是这两条 @{verbatim "..._2"}。
\<close>

lemma caps_of_make_entity:
  "\<not> is_entity s n \<Longrightarrow> caps_of (make_entity n s) e = caps_of s e"
  apply (rule direct_caps_of_caps_of_eq)
  apply clarsimp
  apply (erule direct_caps_of_make_entity)
  done

lemma caps_of_make_entity2:
  "\<lbrakk>\<not> is_entity s n; c \<in> caps_of (make_entity n s) e\<rbrakk> \<Longrightarrow> c \<in> caps_of s e"
  apply (drule caps_of_make_entity)
  apply fastforce
  done

lemma directly_tgs_connected_make_entity:
  "\<not> is_entity s n \<Longrightarrow> make_entity n s \<turnstile> x \<leftrightarrow> y = s \<turnstile> x \<leftrightarrow> y"
  apply (rule direct_caps_of_directly_tgs_connected_eq)
  apply clarsimp
  apply (drule (1) direct_caps_of_make_entity)
  done

lemma directly_tgs_connected_make_entity2:
  "\<lbrakk>\<not> is_entity s n; make_entity n s \<turnstile> x \<leftrightarrow> y\<rbrakk> \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  apply (drule directly_tgs_connected_make_entity)
  apply fastforce
  done

text \<open>
  下一步是本章最要紧的一条 @{verbatim "rule_format"} 引理的形状：
  模板往 @{verbatim "e\<^sub>1"} 里塞的那条能力，
  要么本来就在 @{verbatim "s"} 里，要么就是 @{verbatim "c"} 本身
  （可能打了掩码）且落在 @{verbatim "e\<^sub>1"}。
\<close>

lemma direct_caps_of_generalOp2:
  "\<lbrakk>c' \<in> direct_caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) x\<rbrakk>
   \<Longrightarrow> c' \<in> direct_caps_of s x \<or> (c' \<in>cap {c} \<and> x = e\<^sub>1)"
  apply (clarsimp simp: direct_caps_of_generalOp extra_rights_diminish
                        split: if_split_asm)
  apply (drule extra_rights_diminish)
  by simp

text \<open>
  于是 @{verbatim "store_connected_direct"} 的边只可能多出一条，
  而且这条边一定是 @{verbatim "(e\<^sub>1, target c)"}：
\<close>

lemma store_connected_direct_generalOp:
  "\<lbrakk>(x, y) \<in> store_connected_direct (generalOperation e\<^sub>0 e\<^sub>1 c r s)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> store_connected_direct s \<or>
          (x = e\<^sub>1 \<and> y = target c \<and> Store \<in> rights (extra_rights c))"
  by (auto simp: store_connected_direct_def direct_caps_of_generalOp all_rights_def
          split: if_split_asm)

text \<open>
  闭包怎么办？这里必须归纳——@{verbatim "store_connected"} 是
  @{verbatim "rtrancl"}，@{verbatim "simp"} 推不动。
  结论的形状很典型：原来 @{verbatim "s"} 里的路径 @{verbatim "x \<to> y"}
  在新状态里要么照旧，要么"经过那条新边一次"，
  即 @{verbatim "x"} 先在 @{verbatim "s"} 里连到 @{verbatim "e\<^sub>1"}，
  跨过新边 @{verbatim "e\<^sub>1 \<to> target c"}，再在 @{verbatim "s"} 里连到 @{verbatim "y"}。
  真实文件这一段（@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 344 行）
  用的是 @{verbatim "subgoal_tac"} 加一个 @{verbatim "notE"}，
  意思就是"这条新边不可能重复出现，删掉它剩下的还在 @{verbatim "s"} 里"。
\<close>

lemma store_connected_generalOp:
  "\<lbrakk>(x, y) \<in> store_connected (generalOperation e\<^sub>0 e\<^sub>1 c r s)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> store_connected s \<or>
          ((x, e\<^sub>1) \<in> store_connected s \<and>
           (e\<^sub>1, target c) \<in> store_connected_direct (generalOperation e\<^sub>0 e\<^sub>1 c r s) \<and>
           (target c, y) \<in> store_connected s)"
  apply (unfold store_connected_def)
  apply (erule rtrancl_induct)
   apply clarsimp
  apply clarsimp
  apply (fold store_connected_def)
  apply (subgoal_tac "(y, z) \<in> store_connected_direct s")
   apply (clarsimp simp: store_connected_def)
   apply (erule disjE)
    apply fastforce
   apply clarsimp
   apply (erule notE)
   apply fastforce
  apply (frule store_connected_direct_generalOp)
  apply (clarsimp simp: store_connected_def)
  done

text \<open>
  那条新边还有个性质：如果它确实是@{verbatim "新"}的
  （@{verbatim "s"} 里没有），那么 @{verbatim "c"} 必属于
  @{verbatim "e\<^sub>0"}、且 @{verbatim "e\<^sub>0"} 与 @{verbatim "target c"}
  之间本来就通，或者 @{verbatim "c"} 带 @{verbatim "Create"}。
  这句话看着绕，用处却很大：它把"新边"重新翻译回"旧连通"，
  正是 @{verbatim "generalOperation"} 的 @{verbatim "e\<^sub>0"}
  那个"只用在前件里"的参数唯一发挥作用的地方。
\<close>

lemma store_connected_generalOp_not_new:
  "\<lbrakk>(e\<^sub>1, target c) \<in> store_connected_direct (generalOperation e\<^sub>0 e\<^sub>1 c r s);
     c \<in> caps_of s e\<^sub>0\<rbrakk>
   \<Longrightarrow> (e\<^sub>1, target c) \<in> store_connected_direct s \<or>
          (e\<^sub>0, target c) \<in> store_connected s \<or> Create \<in> rights c"
  apply (drule store_connected_direct_generalOp)
  apply (clarsimp simp: rights_extra_rights split: if_split_asm)
  apply (drule (1) store_caps_store_connected, simp)
  done

text \<open>
  把上面三条合起来，就得到本节的心脏引理的前半：
  模板之后的任意一条 @{verbatim "store_connected"} 路径，
  在模板之前都已经是 @{verbatim "tgs_connected"} 的。
  前提 @{verbatim "c \<in> caps_of s e\<^sub>0"} 与
  @{verbatim "s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1"} 正是"这次搬运合法"的形状。
\<close>

lemma store_connected_generalOp2:
  "\<lbrakk>(x, y) \<in> store_connected (generalOperation e\<^sub>0 e\<^sub>1 c r s);
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (drule store_connected_generalOp)
  apply (erule disjE)
   apply (simp add: tgs_connected_def)
   apply (drule store_connected_directly_tgs_connected, simp)
  apply clarsimp
  apply (drule store_connected_directly_tgs_connected [where x=x and y=e\<^sub>1])
  apply (drule store_connected_directly_tgs_connected [where x="target c" and y=y])
  apply (drule (1) store_connected_generalOp_not_new)
  apply (erule disjE)
   apply (drule store_connected_direct_in_store_connected)
   apply (drule store_connected_directly_tgs_connected [where x=e\<^sub>1 and y="target c"])
   apply (simp add: tgs_connected_def)
  apply (drule directly_tgs_connected_comm [where x="e\<^sub>0" and y="e\<^sub>1"])
  apply (erule disjE)
   apply (drule store_connected_directly_tgs_connected [where x=e\<^sub>0 and y="target c"])
   apply (simp add: tgs_connected_def)
  apply (drule (1) create_caps_directly_tgs_connected)
  apply (simp add: tgs_connected_def)
  done

text \<open>
  有了它，@{verbatim "shares_caps"} 与 @{verbatim "caps_of"}
  两句都是顺水推舟：连通关系是等价关系
  （24.6 的 @{verbatim "tgs_connected_comm"}、
  @{verbatim "tgs_connected_trans"}），
  于是"@{verbatim "x"}、@{verbatim "y"} 都连到同一个 @{verbatim "e\<^sub>i"}"
  就变成"@{verbatim "x"} 连到 @{verbatim "y"}"。
\<close>

lemma shares_caps_of_generalOp:
  "\<lbrakk>shares_caps (generalOperation e\<^sub>0 e\<^sub>1 c r s) x y;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (clarsimp simp: shares_caps_def)
  apply (frule (2) store_connected_generalOp2 [where x=x])
  apply (drule (2) store_connected_generalOp2 [where x=y])
  apply (drule tgs_connected_comm [where x=y])
  apply (simp add: tgs_connected_def)
  done

lemma caps_of_generalOp:
  "\<lbrakk>c' \<in> caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) x;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> \<exists>z. (x, z) \<in> tgs_connected s \<and> c' \<in>cap caps_of s z"
  apply (simp add: caps_of_def [where e=x])
  apply clarsimp
  apply (frule (2) store_connected_generalOp2)
  apply (drule direct_caps_of_generalOp2)
  apply (erule disjE)
   apply (drule direct_cap_in_cap)
   apply (fastforce simp: cap_in_caps_def)
  apply (subgoal_tac "s \<turnstile> x \<leftrightarrow>* e\<^sub>0")
   apply (subgoal_tac "c' \<in>cap caps_of s e\<^sub>0")
    apply fastforce
   apply (fastforce simp: cap_in_caps_def)
  apply clarsimp
  apply (drule directly_tgs_connected_comm [where x="e\<^sub>0" and y="e\<^sub>1"])
  apply (simp add: tgs_connected_def)
  done

text \<open>
  最后一步：@{verbatim "leak"} 的三段一段一段处理。
  @{verbatim "take_cap"}、@{verbatim "grant_cap"} 两段靠
  @{verbatim "caps_of_generalOp"}，@{verbatim "shares_caps"} 那段靠
  @{verbatim "shares_caps_of_generalOp"}；
  @{verbatim "tgs_connected_comm"} 用来把方向掰回来
  （@{verbatim "leak"} 的两段方向是反的，24.6 已经提醒过一次）。
\<close>

lemma take_cap_generalOp:
  "\<lbrakk>take_cap y \<in>cap caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) x;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> \<exists>z. s \<turnstile> x \<leftrightarrow>* z \<and> take_cap y \<in>cap caps_of s z"
  apply (simp add: cap_in_caps_def)
  apply clarsimp
  apply (drule (2) caps_of_generalOp)
  apply (fastforce simp: cap_in_caps_def)
  done

lemma grant_cap_generalOp:
  "\<lbrakk>grant_cap y \<in>cap caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) x;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> \<exists>z. s \<turnstile> x \<leftrightarrow>* z \<and> grant_cap y \<in>cap caps_of s z"
  apply (simp add: cap_in_caps_def)
  apply clarsimp
  apply (drule (2) caps_of_generalOp)
  apply (fastforce simp: cap_in_caps_def)
  done

lemma take_cap_generalOp2:
  "\<lbrakk>take_cap y \<in>cap caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) x;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s"
  apply (drule (2) take_cap_generalOp)
  apply clarsimp
  apply (subgoal_tac "s \<turnstile> z \<leftrightarrow> y")
   apply (simp add: tgs_connected_def)
  apply (simp add: directly_tgs_connected_def leak_def)
  done

lemma grant_cap_generalOp2:
  "\<lbrakk>grant_cap y \<in>cap caps_of (generalOperation e\<^sub>0 e\<^sub>1 c r s) x;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s"
  apply (drule (2) grant_cap_generalOp)
  apply clarsimp
  apply (subgoal_tac "s \<turnstile> z \<leftrightarrow> y")
   apply (simp add: tgs_connected_def)
  apply (simp add: directly_tgs_connected_def leak_def)
  done

lemma generalOp_directly_tgs_connected:
  "\<lbrakk>generalOperation e\<^sub>0 e\<^sub>1 c r s \<turnstile> x \<leftrightarrow> y;
     c \<in> caps_of s e\<^sub>0; s \<turnstile> e\<^sub>0 \<leftrightarrow> e\<^sub>1\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (simp add: directly_tgs_connected_def [where s="generalOperation e\<^sub>0 e\<^sub>1 c r s"]
                   leak_def)
  apply safe
       apply (rule tgs_connected_comm)
       apply (drule (3) take_cap_generalOp2)
      apply (drule (3) grant_cap_generalOp2)
     apply (erule (2) shares_caps_of_generalOp)
    apply (drule (3) take_cap_generalOp2)
   apply (rule tgs_connected_comm)
   apply (drule (3) grant_cap_generalOp2)
  apply (erule (2) shares_caps_of_generalOp)
  done

text \<open>
  有了模板这一套，四个建设性操作各自只剩两件事：
  把 @{verbatim "legal"} 的前提翻成"哪条能力在谁手里"，
  再把操作改写成 @{verbatim "generalOperation"}（@{verbatim "take_general"}
  那一组）。真实文件把这两件事分成两层写：
  先证\emph{前提即边}（@{verbatim "Confine_S.thy"} 第 495 到 522 行），
  再证\emph{结果受控}（第 524 到 559 行的 @{verbatim "caps_of_*"}、
  第 561 到 593 行的 @{verbatim "..._directly_tgs_connected"}、
  第 597 到 631 行的 @{verbatim "..._conTrans"}）。

  第一层里 @{verbatim "SysCreate"} 有点特别：它要的是
  @{verbatim "c\<^sub>1"} 那条带 @{verbatim "Store"} 的能力，
  于是走的不是 @{verbatim "take_caps_*"} 而是
  @{verbatim "store_caps_store_connected"} 加
  @{verbatim "store_connected_directly_tgs_connected"}
  （第 500、501 行）——先有 @{verbatim "store_connected"} 的链，
  再由 24.6 第四条引理折算成一条 tgs 边。
  另外真实文件在 @{verbatim "create_legal_directly_tgs_connected"}
  里还多写了一条 @{verbatim "drule (1) create_caps_directly_tgs_connected"}，
  那条在这里其实用不上（目标只靠 @{verbatim "c\<^sub>1"} 就够），
  本章按精简后的版本写。
\<close>

lemma create_legal_directly_tgs_connected:
  "legal (SysCreate e c\<^sub>1 c\<^sub>2) s \<Longrightarrow> s \<turnstile> target c\<^sub>1 \<leftrightarrow> e"
  apply clarsimp
  apply (rule directly_tgs_connected_comm)
  apply (drule (1) store_caps_store_connected)
  apply (drule (1) store_connected_directly_tgs_connected)
  done

lemma take_legal_directly_tgs_connected:
  "legal (SysTake e c\<^sub>1 c\<^sub>2 r) s \<Longrightarrow> s \<turnstile> target c\<^sub>1 \<leftrightarrow> e"
  apply clarsimp
  apply (rule directly_tgs_connected_comm)
  apply (drule (2) take_caps_directly_tgs_connected)
  done

lemma grant_legal_directly_tgs_connected:
  "legal (SysGrant e c\<^sub>1 c\<^sub>2 r) s \<Longrightarrow> s \<turnstile> e \<leftrightarrow> target c\<^sub>1"
  apply clarsimp
  apply (drule (2) grant_caps_directly_tgs_connected)
  done

lemma copy_legal_directly_tgs_connected:
  "legal (SysCopy e c\<^sub>1 c\<^sub>2 r) s \<Longrightarrow> s \<turnstile> e \<leftrightarrow> target c\<^sub>1"
  apply clarsimp
  apply (drule (1) store_caps_store_connected)
  apply (drule (1) store_connected_directly_tgs_connected)
  done

text \<open>
  第二层的第一组：一次合法操作之后，任何实体能摸到的能力
  @{verbatim "c'"}，必然在\emph{旧}状态里某座已连通的实体手里
  ——@{verbatim "\<exists>z. (x, z) \<in> tgs_connected s \<and> c' \<in>cap caps_of s z"}。
  这里的 @{verbatim "z"} 就是"权威的老东家"，
  四条证明全是同一个三段：先取前提给的边，
  再把操作摊成 @{verbatim "generalOperation"}，最后一条
  @{verbatim "caps_of_generalOp"}。@{verbatim "SysCreate"}
  多一道 @{verbatim "make_entity"}，所以要先过
  @{verbatim "caps_of_make_entity2"}。
\<close>

lemma caps_of_create:
  "\<lbrakk>c' \<in> caps_of (createOperation e c\<^sub>1 c\<^sub>2 s) x;
     legal (SysCreate e c\<^sub>1 c\<^sub>2) s\<rbrakk>
   \<Longrightarrow> \<exists>z. (x, z) \<in> tgs_connected s \<and> c' \<in>cap caps_of s z"
  apply (frule create_legal_directly_tgs_connected)
  apply (clarsimp simp: create_general)
  apply (drule caps_of_make_entity2 [rotated], clarsimp)
  apply (drule (1) caps_of_generalOp)
   apply (drule (2) directly_tgs_connected_comm)
  done

lemma caps_of_take:
  "\<lbrakk>c' \<in> caps_of (takeOperation e c\<^sub>1 c\<^sub>2 r s) x;
     legal (SysTake e c\<^sub>1 c\<^sub>2 r) s\<rbrakk>
   \<Longrightarrow> \<exists>z. (x, z) \<in> tgs_connected s \<and> c' \<in>cap caps_of s z"
  apply (frule take_legal_directly_tgs_connected)
  apply (clarsimp simp: take_general)
  apply (drule (2) caps_of_generalOp)
   apply (drule (1) directly_tgs_connected_comm)
  done

lemma caps_of_grant:
  "\<lbrakk>c' \<in> caps_of (grantOperation e c\<^sub>1 c\<^sub>2 r s) x;
     legal (SysGrant e c\<^sub>1 c\<^sub>2 r) s\<rbrakk>
   \<Longrightarrow> \<exists>z. (x, z) \<in> tgs_connected s \<and> c' \<in>cap caps_of s z"
  apply (frule grant_legal_directly_tgs_connected)
  apply (clarsimp simp: grant_general)
  apply (drule (2) caps_of_generalOp)
   apply (drule (1) directly_tgs_connected_comm)
  done

lemma caps_of_copy:
  "\<lbrakk>c' \<in> caps_of (copyOperation e c\<^sub>1 c\<^sub>2 r s) x;
     legal (SysCopy e c\<^sub>1 c\<^sub>2 r) s\<rbrakk>
   \<Longrightarrow> \<exists>z. (x, z) \<in> tgs_connected s \<and> c' \<in>cap caps_of s z"
  apply (frule copy_legal_directly_tgs_connected)
  apply (clarsimp simp: copy_general)
  apply (drule (2) caps_of_generalOp)
   apply (drule (1) directly_tgs_connected_comm)
  done

text \<open>
  第二层的第二组，也是本章标题那句"一步不造新连接"的原件：
  新状态里的一条\emph{直接}边，在旧状态里是\emph{传递}的连通。
  结论里出现 @{verbatim "\<leftrightarrow>*"} 而不是 @{verbatim "\<leftrightarrow>"}
  是必须的——@{verbatim "SysCreate"} 造出的那条边
  是通往一个\emph{新}实体的，旧状态里根本没有那个点，
  只有把它算进闭包才说得通。
\<close>

lemma create_directly_tgs_connected:
  "\<lbrakk>createOperation e c\<^sub>1 c\<^sub>2 s \<turnstile> x \<leftrightarrow> y;
     legal (SysCreate e c\<^sub>1 c\<^sub>2) s\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (frule create_legal_directly_tgs_connected)
  apply (clarsimp simp: create_general)
  apply (drule directly_tgs_connected_make_entity2 [rotated], clarsimp)
  apply (drule (1) generalOp_directly_tgs_connected)
   apply (drule (2) directly_tgs_connected_comm)
  done

lemma take_directly_tgs_connected:
  "\<lbrakk>takeOperation e c\<^sub>1 c\<^sub>2 r s \<turnstile> x \<leftrightarrow> y;
     legal (SysTake e c\<^sub>1 c\<^sub>2 r) s\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (frule take_legal_directly_tgs_connected)
  apply (clarsimp simp: take_general)
  apply (drule (3) generalOp_directly_tgs_connected)
  done

lemma grant_directly_tgs_connected:
  "\<lbrakk>grantOperation e c\<^sub>1 c\<^sub>2 r s \<turnstile> x \<leftrightarrow> y;
     legal (SysGrant e c\<^sub>1 c\<^sub>2 r) s\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (frule grant_legal_directly_tgs_connected)
  apply (clarsimp simp: grant_general)
  apply (drule (3) generalOp_directly_tgs_connected)
  done

lemma copy_directly_tgs_connected:
  "\<lbrakk>copyOperation e c\<^sub>1 c\<^sub>2 r s \<turnstile> x \<leftrightarrow> y;
     legal (SysCopy e c\<^sub>1 c\<^sub>2 r) s\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* y"
  apply (frule copy_legal_directly_tgs_connected)
  apply (clarsimp simp: copy_general)
  apply (drule (3) generalOp_directly_tgs_connected)
  done

text \<open>
  第三组把"操作"与 @{verbatim "step"} 接上：
  @{verbatim "cmd"} 恰好是这一族调用、@{verbatim "s'"} 是它的一步、
  而 @{verbatim "s'"} 里有一条直接边，则这条边在 @{verbatim "s"} 里传递地成立。
  真实文件四条 @{verbatim "..._conTrans"}（第 597、606、615、624 行）
  形状完全一样，只有 @{verbatim "step_def"} 摊开后的两个分支：
  非法或自环那支直接 @{verbatim "fastforce"}，
  真操作那支交给上一条引理。
\<close>

lemma create_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysCreate e c\<^sub>1 c\<^sub>2)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s"
  apply (clarsimp simp: step_def split: if_split_asm)
   apply (erule disjE, fastforce simp: tgs_connected_def, clarsimp)
   apply (drule create_directly_tgs_connected, clarsimp, assumption)
  apply (simp add: tgs_connected_def)
  done

lemma take_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysTake e c\<^sub>1 c\<^sub>2 r)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s"
  apply (clarsimp simp: step_def split: if_split_asm)
   apply (erule disjE, fastforce simp: tgs_connected_def, clarsimp)
   apply (drule take_directly_tgs_connected, clarsimp, assumption)
  apply (simp add: tgs_connected_def)
  done

lemma grant_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysGrant e c\<^sub>1 c\<^sub>2 r)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s"
  apply (clarsimp simp: step_def split: if_split_asm)
   apply (erule disjE, fastforce simp: tgs_connected_def, clarsimp)
   apply (drule grant_directly_tgs_connected, clarsimp, assumption)
  apply (simp add: tgs_connected_def)
  done

lemma copy_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysCopy e c\<^sub>1 c\<^sub>2 r)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s"
  apply (clarsimp simp: step_def split: if_split_asm)
   apply (erule disjE, fastforce simp: tgs_connected_def, clarsimp)
   apply (drule copy_directly_tgs_connected, clarsimp, assumption)
  apply (simp add: tgs_connected_def)
  done

text \<open>
  四个删除性操作走的是另一条路：它们只会\emph{减少}某个实体手里的能力，
  于是新状态里的每一条边都是旧状态里就有的。
  真实文件给每个操作各证了一遍这件事——
  @{verbatim "store_connected_destroy"}（第 639 行）、
  @{verbatim "store_connected_remove"}（第 709 行）、
  @{verbatim "store_connected_removeSetOfCaps"}（第 828 行）、
  @{verbatim "store_connected_revoke"}（第 871 行）。
  这四条的证明脚本几乎逐字相同：对 @{verbatim "rtrancl"} 归纳，
  再用 @{verbatim "subgoal_tac"} 把多出来的那条边塞回旧关系里。
  本章把重复的部分抽出来，做成一条单调性链：
  先只问"@{verbatim "direct_caps_of"} 有没有变少"，
  连通性、@{verbatim "caps_of"}、@{verbatim "leak"}、闭包层层跟着变小，
  四个操作各自只剩"证明自己的 @{verbatim "direct_caps_of"} 确实变少了"。
  这是本章相对真实文件\emph{唯一}的结构性改写，结论与它逐条一致，
  而且下面会看到：顺手还把真实文件的四条 @{verbatim "caps_of_*"} 也一并拿到了。
\<close>

text \<open>
  先摆四个操作各自的 @{verbatim "direct_caps_of"} 事实，
  这些都是真实文件里的原件
  （@{verbatim "l4v/spec/take-grant/Confine_S.thy"} 第 635、696、702、775、821、863 行）。
  @{verbatim "removeOperation"} 那一族的形状是"只有
  @{verbatim "target c\<^sub>1"} 那一格少了一条能力"，
  写成等式是 @{verbatim "direct_caps_of_remove_eq"}；
  本章前面几条只需要它的 element 版本。
\<close>

lemma direct_caps_of_destroy:
  "c \<in> direct_caps_of (s(e := None)) x \<Longrightarrow> c \<in> direct_caps_of s x"
  by (simp add: direct_caps_of_def split: option.splits if_split_asm)

lemma direct_caps_of_remove_eq:
  "direct_caps_of (removeOperation e c\<^sub>1 c\<^sub>2 s) x =
     (if is_entity s (target c\<^sub>1) \<and> x = target c\<^sub>1
      then direct_caps_of s (target c\<^sub>1) - {c\<^sub>2}
      else direct_caps_of s x)"
  by (simp add: direct_caps_of_def is_entity_def removeOperation_def)

lemma direct_caps_of_remove:
  "c \<in> direct_caps_of (removeOperation e c\<^sub>1 c\<^sub>2 s) x \<Longrightarrow> c \<in> direct_caps_of s x"
  by (clarsimp simp: direct_caps_of_remove_eq split: if_split_asm)

lemma direct_caps_of_removeSet_eq:
  "direct_caps_of (removeSetOperation e c C s) x =
     (if is_entity s (target c) \<and> x = target c
      then direct_caps_of s (target c) - C
      else direct_caps_of s x)"
  by (simp add: direct_caps_of_def is_entity_def removeSetOperation_def)

lemma direct_caps_of_removeSet:
  "c' \<in> direct_caps_of (removeSetOperation e c C s) x \<Longrightarrow> c' \<in> direct_caps_of s x"
  by (clarsimp simp: direct_caps_of_removeSet_eq split: if_split_asm)

lemma direct_caps_of_removeSetOfCaps:
  "c' \<in> direct_caps_of (removeSetOfCaps cap_map s) x \<Longrightarrow> c' \<in> direct_caps_of s x"
  by (clarsimp simp: removeSetOfCaps_def direct_caps_of_def split: option.splits if_split_asm)

lemma direct_caps_of_revoke:
  "\<lbrakk>s' \<in> revokeOperation e c s; c' \<in> direct_caps_of s' x\<rbrakk>
   \<Longrightarrow> c' \<in> direct_caps_of s x"
  apply (clarsimp simp: revokeOperation_def split: if_split_asm)
  by (drule (1) direct_caps_of_removeSetOfCaps)

text \<open>
  把上面六条折成单调性链要的@{verbatim "\<subseteq>"}形状。
  @{verbatim "SysRevoke"} 那一条保留 @{verbatim "s' \<in> revokeOperation e c s"}
  这个前提，因为回收是非确定的一族状态。
\<close>

lemma direct_caps_of_destroy_le:
  "direct_caps_of (destroyOperation e c s) x \<subseteq> direct_caps_of s x"
  by (auto simp: destroyOperation_def dest: direct_caps_of_destroy)

lemma direct_caps_of_remove_le:
  "direct_caps_of (removeOperation e c\<^sub>1 c\<^sub>2 s) x \<subseteq> direct_caps_of s x"
  by (auto dest: direct_caps_of_remove)

lemma direct_caps_of_removeSet_le:
  "direct_caps_of (removeSetOperation e c C s) x \<subseteq> direct_caps_of s x"
  by (auto dest: direct_caps_of_removeSet)

lemma direct_caps_of_revoke_le:
  "s' \<in> revokeOperation e c s \<Longrightarrow> direct_caps_of s' x \<subseteq> direct_caps_of s x"
  by (auto dest: direct_caps_of_revoke)

text \<open>
  单调性链本体。四层，每层一行到三行：
  @{verbatim "store_connected_direct"} 是"存在一条带 @{verbatim "Store"}
  的能力指向对方"，能力变少只会让边变少；闭包跟着单调
  （@{verbatim "rtrancl_mono"}）；@{verbatim "caps_of"} 是"沿闭包把能力并起来"，
  两处同时变少所以整体变少；@{verbatim "shares_caps"} 与
  @{verbatim "leak"} 不过是把这些结果再拼一次。
  最后把 @{verbatim "\<in>cap"} 那个序也接上——它要求的是
  "对方手里有一条权利不少于我的能力"，对方能力变少时这件事\emph{不会}变得更容易，
  所以方向是对的。
\<close>

lemma scd_mono:
  assumes P: "\<And>e. direct_caps_of s' e \<subseteq> direct_caps_of s e"
  shows "store_connected_direct s' \<subseteq> store_connected_direct s"
  using P by (fastforce simp: store_connected_direct_def)

lemma sc_mono:
  assumes P: "\<And>e. direct_caps_of s' e \<subseteq> direct_caps_of s e"
  shows "store_connected s' \<subseteq> store_connected s"
  unfolding store_connected_def
  by (rule rtrancl_mono [OF scd_mono [OF P]])

lemma caps_of_mono:
  assumes P: "\<And>x. direct_caps_of s' x \<subseteq> direct_caps_of s x"
    and "c \<in> caps_of s' e"
  shows "c \<in> caps_of s e"
  using assms sc_mono [OF P] by (auto simp: caps_of_def image_iff)

lemma shares_caps_mono:
  assumes P: "\<And>e. direct_caps_of s' e \<subseteq> direct_caps_of s e"
    and "shares_caps s' x y"
  shows "shares_caps s x y"
proof -
  from P have "store_connected s' \<subseteq> store_connected s" by (rule sc_mono)
  with assms(2) show ?thesis by (auto simp: shares_caps_def)
qed

lemma cap_in_caps_caps_of_mono:
  assumes P: "\<And>e. direct_caps_of s' e \<subseteq> direct_caps_of s e"
    and "c \<in>cap caps_of s' e"
  shows "c \<in>cap caps_of s e"
  using assms unfolding cap_in_caps_def by (auto dest: caps_of_mono [OF P])

lemma leak_mono:
  assumes P: "\<And>e. direct_caps_of s' e \<subseteq> direct_caps_of s e"
    and "leak s' x y"
  shows "leak s x y"
  using assms unfolding leak_def
  by (auto dest: cap_in_caps_caps_of_mono [OF P] shares_caps_mono [OF P])

lemma directly_tgs_connected_mono:
  assumes P: "\<And>e. direct_caps_of s' e \<subseteq> direct_caps_of s e"
    and "s' \<turnstile> x \<leftrightarrow> y"
  shows "s \<turnstile> x \<leftrightarrow> y"
  using assms unfolding directly_tgs_connected_def
  by (auto dest: leak_mono [OF P])

text \<open>
  链子造好了，四个操作各自套上去就是三条一行的引理：
  先给\emph{纯操作}版本（@{verbatim "generalOperation"} 那一族的对偶），
  再给@{verbatim "step"} 版本，形状与真实文件的
  @{verbatim "destroy_directly_tgs_connected"}、
  @{verbatim "remove_directly_tgs_connected"}（第 669、754 行）一致。
  @{verbatim "step"} 版本多出的那一步是"非法调用与自环那支平凡"——
  真实文件用 @{verbatim "if_split_asm"} 摊开 @{verbatim "step_def"}
  再 @{verbatim "erule disjE"}（第 672、673 行），本章把这一步交给 @{verbatim "auto"}。
  链子到 @{verbatim "directly"} 就停：闭包那一步 @{verbatim "tgs_connected"} 不靠单调性引理，
  24.7 结尾用真实文件那条 @{verbatim "rtrancl_induct"} 直接证
  @{verbatim "tgs_connected_preserved_step"}，比先造一个传递版单调性更省。
\<close>

lemma directly_tgs_connected_destroy:
  "destroyOperation e c s \<turnstile> x \<leftrightarrow> y \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  by (rule directly_tgs_connected_mono [OF direct_caps_of_destroy_le])

lemma directly_tgs_connected_remove:
  "removeOperation e c\<^sub>1 c\<^sub>2 s \<turnstile> x \<leftrightarrow> y \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  by (rule directly_tgs_connected_mono [OF direct_caps_of_remove_le])

lemma directly_tgs_connected_removeSet:
  "removeSetOperation e c C s \<turnstile> x \<leftrightarrow> y \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  by (rule directly_tgs_connected_mono [OF direct_caps_of_removeSet_le])

lemma directly_tgs_connected_revoke:
  "s' \<in> revokeOperation e c s \<Longrightarrow> s' \<turnstile> x \<leftrightarrow> y \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  by (rule directly_tgs_connected_mono [OF direct_caps_of_revoke_le])

lemma destroy_directly_tgs_connected:
  "\<lbrakk>s' \<in> step (SysDestroy e c) s; s' \<turnstile> x \<leftrightarrow> y\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  using directly_tgs_connected_destroy by (auto simp: step_def split: if_split_asm)

lemma remove_directly_tgs_connected:
  "\<lbrakk>s' \<in> step (SysRemove e c\<^sub>1 c\<^sub>2) s; s' \<turnstile> x \<leftrightarrow> y\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  using directly_tgs_connected_remove by (auto simp: step_def split: if_split_asm)

lemma removeSet_connected:
  "\<lbrakk>s' \<in> step (SysRemoveSet e c C) s; s' \<turnstile> x \<leftrightarrow> y\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  using directly_tgs_connected_removeSet by (auto simp: step_def split: if_split_asm)

lemma revoke_directly_tgs_connected:
  "\<lbrakk>s' \<in> step (SysRevoke e c) s; s' \<turnstile> x \<leftrightarrow> y\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow> y"
  using directly_tgs_connected_revoke by (auto simp: step_def split: if_split_asm)

text \<open>
  顺手把真实文件的四条 @{verbatim "caps_of_*"} 也拿到，
  它们只用到链上的 @{verbatim "caps_of_mono"}
  （原件分别是第 659、725、781、855 行，
  真实文件里每条都要自己证一遍 @{verbatim "store_connected_*"}）：
\<close>

lemma caps_of_destroy:
  "c \<in> caps_of (destroyOperation e' c' s) e \<Longrightarrow> c \<in> caps_of s e"
  by (rule caps_of_mono [OF direct_caps_of_destroy_le])

lemma caps_of_remove:
  "c \<in> caps_of (removeOperation e c\<^sub>1 c\<^sub>2 s) x \<Longrightarrow> c \<in> caps_of s x"
  by (rule caps_of_mono [OF direct_caps_of_remove_le])

lemma caps_of_removeSet:
  "c' \<in> caps_of (removeSetOperation e c C s) x \<Longrightarrow> c' \<in> caps_of s x"
  by (rule caps_of_mono [OF direct_caps_of_removeSet_le])

lemma caps_of_revoke:
  "\<lbrakk>s' \<in> revokeOperation sub c\<^sub>1 s; c \<in> caps_of s' e\<rbrakk> \<Longrightarrow> c \<in> caps_of s e"
  by (rule caps_of_mono [OF direct_caps_of_revoke_le])

text \<open>
  四条 @{verbatim "..._conTrans"}，与前八个操作的同名引理同形。
  删除性操作的结论比建设性的\emph{强}：直接边还是直接边，
  不必退到闭包——因为删能力不会造出新边。
  真实文件正是这么写的（第 688、770、815、923 行的结论都是
  @{verbatim "directly_tgs_connected s"}）。
\<close>

lemma destroy_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysDestroy e c)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> directly_tgs_connected s"
  by (auto dest: destroy_directly_tgs_connected)

lemma remove_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysRemove e c\<^sub>1 c\<^sub>2)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> directly_tgs_connected s"
  by (auto dest: remove_directly_tgs_connected)

lemma removeSet_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysRemoveSet n c C)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> directly_tgs_connected s"
  by (auto dest: removeSet_connected)

lemma revoke_conTrans:
  "\<lbrakk>s' \<in> step cmd s; (x, y) \<in> directly_tgs_connected s';
     cmd = (SysRevoke n c\<^sub>1)\<rbrakk>
   \<Longrightarrow> (x, y) \<in> directly_tgs_connected s"
  by (auto dest: revoke_directly_tgs_connected)

text \<open>
  八条 @{verbatim "conTrans"} 齐了，收尾三刀与真实文件同形（@{verbatim "connected_tgs_connected"}
  第 948 行、@{verbatim "tgs_connected_preserved_step"} 第 964 行、
  @{verbatim "tgs_connected_preserved"} 第 984 行）。
  第一条的证法值得看一眼：它不对 @{verbatim "cmd"} 直接分类，而是先
  @{verbatim "case_tac"}"这条边原来在不在 @{verbatim "s"} 里"。
  在，闭包自反即得；不在，@{verbatim "case_tac cmd"} 展开出八个构造子，
  每个丢给对应的那条 @{verbatim "conTrans"}——分类的完备性是 datatype 给的，
  不是人列的。
\<close>

lemma connected_tgs_connected:
  "\<lbrakk>s' \<in> step cmd s; (e\<^sub>x, e\<^sub>y) \<in> directly_tgs_connected s'\<rbrakk>
   \<Longrightarrow> (e\<^sub>x, e\<^sub>y) \<in> tgs_connected s"
  apply (case_tac "(e\<^sub>x, e\<^sub>y) \<in> directly_tgs_connected s")
   apply (simp add: tgs_connected_def)
   apply (case_tac cmd)
         apply (rule create_conTrans, fastforce+)
        apply (rule take_conTrans, fastforce+)
       apply (rule grant_conTrans, fastforce+)
      apply (frule copy_conTrans, fastforce+)
     apply (frule remove_conTrans, fastforce+)
    apply (frule removeSet_conTrans, fastforce+)
   apply (frule revoke_conTrans, fastforce+)
  apply (frule destroy_conTrans, fastforce+)
  done

text \<open>
  第二条把"一步"提升到"闭包"。真实文件在这里留了一行 @{verbatim "thm"}
  （第 966、967 行），把 @{verbatim "rtrancl_induct"} 实例化后的样子打印出来给人看，
  本章用同样的实例化，只是把那行注释掉：
  要归纳的是 @{verbatim "directly_tgs_connected s'"} 的闭包，
  谓词取"@{verbatim "s"} 里从 @{verbatim "x"} 出发能到达"。
  基例是闭包自反；归纳步分两种——后半段已经在 @{verbatim "s"} 里连通，
  交给 @{verbatim "tgs_connected_trans"}；否则新走的那条边是
  @{verbatim "s'"} 的直接边，@{verbatim "connected_tgs_connected"} 恰好说它是
  @{verbatim "s"} 的闭包边。这一步 @{verbatim "simp"} 之后剩的目标里
  @{verbatim "y"} 是归纳引入的中间点，所以必须先 @{verbatim "case_tac"} 它。
\<close>

lemma tgs_connected_preserved_step:
  "\<lbrakk>s' \<in> step cmd s; s' \<turnstile> x \<leftrightarrow>* z\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leftrightarrow>* z"
  apply (erule rtrancl_induct [where r="directly_tgs_connected s'",
                               simplified tgs_connected_def [symmetric]], simp)
  apply (case_tac "s \<turnstile> y \<leftrightarrow>* z")
   apply (erule (1) tgs_connected_trans)
  apply (simp add: connected_tgs_connected)
  done

text \<open>
  有了单步版本，序列版本就是 induction over @{verbatim "cmds"}。
  注意 @{verbatim "execute"} 是倒着展开的（24.4 就强调过），
  所以归纳假设关于的是"后半段"，@{verbatim "step"} 作用在"最后一拍"上——
  两条恰好对得上。
\<close>

lemma tgs_connected_preserved [rule_format]:
  "\<forall>s'. s' \<in> execute cmds s \<longrightarrow>
            s' \<turnstile> x \<leftrightarrow>* y \<longrightarrow>
            s \<turnstile> x \<leftrightarrow>* y"
  apply (induct_tac cmds, simp)
  apply clarsimp
  apply (rename_tac cmd cmds s'' s')
  apply (erule_tac x=s' in allE)
  apply (simp add: tgs_connected_preserved_step)
  done

lemma leakImplyConnected:
  "leak s\<^sub>i e\<^sub>x e\<^sub>i \<Longrightarrow> (e\<^sub>x, e\<^sub>i) \<in> directly_tgs_connected s\<^sub>i"
  by (simp add: directly_tgs_connected_def)

lemma leakImplyConnectedTrans:
  "leak s\<^sub>i e\<^sub>x e\<^sub>i \<Longrightarrow> (e\<^sub>x, e\<^sub>i) \<in> tgs_connected s\<^sub>i"
  by (simp add: tgs_connected_def, frule leakImplyConnected, auto)

lemma leak_conTrans [rule_format]:
  "\<lbrakk>s \<in> execute cmds s\<^sub>0; leak s x y\<rbrakk>
   \<Longrightarrow> (x, y) \<in> tgs_connected s\<^sub>0"
  by (auto intro: leakImplyConnectedTrans tgs_connected_preserved)

text \<open>
  这就是本章要的@{verbatim "leakage rule"}："初态里不连通的两方，
  跑任意一串系统调用之后仍然不连通"。它是 @{verbatim "take-grant"}
  模型给出的第一条真正的全局不变式，形式上是 @{verbatim "leak_conTrans"}
  的逆否（真实文件第 1000 行）。
\<close>

lemma leakage_rule:
  "\<lbrakk>s' \<in> execute cmds s; \<not> s \<turnstile> x \<leftrightarrow>* y\<rbrakk>
   \<Longrightarrow> \<not> (s' \<turnstile> x \<rightarrow> y)"
  by (auto simp add: leak_conTrans)

text \<open>
  还差最后一步：@{verbatim "leak"} 说的是"@{verbatim "e\<^sub>x"} 能碰 @{verbatim "e\<^sub>y"}"，
  而真正想要的结论是"@{verbatim "e\<^sub>x"} 手里所有能力都在初态那条岛的支配之下"。
  桥梁是 @{verbatim "caps_of_op"}（真实文件第 1013 行）：
  任何一步之后 @{verbatim "x"} 新见到的能力，要么本来就在 @{verbatim "s"} 里 @{verbatim "x"} 的闭包上某点手里，
  要么就是这一步自己造出来的——而造它用的原料仍在闭包上。
  八个构造子 @{verbatim "case_tac"} 一遍，破坏性那四支靠
  @{verbatim "caps_of_destroy"} 一族的单调性，建设性那四支靠 @{verbatim "caps_of_generalOp"} 一族。
\<close>

lemma caps_of_op:
  "\<lbrakk>s' \<in> step cmd s; c' \<in> caps_of s' x\<rbrakk>
   \<Longrightarrow> \<exists>z. s \<turnstile> x \<leftrightarrow>* z \<and> c' \<in>cap caps_of s z"
  apply (simp add: step_def split: if_split_asm)
   prefer 2
   apply (fastforce simp: cap_in_caps_def tgs_connected_def rights_extra_rights)
  apply (erule disjE)
   apply (fastforce simp: cap_in_caps_def tgs_connected_def rights_extra_rights)
  apply (case_tac cmd)
         apply (simp add: caps_of_create)
        apply (simp add: caps_of_take)
       apply (simp add: caps_of_grant)
      apply (simp add: caps_of_copy)
     apply (clarsimp, drule caps_of_remove)
     apply (fastforce simp: cap_in_caps_def tgs_connected_def rights_extra_rights)
    apply (clarsimp, drule caps_of_removeSet)
    apply (fastforce simp: cap_in_caps_def tgs_connected_def rights_extra_rights)
   apply (clarsimp, drule (1) caps_of_revoke)
   apply (fastforce simp: cap_in_caps_def tgs_connected_def rights_extra_rights)
  apply (clarsimp, drule caps_of_destroy)
  apply (fastforce simp: cap_in_caps_def tgs_connected_def rights_extra_rights)
  done

text \<open>
  于是 @{verbatim "authority_confinement"}（真实文件第 1064 行）：
  若初态里 @{verbatim "e\<^sub>x"} 整座岛的能力都不超过 @{verbatim "c"}，
  那么任意一串系统调用之后仍然不超过。
  @{verbatim "caps_of_op"} 给出"新能力总在初态某点的支配下"，
  岛在闭包下不变（@{verbatim "tgs_connected_preserved_step"}）把它接起来。
   induction 那一步写成 @{verbatim "proof (induct cmds arbitrary: s')"}，
  因为 @{verbatim "s'"} 依赖整串调用，不 generalise 就归纳不出东西。
\<close>

lemma authority_confinement_induct_step:
  "\<lbrakk>s' \<in> step cmd s;
    \<forall>e\<^sub>i. s \<turnstile> e\<^sub>x \<leftrightarrow>* e\<^sub>i \<longrightarrow> caps_of s e\<^sub>i \<le>cap c\<rbrakk>
   \<Longrightarrow> caps_of s' e\<^sub>x \<le>cap c"
  apply (clarsimp simp: caps_dominated_by_def)
  apply (drule (1) caps_of_op)
  apply (fastforce simp: cap_in_caps_def)
  done

lemma authority_confinement_helper:
  "s' \<in> execute cmds s \<longrightarrow>
   (\<forall>e\<^sub>i. s \<turnstile> e\<^sub>x \<leftrightarrow>* e\<^sub>i \<longrightarrow> caps_of s e\<^sub>i \<le>cap c) \<longrightarrow>
   (\<forall>e\<^sub>i. s' \<turnstile> e\<^sub>x \<leftrightarrow>* e\<^sub>i \<longrightarrow> caps_of s' e\<^sub>i \<le>cap c)"
proof (induct cmds arbitrary: s')
case Nil
  show ?case by clarsimp
next
case (Cons cmd cmds s')
show ?case
  apply clarsimp
  apply (rule authority_confinement_induct_step, assumption)
  apply clarsimp
  apply (rule Cons.hyps [rule_format], simp_all)
  apply (drule (1) tgs_connected_preserved_step)
  apply (simp add: tgs_connected_def)
  done
qed

lemma authority_confinement:
  "\<lbrakk>s' \<in> execute cmds s;
    \<forall>e\<^sub>i. s \<turnstile> e\<^sub>x \<leftrightarrow>* e\<^sub>i \<longrightarrow> caps_of s e\<^sub>i \<le>cap c\<rbrakk>
   \<Longrightarrow> caps_of s' e\<^sub>x \<le>cap c"
  by (erule authority_confinement_helper [rule_format, where e\<^sub>x=e\<^sub>x], simp_all)

ML \<open>writeln "==== 24.7 段落 ===="\<close>

subsection \<open>24.8 Island：把不变式改写成一句话\<close>

text \<open>
  24.7 的 @{verbatim "authority_confinement"} 已经够用，但它的前提长得别扭：
  "对每一个闭包可达的点，那点子的能力都不超过 @{verbatim "c"}"。
  真实仓库把这句话说成一个名字，写在
  @{verbatim "l4v/spec/take-grant/Islands_S.thy"}——全文只有 58 行，
  文件头的描述是 @{verbatim "Rephrasing of the confinement proof using the concept of islands"}。
  @{verbatim "island"} 在第 15 行，@{verbatim "island_caps"} 在第 19 行，
  两行定义、四个引理，剩下的都是把 24.7 的结论换个名字再说一遍。
\<close>

definition island :: "state \<Rightarrow> entity_id \<Rightarrow> entity_id set" where
  "island s x \<equiv> {e\<^sub>i. s \<turnstile> x \<leftrightarrow>* e\<^sub>i}"

definition island_caps :: "state \<Rightarrow> entity_id \<Rightarrow> cap set" where
  "island_caps s x \<equiv> \<Union>(caps_of s ` island s x)"

text \<open>
  把 24.6 算出来的连通形状搬过来，三条岛立刻是具体的集合。
  注意 @{verbatim "island"} 自带自反性（闭包），所以每个点都在自己的岛里，
  @{verbatim "island sample_state 4"} 不是空集而是 @{verbatim "{4}"}。
\<close>

lemma island_sample_0: "island sample_state 0 = {0, 1, 2}" by (auto simp: island_def)
lemma island_sample_3: "island sample_state 3 = {3, 5}" by (auto simp: island_def)
lemma island_sample_4: "island sample_state 4 = {4}" by (auto simp: island_def)
lemma island_sample_5: "island sample_state 5 = {3, 5}" by (auto simp: island_def)

text \<open>
  @{verbatim "island_caps"} 与 @{verbatim "direct_caps_of"} 的关系有两条写法。
  第一条（第 23 行）只是把 @{verbatim "\<Union>"} 换个记号；
  第二条（第 27 行）才有内容：整座岛能"够到"的能力，
  等于沿着 @{verbatim "tgs_connected"} 走一步以内的人手里直接握着的能力之并——
  @{verbatim "caps_of"} 那层 @{verbatim "store_connected"} 闭包被吃掉了。
  它的证明要用 24.6 那条 @{verbatim "store_connected_directly_tgs_connected"}
  把 store 边折成 tgs 边，再用 @{verbatim "directly_tgs_connected_rtrancl_into_rtrancl"}
  接一次闭包，两个方向合起来正好是一个 @{verbatim "metis"}。
\<close>

lemma island_caps_def2:
  "island_caps s x \<equiv> \<Union>e \<in> island s x. caps_of s e"
  by (simp add: island_caps_def)

lemma island_caps_def3:
  "island_caps s x = \<Union>(direct_caps_of s ` island s x)"
  apply (clarsimp simp: island_caps_def)
  apply rule
   apply (clarsimp simp: island_def caps_of_def)
   apply (drule store_connected_directly_tgs_connected)
   apply (metis (opaque_lifting, no_types) directly_tgs_connected_rtrancl_into_rtrancl)
  apply (fastforce simp: caps_of_def store_connected_def)
  done

text \<open>
  在这个记号下算 24.3 那个系统的整座岛：实体 0 的岛包含 0 与 1，
  两者的能力并起来还是 @{verbatim "{cA, cB}"}（@{verbatim "cB"} 重复了一次）；
  3 的岛把不存在的 5 也算进去，可 5 手里什么都没有，于是岛的能力就是 @{verbatim "{cC}"}；
  4 的岛只有自己，能力 @{verbatim "{cD}"}。
\<close>

lemma island_caps_sample_0: "island_caps sample_state 0 = {cA, cB}"
  by (simp add: island_caps_def island_sample_0)

lemma island_caps_sample_3: "island_caps sample_state 3 = {cC}"
  by (simp add: island_caps_def island_sample_3)

lemma island_caps_sample_4: "island_caps sample_state 4 = {cD}"
  by (simp add: island_caps_def island_sample_4)

text \<open>
  @{verbatim "island_caps_dom"}（第 37 行）把"@{verbatim "c"} 支配整座岛"
  与"逐点支配"划等号，这条等式就是改写前后唯一的差别；
  有了它，@{verbatim "authority_confinement"} 立刻换个说法成立。
  证明里 @{verbatim "subst (asm) tgs_connected_comm_eq"} 那一步是必需的：
  24.7 的结论说"@{verbatim "s"} 里连通的在 @{verbatim "s'"} 里也连通"，
  而这里需要的是"@{verbatim "s'"} 里从 @{verbatim "x"} 出发可达的点，
  在 @{verbatim "s"} 里也可达"——方向靠对称性扳过来。
\<close>

lemma island_caps_dom:
  "island_caps s e\<^sub>x \<le>cap c =
     (\<forall>e\<^sub>i. (e\<^sub>x, e\<^sub>i) \<in> tgs_connected s \<longrightarrow> caps_of s e\<^sub>i \<le>cap c)"
  by (auto simp add: island_caps_def caps_dominated_by_def island_def)

lemma authority_confinement_islands:
  "\<lbrakk>s' \<in> execute cmds s;
    island_caps s x \<le>cap c\<rbrakk>
   \<Longrightarrow> island_caps s' x \<le>cap c"
  apply (simp add: island_caps_dom)
  apply clarsimp
  apply (frule (1) tgs_connected_preserved)
  apply (subst (asm) tgs_connected_comm_eq)
  apply (erule authority_confinement)
  apply clarsimp
  apply (erule_tac x=e\<^sub>i' in allE)
  apply (erule impE)
  apply (metis (opaque_lifting, no_types) tgs_connected_comm_eq tgs_connected_def rtrancl_trans)
  apply clarsimp
  done

ML \<open>writeln "==== 24.8 段落 ===="\<close>

subsection \<open>24.9 从权威流到信息流\<close>

text \<open>
  前八节说的都是"权威"（谁能对谁做系统调用）。
  第 22 章的信息流是另一种东西：谁能把数据写给谁。
  @{verbatim "l4v/spec/take-grant/Isolation_S.thy"}（106 行）在同一个模型上
  再套一层，用的只有 @{verbatim "Read"} 与 @{verbatim "Write"} 两个权利：
  @{verbatim "set_flow"}（第 11 行）说"两组实体之间有数据流"，
  当且仅当其中某一方手里有指向另一方的读能力或写能力；
  @{verbatim "flow"}（第 23 行）把点提升到整座岛，
  @{verbatim "flow_trans"}（第 37 行）再取闭包。
\<close>

definition set_flow :: "state \<Rightarrow> (entity_id set \<times> entity_id set) set" where
  "set_flow s \<equiv> {(X, Y). \<exists>x \<in> X. \<exists>y \<in> Y.
                       read_cap x \<in>cap caps_of s y \<or>
                       write_cap y \<in>cap caps_of s x}"

definition flow :: "state \<Rightarrow> (entity_id \<times> entity_id) set" where
  "flow s \<equiv> {(x, y). (island s x, island s y) \<in> set_flow s}"

definition flow_trans :: "state \<Rightarrow> (entity_id \<times> entity_id) set" ("flow\<^sup>*") where
  "flow_trans s \<equiv> (flow s)^*"

abbreviation in_flow :: "state \<Rightarrow> entity_id \<Rightarrow> entity_id \<Rightarrow> bool"
  ("_ \<turnstile> _ \<leadsto> _" [60, 0, 60] 61) where
  "s \<turnstile> x \<leadsto> y \<equiv> (x, y) \<in> flow s"

abbreviation in_flow_trans :: "state \<Rightarrow> entity_id \<Rightarrow> entity_id \<Rightarrow> bool"
  ("_ \<turnstile> _ \<leadsto>* _" [60, 0, 60] 61) where
  "s \<turnstile> x \<leadsto>* y \<equiv> (x, y) \<in> flow_trans s"

text \<open>
  真实文件在这里还有一条 @{verbatim "notation (latex output)"}（第 46 行）
  和两条 @{verbatim "translations"}（第 49 行），只为把
  "@{verbatim "\<not> (s \<turnstile> x \<leadsto> y)"}" 这样的否定式排回非成员写法；
  本章不出 PDF，就省下了。

  三条定义的手感要在 24.3 那个系统上算才有。 @{verbatim "cD"} 是
  实体 4 手里那条指向 3 的 @{verbatim "{Read, Write}"} 能力，
  于是 4 与 3 的岛之间有数据流，反方向也有——一条读写能力天然双向。
\<close>

text \<open>
  两条 @{verbatim "rights_extra_rights_"} 引理（真实文件第 55、59 行）是下面
  所有算式的钥匙：@{verbatim "read_cap"} 不带 @{verbatim "Create"}，
  所以 @{verbatim "extra_rights"} 不放大它，
  @{verbatim "rights (extra_rights (read_cap e)) = {Read}"} 一行就完事。
  换成 24.5 的话说：读能力永远只给读的权利，@{verbatim "\<in>cap"}
  那一步不会偷偷把它放大成写。
\<close>

lemma rights_extra_rights_read_cap [simp]:
  "rights (extra_rights (read_cap e)) = {Read}"
  by (simp add: rights_extra_rights)

lemma rights_extra_rights_write_cap [simp]:
  "rights (extra_rights (write_cap e)) = {Write}"
  by (simp add: rights_extra_rights)

text \<open>
  三条现成能力先各算一笔。@{verbatim "cD"} 同时给出读与写两条；
  @{verbatim "cC"} 那条指向"@{verbatim "5"}"的悬挂能力只带 @{verbatim "Create"}，
  可 24.5 的 @{verbatim "extra_rights"} 把它折成了全部权利，
  于是 @{verbatim "read_cap 5"} 反而 @{verbatim "\<in>cap"} 它——
  "@{verbatim "3"} 能读 @{verbatim "5"}"这句话在这个模型里是真命题，
  哪怕 @{verbatim "is_entity sample_state 5"} 不成立（24.3 算过）。
\<close>

lemma read_cap_incap_cD: "read_cap 3 \<in>cap caps_of sample_state 4"
  by (simp add: cap_in_caps_def all_rights_def)

lemma write_cap_incap_cD: "write_cap 3 \<in>cap caps_of sample_state 4"
  by (simp add: cap_in_caps_def all_rights_def)

lemma read_cap_incap_cC: "read_cap 5 \<in>cap caps_of sample_state 3"
  by (simp add: cap_in_caps_def all_rights_def)

text \<open>
  三条 @{verbatim "set_flow"} 事实。 @{verbatim "B"} 记 @{verbatim "{3, 5}"}，
  @{verbatim "C"} 记 @{verbatim "{4}"}。

  这里有一处本章踩过的坑，值得写下来：第一版把 witness 逐条写成
  @{verbatim "rule bexI [where x=3]"} 的形式，结果 simp 早就把
  @{verbatim "\<exists>x\<in>{3, 5}. P x"} 摊成了 @{verbatim "P 3 \<or> P 5"}
  （@{verbatim "bex_insert"} 是 simp 规则），人工 witness 反而撞上
  @{verbatim "No subgoals"}。目标里 @{verbatim "entity_id"} 全是字面量时，
  先让 @{verbatim "simp"}/@{verbatim "auto"} 跑一遍再决定要不要自己举证。
\<close>

lemma set_flow_B_C: "({3, 5}, {4}) \<in> set_flow sample_state"
  by (auto simp: set_flow_def all_rights_def)

lemma set_flow_C_B: "({4}, {3, 5}) \<in> set_flow sample_state"
  by (auto simp: set_flow_def all_rights_def)

lemma set_flow_B_B: "({3, 5}, {3, 5}) \<in> set_flow sample_state"
  by (auto simp: set_flow_def all_rights_def)

text \<open>
  把 witness 折回 @{verbatim "flow"}：@{verbatim "flow_def"} 说的是"两条岛之间有事"，
  所以岛相等的点结论相同——@{verbatim "3 \<leadsto> 4"} 与 @{verbatim "5 \<leadsto> 4"}
  是同一条事实的两张脸。
\<close>

lemma flow_3_4: "sample_state \<turnstile> 3 \<leadsto> 4"
  by (simp add: flow_def island_sample_3 island_sample_4 set_flow_B_C)

lemma flow_5_4: "sample_state \<turnstile> 5 \<leadsto> 4"
  by (simp add: flow_def island_sample_4 island_sample_5 set_flow_B_C)

lemma flow_4_3: "sample_state \<turnstile> 4 \<leadsto> 3"
  by (simp add: flow_def island_sample_3 island_sample_4 set_flow_C_B)

lemma flow_4_5: "sample_state \<turnstile> 4 \<leadsto> 5"
  by (simp add: flow_def island_sample_4 island_sample_5 set_flow_C_B)

lemma flow_3_5: "sample_state \<turnstile> 3 \<leadsto> 5"
  by (simp add: flow_def island_sample_3 island_sample_5 set_flow_B_B)

text \<open>
  反过来，24.6 那条"@{verbatim "0"} 与 @{verbatim "4"} 不连通"在这里有个更硬的版本：
  0 的岛 @{verbatim "{0, 1, 2}"} 与 4 的岛 @{verbatim "{4}"} 之间连一条数据流都没有，
  因为那三个实体手里的 @{verbatim "cA"}/@{verbatim "cB"} 全是
  @{verbatim "Store"}/@{verbatim "Take"}/@{verbatim "Grant"}，一个
  @{verbatim "Read"}/@{verbatim "Write"} 都不带。
  这一条是算出来的，不是"没试出来"：
  @{verbatim "cap_in_caps_def"} 展开后要求存在一条目标与权利都合适的现成能力，
  而 @{verbatim "caps_of_sample"}（24.3）已经把岛里每个人的能力算干净了。
\<close>

lemma no_flow_0_4: "\<not> (sample_state \<turnstile> 0 \<leadsto> 4)"
  by (auto simp: flow_def set_flow_def island_sample_0 island_sample_4
                 cap_in_caps_def)

lemma no_flow_4_0: "\<not> (sample_state \<turnstile> 4 \<leadsto> 0)"
  by (auto simp: flow_def set_flow_def island_sample_0 island_sample_4
                 cap_in_caps_def)

text \<open>
  上面四条只说"一步之内"。 @{verbatim "information_flow"} 的前提要的是闭包版本，
  而闭包版本需要一个不变式：@{verbatim "flow sample_state"} 的两端都在
  @{verbatim "{3, 4, 5}"} 里，于是从 @{verbatim "0"} 出发的闭包路一步也迈不出去，
  @{verbatim "0 \<leadsto>* 4"} 与 @{verbatim "0 \<leadsto>* 3"} 一样不成立。

  这正是 @{verbatim "l4v/spec/take-grant/Example2.thy"} 的招：它把整条
  @{verbatim "flow_trans s"} 折进一个 @{verbatim "inv_image"}，谓词是
  "@{verbatim "x = 1 \<or> x = 2"}"
  （@{verbatim "flow_in_inv_image"} 第 1174 行、
  @{verbatim "flow_trans_in_inv_image"} 第 1181 行），再由 @{verbatim "0"}
  不满足那个谓词得出 @{verbatim "e0_not_flow_trans_e1"}（第 1189 行），
  最后第 1203 行的 @{verbatim "e0_e1_isolated"} 说：
  任意调用序列之后 @{verbatim "0"} 与 @{verbatim "1"} 之间双向都无信息流。
\<close>

lemma flow_within_345:
  "(x, y) \<in> flow sample_state \<Longrightarrow> x \<in> {3, 4, 5} \<and> y \<in> {3, 4, 5}"
  by (auto simp: flow_def set_flow_def island_def cap_in_caps_def
                 split: if_splits)

lemma flow_trans_from_0:
  "(0, z) \<in> (flow sample_state)^* \<Longrightarrow> z = 0"
  apply (erule rtrancl_induct [where r="flow sample_state"])
   apply simp
  by (auto dest: flow_within_345)

lemma no_flow_trans_0_4: "\<not> (sample_state \<turnstile> 0 \<leadsto>* 4)"
  using flow_trans_from_0 [of 4] by (auto simp: flow_trans_def)

lemma flow_trans_refl [simp]:
  "s \<turnstile> x \<leadsto>* x"
  by (metis flow_trans_def rtrancl.rtrancl_refl)

text \<open>
  真正的定理是 @{verbatim "flow_connected_step"}（第 67 行）：
  系统调用不会造出新的信息流。证明的结构与 24.7 的
  @{verbatim "tgs_connected_preserved_step"} 一模一样——
  对 @{verbatim "flow s'"} 的闭包归纳，基例 @{verbatim "simp"}，
  归纳步先立"@{verbatim "s"} 里 @{verbatim "y \<leadsto> z"}"再往前推。
  新的一点是那条 @{verbatim "subgoal_tac"}：
  @{verbatim "y \<leadsto> z"} 是两条岛之间的 @{verbatim "set_flow"}，
  岛在 @{verbatim "s"} 与 @{verbatim "s'"} 之间不变吗？不是——
  岛会变，但 @{verbatim "tgs_connected_preserved_step"} 说新岛里的点在旧岛里可达，
  于是那本账记在旧岛头上；能力这一侧靠 24.7 的 @{verbatim "caps_of_op"} 兜住。
  两条一拼，@{verbatim "metis"} 收尾。
\<close>

lemma flow_connected_step:
  "\<lbrakk>s' \<turnstile> x \<leadsto>* y; s' \<in> step cmd s\<rbrakk>
   \<Longrightarrow> s \<turnstile> x \<leadsto>* y"
  apply (erule rtrancl_induct [where r="flow s'",
                               simplified flow_trans_def [symmetric]])
   apply simp
  apply (subgoal_tac "s \<turnstile> y \<leadsto> z")
   apply (fastforce simp: flow_trans_def rtrancl.rtrancl_into_rtrancl)
  apply (clarsimp simp: flow_def island_def set_flow_def)
  apply (frule_tac x=y in tgs_connected_preserved_step, simp)
  apply (frule_tac x=z in tgs_connected_preserved_step, simp)
  apply (clarsimp simp: cap_in_caps_def)
  apply (erule disjE)
   apply clarsimp
   apply (drule (1) caps_of_op)
   apply (clarsimp simp: cap_in_caps_def)
   apply (metis (no_types) tgs_connected_trans subsetD)
  apply clarsimp
  apply (drule (1) caps_of_op)
  apply (clarsimp simp: cap_in_caps_def)
  apply (metis (no_types) tgs_connected_trans subsetD)
  done

text \<open>
  剩下的两行就是把单步提升成序列，再取逆否：
  @{verbatim "information_flow"}（第 100 行）是这一节要的结论——
  初态里没有从 @{verbatim "x"} 到 @{verbatim "y"} 的信息流，
  跑任意一串系统调用之后仍然没有。
\<close>

lemma flow_connected [rule_format]:
  "\<forall>s'. s' \<in> execute cmds s \<longrightarrow>
            s' \<turnstile> x \<leadsto>* y \<longrightarrow>
            s \<turnstile> x \<leadsto>* y"
  apply (induct_tac cmds, simp)
  apply clarsimp
  apply (drule (1) flow_connected_step)
  apply auto
  done

lemma information_flow:
  "\<lbrakk>s' \<in> execute cmds s; \<not> s \<turnstile> x \<leadsto>* y\<rbrakk>
   \<Longrightarrow> \<not> s' \<turnstile> x \<leadsto>* y"
  by (auto simp: flow_connected)

text \<open>
  值得留意 @{verbatim "flow"} 与 @{verbatim "tgs_connected"} 在这一节里的分工：
  不变式是关于 @{verbatim "flow"} 闭包的，可它的证明全程在 @{verbatim "tgs"} 闭包上走——
  因为 @{verbatim "set_flow"} 用的是 @{verbatim "caps_of"}，而 @{verbatim "caps_of"} 是沿 @{verbatim "tgs"} 的
  @{verbatim "store"} 闭包并出来的。权威是信息流的粗粒度上界，
  这正是第 22 章 @{verbatim "sources"}（"这条 trace 里谁会影响到 u"）那一层的意思。
\<close>

ML \<open>writeln "==== 24.9 段落 ===="\<close>

subsection \<open>24.10 这个模型没有证明什么\<close>

text \<open>
  24.2 到 24.9 把 @{verbatim "l4v/spec/take-grant/"} 的四个理论重述完了。
  收尾要交代三件机器查得到的事：这一堆理论挂在哪个 Isabelle 会话上、
  两个示例理论各自算到哪一步就停了、以及它跟 @{verbatim "seL4/"} 那棵 C 树
  的对应关系究竟有多松。

  先说会话。@{verbatim "TakeGrant"}（`l4v/spec/ROOT` 第 124 行）
  只列了四个叶子理论，@{verbatim "System_S"}（`l4v/spec/ROOT` 第 126 行）
  与 @{verbatim "Isolation_S"}、@{verbatim "Example"}、
  @{verbatim "Example2"}，一共七行。@{verbatim "Confine_S"} 和
  @{verbatim "Islands_S"} 不在清单里——它们是 @{verbatim "Islands_S"}
  那条 import 链上的依赖，被顺带构建。所以"@{verbatim "l4v/spec/take-grant/"}
  有六个理论"和"会话只构建四个"两句话同时成立，
  看 ROOT 的时候别按清单数文件。
  构建命令 README 里给了：在 @{verbatim "l4v/"} 目录下跑
  @{verbatim "L4V_ARCH=ARM ./run_tests TakeGrant"}。其实
  @{verbatim "L4V_ARCH_DEFAULT"}（`l4v/run_tests` 第 14 行）本来就是
  @{verbatim "ARM"}，不写那个环境变量也是同一个架构。
  再说一句定位：这条会话是 @{verbatim "l4v/spec/"} 那一侧的抽象研究，
  精化链挂在另一份 ROOT 上——@{verbatim "Refine"}（`l4v/proof/ROOT` 第 29 行）
  与 @{verbatim "CRefine"}（`l4v/proof/ROOT` 第 85 行），两边互不 import。
\<close>

text \<open>
  两个示例理论承担的角色不一样。@{verbatim "Example.thy"} 只有 92 行，
  三个实体、一条 @{verbatim "Store"} 边、一条 @{verbatim "Grant"} 边，
  而且它只 import @{verbatim "System_S"}（`l4v/spec/take-grant/Example.thy` 第 8 行），
  连 24.6 的 @{verbatim "leak"} 都不用到。它存在的意义是把
  24.2 里 @{verbatim "direct_caps_of"} 与 @{verbatim "caps_of"} 的落差
  算成一个具体集合：@{verbatim "de0"}（`l4v/spec/take-grant/Example.thy` 第 25 行）
  给出实体 0 手里直接那条 @{verbatim "{Store}"} 能力，
  @{verbatim "ce0"}（`l4v/spec/take-grant/Example.thy` 第 71 行）
  给出 0 的 @{verbatim "caps_of"}——两条，多出来的 @{verbatim "{Grant}"} 是
  顺着 @{verbatim "Store"} 边从实体 1 那里"并"过来的。
  这一对引理是整个模型里最省话的一张图：能力本身不传播，
  传播的是能看见哪些直接能力表。
\<close>

text \<open>
  @{verbatim "Example2.thy"} 有 1212 行，只 import
  @{verbatim "Isolation_S"}（`l4v/spec/take-grant/Example2.thy` 第 8 行），
  才是真正的"手动模拟"：初始实体只有一个，
  @{verbatim "e0_caps"}（`l4v/spec/take-grant/Example2.thy` 第 31 行）
  把 @{verbatim "range create_cap"} 与对自己的全权利打包；
  十一个操作 @{verbatim "ops"}（`l4v/spec/take-grant/Example2.thy` 第 136 行）
  逐个把状态往前推。每个操作三条引理：@{verbatim "legal"}
  （`l4v/spec/take-grant/System_S.thy` 第 159 行起的判定）、
  @{verbatim "safe"}（结果集合 @{verbatim "\<subseteq>"} 那两个状态）、
  @{verbatim "live"}（反过来 @{verbatim "\<supseteq>"}），
  然后合成一条等式，比如 @{verbatim "execute_op0"}
  （`l4v/spec/take-grant/Example2.thy` 第 373 行）说的
  @{verbatim "step op0 s0 = {s0, s1}"}。为什么要拆成两半？
  因为 @{verbatim "step"} 的定义（24.4 抄过）是
  @{verbatim "step' cmd s \<union> {s}"} 那一路的分支和，
  直接证等式要同时管"合法时得到什么"和"非法时什么都不变"，
  拆开之后 @{verbatim "safe"} 那半边只用
  @{verbatim "split: if_split_asm"} 就能收敛。
\<close>

text \<open>
  这一节最值得抄的是它\emph{停下来}的地方，三处都是白纸黑字：

  \begin{enumerate}
  \item @{verbatim "ops"} 的上一行是一段注释（第 133 行）：
    "since the CDT isn't defined, op6 is skipped"。
    @{verbatim "op6"}（`l4v/spec/take-grant/Example2.thy` 第 118 行）是
    唯一一条 @{verbatim "SysRevoke"}，而 revoke 的正确语义要依赖
    capability derivation tree 的删除顺序；模型里没有 CDT，于是 op6 那一段
    留了四个 @{verbatim "oops"}：@{verbatim "execute_op6_safe"}
    （`l4v/spec/take-grant/Example2.thy` 第 537 行）、两条同名的
    @{verbatim "execute_op6_live"}（第 544 与 552 行，第二条换了陈述）、
    以及合成式 @{verbatim "execute_op6"}
    （`l4v/spec/take-grant/Example2.thy` 第 556 行）。
  \item 第 532 行那句注释写着 @{verbatim "SysRevoke 0 (read_cap 2)"}，
    可第 118 行的定义是 @{verbatim "write_cap"}。注释和定义不一致，
    而定义才是被证明引用的那一份。
  \item @{verbatim "into_rtrancl2"}（`l4v/spec/take-grant/Example2.thy` 第 749 行）
    也停在一个 @{verbatim "oops"}，它前面第 751 行还留着一条
    @{verbatim "thm"} 调试命令——作者在这里卡住时打印过规则。
  \end{enumerate}

  这五处 @{verbatim "oops"} 不影响最终结论，因为结论不需要它们：
  终态 @{verbatim "s"} 到得了，靠的是 @{verbatim "s7"}（`l4v/spec/take-grant/Example2.thy` 第 73 行）
  和 @{verbatim "s10"}（`l4v/spec/take-grant/Example2.thy` 第 90 行）都被定义成
  @{verbatim "s4"}——于是 @{verbatim "ops"} 里跳过 op4、op5、op6 之后链条仍然接得上，
  @{verbatim "execute_ops"}（`l4v/spec/take-grant/Example2.thy` 第 689 行）证明里那句
  @{verbatim "simp add: s7_def"} 干的就是把 @{verbatim "s7"} 折回
  @{verbatim "s4"} 这一件事。
\<close>

text \<open>
  有了终态，剩下的三步就是本章的结论在真实文件里的样子：
  @{verbatim "island_e0"}（`l4v/spec/take-grant/Example2.thy` 第 1071 行）
  算出 0 的孤岛是 @{verbatim "{i. i \<noteq> 1 \<and> i \<noteq> 2}"}——注意它把
  根本不存在的实体也算进去了，因为 @{verbatim "island"} 走的是
  连接闭包，而空实体的 @{verbatim "caps_of"} 是空的；
  @{verbatim "flow_in_inv_image"}（`l4v/spec/take-grant/Example2.thy` 第 1174 行）
  把 @{verbatim "flow s"} 压进 @{verbatim "inv_image Id (\<lambda>x. x = 1 \<or> x = 2)"}，
  意思是"数据流只能在 @{verbatim "{1,2}"} 内部或者它外部走，跨不过去"；
  最后 @{verbatim "e0_e1_isolated"}（`l4v/spec/take-grant/Example2.thy` 第 1203 行）
  套 24.9 那条 @{verbatim "information_flow"}
  （`l4v/spec/take-grant/Isolation_S.thy` 第 100 行），
  对 @{verbatim "execute cmds s"} 里的一切运行同时关掉两个方向。
  中间还夹了一条 @{verbatim "e0_e1_leakage"}（第 1058 行），
  它用的是 24.7 的 @{verbatim "leakage_rule"}
  （`l4v/spec/take-grant/Confine_S.thy` 第 1000 行）：0 与 1 之间连一次
  @{verbatim "leak"} 都没有，比"没有数据流"更强。
\<close>

text \<open>
  再说 C 内核。@{verbatim "rights"} 那六个权利在实现里不是一个通用位段，
  而是每种能力各自决定要不要留位。四条锚点：

  \begin{itemize}
  \item @{verbatim "endpoint_cap"}（`seL4/include/object/structures_64.bf` 第 24 行）
    里有四个 1 位字段：@{verbatim "capCanGrantReply"}、@{verbatim "capCanGrant"}、
    @{verbatim "capCanReceive"}、@{verbatim "capCanSend"}。
  \item @{verbatim "cnode_cap"}（`seL4/include/object/structures_64.bf` 第 71 行）
    \emph{没有}任何权利位，只有 radix、guard、guard size 和指针。
  \item @{verbatim "maskCapRights"}（`seL4/src/object/objecttype.c` 第 441 行）
    对 @{verbatim "cap_cnode_cap"} 那一长串 case 直接
    @{verbatim "return cap"}，只有 endpoint 与 reply 两类会真的把
    @{verbatim "capCanSend"} 与 @{verbatim "capAllowWrite"}、
    @{verbatim "capCanReceive"} 与 @{verbatim "capAllowRead"} 相与。
  \item 用户传进来的那一个字靠 @{verbatim "rightsFromWord"}
    （`seL4/include/api/types.h` 第 52 行）包成
    @{verbatim "seL4_CapRights"}，四个允许位在
    `seL4/libsel4/mode_include/64/sel4/shared_types.bf` 第 25 行附近的
    @{verbatim "capAllowWrite"} 那一组里；@{verbatim "seL4_CapRights_t"}
    （`seL4/include/api/types.h` 第 20 行）那句注释写的路径
    @{verbatim "mode/api/shared_types.bf"} 是历史遗留，
    今天真实的文件在 @{verbatim "libsel4/mode_include/64/"} 下面。
  \end{itemize}

  于是 24.2 里那句"抽象模型有六个权利"与实现的关系是：Take/Grant 对应
  endpoint 能力的两个 @{verbatim "CanGrant"} 位，Read/Write 对应
  @{verbatim "CanReceive/CanSend"}，Create 大致对应 untyped 的重新分配，
  @{verbatim "Store"} 则对应"@{verbatim "decodeCNodeInvocation"}
  （`seL4/src/object/cnode.c` 第 42 行）这条路径上根本没有权利可掩"这件事。
  这不是精化，是比喻：@{verbatim "cnode_cap"} 不存权利，
  而 CNode 调用里第 124 行那句 @{verbatim "rightsFromWord"} 与
  第 125 行的 @{verbatim "maskCapRights"} 只作用在被复制的那条能力上，
  和模型里一条 @{verbatim "cap"} 记录带着 @{verbatim "rights"} 字段的形状
  不是一张表。
\<close>

text \<open>
  最后把"没有证明"列清楚，四条：

  \begin{enumerate}
  \item README 末尾那条免责声明（`l4v/spec/take-grant/README.md` 第 41 行）：
    这份规范 @{verbatim "*not* connected with the seL4 code"}，
    也 @{verbatim "*not* completely describe seL4 behaviour"}。
    它上面没有任何精化定理；精化链在另一份 ROOT 里，
    @{verbatim "Refine"} 那一路（`l4v/proof/ROOT` 第 29 行）从头到尾
    没有 import 过 take-grant 的任何理论。
    同一份 README 第 20 行起的分工表还有一处笔误：它把文件名写成了
    @{verbatim "Isolations_S"}（`l4v/spec/take-grant/README.md` 第 24 行），
    磁盘上的真实文件是单数的 @{verbatim "Isolation_S.thy"}，
    照着 import 会直接失败。
  \item 实体是扁平的 @{verbatim "cap set"}，没有 CNode 深度、guard、
    index 这些概念，所以"能不能构造出某条能力"这类实现层的攻击面
    在本章完全没有被建模。
  \item @{verbatim "Example2"} 只算了 @{verbatim "ops"} 那一条固定序列到达的
    终态，加上一条关于任意 @{verbatim "cmds"} 的 @{verbatim "execute"} 结论；
    它不是"任何策略都隔离"，而是"从这个起点出发、任何后续调用串都隔离"。
    起点本身是否可达，模型不管。
  \item 六个权利里没有 x86 的 IO port、页表、@{verbatim "ASID"} 这些概念，
    @{verbatim "all_rights"}（`l4v/spec/take-grant/System_S.thy` 第 57 行）
    就是 @{verbatim "Read/Write/Take/Grant/Create/Store"} 六个，
    再多一个都没有。
  \end{enumerate}

  这四条不是本章的缺点，是 24.1 定下的口吻：take-grant 证的是权威约束
  这一层\emph{概念}为什么站得住，第 17 到 22 章那条精化链证的才是
  这台内核。两件事，别混着说。
\<close>

ML \<open>writeln "==== 24.10 段落 ===="\<close>

ML \<open>writeln "==== 24 结束 ===="\<close>

end

