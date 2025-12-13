open Shape_safe

module D = Dim
module L = Layer
module M = Model
module DS = Dataset

let p : (D.d128, D.d10) L.dense_params = { name = "dense_128_10" }
let arch : (D.batch, D.d128, D.d10) L.t = L.dense p

let () =
  (* Load raw datasets *)
  let train_raw : (DS.train, DS.raw, D.batch, D.d128, D.d10) DS.t =
    DS.load_train_raw ~path:"train.csv"
  in
  let test_raw : (DS.test, DS.raw, D.batch, D.d128, D.d10) DS.t =
    DS.load_test_raw ~path:"test.csv"
  in

  (* Fit normalizer ONLY on Train Raw (anti-leakage) *)
  let n = DS.fit_norm train_raw in

  (* Apply the same normalizer to Train/Test (Raw -> Normalized) *)
  let train_norm = DS.apply_norm n train_raw in
  let _test_norm = DS.apply_norm n test_raw in

  (* Train only on Train + Normalized *)
  let m0 = M.init ~name:"m" arch in
  let _m1 = M.train_on train_norm m0 in
  ()