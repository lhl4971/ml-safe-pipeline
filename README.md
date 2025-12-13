# Type-Safe ML Pipeline (Course Project)

This project demonstrates how **static types** (phantom types and GADTs) can be used
to enforce important **safety invariants in machine learning pipelines at compile time**.

The code is written in **OCaml**, following the style used in the course materials.
The goal is not to implement a real ML framework, but to show how *types alone*
can prevent entire classes of errors and attacks.

This README documents the design decisions and guarantees of each stage.

---

## Part 1 — Shape-Safe Neural Network Architecture

This part demonstrates how the type system enforces **shape consistency**
between neural network layers at compile time.

### Relevant Files

**Core implementation**
- `src/dim.ml`  
  Phantom types representing feature dimensions (e.g. `d128`, `d256`).

- `src/tensor.ml`  
  Tensor type carrying batch and feature dimensions at the type level.

- `src/layer.ml`  
  Shape-safe layer definitions using GADTs and a type-safe composition operator.

- `src/shape_safe.ml`  
  Public entry point re-exporting the core modules.

---

### Test / Example Files

**Correct example (compiles successfully)**
- `examples/shape_good.ml`  
  Demonstrates a well-typed network where all layer dimensions match.

**Incorrect example (rejected at compile time)**
- `examples/shape_bad.ml`  
  Attempts to compose layers with incompatible dimensions and fails
  with a type error (`d256 ≠ d128`).

---

### What Is Guaranteed

- Layers can only be composed if their input/output dimensions match
- Shape mismatch errors are detected at compile time
- No runtime shape checks are required


## Part 2 — Model Lifecycle and States

This part demonstrates how the type system enforces the **correct lifecycle**
of a machine learning model:

Untrained → Trained → Validated

Invalid state transitions are rejected at compile time.

---

### Relevant Files

**Core implementation**
- `src/model.ml`  
  Model definition with phantom lifecycle states (`untrained`, `trained`, `validated`)
  and a typed API enforcing valid state transitions.

- `src/layer.ml`  
  Used as the underlying, shape-safe architecture for the model.

- `src/tensor.ml`  
  Provides the typed tensor interface required for prediction.

- `src/shape_safe.ml`  
  Re-exports the model and related modules.

---

### Test / Example Files

**Correct example (compiles successfully)**
- `examples/lifecycle_good.ml`  
  Demonstrates a valid workflow:
  initialization → training → validation → prediction.

**Incorrect examples (rejected at compile time)**

- `examples/lifecycle_bad_untrained_predict.ml`  
  Attempts to perform prediction on an untrained model.

- `examples/lifecycle_bad_double_train.ml`  
  Attempts to train a model that is already trained.

- `examples/lifecycle_bad_validate_before_train.ml`  
  Attempts to validate a model before it has been trained.

Each incorrect example fails with a type error, demonstrating that
the lifecycle invariants are enforced statically.

---

### What Is Guaranteed

- Prediction is impossible on untrained models
- Training can only occur once without an explicit reset
- Validation is only allowed after training
- Invalid lifecycle transitions are rejected at compile time


## Part 3 — Type-Safe Datasets & Data Leakage Prevention

This part demonstrates how the type system tracks dataset **splits** and **processing stages**
to prevent common pipeline bugs and data leakage at compile time.

---

### Relevant Files

**Core implementation**
- `src/dataset.ml`  
  Defines a parametrized dataset type using phantom types for:
  - split: `train | valid | test`
  - processing: `raw | normalized`  
  Also defines typed operations such as loading, splitting, fitting normalization
  parameters (Train-only), and applying normalization.

- `src/model.ml`  
  Adds a dataset-driven training API (e.g. `train_on`) that only accepts
  `Train + Normalized` datasets.

- `src/shape_safe.ml`  
  Re-exports `Dataset` together with other modules.

---

### Test / Example Files

**Correct example (compiles successfully)**
- `examples/dataset_good.ml`  
  Demonstrates a safe workflow:
  - load Train/Test as Raw
  - fit normalization only on Train Raw
  - apply the fitted normalizer to Train/Test (Raw → Normalized)
  - train the model only on Train Normalized

**Incorrect examples (rejected at compile time)**
- `examples/dataset_bad_train_on_test.ml`  
  Attempts to train on `Test` data.

- `examples/dataset_bad_train_on_raw.ml`  
  Attempts to train on `Raw` (non-normalized) data.

- `examples/dataset_bad_fit_norm_on_test.ml`  
  Attempts to compute normalization parameters on non-Train data
  (data leakage).

---

### What Is Guaranteed

- Models can only be trained on `Train` data
- Training requires `Normalized` data (Raw is rejected)
- Normalization parameters can only be fitted on `Train` data (anti-leakage)
- Invalid pipelines are rejected at compile time