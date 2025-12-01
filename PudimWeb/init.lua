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
local Router = require("PudimWeb.router")
local server = require("PudimWeb.http.server")
local static = require("PudimWeb.middleware.static")
local components = require("PudimWeb.core.components")
local fileRouter = require("PudimWeb.core.fileRouter")
local hooks = require("PudimWeb.core.hooks")
local vdom = require("PudimWeb.core.vdom")
local reconciler = require("PudimWeb.core.reconciler")
local client = require("PudimWeb.core.client")
local renderer = require("PudimWeb.core.renderer")

-- Builder carregado sob demanda (não precisa em runtime)
local builder = nil

-- Exporta módulos
PudimWeb.html = html
PudimWeb.Router = Router
PudimWeb.vdom = vdom
PudimWeb.reconciler = reconciler
PudimWeb.client = client
PudimWeb.renderer = renderer

-- Lazy load do builder
function PudimWeb.getBuilder()
    if not builder then
        builder = require("PudimWeb.core.builder")
    end
    return builder
end

-- Exporta funções do VDom para fácil acesso
PudimWeb.h = vdom.h
PudimWeb.diff = vdom.diff
PudimWeb.render = vdom.render

-- Exporta funções do Reconciler
PudimWeb.createRoot = reconciler.createRoot
PudimWeb.createElement = reconciler.createElement
PudimWeb.el = reconciler.el

-- Exporta funções do Renderer
PudimWeb.render = renderer.render
PudimWeb.renderPage = renderer.renderPage
PudimWeb.configureRenderer = renderer.configure

-- Exporta hooks (estilo React)
PudimWeb.useState = hooks.useState
PudimWeb.useEffect = hooks.useEffect
PudimWeb.useMemo = hooks.useMemo
PudimWeb.useContext = hooks.useContext
PudimWeb.createContext = hooks.createContext

-- Configuração padrão
local defaultConfig = {
    port = 3000,
    host = "127.0.0.1",
    pagesDir = "./app/pages",
    publicDir = "./app/public",
    apiDir = "./app/api",
    componentsDir = "./app/components",
}

local appConfig = {}
local appRouter = Router.new()

--- Cria um componente funcional (estilo React)
--- @param render function Função (props, children) -> string
--- @return function
function PudimWeb.component(render)
    return components.create(render)
end

--- Define o layout global
--- @param layoutFn function
function PudimWeb.setLayout(layoutFn)
    appConfig.layout = layoutFn
end

--- Registra rota GET
function PudimWeb.get(path, handler)
    appRouter:add("GET", path, handler)
end

--- Registra rota POST
function PudimWeb.post(path, handler)
    appRouter:add("POST", path, handler)
end

--- Registra rota PUT
function PudimWeb.put(path, handler)
    appRouter:add("PUT", path, handler)
end

--- Registra rota DELETE
function PudimWeb.delete(path, handler)
    appRouter:add("DELETE", path, handler)
end

--- Configura diretório estático
function PudimWeb.staticDir(dir)
    appConfig.publicDir = dir
end

--- Inicia o servidor (estilo Next.js)
--- @param config table|nil
function PudimWeb.start(config)
    config = config or {}
    
    -- Merge configs
    for k, v in pairs(defaultConfig) do
        appConfig[k] = config[k] or appConfig[k] or v
    end
    
    -- Carrega rotas baseadas em arquivos
    local routes = fileRouter.loadRoutes(appConfig.pagesDir, appConfig.apiDir)
    for _, route in ipairs(routes) do
        appRouter:add(route.method, route.path, route.handler)
    end
    
    -- Inicia servidor
    server.start({
        port = appConfig.port,
        host = appConfig.host,
        router = appRouter,
        static_dir = appConfig.publicDir,
        layout = appConfig.layout,
    })
end

--- Atalho para iniciar (retrocompatibilidade)
function PudimWeb.listen(port, host)
    PudimWeb.start({ port = port, host = host })
end

--- Expõe globais para arquivos .lx (como React global)
function PudimWeb.expose()
    _G.html = html
    _G.component = PudimWeb.component
    _G.Fragment = function(_, children) return html.fragment(children) end
    _G.useState = hooks.useState
    _G.useEffect = hooks.useEffect
    _G.useMemo = hooks.useMemo
    -- VDom
    _G.h = vdom.h
    _G.vdom = vdom
    -- Reconciler
    _G.createRoot = reconciler.createRoot
    _G.createElement = reconciler.createElement
    _G.el = reconciler.el
    -- Client (browser bindings) - agora integrado automaticamente
    _G.client = client
    _G["$"] = client.select
    _G["$$"] = client.selectAll
    -- Renderer
    _G.render = renderer.render
    _G.renderPage = renderer.renderPage
end

--- Helper para criar fragmentos
function PudimWeb.Fragment(_, children)
    return html.fragment(children)
end

return PudimWeb
