package = ".bridges"
version = "dev-1"
source = {
   url = "git+ssh://git@codeberg.org/abdelkadous/dotfiles.git"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   queries = {}
}
build_dependencies = {
   queries = {}
}
build = {
   type = "builtin",
   modules = {
      ["eget.main"] = "eget/main.lua"
   }
}
test_dependencies = {
   queries = {}
}
