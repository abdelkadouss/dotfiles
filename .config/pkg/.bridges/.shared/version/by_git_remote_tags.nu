export def "version via-git-remote-tags" []: string -> string {
  git ls-remote --tags https://github.com/sxyazi/yazi.git
  | lines
  | last
  | split row (char tab)
  | last
  | path basename
  | (
    if (
      $in
      | str starts-with v
    ) {
      $in
      | str substring 1..
    } else { $in }
  )

}

