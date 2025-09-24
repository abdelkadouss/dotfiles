export def "one of" [
  opts: list
  --allow-empty
] {
  let opts_state = (
    $opts
    | each { is-not-empty }
    | where {|item| $item  == true }
  )

  if (
    $opts_state
    | length
    | $in > 1
  ) {
    panic $"use one of those not more than one ($opts | str join ', ')"

  } else if (
    $opts_state
    | length
    | $in <= 0
  ) and not $allow_empty {
    panic $"use have to shoose one of those ($opts | str join ', ')"

  } else {
    return (
      $opts
      | where {|item| $item | is-not-empty }
      | first
    )

  }

}
