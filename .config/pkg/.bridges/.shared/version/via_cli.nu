const FALLBACK = 'x.x.x'

export def 'version via-cli' []: string -> string {
  let cmds = [
    --version
    -version
    version
  ]
  let cli = $in;

  mut version = $FALLBACK

  for cmd in $cmds {
    try {
      $version = (
        run-external $cli $cmd
        | (
          if not ( $in | split row "." | length ) == 3 {
            continue
          };
          $in
        )
        | str trim
      )

      break

    } catch { ignore }

  }

  return $version

}
