export def 'version trim' [
  version: string # version to trim
  --other-dots-to-dashes # replace the not-frist-3-dots with dashes
]: nothing -> string {
  $version
  | str trim
  | (
    if ( $in | split row '.' | length ) < 3 {
      panic $"version must have at least 3 parts separated by dots. ($in)"

    } else { $in }
  )
  | (
    if ( $in | str starts-with 'v' ) {
      $in | str substring 1..
    } else { $in }
  )
  | (
    $in
    | split row ' '
    | first
  )
  | (
    if ( $other_dots_to_dashes ) {
      let first_part = (
        $in
        | split row '.'
        | take 3
        | str join '.'
      );

      let last_part = (
        $in
        | split row '.'
        | reject 0 1 2
        | str join '-'
      );

      if ( $last_part | is-empty ) {
        $first_part
      } else {
        (
          [
            $first_part
            $last_part
          ] | str join '-'
        )
      }
    } else { $in }
  )
  | (
    if ( $in | split row '.' | length ) > 3 {
      $in
      | split row '.'
      | take 3
      | str join '.'
    } else { $in }
  )
  | return $in
}
