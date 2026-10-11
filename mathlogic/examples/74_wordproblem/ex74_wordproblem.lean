/- ex44 —— 字问题与重写（Müller-Stach ch5）Lean 镜像
   Tseytin 半群九关系：双向重写一步算子 + 深度界 BFS 闭包 +
   等式链账本 + aaa 不可达有限影子 + 两条写法汇合样本。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

abbrev Word := List Nat   -- 字母 a..e 编码 0..4

def strip : Word → Word → Option Word
  | w, [] => some w
  | [], _ => none
  | wc :: wt, pc :: pt => if wc == pc then strip wt pt else none

def replaceAt (w : Word) (i : Nat) (p q : Word) : Option Word :=
  match strip (w.drop i) p with
  | some rest => some (w.take i ++ q ++ rest)
  | none => none

def rew1Once (rs : List (Word × Word)) (w : Word) : List Word :=
  rs.flatMap fun r =>
    (List.range (w.length + 1)).flatMap fun i =>
      (match replaceAt w i r.1 r.2 with
       | some w1 => [w1] | none => []) ++
      (match replaceAt w i r.2 r.1 with
       | some w2 => [w2] | none => [])

def weqb (u v : Word) : Bool :=
  match u, v with
  | [], [] => true
  | x :: t, y :: t' => (x == y) && weqb t t'
  | _, _ => false

def inW (x : Word) (l : List Word) : Bool := l.any (weqb x)

def closureW : Nat → List (Word × Word) → List Word → List Word → List Word
  | 0, _, seen, _ => seen
  | d + 1, rs, seen, frontier =>
      let next := (frontier.flatMap (rew1Once rs)).filter (fun x => !inW x seen)
      closureW d rs (seen ++ next) next

def rewStar (d : Nat) (rs : List (Word × Word)) (w : Word) : List Word :=
  closureW d rs [w] [w]

/-- Tseytin 半群九关系（书 p84）：
    ac=ca, ad=da, bc=cb, bd=db, ce=eca, de=edb,
    cdca=cdcae, caaa=aaa, daaa=aaa -/
def RS : List (Word × Word) :=
  [([0, 2], [2, 0]),
   ([0, 3], [3, 0]),
   ([1, 2], [2, 1]),
   ([1, 3], [3, 1]),
   ([2, 4], [4, 2, 0]),
   ([3, 4], [4, 3, 1]),
   ([2, 3, 2, 0], [2, 3, 2, 0, 4]),
   ([2, 0, 0, 0], [0, 0, 0]),
   ([3, 0, 0, 0], [0, 0, 0])]

example :
  [ inW [2, 0] (rew1Once RS [0, 2]),
    inW [0, 2] (rew1Once RS [2, 0]),
    inW [4, 2, 0] (rew1Once RS [2, 4]),
    inW [2, 4] (rew1Once RS [4, 2, 0]),
    inW [2, 3, 2, 0, 4] (rew1Once RS [2, 3, 2, 0]),
    inW [2, 3, 2, 0] (rew1Once RS [2, 3, 2, 0, 4]) ]
    = [true, true, true, true, true, true] := by native_decide

example :
    (inW [2, 3, 2, 0, 4] (rewStar 1 RS [2, 3, 2, 0])
      && inW [2, 3, 2, 0] (rewStar 1 RS [2, 3, 2, 0, 4])) := by native_decide

def interW (l1 l2 : List Word) : List Word := l1.filter (fun x => inW x l2)

/-- 两条写法汇合样本：eca 与 ce 的深度 3 闭包交集非空 -/
example : !(interW (rewStar 3 RS [4, 2, 0]) (rewStar 3 RS [2, 4])).isEmpty := by
  native_decide

/-- aaa 不可达的有限影子（深度 5、三出发词） -/
example :
  [ !(inW [0, 0, 0] (rewStar 5 RS [2, 4])),
    !(inW [0, 0, 0] (rewStar 5 RS [3, 4])),
    !(inW [0, 0, 0] (rewStar 5 RS [2, 3, 2, 0])) ]
    = [true, true, true] := by native_decide

#eval (rewStar 5 RS [2, 4]).length
