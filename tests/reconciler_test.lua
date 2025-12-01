--[[
    Testes do Reconciler
    ====================
    
    Testa o sistema de reconciliação de componentes.
    
    Executar: lua tests/reconciler_test.lua
--]]

local reconciler = require("PudimWeb.core.reconciler")
local vdom = require("PudimWeb.core.vdom")

local passed = 0
local failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("✓ " .. name)
        passed = passed + 1
    else
        print("✗ " .. name)
        print("  Erro: " .. tostring(err))
        failed = failed + 1
    end
end

local function assertEquals(expected, actual, msg)
    if expected ~= actual then
        error(string.format("%s\n  Esperado: %s\n  Obtido: %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assertNotNil(value, msg)
    if value == nil then
        error(msg or "Value is nil")
    end
end

local function assertTrue(value, msg)
    if not value then
        error(msg or "Expected true")
    end
end

local function assertFalse(value, msg)
    if value then
        error(msg or "Expected false")
    end
end

print("\n=== Testes do Reconciler ===\n")

-- Componente de teste simples
local function SimpleComponent(props)
    return vdom.h("div", { class = "simple" }, props.text or "Default")
end

-- Componente com filhos
local function ComplexComponent(props)
    return vdom.h("div", { class = "complex" }, {
        vdom.h("h1", {}, props.title or "Title"),
        vdom.h("p", {}, props.content or "Content"),
        vdom.h("span", { class = "counter" }, "Count: " .. (props.count or 0)),
    })
end

-- Teste: createRoot
test("createRoot - Cria instância Root", function()
    local root = reconciler.createRoot(SimpleComponent)
    assertNotNil(root)
    assertNotNil(root.render)
    assertNotNil(root.update)
end)

-- Teste: Primeira renderização
test("Primeira renderização", function()
    local root = reconciler.createRoot(SimpleComponent)
    local html = root:render({ text = "Hello World" })
    assertNotNil(html)
    assertNotNil(html:find("Hello World"))
    assertNotNil(html:find("simple"))
end)

-- Teste: getHTML após renderização
test("getHTML após renderização", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Test" })
    local html = root:getHTML()
    assertEquals('<div class="simple">Test</div>', html)
end)

-- Teste: hasChanges na primeira renderização
test("hasChanges - Primeira renderização", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Test" })
    -- Na primeira renderização, não há patches (não há árvore anterior)
    assertFalse(root:hasChanges())
end)

-- Teste: update sem mudanças
test("update - Sem mudanças", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Same" })
    local patches = root:update({ text = "Same" })
    assertEquals(0, #patches)
    assertFalse(root:hasChanges())
end)

-- Teste: update com mudanças
test("update - Com mudanças", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Old" })
    local patches = root:update({ text = "New" })
    assertTrue(#patches > 0)
    assertTrue(root:hasChanges())
end)

-- Teste: getChangeCount
test("getChangeCount", function()
    local root = reconciler.createRoot(ComplexComponent)
    root:render({ title = "T1", content = "C1", count = 0 })
    root:update({ title = "T2", content = "C2", count = 0 })
    -- Deve ter 2 mudanças (title e content)
    assertEquals(2, root:getChangeCount())
end)

-- Teste: getUpdateScript
test("getUpdateScript - Gera JavaScript", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Old" })
    root:update({ text = "New" })
    local script = root:getUpdateScript()
    assertNotNil(script)
    assertNotNil(script:find("function"))
    assertNotNil(script:find("New"))
end)

-- Teste: getPatches
test("getPatches", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Old" })
    root:update({ text = "New" })
    local patches = root:getPatches()
    assertTrue(#patches > 0)
    assertEquals(vdom.PATCH_TYPES.TEXT, patches[1].type)
end)

-- Teste: getTree
test("getTree - Retorna árvore atual", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Test" })
    local tree = root:getTree()
    assertNotNil(tree)
    assertEquals("div", tree.type)
end)

-- Teste: inspect
test("inspect - Debug da árvore", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Debug" })
    local output = root:inspect()
    assertNotNil(output)
    assertNotNil(output:find("div"))
end)

-- Teste: reset
test("reset - Limpa estado", function()
    local root = reconciler.createRoot(SimpleComponent)
    root:render({ text = "Test" })
    root:reset()
    assertEquals(nil, root:getTree())
    assertTrue(root.isFirstRender)
end)

-- Teste: Múltiplas atualizações
test("Múltiplas atualizações sequenciais", function()
    local root = reconciler.createRoot(ComplexComponent)
    root:render({ title = "V1", content = "C1", count = 0 })
    
    -- Atualização 1
    root:update({ title = "V2", content = "C1", count = 0 })
    assertEquals(1, root:getChangeCount()) -- só title mudou
    
    -- Atualização 2
    root:update({ title = "V2", content = "C2", count = 1 })
    assertEquals(2, root:getChangeCount()) -- content e count mudaram
    
    -- Atualização 3 - sem mudanças
    root:update({ title = "V2", content = "C2", count = 1 })
    assertEquals(0, root:getChangeCount())
end)

-- Teste: createElement
test("createElement - Cria VNode", function()
    local node = reconciler.createElement("div", { class = "test" }, "Hello")
    assertEquals("div", node.type)
    assertEquals("test", node.props.class)
end)

-- Teste: createElement com múltiplos filhos
test("createElement com múltiplos filhos", function()
    local node = reconciler.createElement("ul", {},
        reconciler.el("li", {}, "Item 1"),
        reconciler.el("li", {}, "Item 2")
    )
    assertEquals("ul", node.type)
    assertEquals(2, #node.children)
end)

-- Teste: el (alias)
test("el - Alias para createElement", function()
    local node = reconciler.el("span", { id = "test" }, "Content")
    assertEquals("span", node.type)
    assertEquals("test", node.props.id)
end)

-- Teste: getPageRoot
test("getPageRoot - Cria e obtém raiz de página", function()
    reconciler.clearAll()
    
    local root1 = reconciler.getPageRoot("/home", SimpleComponent)
    assertNotNil(root1)
    
    local root2 = reconciler.getPageRoot("/home", nil)
    assertEquals(root1, root2) -- Mesma instância
end)

-- Teste: removePageRoot
test("removePageRoot", function()
    reconciler.clearAll()
    
    reconciler.getPageRoot("/test", SimpleComponent)
    reconciler.removePageRoot("/test")
    
    local pages = reconciler.listPages()
    for _, page in ipairs(pages) do
        assertFalse(page == "/test")
    end
end)

-- Teste: listPages
test("listPages", function()
    reconciler.clearAll()
    
    reconciler.getPageRoot("/page1", SimpleComponent)
    reconciler.getPageRoot("/page2", SimpleComponent)
    
    local pages = reconciler.listPages()
    assertEquals(2, #pages)
end)

-- Teste: clearAll
test("clearAll - Limpa todas as raízes", function()
    reconciler.getPageRoot("/a", SimpleComponent)
    reconciler.getPageRoot("/b", SimpleComponent)
    
    reconciler.clearAll()
    
    local pages = reconciler.listPages()
    assertEquals(0, #pages)
end)

-- Teste: withReconciliation HOC
test("withReconciliation - HOC", function()
    local WrappedComponent = reconciler.withReconciliation(SimpleComponent)
    
    -- Primeira chamada
    local html1 = WrappedComponent({ text = "First" })
    assertNotNil(html1:find("First"))
    
    -- Segunda chamada com mudança
    local html2 = WrappedComponent({ text = "Second" })
    assertNotNil(html2)
end)

-- Teste: Componente que retorna string
test("Componente que retorna string", function()
    local StringComponent = function(props)
        return "Just a string: " .. (props.value or "")
    end
    
    local root = reconciler.createRoot(StringComponent)
    local html = root:render({ value = "test" })
    assertEquals("Just a string: test", html)
end)

-- Teste: Componente complexo com mudanças parciais
test("Componente complexo - Mudanças parciais detectadas", function()
    local function ListComponent(props)
        local items = {}
        for i, item in ipairs(props.items or {}) do
            table.insert(items, vdom.h("li", { key = "item-" .. i }, item))
        end
        return vdom.h("ul", { class = props.class or "list" }, items)
    end
    
    local root = reconciler.createRoot(ListComponent)
    root:render({ items = { "A", "B", "C" }, class = "my-list" })
    
    -- Mudar apenas um item
    local patches = root:update({ items = { "A", "B", "D" }, class = "my-list" })
    
    -- Deve detectar mudança apenas no terceiro item
    assertTrue(#patches > 0)
end)

-- Resumo
print(string.format("\n=== Resultado: %d passaram, %d falharam ===\n", passed, failed))

if failed > 0 then
    os.exit(1)
end
