export def 'push if exist' [
  dist_list: list<any>
  lists: list<list<any>>
  --pass-value
  --allow-empty
]: nothing -> list<any> {
  mut res = $dist_list;

  for list in $lists {
    let non_empty_items_count = (
      $list
      | where {|record|
        $record
        | transpose k v
        | first
        | $in.v.0 | is-not-empty
      }
      | length
    )

    if (
      $non_empty_items_count
      | $in > 1
    ) {
      error make {
        msg: "wrong usage of options"

        label: {
          text: "u have to use only one of these not options"
          span: (metadata $list).span

        }

      }

    } else if (
      $non_empty_items_count
      | $in <= 0
      | $in and not $allow_empty
    ) {
      error make {
        msg: "wrong usage of options"

        label: {
          text: "u have to pass at least one of these options"
          span: (metadata $list).span

        }

      }

    } else {
      $res ++= (
        $list
        | where {|record|
          $record
          | transpose k v
          | flatten
          | $in.v.0 | is-not-empty
        }
        | (
          if ( $in | is-empty ) { continue };
          ( $in | into record | transpose k v | first )
        )
        | (
          [
            $in.k,
            (
              let value = $in.v;
              if ( $value.1? | default $pass_value ) { $value.0 } else { '' }
            )
          ]
        )
      )

    }

  }


  return (
    $res
    | where {|item|
      $item | is-not-empty
    }
  )

}
