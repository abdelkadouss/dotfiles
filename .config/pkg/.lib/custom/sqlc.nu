const platform = 'macOS';

def main [] {
  http get https://docs.sqlc.dev/en/stable/overview/install.html
  | lines
  | where {|line|
    (
      $line
      | str contains '<a class="reference external" href="'
    ) and (
      $line
      | str contains $platform
    )
  }
  | first
  | from xml
  | get content
  | first
  | get content
  | first
  | get attributes
  | get href
  | eget $in
  | complete
  | ignore;

  return (
    {
      path: "sqlc"
      version: (sqlc version | str substring 1..)
    } | to json
  )

}
