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
