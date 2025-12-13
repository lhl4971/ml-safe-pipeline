(*
  model.ml — Model lifecycle encoded with phantom types

  Goal:
    Statically enforce the correct lifecycle of a machine learning model:

      Untrained → Trained → Validated

    Incorrect usages (e.g., predicting before training, training twice,
    or validating an untrained model) must be rejected at compile time.

  Key idea:
    The lifecycle state of a model is represented by a phantom type parameter.
    Functions are typed so that only valid state transitions are expressible.

  This file contains no real training or evaluation logic.
  It is a type-level specification of a safe ML model lifecycle.
*)

(* Lifecycle state markers (phantom types).
   These types have no values and exist only at the type level. *)
type untrained
type trained
type validated

(*
  Model type.

  ('b, 'inp, 'out, 'st) t means:
    - 'b   : batch dimension (phantom, shared with tensors/layers)
    - 'inp : input feature dimension
    - 'out : output feature dimension
    - 'st  : lifecycle state (untrained | trained | validated)

  The architecture itself is shape-safe (see layer.ml);
  here we additionally track *when* the model may be used.
*)
type ('b, 'inp, 'out, 'st) t = {
  arch : ('b, 'inp, 'out) Layer.t;
  name : string;
}

(*
  Initialization.

  Creates a model in the untrained state.
  At this point:
    - training is allowed
    - prediction and validation are forbidden by the type system
*)
let init
    ~(name : string)
    (arch : ('b, 'inp, 'out) Layer.t)
  : ('b, 'inp, 'out, untrained) t =
  { arch; name }

(*
  Training.

  This function can only be applied to an untrained model.
  The result is a trained model.

  Attempting to train an already trained or validated model
  is rejected at compile time.
*)
let train
    (m : ('b, 'inp, 'out, untrained) t)
    ~(train_data : string)
  : ('b, 'inp, 'out, trained) t =
  ignore train_data;
  { m with name = m.name ^ "_trained" }

(*
  Validation.

  Validation is only allowed after training.
  The function encodes the transition:

      trained → validated

  Calling validate on an untrained model is a type error.
*)
let validate
    (m : ('b, 'inp, 'out, trained) t)
    ~(val_data : string)
  : ('b, 'inp, 'out, validated) t =
  ignore val_data;
  { m with name = m.name ^ "_validated" }

(*
  Explicit reset.

  This operation discards the training/validation state
  and returns the model to the untrained state.

  Reset must be explicit; without it, retraining is impossible.
*)
let reset
    (m : ('b, 'inp, 'out, 'st) t)
  : ('b, 'inp, 'out, untrained) t =
  { m with name = m.name ^ "_reset" }

(*
  Prediction.

  Prediction is only permitted on models that have been trained.
  There is intentionally no prediction function for untrained models.

  We provide two functions instead of overloading:
    - predict_trained
    - predict_validated

  This avoids ambiguity and makes the allowed states explicit.
*)

let predict_trained
    (m : ('b, 'inp, 'out, trained) t)
    (x : ('b, 'inp) Tensor.t)
  : ('b, 'out) Tensor.t =
  Layer.run m.arch x

let predict_validated
    (m : ('b, 'inp, 'out, validated) t)
    (x : ('b, 'inp) Tensor.t)
  : ('b, 'out) Tensor.t =
  Layer.run m.arch x