open Shape_safe

module P = Privacy

let () =
  (* Use the convenience epsilon witnesses from Privacy *)
  let eps1 = P.eps1 in
  let eps2 = P.eps2 in

  (* Private data with initial budget ε = 0 *)
  let d0 : (P.zero P.private_, int) P.data = P.private_ 42 in

  (* Add noise with ε = 1: 0 + 1 = 1 (proof: PlusZ) *)
  let d1 : (P.zero P.succ P.private_, int) P.data =
    P.add_noise P.PlusZ ~eps:eps1 d0
  in

  (* Add noise again with ε = 1: 1 + 1 = 2 (proof: PlusS PlusZ) *)
  let plus_1_1_2 : (P.zero P.succ, P.zero P.succ, (P.zero P.succ) P.succ) P.plus =
    P.PlusS P.PlusZ
  in
  let d2 : ((P.zero P.succ) P.succ P.private_, int) P.data =
    P.add_noise plus_1_1_2 ~eps:eps1 d1
  in

  (* Release policy: ε_safe = 2 *)
  let eps_safe = eps2 in

  (* Proof that 2 ≤ 2 *)
  let leq_2_2 : ((P.zero P.succ) P.succ, (P.zero P.succ) P.succ) P.leq =
    P.LeqS (P.LeqS P.LeqZ)
  in
  let _released_ok : int =
    P.release_private leq_2_2 ~eps_safe d2
  in

  (* Public data can always be released *)
  let pub : (P.public, string) P.data = P.public "hello" in
  let _ : string = P.release_public pub in
  ()