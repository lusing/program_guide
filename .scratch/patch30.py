import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
start = t.index('(* ---------- 旗舰：total-while（变体版 while 规则，式 4.15） ---------- *)')
end = t.index('(* 上面的 total-while 完整版需要')
t = t[:start] + '''(* ---------- 旗舰：total-while（变体版 while 规则，式 4.15 的分层形态） ---------- *)

Theorem hoareT_while_layered : forall P b c V,
  (forall s, P s -> b s = true -> V s > 0) ->
  (hoareT (fun s => P s /\\ b s = true /\\ V s > 0) c
          (fun s => P s /\\ V s < V s)) ->
  hoareT P (cwhile b c) (fun s => P s /\\ b s = false).
Proof.
  intros P b c V Hpos Hbody.
  assert (Hmain : forall n s1, P s1 -> V s1 <= n ->
    exists s2, exec (cwhile b c) s1 s2 /\\ P s2 /\\ b s2 = false).
  { induction n as [|n IH]; intros s1 HP HV.
    - destruct (b s1) eqn:Eb.
      + specialize (Hpos s1 HP Eb).
        assert (V s1 = 0) by lia. lia.
      + exists s1. split; [apply ewhile_false; exact Eb|].
        split; [exact HP | exact Eb].
    - destruct (b s1) eqn:Eb.
      + destruct (Hbody s1) as [s2 [Hex Hstep]].
        { split; [exact HP|]. split; [exact Eb|]. apply Hpos; assumption. }
        destruct Hstep as [HP2 HV2].
        destruct (IH s2 HP2) as [s3 [Hex2 [HP3 Eb3]]].
        { destruct (V s1) as [|v]; [lia | lia]. }
        exists s3. split.
        { apply ewhile_true with (s2 := s2); [exact Eb | exact Hex | exact Hex2]. }
        split; [exact HP3 | exact Eb3].
      + exists s1. split; [apply ewhile_false; exact Eb|].
        split; [exact HP | exact Eb].
  }
  intros s1 HP. apply Hmain; [exact HP | apply Nat.le_0_l].
Qed.

'''
t = t[:start] + t if False else t
# splice: remove old block, insert new
old_start = start
old_end = t.index('Theorem hoareT_while_layered', start)
new_block = t[:old_start] + '''(* ---------- 旗舰：total-while（变体版 while 规则，式 4.15 的分层形态） ---------- *)

'''
t = new_block + t[old_start:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('done')
