(*
  layer.ml — Shape-safe neural network layers (phantom types + GADT)

  Goal:
    Encode layer input/output dimensions in the type system, so that
    invalid architectures (shape mismatch) are rejected at compile time.

  Key idea:
    - Dimensions are phantom types (e.g., d128, d256, d10)
    - A layer carries (batch, input_dim, output_dim) in its type:
        ('b, 'i, 'o) t
    - Composition is only possible when the intermediate dimensions match
        ('b, 'a, 'm) t >>> ('b, 'm, 'c) t

  This file intentionally contains no real numeric computation.
  It is a minimal type-level model of shape checking for the assignment.
*)

(* Parameters of a Dense layer.
   The parameters carry phantom input/output dimensions ('i, 'o).
   In a real framework this would include weights/biases; here we keep only a name. *)
type ('i,'o) dense_params = {
  name : string;
}

(* GADT for layers.

   ('b, 'i, 'o) t means:
     - batch dimension phantom type: 'b
     - input feature dimension phantom type:  'i
     - output feature dimension phantom type: 'o

   Constructors:
     Dense   : transforms 'i -> 'o
     Relu    : preserves dimension 'd -> 'd
     Dropout : preserves dimension 'd -> 'd
     Seq     : sequential composition, only well-typed if the middle dims match
*)
type ('b,'i,'o) t =
  | Dense   : ('i,'o) dense_params -> ('b,'i,'o) t
  | Relu    : ('b,'d,'d) t
  | Dropout : float -> ('b,'d,'d) t
  | Seq     : ('b,'a,'m) t * ('b,'m,'c) t -> ('b,'a,'c) t

(* Smart constructors (purely for readability). *)
let dense (p : ('i,'o) dense_params) : ('b,'i,'o) t =
  Dense p

let relu : ('b,'d,'d) t =
  Relu

let dropout (p:float) : ('b,'d,'d) t =
  Dropout p

(*
  Type-safe composition operator.

  The type forces the output dimension of the first layer to be exactly the
  input dimension of the second layer:

    (>>>)
      : ('b,'a,'m) t   -> ('b,'m,'c) t   -> ('b,'a,'c) t

  If you attempt to connect mismatching layers (e.g., d256 -> d128),
  the compiler will reject the program with a type error.
*)
let ( >>> )
  (l1 : ('b,'a,'m) t)
  (l2 : ('b,'m,'c) t)
  : ('b,'a,'c) t =
  Seq (l1, l2)

(*
  Forward propagation (type demonstration only).

  We define a minimal "run" that propagates shapes through the network:
    run : layer ('b,'i,'o) -> tensor ('b,'i) -> tensor ('b,'o)

  No real computation happens:
    - Dense returns a dummy tensor of the correct output shape
    - Relu/Dropout return the input tensor unchanged (shape-preserving)
    - Seq composes runs; the types ensure intermediate shapes match
*)
let rec run :
  type b i o.
  (b,i,o) t -> (b,i) Tensor.t -> (b,o) Tensor.t =
 fun layer x ->
  match layer with
  | Dense _ ->
      (* Dense changes feature dimension: (b,i) -> (b,o). *)
      Tensor.T
  | Relu ->
      (* Shape-preserving activation: (b,d) -> (b,d). *)
      x
  | Dropout _ ->
      (* Shape-preserving regularization: (b,d) -> (b,d). *)
      x
  | Seq (l1, l2) ->
      (* Sequential composition:
         run l1 : (b,a) -> (b,m)
         run l2 : (b,m) -> (b,c)
         The GADT ensures m matches in both places. *)
      let y = run l1 x in
      run l2 y