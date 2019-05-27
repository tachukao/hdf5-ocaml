open Hdf5_caml

module Record = struct
  [%%h5struct
  sf64 "sf64" Float64 Seek;
  si "si" Int Seek;
  si64 "si64" Int64 Seek;
  ss "ss" (String 14) Seek;
  f64 "f64" Float64;
  i "i" Int;
  i64 "i64" Int64;
  s "s" (String 16)]
end

let () =
  let len = 1000 in
  let a =
    Record.Array.init len (fun i e ->
        let f = float_of_int i in
        let i64 = Int64.of_int i in
        let s = string_of_int i in
        Record.set e ~sf64:f ~si:i ~si64:i64 ~ss:s ~f64:f ~i ~i64 ~s)
  in
  let expected_val e i =
    let f = float_of_int i in
    let i64 = Int64.of_int i in
    let s = string_of_int i in
    Record.sf64 e = f
    && Record.si e = i
    && Record.si64 e = i64
    && Record.ss e = s
    && Record.f64 e = f
    && Record.i e = i
    && Record.i64 e = i64
    && Record.s e = s
    && Record.pos e = i
  in
  for i = 0 to len - 1 do
    let e = Record.Array.get a i in
    assert (expected_val e i)
  done;
  let e = Record.Array.get a 0 in
  for i = 0 to len - 2 do
    assert (expected_val e i);
    Record.next e
  done;
  assert (expected_val e (len - 1));
  for i = len - 1 downto 1 do
    assert (expected_val e i);
    Record.prev e
  done;
  assert (expected_val e 0);
  for i = 0 to len - 1 do
    Record.move e i;
    assert (expected_val e i)
  done;
  let r = Array.init len (fun i -> i) in
  for i = 0 to len - 2 do
    let j = i + Random.int (len - i) in
    let r_i = r.(i) in
    r.(i) <- r.(j);
    r.(j) <- r_i
  done;
  for i = 0 to len - 1 do
    Record.seek_sf64 e (float_of_int r.(i));
    assert (expected_val e r.(i))
  done;
  for i = 0 to len - 1 do
    Record.seek_si e r.(i);
    assert (expected_val e r.(i))
  done;
  for i = 0 to len - 1 do
    Record.seek_si64 e (Int64.of_int r.(i));
    assert (expected_val e r.(i))
  done;
  for _ = 0 to len - 1 do
    let f = Random.float (float_of_int len) in
    Record.seek_sf64 e f;
    assert (Record.sf64 e <= f);
    assert (Record.sf64 e +. 1. > f);
    Record.seek_sf64 e f;
    assert (Record.sf64 e <= f);
    assert (Record.sf64 e +. 1. > f)
  done;
  for _ = 0 to len - 1 do
    let i = Random.int len in
    Record.seek_si e i;
    assert (Record.si e <= i);
    assert (Record.si e + 1 > i);
    Record.seek_si e i;
    assert (Record.si e <= i);
    assert (Record.si e + 1 > i)
  done;
  for _ = 0 to len - 1 do
    let i = Int64.of_int (Random.int len) in
    Record.seek_si64 e i;
    assert (Record.si64 e <= i);
    assert (Int64.add (Record.si64 e) 1L > i);
    Record.seek_si64 e i;
    assert (Record.si64 e <= i);
    assert (Int64.add (Record.si64 e) 1L > i)
  done;
  let v = Record.Vector.create () in
  let e = Record.Vector.get v 0 in
  for i = 0 to len - 1 do
    let e' = Record.Vector.append v in
    if i > 0 then Record.next e;
    Record.set_i e' i;
    assert (Record.i e = i)
  done;
  let _ = Marshal.to_string (module Record : Hdf5_caml.Struct_intf.S) [ Closures ] in
  let h5 = H5.create_trunc "test.h5" in
  Record.Array.make_table a h5 "f\\o/o";
  Record.Array.write a h5 "b\\a/r";
  H5.close h5;
  let h5 = H5.open_rdonly "test.h5" in
  assert (H5.ls ~order:INC h5 = [ "b\\a/r"; "f\\o/o" ]);
  Record.Array.read_table h5 "f\\o/o"
  |> Record.Array.iteri ~f:(fun i e -> assert (expected_val e i));
  Record.Array.read h5 "b\\a/r"
  |> Record.Array.iteri ~f:(fun i e -> assert (expected_val e i));
  H5.close h5
