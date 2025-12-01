--[[
    PudimWeb Client
    ===============
    
    Bindings Lua -> JavaScript para acesso ao ambiente do navegador.
    Gera código JavaScript a partir de chamadas Lua.
    
    USO:
    ----
    local client = require("PudimWeb.core.client")
    
    -- Selecionar elementos
    local btn = client.select("#meuBotao")
    local items = client.selectAll(".item")
    
    -- Manipular DOM
    btn:text("Novo texto")
    btn:html("<strong>HTML</strong>")
    btn:addClass("ativo")
    btn:removeClass("inativo")
    btn:toggleClass("visivel")
    btn:attr("data-id", "123")
    btn:css("color", "red")
    btn:show()
    btn:hide()
    
    -- Event listeners
    btn:on("click", function()
        client.alert("Clicado!")
    end)
    
    -- Fetch API
    client.fetch("/api/users", {
        method = "GET",
        onSuccess = function(data)
            client.console.log(data)
        end,
        onError = function(err)
            client.console.error(err)
        end
    })
    
    -- Gerar script final
    local script = client.build()
    
    COMO FUNCIONA:
    --------------
    1. Chamadas Lua são convertidas em comandos JavaScript
    2. Os comandos são acumulados em um buffer
    3. client.build() retorna todo o JavaScript gerado
    4. O script é injetado na página HTML
    
    @module PudimWeb.core.client
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local Client = {}

-- Buffer de comandos JavaScript
local jsBuffer = {}
local handlerCounter = 0

--- Limpa o buffer de comandos
function Client.clear()
    jsBuffer = {}
    handlerCounter = 0
end

--- Adiciona comando ao buffer
--- @param js string Código JavaScript
local function addJS(js)
    table.insert(jsBuffer, js)
end

--- Escapa string para JavaScript
--- @param str string
--- @return string
local function escapeJS(str)
    if type(str) ~= "string" then
        return tostring(str)
    end
    return str:gsub("\\", "\\\\")
              :gsub("'", "\\'")
              :gsub("\n", "\\n")
              :gsub("\r", "\\r")
              :gsub("\t", "\\t")
end

--- Converte valor Lua para JavaScript
--- @param value any
--- @return string
local function toLuaJS(value)
    if value == nil then
        return "null"
    elseif type(value) == "boolean" then
        return value and "true" or "false"
    elseif type(value) == "number" then
        return tostring(value)
    elseif type(value) == "string" then
        return "'" .. escapeJS(value) .. "'"
    elseif type(value) == "table" then
        -- Verifica se é array
        local isArray = true
        local maxIdx = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            maxIdx = math.max(maxIdx, k)
        end
        isArray = isArray and maxIdx == #value
        
        if isArray then
            local parts = {}
            for _, v in ipairs(value) do
                table.insert(parts, toLuaJS(v))
            end
            return "[" .. table.concat(parts, ", ") .. "]"
        else
            local parts = {}
            for k, v in pairs(value) do
                local key = type(k) == "string" and k or ("[" .. tostring(k) .. "]")
                table.insert(parts, key .. ": " .. toLuaJS(v))
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
    elseif type(value) == "function" then
        -- Funções são convertidas em handlers registrados
        handlerCounter = handlerCounter + 1
        local handlerName = "__pudim_handler_" .. handlerCounter
        
        -- Executa a função para capturar os comandos gerados
        local oldBuffer = jsBuffer
        jsBuffer = {}
        value()
        local innerJS = table.concat(jsBuffer, "\n    ")
        jsBuffer = oldBuffer
        
        return "function(event) {\n    " .. innerJS .. "\n  }"
    end
    return "null"
end

--[[
    Element - Wrapper para elementos DOM
--]]

local Element = {}
Element.__index = Element

function Element.new(selector, isAll)
    local self = setmetatable({}, Element)
    self.selector = selector
    self.isAll = isAll or false
    self.varName = isAll and ("document.querySelectorAll('" .. escapeJS(selector) .. "')") 
                         or ("document.querySelector('" .. escapeJS(selector) .. "')")
    return self
end

--- Define texto do elemento
function Element:text(content)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.textContent = " .. toLuaJS(content) .. "; });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".textContent = " .. toLuaJS(content) .. ";")
    end
    return self
end

--- Define HTML interno do elemento
function Element:html(content)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.innerHTML = " .. toLuaJS(content) .. "; });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".innerHTML = " .. toLuaJS(content) .. ";")
    end
    return self
end

--- Define valor do elemento (input, textarea, select)
function Element:val(value)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.value = " .. toLuaJS(value) .. "; });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".value = " .. toLuaJS(value) .. ";")
    end
    return self
end

--- Adiciona classe
function Element:addClass(className)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.classList.add(" .. toLuaJS(className) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".classList.add(" .. toLuaJS(className) .. ");")
    end
    return self
end

--- Remove classe
function Element:removeClass(className)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.classList.remove(" .. toLuaJS(className) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".classList.remove(" .. toLuaJS(className) .. ");")
    end
    return self
end

--- Toggle classe
function Element:toggleClass(className)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.classList.toggle(" .. toLuaJS(className) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".classList.toggle(" .. toLuaJS(className) .. ");")
    end
    return self
end

--- Define atributo
function Element:attr(name, value)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.setAttribute(" .. toLuaJS(name) .. ", " .. toLuaJS(value) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".setAttribute(" .. toLuaJS(name) .. ", " .. toLuaJS(value) .. ");")
    end
    return self
end

--- Remove atributo
function Element:removeAttr(name)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.removeAttribute(" .. toLuaJS(name) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".removeAttribute(" .. toLuaJS(name) .. ");")
    end
    return self
end

--- Define propriedade CSS
function Element:css(property, value)
    local prop = property:gsub("%-(%w)", function(c) return c:upper() end) -- kebab-case to camelCase
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.style." .. prop .. " = " .. toLuaJS(value) .. "; });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".style." .. prop .. " = " .. toLuaJS(value) .. ";")
    end
    return self
end

--- Mostra elemento
function Element:show()
    return self:css("display", "")
end

--- Esconde elemento
function Element:hide()
    return self:css("display", "none")
end

--- Adiciona event listener
function Element:on(event, handler)
    local handlerJS = toLuaJS(handler)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.addEventListener(" .. toLuaJS(event) .. ", " .. handlerJS .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".addEventListener(" .. toLuaJS(event) .. ", " .. handlerJS .. ");")
    end
    return self
end

--- Remove elemento do DOM
function Element:remove()
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.remove(); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".remove();")
    end
    return self
end

--- Insere HTML antes do elemento
function Element:before(html)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.insertAdjacentHTML('beforebegin', " .. toLuaJS(html) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".insertAdjacentHTML('beforebegin', " .. toLuaJS(html) .. ");")
    end
    return self
end

--- Insere HTML depois do elemento
function Element:after(html)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.insertAdjacentHTML('afterend', " .. toLuaJS(html) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".insertAdjacentHTML('afterend', " .. toLuaJS(html) .. ");")
    end
    return self
end

--- Insere HTML no início do elemento
function Element:prepend(html)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.insertAdjacentHTML('afterbegin', " .. toLuaJS(html) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".insertAdjacentHTML('afterbegin', " .. toLuaJS(html) .. ");")
    end
    return self
end

--- Insere HTML no final do elemento
function Element:append(html)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.insertAdjacentHTML('beforeend', " .. toLuaJS(html) .. "); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".insertAdjacentHTML('beforeend', " .. toLuaJS(html) .. ");")
    end
    return self
end

--- Dispara evento
function Element:trigger(event)
    if self.isAll then
        addJS(self.varName .. ".forEach(function(el) { el.dispatchEvent(new Event(" .. toLuaJS(event) .. ")); });")
    else
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".dispatchEvent(new Event(" .. toLuaJS(event) .. "));")
    end
    return self
end

--- Foca no elemento
function Element:focus()
    if not self.isAll then
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".focus();")
    end
    return self
end

--- Remove foco do elemento
function Element:blur()
    if not self.isAll then
        addJS("if (" .. self.varName .. ") " .. self.varName .. ".blur();")
    end
    return self
end

--[[
    API Pública
--]]

--- Seleciona um elemento
--- @param selector string Seletor CSS
--- @return Element
function Client.select(selector)
    return Element.new(selector, false)
end

--- Seleciona múltiplos elementos
--- @param selector string Seletor CSS
--- @return Element
function Client.selectAll(selector)
    return Element.new(selector, true)
end

--- Alias para select
Client.el = Client.select
Client["$"] = Client.select
Client["$$"] = Client.selectAll

--- Cria novo elemento
--- @param tag string Tag HTML
--- @param props table|nil Propriedades
--- @return string variableName
function Client.create(tag, props)
    local varName = "__pudim_el_" .. (handlerCounter + 1)
    handlerCounter = handlerCounter + 1
    
    addJS("var " .. varName .. " = document.createElement(" .. toLuaJS(tag) .. ");")
    
    if props then
        for k, v in pairs(props) do
            if k == "class" or k == "className" then
                addJS(varName .. ".className = " .. toLuaJS(v) .. ";")
            elseif k == "text" then
                addJS(varName .. ".textContent = " .. toLuaJS(v) .. ";")
            elseif k == "html" then
                addJS(varName .. ".innerHTML = " .. toLuaJS(v) .. ";")
            elseif k:sub(1, 2) == "on" then
                local event = k:sub(3):lower()
                addJS(varName .. ".addEventListener('" .. event .. "', " .. toLuaJS(v) .. ");")
            else
                addJS(varName .. ".setAttribute(" .. toLuaJS(k) .. ", " .. toLuaJS(v) .. ");")
            end
        end
    end
    
    return varName
end

--[[
    Window/Document APIs
--]]

--- Alert
function Client.alert(message)
    addJS("alert(" .. toLuaJS(message) .. ");")
end

--- Confirm
function Client.confirm(message, onConfirm, onCancel)
    addJS("if (confirm(" .. toLuaJS(message) .. ")) {")
    if onConfirm then
        local oldBuffer = jsBuffer
        jsBuffer = {}
        onConfirm()
        local innerJS = table.concat(jsBuffer, "\n  ")
        jsBuffer = oldBuffer
        addJS("  " .. innerJS)
    end
    addJS("}")
    if onCancel then
        addJS("else {")
        local oldBuffer = jsBuffer
        jsBuffer = {}
        onCancel()
        local innerJS = table.concat(jsBuffer, "\n  ")
        jsBuffer = oldBuffer
        addJS("  " .. innerJS)
        addJS("}")
    end
end

--- Prompt
function Client.prompt(message, defaultValue)
    local varName = "__pudim_prompt_" .. (handlerCounter + 1)
    handlerCounter = handlerCounter + 1
    addJS("var " .. varName .. " = prompt(" .. toLuaJS(message) .. ", " .. toLuaJS(defaultValue or "") .. ");")
    return varName
end

--- Console
Client.console = {
    log = function(...)
        local args = {...}
        local jsArgs = {}
        for _, arg in ipairs(args) do
            table.insert(jsArgs, toLuaJS(arg))
        end
        addJS("console.log(" .. table.concat(jsArgs, ", ") .. ");")
    end,
    warn = function(...)
        local args = {...}
        local jsArgs = {}
        for _, arg in ipairs(args) do
            table.insert(jsArgs, toLuaJS(arg))
        end
        addJS("console.warn(" .. table.concat(jsArgs, ", ") .. ");")
    end,
    error = function(...)
        local args = {...}
        local jsArgs = {}
        for _, arg in ipairs(args) do
            table.insert(jsArgs, toLuaJS(arg))
        end
        addJS("console.error(" .. table.concat(jsArgs, ", ") .. ");")
    end,
    info = function(...)
        local args = {...}
        local jsArgs = {}
        for _, arg in ipairs(args) do
            table.insert(jsArgs, toLuaJS(arg))
        end
        addJS("console.info(" .. table.concat(jsArgs, ", ") .. ");")
    end,
}

--- setTimeout
--- @param callback function
--- @param delay number Delay em ms
function Client.setTimeout(callback, delay)
    local handlerJS = toLuaJS(callback)
    addJS("setTimeout(" .. handlerJS .. ", " .. toLuaJS(delay) .. ");")
end

--- setInterval
--- @param callback function
--- @param interval number Intervalo em ms
function Client.setInterval(callback, interval)
    local handlerJS = toLuaJS(callback)
    local varName = "__pudim_interval_" .. (handlerCounter + 1)
    handlerCounter = handlerCounter + 1
    addJS("var " .. varName .. " = setInterval(" .. handlerJS .. ", " .. toLuaJS(interval) .. ");")
    return varName
end

--- Redireciona para URL
function Client.redirect(url)
    addJS("window.location.href = " .. toLuaJS(url) .. ";")
end

--- Recarrega página
function Client.reload()
    addJS("window.location.reload();")
end

--- Navega para trás
function Client.back()
    addJS("window.history.back();")
end

--- Navega para frente
function Client.forward()
    addJS("window.history.forward();")
end

--[[
    Fetch API
--]]

--- Faz requisição HTTP
--- @param url string
--- @param options table|nil
function Client.fetch(url, options)
    options = options or {}
    
    local fetchOptions = {
        method = options.method or "GET",
    }
    
    if options.headers then
        fetchOptions.headers = options.headers
    end
    
    if options.body then
        if type(options.body) == "table" then
            fetchOptions.body = "JSON.stringify(" .. toLuaJS(options.body) .. ")"
            fetchOptions.headers = fetchOptions.headers or {}
            fetchOptions.headers["Content-Type"] = "application/json"
        else
            fetchOptions.body = toLuaJS(options.body)
        end
    end
    
    -- Gera o código fetch
    local js = "fetch(" .. toLuaJS(url) .. ", {"
    local optParts = {}
    
    table.insert(optParts, "method: " .. toLuaJS(fetchOptions.method))
    
    if fetchOptions.headers then
        table.insert(optParts, "headers: " .. toLuaJS(fetchOptions.headers))
    end
    
    if fetchOptions.body then
        if type(options.body) == "table" then
            table.insert(optParts, "body: JSON.stringify(" .. toLuaJS(options.body) .. ")")
        else
            table.insert(optParts, "body: " .. toLuaJS(options.body))
        end
    end
    
    js = js .. table.concat(optParts, ", ") .. "})"
    
    -- Response handling
    js = js .. "\n  .then(function(response) { return response.json(); })"
    
    if options.onSuccess then
        local oldBuffer = jsBuffer
        jsBuffer = {}
        options.onSuccess("data")
        local innerJS = table.concat(jsBuffer, "\n      ")
        jsBuffer = oldBuffer
        js = js .. "\n  .then(function(data) {\n      " .. innerJS .. "\n  })"
    end
    
    if options.onError then
        local oldBuffer = jsBuffer
        jsBuffer = {}
        options.onError("error")
        local innerJS = table.concat(jsBuffer, "\n      ")
        jsBuffer = oldBuffer
        js = js .. "\n  .catch(function(error) {\n      " .. innerJS .. "\n  })"
    end
    
    js = js .. ";"
    addJS(js)
end

--[[
    Local Storage
--]]

Client.storage = {
    get = function(key)
        local varName = "__pudim_storage_" .. (handlerCounter + 1)
        handlerCounter = handlerCounter + 1
        addJS("var " .. varName .. " = localStorage.getItem(" .. toLuaJS(key) .. ");")
        return varName
    end,
    set = function(key, value)
        addJS("localStorage.setItem(" .. toLuaJS(key) .. ", " .. toLuaJS(value) .. ");")
    end,
    remove = function(key)
        addJS("localStorage.removeItem(" .. toLuaJS(key) .. ");")
    end,
    clear = function()
        addJS("localStorage.clear();")
    end,
}

--[[
    Session Storage
--]]

Client.session = {
    get = function(key)
        local varName = "__pudim_session_" .. (handlerCounter + 1)
        handlerCounter = handlerCounter + 1
        addJS("var " .. varName .. " = sessionStorage.getItem(" .. toLuaJS(key) .. ");")
        return varName
    end,
    set = function(key, value)
        addJS("sessionStorage.setItem(" .. toLuaJS(key) .. ", " .. toLuaJS(value) .. ");")
    end,
    remove = function(key)
        addJS("sessionStorage.removeItem(" .. toLuaJS(key) .. ");")
    end,
    clear = function()
        addJS("sessionStorage.clear();")
    end,
}

--[[
    JavaScript direto
--]]

--- Executa código JavaScript arbitrário
--- @param code string
function Client.raw(code)
    addJS(code)
end

--- Executa código quando DOM estiver pronto
--- @param callback function
function Client.ready(callback)
    addJS("document.addEventListener('DOMContentLoaded', " .. toLuaJS(callback) .. ");")
end

--- Executa código quando página carregar completamente
--- @param callback function
function Client.onLoad(callback)
    addJS("window.addEventListener('load', " .. toLuaJS(callback) .. ");")
end

--[[
    Build
--]]

--- Constrói o script JavaScript final
--- @param options table|nil
--- @return string JavaScript code
function Client.build(options)
    options = options or {}
    
    local js = table.concat(jsBuffer, "\n")
    
    -- Wrap em IIFE para evitar poluição do escopo global
    if options.wrap ~= false then
        js = "(function() {\n  'use strict';\n  " .. js:gsub("\n", "\n  ") .. "\n})();"
    end
    
    return js
end

--- Constrói e envolve em tag <script>
--- @param options table|nil
--- @return string HTML script tag
function Client.buildTag(options)
    options = options or {}
    local js = Client.build(options)
    
    if options.defer then
        return '<script defer>\n' .. js .. '\n</script>'
    elseif options.async then
        return '<script async>\n' .. js .. '\n</script>'
    else
        return '<script>\n' .. js .. '\n</script>'
    end
end

--- Constrói e limpa o buffer
--- @param options table|nil
--- @return string JavaScript code
function Client.flush(options)
    local js = Client.build(options)
    Client.clear()
    return js
end

--- Constrói tag e limpa o buffer
--- @param options table|nil
--- @return string HTML script tag
function Client.flushTag(options)
    local tag = Client.buildTag(options)
    Client.clear()
    return tag
end

return Client
