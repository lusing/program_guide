theory T36_corec_friends
  imports "HOL-Library.BNF_Corec" "HOL-Library.Stream"
begin

section \<open>36.1 corec 的三档：守卫、友元与混合递归\<close>

text \<open>第 26 章的 @{verbatim "primcorec"} 只会"逐层吐构造子"。corec 手册
（corec.pdf）的主线是它的升级版 @{verbatim "corec"}，三档火力：

  1. **守卫递归**：@{verbatim "if"} 分支下递归（primcorec 做不到）；
  2. **友元（friends）**：递归调用出现在**别的共递归函数**的参数里
     ——该函数先注册成友元，"递归上下文"随之扩大；
  3. **混合递归-共递归**（@{verbatim "corecursive"}）：允许裸递归调用，
     代价是手证终止性（对"消耗输入"的度量）。

本章在自定义 @{verbatim "llist"} 与库 @{verbatim "stream"} 上把三档
全部实测。本理论属于 @{verbatim "IsaTutLib"} 会话（父堆 HOL-Library）：
@{verbatim "corec"}/@{verbatim "friend_of_corec"} 注册在
@{verbatim "HOL-Library.BNF_Corec"}，**不在 Main**（实测裸 HOL 里
@{verbatim "corec"} 报 outer syntax error）。\<close>

ML \<open>writeln "==== 36 开始 ===="\<close>

subsection \<open>36.2 自定义 llist 与 corec 的第一档\<close>

text \<open>带收集器 @{verbatim "lset"} 的惰性表。@{verbatim "corec"} 的方程
用 @{verbatim "case"} 拆输入、右端递归藏在构造器后面——注意
@{verbatim "primcorec"} **不接受构造子模式方程**（实测报
@{verbatim "Non-variable function argument on left-hand side"}；
现代 primcorec 只认选择子/判别式方程），双构造子类型用
@{verbatim "corec"} + @{verbatim "case"} 最顺：\<close>

codatatype (lset: 'a) llist =
  LNil
| LCons (lhd: 'a) (ltl: "'a llist")

corec lmap :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a llist \<Rightarrow> 'b llist" where
  "lmap f xs = (case xs of LNil \<Rightarrow> LNil | LCons y ys \<Rightarrow> LCons (f y) (lmap f ys))"

text \<open>守卫递归（第一档）：@{verbatim "if"} 分支 + 基础情形 @{verbatim "LNil"}。\<close>

corec upto :: "nat \<Rightarrow> nat llist" where
  "upto i = (if i = 0 then LNil else LCons i (upto (i - 1)))"

lemma upto_head: "lhd (upto 3) = 3"
  by (subst upto.code) simp

subsection \<open>36.3 友元：把递归上下文扩大\<close>

text \<open>库 @{verbatim "stream"}（单构造子，@{verbatim "##"}）是友元的
主场——官方 @{verbatim "Corec_Examples/Paper_Examples.thy"} 全在这里做。
注册友元只要 @{verbatim "corec (friend)"}，**无需显式证明**（stream 的
transfer 设施齐全，义务被默认策略自动消掉）：\<close>

corec (friend) add1s :: "nat stream \<Rightarrow> nat stream" where
  "add1s ns = (shd ns + 1) ## add1s (stl ns)"

corec (friend) plus_s :: "nat stream \<Rightarrow> nat stream \<Rightarrow> nat stream" where
  "plus_s xs ys = (shd xs + shd ys) ## plus_s (stl xs) (stl ys)"

text \<open>注册之后，@{verbatim "corec"} 的右端可以**在友元函数的参数里**
递归——这就是"友元扩大递归上下文"。教科书例子：自然数流不必逐个加一，
交给 @{verbatim "add1s"}：\<close>

corec natsFrom2 :: "nat \<Rightarrow> nat stream" where
  "natsFrom2 n = n ## add1s (natsFrom2 n)"

text \<open>斐波那契流——右端递归同时藏在 @{verbatim "plus_s"} 的两个参数里，
友元注册后一个方程搞定：\<close>

corec fibS :: "nat stream" where
  "fibS = plus_s (0 ## 1 ## fibS) (0 ## fibS)"

subsection \<open>36.4 证引理：subst 单步展开，别让 simp 全家桶上场\<close>

text \<open>@{verbatim "corec"} 的 @{verbatim ".code"} 方程是**无穷展开**的：
@{verbatim "simp add: fibS.code"} 一挂，化简器追着流无限展开（实测
构建挂死到被超时打断）。安全姿势是 @{verbatim "subst"} 单步换掉
要算的那一层，剩下的交给构造子选择子规则：\<close>

lemma nats_head: "shd (natsFrom2 5) = 5"
  by (subst natsFrom2.code) simp

lemma fib_head: "shd fibS = 0"
  by (subst fibS.code, subst plus_s.code) simp

subsection \<open>36.5 corecursive：裸递归的代价\<close>

text \<open>过滤惰性表是 corec 手册的招牌：@{verbatim "else"} 分支的
@{verbatim "lfilter P (ltl xs)"} 是**裸递归**（不在构造器也不在友元后），
@{verbatim "corec"} 拒收，必须用 @{verbatim "corecursive"} 并手证
"消耗输入"的终止性。下面是官方 @{verbatim "Corec_Examples/LFilter.thy"}
的原文（度量：到下一个满足 P 的元素的距离）：\<close>

corecursive lfilter where
  "lfilter P xs = (if \<forall>x \<in> lset xs. \<not> P x then
    LNil
    else if P (lhd xs) then
      LCons (lhd xs) (lfilter P (ltl xs))
    else
      lfilter P (ltl xs))"
proof (relation "measure (\<lambda>(P, xs). LEAST n. P (lhd ((ltl ^^ n) xs)))", rule wf_measure, clarsimp)
  fix P xs x
  assume "x \<in> lset xs" "P x" "\<not> P (lhd xs)"
  from this(1,2) obtain a where "P (lhd ((ltl ^^ a) xs))"
    by (atomize_elim, induct x xs rule: llist.set_induct)
       (auto simp: funpow_Suc_right simp del: funpow.simps(2) intro: exI[of _ 0] exI[of _ "Suc i" for i])
  with \<open>\<not> P (lhd xs)\<close>
    have "(LEAST n. P (lhd ((ltl ^^ n) xs))) = Suc (LEAST n. P (lhd ((ltl ^^ Suc n) xs)))"
    by (intro Least_Suc) auto
  then show "(LEAST n. P (lhd ((ltl ^^ n) (ltl xs)))) < (LEAST n. P (lhd ((ltl ^^ n) xs)))"
    by (simp add: funpow_swap1[of ltl])
qed

text \<open>读法：度量取"离下一个满足谓词的元素还有几步"（@{verbatim "LEAST"}
找第一个满足的下标，@{verbatim "Least_Suc"} 说明跳过头一步后距离恰减一）。
定义之后 @{verbatim "lfilter.code"} 可当方程用（依然要 @{verbatim "subst"}
单步）。官方接着证三条化简引理；第二条的 @{verbatim "auto"} 暗中依赖
一条隐藏前提——@{verbatim "lfilter P xs = LNil"} 的判定引理。教学版
直接把它的**充分方向**立成条件化简规则，一行等价服务本场景：\<close>

lemma lfilter_LNil [simp]: "lfilter P LNil = LNil"
  by(simp add: lfilter.code)

lemma lfilter_none_cond [simp]:
  "(\<forall>x\<in>lset xs. \<not> P x) \<Longrightarrow> lfilter P xs = LNil"
  by (simp add: lfilter.code)

lemma lfilter_LCons [simp]: "lfilter P (LCons x xs) = (if P x then LCons x (lfilter P xs) else lfilter P xs)"
  by(subst lfilter.code)(auto intro: sym)

subsection \<open>36.6 坑位清单（实测）\<close>

text \<open>1. @{verbatim "corec"}/@{verbatim "friend_of_corec"} 不在 Main：
   裸 HOL 里报 outer syntax error；本理论走 HOL-Library 会话。
2. @{verbatim "primcorec"} 拒绝构造子模式方程
   （@{verbatim "Non-variable function argument on left-hand side"}）；
   双构造子共数据类型用 @{verbatim "corec"} + @{verbatim "case"}。
3. **自定义共数据类型上的友元默认策略打不动**：同款加一在库 stream 上
   免证明，在自定义 llist 上报 @{verbatim "Tactic failed"}（尊重义务要
   自己补 transfer 规则）。教学示例的友元全放 stream 上做。
4. @{verbatim "simp add: foo.code"} 对 corec 方程**发散**（无穷展开，
   实测挂死）；用 @{verbatim "subst foo.code"} 单步。
5. 流的 cons 是 @{verbatim "##"}；@{verbatim "<lhd>"} 是个别文件的自定义
   记号，别处使用直接词法错误。
6. **照抄官方片段要抄全**：lfilter 的三条化简引理环环相扣——少了
   中间那条判定引理，第三条的 @{verbatim "auto"} 当场卡住
   （实测目标剩 @{verbatim "LNil = lfilter P xs"}）。官方证明的依赖
   不是注释里的"读法"，而是前一条 [simp]。
7. @{verbatim "corecursive"} 的度量证明用 @{verbatim "LEAST"} +
   @{verbatim "Least_Suc"}：这是"消耗输入直到触发条件"的标准度量模板，
   换业务时照抄骨架。
8. @{verbatim "value"} 对无穷流**不可用**（急切求值跑不完）——
   观察流要用引理（@{verbatim "shd/stl"} 的 subst 链），
   或 Library 的 @{verbatim "Code_Lazy"}（超出本章）。\<close>

thm upto_head nats_head fib_head lfilter_LCons

ML \<open>writeln "==== 36 结束 ===="\<close>

end
