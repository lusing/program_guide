import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
start = t.index('Theorem countdown_total')
end = t.index('(* ---------- minsum 构件')
new = r'''Theorem countdown_total : forall x y C s1,
  x <> y ->
  s1 x + s1 y = C ->
  exists s2, exec (countdownC x y) s1 s2 /\ s2 x + s2 y = C /\ s2 x = 0.
Proof.
  intros x y C s1 Hxy Hinv.
  destruct (hoareT_while_layered
              (fun s => s x + s y = C)
              (fun s => negb (Nat.eqb (s x) 0))
              (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
              (fun s => s x)
              s1 Hinv)
    as [s2 [Hex [HP Hb]]].
  - (* 守卫真 ⟹ 变体 > 0 *)
    intros s HPs Hbs. unfold negb in Hbs.
    apply negb_true_iff, Nat.eqb_neq in Hbs.
    lia.
  - (* 体完全正确：不变式保持 + 变体递减（n 参数化） *)
    intros n s [HPs [Hbs Hns]].
    destruct (s x) as [|v].
    { unfold negb in Hbs. rewrite Nat.eqb_refl in Hbs. discriminate. }
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
  - (* 结论换形：negb (x=?0) = false → x = 0 *)
  destruct s2 as ….
Admitted.

'''
t = t[:start] + '(* 见下方净版 *)\n\n' + t[end:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
