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