--[[
    PudimWeb Renderer
    =================
    
    Sistema de renderização integrado que une VDom, Reconciler e Client.
    Este é o coração do PudimWeb - toda página passa por aqui automaticamente.
    
    FLUXO:
    ------
    1. Componente é executado
    2. VDom é construído automaticamente
    3. Reconciler compara com versão anterior (se houver)
    4. Client scripts são coletados e injetados
    5. HTML final é retornado
    
    RECURSOS:
    ---------
    - Renderização automática via VDom
    - Cache de árvores por página/sessão
    - Injeção automática de scripts do Client
    - Suporte a hidratação no cliente
    
    @module PudimWeb.core.renderer
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local vdom = require("PudimWeb.core.vdom")
local reconciler = require("PudimWeb.core.reconciler")
local client = require("PudimWeb.core.client")
local hooks = require("PudimWeb.core.hooks")

local Renderer = {}

-- Cache de raízes por página (para reconciliação entre requisições)
local pageRoots = {}

-- Configurações globais
local config = {
    -- Injeta scripts do client automaticamente
    autoInjectScripts = true,
    -- Habilita hidratação no cliente
    enableHydration = true,
    -- Cache de árvores VDom
    enableCache = true,
    -- Tempo máximo de cache (segundos)
    cacheMaxAge = 300,
    -- Adiciona data-pudim-id nos elementos para hidratação
    addHydrationIds = true,
}

--- Configura o renderer
--- @param options table
function Renderer.configure(options)
    for k, v in pairs(options or {}) do
        config[k] = v
    end
end

--- Obtém configuração atual
--- @return table
function Renderer.getConfig()
    return config
end

--[[
    Renderização de Componentes
--]]

--- Renderiza um componente para HTML
--- @param component function|table Componente ou VNode
--- @param props table|nil Props do componente
--- @param pageKey string|nil Identificador da página (para cache)
--- @return string HTML renderizado
--- @return table|nil patches Lista de patches (se houve atualização)
function Renderer.render(component, props, pageKey)
    props = props or {}
    
    -- Limpa o buffer do client para esta renderização
    client.clear()
    
    -- Reset hooks
    hooks.reset()
    
    local tree
    local patches = nil
    
    -- Se é uma função (componente), executa
    if type(component) == "function" then
        local ok, result = pcall(component, props)
        if not ok then
            if _G.log then
                _G.log.error(_G.log.section("PudimWeb.renderer"), "Erro ao executar componente:", result)
            end
            return Renderer.renderError(result), nil
        end
        
        -- Converte resultado para VNode se necessário
        tree = Renderer.toVNode(result)
    elseif type(component) == "table" then
        -- Já é um VNode ou tabela
        tree = Renderer.toVNode(component)
    elseif type(component) == "string" then
        -- String HTML direta
        tree = vdom.createTextNode(component)
    else
        tree = vdom.createTextNode(tostring(component or ""))
    end
    
    -- Executa efeitos
    hooks.runEffects()
    
    -- Reconciliação (se pageKey fornecida e cache habilitado)
    if pageKey and config.enableCache then
        local root = pageRoots[pageKey]
        
        if root and root.tree then
            -- Calcula diferenças
            patches = vdom.diff(root.tree, tree)
            
            if _G.log and #patches > 0 then
                _G.log.debug(_G.log.section("PudimWeb.renderer"), 
                    string.format("Página '%s': %d patches gerados", pageKey, #patches))
            end
        end
        
        -- Atualiza cache
        pageRoots[pageKey] = {
            tree = tree,
            timestamp = os.time(),
        }
    end
    
    -- Renderiza para HTML
    local html = vdom.render(tree)
    
    -- Adiciona IDs de hidratação se habilitado
    if config.addHydrationIds then
        html = Renderer.addHydrationMarkers(html, tree)
    end
    
    -- Injeta scripts do client se houver
    if config.autoInjectScripts then
        local scripts = client.flush()
        if scripts and scripts ~= "" and scripts ~= "(function() {\n  'use strict';\n  \n})();" then
            html = Renderer.injectScripts(html, scripts)
        end
    end
    
    return html, patches
end

--- Converte qualquer valor para VNode
--- @param value any
--- @return table VNode
function Renderer.toVNode(value)
    if value == nil then
        return vdom.createTextNode("")
    end
    
    -- Já é VNode
    if type(value) == "table" and value.type then
        return value
    end
    
    -- String HTML - tenta detectar se é HTML e criar estrutura adequada
    if type(value) == "string" then
        -- Se parece com HTML, envolve em um container
        if value:match("^%s*<") then
            -- Retorna como raw HTML (será tratado como texto por enquanto)
            -- TODO: Parser de HTML para VNode
            return {
                type = "#raw",
                props = {},
                children = {},
                html = value,
                _id = "raw_" .. os.time(),
            }
        end
        return vdom.createTextNode(value)
    end
    
    -- Tabela (array de filhos)
    if type(value) == "table" then
        local children = {}
        for _, child in ipairs(value) do
            table.insert(children, Renderer.toVNode(child))
        end
        return vdom.h("div", { class = "pudim-fragment" }, children)
    end
    
    return vdom.createTextNode(tostring(value))
end

--- Renderiza página de erro
--- @param err string Mensagem de erro
--- @return string HTML
function Renderer.renderError(err)
    local errorHtml = string.format([[
<!DOCTYPE html>
<html>
<head>
    <title>Erro - PudimWeb</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a2e; 
            color: #eee; 
            padding: 40px;
            margin: 0;
        }
        .error-container {
            max-width: 800px;
            margin: 0 auto;
            background: #16213e;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }
        h1 { 
            color: #e94560; 
            margin-top: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        pre { 
            background: #0f0f23; 
            padding: 20px; 
            border-radius: 4px;
            overflow-x: auto;
            border-left: 4px solid #e94560;
        }
        .emoji { font-size: 1.5em; }
    </style>
</head>
<body>
    <div class="error-container">
        <h1><span class="emoji">🍮</span> Erro de Renderização</h1>
        <p>Ocorreu um erro ao renderizar a página:</p>
        <pre>%s</pre>
    </div>
</body>
</html>
]], tostring(err):gsub("<", "&lt;"):gsub(">", "&gt;"))

    return errorHtml
end

--- Adiciona marcadores de hidratação ao HTML
--- @param html string
--- @param tree table VNode tree
--- @return string HTML com marcadores
function Renderer.addHydrationMarkers(html, tree)
    -- Por enquanto, adiciona apenas um script de bootstrap
    -- TODO: Implementar marcação de IDs em elementos
    return html
end

--- Injeta scripts no HTML
--- @param html string HTML original
--- @param scripts string Código JavaScript
--- @return string HTML com scripts
function Renderer.injectScripts(html, scripts)
    local scriptTag = string.format([[
<script data-pudim-client>
%s
</script>]], scripts)
    
    -- Tenta injetar antes do </body>
    local injected = html:gsub("(</body>)", scriptTag .. "\n%1")
    
    -- Se não encontrou </body>, adiciona no final
    if injected == html then
        injected = html .. "\n" .. scriptTag
    end
    
    return injected
end

--[[
    Cache e Reconciliação
--]]

--- Obtém raiz da página do cache
--- @param pageKey string
--- @return table|nil
function Renderer.getPageRoot(pageKey)
    return pageRoots[pageKey]
end

--- Remove página do cache
--- @param pageKey string
function Renderer.invalidateCache(pageKey)
    pageRoots[pageKey] = nil
    if _G.log then
        _G.log.debug(_G.log.section("PudimWeb.renderer"), "Cache invalidado para:", pageKey)
    end
end

--- Limpa cache antigo
--- @param maxAge number|nil Idade máxima em segundos
function Renderer.cleanCache(maxAge)
    maxAge = maxAge or config.cacheMaxAge
    local now = os.time()
    local cleaned = 0
    
    for key, root in pairs(pageRoots) do
        if now - (root.timestamp or 0) > maxAge then
            pageRoots[key] = nil
            cleaned = cleaned + 1
        end
    end
    
    if _G.log and cleaned > 0 then
        _G.log.debug(_G.log.section("PudimWeb.renderer"), 
            string.format("Cache limpo: %d páginas removidas", cleaned))
    end
    
    return cleaned
end

--- Limpa todo o cache
function Renderer.clearCache()
    pageRoots = {}
    vdom.clearCache()
end

--- Lista páginas em cache
--- @return table
function Renderer.listCachedPages()
    local pages = {}
    for key, root in pairs(pageRoots) do
        table.insert(pages, {
            key = key,
            timestamp = root.timestamp,
            age = os.time() - (root.timestamp or 0),
        })
    end
    return pages
end

--[[
    Renderização de Página Completa
--]]

--- Renderiza uma página completa com doctype e estrutura HTML
--- @param options table Opções de renderização
--- @return string HTML completo
function Renderer.renderPage(options)
    options = options or {}
    
    local title = options.title or "PudimWeb"
    local head = options.head or ""
    local body = options.body or ""
    local lang = options.lang or "pt-BR"
    local charset = options.charset or "utf-8"
    local scripts = options.scripts or {}
    local styles = options.styles or {}
    
    -- Monta head adicional
    local headExtra = {}
    
    for _, style in ipairs(styles) do
        if style:match("^https?://") or style:match("^/") then
            table.insert(headExtra, string.format('<link rel="stylesheet" href="%s">', style))
        else
            table.insert(headExtra, string.format('<style>%s</style>', style))
        end
    end
    
    -- Monta scripts
    local bodyScripts = {}
    for _, script in ipairs(scripts) do
        if script:match("^https?://") or script:match("^/") then
            table.insert(bodyScripts, string.format('<script src="%s"></script>', script))
        else
            table.insert(bodyScripts, string.format('<script>%s</script>', script))
        end
    end
    
    local html = string.format([[<!DOCTYPE html>
<html lang="%s">
<head>
    <meta charset="%s">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="PudimWeb">
    <title>%s</title>
    %s
    %s
</head>
<body>
    %s
    %s
</body>
</html>]], 
        lang, 
        charset, 
        title, 
        head,
        table.concat(headExtra, "\n    "),
        body,
        table.concat(bodyScripts, "\n    ")
    )
    
    return html
end

--[[
    Wrapper para Componentes com Renderização Automática
--]]

--- Cria um componente com renderização VDom automática
--- @param component function Função do componente
--- @return function Componente wrapped
function Renderer.createComponent(component)
    return function(props)
        -- Limpa client para este componente
        local savedBuffer = client.flush({ wrap = false })
        client.clear()
        
        -- Renderiza
        local html = Renderer.render(component, props)
        
        -- Restaura buffer anterior se havia
        if savedBuffer and savedBuffer ~= "" then
            client.raw(savedBuffer)
        end
        
        return html
    end
end

--[[
    Hidratação (Client-side)
--]]

--- Gera script de hidratação para o cliente
--- @param tree table VNode tree
--- @return string JavaScript
function Renderer.generateHydrationScript(tree)
    local treeJson = vdom.toJSON(tree)
    
    return string.format([[
(function() {
    'use strict';
    
    // PudimWeb Hydration
    window.__PUDIM_STATE__ = %s;
    
    // Marca como hidratado
    document.documentElement.setAttribute('data-pudim-hydrated', 'true');
    
    console.log('🍮 PudimWeb: Página hidratada');
})();
]], treeJson)
end

--- Verifica se uma requisição precisa de hidratação
--- @param req table Request object
--- @return boolean
function Renderer.needsHydration(req)
    -- Verifica header ou query param
    if req.headers and req.headers["x-pudim-hydrate"] then
        return true
    end
    if req.query and req.query._hydrate then
        return true
    end
    return false
end

--[[
    Utilitários
--]]

--- Escapa HTML
--- @param str string
--- @return string
function Renderer.escapeHtml(str)
    if type(str) ~= "string" then
        return tostring(str or "")
    end
    return str:gsub("&", "&amp;")
              :gsub("<", "&lt;")
              :gsub(">", "&gt;")
              :gsub('"', "&quot;")
              :gsub("'", "&#39;")
end

--- Estatísticas do renderer
--- @return table
function Renderer.getStats()
    local cacheSize = 0
    for _ in pairs(pageRoots) do
        cacheSize = cacheSize + 1
    end
    
    return {
        cachedPages = cacheSize,
        config = config,
    }
end

return Renderer
