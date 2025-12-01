--[[
    PudimWeb Hooks
    ==============
    
    Sistema de hooks inspirado no React.
    Permite gerenciar estado e efeitos colaterais em componentes.
    
    IMPORTANTE:
    -----------
    Em Lua/servidor, hooks funcionam de forma diferente do React.
    Aqui são helpers para gerenciar estado durante a renderização
    de uma única requisição (sem persistência entre requisições).
    
    HOOKS DISPONÍVEIS:
    ------------------
    
    useState(initial)
        Gerencia estado local
        local count, setCount = useState(0)
        setCount(count + 1)
        setCount(function(prev) return prev + 1 end)
    
    useEffect(effect, deps)
        Registra efeito colateral
        useEffect(function()
            print("Executado!")
            return function() print("Cleanup") end
        end, {})
    
    useMemo(compute, deps)
        Memoriza valor computado
        local doubled = useMemo(function() return x * 2 end, {x})
    
    useCallback(fn, deps)
        Memoriza função (alias para useMemo)
        local handler = useCallback(function() ... end, {dep})
    
    createContext(default)
        Cria contexto para compartilhar dados
        local ThemeContext = createContext("light")
    
    useContext(context)
        Consome valor do contexto
        local theme = useContext(ThemeContext)
    
    @module PudimWeb.core.hooks
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local Hooks = {}

-- Armazena estado global para a requisição atual
local currentState = {}
local stateIndex = 0
local effects = {}
local memoCache = {}

--- Reseta o estado dos hooks (chamado a cada requisição)
function Hooks.reset()
    currentState = {}
    stateIndex = 0
    effects = {}
end

--- useState - Gerencia estado local
--- @param initialValue any Valor inicial
--- @return any value Valor atual
--- @return function setter Função para atualizar
function Hooks.useState(initialValue)
    local index = stateIndex
    stateIndex = stateIndex + 1
    
    -- Inicializa se não existir
    if currentState[index] == nil then
        currentState[index] = initialValue
    end
    
    local value = currentState[index]
    
    local function setValue(newValue)
        if type(newValue) == "function" then
            currentState[index] = newValue(currentState[index])
        else
            currentState[index] = newValue
        end
    end
    
    return value, setValue
end

--- useEffect - Registra efeito colateral
--- @param effect function Função do efeito
--- @param deps table|nil Dependências (nil = sempre executa)
function Hooks.useEffect(effect, deps)
    table.insert(effects, {
        effect = effect,
        deps = deps,
    })
end

--- useMemo - Memoriza valor computado
--- @param compute function Função que computa o valor
--- @param deps table Dependências
--- @return any Valor memorizado
function Hooks.useMemo(compute, deps)
    local key = tostring(compute)
    
    -- Verifica se deps mudaram
    local cached = memoCache[key]
    if cached then
        local depsChanged = false
        if deps and cached.deps then
            for i, dep in ipairs(deps) do
                if dep ~= cached.deps[i] then
                    depsChanged = true
                    break
                end
            end
        else
            depsChanged = true
        end
        
        if not depsChanged then
            return cached.value
        end
    end
    
    -- Computa novo valor
    local value = compute()
    memoCache[key] = { value = value, deps = deps }
    return value
end

--- useCallback - Memoriza função (alias para useMemo)
--- @param callback function
--- @param deps table
--- @return function
function Hooks.useCallback(callback, deps)
    return Hooks.useMemo(function() return callback end, deps)
end

-- Contextos
local contexts = {}

--- Cria um contexto
--- @param defaultValue any
--- @return table Context
function Hooks.createContext(defaultValue)
    local context = {
        _defaultValue = defaultValue,
        _currentValue = defaultValue,
    }
    return context
end

--- useContext - Obtém valor do contexto
--- @param context table
--- @return any
function Hooks.useContext(context)
    return context._currentValue or context._defaultValue
end

--- Provider - Define valor do contexto
--- @param context table
--- @param value any
--- @param children table|string
--- @return string
function Hooks.Provider(context, value, children)
    local oldValue = context._currentValue
    context._currentValue = value
    
    local result
    if type(children) == "function" then
        result = children()
    elseif type(children) == "table" then
        local parts = {}
        for _, child in ipairs(children) do
            if type(child) == "function" then
                table.insert(parts, child())
            else
                table.insert(parts, tostring(child))
            end
        end
        result = table.concat(parts)
    else
        result = tostring(children or "")
    end
    
    context._currentValue = oldValue
    return result
end

--- Executa todos os efeitos registrados
function Hooks.runEffects()
    for i, e in ipairs(effects) do
        local ok, err = pcall(e.effect)
        if not ok and _G.log then
            _G.log.error(_G.log.section("PudimWeb.hooks"), "Erro ao executar efeito #" .. i .. ":", err)
        end
    end
    effects = {}
end

return Hooks
