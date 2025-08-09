use ../../.api/bridges.nu *;

bridge new {
  info: {
    name: "nur",
    description: "the nix (i hate nix BTW) user repository",
    version: "0.1.0",
  },
  config: {
    isolate_path: true
    executables: [
      nix
    ],
  },
  usege: {
    install: {
      script: {|pkg:string, opts|
        nix profile install nixpkgs#($pkg) --profile ./out
        | print -e $in;

        {
          version: (
            nix profile show nixpkgs#($pkg) --profile ./out
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
