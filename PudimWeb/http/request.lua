--[[
    PudimWeb HTTP Request
    =====================
    
    Parser de requisições HTTP.
    Converte dados brutos do socket em um objeto request estruturado.
    
    ESTRUTURA DO OBJETO REQUEST:
    ----------------------------
    req = {
        method = "GET",           -- Método HTTP (GET, POST, etc.)
        path = "/users",          -- Caminho da URL
        query = { id = "123" },   -- Query string parseada
        headers = {               -- Headers HTTP
            ["content-type"] = "application/json",
            ["host"] = "localhost:3000"
        },
        body = { ... },           -- Body parseado (JSON ou form)
        params = { id = "123" },  -- Parâmetros de rota (preenchido pelo router)
        raw = "...",              -- Body raw (string)
    }
    
    @module PudimWeb.http.request
    @author pessoa736
    @license MIT
--]]

local Request = {}

--- Faz parse de query string
--- @param query string
--- @return table
local function parseQuery(query)
    local params = {}
    if not query or query == "" then return params end
    
    for pair in query:gmatch("[^&]+") do
        local key, value = pair:match("([^=]+)=?(.*)")
        if key then
            -- URL decode básico
            key = key:gsub("%%(%x%x)", function(h)
                return string.char(tonumber(h, 16))
            end)
            value = value:gsub("%%(%x%x)", function(h)
                return string.char(tonumber(h, 16))
            end)
            value = value:gsub("+", " ")
            params[key] = value
        end
    end
    
    return params
end

--- Faz parse dos headers HTTP
--- @param client userdata Socket do cliente
--- @return table Headers
local function parseHeaders(client)
    local headers = {}
    
    while true do
        local line = client:receive("*l")
        if not line or line == "" then break end
        
        local key, value = line:match("^([^:]+):%s*(.+)$")
        if key then
            headers[key:lower()] = value
        end
    end
    
    return headers
end

--- Lê o body da requisição
--- @param client userdata Socket do cliente
--- @param headers table Headers da requisição
--- @return string|nil Body
local function readBody(client, headers)
    local length = tonumber(headers["content-length"])
    if not length or length == 0 then return nil end
    
    return client:receive(length)
end

--- Faz parse de uma requisição HTTP
--- @param client userdata Socket do cliente
--- @return table|nil Request object
function Request.parse(client)
    -- Lê a primeira linha (GET /path HTTP/1.1)
    local line = client:receive("*l")
    if not line then return nil end
    
    local method, fullPath, version = line:match("^(%w+)%s+([^%s]+)%s+HTTP/([%d%.]+)$")
    if not method then return nil end
    
    -- Separa path e query string
    local path, queryString = fullPath:match("^([^?]+)%??(.*)")
    path = path or fullPath
    
    -- Parse dos headers
    local headers = parseHeaders(client)
    
    -- Lê o body se houver
    local body = readBody(client, headers)
    
    -- Monta o objeto de requisição
    local req = {
        method = method:upper(),
        path = path,
        fullPath = fullPath,
        version = version,
        query = parseQuery(queryString),
        headers = headers,
        body = body,
        params = {},  -- Preenchido pelo router
    }
    
    -- Helper para pegar header
    function req.header(name)
        return headers[name:lower()]
    end
    
    return req
end

return Request
