--[[
    PudimWeb Static Middleware
    ==========================
    
    Middleware para servir arquivos estáticos.
    Suporta diversos tipos de arquivos com Content-Type correto.
    
    USO:
    ----
    local static = require("PudimWeb.middleware.static")
    
    -- No handler de requisição
    if static.serve(req, res, "./app/public") then
        return  -- Arquivo servido com sucesso
    end
    
    ARQUIVOS SUPORTADOS:
    --------------------
    - Texto: html, css, js, json, xml, txt, md
    - Imagens: png, jpg, gif, webp, svg, ico
    - Fontes: woff, woff2, ttf, otf, eot
    - Mídia: mp3, wav, mp4, webm
    - Outros: pdf, zip, wasm
    
    SEGURANÇA:
    ----------
    - Bloqueia path traversal (../)
    - Não expõe arquivos fora do diretório público
    
    @module PudimWeb.middleware.static
    @author pessoa736
    @license MIT
--]]

local Static = {}

--- Mapeamento de extensões para Content-Type
local MIME_TYPES = {
    -- Texto
    html = "text/html; charset=utf-8",
    htm = "text/html; charset=utf-8",
    css = "text/css; charset=utf-8",
    js = "application/javascript; charset=utf-8",
    mjs = "application/javascript; charset=utf-8",
    json = "application/json; charset=utf-8",
    xml = "application/xml; charset=utf-8",
    txt = "text/plain; charset=utf-8",
    md = "text/markdown; charset=utf-8",
    
    -- Imagens
    png = "image/png",
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    gif = "image/gif",
    webp = "image/webp",
    svg = "image/svg+xml",
    ico = "image/x-icon",
    bmp = "image/bmp",
    
    -- Fontes
    woff = "font/woff",
    woff2 = "font/woff2",
    ttf = "font/ttf",
    otf = "font/otf",
    eot = "application/vnd.ms-fontobject",
    
    -- Áudio/Vídeo
    mp3 = "audio/mpeg",
    wav = "audio/wav",
    ogg = "audio/ogg",
    mp4 = "video/mp4",
    webm = "video/webm",
    
    -- Outros
    pdf = "application/pdf",
    zip = "application/zip",
    wasm = "application/wasm",
}

--- Obtém o Content-Type baseado na extensão
--- @param path string Caminho do arquivo
--- @return string Content-Type
local function getMimeType(path)
    local ext = path:match("%.([^%.]+)$")
    if ext then
        ext = ext:lower()
        return MIME_TYPES[ext] or "application/octet-stream"
    end
    return "application/octet-stream"
end

--- Verifica se o path é seguro (não permite path traversal)
--- @param path string
--- @return boolean
local function isSafePath(path)
    -- Bloqueia tentativas de path traversal
    if path:match("%.%.") then return false end
    if path:match("^/") then return false end
    return true
end

--- Lê um arquivo
--- @param path string Caminho do arquivo
--- @return string|nil content
--- @return string|nil error
local function readFile(path)
    local file = io.open(path, "rb")
    if not file then
        return nil, "File not found"
    end
    
    local content = file:read("*a")
    file:close()
    return content
end

--- Serve um arquivo estático
--- @param req table Request object
--- @param res table Response object
--- @param staticDir string Diretório base dos arquivos
--- @param prefix string Prefixo de URL
--- @return boolean true se serviu o arquivo
function Static.serve(req, res, staticDir, prefix)
    local path = req.path
    
    -- Remove o prefixo se existir
    if prefix and prefix ~= "/" then
        if path:sub(1, #prefix) == prefix then
            path = path:sub(#prefix + 1)
        end
    end
    
    -- Remove / inicial para concatenar com o diretório
    if path:sub(1, 1) == "/" then
        path = path:sub(2)
    end
    
    -- Verifica segurança do path
    if not isSafePath(path) then
        return false
    end
    
    -- Monta o caminho completo
    local fullPath = staticDir .. "/" .. path
    
    -- Tenta ler o arquivo
    local content = readFile(fullPath)
    if not content then
        return false
    end
    
    -- Obtém o Content-Type
    local mimeType = getMimeType(path)
    
    -- Envia a resposta
    res.type(mimeType)
    res.send(content)
    
    return true
end

return Static
