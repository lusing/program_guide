theory T64_streams
  imports "HOL-Library.Stream" "HOL-Library.Linear_Temporal_Logic_on_Streams"
    "HOL-Library.Omega_Words_Fun" "HOL-Library.Periodic_Fun" "HOL-Library.Code_Lazy"
begin

section \<open>64.1 Stream：共归纳列表及其求值前提\<close>

text \<open>@{theory "HOL-Library.Stream"} 的 @{typ "'a stream"} 是第 26 章
共归数据类型的库存实例：构造子 @{verbatim "x ## s"}（@{const SCons}），
选择子 @{const shd}/@{const stl}，映射 @{const smap}，索引
@{term "s !! n"}，取前段 @{const stake}、丢前段 @{const sdrop}，
列表前缀拼接 @{term "xs @- s"}。先讲一个求值前提：流是**无穷**的，
直接 @{verbatim value} 会在严格求值下撑爆栈（生成代码严格构造
无限尾部）。@{theory "HOL-Library.Code_Lazy"} 的
@{verbatim "code_lazy_type"} 把选定类型包成惰性表示，之后
@{const stake} 一类有限观察就能安全求值：\<close>

code_lazy_type stream

ML \<open>writeln "==== 64 开始 ===="\<close>

value "stake 5 (nats :: nat stream)"
value "(nats :: nat stream) !! 4"
value "stake 5 (cycle [1::nat, 2, 3])"
value "stake 4 (smap (%n. n * 2) (nats :: nat stream))"
value "stake 3 ([9::nat, 8] @- nats)"

text \<open>@{const nats} 是库里现成的缩写（@{verbatim "fromN 0"}，
即 @{verbatim "siterate Suc 0"}）；@{const cycle} 循环一个非空列表。
@{const sset} 是元素集合，@{thm sset_range [no_vars]} 把它与
@{const snth} 的值域互译——流的集合视角与序列视角的桥。\<close>

section \<open>64.2 生成器与共归纳证明\<close>

text \<open>两个基本生成器：@{const siterate}（反复应用函数）与
@{const cycle}（循环列表）。它们满足同一个不动点方程
@{verbatim "s = x ## s"} 的形态，于是「逐个构造子相等」的共归纳
（@{method coinduction}，第 26 章）能证它们相等：\<close>

lemma cycle_singleton_is_siterate: "cycle [x] = siterate id x"
  by coinduction auto

text \<open>共归纳方法自动生成关系 @{verbatim "R a b ⟷ (a = cycle [x] ∧ b = siterate id x)"}，
剩下的头相等、尾仍在关系内都是 auto 的常规动作。这是流上证明的
标准起手式，比展开不动点方程手动构造双模拟省力得多。\<close>

section \<open>64.3 Linear_Temporal_Logic_on_Streams：流上的 LTL\<close>

text \<open>@{theory "HOL-Library.Linear_Temporal_Logic_on_Streams"} 把线性
时序逻辑建在流上：谓词是 @{typ "'a stream \<Rightarrow> bool"}。
@{const holds}（首元素满足）、@{const nxt}（下一时刻）、
@{const HLD}（首元素属于某集合，原子命题的入口）、@{const ev}
（终将，归纳定义）、@{const alw}（恒常，**共**归纳定义）、
@{term "\<phi> until \<psi>"}（弱直到，共归纳）。记号 @{term "s \<cdot> P"}
是「当前在 s、下一刻起 P」。

两个证明演示。@{const ev} 是归纳定义，用引入规则直接构造
（第 2 位恰好是 2）：\<close>

lemma ev_demo: "ev (HLD {2::nat}) (sdrop 2 nats)"
  by (rule ev.base) (simp add: HLD_iff)

text \<open>@{const alw} 是共归纳的，证明用共归纳（注意要带
@{verbatim "arbitrary: k"} 把归纳关系泛化到任意起点，
否则尾巴换相后关系就断了）：\<close>

lemma alw_demo: "alw (%s. even (shd s)) (smap (%n. 2 * n) (siterate Suc k))"
  by (coinduction arbitrary: k) auto

text \<open>@{verbatim until} 一族配了完整的代数（@{thm ev_nxt [no_vars]}、
@{thm alw_mono [no_vars]} 等单调性、展开式），模型检查社区需要的
LTL 语义基础都在。\<close>

section \<open>64.4 Omega_Words_Fun：作为函数的 ω 词\<close>

text \<open>@{theory "HOL-Library.Omega_Words_Fun"} 走了与 Stream 平行的
另一条路：@{typ "'a word"} 就是 @{typ "nat \<Rightarrow> 'a"} 的类型**同义词**
——不是新类型，没有包装。好处是函数装备（复合、逐点运算、
第 63 章的 Function_Algebras）全部直接用；坏处是没有流的
共归纳工具。配套操作：拼接 @{term "w \<frown> x"}（有限词接 ω 词）、
ω 迭代 @{term "w\<^sup>\<omega>"}（非空有限词的无限循环）、
@{const suffix}（丢弃前 k 个）、@{term "w [i \<rightarrow> j]"}（子串）、
@{const limit}（无穷多次出现的字母集，定义在 62 章的
@{const Inf_many} 上，是 ω 自动机接受条件的基石）：\<close>

value "([0::nat, 1]\<^sup>\<omega>) 5"

lemma "([1::nat, 2, 3] \<frown> w) 1 = 2"
  by simp

lemma aux: "Suc (Suc n) mod Suc (Suc 0) = n mod Suc (Suc 0)"
  by arith

lemma iter_periodic: "([0::nat, 1]\<^sup>\<omega>) (2 + n) = ([0, 1]\<^sup>\<omega>) n"
  by (simp add: iter_nth aux)

text \<open>@{verbatim iter} 的定义 @{term "w\<^sup>\<omega> n = w ! (n mod length w)"}
把「周期性」直接写成取模——周期引理由 mod 算术完成（上面的
@{verbatim aux} 是@{const iter}周期性的原子事实）。\<close>

section \<open>64.5 Periodic_Fun：周期函数的 locale\<close>

text \<open>@{theory "HOL-Library.Periodic_Fun"} 把「@{term "f (x + p) = f x"}」
封装成 locale @{locale periodic_fun}：证一次周期，白拿一族导出
（@{verbatim "f (x - p) = f x"}、@{verbatim "f (x + n*p) = f x"} 等，
 @{verbatim periodic_simps} 引理集）。两个便利子 locale：
@{verbatim periodic_fun_simple}（任意周期 p）与
@{verbatim periodic_fun_simple'}（周期 1）。演示：mod 2 是周期 2 的：\<close>

interpretation mod2: periodic_fun_simple "%n::int. n mod 2" 2
  by standard auto

lemma "(%n::int. n mod 2) (5 + 3 * 2) = (%n::int. n mod 2) 5"
  using mod2.plus_of_nat[of 5 3] by simp

text \<open>@{verbatim plus_of_nat} 是 locale 里导出的「加 n 个周期不变」：
@{verbatim "f (x + of_nat n * period) = f x"}。三角函数是它的头牌
用户（@{verbatim sin_plus_pi}、@{verbatim cos_plus_pi} 一族就是
这么来的）。\<close>

section \<open>64.6 坑位清单（实测）\<close>

text \<open>
1. **流的 value 必须先 @{verbatim "code_lazy_type stream"}**
   （导入 @{theory "HOL-Library.Code_Lazy"}）——严格求值下
   任何无穷流都撑爆栈（Interrupt_Breakdown），第 65 章细讲
   惰性化。
2. 库里已有缩写 @{verbatim "nats = fromN 0"}——别自己再定义
   同名 @{verbatim nats} 常量（不报错但 simp 展开路径不同，
   证明残目标会突然冒出 @{verbatim fromN}）。
3. 共归纳证流相等：@{verbatim "by coinduction auto"} 是基准形态；
   关系里若有「走一步变一点」的参数（如 siterate 的起点），
   必须 @{verbatim "arbitrary: k"} 泛化，否则尾巴掉出关系。
4. @{const ev} 是**归纳**定义（用 intro 规则构造），@{const alw}
   是**共归纳**定义（用 coinduction）——两者证明风格相反，
   别拿 intro 去证 alw。
5. @{term "xs @- s"} 的拼接记号优先级 65；@{term "s !! n"} 的
   @{verbatim "!!"} 与列表 @{const nth} 同记号但类型分辨。
6. @{typ "'a word"} 是类型同义词不是新类型：不能与 stream
   混写（@{const shd}/@{const stake} 不适用于 word），但函数
   装备直接用。转换靠各写引理。
7. @{term "w\<^sup>\<omega>"} 对空列表是 @{term undefined}——所有
   周期引理都带 @{term "w \<noteq> []"}/@{term "0 < length w"} 前提。
8. @{verbatim "w [i \<rightarrow> j]"} 是**右开**区间子串（基于
   @{term "[i..<j]"}），长度 j - i。
9. periodic_fun 的总 locale 参数多（g/gm/g1/gn1 四个加速器），
   自用先实例化 @{verbatim periodic_fun_simple} 或
   @{verbatim periodic_fun_simple'}。
10. LTL 的 @{const holds}/@{const nxt}/@{const ev}/@{const alw}
    名字很短，与其他理论（如进程代数库）同堂时留意冲突；
    @{const HLD} 是原子命题的标准入口（@{thm HLD_iff [no_vars]}）。
\<close>

ML \<open>writeln "==== 64 结束 ===="\<close>

end
