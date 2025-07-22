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
      script: {|pkg:string, opts|#:record<name:string, file?:string, all?:bool, asset?:string,tag:string target?:string>
        mkdir out;
        mut cmd = [ "eget", "--to", "out" ];

        if ( $opts.file? | is-not-empty ) {
          $cmd = ($cmd | append [ "--file", $opts.file ] )

        } else if ( $opts.all? == true ) {
          $cmd = ($cmd | append "--all" )

        }

        if ( $opts.asset? | is-not-empty ) {
          $cmd = ($cmd | append [ "--asset", $opts.asset ] )

        }

        if ( $opts.tag? | is-not-empty ) {
          $cmd = ($cmd | append [ "--tag", $opts.tag ] )

        }

        $cmd = ( $cmd | append $pkg );

        run-external $cmd
        | print -e $in;

        let path = (
          try {
            [
              out
              $opts.target
            ] | path join

          } catch {
            ( ls out | where type == file | get name | first )

          }
        );

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
