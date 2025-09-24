const SEPARATOR = ','

export def 'pkg new' [
  path: string # pkg path
  version: string # pkg version
  entry_point?: string # entry point
] {
  mut output = (
    [
      $path
      $version
    ] | str join $SEPARATOR
  );

  if ( $entry_point | is-not-empty ) {
    $output = (
      [
        $output
        $entry_point
      ] | str join $SEPARATOR
    )
  }

  $output

}
