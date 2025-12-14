(*
  adversarial.ml — Origin-labeled data to prevent mixing Clean/Adversarial/Suspicious

  Goal:
    Prevent accidental mixing of adversarial examples with clean data
    in the training pipeline using phantom types.

  Requirements encoded in types:
    - Data is labeled as Clean / Adversarial / Suspicious
    - Normal training does NOT accept Adversarial data
    - Adversarial training is a separate operation that accepts both
    - Adversarial examples can be generated ONLY from Clean data using a trained model
    - Evaluation works on data of any origin

  Note: This is a type-level demo; no real ML computation is performed.
*)

(* Origin markers (phantom types) *)
type clean
type adversarial
type suspicious

(*
  IMPORTANT:
  We must NOT use a type alias here, otherwise the origin tag disappears after expansion.
  We use a wrapper so that 'origin remains in the type and affects type checking.
*)
type ('origin, 'split, 'proc, 'b, 'inp, 'out) data =
  Data of ('split, 'proc, 'b, 'inp, 'out) Dataset.t

let unwrap (Data d) = d

(* A minimal "attack" description (for documentation / API separation). *)
type attack =
  | FGSM of { eps : float }
  | PGD of { eps : float; steps : int }
  | DeepFool

(* --- Loading clean data --- *)

let load_clean_train_raw ~(path : string)
  : (clean, Dataset.train, Dataset.raw, 'b, 'inp, 'out) data =
  Data (Dataset.load_train_raw ~path)

let load_clean_valid_raw ~(path : string)
  : (clean, Dataset.valid, Dataset.raw, 'b, 'inp, 'out) data =
  Data (Dataset.load_valid_raw ~path)

let load_clean_test_raw ~(path : string)
  : (clean, Dataset.test, Dataset.raw, 'b, 'inp, 'out) data =
  Data (Dataset.load_test_raw ~path)

(* --- Normalization (reusing Part 3) --- *)

let fit_norm
    (Data d : (clean, Dataset.train, Dataset.raw, 'b, 'inp, 'out) data)
  : ('b, 'inp) Dataset.normalizer =
  Dataset.fit_norm d

let apply_norm
    (n : ('b, 'inp) Dataset.normalizer)
    (Data d : ('origin, 'split, Dataset.raw, 'b, 'inp, 'out) data)
  : ('origin, 'split, Dataset.normalized, 'b, 'inp, 'out) data =
  Data (Dataset.apply_norm n d)

(* --- Adversarial example generation --- *)

(*
  Generate adversarial examples from clean data using a TRAINED model.

  Type-level guarantees:
    - input data must be Clean
    - model must be Trained (so it can be attacked)
    - output data is labeled Adversarial
*)
let gen_adversarial
    (_m : ('b, 'inp, 'out, Model.trained) Model.t)
    (_atk : attack)
    (Data d : (clean, 'split, 'proc, 'b, 'inp, 'out) data)
  : (adversarial, 'split, 'proc, 'b, 'inp, 'out) data =
  Data d

(* --- Training APIs (separate normal vs adversarial training) --- *)

(*
  Normal training: only accepts CLEAN data (and Train + Normalized).
  This prevents accidental use of adversarial samples in the standard train path.
*)
let train_clean
    (Data d : (clean, Dataset.train, Dataset.normalized, 'b, 'inp, 'out) data)
    (m : ('b, 'inp, 'out, Model.untrained) Model.t)
  : ('b, 'inp, 'out, Model.trained) Model.t =
  Model.train_on d m

(*
  Adversarial training: separate operation that accepts BOTH clean and adversarial data.
  (We model this as a single API to make the separation explicit.)
*)
let train_adversarial
    (_clean : (clean, Dataset.train, Dataset.normalized, 'b, 'inp, 'out) data)
    (_adv   : (adversarial, Dataset.train, Dataset.normalized, 'b, 'inp, 'out) data)
    (m : ('b, 'inp, 'out, Model.untrained) Model.t)
  : ('b, 'inp, 'out, Model.trained) Model.t =
  { m with name = m.name ^ "_adv_trained" }

(* --- Evaluation --- *)

(*
  Evaluation accepts data of ANY origin.
  This is safe because evaluation is not training (does not mutate the model).
*)
let evaluate
    (Data d : ('origin, Dataset.test, Dataset.normalized, 'b, 'inp, 'out) data)
    (_m : ('b, 'inp, 'out, Model.trained) Model.t)
  : float =
  ignore d;
  0.0
(*
  Bonus idea (data poisoning):
    Extend origin with a "trust" or "label integrity" tag:

      type trusted
      type untrusted

    and require training to use trusted labels only, while allowing
    evaluation on both.
*)