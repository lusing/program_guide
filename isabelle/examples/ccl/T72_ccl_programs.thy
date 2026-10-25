theory T72_ccl_programs
  imports "IsaTutCCL.Nat" "IsaTutCCL.List" "IsaTutCCL.Stream" "IsaTutCCL.Flag"
begin

section \<open>72.1 四个例子理论：CCL 库的"毕业设计"\<close>

text \<open>前四章（69–71）把 CCL 库的**机制**讲完了：集合与不动点、
无类型 λ 演算、类型系统、良基关系、不动点归纳。本章讲**用法**——
库在 @{verbatim "src/CCL/ex/"} 下放了四个完整例子，每一个都是一篇
小论文：

@{verbatim "ex/Nat.thy"}（109 行）在自然数上定义算术与比较，
并用 @{verbatim typechk} 证明它们保类型、用 @{verbatim NatPR}
证明它们终止；
@{verbatim "ex/List.thy"}（121 行）定义 map / append / filter /
flat / insert / isort / partition / qsort；
@{verbatim "ex/Stream.thy"}（137 行）定义两个迭代函数，并用
**余归纳**证明无穷流上的等式；
@{verbatim "ex/Flag.thy"}（76 行）把 Dijkstra 的荷兰国旗问题
改写成列表版（库自己的吐槽：原例的精髓是用数组，这里只能用列表）。

四个理论的依赖链是一条直线：
@{verbatim "Nat"} → @{verbatim "List"} → @{verbatim "Stream"} / @{verbatim "Flag"}。
本章把它们逐个拆开。\<close>

ML \<open>writeln "==== 72 开始 ===="\<close>

thm not_def add_def mult_def sub_def le_def lt_def div_def ackermann_def
thm map_def comp_def append_def member_ax filter_def flat_def
thm partition_def insert_def isort_def qsort_def
thm iter1_def iter2_def


subsection \<open>72.2 Nat 上的程序：定义\<close>

text \<open>库源码 @{verbatim "src/CCL/ex/Nat.thy"} 第 12–19 行，七个定义
两种写法。**非递归**的用 @{verbatim nrec}（第 70 章的原始递归子）：

@{verbatim "definition not :: \"i\<Rightarrow>i\""}
@{verbatim "  where \"not(b) == if b then false else true\""}
@{verbatim "definition add :: \"[i,i]\<Rightarrow>i\"  (infixr \<open>#+\<close> 60)"}
@{verbatim "  where \"a #+ b == nrec(a, b, \<lambda>x g. succ(g))\""}
@{verbatim "definition mult :: \"[i,i]\<Rightarrow>i\"  (infixr \<open>#*\<close> 60)"}
@{verbatim "  where \"a #* b == nrec(a, zero, \<lambda>x g. b #+ g)\""}

@{verbatim add} 读作"对第一个参数递归：递归到 0 返回第二个参数，
每层多套一个 @{verbatim succ}"——就是结构递归版的加法。
@{verbatim mult} 则是"把 @{verbatim b} 连加 @{verbatim a} 次"。

**递归的**（自己调用自己）必须用 @{verbatim letrec}：

@{verbatim "definition sub :: \"[i,i]\<Rightarrow>i\"  (infixr \<open>#-\<close> 60)"}
@{verbatim "  where"}
@{verbatim "    \"a #- b =="}
@{verbatim "      letrec sub x y be ncase(y, x, \<lambda>yy. ncase(x, zero, \<lambda>xx. sub(xx,yy)))"}
@{verbatim "      in sub(a,b)\""}

@{verbatim sub} 的递归结构值得细看：先对 @{verbatim y} 分情况——
@{verbatim y} 是 @{verbatim zero} 就直接返回 @{verbatim x}（减光了）；
否则再对 @{verbatim x} 分情况，@{verbatim x} 是 @{verbatim zero} 说明
"减出负数了"，库选择**返回零**（截断减法，源第 78 行的注释
@{verbatim "(* Defined to return zero if a<b *)"}）。
@{verbatim le} / @{verbatim lt} 是同一模板（源第 27–34 行），
@{verbatim div} 和 @{verbatim ackermann}（源第 36–47 行）稍复杂但同构：

@{verbatim "definition div :: \"[i,i]\<Rightarrow>i\"  (infixr \<open>##\<close> 60)"}
@{verbatim "  where"}
@{verbatim "    \"a ## b =="}
@{verbatim "      letrec div x y be if x #< y then zero else succ(div(x#-y,y))"}
@{verbatim "      in div(a,b)\""}

@{verbatim ackermann} 是双重递归，两个参数互相递归——
正是它让普通的原始递归子 @{verbatim nrec} 不够用。\<close>

thm not_def add_def mult_def sub_def le_def lt_def div_def ackermann_def


subsection \<open>72.3 natBs：哪些函数能算，哪些不能\<close>

text \<open>库源码第 49–60 行把可计算的函数打包成一条 simp 规则集：

@{verbatim "lemmas nat_defs = not_def add_def mult_def sub_def le_def lt_def ackermann_def napply_def"}

@{verbatim "lemma natBs [simp]:"}
@{verbatim "  \"not(true) = false\""}
@{verbatim "  \"not(false) = true\""}
@{verbatim "  \"zero #+ n = n\""}
@{verbatim "  \"succ(n) #+ m = succ(n #+ m)\""}
@{verbatim "  \"zero #* n = zero\""}
@{verbatim "  \"succ(n) #* m = m #+ (n #* m)\""}
@{verbatim "  \"f^zero`a = a\""}
@{verbatim "  \"f^succ(n)`a = f(f^n`a)\""}
@{verbatim "  by (simp_all add: nat_defs)"}

注意这条规则集**只覆盖 @{verbatim not} / @{verbatim add} /
@{verbatim mult} / @{verbatim napply}**，@{verbatim sub} / @{verbatim le} /
@{verbatim lt} / @{verbatim div} / @{verbatim ackermann} 一条都没有。
原因在第 70 章已经踩过：后几个用 @{verbatim letrec} 定义，
@{verbatim letrecB} 会把 @{verbatim "fix(...)"} 无限展开，
不能进 simp 集。这不是疏漏，是**有意的设计取舍**——
下面四个计算演示全部落在"能算"的那一侧：\<close>

lemma not_demo: "not(true) = false"
  by simp

lemma add_demo: "succ(succ(zero)) #+ succ(succ(zero)) = succ(succ(succ(succ(zero))))"
  by simp

lemma mult_demo: "succ(succ(zero)) #* succ(succ(zero)) = succ(succ(succ(succ(zero))))"
  by simp

lemma napply_demo: "succ ^ succ(succ(zero)) ` zero = succ(succ(zero))"
  by simp

text \<open>反过来，把 @{verbatim "sub"} 交给 @{verbatim simp}
（哪怕连 @{verbatim nat_defs} 一起给）只会得到展开到一半的
@{verbatim letrec}，此后再无规则可施——库因此没给
@{verbatim sub} / @{verbatim le} / @{verbatim lt} / @{verbatim div} /
@{verbatim ackermann} 任何计算规则。\<close>


subsection \<open>72.4 类型保持：typechk 战术\<close>

text \<open>库源码第 68–96 行，五个类型定理形状完全一样：
"两个 Nat 进去，一个 Nat/Bool 出来"。证明全是三行：

@{verbatim "lemma addT: \"\<lbrakk>a:Nat; b:Nat\<rbrakk> \<Longrightarrow> a #+ b : Nat\""}
@{verbatim "  apply (unfold add_def)"}
@{verbatim "  apply typechk"}
@{verbatim "  done"}

@{verbatim typechk} 是 @{verbatim Wfd.thy} 第 482–484 行定义的
@{verbatim method_setup}，它把第 71 章的 @{verbatim ncaseT} /
@{verbatim lrecT} 等类型规则按目标形状自动拼起来。
**关键在于 @{verbatim "unfold add_def"}**：不先把定义展开，
@{verbatim typechk} 看到的只是一个陌生的常量 @{verbatim "#+"}，
无从下手。这也是本章第一条实用经验：

@{verbatim "unfold 定义 → typechk → （必要时）clean_ccs + 良基证明"}

下面把四个类型定理原样复用一遍（这一步什么新东西都没证明，
目的是让读者看到"库的定理可以直接当地基用"）：\<close>

lemma add_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #+ b : Nat"
  by (rule addT)

lemma mult_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #* b : Nat"
  by (rule multT)

lemma le_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #<= b : Bool"
  by (rule leT)

lemma lt_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #< b : Bool"
  by (rule ltT)


subsection \<open>72.5 终止性：NatPR 三件套\<close>

text \<open>@{verbatim sub} / @{verbatim le} 是**自己调用自己**的，
@{verbatim typechk} 只能证明"如果递归调用有类型，那整体有类型"，
剩下的义务是"递归确实停下来"。库源码第 79–84 行（@{verbatim leT} 在第 86–91 行，同款）：

@{verbatim "lemma subT: \"\<lbrakk>a:Nat; b:Nat\<rbrakk> \<Longrightarrow> a #- b : Nat\""}
@{verbatim "  apply (unfold sub_def)"}
@{verbatim "  apply typechk"}
@{verbatim "  apply clean_ccs"}
@{verbatim "  apply (erule NatPRI [THEN wfstI, THEN NatPR_wf [THEN wmap_wf, THEN wfI]])"}
@{verbatim "  done"}

拆开最后那行 @{verbatim OF} 链（从右往左读）：

@{verbatim "NatPR_wf"}：前驱关系 @{verbatim "NatPR = {p. EX x:Nat. p=<x,succ(x)>}"}
在 Nat 上良基（源第 71.7 节引过）；
@{verbatim "wmap_wf"}：经函数映射保持良基；
@{verbatim "wfI"}：把良基判据兑现成集合包含；
@{verbatim "wfstI"}：把"对第一个分量递减"升级成"对序对递减"；
@{verbatim "NatPRI"}：给出具体的递减序对 @{verbatim "<t, h$t>"} 形状的见证。

@{verbatim clean_ccs}（源第 566 行前后的 @{verbatim method_setup}）
负责把 @{verbatim letrec} 产生的"干净性副条件"清掉。
这一套（@{verbatim clean_ccs} + 良基链）就是 CCL 里证明
**递归函数终止**的标准动作，第 72.6 节的 ackermann 和第 72.11 节的
荷兰国旗用的都是它。\<close>

thm NatPR_def NatPR_wf NatPRI wfstI wmap_wf wfI


subsection \<open>72.6 ackermann：字典序 \<close>

text \<open>Ackermann 函数的终止性不能靠单一递减关系——
它的两个递归调用中，一个减 @{verbatim n}、一个加 @{verbatim m}，
是典型的**字典序**形状。库源码第 99–107 行先造一条复合良基关系：

@{verbatim "lemmas relI = NatPR_wf [THEN NatPR_wf [THEN lex_wf, THEN wfI]]"}

读作：@{verbatim "ra ** rb"} 良基，若 @{verbatim ra} 与 @{verbatim rb}
都良基（第 71.7 节的 @{verbatim lex_wf}）。然后：

@{verbatim "lemma \"\<lbrakk>a:Nat; b:Nat\<rbrakk> \<Longrightarrow> ackermann(a,b) : Nat\""}
@{verbatim "  apply (unfold ackermann_def)"}
@{verbatim "  apply gen_ccs"}
@{verbatim "  apply (erule NatPRI [THEN lexI1 [THEN relI]] NatPRI [THEN lexI2 [THEN relI]])+"}
@{verbatim "  done"}

@{verbatim lexI1} / @{verbatim lexI2} 分别覆盖字典序的两支：
第一分量严格递减，或第一分量相同、第二分量递减。
两个递归调用正好一支一支。@{verbatim gen_ccs} 是
@{verbatim typechk} 的加强版（源第 566 行附近），
额外接受要用的类型定理作参数。\<close>

thm lex_def lex_wf lexI1 lexI2 relI


subsection \<open>72.7 List 上的程序：定义\<close>

text \<open>库源码 @{verbatim "src/CCL/ex/List.thy"} 第 12–28 行。
非递归的（对列表结构递归的）用 @{verbatim lrec}：

@{verbatim "definition map :: \"[i\<Rightarrow>i,i]\<Rightarrow>i\""}
@{verbatim "  where \"map(f,l) == lrec(l, [], \<lambda>x xs g. f(x)$g)\""}
@{verbatim "definition append :: \"[i,i]\<Rightarrow>i\"  (infixr \<open>@\<close> 55)"}
@{verbatim "  where \"l @ m == lrec(l, m, \<lambda>x xs g. x$g)\""}
@{verbatim "definition filter :: \"[i,i]\<Rightarrow>i\""}
@{verbatim "  where \"filter(f,l) == lrec(l, [], \<lambda>x xs g. if f`x then x$g else g)\""}
@{verbatim "definition flat :: \"i\<Rightarrow>i\""}
@{verbatim "  where \"flat(l) == lrec(l, [], \<lambda>h t g. h @ g)\""}

注意 @{verbatim map} 的第一个参数是 **HOL 函数** @{verbatim "i\<Rightarrow>i"}
（所以 @{verbatim "map(succ, l)"} 能直接写），而 @{verbatim filter} 的
谓词参数是 **CCL 项**（要用 `` f`x `` 施加，所以得写
@{verbatim "lam x. ..."}）——这个不对称在第 72.10 节还会再咬一次。

两个比较函数的例子用 @{verbatim letrec}：

@{verbatim "definition partition :: \"[i,i]\<Rightarrow>i\" where"}
@{verbatim "  \"partition(f,l) == letrec part l a b be lcase(l, <a,b>, \<lambda>x xs."}
@{verbatim "                            if f`x then part(xs,x$a,b) else part(xs,a,x$b))\""}
@{verbatim "                    in part(l,[],[])\""}

@{verbatim partition} 把 @{verbatim l} 按谓词 @{verbatim f} 劈成两截，
用的是**双累加器** @{verbatim a} / @{verbatim b}；快排
@{verbatim qsort}（源第 41–45 行）则是它加自身递归：

@{verbatim "definition qsort :: \"i\<Rightarrow>i\" where"}
@{verbatim "  \"qsort(f) == lam l. letrec qsortx l be lcase(l, [], \<lambda>h t."}
@{verbatim "                                   let p be partition(f`h,t)"}
@{verbatim "                                   in split(p, \<lambda>x y. qsortx(x) @ h$qsortx(y)))\""}
@{verbatim "                          in qsortx(l)\""}\<close>

thm map_def comp_def append_def member_ax filter_def flat_def
thm partition_def insert_def isort_def qsort_def


subsection \<open>72.8 listBs 与计算\<close>

text \<open>库源码第 47–63 行，与 @{verbatim natBs} 同构：

@{verbatim "lemmas list_defs = map_def comp_def append_def filter_def flat_def"}
@{verbatim "  insert_def isort_def partition_def qsort_def"}

@{verbatim "lemma listBs [simp]:"}
@{verbatim "  \"\<And>f g. (f \<circ> g) = (\<lambda>a. f(g(a)))\""}
@{verbatim "  \"\<And>f. map(f,[]) = []\""}
@{verbatim "  \"\<And>f x xs. map(f,x$xs) = f(x)$map(f,xs)\""}
@{verbatim "  \"\<And>m. [] @ m = m\""}
@{verbatim "  \"\<And>x xs m. x$xs @ m = x$(xs @ m)\""}
@{verbatim "  \"\<And>f. filter(f,[]) = []\""}
@{verbatim "  \"\<And>f x xs. filter(f,x$xs) = if f`x then x$filter(f,xs) else filter(f,xs)\""}
@{verbatim "  \"flat([]) = []\""}
@{verbatim "  \"\<And>x xs. flat(x$xs) = x @ flat(xs)\""}
@{verbatim "  \"\<And>a f. insert(f,a,[]) = a$[]\""}
@{verbatim "  \"\<And>a f xs. insert(f,a,x$xs) = if f`a`x then a$x$xs else x$insert(f,a,xs)\""}
@{verbatim "  by (simp_all add: list_defs)"}

@{verbatim map} / @{verbatim append} / @{verbatim flat} / @{verbatim insert} /
@{verbatim filter} 都能算；@{verbatim isort} / @{verbatim qsort} /
@{verbatim partition} 含 @{verbatim letrec}，算不动。
四个计算演示：\<close>

lemma map_demo: "map(succ, zero $ succ(zero) $ []) = succ(zero) $ succ(succ(zero)) $ []"
  by simp

lemma append_demo: "zero$[] @ succ(zero)$[] = zero $ succ(zero) $ []"
  by simp

lemma flat_demo: "flat(zero $ (succ(zero)$[]) $ []) = zero @ (succ(zero) $ [])"
  by simp

lemma insert_demo:
  "insert(lam x. lam y. true, zero, succ(zero)$[]) = zero $ succ(zero) $ []"
  by simp

text \<open>@{verbatim insert} 那一支把比较函数写死成 @{verbatim true}
（"总是插到前面"），于是 @{verbatim "if f`a`h"} 直接归约；
这也反证了第 72.3 节的取舍——想让 @{verbatim insert} 真正按大小插入，
得先让 @{verbatim "#<="} 可计算，而库刻意没给。\<close>

thm map_def append_def filter_def flat_def insert_def isort_def


subsection \<open>72.9 有限列表用归纳，无穷流用余归纳\<close>

text \<open>这是本章最重要的一节。第 71.2 节说过：
@{verbatim "List(A) == lfp(...)"}（有限），
@{verbatim "Lists(A) == gfp(...)"}（含无穷）。两类列表的证明方法
因此完全不同：有限的用 @{verbatim List_ind} 归纳，
无穷的用 @{verbatim eq_coinduct3} 余归纳。

库在 @{verbatim "ex/Stream.thy"} 里给无穷版证了三条
（@{verbatim map_comp} / @{verbatim map_id} / @{verbatim map_append}），
全是 apply 风格。这里先把**有限版**用 Isar 写出来当对照——
同一条命题，归纳证明只多几行，且每一步都能说清：\<close>

lemma map_id_finite_demo: "l : List(A) \<Longrightarrow> map((\<lambda>x. x), l) = l"
proof (erule List_ind)
  show "map((\<lambda>x. x), []) = []" by simp
  fix x xs assume "x:A" "xs:List(A)" and ih: "map((\<lambda>x. x), xs) = xs"
  show "map((\<lambda>x. x), x$xs) = x$xs" by (simp add: ih)
qed

lemma map_comp_finite_demo:
  "l : List(A) \<Longrightarrow> map((\<lambda>x. f(g(x))), l) = map(f,map(g,l))"
proof (erule List_ind)
  show "map((\<lambda>x. f(g(x))), []) = map(f,map(g,[]))" by simp
  fix x xs assume "x:A" "xs:List(A)"
    and ih: "map((\<lambda>x. f(g(x))), xs) = map(f,map(g,xs))"
  show "map((\<lambda>x. f(g(x))), x$xs) = map(f,map(g,x$xs))" by (simp add: ih)
qed

lemma append_assoc_finite_demo:
  "\<lbrakk>k:List(A); l:List(A); m:List(A)\<rbrakk> \<Longrightarrow> k @ l @ m = (k@l) @ m"
proof (erule List_ind)
  show "[] @ l @ m = ([]@l) @ m" by simp
  fix x xs assume "x:A" "xs:List(A)" "l:List(A)" "m:List(A)"
    and ih: "xs @ l @ m = (xs@l) @ m"
  show "x$xs @ l @ m = (x$xs@l) @ m" by (simp add: ih)
qed

text \<open>三条的证法一模一样：@{verbatim "erule List_ind"} 把目标按
列表结构拆成空表一支与 @{verbatim "x$xs"} 一支，基例 @{verbatim simp}
（@{verbatim listBs} 里 @{verbatim "map(f,[]) = []"}、
@{verbatim "[] @ m = m"}），步进支 @{verbatim "simp add: ih"}
把归纳假设喂进去。**换成无穷列表，这套立刻失效**——
@{verbatim List_ind} 的归纳假设只覆盖有限层，
而一条无穷流有穷层永不到头。\<close>

thm List_ind ListsXH IListsXH


subsection \<open>72.10 流：iter1、iter2 与余归纳\<close>

text \<open>库源码 @{verbatim "src/CCL/ex/Stream.thy"} 第 12–16 行定义两个
"从一个起点产生无穷流"的函数，写法不同、语义相同：

@{verbatim "definition iter1 :: \"[i\<Rightarrow>i,i]\<Rightarrow>i\""}
@{verbatim "  where \"iter1(f,a) == letrec iter x be x$iter(f(x)) in iter(a)\""}
@{verbatim "definition iter2 :: \"[i\<Rightarrow>i,i]\<Rightarrow>i\""}
@{verbatim "  where \"iter2(f,a) == letrec iter x be x$map(f,iter(x)) in iter(a)\""}

@{verbatim iter1} 直接递归调用自己，@{verbatim iter2} 先把 @{verbatim f}
通过 @{verbatim map} 施加到尾部再递归。两者的一步展开规则
（源第 108–118 行）就是 @{verbatim letrecB} 的直接推论：

@{verbatim "lemma iter1B: \"iter1(f,a) = a$iter1(f,f(a))\""}
@{verbatim "  apply (unfold iter1_def)"}
@{verbatim "  apply (rule letrecB [THEN trans])"}
@{verbatim "  apply simp"}
@{verbatim "  done"}

@{verbatim "lemma iter2B: \"iter2(f,a) = a $ map(f,iter2(f,a))\""}
@{verbatim "  apply (unfold iter2_def)"}
@{verbatim "  apply (rule letrecB [THEN trans])"}
@{verbatim "  apply (rule refl)"}
@{verbatim "  done"}

注意 @{verbatim letrecB} 后面必须接 @{verbatim trans}：
@{verbatim letrecB} 给出的是 @{verbatim "let x be t in f(x) = f(t)"}，
还要再传一步才落到 @{verbatim "iter1(f,a)"} 上。

真正有意思的是**证明两者相等**。库的做法（源第 127–135 行）
是第 70 章 @{verbatim eq_coinduct3} 的标准三段式：

@{verbatim "lemma iter1_iter2_eq: \"iter1(f,a) = iter2(f,a)\""}
@{verbatim "  apply (eq_coinduct3"}
@{verbatim "    \"{p. EX x y. p=<x,y> \<and> (EX n:Nat. x=iter1 (f,f^n`a) \<and> y=map (f) ^n`iter2 (f,a))}\")"}
@{verbatim "  apply (fast intro!: napplyBzero [symmetric] napplyBzero [symmetric, THEN arg_cong])"}
@{verbatim "  apply (EQgen iter1B iter2Blemma)"}
@{verbatim "  apply (subst napply_f, assumption)"}
@{verbatim "  apply (rule_tac f1 = f in napplyBsucc [THEN subst])"}
@{verbatim "  apply blast"}
@{verbatim "  done"}

关系 @{verbatim R} 的设计是全证明的灵魂：它不说
"@{verbatim x} 与 @{verbatim y} 结构相同"，而说
"@{verbatim x} 是 @{verbatim iter1} 从 @{verbatim "f^n`a"} 出发、
@{verbatim y} 是 @{verbatim iter2} 施加 @{verbatim n} 次 @{verbatim map}"
——把"已经同步了多少步"编码进关系里，于是余归纳的每一步
只要把 @{verbatim n} 推成 @{verbatim "succ(n)"}。
@{verbatim "EX n:Nat"} 这个存在量词是**余归纳关系的燃料**：
每展开一层就换一个更大的 @{verbatim n}，关系却不变。

作为对照，库还给无穷列表证了三条纯等式
（源第 27–67 行的 @{verbatim map_comp} / @{verbatim map_id} /
@{verbatim map_append}），全是 @{verbatim eq_coinduct3} +
@{verbatim "drule ListsXH [THEN iffD1]"} + @{verbatim EQgen} 的三连。
第 72.9 节已经用 Isar 把它们的有限版写完了，读者可以自己对比：
同样的命题，一边是 @{verbatim "erule List_ind"}，
一边是 @{verbatim "eq_coinduct3"} + 一条精心设计的 @{verbatim R}。\<close>

thm iter1_def iter2_def iter1B iter2B eq_coinduct3 EQgenXH


subsection \<open>72.11 荷兰国旗：列表版 Dijkstra\<close>

text \<open>库源码 @{verbatim "src/CCL/ex/Flag.thy"}。Dijkstra 的原例用数组，
这里退化成列表：三色各归各的桶。颜色用和类型编码
（源第 13–23 行）：

@{verbatim "definition Colour :: \"i set\""}
@{verbatim "  where \"Colour == Unit + Unit + Unit\""}
@{verbatim "definition red :: \"i\""}
@{verbatim "  where \"red == inl(one)\""}
@{verbatim "definition white :: \"i\""}
@{verbatim "  where \"white == inr(inl(one))\""}
@{verbatim "definition blue :: \"i\""}
@{verbatim "  where \"blue == inr(inr(one))\""}

@{verbatim ccase}（源第 25–26 行）是颜色上的三分支 case，
@{verbatim flag}（源第 28–36 行）用双累加器 @{verbatim lr} / @{verbatim "p"} /
@{verbatim lw} / @{verbatim lb} 一趟扫完。库证了它的**类型**
（源第 63–69 行）——注意最后两步与第 72.5 节完全同构：

@{verbatim "lemma \"flag : List(Colour)->List(Colour)*List(Colour)*List(Colour)\""}
@{verbatim "  apply (unfold flag_def)"}
@{verbatim "  apply (typechk redT whiteT blueT ccaseT)"}
@{verbatim "  apply clean_ccs"}
@{verbatim "  apply (erule ListPRI [THEN ListPR_wf [THEN wfI]])"}
@{verbatim "  apply assumption"}
@{verbatim "  done"}

这里 @{verbatim typechk} 带上了三个参数 @{verbatim redT} /
@{verbatim whiteT} / @{verbatim blueT} 与 @{verbatim ccaseT}——
它们不是 Nat 上那样的内置规则，而是本文件自己证的
（源第 53–61 行），正好演示"类型定理也是普通定理，可以当参数传"。

库最后一条（源第 71–74 行）想证 flag 满足规格
@{verbatim "PROD l:List(Colour).{x:...Flag(x,l)}"}，用
@{verbatim gen_ccs} 之后**以 @{verbatim oops} 收场**——
Perm 是公理化的（源第 38 行 @{verbatim "axiomatization Perm"}），
 correctness 证不下去。这是库作者留的诚实尾巴。\<close>

thm Colour_def red_def white_def blue_def ccaseT redT whiteT blueT


subsection \<open>72.12 坑位清单（实测）\<close>

text \<open>1. **@{verbatim "map"} 收 HOL 函数，@{verbatim filter} /
   @{verbatim insert} / @{verbatim isort} 收 CCL 项**：
   @{verbatim "map(succ, l)"} 直接写，@{verbatim "map(lam x. x, l)"}
   反而类型报错（@{verbatim "lam x. x :: i"} 塞不进 @{verbatim "i\<Rightarrow>i"}）；
   而 @{verbatim "filter(f,l)"} 里 @{verbatim f} 要用 @{verbatim "f`x"}
   施加，必须写 @{verbatim "lam x. ..."}。两类参数写法相反，
   是本库最容易反复踩的一条。
2. **@{verbatim "letrec"} 定义的函数没有 simp 规则**：
   @{verbatim natBs} 只覆盖 @{verbatim not} / @{verbatim add} /
   @{verbatim mult} / @{verbatim napply}；@{verbatim sub} /
   @{verbatim le} / @{verbatim lt} / @{verbatim div} /
   @{verbatim ackermann} / @{verbatim partition} / @{verbatim qsort}
   一条都没有（@{verbatim letrecB} 进 simp 集会无限展开）。
   拿它们做计算演示只会得到展开到一半的 @{verbatim letrec}。
3. **证明类型之前必须 @{verbatim unfold} 定义**：
   @{verbatim typechk} 靠 @{verbatim ncaseT} / @{verbatim lrecT}
   这些**规则**匹配目标，面对未展开的常量 @{verbatim "#+"}
   无从下手；顺序写成 @{verbatim typechk} 再 @{verbatim unfold}
   必然失败。
4. **@{verbatim sub} 是截断减法**：@{verbatim "a #- b"} 在
   @{verbatim "a < b"} 时返回 @{verbatim zero} 而不是负数
   （源第 78 行注释）。拿它当普通减法推性质会推出假命题。
5. **@{verbatim eq_coinduct3} 的关系里要带存在量词当燃料**：
   @{verbatim iter1_iter2_eq} 的 @{verbatim R} 里有
   @{verbatim "EX n:Nat"}，每展开一层换更大的 @{verbatim n}；
   写成不带量词的"结构相同"型关系，余归纳前提
   @{verbatim "R <= EQgen(...)"} 证不出来。
6. **@{verbatim letrecB} 后必须接 @{verbatim trans}**：
   它给的是 @{verbatim "let x be t in f(x) = f(t)"}，
   与目标 @{verbatim "iter1(f,a) = ..."} 还差一次传递，
   少了 @{verbatim trans} 会报形状不匹配。
7. **有限与无穷的证明方法不能混用**：@{verbatim List_ind}
   对 @{verbatim "Lists(A)"} 无效（无穷流到不了基例），
   @{verbatim eq_coinduct3} 对 @{verbatim "List(A)"} 也能用但
   是杀鸡用牛刀。选错方法的报错是
   @{verbatim "Failed to refine"}，很难直接看出原因。
8. **@{verbatim typechk} 可以带类型定理作参数**：
   @{verbatim "typechk redT whiteT blueT ccaseT"}——
   这些定理是本文件现证的，不是内置规则。
   @{verbatim gen_ccs} 同理。忘了传参会在
   @{verbatim clean_ccs} 阶段留下无法关闭的义务。
9. **@{verbatim Perm} 是公理不是定理**：@{verbatim Flag.thy}
   第 38 行 @{verbatim "axiomatization Perm"}，
   所以 correctness 那条以 @{verbatim oops} 结束；
   读库时别把 @{verbatim oops} 当成"已经证完"。
10. **@{verbatim "x$xs"} 与 @{verbatim "l @ m"} 优先级不同**：
    @{verbatim "$"} 是 80、@{verbatim "@"} 是 55，
    写 @{verbatim "x$xs @ m"} 不会被解析成
    @{verbatim "x $ (xs @ m)"}，但也别依赖直觉，
     拿不准就加括号（本章 @{verbatim flat_demo} 就这么干的）。\<close>

subsection \<open>72.13 与其他章的接口\<close>

text \<open>第 70 章的 @{verbatim nrec} / @{verbatim lrec} /
@{verbatim letrec} / @{verbatim eq_coinduct3} 是本章全部程序的
执行与证明引擎；第 71 章的 @{verbatim ncaseT} / @{verbatim lrecT} /
@{verbatim typechk} 管类型，@{verbatim NatPR} / @{verbatim ListPR} /
@{verbatim lex} 管终止；第 69 章的 lfp 造 @{verbatim List}、
gfp 造 @{verbatim Lists}——有限与无穷的分界线就刻在这两个
不动点上。\<close>

ML \<open>writeln "==== 72 结束 ===="\<close>

end
