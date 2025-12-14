open Shape_safe

module D  = Dim
module L  = Layer
module M  = Model
module A  = Adversarial

let p : (D.d128, D.d10) L.dense_params = { name = "dense_128_10" }
let arch : (D.batch, D.d128, D.d10) L.t = L.dense p

let () =
  let m0 = M.init ~name:"m" arch in

  (* Fake: suppose we already have adversarial Train Normalized data *)
  let adv_train :
    (A.adversarial, Dataset.train, Dataset.normalized, D.batch, D.d128, D.d10) A.data =
    A.Data Dataset.DS
  in

  (* Should FAIL: normal training does not accept adversarial data *)
  let _m1 = A.train_clean adv_train m0 in
  ()