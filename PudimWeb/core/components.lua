--[[
    PudimWeb Components
    ===================
    
    Sistema de componentes funcionais inspirado no React.
    Permite criar componentes reutilizáveis com props e children.
    
    Integra-se automaticamente com DaviLuaXML através do sistema de middleware,
    renderizando children como string automaticamente.
    
    USO:
    ----
    local component = require("PudimWeb.core.components").create
    
    -- Criar componente
    local Button = component(function(props, children)
        local class = props.class or "btn"
        return '<button class="' .. class .. '">' .. children .. '</button>'
    end)
    
    -- Usar componente (children já vem como string)
    Button({ class = "primary" }, "Clique aqui")
    -- <button class="primary">Clique aqui</button>
    
    -- Com DaviLuaXML (.lx)
    local Btn = html.button
    local Button = component(function(props, children)
        return <Btn class={props.class}>{children}</Btn>
    end)
    
    FUNÇÕES:
    --------
    - create(render): Cria componente funcional
    - renderChildren(children): Renderiza children como string
    - mergeProps(props, defaults): Mescla props com valores padrão
    - setupMiddleware(): Registra middleware no DaviLuaXML (chamado automaticamente)
    
    MIDDLEWARE:
    -----------
    O módulo registra automaticamente um middleware no DaviLuaXML que:
    1. Converte a tabela children para string concatenada
    2. Permite que componentes recebam children como string diretamente
    
    @module PudimWeb.core.components
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local Components = {}

-- Flag para evitar registro duplicado do middleware
Components._middlewareRegistered = false

--- Renderiza children como string
--- @param children table|string|nil
--- @return string
function Components.renderChildren(children)
    if not children then return "" end
    
    if type(children) == "string" then
        return children
    end
    
    if type(children) == "table" then
        local parts = {}
        for _, child in ipairs(children) do
            if type(child) == "function" then
                table.insert(parts, child())
            elseif child then
                table.insert(parts, tostring(child))
            end
        end
        return table.concat(parts)
    end
    
    return tostring(children)
end

--- Registra o middleware no DaviLuaXML
--- Chamado automaticamente quando o módulo é carregado
function Components.setupMiddleware()
    if Components._middlewareRegistered then
        return
    end
    
    -- Tenta carregar o middleware do DaviLuaXML
    local ok, middleware = pcall(require, "DaviLuaXML.middleware")
    if not ok then
        -- DaviLuaXML não está disponível, não registra middleware
        if _G.log then
            _G.log.debug(_G.log.section("PudimWeb"), "DaviLuaXML.middleware não disponível:", middleware)
        end
        return
    end
    
    -- Registra middleware para transformar children em string
    middleware.addChild(function(value, ctx)
        -- Se for uma tabela, converte para string
        if type(value) == "table" then
            local ok2, result = pcall(Components.renderChildren, value)
            if not ok2 then
                if _G.log then
                    _G.log.error(_G.log.section("PudimWeb"), "Erro ao renderizar children:", result)
                end
                return value
            end
            return result
        end
        return value
    end)
    
    Components._middlewareRegistered = true
    
    if _G.log then
        _G.log.debug(_G.log.section("PudimWeb"), "Middleware de children registrado no DaviLuaXML")
    end
end

--- Cria um componente funcional
--- @param render function Função de renderização (props, children) -> string
--- @return function Componente
function Components.create(render)
    return function(props, children)
        props = props or {}
        children = children or {}
        
        -- Renderiza children como string para facilitar uso em DaviLuaXML
        local childrenStr = Components.renderChildren(children)
        
        -- Chama a função de render
        local result = render(props, childrenStr)
        
        return result
    end
end

--- Mescla props com valores padrão
--- @param props table
--- @param defaults table
--- @return table
function Components.mergeProps(props, defaults)
    local merged = {}
    for k, v in pairs(defaults) do
        merged[k] = v
    end
    for k, v in pairs(props or {}) do
        merged[k] = v
    end
    return merged
end

-- Registra o middleware automaticamente ao carregar o módulo
Components.setupMiddleware()

return Components
