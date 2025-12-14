open Shape_safe

module P = Privacy

let () =
  let eps1 = P.eps1 in

  (* Private data with ε = 2 *)
  let d2 : ((P.zero P.succ) P.succ P.private_, int) P.data =
    P.private_ 7
  in

  (* Policy threshold ε_safe = 1 (too strict for ε=2) *)
  let eps_safe = eps1 in

  (* WRONG proof: 0 ≤ _  (cannot be used to prove 2 ≤ 1) *)
  let bogus : (P.zero, P.zero) P.leq = P.LeqZ in

  (* Should FAIL: expected a proof of (2 ≤ 1), but bogus is (0 ≤ 0) *)
  let _ = P.release_private bogus ~eps_safe d2 in
  ()