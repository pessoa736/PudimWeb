--[[
    test - Servidor PudimWeb (Next.js style)
    Execute com: lua server.lua
]]

package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    "./app/?.lua",
    "./app/?/init.lua",
    "./lua_modules/share/lua/5.4/?.lua",
    "./lua_modules/share/lua/5.4/?/init.lua",
}, ";") .. ";" .. package.path

package.cpath = table.concat({
    "./lua_modules/lib/lua/5.4/?.so",
}, ";") .. ";" .. package.cpath

pcall(require, "luarocks.loader")
require("DaviLuaXML")

local pudim = require("PudimWeb")

-- Expõe globais para arquivos .lx
pudim.expose()

-- Inicia com roteamento automático (estilo Next.js)
pudim.start({
    port = 3000,
    pagesDir = "./app/pages",
    publicDir = "./app/public",
    apiDir = "./app/api",
})
