(* 41 词法与语法解析 —— 从源文本字符串到 aexp/bexp/com：字符判定、tokenize、解析器组合子与 parse *)

From Stdlib Require Import Arith Bool List Strings.String Strings.Ascii Arith.Arith.
Import ListNotations.

Module Ex57Parsing.

(* ---------- 57.1 语言层的最小副本（同 38-55 章：只要语法，不要语义） ---------- *)

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.

Declare Custom Entry com.
Declare Scope com_scope.

Notation "<{ e }>" := e
  (e custom com, format "'[hv' <{ '/  ' '[v' e ']' '/' }> ']'") : com_scope.

Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).

Notation "f x .. y" := (.. (f x) .. y)
                  (in custom com at level 0, only parsing,
                  f constr at level 0, x constr at level 1,
                      y constr at level 1).

Notation "x + y"   := (APlus x y) (in custom com at level 50, left associativity).
Notation "x - y"   := (AMinus x y) (in custom com at level 50, left associativity).
Notation "x * y"   := (AMult x y) (in custom com at level 40, left associativity).

Notation "'true'"  := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).

Notation "x <= y"  := (BLe x y) (in custom com at level 70, no associativity).
Notation "x = y"   := (BEq x y) (in custom com at level 70, no associativity).
Notation "x && y"  := (BAnd x y) (in custom com at level 80, left associativity).
Notation "'~' b"   := (BNot b) (in custom com at level 75, right associativity).

Open Scope com_scope.

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'"  := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y"  := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85, no associativity,
    format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.

(* ---------- 57.2 字符判定：ascii 码点上的布尔函数 ---------- *)

Definition isWhite (c : ascii) : bool :=
  let n := nat_of_ascii c in
  orb (orb (n =? 32)   (* space *)
           (n =? 9))   (* tab *)
      (orb (n =? 10)   (* linefeed *)
           (n =? 13)). (* Carriage return. *)

Definition isLowerAlpha (c : ascii) : bool :=
  let n := nat_of_ascii c in
    andb (97 <=? n) (n <=? 122).

Definition isAlpha (c : ascii) : bool :=
  let n := nat_of_ascii c in
    orb (andb (65 <=? n) (n <=? 90))
        (andb (97 <=? n) (n <=? 122)).

Definition isDigit (c : ascii) : bool :=
  let n := nat_of_ascii c in
     andb (48 <=? n) (n <=? 57).

Inductive chartype := white | alpha | digit | other.

Definition classifyChar (c : ascii) : chartype :=
  if isWhite c then
    white
  else if isAlpha c then
    alpha
  else if isDigit c then
    digit
  else
    other.

Example classifyChar_ex :
  map classifyChar ["a"%char; " "%char; "9"%char; "("%char; "Z"%char]
  = [alpha; white; digit; other; alpha].
Proof. reflexivity. Qed.

(* ---------- 57.3 字符串与 ascii 列表的互转 ---------- *)

Fixpoint list_of_string (s : string) : list ascii :=
  match s with
  | EmptyString => []
  | String c s => c :: (list_of_string s)
  end.

Definition string_of_list (xs : list ascii) : string :=
  fold_right String EmptyString xs.

Example list_of_string_ex :
  list_of_string "ab1" = ["a"%char; "b"%char; "1"%char].
Proof. reflexivity. Qed.

Example string_roundtrip :
  string_of_list (list_of_string "x:=1") = "x:=1"%string.
Proof. reflexivity. Qed.

(* ---------- 57.4 正则表达式与 exp_match：词法的归纳规格 ---------- *)

Reserved Notation "s =~ re" (at level 80).

Inductive reg_exp (T : Type) : Type :=
  | EmptySet
  | EmptyStr
  | Char (x : T)
  | App (re1 re2 : reg_exp T)
  | Union (re1 re2 : reg_exp T)
  | Star (re : reg_exp T).

Arguments EmptySet {T}.
Arguments EmptyStr {T}.
Arguments Char {T} _.
Arguments App {T} _ _.
Arguments Union {T} _ _.
Arguments Star {T} _.

Inductive exp_match {T} : list T -> reg_exp T -> Prop :=
  | MEmpty : [] =~ EmptyStr
  | MChar x : [x] =~ (Char x)
  | MApp s1 re1 s2 re2
             (H1 : s1 =~ re1)
             (H2 : s2 =~ re2)
           : (s1 ++ s2) =~ (App re1 re2)
  | MUnionL s1 re1 re2
                (H1 : s1 =~ re1)
              : s1 =~ (Union re1 re2)
  | MUnionR s2 re1 re2
                (H2 : s2 =~ re2)
              : s2 =~ (Union re1 re2)
  | MStar0 re : [] =~ (Star re)
  | MStarApp s1 s2 re
                 (H1 : s1 =~ re)
                 (H2 : s2 =~ (Star re))
               : (s1 ++ s2) =~ (Star re)

  where "s =~ re" := (exp_match s re).

Example reg_exp_ex1 : [1] =~ Char 1.
Proof.
  apply MChar.
Qed.

Example reg_exp_ex2 : [1; 2] =~ App (Char 1) (Char 2).
Proof.
  apply (MApp [1]).
  - apply MChar.
  - apply MChar.
Qed.

Lemma MStar1 :
  forall T s (re : reg_exp T),
    s =~ re ->
    s =~ Star re.
Proof.
  intros T s re H.
  rewrite <- (app_nil_r s).
  apply MStarApp.
  - apply H.
  - apply MStar0.
Qed.

Example digits_ex :
  ["1"%char; "2"%char] =~ Star (Union (Char "1"%char) (Char "2"%char)).
Proof.
  apply (MStarApp ["1"%char]).
  - apply MUnionL. apply MChar.
  - apply (MStarApp ["2"%char]).
    + apply MUnionR. apply MChar.
    + apply MStar0.
Qed.

(* ---------- 57.5 词法分析：tokenize ---------- *)

Definition token := string.

Fixpoint tokenize_helper (cls : chartype) (acc xs : list ascii)
                       : list (list ascii) :=
  let tk := match acc with [] => [] | _::_ => [rev acc] end in
  match xs with
  | [] => tk
  | (x::xs') =>
    match cls, classifyChar x, x with
    | _, _, "("      =>
      tk ++ ["("]::(tokenize_helper other [] xs')
    | _, _, ")"      =>
      tk ++ [")"]::(tokenize_helper other [] xs')
    | _, white, _    =>
      tk ++ (tokenize_helper white [] xs')
    | alpha,alpha,x  =>
      tokenize_helper alpha (x::acc) xs'
    | digit,digit,x  =>
      tokenize_helper digit (x::acc) xs'
    | other,other,x  =>
      tokenize_helper other (x::acc) xs'
    | _,tp,x         =>
      tk ++ (tokenize_helper tp [x] xs')
    end
  end %char.

Definition tokenize (s : string) : list string :=
  map string_of_list (tokenize_helper white [] (list_of_string s)).

Open Scope string_scope.

(* 本章 token 集：固定符号 + 关键字，都由 tokenize 切成单 token *)
Definition symbols : list token :=
  ["("; ")"; "+"; "-"; "*"; "="; "<="; "&&"; "~"; ":="; ";"].

Definition keywords : list token :=
  ["skip"; "if"; "then"; "else"; "end"; "while"; "do"; "true"; "false"].

Example symbols_tokenize :
  map tokenize symbols = map (fun t => [t]) symbols.
Proof. reflexivity. Qed.

Example keywords_tokenize :
  map tokenize keywords = map (fun t => [t]) keywords.
Proof. reflexivity. Qed.

Example tokenize_ex1 :
    tokenize "abc12=3  223*(3+(a+c))" %string
  = ["abc"; "12"; "="; "3"; "223";
       "*"; "("; "3"; "+"; "(";
       "a"; "+"; "c"; ")"; ")"]%string.
Proof. reflexivity. Qed.

Example tokenize_fuse :
  tokenize "+-"%string = ["+-"]%string.
Proof. reflexivity. Qed.

(* ---------- 57.6 带错误信息的结果类型：optionE 与两条记号 ---------- *)

Inductive optionE (X : Type) : Type :=
  | SomeE (x : X)
  | NoneE (s : string).

Arguments SomeE {X}.
Arguments NoneE {X}.

Notation "' p <- e1 ;; e2"
   := (match e1 with
       | SomeE p => e2
       | NoneE err => NoneE err
       end)
   (right associativity, p pattern, at level 60, e1 at next level).

Notation "'TRY' e1 'OR' e2"
   := (
    let result := e1 in
    match result with
       | SomeE _  => result
       | NoneE _ => e2
       end)
   (right associativity,
    at level 60, e1 at next level, e2 at next level).

Fail Check [1] ++ [2].

Example optionE_chain :
  ' (n, rest) <- SomeE (41, ["x"]) ;;
  SomeE (n + 1, rest) = SomeE (42, ["x"]).
Proof. reflexivity. Qed.

Example optionE_shortcut :
  ' (n, rest) <- NoneE "no number" ;;
  SomeE (n + 1, rest)
  = (NoneE "no number" : optionE (nat * list token)).
Proof. reflexivity. Qed.

Example try_or_first :
  (TRY SomeE 3 OR SomeE 4) = (SomeE 3 : optionE nat).
Proof. reflexivity. Qed.

Example try_or_fallback :
  (TRY NoneE "first" OR SomeE 7) = (SomeE 7 : optionE nat).
Proof. reflexivity. Qed.

(* ---------- 57.7 解析器组合子：parser / many / firstExpect / expect ---------- *)

Definition parser (T : Type) :=
  list token -> optionE (T * list token).

Fail Fixpoint many_bad {T} (p : parser T) (xs : list token)
                       : optionE (list T * list token) :=
  match p xs with
  | NoneE _ => SomeE ([], xs)
  | SomeE (t, xs') =>
      ' (ts, rest) <- many_bad p xs' ;;
      SomeE (t :: ts, rest)
  end.

Fixpoint many_helper {T} (p : parser T) acc steps xs :=
  match steps, p xs with
  | 0, _ =>
      NoneE "Too many recursive calls"
  | _, NoneE _ =>
      SomeE ((rev acc), xs)
  | S steps', SomeE (t, xs') =>
      many_helper p (t :: acc) steps' xs'
  end.

Definition many {T} (p : parser T) (steps : nat) : parser (list T) :=
  many_helper p [] steps.

Definition firstExpect {T} (t : token) (p : parser T)
                     : parser T :=
  fun xs => match xs with
            | x::xs' =>
              if string_dec x t
              then p xs'
              else NoneE ("expected '" ++ t ++ "'.")
            | [] =>
              NoneE ("expected '" ++ t ++ "'.")
            end.

Definition expect (t : token) : parser unit :=
  firstExpect t (fun xs => SomeE (tt, xs)).

Example many_exhausted :
  many (expect "x") 1 ["x"; "x"] = NoneE "Too many recursive calls".
Proof. reflexivity. Qed.

Example many_two :
  many (expect "x") 3 ["x"; "x"] = SomeE ([tt; tt], []).
Proof. reflexivity. Qed.

Example many_zero :
  many (expect "x") 5 [] = SomeE ([], []).
Proof. reflexivity. Qed.

(* ---------- 57.8 标识符与数字：最底层的两个原子解析器 ---------- *)

Definition parseIdentifier (xs : list token)
                         : optionE (string * list token) :=
match xs with
| [] => NoneE "Expected identifier"
| x::xs' =>
    if forallb isLowerAlpha (list_of_string x) then
      SomeE (x, xs')
    else
      NoneE ("Illegal identifier:'" ++ x ++ "'")
end.

Definition parseNumber (xs : list token)
                     : optionE (nat * list token) :=
match xs with
| [] => NoneE "Expected number"
| x::xs' =>
    if forallb isDigit (list_of_string x) then
      SomeE (fold_left
               (fun n d =>
                  10 * n + (nat_of_ascii d -
                            nat_of_ascii "0"%char))
               (list_of_string x)
               0,
             xs')
    else
      NoneE "Expected number"
end.

Example parseIdentifier_ok :
  parseIdentifier ["abc"; "+"] = SomeE ("abc", ["+"]).
Proof. reflexivity. Qed.

Example parseIdentifier_bad :
  parseIdentifier ["X"; ":="] = NoneE "Illegal identifier:'X'".
Proof. reflexivity. Qed.

Example parseNumber_ok :
  parseNumber ["314"; ")"] = SomeE (314, [")"]).
Proof. reflexivity. Qed.

(* ---------- 57.9 算术表达式：初级/乘法/加法三级互递归 ---------- *)

Fixpoint parsePrimaryExp (steps : nat)
                         (xs : list token)
                       : optionE (aexp * list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
      TRY ' (i, rest) <- parseIdentifier xs ;;
          SomeE (AId i, rest)
      OR
      TRY ' (n, rest) <- parseNumber xs ;;
          SomeE (ANum n, rest)
      OR
      ' (e, rest) <- firstExpect "(" (parseSumExp steps') xs ;;
      ' (u, rest') <- expect ")" rest ;;
      SomeE (e, rest')
  end

with parseProductExp (steps : nat)
                     (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (e, rest) <- parsePrimaryExp steps' xs ;;
    ' (es, rest') <- many (firstExpect "*" (parsePrimaryExp steps'))
                          steps' rest ;;
    SomeE (fold_left AMult es e, rest')
  end

with parseSumExp (steps : nat) (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (e, rest) <- parseProductExp steps' xs ;;
    ' (es, rest') <-
        many (fun xs =>
                TRY ' (e, rest') <-
                    firstExpect "+"
                                (parseProductExp steps') xs ;;
                    SomeE ( (true, e), rest')
                OR
                ' (e, rest') <-
                    firstExpect "-"
                                (parseProductExp steps') xs ;;
                    SomeE ( (false, e), rest'))
        steps' rest ;;
      SomeE (fold_left (fun e0 term =>
                          match term with
                          | (true,  e) => APlus e0 e
                          | (false, e) => AMinus e0 e
                          end)
                       es e,
             rest')
  end.

Definition parseAExp := parseSumExp.

Definition testParsing {X : Type}
           (p : nat -> list token -> optionE (X * list token))
           (s : string) :=
  let t := tokenize s in
  p 100 t.

Example parseAExp_ex :
  testParsing parseAExp "1+2*y" = SomeE (<{1 + 2 * "y"}>, []).
Proof. reflexivity. Qed.

Example parseAExp_leftassoc :
  testParsing parseAExp "x-y-z" = SomeE (<{"x" - "y" - "z"}>, []).
Proof. reflexivity. Qed.

Example parseAExp_fuel_short :
  parseAExp 2 (tokenize "1+2") = NoneE "Too many recursive calls".
Proof. reflexivity. Qed.

(* ---------- 57.10 布尔表达式：原子与合取两级互递归 ---------- *)

Fixpoint parseAtomicExp (steps : nat)
                        (xs : list token) :=
match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
     TRY ' (u, rest) <- expect "true" xs ;;
         SomeE (BTrue, rest)
     OR
     TRY ' (u, rest) <- expect "false" xs ;;
         SomeE (BFalse, rest)
     OR
     TRY ' (e, rest) <- firstExpect "~"
                                   (parseAtomicExp steps')
                                   xs ;;
         SomeE (BNot e, rest)
     OR
     TRY ' (e, rest) <- firstExpect "("
                                   (parseConjunctionExp steps')
                                   xs ;;
         ' (u, rest') <- expect ")" rest ;;
         SomeE (e, rest')
     OR
     ' (e, rest) <- parseProductExp steps' xs ;;
     TRY ' (e', rest') <- firstExpect "="
                                  (parseAExp steps') rest ;;
         SomeE (BEq e e', rest')
     OR
     TRY ' (e', rest') <- firstExpect "<="
                                      (parseAExp steps') rest ;;
         SomeE (BLe e e', rest')
     OR
     NoneE "Expected '=' or '<=' after arithmetic expression"
end

with parseConjunctionExp (steps : nat)
                         (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (e, rest) <- parseAtomicExp steps' xs ;;
    ' (es, rest') <- many (firstExpect "&&"
               (parseAtomicExp steps'))
            steps' rest ;;
    SomeE (fold_left BAnd es e, rest')
  end.

Definition parseBExp := parseConjunctionExp.

Example parseBExp_ex :
  testParsing parseBExp "~(x=x&&x*x<=2)"
  = SomeE (<{~ ("x" = "x" && "x" * "x" <= 2)}>, []).
Proof. reflexivity. Qed.

(* ---------- 57.11 命令与总入口 parse ---------- *)

Fixpoint parseSimpleCommand (steps : nat)
                            (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    TRY ' (u, rest) <- expect "skip" xs ;;
        SomeE (<{skip}>, rest)
    OR
    TRY ' (e, rest) <-
            firstExpect "if"
                        (parseBExp steps') xs ;;
        ' (c, rest') <-
            firstExpect "then"
                        (parseSequencedCommand steps') rest ;;
        ' (c', rest'') <-
            firstExpect "else"
                        (parseSequencedCommand steps') rest' ;;
        ' (tt, rest''') <-
            expect "end" rest'' ;;
       SomeE (<{if e then c else c' end}>, rest''')
    OR
    TRY ' (e, rest) <-
            firstExpect "while"
                        (parseBExp steps') xs ;;
        ' (c, rest') <-
            firstExpect "do"
                        (parseSequencedCommand steps') rest ;;
        ' (u, rest'') <-
            expect "end" rest' ;;
        SomeE (<{while e do c end}>, rest'')
    OR
    TRY ' (i, rest) <- parseIdentifier xs ;;
        ' (e, rest') <- firstExpect ":=" (parseAExp steps') rest ;;
        SomeE (<{i := e}>, rest')
    OR
        NoneE "Expecting a command"
end

with parseSequencedCommand (steps : nat)
                           (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (c, rest) <- parseSimpleCommand steps' xs ;;
    TRY ' (c', rest') <-
            firstExpect ";"
                        (parseSequencedCommand steps') rest ;;
        SomeE (<{c ; c'}>, rest')
    OR
    SomeE (c, rest)
  end.

Definition bignumber := 1000.

Definition parse (str : string) : optionE com :=
  let tokens := tokenize str in
  match parseSequencedCommand bignumber tokens with
  | SomeE (c, []) => SomeE c
  | SomeE (_, t::_) => NoneE ("Trailing tokens remaining: " ++ t)
  | NoneE err => NoneE err
  end.

Compute parse "x := 1".

Compute parse "x := (1 + 2".

Example parse_trailing :
  parse "x := 1 y := 2" = NoneE "Trailing tokens remaining: y".
Proof. reflexivity. Qed.

(* ---------- 57.12 实测：两段完整源文本变成 AST ---------- *)

Example eg1 : parse "
  if x = y + 1 + 2 - y * 6 + 3 then
    x := x * 1;
    y := 0
  else
    skip
  end  "
=
  SomeE <{
      if ("x" = ("y" + 1 + 2 - "y" * 6 + 3)) then
        "x" := "x" * 1;
        "y" := 0
      else
        skip
      end }>.
Proof. cbv. reflexivity. Qed.

Example eg2 : parse "
  skip;
  z:=x*y*(x*x);
  while x=x do
    if (z <= z*z) && ~(x = 2) then
      x := z;
      y := z
    else
      skip
    end;
    skip
  end;
  x:=z  "
=
  SomeE <{
      skip;
      "z" := "x" * "y" * ("x" * "x");
      while ("x" = "x") do
        if ("z" <= "z" * "z") && ~("x" = 2) then
          "x" := "z";
          "y" := "z"
        else
          skip
        end;
        skip
      end;
      "x" := "z" }>.
Proof. cbv. reflexivity. Qed.

End Ex57Parsing.
