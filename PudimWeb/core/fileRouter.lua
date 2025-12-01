--[[
    PudimWeb File Router
    ====================
    
    Roteamento baseado em arquivos (estilo Next.js)
    
    ESTRUTURA:
    ----------
    pages/
    ├── index.lx          → GET /
    ├── about.lx          → GET /about
    ├── contact.lx        → GET /contact
    ├── blog/
    │   ├── index.lx      → GET /blog
    │   └── [slug].lx     → GET /blog/:slug (rota dinâmica)
    └── users/
        └── [id]/
            └── posts.lx  → GET /users/:id/posts
    
    api/
    ├── users.lua         → /api/users (GET, POST, etc.)
    └── posts/
        └── [id].lua      → /api/posts/:id
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local renderer = require("PudimWeb.core.renderer")

local FileRouter = {}

--- Verifica se um caminho existe
local function pathExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

--- Lista arquivos em um diretório
local function listDir(path)
    local files = {}
    local handle = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end
    return files
end

--- Verifica se é diretório
local function isDir(path)
    local handle = io.popen('test -d "' .. path .. '" && echo "yes" || echo "no"')
    if handle then
        local result = handle:read("*l")
        handle:close()
        return result == "yes"
    end
    return false
end

--- Converte nome de arquivo para path de rota
--- [param].lx -> :param
--- index.lx -> /
local function fileToRoute(filename, basePath)
    -- Remove extensão
    local name = filename:gsub("%.lx$", ""):gsub("%.lua$", "")
    
    -- index vira raiz
    if name == "index" then
        return basePath == "" and "/" or basePath
    end
    
    -- [param] vira :param
    name = name:gsub("%[([^%]]+)%]", ":%1")
    
    return basePath .. "/" .. name
end

--- Cria handler para página .lx
--- Agora usa o Renderer para integração automática com VDom, Reconciler e Client
local function createPageHandler(filePath)
    return function(req, res)
        -- Carrega o módulo da página
        local pagePath = filePath:gsub("^%./", ""):gsub("%.lx$", ""):gsub("/", ".")
        
        local ok, pageModule = pcall(require, pagePath)
        if not ok then
            if _G.log then
                _G.log.error(_G.log.section("PudimWeb.fileRouter"), "Erro ao carregar página:", pagePath, pageModule)
            end
            return renderer.renderError("Erro ao carregar página: " .. tostring(pageModule))
        end
        
        -- Determina o componente a renderizar
        local component
        if type(pageModule) == "function" then
            component = pageModule
        elseif type(pageModule) == "table" and pageModule.default then
            component = pageModule.default
        elseif type(pageModule) == "string" then
            -- String direta, passa ao renderer
            return renderer.render(pageModule, { request = req }, req.path)
        else
            return renderer.render(tostring(pageModule), { request = req }, req.path)
        end
        
        -- Usa o Renderer para renderização integrada
        -- O renderer automaticamente:
        -- 1. Constrói o VDom
        -- 2. Faz reconciliação se houver versão em cache
        -- 3. Injeta scripts do client
        -- 4. Retorna HTML otimizado
        local html, patches = renderer.render(component, { request = req, params = req.params }, req.path)
        
        -- Se houve patches e cliente suporta, poderia enviar apenas patches
        -- Por enquanto, sempre envia HTML completo
        -- TODO: Implementar SSE/WebSocket para enviar patches incrementais
        
        if _G.log and patches and #patches > 0 then
            _G.log.debug(_G.log.section("PudimWeb.fileRouter"), 
                string.format("Página %s: %d mudanças detectadas", req.path, #patches))
        end
        
        return html
    end
end

--- Cria handler para API .lua
local function createApiHandler(filePath)
    return function(req, res)
        local apiPath = filePath:gsub("^%./", ""):gsub("%.lua$", ""):gsub("/", ".")
        
        local ok, apiModule = pcall(require, apiPath)
        if not ok then
            if _G.log then
                _G.log.error(_G.log.section("PudimWeb.fileRouter"), "Erro ao carregar API:", apiPath, apiModule)
            end
            return res.status(500).json({ error = "Erro ao carregar API", details = tostring(apiModule) })
        end
        
        -- Busca método correspondente (GET, POST, etc.)
        local method = req.method:upper()
        local handler = apiModule[method] or apiModule[method:lower()]
        
        if handler then
            local ok2, result = pcall(handler, req, res)
            if not ok2 then
                if _G.log then
                    _G.log.error(_G.log.section("PudimWeb.fileRouter"), "Erro ao executar API:", apiPath, method, result)
                end
                return res.status(500).json({ error = "Erro ao executar API", details = tostring(result) })
            end
            return result
        elseif apiModule.default then
            local ok2, result = pcall(apiModule.default, req, res)
            if not ok2 then
                if _G.log then
                    _G.log.error(_G.log.section("PudimWeb.fileRouter"), "Erro ao executar API (default):", apiPath, result)
                end
                return res.status(500).json({ error = "Erro ao executar API", details = tostring(result) })
            end
            return result
        else
            if _G.log then
                _G.log.debug(_G.log.section("PudimWeb.fileRouter"), "Método não permitido:", apiPath, method)
            end
            return res.status(405).json({ error = "Método não permitido" })
        end
    end
end

--- Escaneia diretório recursivamente e gera rotas
local function scanDir(dir, basePath, routes, isApi)
    if not pathExists(dir) then return end
    
    local files = listDir(dir)
    
    for _, file in ipairs(files) do
        local fullPath = dir .. "/" .. file
        
        if isDir(fullPath) then
            -- Diretório - recursão
            local dirName = file:gsub("%[([^%]]+)%]", ":%1")
            local newBase = basePath .. "/" .. dirName
            scanDir(fullPath, newBase, routes, isApi)
        else
            -- Arquivo
            local ext = file:match("%.([^%.]+)$")
            
            if ext == "lx" and not isApi then
                -- Página .lx
                local routePath = fileToRoute(file, basePath)
                table.insert(routes, {
                    method = "GET",
                    path = routePath,
                    handler = createPageHandler(fullPath),
                    file = fullPath,
                })
            elseif ext == "lua" and isApi then
                -- API .lua
                local routePath = "/api" .. fileToRoute(file, basePath)
                -- APIs suportam múltiplos métodos
                for _, method in ipairs({"GET", "POST", "PUT", "DELETE", "PATCH"}) do
                    table.insert(routes, {
                        method = method,
                        path = routePath,
                        handler = createApiHandler(fullPath),
                        file = fullPath,
                    })
                end
            end
        end
    end
end

--- Carrega todas as rotas dos diretórios
--- @param pagesDir string Diretório de páginas
--- @param apiDir string Diretório de APIs
--- @return table Lista de rotas
function FileRouter.loadRoutes(pagesDir, apiDir)
    local routes = {}
    
    -- Escaneia páginas
    scanDir(pagesDir or "./app/pages", "", routes, false)
    
    -- Escaneia APIs
    scanDir(apiDir or "./app/api", "", routes, true)
    
    return routes
end

--- Imprime rotas carregadas (debug)
function FileRouter.printRoutes(routes)
    print("\n📁 Rotas carregadas:")
    print(string.rep("-", 50))
    for _, route in ipairs(routes) do
        print(string.format("  %s %s → %s", route.method, route.path, route.file))
    end
    print(string.rep("-", 50))
end

return FileRouter
