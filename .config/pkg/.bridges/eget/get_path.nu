use ../.shared/fs 'fs find exec';

export def 'get path' [ out: string ] {
  mut output = {
    path: null
    entry_point: null
  }

  # 1. try to use target if set
  $output.path = (
    try {
      [
        $out
        $env.target
      ] | path join
    } catch {
      # 2. else use first executable
      let execs = (
        fs find exec $out
      )

      if ( $execs | length ) == 0 {
        error make {
          msg: "no executable found"
          label: {
            text: "there is no executable in out directory"
            span: (metadata $execs).span
          }
          help: "fix the instaltion or try to use the target attribute"

        }

      }

      if ( $execs | length ) > 1 {
        error make {
          msg: "multiple executables found"

          label: {
            text: "there is more than one executable in out directory"
            span: (metadata $execs).span

          }

          help: "use target attribute to spcifiy which to use"

        }

      }

      (
        [
          $out
          $execs.0
        ] | path join
      )

    }
  )

  if ( $output.path | path type ) == dir and ( $output.entry_point | is-empty ) {
    error make {
      msg: "a directory was specified as target without an entry point"
      label: {
        text: "a pkg with type dirceletory must have an entry point"
        span: (metadata $output.path).span
      }
      help: "use entry_point attribute to specify an executable or try to use a pkg with typr `singleexecutable` by specify a executable as target"
    }

  }

  if ( $output.path | str contains '*' ) {
    $output.path = (
      glob $output.path | first
    )
  }

  $output.entry_point = (
    try {
      [
        $output.path
        $env.entry_point
      ] | path join
    } catch { null }
  )

  return $output

}
