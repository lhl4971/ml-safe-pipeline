open Shape_safe

module D = Dim
module T = Tensor
module L = Layer
module M = Model

let p : (D.d128, D.d10) L.dense_params = { name = "dense_128_10" }
let net : (D.batch, D.d128, D.d10) L.t = L.dense p

let () =
  let m0 = M.init ~name:"m" net in
  let _ = M.predict_trained m0 T.dummy in
  ()