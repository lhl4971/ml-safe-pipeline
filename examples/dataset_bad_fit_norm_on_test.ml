open Shape_safe

module D = Dim
module DS = Dataset

let () =
  let test_raw : (DS.test, DS.raw, D.batch, D.d128, D.d10) DS.t =
    DS.load_test_raw ~path:"test.csv"
  in
  let _n = DS.fit_norm test_raw in
  ()