(*
  dataset.ml — Type-safe datasets (split + processing stage) and anti-leakage

  Goal:
    Encode dataset metadata in types so the compiler prevents:
      - training on Test data
      - feeding Raw data into functions requiring Normalized
      - computing normalization parameters (fit) on non-Train data (data leakage)

  Key idea:
    Use phantom types to mark:
      - split: train | valid | test
      - processing: raw | normalized

    Dataset carries:
      ('split, 'proc, 'b, 'inp, 'out) t
*)

(* Split markers *)
type train
type valid
type test

(* Processing markers *)
type raw
type normalized

(*
  Dataset type.

  ('split, 'proc, 'b, 'inp, 'out) t means:
    - 'split : train | valid | test
    - 'proc  : raw | normalized
    - 'b     : batch phantom
    - 'inp   : input feature dimension phantom
    - 'out   : output/label dimension phantom

  We do not store real data; this is a type-level demo.
*)
type ('split, 'proc, 'b, 'inp, 'out) t = DS

(*
  A fitted normalizer object.
  In a real system it would store mean/std etc.
  Here it is only a witness that "normalization parameters exist".
*)
type ('b, 'inp) normalizer = Norm

(* --- Loading data --- *)

(* For the demo we provide split-specific loaders. *)
let load_train_raw
    ~(path : string)
  : (train, raw, 'b, 'inp, 'out) t =
  ignore path;
  DS

let load_valid_raw
    ~(path : string)
  : (valid, raw, 'b, 'inp, 'out) t =
  ignore path;
  DS

let load_test_raw
    ~(path : string)
  : (test, raw, 'b, 'inp, 'out) t =
  ignore path;
  DS

(*
  Optional: split a training dataset into train/test.
  The key point is that the resulting types differ by split phantom.
*)
let split_train_test
    (d : (train, raw, 'b, 'inp, 'out) t)
  : (train, raw, 'b, 'inp, 'out) t * (test, raw, 'b, 'inp, 'out) t =
  ignore d;
  (DS, DS)

(* --- Normalization (anti-leakage) --- *)

(*
  Fit normalization parameters.
  IMPORTANT: allowed only on Train + Raw data.
  This is exactly the "no data leakage" invariant.
*)
let fit_norm
    (_d : (train, raw, 'b, 'inp, 'out) t)
  : ('b, 'inp) normalizer =
  Norm

(*
  Apply a fitted normalizer to any split, but only Raw -> Normalized.
  This allows using Train-fitted parameters on Validation/Test data safely.
*)
let apply_norm
    (_n : ('b, 'inp) normalizer)
    (_d : ('split, raw, 'b, 'inp, 'out) t)
  : ('split, normalized, 'b, 'inp, 'out) t =
  DS