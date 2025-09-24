export def "fs is exec" [
  path: string
]: nothing -> bool {
  if ($path | path type) == "file" {
    ls --long --full-paths $path
    | first
    | get mode
    | str contains x
    | return $in

  } else {
    error make {
      msg: $"only files are supported"
      label: {
        text: $"this path is not a file"
        span: (metadata $path).span

      }
      help: "use fs is exec on files only"

    }

  }

}
