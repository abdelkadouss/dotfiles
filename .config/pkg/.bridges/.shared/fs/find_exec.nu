use is_exec.nu "fs is exec";

export def "fs find exec" [
  path: string # path to dir to search in
] {
  if ( $path | path type ) == dir {
    ls --long --full-paths $path
    | where type == file
    | get name
    | where {|file|
      fs is exec $file
    }
    | return $in

  } else {
    error make {
      msg: $"only directories are supported"
      label: {
        text: $"this path is not a directory"
        span: (metadata $path).span

      }
      help: "use fs find exec on directories only"

    }

  }

}
