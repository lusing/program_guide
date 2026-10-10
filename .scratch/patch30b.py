import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()

start = t.index('(* 分层前提')
end = t.index('(* ---------- countdown 的完全正确性 ---------- *)')
new = r'''(* 分层前提：体自身完全正确，且每轮变体降到当前值 n 之下——
   H&R 式 4.15 的 E0（逻辑变量冻结本轮变体初值）在此参数化为 n *)
Theorem hoareT_while_layered : forall P b c V,
  (forall s, P s -> b s = true -> V s > 0) ->
  (forall n, hoareT (fun s => P s /\ b s = true /\ V s = n)
                    c (fun s => P s /\ V s < n)) ->
  hoareT P (cwhile b c) (fun s => P s /\ b s = false).
Proof.
  intros P b c V Hpos Hbody.
  assert (Hmain : forall n s1, P s1 -> V s1 <= n ->
    exists s2, exec (cwhile b c) s1 s2 /\ P s2 /\ b s2 = false).
  { induction n as [|n IH]; intros s1 HP HV.
    - destruct (b s1) eqn:Eb.
      + specialize (Hpos s1 HP Eb).
        assert (V s1 = 0) by lia. lia.
      + exists s1. split; [apply ewhile_false; exact Eb|].
        split; [exact HP | exact Eb].
    - destruct (b s1) eqn:Eb.
      + destruct (Hbody (V s1) s1) as [s2 [Hex Hstep]].
        { split; [exact HP|exact Eb]. split; [reflexivity|].
          lia. }
        destruct Hstep as [HP2 HV2].
        destruct (IH s2 HP2) as [s3 [Hex2 [HP3 Eb3]]].
        { lia. }
        exists s3. split.
        { apply ewhile_true with (s2 := s2);
            [exact Eb | exact Hex | exact Hex2]. }
        split; [exact HP3 | exact Eb3].
      + exists s1. split; [apply ewhile_false; exact Eb|].
        split; [exact HP | exact Eb].
  }
  intros s1 HP. apply Hmain; [exact HP | apply Nat.le_0_l].
Qed.

'''
t = t[:start] + new + t[end:]

# countdown_total 的第二前提改为 forall n 形态
start2 = t.index('  - (* 体完全正确 + 不变式保持 + 变体递减 *)')
end2 = t.index('(* ---------- minsum 构件')
new2 = r'''  - (* 体完全正确：不变式保持 + 变体递减（n 参数化） *)
    intros n s [HP [Hb Hn]].
    destruct (s x) as [|v].
    { unfold negb in Hb. rewrite Nat.eqb_refl in Hb. discriminate. }
    exists (upd (upd s x v) y (s y + 1)).
    split.
    + apply eseq with (s2 := upd s x v).
      * apply eass.
      * apply eass.
    + split.
      * (* 不变式：x-1 与 y+1 的和守恒（x≠y 防别名） *)
        assert (Hx : upd (upd s x v) y (s y + 1) x = v).
        { unfold upd. rewrite Nat.eqb_refl.
          destruct (Nat.eqb x y) eqn:Exy.
          - apply Nat.eqb_eq in Exy. contradiction.
          - reflexivity. }
        assert (Hy : upd (upd s x v) y (s y + 1) y = s y + 1).
        { unfold upd. destruct (Nat.eqb y x) eqn:Eyx.
          - apply Nat.eqb_eq in Eyx. contradiction.
          - rewrite Nat.eqb_refl. reflexivity. }
        lia.
      * (* 变体严格下降 *)
        assert (Hx : upd (upd s x v) y (s y + 1) x = v).
        { unfold upd. rewrite Nat.eqb_refl.
          destruct (Nat.eqb x y) eqn:Exy.
          - apply Nat.eqb_eq in Exy. contradiction.
          - reflexivity. }
        lia.
Qed.

'''
t = t[:start2] + new2 + t[end2:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
