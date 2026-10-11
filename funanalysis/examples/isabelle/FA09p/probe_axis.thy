theory probe_axis
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin
lemma p1: "axis 0 (1::real) $ (1::2) = 0" by (simp add: axis_def)
lemma p2: "axis 0 (1::real) $ (0::2) = 1" by simp
end
