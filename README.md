# Type-Safe ML Pipeline (Course Project)

## Project Structure and Purpose

This project is organized as a collection of **small, independent examples**,
each illustrating a specific safety invariant enforced by the OCaml type system.

- The `src/` directory contains the core library implementing type-safe building blocks:
  tensors, layers, models, datasets, adversarial handling, and privacy tracking.

- The `examples/` directory contains executable examples divided into:
  - **good examples** — well-typed programs that compile successfully
  - **bad examples** — intentionally ill-typed programs that demonstrate
    which errors are rejected by the compiler

The project is designed so that **type errors correspond directly to violated
ML safety invariants**, such as data leakage, invalid model states, or privacy violations.

## Systematic Analysis of Safety Invariants

This section summarizes all **safety invariants** enforced by the type system
across Parts 1–6 and discusses the limitations of the approach.


### Enforced Safety Invariants

1. **Shape consistency**
   - **Forbidden:** composing layers with mismatched dimensions
   - **Enforced by:** phantom dimension types and GADT-typed layers
   - **Compiler error:** type mismatch (e.g. `d128 is not compatible with d256`)

2. **Model lifecycle correctness**
   - **Forbidden:** prediction on untrained models, repeated training
   - **Enforced by:** phantom lifecycle state in `Model.t`
   - **Compiler error:** state mismatch (`trained` vs `untrained`)

3. **Dataset split safety (no data leakage)**
   - **Forbidden:** training on `Test` data
   - **Enforced by:** phantom dataset split (`Train | Valid | Test`)
   - **Compiler error:** split mismatch (`test is not compatible with train`)

4. **Processing stage correctness**
   - **Forbidden:** training on raw (non-normalized) data
   - **Enforced by:** phantom processing stage (`Raw | Normalized`)
   - **Compiler error:** stage mismatch (`raw is not compatible with normalized`)

5. **Adversarial data separation**
   - **Forbidden:** using adversarial data in standard training
   - **Enforced by:** phantom origin labels (`Clean | Adversarial`)
   - **Compiler error:** origin mismatch (`adversarial is not compatible with clean`)

6. **Privacy budget enforcement**
   - **Forbidden:** releasing private data with insufficient privacy budget
   - **Enforced by:** type-level ε and GADT proofs (`leq`)
   - **Compiler error:** impossible proof construction (`ε ≤ ε_safe` cannot be derived)

All violations are detected **at compile time**, before program execution.


### Limitations of the Type-Based Approach

Some important invariants cannot be expressed using phantom types alone
and require runtime checks, testing, or full dependent types:

- Model accuracy is above a baseline
- Dataset is balanced across classes
- No duplicated samples between Train and Test
- Statistical robustness against adversarial attacks

These properties depend on runtime values or statistical guarantees
and are outside the scope of static typing in OCaml.


### Summary

The implemented type system eliminates a large class of ML pipeline errors
by construction. While not all properties are statically expressible,
the approach provides strong practical guarantees with zero runtime overhead.

## How to Build and Use the Project

### Prerequisites

- OCaml (via opam)
- dune build system


### Building Correct Examples Only

By default, the project is configured to compile only well-typed (correct) examples.

Command: ```dune build```

This command should succeed without errors and confirms that all safety invariants
are satisfied in the valid pipelines.


### Building Incorrect Examples (Demonstrating Compile-Time Rejection)

Incorrect examples are included in the repository but are disabled by default
to allow the project to build successfully.

They are defined in examples/dune under a stanza with: ```(enabled_if false)```

To observe the compile-time errors produced by the type system:

1. Edit examples/dune and change: ```(enabled_if false)``` to: ```(enabled_if true)```

2. Build a specific incorrect example, for example: ```dune build examples/shape_bad.exe```

The compiler will report a type error corresponding to a violated safety invariant
(e.g. shape mismatch, invalid dataset usage, or insufficient privacy budget).


### Intended Usage

This project is not intended as a production ML framework.
Instead, it serves as a didactic demonstration of how static types
(phantom types and GADTs) can encode and enforce non-trivial ML safety properties
before the program is ever run.