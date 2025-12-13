open Shape_safe

module D = Dim
module T = Tensor
module L = Layer
module M = Model

let p1 : (D.d128, D.d256) L.dense_params = { name = "dense_128_256" }
let p2 : (D.d256, D.d10)  L.dense_params = { name = "dense_256_10" }

let net : (D.batch, D.d128, D.d10) L.t =
  L.(dense p1 >>> relu >>> dense p2)

let () =
  let m0 : (D.batch, D.d128, D.d10, M.untrained) M.t =
    M.init ~name:"m" net
  in
  let m1 = M.train m0 ~train_data:"train.csv" in
  let _y1 = M.predict_trained m1 T.dummy in
  let m2 = M.validate m1 ~val_data:"val.csv" in
  let _y2 = M.predict_validated m2 T.dummy in
  ()