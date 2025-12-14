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


## Part 4 — Connection to $\lambda P$ and Dependent Types

### Chosen Invariant

**A model can only be trained on Train data.**

---

### Invariant in $\lambda P$ Style

In a dependently typed system ($\lambda P$), the training function can be expressed as:

    train :
    Π (d : Dataset Train Normalized),
    Π (m : Model Untrained),
    Model Trained

This type directly encodes the invariant that only datasets whose split is
exactly `Train` may be used for training.

---

### Approximation with Phantom Types

In the ML implementation, the invariant is approximated using phantom types:

    train_on :
    (train, normalized, ...) Dataset.t ->
    Model untrained ->
    Model trained

The phantom type parameters train and normalized restrict the admissible
arguments at compile time, rejecting invalid usages such as training on
Test or Raw data.

---

### Limitation

Phantom types cannot express value-dependent properties
(e.g. dataset size, sample overlap, or exact provenance).
Such invariants require full dependent types as in $\lambda P$.

---

### Summary
- $\lambda P$ expresses the invariant exactly via dependent types
- Phantom types provide a practical but incomplete approximation
- Some properties remain inexpressible without full dependent typing


## Part 5 — Protection Against Adversarial Examples

This part demonstrates how the type system can be used to prevent
accidental mixing of clean and adversarial data in a machine learning pipeline.

Adversarial examples are specially crafted inputs designed to mislead a model.
In production systems, it is critical to separate such data from standard
training workflows.

---

### Core Idea

We extend datasets with an additional **origin label**, encoded as a phantom type:

- `Clean` — original, unperturbed data
- `Adversarial` — data generated by an attack using a trained model
- `Suspicious` — data of unknown or questionable origin

The origin label is enforced by the type system and cannot be ignored or mixed
implicitly.

---

### Relevant Files

**Core implementation**
- `src/adversarial.ml`  
  Defines origin-labeled data wrappers and typed APIs for:
  - loading clean data
  - generating adversarial examples
  - clean training vs adversarial training
  - evaluation on arbitrary data origins

- `src/dataset.ml`  
  Reused for split (`Train/Test`) and processing (`Raw/Normalized`) tracking.

- `src/model.ml`  
  Provides trained models required for adversarial example generation.

---

### Typed API Overview

- **Loading**
  - Clean data is loaded with an explicit `Clean` origin label.

- **Normal training**
  - `train_clean` accepts only `Clean + Train + Normalized` data.
  - Adversarial data is rejected at compile time.

- **Adversarial example generation**
  - `gen_adversarial` requires:
    - a *trained* model
    - *clean* input data
  - The result is explicitly labeled as `Adversarial`.

- **Adversarial training**
  - Implemented as a separate API.
  - Explicitly accepts both `Clean` and `Adversarial` datasets.
  - Cannot be confused with standard training.

- **Evaluation**
  - Works on data of any origin (`Clean`, `Adversarial`, or `Suspicious`).
  - Safe because evaluation does not modify the model.

---

### Test / Example Files

**Correct example (compiles successfully)**
- `examples/adv_good.ml`  
  Demonstrates:
  - clean training
  - adversarial example generation (FGSM)
  - explicit adversarial training
  - evaluation on arbitrary data

**Incorrect examples (rejected at compile time)**
- `examples/adv_bad_train_on_adv.ml`  
  Attempts to use adversarial data in normal training.

- `examples/adv_bad_gen_from_adv.ml`  
  Attempts to generate adversarial examples from non-clean data.

---

### How Types Prevent Unsafe Mixing

- Origin labels are encoded as phantom types in a wrapper type
- Normal training APIs only accept `Clean` data
- Adversarial data can only be used via explicit adversarial training APIs
- Accidental mixing of clean and adversarial data is rejected at compile time


## Part 6 — Privacy-Aware Types

This part demonstrates how privacy guarantees can be tracked at the type level
using a simplified model of **differential privacy**.

---

### Core Idea

Data is marked as either:

- `Public`
- `Private ε` — private data with a privacy budget `ε`

The privacy budget is encoded in the type and updated explicitly by operations.
Data cannot be released unless the privacy budget satisfies a safety threshold.

---

### Relevant Files

**Core implementation**
- `src/privacy.ml`  
  Defines privacy-aware wrapper types and typed operations for:
  - adding noise (consuming privacy budget)
  - releasing data under a policy

- `src/shape_safe.ml`  
  Re-exports the `Privacy` module.

---

### Test / Example Files

**Correct example (compiles successfully)**
- `examples/privacy_good.ml`  
  Demonstrates:
  - adding noise multiple times
  - tracking accumulated privacy budget
  - successful release when the budget is within the allowed threshold
  - unconditional release of public data

**Incorrect example (rejected at compile time)**
- `examples/privacy_bad_release.ml`  
  Attempts to release private data whose privacy budget exceeds the allowed limit.

---

### What Is Guaranteed

- Private data is always annotated with a privacy budget
- Adding noise explicitly consumes privacy budget
- Privacy budget is tracked across multiple operations
- Private data cannot be released unless it satisfies the policy
- Unsafe data release is rejected at compile time

---

### Real-World Context

Differential privacy is used in real systems such as:

- Google RAPPOR
- Apple Differential Privacy
- Federated learning with differential privacy