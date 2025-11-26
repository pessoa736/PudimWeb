--[[
    PudimWeb - Exemplo de uso
    =========================
    
    Execute com: lua ./PudimWeb/server.lua
--]]

-- Configuração de caminhos
package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    "./lua_modules/share/lua/5.4/?.lua",
    "./lua_modules/share/lua/5.4/?/init.lua",
}, ";") .. ";" .. package.path

package.cpath = table.concat({
    "./lua_modules/lib/lua/5.4/?.so",
}, ";") .. ";" .. package.cpath

pcall(require, "luarocks.loader")

-- Carrega o DaviLuaXML para suporte a arquivos .lx
require("DaviLuaXML")

-- Carrega o framework
local pudim = require("PudimWeb")
local html = pudim.html

-- Expõe html como global para uso em arquivos .lx
_G.html = html

-- Configura arquivos estáticos
pudim.staticDir("/", "./app/public")

-- Rota principal
pudim.get("/", function(req, res)
    local Page = require("app.Pages.index")
    
    local page = html.doctype .. html.html({lang = "pt-BR"}, {
        html.head({}, {
            html.meta({charset = "utf-8"}),
            html.title({}, {"PudimWeb"}),
        }),
        html.body({}, {
            Page()
        }),
    })
    
    return page
end)

-- Rota de exemplo com parâmetro
pudim.get("/hello/:name", function(req, res)
    local name = req.params.name or "mundo"
    
    return html.doctype .. html.html({}, {
        html.body({}, {
            html.h1({}, {"Olá, " .. name .. "!"}),
            html.a({href = "/"}, {"Voltar"}),
        }),
    })
end)

-- Rota de API JSON
pudim.get("/api/status", function(req, res)
    res.json({
        status = "ok",
        framework = "PudimWeb",
        lua_version = _VERSION,
    })
end)

-- Inicia o servidor
pudim.listen(9001, "127.0.0.1")