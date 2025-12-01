--[[
    PudimWeb HTTP Response
    ======================
    
    Builder de respostas HTTP.
    Fornece métodos chainable para construir e enviar respostas.
    
    USO:
    ----
    -- Resposta HTML
    res:html("<h1>Olá!</h1>")
    
    -- Resposta JSON
    res:json({ message = "OK" })
    
    -- Com status
    res:status(404):html("<h1>Não encontrado</h1>")
    
    -- Com headers
    res:header("X-Custom", "valor"):json({ ok = true })
    
    -- Redirect
    res:redirect("/login")
    
    -- Enviar arquivo
    res:file("./arquivo.pdf")
    
    MÉTODOS:
    --------
    - status(code)      : Define código HTTP
    - header(name, val) : Define header
    - html(content)     : Envia HTML
    - json(data)        : Envia JSON
    - send(content)     : Envia texto
    - redirect(url)     : Redireciona
    - file(path)        : Envia arquivo
    
    @module PudimWeb.http.response
    @author pessoa736
    @license MIT
--]]

local Response = {}
Response.__index = Response

--- Mensagens de status HTTP
local STATUS_MESSAGES = {
    [200] = "OK",
    [201] = "Created",
    [204] = "No Content",
    [301] = "Moved Permanently",
    [302] = "Found",
    [304] = "Not Modified",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [500] = "Internal Server Error",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
}

--- Cria um novo objeto de resposta
--- @param client userdata Socket do cliente
--- @return table Response object
function Response.new(client)
    local self = setmetatable({
        _client = client,
        _status = 200,
        _headers = {
            ["Content-Type"] = "text/html; charset=utf-8",
        },
        _sent = false,
    }, Response)
    
    return self
end

--- Define o status HTTP
--- @param code number Código de status
--- @return table self (chainable)
function Response:status(code)
    self._status = code
    return self
end

--- Define um header
--- @param name string Nome do header
--- @param value string Valor do header
--- @return table self (chainable)
function Response:header(name, value)
    self._headers[name] = value
    return self
end

--- Define Content-Type
--- @param contentType string
--- @return table self (chainable)
function Response:type(contentType)
    self._headers["Content-Type"] = contentType
    return self
end

--- Envia a resposta
--- @param body string|nil Corpo da resposta
function Response:send(body)
    if self._sent then return self end
    self._sent = true
    
    body = body or ""
    self._headers["Content-Length"] = #body
    
    -- Monta a resposta HTTP
    local statusMsg = STATUS_MESSAGES[self._status] or "Unknown"
    local parts = {
        string.format("HTTP/1.1 %d %s", self._status, statusMsg),
    }
    
    for name, value in pairs(self._headers) do
        table.insert(parts, name .. ": " .. value)
    end
    
    table.insert(parts, "")
    table.insert(parts, body)
    
    self._client:send(table.concat(parts, "\r\n"))
    return self
end

--- Envia resposta HTML
--- @param body string HTML
function Response:html(body)
    self:type("text/html; charset=utf-8")
    self:send(body)
    return self
end

--- Envia resposta JSON
--- @param data table|string Dados para serializar
function Response:json(data)
    self:type("application/json")
    if type(data) == "table" then
        local json = require("PudimWeb.utils.json")
        data = json.encode(data)
    end
    self:send(data)
    return self
end

--- Envia arquivo
--- @param path string Caminho do arquivo
--- @param contentType string|nil Content-Type
function Response:file(path, contentType)
    local file = io.open(path, "rb")
    if not file then
        self:status(404):send("File not found")
        return self
    end
    
    local content = file:read("*a")
    file:close()
    
    if contentType then
        self:type(contentType)
    end
    self:send(content)
    return self
end

--- Redireciona para outra URL
--- @param url string URL de destino
--- @param code number|nil Código (301 ou 302, padrão: 302)
function Response:redirect(url, code)
    self:status(code or 302)
    self:header("Location", url)
    self:send("")
    return self
end

return Response
