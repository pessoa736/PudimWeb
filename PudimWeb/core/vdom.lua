--[[
    PudimWeb Virtual DOM (VDom)
    ===========================
    
    Sistema de Virtual DOM com tree diffing inspirado no React.
    Compara árvores de elementos e gera patches mínimos para
    atualizar apenas o que mudou.
    
    USO:
    ----
    local vdom = require("PudimWeb.core.vdom")
    
    -- Criar VNodes
    local tree1 = vdom.h("div", { class = "container" }, {
        vdom.h("h1", {}, "Título"),
        vdom.h("p", {}, "Texto original")
    })
    
    local tree2 = vdom.h("div", { class = "container" }, {
        vdom.h("h1", {}, "Título"),
        vdom.h("p", {}, "Texto modificado")
    })
    
    -- Calcular diferenças
    local patches = vdom.diff(tree1, tree2)
    
    -- Aplicar patches (gera script de update)
    local updateScript = vdom.patch(patches)
    
    TIPOS DE PATCHES:
    -----------------
    - REPLACE: Substitui nó inteiro
    - PROPS: Atualiza propriedades
    - TEXT: Atualiza texto
    - REORDER: Reordena filhos
    - INSERT: Insere novo nó
    - REMOVE: Remove nó
    
    @module PudimWeb.core.vdom
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local VDom = {}

-- Tipos de patches
VDom.PATCH_TYPES = {
    REPLACE = "REPLACE",
    PROPS = "PROPS",
    TEXT = "TEXT",
    REORDER = "REORDER",
    INSERT = "INSERT",
    REMOVE = "REMOVE",
}

--- Gera ID único para nós
local nodeIdCounter = 0
local function generateId()
    nodeIdCounter = nodeIdCounter + 1
    return "vnode_" .. nodeIdCounter
end

--- Reseta contador de IDs (para testes)
function VDom.resetIdCounter()
    nodeIdCounter = 0
end

--[[
    VNode - Representação de um nó virtual
    
    Estrutura:
    {
        type = "div" | "#text" | ComponentFunction,
        props = { class = "btn", onClick = fn },
        children = { VNode, VNode, ... },
        key = "unique-key" (opcional),
        _id = "vnode_1" (gerado automaticamente),
    }
--]]

--- Cria um VNode (elemento virtual)
--- @param nodeType string|function Tag HTML ou componente
--- @param props table|nil Propriedades
--- @param children table|string|nil Filhos
--- @return table VNode
function VDom.h(nodeType, props, children)
    props = props or {}
    
    -- Normaliza children
    local normalizedChildren = {}
    
    if children ~= nil then
        if type(children) == "table" and children.type == nil then
            -- É uma lista de filhos
            for _, child in ipairs(children) do
                if child ~= nil then
                    table.insert(normalizedChildren, VDom.normalizeChild(child))
                end
            end
        else
            -- É um único filho
            table.insert(normalizedChildren, VDom.normalizeChild(children))
        end
    end
    
    local vnode = {
        type = nodeType,
        props = props,
        children = normalizedChildren,
        key = props.key,
        _id = generateId(),
    }
    
    -- Remove key das props (não deve ir para o DOM)
    vnode.props.key = nil
    
    return vnode
end

--- Normaliza um child para VNode
--- @param child any
--- @return table VNode
function VDom.normalizeChild(child)
    if type(child) == "string" or type(child) == "number" then
        return VDom.createTextNode(tostring(child))
    elseif type(child) == "table" and child.type then
        return child
    elseif type(child) == "boolean" or child == nil then
        return VDom.createTextNode("")
    end
    return VDom.createTextNode(tostring(child))
end

--- Cria um nó de texto
--- @param text string
--- @return table VNode
function VDom.createTextNode(text)
    return {
        type = "#text",
        props = {},
        children = {},
        text = text,
        _id = generateId(),
    }
end

--- Verifica se dois VNodes são do mesmo tipo
--- @param vnode1 table|nil
--- @param vnode2 table|nil
--- @return boolean
function VDom.isSameType(vnode1, vnode2)
    if not vnode1 or not vnode2 then
        return false
    end
    
    -- Se ambos têm keys, compara por key
    if vnode1.key and vnode2.key then
        return vnode1.type == vnode2.type and vnode1.key == vnode2.key
    end
    
    return vnode1.type == vnode2.type
end

--- Compara duas tabelas de props
--- @param props1 table
--- @param props2 table
--- @return table|nil Diferenças ou nil se iguais
function VDom.diffProps(props1, props2)
    local changes = {}
    local hasChanges = false
    
    -- Props removidas ou alteradas
    for key, value1 in pairs(props1) do
        local value2 = props2[key]
        if value2 == nil then
            changes[key] = { action = "remove" }
            hasChanges = true
        elseif value1 ~= value2 then
            changes[key] = { action = "update", value = value2 }
            hasChanges = true
        end
    end
    
    -- Props novas
    for key, value2 in pairs(props2) do
        if props1[key] == nil then
            changes[key] = { action = "add", value = value2 }
            hasChanges = true
        end
    end
    
    return hasChanges and changes or nil
end

--- Calcula diferenças entre duas árvores de VNodes
--- @param oldTree table|nil VNode antigo
--- @param newTree table|nil VNode novo
--- @param path string|nil Caminho atual na árvore
--- @return table Lista de patches
function VDom.diff(oldTree, newTree, path)
    path = path or "root"
    local patches = {}
    
    -- Caso 1: Novo nó foi adicionado
    if oldTree == nil and newTree ~= nil then
        table.insert(patches, {
            type = VDom.PATCH_TYPES.INSERT,
            path = path,
            node = newTree,
        })
        return patches
    end
    
    -- Caso 2: Nó foi removido
    if oldTree ~= nil and newTree == nil then
        table.insert(patches, {
            type = VDom.PATCH_TYPES.REMOVE,
            path = path,
        })
        return patches
    end
    
    -- Caso 3: Ambos nil
    if oldTree == nil and newTree == nil then
        return patches
    end
    
    -- Caso 4: Tipos diferentes - substituir completamente
    if not VDom.isSameType(oldTree, newTree) then
        table.insert(patches, {
            type = VDom.PATCH_TYPES.REPLACE,
            path = path,
            oldNode = oldTree,
            newNode = newTree,
        })
        return patches
    end
    
    -- Caso 5: Nó de texto - verificar se texto mudou
    -- (Neste ponto, oldTree e newTree são garantidamente não-nil)
    if oldTree.type == "#text" then
        local oldText = oldTree.text or ""
        local newText = newTree.text or ""
        if oldText ~= newText then
            table.insert(patches, {
                type = VDom.PATCH_TYPES.TEXT,
                path = path,
                oldText = oldText,
                newText = newText,
            })
        end
        return patches
    end
    
    -- Caso 6: Mesmo tipo de elemento - comparar props e filhos
    -- (Neste ponto, oldTree e newTree são garantidamente não-nil e do mesmo tipo)
    
    -- Diff de props
    local propChanges = VDom.diffProps(oldTree.props or {}, newTree.props or {})
    if propChanges then
        table.insert(patches, {
            type = VDom.PATCH_TYPES.PROPS,
            path = path,
            changes = propChanges,
        })
    end
    
    -- Diff de filhos
    local childPatches = VDom.diffChildren(oldTree.children or {}, newTree.children or {}, path)
    for _, patch in ipairs(childPatches) do
        table.insert(patches, patch)
    end
    
    return patches
end

--- Calcula diferenças entre listas de filhos
--- @param oldChildren table
--- @param newChildren table
--- @param parentPath string
--- @return table Lista de patches
function VDom.diffChildren(oldChildren, newChildren, parentPath)
    local patches = {}
    
    -- Criar mapas por key para reconciliação eficiente
    local oldKeyMap = {}
    local newKeyMap = {}
    
    for i, child in ipairs(oldChildren) do
        if child.key then
            oldKeyMap[child.key] = { index = i, node = child }
        end
    end
    
    for i, child in ipairs(newChildren) do
        if child.key then
            newKeyMap[child.key] = { index = i, node = child }
        end
    end
    
    -- Algoritmo de reconciliação
    local maxLen = math.max(#oldChildren, #newChildren)
    local reorderMoves = {}
    local hasReorder = false
    
    for i = 1, maxLen do
        local oldChild = oldChildren[i]
        local newChild = newChildren[i]
        local childPath = parentPath .. ".children[" .. i .. "]"
        
        -- Se novo filho tem key, tenta encontrar no antigo
        if newChild and newChild.key and oldKeyMap[newChild.key] then
            local oldEntry = oldKeyMap[newChild.key]
            if oldEntry.index ~= i then
                -- Nó foi movido
                hasReorder = true
                table.insert(reorderMoves, {
                    from = oldEntry.index,
                    to = i,
                    key = newChild.key,
                })
                -- Diff do conteúdo
                local childPatches = VDom.diff(oldEntry.node, newChild, childPath)
                for _, patch in ipairs(childPatches) do
                    table.insert(patches, patch)
                end
            else
                -- Mesma posição, faz diff normal
                local childPatches = VDom.diff(oldChild, newChild, childPath)
                for _, patch in ipairs(childPatches) do
                    table.insert(patches, patch)
                end
            end
        else
            -- Sem key ou key não encontrada - diff normal
            local childPatches = VDom.diff(oldChild, newChild, childPath)
            for _, patch in ipairs(childPatches) do
                table.insert(patches, patch)
            end
        end
    end
    
    -- Adiciona patch de reordenação se necessário
    if hasReorder then
        table.insert(patches, 1, {
            type = VDom.PATCH_TYPES.REORDER,
            path = parentPath,
            moves = reorderMoves,
        })
    end
    
    return patches
end

--- Renderiza um VNode para string HTML
--- @param vnode table
--- @param indent number|nil Indentação (para formatação)
--- @return string
function VDom.render(vnode, indent)
    if not vnode then return "" end
    
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    
    -- Nó de texto
    if vnode.type == "#text" then
        return vnode.text or ""
    end
    
    -- Nó raw (HTML direto)
    if vnode.type == "#raw" then
        return vnode.html or ""
    end
    
    -- Componente funcional
    if type(vnode.type) == "function" then
        local result = vnode.type(vnode.props, vnode.children)
        if type(result) == "table" and result.type then
            return VDom.render(result, indent)
        end
        return tostring(result or "")
    end
    
    -- Elemento HTML
    local tag = vnode.type
    local propsStr = VDom.propsToString(vnode.props)
    local space = propsStr ~= "" and " " or ""
    
    -- Tags void (auto-fechadas)
    local VOID_TAGS = {
        area = true, base = true, br = true, col = true,
        embed = true, hr = true, img = true, input = true,
        link = true, meta = true, param = true, source = true,
        track = true, wbr = true,
    }
    
    if VOID_TAGS[tag] then
        return "<" .. tag .. space .. propsStr .. " />"
    end
    
    -- Renderiza filhos
    local childrenStr = ""
    for _, child in ipairs(vnode.children) do
        childrenStr = childrenStr .. VDom.render(child, indent + 1)
    end
    
    return "<" .. tag .. space .. propsStr .. ">" .. childrenStr .. "</" .. tag .. ">"
end

--- Converte props para string de atributos HTML
--- @param props table
--- @return string
function VDom.propsToString(props)
    if not props then return "" end
    
    local parts = {}
    
    for key, value in pairs(props) do
        -- Ignora props especiais
        if key ~= "key" and key ~= "ref" and key:sub(1, 1) ~= "_" then
            if value == true then
                table.insert(parts, key)
            elseif value and value ~= false then
                -- Escapa aspas
                local escaped = tostring(value):gsub('"', '&quot;')
                table.insert(parts, key .. '="' .. escaped .. '"')
            end
        end
    end
    
    -- Ordena para output consistente
    table.sort(parts)
    
    return table.concat(parts, " ")
end

--- Aplica patches e gera script JavaScript para atualização no cliente
--- @param patches table Lista de patches
--- @return string Script JavaScript
function VDom.generateUpdateScript(patches)
    if #patches == 0 then
        return "// No changes needed"
    end
    
    local scripts = {}
    table.insert(scripts, "(function() {")
    table.insert(scripts, "  'use strict';")
    
    for i, patch in ipairs(patches) do
        local patchScript = VDom.patchToScript(patch, i)
        table.insert(scripts, patchScript)
    end
    
    table.insert(scripts, "})();")
    
    return table.concat(scripts, "\n")
end

--- Converte um patch individual para JavaScript
--- @param patch table
--- @param index number
--- @return string
function VDom.patchToScript(patch, index)
    local ptype = patch.type
    local path = patch.path
    
    -- Converte path para seletor
    local selector = VDom.pathToSelector(path)
    
    if ptype == VDom.PATCH_TYPES.REPLACE then
        local newHtml = VDom.render(patch.newNode):gsub("'", "\\'"):gsub("\n", "\\n")
        return string.format([[
  // Patch %d: REPLACE at %s
  (function() {
    var el = %s;
    if (el) {
      var temp = document.createElement('div');
      temp.innerHTML = '%s';
      el.parentNode.replaceChild(temp.firstChild, el);
    }
  })();]], index, path, selector, newHtml)
  
    elseif ptype == VDom.PATCH_TYPES.TEXT then
        local newText = (patch.newText or ""):gsub("'", "\\'"):gsub("\n", "\\n")
        return string.format([[
  // Patch %d: TEXT at %s
  (function() {
    var el = %s;
    if (el) el.textContent = '%s';
  })();]], index, path, selector, newText)
  
    elseif ptype == VDom.PATCH_TYPES.PROPS then
        local propScripts = {}
        for propName, change in pairs(patch.changes) do
            if change.action == "remove" then
                table.insert(propScripts, string.format("el.removeAttribute('%s');", propName))
            elseif change.action == "add" or change.action == "update" then
                local value = tostring(change.value):gsub("'", "\\'")
                table.insert(propScripts, string.format("el.setAttribute('%s', '%s');", propName, value))
            end
        end
        return string.format([[
  // Patch %d: PROPS at %s
  (function() {
    var el = %s;
    if (el) {
      %s
    }
  })();]], index, path, selector, table.concat(propScripts, "\n      "))
  
    elseif ptype == VDom.PATCH_TYPES.INSERT then
        local newHtml = VDom.render(patch.node):gsub("'", "\\'"):gsub("\n", "\\n")
        return string.format([[
  // Patch %d: INSERT at %s
  (function() {
    var parent = %s;
    if (parent) {
      var temp = document.createElement('div');
      temp.innerHTML = '%s';
      parent.appendChild(temp.firstChild);
    }
  })();]], index, path, selector, newHtml)
  
    elseif ptype == VDom.PATCH_TYPES.REMOVE then
        return string.format([[
  // Patch %d: REMOVE at %s
  (function() {
    var el = %s;
    if (el && el.parentNode) el.parentNode.removeChild(el);
  })();]], index, path, selector)
  
    elseif ptype == VDom.PATCH_TYPES.REORDER then
        -- Reordenação é mais complexa
        return string.format("  // Patch %d: REORDER at %s (handled by full reconciliation)", index, path)
    end
    
    return string.format("  // Patch %d: Unknown type %s", index, ptype)
end

--- Converte path da árvore para seletor DOM
--- @param path string
--- @return string JavaScript selector
function VDom.pathToSelector(path)
    -- Path format: "root.children[1].children[2]"
    if path == "root" then
        return "document.body.firstElementChild"
    end
    
    -- Extrai índices do path
    local indices = {}
    for idx in path:gmatch("%[(%d+)%]") do
        table.insert(indices, tonumber(idx))
    end
    
    if #indices == 0 then
        return "document.body.firstElementChild"
    end
    
    -- Constrói seletor usando childNodes
    local parts = {"document.body.firstElementChild"}
    for _, idx in ipairs(indices) do
        table.insert(parts, string.format(".childNodes[%d]", idx - 1))
    end
    
    return table.concat(parts)
end

--[[
    Cache de árvores para comparação entre requisições
    
    Em um cenário server-side, o cache permite comparar
    a árvore atual com a anterior e gerar patches.
--]]

local treeCache = {}

--- Armazena árvore no cache
--- @param key string Identificador único (ex: URL da página)
--- @param tree table VNode tree
function VDom.cacheTree(key, tree)
    treeCache[key] = {
        tree = tree,
        timestamp = os.time(),
    }
end

--- Obtém árvore do cache
--- @param key string
--- @return table|nil VNode tree
function VDom.getCachedTree(key)
    local cached = treeCache[key]
    if cached then
        return cached.tree
    end
    return nil
end

--- Limpa cache antigo
--- @param maxAge number Idade máxima em segundos
function VDom.clearOldCache(maxAge)
    maxAge = maxAge or 3600 -- 1 hora por padrão
    local now = os.time()
    
    for key, cached in pairs(treeCache) do
        if now - cached.timestamp > maxAge then
            treeCache[key] = nil
        end
    end
end

--- Limpa todo o cache
function VDom.clearCache()
    treeCache = {}
end

--[[
    Utilitários para debug
--]]

--- Imprime árvore de forma legível
--- @param vnode table
--- @param indent number|nil
--- @return string
function VDom.inspect(vnode, indent)
    if not vnode then return "nil" end
    
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    
    if vnode.type == "#text" then
        return spacing .. '#text: "' .. (vnode.text or "") .. '"'
    end
    
    local lines = {}
    local propsStr = ""
    
    for k, v in pairs(vnode.props) do
        propsStr = propsStr .. string.format(" %s=%q", k, tostring(v))
    end
    
    table.insert(lines, spacing .. "<" .. vnode.type .. propsStr .. ">")
    
    for _, child in ipairs(vnode.children) do
        table.insert(lines, VDom.inspect(child, indent + 1))
    end
    
    if #vnode.children > 0 then
        table.insert(lines, spacing .. "</" .. vnode.type .. ">")
    end
    
    return table.concat(lines, "\n")
end

--- Conta total de nós na árvore
--- @param vnode table
--- @return number
function VDom.countNodes(vnode)
    if not vnode then return 0 end
    
    local count = 1
    for _, child in ipairs(vnode.children or {}) do
        count = count + VDom.countNodes(child)
    end
    return count
end

--- Serializa VNode para JSON (para envio ao cliente)
--- @param vnode table
--- @return string
function VDom.toJSON(vnode)
    local ok, json = pcall(require, "PudimWeb.utils.json")
    if not ok then
        if _G.log then
            _G.log.error(_G.log.section("PudimWeb.vdom"), "Erro ao carregar módulo JSON:", json)
        end
        return "{}"
    end
    
    local ok2, result = pcall(json.encode, vnode)
    if not ok2 then
        if _G.log then
            _G.log.error(_G.log.section("PudimWeb.vdom"), "Erro ao serializar VNode para JSON:", result)
        end
        return "{}"
    end
    
    return result
end

return VDom
