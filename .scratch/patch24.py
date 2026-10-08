import io, re
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()

# 定位并整体替换 iterEU_In_step 引理（从 Lemma 行到其后第一个 Qed.）
start = t.index('Lemma iterEU_In_step')
end = t.index('Qed.', start) + len('Qed.')
new = r'''Lemma iterEU_In_step : forall m fuel A B s,
  In s (iterEU m (S fuel) A B) <->
  In s (iterEU m fuel A B) \/
  (In s (fstates m) /\ In s A /\
   exists s', In s' (ftrans m s) /\ In s' (iterEU m fuel A B)).
Proof.
  intros m fuel A B s. simpl.
  unfold unionL. rewrite in_app_or, in_or_app.
  unfold interL. rewrite filter_In.
  unfold satEX. rewrite filter_In, existsb_exists.
  unfold memList. rewrite existsb_exists.
  split.
  - intros [H1 | [H2 H3]].
    + left. exact H1.
    + right. destruct H3 as [HA Hmem].
      rewrite existsb_exists in Hmem.
      destruct Hmem as [s0 [Hf Hb]]. apply Nat.eqb_eq in Hb. subst s0.
      right. split; [exact H2|]. split; [exact HA|].
      rewrite existsb_exists in Hf. exists s'. tauto.
  - intros [H1 | [Hst [HA [s' [Htr Hin]]]]].
    + left. exact H1.
    + right. split; [exact Hst|]. split; [exact HA|].
      exists s'. split; [| rewrite existsb_exists; exists s';
        split; [exact Hin|apply Nat.eqb_refl]].
      rewrite existsb_exists. exists s'. tauto.
Qed.'''
t = t[:start] + new + t[end:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
