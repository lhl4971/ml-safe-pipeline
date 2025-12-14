open Shape_safe

module D  = Dim
module L  = Layer
module M  = Model
module DS = Dataset
module A  = Adversarial

let p : (D.d128, D.d10) L.dense_params = { name = "dense_128_10" }
let arch : (D.batch, D.d128, D.d10) L.t = L.dense p

let () =
  (* Load clean datasets *)
  let train_raw = A.load_clean_train_raw ~path:"train.csv" in
  let test_raw  = A.load_clean_test_raw  ~path:"test.csv"  in

  (* Fit normalizer only on CLEAN Train Raw (anti-leakage still holds) *)
  let n = A.fit_norm train_raw in

  (* Normalize *)
  let train_norm = A.apply_norm n train_raw in
  let test_norm  = A.apply_norm n test_raw in

  (* Normal training: only Clean data allowed *)
  let m0 = M.init ~name:"m" arch in
  let m1 = A.train_clean train_norm m0 in

  (* Generate adversarial examples from clean data using a trained model *)
  let adv_train = A.gen_adversarial m1 (A.FGSM { eps = 0.03 }) train_norm in

  (* Adversarial training is explicit and separate *)
  let m0' = M.reset m1 in
  let m2  = A.train_adversarial train_norm adv_train m0' in

  (* Evaluation accepts any origin *)
  let _score = A.evaluate test_norm m2 in
  ()