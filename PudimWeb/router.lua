--[[
    PudimWeb Router
    ===============
    
    Sistema de rotas para o PudimWeb.
    Suporta rotas estáticas e dinâmicas com parâmetros.
    
    USO:
    ----
    local router = Router.new()
    
    -- Rota estática
    router:add("GET", "/users", function(req, res)
        res.json({ users = {} })
    end)
    
    -- Rota com parâmetro
    router:add("GET", "/users/:id", function(req, res)
        local id = req.params.id
        res.json({ id = id })
    end)
    
    -- Buscar rota
    local handler, params = router:match("GET", "/users/123")
    -- params = { id = "123" }
    
    @module PudimWeb.router
    @author pessoa736
    @license MIT
--]]

local Router = {}
Router.__index = Router

--- Cria um novo router
--- @return table Router instance
function Router.new()
    local self = setmetatable({}, Router)
    self.routes = {
        GET = {},
        POST = {},
        PUT = {},
        DELETE = {},
    }
    return self
end

--- Adiciona uma rota
--- @param method string Método HTTP
--- @param path string Caminho da rota
--- @param handler function Handler da rota
function Router:add(method, path, handler)
    method = method:upper()
    if not self.routes[method] then
        self.routes[method] = {}
    end
    
    -- Converte path params para pattern
    local pattern = path:gsub(":([%w_]+)", "([^/]+)")
    local params = {}
    for param in path:gmatch(":([%w_]+)") do
        table.insert(params, param)
    end
    
    table.insert(self.routes[method], {
        pattern = "^" .. pattern .. "$",
        handler = handler,
        params = params,
        path = path,
    })
end

--- Busca uma rota correspondente
--- @param method string Método HTTP
--- @param path string Caminho requisitado
--- @return function|nil handler
--- @return table|nil params extraídos da URL
function Router:match(method, path)
    method = method:upper()
    local routes = self.routes[method]
    
    if not routes then return nil, nil end
    
    for _, route in ipairs(routes) do
        local matches = {path:match(route.pattern)}
        if #matches > 0 or path:match(route.pattern) then
            local params = {}
            for i, param_name in ipairs(route.params) do
                params[param_name] = matches[i]
            end
            return route.handler, params
        end
    end
    
    return nil, nil
end

return Router
