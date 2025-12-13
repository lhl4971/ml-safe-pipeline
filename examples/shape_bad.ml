open Shape_safe

module D = Dim
module L = Layer

let p1 : (D.d128, D.d256) L.dense_params =
  { name = "dense_128_256" }

(* Intentionally misspelled: The input is d128, but the previous layer output is d256 *)
let p_bad : (D.d128, D.d10) L.dense_params =
  { name = "dense_128_10" }

let _bad =
  L.(dense p1 >>> dense p_bad)