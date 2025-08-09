use ../../.api/bridges.nu *;

bridge new {
  info: {
    name: "go",
    description: "The Go programming language package manager",
    version: "0.1.0",
  },
  config: {
    isolate_path: true
    env: {
      GOPATH: "__<PKG_TARGET_DIR>"
    },
    executables: [
      go
    ],
  },
  usege: {
    install: {
      script: {|pkg:string, opts|
        with-env {
          GOPATH: ("." | path expand),
          GOPROXY: 'https://proxy.golang.org,direct',
          GOSUMDB: 'sum.golang.org'
        } {
          go install $pkg
        }
        | print -e $in

        # version
        mut pkg_url_path = (
          "http://" + $pkg
          | url parse
          | get path
          | path parse
          | get parent
        );

        while ($pkg_url_path | split row "/" | length) > 2 {
          $pkg_url_path = ($pkg_url_path | path dirname);

        };

        let pkg_url = (
          [
            (
              "http://" + $pkg
              | url parse
              | get host
            )
            (
              [
                $pkg_url_path,
                (
                  "http://" + $pkg
                  | url parse
                  | get path
                  | path basename
                )
              ] | path join
            )
          ] | str join
        );

        {
          version: (go list -m $pkg_url | split row " " | get 1 | str substring 1..)
          path: (ls ./bin | where type == file | get name | first)
        } | to json
      }
    },
    remove: { },
    update: { },
    cleanup: {
      events: [ "AFTER_INSTALL", "AFTER_UPDATE" ],
    },
  },
}
