open Shape_safe

module D  = Dim
module L  = Layer
module M  = Model
module A  = Adversarial

let p : (D.d128, D.d10) L.dense_params = { name = "dense_128_10" }
let arch : (D.batch, D.d128, D.d10) L.t = L.dense p

let () =
  let m0 = M.init ~name:"m" arch in
  let m1 = M.train m0 ~train_data:"train.csv" in

  (* IMPORTANT: explicitly force the origin to be adversarial *)
  let adv_data :
    (A.adversarial, Dataset.train, Dataset.raw, D.batch, D.d128, D.d10) A.data =
    A.Data Dataset.DS
  in

  (* Should FAIL: gen_adversarial only accepts CLEAN input *)
  let _ = A.gen_adversarial m1 (A.FGSM { eps = 0.03 }) adv_data in
  ()