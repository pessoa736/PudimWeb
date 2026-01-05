--[[
    PudimWeb Framework
    ==================
    
    Framework web para Lua 5.4 inspirado em React/Next.js
    
    ESTRUTURA DE PROJETO:
    ---------------------
    app/
    ├── pages/           # Rotas automáticas (como Next.js)
    │   ├── index.lx     # → /
    │   ├── about.lx     # → /about
    │   └── blog/
    │       ├── index.lx # → /blog
    │       └── [id].lx  # → /blog/:id (rota dinâmica)
    ├── api/             # API Routes
    │   └── users.lua    # → /api/users
    ├── components/      # Componentes reutilizáveis
    ├── public/          # Arquivos estáticos
    └── layout.lx        # Layout global
    
    USO:
    ----
    local pudim = require("PudimWeb")
    
    pudim.start({
        port = 3000,
    })
--]]

local PudimWeb = {}

-- Módulos internos
local html = require("PudimWeb.html")
local components = require("PudimWeb.core.components")
local fileRouter = require("PudimWeb.core.fileRouter")
local hooks = require("PudimWeb.core.hooks")
local vdom = require("PudimWeb.core.vdom")
local reconciler = require("PudimWeb.core.reconciler")
local client = require("PudimWeb.core.client")
local renderer = require("PudimWeb.core.renderer")
local PudimServer = require("PudimServer")

-- Builder carregado sob demanda (não precisa em runtime)

-- Exporta módulos
PudimWeb.html = html

-- Configuração padrão
local defaultConfig = {
    port = 3000,
    host = "127.0.0.1",
    pagesDir = "./app/pages",
    publicDir = "./app/public",
    apiDir = "./app/api",
    componentsDir = "./app/components",
}



return PudimWeb
