open Shape_safe

module D = Dim
module T = Tensor
module L = Layer

let p1 : (D.d128, D.d256) L.dense_params =
  { name = "dense_128_256" }

let p2 : (D.d256, D.d10) L.dense_params =
  { name = "dense_256_10" }

let net : (D.batch, D.d128, D.d10) L.t =
  L.(dense p1 >>> relu >>> dropout 0.1 >>> dense p2)

let x : (D.batch, D.d128) T.t =
  T.dummy

let _y : (D.batch, D.d10) T.t =
  L.run net x