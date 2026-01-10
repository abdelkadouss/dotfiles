use ../.shared/push_if_exist.nu 'push if exist'
use ../.shared/fs 'fs find exec';
use ./get_path.nu 'get path';
use ../.shared/pkg 'pkg new';
use ../.shared/version [
'version via-git-remote-tags',
'version via-github-tags'
'version via-cli'
'version trim'
];

const VERSION_FALLBACK = 'x.x.x'
const EGET_SECRET_FILE_PATH = '~/.env/eget/github_token'

export def main [input: string] {
  let config: record = ( try { open ./config.nuon } );

  mkdir out

  mut install_cmd = [
    # pkgx
    # eget@1.3.4
    eget
    --to
    out
  ]

  let opts = (
    push if exist --pass-value --allow-empty  [] [
      [
        { "--file": [ $env.file? ] }
        { "--all": [ $env.all?, false ] }
        { "--download-only": [ $env.keep_structure?, false ] }
      ]
      [
        { "--asset": [ $env.asset? ] }
      ]
      [
        { "--tag": [ $env.tag? ] }
      ]
    ]
  )

  $install_cmd ++= $opts
  $install_cmd ++= [ $input ]
  let install_cmd = $install_cmd;

  try {
    with-env {
      EGET_GITHUB_TOKEN: (
        if ( $config.use_authorised_install? | default false ) {
          open ( $EGET_SECRET_FILE_PATH | path expand )
        }
      )
    } {
      run-external $install_cmd
      | print -e $in

    }

  } catch {|err|
    print $err.rendered
    panic "failed to run eget command"

  }

  if ( $env.keep_structure? | is-not-empty ) {
    ls --all out
    | each {|file|
      try {
        tar -xf ( $file | get name ) -C out
        rm -rf ( $file | get name )

      } catch { ignore }

    }

  }

  if ( $env.after_hook? | is-not-empty ) {
    try {
      nu -c $env.after_hook

    } catch {|err|
      print $err.rendered
      panic "failed to run after install hook"

    }

  }

  let res = (
    get path out
  )

  mut version = $VERSION_FALLBACK
  mut i = 0
  let get_ways = [
    {|input| version via-github-tags $input }
    {|input| $input | version via-git-remote-tags }
    {|input| $input | version via-cli }
  ]

  while ( $version == $VERSION_FALLBACK ) and $i <= ( $get_ways | length ) {
    $version = (
      $get_ways
      | get $i
      | (
        try {
          do $in $input
          | ( version trim $in )
        } catch { $VERSION_FALLBACK }
      )
    )
  }

  return ( pkg new $res.path $version $res.entry_point )

}
