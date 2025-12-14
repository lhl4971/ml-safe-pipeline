(*
  privacy.ml — Privacy-aware types (Differential Privacy) with typed epsilon budget

  OCaml does not support full dependent types, so we approximate ε using:
    - type-level naturals (zero/succ) where succ is injective
    - GADT witnesses for addition (plus) and ordering (leq)

  This enables:
    - Public vs Private ε tagging in types
    - type-level tracking of privacy budget under composition
    - preventing release unless ε ≤ ε_safe (policy threshold)
*)

(* --- Type-level naturals (injective encoding) --- *)
type zero
type 'n succ = 'n * unit  (* IMPORTANT: injective type constructor *)

type _ nat =
  | Z : zero nat
  | S : 'n nat -> ('n succ) nat

(* Type-level addition witness: plus a b c means a + b = c *)
type (_,_,_) plus =
  | PlusZ : (zero,'b,'b) plus
  | PlusS : ('a,'b,'c) plus -> ('a succ,'b,'c succ) plus

(* Type-level ≤ witness: leq a b means a ≤ b *)
type (_,_) leq =
  | LeqZ : (zero,'b) leq
  | LeqS : ('a,'b) leq -> ('a succ,'b succ) leq

(* --- Privacy levels --- *)
type public
type 'eps private_

(* Wrapper so privacy tags cannot be erased by type expansion *)
type ('p,'a) data = Data of 'a

let public (x:'a) : (public,'a) data = Data x
let private_ (x:'a) : ('eps private_,'a) data = Data x

(* --- DP operations --- *)

(*
  Adding noise consumes privacy budget:
    Private ε0  --add_noise with ε1-->  Private (ε0 + ε1)

  We require an explicit witness (ε0 + ε1 = ε2).
*)
let add_noise :
  type e0 e1 e2 a.
  (e0,e1,e2) plus ->
  eps:e1 nat ->
  (e0 private_, a) data ->
  (e2 private_, a) data
= fun _plus ~eps:_ (Data x) ->
  (* placeholder: real DP would add noise calibrated to eps *)
  Data x

(*
  Release policy:
    - public data can always be released
    - private data can be released only if ε ≤ ε_safe (proof required)
*)
let release_public : type a. (public,a) data -> a =
  fun (Data x) -> x

let release_private :
  type eps eps_safe a.
  (eps, eps_safe) leq ->
  eps_safe:eps_safe nat ->
  (eps private_, a) data ->
  a
= fun _proof ~eps_safe:_ (Data x) ->
  x

(* Convenient epsilon witnesses *)
let eps0 : zero nat = Z
let eps1 : zero succ nat = S Z
let eps2 : (zero succ) succ nat = S eps1