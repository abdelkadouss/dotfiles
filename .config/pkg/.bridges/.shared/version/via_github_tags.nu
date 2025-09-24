const FALLBACK = 'x.x.x'

export def 'version via-github-tags' [ repo: string] {
  let url = (
    {
      scheme: "https"
      host: "api.github.com"
      path: $"/repos/( $repo )/releases/latest"
    } | url join
  )

  let output = (
    try {
      http get $url
      | get tag_name

    } catch { $FALLBACK }
  )

  if ( $output | str starts-with 'v' ) {
    $output | str substring 1..
  } else { $output }

}
