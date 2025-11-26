package = "PudimWeb"
version = "dev-2"
source = {
   url = "git://github.com/pessoa736/PudimWeb.git"
}
description = {
   summary = "Framework web para Lua 5.4 inspirado em React/Next.js",
   detailed = [[
      PudimWeb é um framework web para Lua 5.4 com arquitetura
      inspirada em React/Next.js. Inclui roteamento baseado em
      arquivos, componentes funcionais, hooks (useState, useEffect,
      useMemo, useContext), e suporte a arquivos .lx via DaviLuaXML.
      
      Características:
      - Roteamento automático baseado em arquivos (Next.js style)
      - Componentes funcionais com props/children
      - Hooks para gerenciamento de estado
      - API Routes
      - Arquivos estáticos
      - CLI para criar projetos (pudim new)
   ]],
   homepage = "https://github.com/pessoa736/PudimWeb",
   license = "MIT"
}
dependencies = {
   "lua >= 5.4",
   "DaviLuaXML",
   "loglua",
   "luasocket"
}
build = {
   type = "builtin",
   modules = {
      ["PudimWeb"] = "PudimWeb/init.lua",
      ["PudimWeb.router"] = "PudimWeb/router.lua",
      ["PudimWeb.html"] = "PudimWeb/html/init.lua",
      ["PudimWeb.http.server"] = "PudimWeb/http/server.lua",
      ["PudimWeb.http.request"] = "PudimWeb/http/request.lua",
      ["PudimWeb.http.response"] = "PudimWeb/http/response.lua",
      ["PudimWeb.middleware.static"] = "PudimWeb/middleware/static.lua",
      ["PudimWeb.utils.json"] = "PudimWeb/utils/json.lua",
      ["PudimWeb.core.components"] = "PudimWeb/core/components.lua",
      ["PudimWeb.core.hooks"] = "PudimWeb/core/hooks.lua",
      ["PudimWeb.core.fileRouter"] = "PudimWeb/core/fileRouter.lua",
   },
   install = {
      bin = {
         pudim = "bin/pudim"
      }
   }
}
