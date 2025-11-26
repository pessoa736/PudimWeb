--[[
    PudimWeb JSON Utils
    ===================
    
    Utilitário simples para serialização JSON.
    Implementação leve sem dependências externas.
    
    USO:
    ----
    local json = require("PudimWeb.utils.json")
    
    -- Codificar
    local str = json.encode({ name = "João", age = 30 })
    -- '{"name":"João","age":30}'
    
    -- Codificar formatado
    local str = json.encode({ name = "João" }, true)
    -- '{
    --   "name": "João"
    -- }'
    
    -- Decodificar
    local obj = json.decode('{"name":"João"}')
    -- { name = "João" }
    
    TIPOS SUPORTADOS:
    -----------------
    - string, number, boolean, nil
    - table (array e objeto)
    - Nested tables
    
    @module PudimWeb.utils.json
    @author pessoa736
    @license MIT
--]]

local JSON = {}

--- Escapa string para JSON
--- @param s string
--- @return string
local function escapeString(s)
    local escapes = {
        ['"'] = '\\"',
        ['\\'] = '\\\\',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t',
    }
    local result = s:gsub('["\\\b\f\n\r\t]', escapes)
    return result
end

--- Verifica se tabela é array
--- @param t table
--- @return boolean
local function isArray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

--- Codifica valor para JSON
--- @param value any
--- @param indent number|nil Nível de indentação (nil = sem formatação)
--- @return string
function JSON.encode(value, indent)
    local t = type(value)
    
    if value == nil then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        if value ~= value then -- NaN
            return "null"
        elseif value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    elseif t == "string" then
        return '"' .. escapeString(value) .. '"'
    elseif t == "table" then
        local parts = {}
        
        if isArray(value) then
            for _, v in ipairs(value) do
                table.insert(parts, JSON.encode(v, indent))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(value) do
                if type(k) == "string" then
                    table.insert(parts, '"' .. escapeString(k) .. '":' .. JSON.encode(v, indent))
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return "null"
    end
end

--- Decodifica JSON para valor Lua (implementação básica)
--- @param str string JSON string
--- @return any
function JSON.decode(str)
    -- Implementação básica usando load (CUIDADO: não é seguro para JSON não confiável)
    -- Para produção, use uma biblioteca JSON real
    if not str or str == "" then return nil end
    
    str = str:gsub('"([^"]-)":', '["%1"]=')
    str = str:gsub('%[', '{')
    str = str:gsub('%]', '}')
    str = str:gsub(':true', '=true')
    str = str:gsub(':false', '=false')
    str = str:gsub(':null', '=nil')
    
    local fn = load("return " .. str)
    if fn then
        local ok, result = pcall(fn)
        if ok then return result end
    end
    
    return nil
end

return JSON
