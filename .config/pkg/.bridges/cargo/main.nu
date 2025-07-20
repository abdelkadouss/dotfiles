use ../../.api/bridges.nu *;

bridge new {
  info: {
    name: "cargo",
    description: "A package manager for the Rust ecosystem",
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
    ],
  },
  usege: {
    install: {
      script: {|pkg:string|
        mkdir out;
        cargo install $pkg --root out
        {
          version: (
            cargo info $pkg
            | lines
            | get 2
            | split row ":"
            | get 1
            | str trim
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
