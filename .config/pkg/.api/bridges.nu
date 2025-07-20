# some stuff to help u in Chaa'Allah work with bridges

# to make new bridge (the nuon file) from it's source code (the nu file) in Chaa'Allah
export module bridge {
  export def main [] {};

  export def new [ bridge: any ] {
    $bridge
    | to nuon --serialize --raw

  }

  export def out [ version: string, path?: string ] {
    {
      version: $version,
      path: $path
    }
    | to json

  }

};
