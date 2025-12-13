open Shape_safe

module D = Dim
module L = Layer
module M = Model
module DS = Dataset

let p : (D.d128, D.d10) L.dense_params = { name = "dense_128_10" }
let arch : (D.batch, D.d128, D.d10) L.t = L.dense p

let () =
  let train_raw : (DS.train, DS.raw, D.batch, D.d128, D.d10) DS.t =
    DS.load_train_raw ~path:"train.csv"
  in
  let m0 = M.init ~name:"m" arch in
  let _m1 = M.train_on train_raw m0 in
  ()