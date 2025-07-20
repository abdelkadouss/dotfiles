use ../../.api/bridges.nu *;

bridge new {
  info: {
    name: "eget",
    description: "the github installing tool",
    version: "0.1.0",
  },
  config: {
    executables: [
      eget
    ],
  },
  usege: {
    install: {
      script: {|pkg:string|
        mkdir out;
        eget --to out $pkg # FIXME: --all --asset ^.t

        let path = (ls out | where type == file | get name | first);
        {
          version: (
            try {
              {
                scheme: https,
                host: api.github.com,
                path: (
                  [
                    repos,
                    $pkg
                    releases/latest
                  ] | path join
                )
              }
              | url join
              | http get $in
              | get tag_name
              | (
                if ( $in | str contains '.' ) {
                  let tag = $in;

                  $tag
                  | str starts-with 'v'
                  | if $in {
                    $tag
                    | str substring 1..

                  } else {
                    $tag

                  }

                } else {
                  "unknown"

                }
              )

            } catch {
              "unknown"

            }
          ),
          path: $path
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
