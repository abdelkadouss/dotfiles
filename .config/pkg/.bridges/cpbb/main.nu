use ../../.api/bridges.nu *;

bridge new {
  info: {
    name: "cpbb",
    description: "the cargo pre build bins, cpbb in short",
    version: "0.1.0",
  },
  config: {
    isolate_path: true
    env: {
      CARGO_HOME: "__<PKG_TARGET_DIR>"
      CARGO_TARGET_DIR: "__<PKG_TARGET_DIR>/bin"
    },
    executables: [
      cargo,
      rustc
      cargo-binstall
    ],
  },
  usege: {
    install: {
      script: {|pkg:string|
        mkdir out;

        cargo binstall $pkg --root out -y
        | print -e $in;

        {
          version: (
            open out/.crates.toml
            | get v1
            | transpose k v
            | get k
            | first
            | split row " "
            | get 1
          )
          path: (ls out/bin | where type == file | get name | first)
        } | to json # FIXME: make an api
      }
    },
    remove: { },
    update: { },
    cleanup: {
      events: [ "AFTER_INSTALL", "AFTER_UPDATE" ],
    },
  },
}
