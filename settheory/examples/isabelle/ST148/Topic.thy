theory Topic
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 148 章：三轴共用六个有限索引。这里只核验索引关系，
不声称形式化大基数、力迫、投影决定性或 AD。\<close>

definition Six where
  "Six \<equiv> succ(succ(succ(succ(succ(succ(0))))))"

definition Strength where
  "Strength(n) \<equiv> n:nat & n<Six"

definition Forcing where
  "Forcing(n) \<equiv> n:nat & n<Six"

definition Regularity where
  "Regularity(n) \<equiv> n:nat & n<Six"

lemma axes_coincide:
  "(Strength(n) <-> Forcing(n)) & (Forcing(n) <-> Regularity(n))"
  by (simp add: Strength_def Forcing_def Regularity_def)

lemma first_row: "Strength(0)"
  by (simp add: Strength_def Six_def)

lemma last_row: "Regularity(succ(succ(succ(succ(succ(0))))))"
  by (simp add: Regularity_def Six_def)

lemma no_seventh_row:
  "Strength(Six) \<Longrightarrow> False"
  by (simp add: Strength_def Six_def)

end
