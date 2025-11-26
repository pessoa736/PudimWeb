--[[
    PudimWeb HTTP Response
    ======================
    
    Builder de respostas HTTP.
    Fornece métodos chainable para construir e enviar respostas.
    
    USO:
    ----
    -- Resposta HTML
    res.html("<h1>Olá!</h1>")
    
    -- Resposta JSON
    res.json({ message = "OK" })
    
    -- Com status
    res.status(404).html("<h1>Não encontrado</h1>")
    
    -- Com headers
    res.header("X-Custom", "valor").json({ ok = true })
    
    -- Redirect
    res.redirect("/login")
    
    -- Enviar arquivo
    res.sendFile("./arquivo.pdf")
    
    MÉTODOS:
    --------
    - status(code)      : Define código HTTP
    - header(name, val) : Define header
    - html(content)     : Envia HTML
    - json(data)        : Envia JSON
    - send(content)     : Envia texto
    - redirect(url)     : Redireciona
    - sendFile(path)    : Envia arquivo
    
    @module PudimWeb.http.response
    @author pessoa736
    @license MIT
--]]

local Response = {}

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
    local res = {
        _client = client,
        _status = 200,
        _headers = {
            ["Content-Type"] = "text/html; charset=utf-8",
        },
        _sent = false,
    }
    
    --- Define o status HTTP
    --- @param code number Código de status
    --- @return table self (chainable)
    function res.status(code)
        res._status = code
        return res
    end
    
    --- Define um header
    --- @param name string Nome do header
    --- @param value string Valor do header
    --- @return table self (chainable)
    function res.header(name, value)
        res._headers[name] = value
        return res
    end
    
    --- Define Content-Type
    --- @param contentType string
    --- @return table self (chainable)
    function res.type(contentType)
        res._headers["Content-Type"] = contentType
        return res
    end
    
    --- Envia a resposta
    --- @param body string|nil Corpo da resposta
    function res.send(body)
        if res._sent then return end
        res._sent = true
        
        body = body or ""
        res._headers["Content-Length"] = #body
        
        -- Monta a resposta HTTP
        local statusMsg = STATUS_MESSAGES[res._status] or "Unknown"
        local parts = {
            string.format("HTTP/1.1 %d %s", res._status, statusMsg),
        }
        
        for name, value in pairs(res._headers) do
            table.insert(parts, name .. ": " .. value)
        end
        
        table.insert(parts, "")
        table.insert(parts, body)
        
        client:send(table.concat(parts, "\r\n"))
    end
    
    --- Envia resposta HTML
    --- @param body string HTML
    function res.html(body)
        res.type("text/html; charset=utf-8")
        res.send(body)
    end
    
    --- Envia resposta JSON
    --- @param data table|string Dados para serializar
    function res.json(data)
        res.type("application/json")
        if type(data) == "table" then
            -- Serialização JSON simples
            local json = require("PudimWeb.utils.json")
            data = json.encode(data)
        end
        res.send(data)
    end
    
    --- Envia arquivo
    --- @param path string Caminho do arquivo
    --- @param contentType string|nil Content-Type
    function res.file(path, contentType)
        local file = io.open(path, "rb")
        if not file then
            res.status(404).send("File not found")
            return
        end
        
        local content = file:read("*a")
        file:close()
        
        if contentType then
            res.type(contentType)
        end
        res.send(content)
    end
    
    --- Redireciona para outra URL
    --- @param url string URL de destino
    --- @param code number|nil Código (301 ou 302, padrão: 302)
    function res.redirect(url, code)
        res.status(code or 302)
        res.header("Location", url)
        res.send("")
    end
    
    return res
end

return Response
