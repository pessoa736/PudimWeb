--[[
    PudimWeb Components
    ===================
    
    Sistema de componentes funcionais inspirado no React.
    Permite criar componentes reutilizáveis com props e children.
    
    USO:
    ----
    local component = require("PudimWeb.core.components").create
    
    -- Criar componente
    local Button = component(function(props, children)
        local class = props.class or "btn"
        return '<button class="' .. class .. '">' .. 
               Components.renderChildren(children) .. 
               '</button>'
    end)
    
    -- Usar componente
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
    
    @module PudimWeb.core.components
    @author pessoa736
    @license MIT
--]]

local Components = {}

--- Cria um componente funcional
--- @param render function Função de renderização (props, children) -> string
--- @return function Componente
function Components.create(render)
    return function(props, children)
        props = props or {}
        children = children or {}
        
        -- Converte children para tabela se for string
        if type(children) == "string" then
            children = { children }
        end
        
        -- Chama a função de render
        local result = render(props, children)
        
        return result
    end
end

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

return Components
