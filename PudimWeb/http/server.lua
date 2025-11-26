--[[
    PudimWeb HTTP Server
    ====================
    
    Servidor HTTP baseado em LuaSocket.
    Processa requisições de forma síncrona e roteia para handlers.
    
    USO:
    ----
    local server = require("PudimWeb.http.server")
    local Router = require("PudimWeb.router")
    
    local router = Router.new()
    router:add("GET", "/", function(req, res)
        res.html("<h1>Olá!</h1>")
    end)
    
    server.start({
        port = 3000,
        host = "127.0.0.1",
        router = router,
        static_dir = "./app/public",
    })
    
    CONFIGURAÇÕES:
    --------------
    - port: Porta do servidor (padrão: 9001)
    - host: Host para bind (padrão: 127.0.0.1)
    - router: Instância do Router
    - static_dir: Diretório de arquivos estáticos
    - static_prefix: Prefixo de URL para estáticos
    
    @module PudimWeb.http.server
    @author pessoa736
    @license MIT
--]]

local socket = require("socket")
local request = require("PudimWeb.http.request")
local response = require("PudimWeb.http.response")
local static = require("PudimWeb.middleware.static")

local Server = {}

--- Inicia o servidor
--- @param config table Configurações do servidor
function Server.start(config)
    local host = config.host or "127.0.0.1"
    local port = config.port or 9001
    local router = config.router
    local static_dir = config.static_dir or "./app/public"
    local static_prefix = config.static_prefix or "/"
    
    -- Cria o servidor
    local server = assert(socket.bind(host, port))
    server:settimeout(0.1)
    
    print(string.format([[
╔═══════════════════════════════════════════════════════════╗
║                     🍮 PudimWeb                           ║
╠═══════════════════════════════════════════════════════════╣
║  Servidor rodando em: http://%s:%d                  ║
║  Arquivos estáticos:  %s                         ║
║  Pressione Ctrl+C para parar                              ║
╚═══════════════════════════════════════════════════════════╝
]], host, port, static_dir))

    -- Loop principal
    while true do
        local client = server:accept()
        
        if client then
            client:settimeout(5)
            
            local ok, err = pcall(function()
                Server.handleRequest(client, router, static_dir, static_prefix)
            end)
            
            if not ok then
                print("[ERROR] " .. tostring(err))
            end
            
            client:close()
        end
    end
end

--- Processa uma requisição
--- @param client userdata Socket do cliente
--- @param router table Router instance
--- @param static_dir string Diretório de arquivos estáticos
--- @param static_prefix string Prefixo de URL para arquivos estáticos
function Server.handleRequest(client, router, static_dir, static_prefix)
    -- Parse da requisição
    local req = request.parse(client)
    if not req then return end
    
    -- Log da requisição
    print(string.format("[%s] %s %s", os.date("%H:%M:%S"), req.method, req.path))
    
    -- Cria objeto de resposta
    local res = response.new(client)
    
    -- Tenta servir arquivo estático primeiro
    if static.serve(req, res, static_dir, static_prefix) then
        return
    end
    
    -- Busca rota no router
    local handler, params = router:match(req.method, req.path)
    
    if handler then
        req.params = params or {}
        local ok, result = pcall(handler, req, res)
        
        if not ok then
            print("[ERROR] Handler: " .. tostring(result))
            res.status(500).send("Internal Server Error")
        elseif type(result) == "string" then
            res.html(result)
        end
    else
        res.status(404).html("<h1>404 - Página não encontrada</h1>")
    end
end

return Server
