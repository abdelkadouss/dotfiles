use ../.shared/push_if_exist.nu 'push if exist'
use ../.shared/fs 'fs find exec';
use ../.shared/pkg 'pkg new';
use ../.shared/version [
  'version via-git-remote-tags'
  'version via-github-tags'
  # 'version via-cli'
  'version trim'
];

def get_version_via_cargo_info [ ]: string -> string {
  let crate = $in;

  cargo info $crate
  | lines
  | where { |line|
    $line
    | str starts-with version:
  }
  | first
  | split row :
  | last

}

export def main [ input: string ] {
  mkdir out;

  mut install_cmd = [
    # pkgx
    # +rust-lang.org
    # +cargo-binstall
    cargo
  ]

  match $env.method? {
    git => {
      $install_cmd ++= [
        install
        --git
      ]

      $install_cmd = (
        push if exist --pass-value --allow-empty $install_cmd [
          [
            { "--branch": [ $env.branch? ] }
            { "--tag": [ $env.tag? ] }
            { "--rev": [ $env.rev? ] }
          ]
        ]
      )

    }
    crate => {
      $install_cmd ++= [ install ]

    }
    null => {
      $install_cmd ++= [ binstall ]
    }
    _ => {
      panic $"method must be one of git, crate. ($env.method) not supported"

    }

  }

  push if exist --pass-value --allow-empty $install_cmd [
    [
      { "--features": [ $env.features? ] }
      { "--locked": [ $env.locked? ] }
    ]
  ]

  if (
    $env.method?
    | (
      ($in == "crate") or ($in == null)
    )
  ) {
    if ($env.version? | is-not-empty) {
      $install_cmd ++= [
        "--version"
        $env.version
      ]

    }

  }

  $install_cmd ++= [
    $input
    --root
    out
  ]

  try {
    yes
    | run-external $install_cmd
    | print -e $in # don't write anything except result in the stdout, use the stderr or non-stdout prints

  } catch { |err|
    print $err.rendered
    panic $"failed to install ($input)"

  }

  # FIXME: make this better insha'Allah
  let version = (
    try {
      match $env.method? {
        "git" => (
          $input | version via-git-remote-tags
        )
        _ => (
          try {
            $input | get_version_via_cargo_info
          } catch {
            cargo info $input
            | lines
            | where { |line|
              $line
              | str starts-with repository:
            }
            | first
            | split row :
            | last
            | version via-git-remote-tags
          }
        )
      } | version trim --other-dots-to-dashes $in
    } catch { "x.x.x" }
  )

  let path = (
    try {
      [
        ./out
        $env.target-dir
      ] | path join
      | path expand
    } catch {
      fs find exec ./out/bin/
      | first
    }
  )

  return (
    pkg new $path $version (
      try {
        $env.target-dir; # if target-dir is set then
        try {
          (
            [
              $path
              $env.target
            ] | path join
          ) | path expand
        } catch { ||
          fs find exec ./out/bin/
          | first
        }
      } catch { ||
        null
      }
    )
  )

}
