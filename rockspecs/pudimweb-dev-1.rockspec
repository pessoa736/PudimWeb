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
   "lua >= 5.4",
   "luaXML",
   "loglua",
   "luasocket"
}


build = {
   type = "builtin",
   modules = {
      ["PudimWeb.server"] = "PudimWeb/server.lua",
      ["PudimWeb.loader"] = "PudimWeb/loader.lua",
      ["PudimWeb.taghtml"] = "PudimWeb/taghtml.lua",
   }
}
