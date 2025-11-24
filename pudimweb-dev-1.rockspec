package = "PudimWeb"
version = "dev-1"

source = {
   url = ""
}

description = {
   homepage = "",
   license = ""
}

dependencies = {
   "lua >= 5.4"
   "luaXML",
   "loglua",
   "luasocket"
}


build = {
   type = "builtin",
   modules = {}
}

test_dependencies = {
   queries = {}
}
