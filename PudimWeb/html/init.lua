--[[
    PudimWeb HTML
    =============
    
    Gerador de tags HTML para o PudimWeb.
    Fornece funções para criar qualquer tag HTML de forma programática.
    
    USO:
    ----
    local html = require("PudimWeb.html")
    
    -- Tags básicas
    html.div({ class = "container" }, "Conteúdo")
    -- <div class="container">Conteúdo</div>
    
    -- Tags self-closing
    html.img({ src = "foto.jpg", alt = "Foto" })
    -- <img src="foto.jpg" alt="Foto" />
    
    -- Aninhamento
    html.div({ class = "card" }, {
        html.h1({}, "Título"),
        html.p({}, "Descrição")
    })
    
    -- Doctype
    html.doctype  -- "<!DOCTYPE html>"
    
    -- Fragment (sem tag wrapper)
    html.fragment({ "item1", "item2" })
    
    TAGS DISPONÍVEIS:
    -----------------
    Todas as tags HTML5 são suportadas automaticamente.
    Ex: div, span, p, h1-h6, a, img, form, input, button, etc.
    
    @module PudimWeb.html
    @author pessoa736
    @license MIT
--]]

local HTML = {}

--- Tags que não precisam de fechamento
local VOID_TAGS = {
    area = true, base = true, br = true, col = true,
    embed = true, hr = true, img = true, input = true,
    link = true, meta = true, param = true, source = true,
    track = true, wbr = true,
}

--- Escapa caracteres especiais HTML
--- @param str string
--- @return string
local function escape(str)
    if type(str) ~= "string" then return tostring(str) end
    local result = str
    result = result:gsub("&", "&amp;")
    result = result:gsub("<", "&lt;")
    result = result:gsub(">", "&gt;")
    result = result:gsub('"', "&quot;")
    result = result:gsub("'", "&#39;")
    return result
end

--- Converte tabela de props para string de atributos
--- @param props table
--- @return string
local function propsToString(props)
    if not props or type(props) ~= "table" then return "" end
    
    local parts = {}
    for key, value in pairs(props) do
        if type(key) == "string" then
            if value == true then
                table.insert(parts, key)
            elseif value and value ~= false then
                table.insert(parts, key .. '="' .. escape(tostring(value)) .. '"')
            end
        end
    end
    
    return table.concat(parts, " ")
end

--- Processa children para string
--- @param children any
--- @return string
local function processChildren(children)
    if not children then return "" end
    
    if type(children) == "string" then
        return children
    end
    
    if type(children) == "table" then
        local parts = {}
        for _, child in ipairs(children) do
            if child then
                table.insert(parts, tostring(child))
            end
        end
        return table.concat(parts)
    end
    
    return tostring(children)
end

--- Cria uma função geradora de tag
--- @param tagName string
--- @return function
local function createTag(tagName)
    local isVoid = VOID_TAGS[tagName]
    
    return function(props, children)
        local propsStr = propsToString(props)
        local space = propsStr ~= "" and " " or ""
        
        if isVoid then
            return "<" .. tagName .. space .. propsStr .. " />"
        end
        
        local childrenStr = processChildren(children)
        return "<" .. tagName .. space .. propsStr .. ">" .. childrenStr .. "</" .. tagName .. ">"
    end
end

--- Lista de todas as tags HTML suportadas
local TAG_NAMES = {
    -- Estrutura do documento
    "html", "head", "body", "title", "base", "link", "meta", "style",
    -- Seções
    "header", "nav", "main", "section", "article", "aside", "footer",
    "h1", "h2", "h3", "h4", "h5", "h6",
    -- Agrupamento
    "div", "p", "hr", "pre", "blockquote", "ol", "ul", "li", "dl", "dt", "dd",
    "figure", "figcaption", "address",
    -- Texto
    "span", "a", "em", "strong", "small", "s", "cite", "q", "dfn", "abbr",
    "code", "var", "samp", "kbd", "sub", "sup", "i", "b", "u", "mark",
    "ruby", "rt", "rp", "bdi", "bdo", "br", "wbr",
    -- Edição
    "ins", "del",
    -- Conteúdo incorporado
    "img", "iframe", "embed", "object", "param", "video", "audio", "source",
    "track", "canvas", "map", "area", "svg", "math",
    -- Tabelas
    "table", "caption", "colgroup", "col", "thead", "tbody", "tfoot", "tr", "th", "td",
    -- Formulários
    "form", "label", "input", "button", "select", "datalist", "optgroup", "option",
    "textarea", "output", "progress", "meter", "fieldset", "legend",
    -- Interativo
    "details", "summary", "dialog", "menu",
    -- Scripts
    "script", "noscript", "template", "slot",
}

-- Registra todas as tags
for _, tagName in ipairs(TAG_NAMES) do
    HTML[tagName] = createTag(tagName)
end

--- Cria tag customizada
--- @param tagName string
--- @return function
function HTML.tag(tagName)
    return createTag(tagName)
end

--- Cria fragmento (sem tag wrapper)
--- @param children table
--- @return string
function HTML.fragment(children)
    return processChildren(children)
end

--- Texto escapado
--- @param text string
--- @return string
function HTML.text(text)
    return escape(text)
end

--- Texto raw (sem escape)
--- @param text string
--- @return string
function HTML.raw(text)
    return text
end

--- DOCTYPE HTML5
HTML.doctype = "<!DOCTYPE html>"

return HTML
