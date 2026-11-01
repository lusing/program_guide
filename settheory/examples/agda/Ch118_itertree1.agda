module Ch118_itertree1 where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<ᵇ_)
open import Data.Bool using (if_then_else_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Data.Unit using (⊤; tt)
open import Data.Product using (_×_; _,_)

-- 有限节点和 extender 标签；不把有限数字模型冒充真实准模块。
data Node : Set where N0 N1 N2 N3 N4 N5 N6 : Node
data Ext : Set where E0 E1 E2 E3 E4 E5 : Ext

parent : Node → Node
parent N0 = N0
parent N1 = N0
parent N2 = N0
parent N3 = N1
parent N4 = N2
parent N5 = N3
parent N6 = N4

source : Ext → Node
source E0 = N0
source E1 = N1
source E2 = N2
source E3 = N3
source E4 = N4
source E5 = N5

target : Ext → Node
target E0 = N0
target E1 = N0
target E2 = N1
target E3 = N2
target E4 = N3
target E5 = N4

child : Ext → Node
child E0 = N1
child E1 = N2
child E2 = N3
child E3 = N4
child E4 = N5
child E5 = N6

LegalApplication : Ext → Set
LegalApplication e = parent (child e) ≡ target e

legal-all : (e : Ext) → LegalApplication e
legal-all E0 = refl
legal-all E1 = refl
legal-all E2 = refl
legal-all E3 = refl
legal-all E4 = refl
legal-all E5 = refl

external-E1 : source E1 ≡ N1 × target E1 ≡ N0
external-E1 = refl , refl

-- Path 的索引记录终点；每个构造子恰好是一条指向新节点的合法边。
data Path : Node → Set where
  P0 : Path N0
  P1 : Path N0 → Path N1
  P2 : Path N0 → Path N2
  P3 : Path N1 → Path N3
  P4 : Path N2 → Path N4
  P5 : Path N3 → Path N5
  P6 : Path N4 → Path N6

path-unique : {n : Node} → (p q : Path n) → p ≡ q
path-unique P0 P0 = refl
path-unique (P1 p) (P1 q) = cong P1 (path-unique p q)
path-unique (P2 p) (P2 q) = cong P2 (path-unique p q)
path-unique (P3 p) (P3 q) = cong P3 (path-unique p q)
path-unique (P4 p) (P4 q) = cong P4 (path-unique p q)
path-unique (P5 p) (P5 q) = cong P5 (path-unique p q)
path-unique (P6 p) (P6 q) = cong P6 (path-unique p q)

even-prefix : Path N6
even-prefix = P6 (P4 (P2 P0))
odd-prefix : Path N5
odd-prefix = P5 (P3 (P1 P0))

crit : Ext → ℕ
crit E0 = 1
crit E1 = 2
crit E2 = 3
crit E3 = 4
crit E4 = 5
crit E5 = 6

strength : Ext → ℕ
strength e = crit e + 2

toy-embed : Ext → ℕ → ℕ
toy-embed e x = if x <ᵇ crit e then x else suc x

toy-below : toy-embed E2 1 ≡ 1
toy-below = refl
toy-moves : toy-embed E2 3 ≡ 4
toy-moves = refl
