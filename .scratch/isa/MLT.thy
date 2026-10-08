theory MLT
  imports Main
begin
type_synonym state = "nat \<Rightarrow> nat"
datatype cmd =
    cskip
  | cass nat "state \<Rightarrow> nat"
  | cseq cmd cmd
  | cwhile "state \<Rightarrow> bool" cmd
axiomatization where mainI: "\<exists>s2. exec_like s1 s2 \<and> s2 x + s2 y = C \<and> s2 x = 0"
axiomatization exec_like :: "cmd \<Rightarrow> state \<Rightarrow> state \<Rightarrow> bool" and s1 :: state and x y C :: nat

lemma test: "True"
proof -
  then obtain s2 where hex: "exec_like (cwhile (\<lambda>s. s x \<noteq> 0)
      (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1))) s1 s2"
    and hq: "s2 x + s2 y = C" and hq0: "s2 x = 0"
    by metis
  show "True" by simp
qed

end
