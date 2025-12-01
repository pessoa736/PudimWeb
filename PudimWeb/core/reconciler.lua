--[[
    PudimWeb Reconciler
    ===================
    
    Sistema de reconciliação que integra o VDom com os componentes.
    Gerencia o ciclo de vida de renderização e atualização.
    
    USO:
    ----
    local reconciler = require("PudimWeb.core.reconciler")
    
    -- Registrar componente para reconciliação
    local App = reconciler.createRoot(function(props)
        return vdom.h("div", { class = "app" }, {
            vdom.h("h1", {}, props.title),
            vdom.h("p", {}, props.content)
        })
    end)
    
    -- Primeira renderização
    local html = App:render({ title = "Olá", content = "Mundo" })
    
    -- Atualização (gera apenas as mudanças)
    local patches = App:update({ title = "Olá", content = "Mundo Atualizado" })
    local updateScript = App:getUpdateScript()
    
    WORKFLOW:
    ---------
    1. createRoot() - Cria raiz da aplicação com componente
    2. render() - Renderiza componente completo (primeira vez)
    3. update() - Atualiza e calcula diferenças
    4. getUpdateScript() - Gera JavaScript para aplicar mudanças
    
    @module PudimWeb.core.reconciler
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local vdom = require("PudimWeb.core.vdom")
local hooks = require("PudimWeb.core.hooks")

local Reconciler = {}

--[[
    Root - Raiz de uma aplicação
    
    Gerencia o estado da árvore e reconciliação.
--]]

local Root = {}
Root.__index = Root

--- Cria uma nova raiz
--- @param component function Componente raiz
--- @return table Root instance
function Root.new(component)
    local self = setmetatable({}, Root)
    self.component = component
    self.currentTree = nil
    self.previousTree = nil
    self.patches = {}
    self.isFirstRender = true
    self.props = {}
    self.state = {}
    return self
end

--- Renderiza o componente
--- @param props table|nil Props para o componente
--- @return string HTML renderizado
function Root:render(props)
    self.props = props or {}
    
    -- Reset hooks antes de renderizar
    hooks.reset()
    
    -- Salva árvore anterior
    self.previousTree = self.currentTree
    
    -- Renderiza nova árvore
    local ok, result = pcall(self.component, self.props)
    if not ok then
        if _G.log then
            _G.log.error(_G.log.section("PudimWeb.reconciler"), "Erro ao renderizar componente:", result)
        end
        self.currentTree = vdom.createTextNode("[Erro de renderização]")
        return vdom.render(self.currentTree)
    end
    
    -- Se resultado é VNode, usa diretamente
    if type(result) == "table" and result.type then
        self.currentTree = result
    else
        -- Se é string/outro, envolve em text node
        self.currentTree = vdom.createTextNode(tostring(result or ""))
    end
    
    -- Executa efeitos
    hooks.runEffects()
    
    -- Marca como não mais primeira renderização
    self.isFirstRender = false
    
    -- Renderiza para HTML
    return vdom.render(self.currentTree)
end

--- Atualiza o componente e calcula patches
--- @param props table|nil Novos props
--- @return table Lista de patches
function Root:update(props)
    props = props or self.props
    
    -- Se é primeira renderização, renderiza normalmente
    if self.isFirstRender or not self.currentTree then
        self:render(props)
        return {}
    end
    
    -- Salva props
    self.props = props
    
    -- Reset hooks
    hooks.reset()
    
    -- Salva árvore anterior
    self.previousTree = self.currentTree
    
    -- Renderiza nova árvore
    local ok, result = pcall(self.component, props)
    if not ok then
        if _G.log then
            _G.log.error(_G.log.section("PudimWeb.reconciler"), "Erro ao atualizar componente:", result)
        end
        return {}
    end
    
    if type(result) == "table" and result.type then
        self.currentTree = result
    else
        self.currentTree = vdom.createTextNode(tostring(result or ""))
    end
    
    -- Executa efeitos
    hooks.runEffects()
    
    -- Calcula diferenças
    local ok2, patches = pcall(vdom.diff, self.previousTree, self.currentTree)
    if not ok2 then
        if _G.log then
            _G.log.error(_G.log.section("PudimWeb.reconciler"), "Erro ao calcular diff:", patches)
        end
        return {}
    end
    
    self.patches = patches
    return self.patches
end

--- Verifica se houve mudanças na última atualização
--- @return boolean
function Root:hasChanges()
    return #self.patches > 0
end

--- Obtém quantidade de mudanças
--- @return number
function Root:getChangeCount()
    return #self.patches
end

--- Gera script JavaScript para aplicar mudanças no cliente
--- @return string JavaScript code
function Root:getUpdateScript()
    return vdom.generateUpdateScript(self.patches)
end

--- Obtém os patches da última atualização
--- @return table
function Root:getPatches()
    return self.patches
end

--- Obtém HTML renderizado da árvore atual
--- @return string
function Root:getHTML()
    if self.currentTree then
        return vdom.render(self.currentTree)
    end
    return ""
end

--- Obtém a árvore atual
--- @return table|nil VNode tree
function Root:getTree()
    return self.currentTree
end

--- Inspeciona a árvore atual (debug)
--- @return string
function Root:inspect()
    if self.currentTree then
        return vdom.inspect(self.currentTree)
    end
    return "No tree"
end

--- Limpa estado
function Root:reset()
    self.currentTree = nil
    self.previousTree = nil
    self.patches = {}
    self.isFirstRender = true
end

--[[
    API Pública
--]]

--- Cria uma raiz de aplicação
--- @param component function Componente raiz
--- @return table Root instance
function Reconciler.createRoot(component)
    return Root.new(component)
end

--[[
    Gerenciador de Páginas
    
    Gerencia múltiplas raízes para diferentes páginas/rotas.
--]]

local pageRoots = {}

--- Obtém ou cria raiz para uma página
--- @param pageKey string Identificador da página (ex: URL)
--- @param component function Componente da página
--- @return table Root instance
function Reconciler.getPageRoot(pageKey, component)
    if not pageRoots[pageKey] then
        pageRoots[pageKey] = Root.new(component)
    elseif component then
        -- Atualiza componente se fornecido
        pageRoots[pageKey].component = component
    end
    return pageRoots[pageKey]
end

--- Remove raiz de uma página
--- @param pageKey string
function Reconciler.removePageRoot(pageKey)
    pageRoots[pageKey] = nil
end

--- Lista todas as páginas registradas
--- @return table Lista de pageKeys
function Reconciler.listPages()
    local keys = {}
    for key in pairs(pageRoots) do
        table.insert(keys, key)
    end
    return keys
end

--- Limpa todas as raízes
function Reconciler.clearAll()
    pageRoots = {}
end

--[[
    Helpers para criação de VNodes com sintaxe mais limpa
--]]

--- Cria elemento com children como argumentos variádicos
--- @param tag string
--- @param props table|nil
--- @vararg any Children
--- @return table VNode
function Reconciler.createElement(tag, props, ...)
    local children = {...}
    if #children == 0 then
        return vdom.h(tag, props, {})
    elseif #children == 1 then
        return vdom.h(tag, props, children[1])
    end
    return vdom.h(tag, props, children)
end

-- Atalho
Reconciler.el = Reconciler.createElement

--[[
    HOC (Higher Order Component) para adicionar reconciliação automática
--]]

--- Envolve componente com reconciliação automática
--- @param component function
--- @param key string|nil Chave única para cache
--- @return function
function Reconciler.withReconciliation(component, key)
    local root = nil
    
    return function(props)
        if not root then
            root = Root.new(component)
            return root:render(props)
        end
        
        -- Atualiza e verifica se há mudanças
        local patches = root:update(props)
        
        if #patches > 0 then
            -- Retorna HTML completo com script de update
            local html = root:getHTML()
            local script = root:getUpdateScript()
            return html .. "\n<script>\n" .. script .. "\n</script>"
        end
        
        return root:getHTML()
    end
end

return Reconciler
