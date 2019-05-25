module C = Configurator.V1

let hdf5_default : C.Pkg_config.package_conf =
  let libs = ["-lhdf5"; "-lhdf5_hl"] in
  let p0 = "/usr/include/hdf5/serial" in
  let p1 = "/usr/lib/x86_64-linux-gnu/hdf5/serial" in
  let cflags =
    if Sys.file_exists p0 then ["-I" ^ p0] else if Sys.file_exists p1 then ["-I" ^ p1] else []
  in
  C.Pkg_config.{cflags; libs}

let () =
  C.main ~name:"hdf5-raw" (fun c ->
      let hdf5_conf =
        let open Base.Option.Monad_infix in
        Base.Option.value
          ~default:hdf5_default
          (C.Pkg_config.get c >>= C.Pkg_config.query ~package:"hdf5")
      in
      let libs = [] @ hdf5_conf.libs in
      let cflags = [] @ hdf5_conf.cflags in
      let conf : C.Pkg_config.package_conf = {cflags; libs} in
      C.Flags.write_sexp "c_flags.sexp" conf.cflags;
      C.Flags.write_sexp "c_library_flags.sexp" conf.libs )
