--[[
    Testes do Virtual DOM (VDom)
    ============================
    
    Testa o sistema de Virtual DOM com tree diffing.
    
    Executar: lua tests/vdom_test.lua
--]]

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

print("\n=== Testes do VDom ===\n")

-- Resetar contador de IDs para testes consistentes
vdom.resetIdCounter()

-- Teste: Criar VNode básico
test("Criar VNode básico", function()
    local node = vdom.h("div", { class = "container" }, "Hello")
    assertEquals("div", node.type)
    assertEquals("container", node.props.class)
    assertEquals(1, #node.children)
    assertEquals("#text", node.children[1].type)
    assertEquals("Hello", node.children[1].text)
end)

-- Teste: Criar VNode com múltiplos filhos
test("Criar VNode com múltiplos filhos", function()
    local node = vdom.h("ul", {}, {
        vdom.h("li", {}, "Item 1"),
        vdom.h("li", {}, "Item 2"),
        vdom.h("li", {}, "Item 3"),
    })
    assertEquals("ul", node.type)
    assertEquals(3, #node.children)
    assertEquals("li", node.children[1].type)
    assertEquals("li", node.children[2].type)
    assertEquals("li", node.children[3].type)
end)

-- Teste: Criar TextNode
test("Criar TextNode", function()
    local node = vdom.createTextNode("Hello World")
    assertEquals("#text", node.type)
    assertEquals("Hello World", node.text)
end)

-- Teste: Renderizar VNode simples
test("Renderizar VNode simples", function()
    local node = vdom.h("div", { class = "test" }, "Content")
    local html = vdom.render(node)
    assertEquals('<div class="test">Content</div>', html)
end)

-- Teste: Renderizar VNode com filhos
test("Renderizar VNode com filhos", function()
    local node = vdom.h("div", {}, {
        vdom.h("h1", {}, "Title"),
        vdom.h("p", {}, "Paragraph"),
    })
    local html = vdom.render(node)
    assertEquals("<div><h1>Title</h1><p>Paragraph</p></div>", html)
end)

-- Teste: Renderizar tag void
test("Renderizar tag void (img)", function()
    local node = vdom.h("img", { src = "test.jpg", alt = "Test" })
    local html = vdom.render(node)
    -- Props são ordenadas alfabeticamente
    assertEquals('<img alt="Test" src="test.jpg" />', html)
end)

-- Teste: Diff - Sem mudanças
test("Diff - Sem mudanças", function()
    local tree1 = vdom.h("div", { class = "same" }, "Same content")
    local tree2 = vdom.h("div", { class = "same" }, "Same content")
    local patches = vdom.diff(tree1, tree2)
    assertEquals(0, #patches)
end)

-- Teste: Diff - Mudança de texto
test("Diff - Mudança de texto", function()
    local tree1 = vdom.h("p", {}, "Old text")
    local tree2 = vdom.h("p", {}, "New text")
    local patches = vdom.diff(tree1, tree2)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.TEXT, patches[1].type)
    assertEquals("Old text", patches[1].oldText)
    assertEquals("New text", patches[1].newText)
end)

-- Teste: Diff - Mudança de props
test("Diff - Mudança de props", function()
    local tree1 = vdom.h("div", { class = "old" })
    local tree2 = vdom.h("div", { class = "new" })
    local patches = vdom.diff(tree1, tree2)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.PROPS, patches[1].type)
    assertNotNil(patches[1].changes.class)
    assertEquals("update", patches[1].changes.class.action)
    assertEquals("new", patches[1].changes.class.value)
end)

-- Teste: Diff - Adicionar prop
test("Diff - Adicionar prop", function()
    local tree1 = vdom.h("div", {})
    local tree2 = vdom.h("div", { id = "newId" })
    local patches = vdom.diff(tree1, tree2)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.PROPS, patches[1].type)
    assertEquals("add", patches[1].changes.id.action)
end)

-- Teste: Diff - Remover prop
test("Diff - Remover prop", function()
    local tree1 = vdom.h("div", { id = "oldId" })
    local tree2 = vdom.h("div", {})
    local patches = vdom.diff(tree1, tree2)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.PROPS, patches[1].type)
    assertEquals("remove", patches[1].changes.id.action)
end)

-- Teste: Diff - Substituir tipo de elemento
test("Diff - Substituir tipo de elemento", function()
    local tree1 = vdom.h("div", {}, "Content")
    local tree2 = vdom.h("span", {}, "Content")
    local patches = vdom.diff(tree1, tree2)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.REPLACE, patches[1].type)
end)

-- Teste: Diff - Inserir filho
test("Diff - Inserir filho", function()
    local tree1 = vdom.h("ul", {}, {
        vdom.h("li", {}, "Item 1"),
    })
    local tree2 = vdom.h("ul", {}, {
        vdom.h("li", {}, "Item 1"),
        vdom.h("li", {}, "Item 2"),
    })
    local patches = vdom.diff(tree1, tree2)
    local hasInsert = false
    for _, p in ipairs(patches) do
        if p.type == vdom.PATCH_TYPES.INSERT then
            hasInsert = true
            break
        end
    end
    assertEquals(true, hasInsert)
end)

-- Teste: Diff - Remover filho
test("Diff - Remover filho", function()
    local tree1 = vdom.h("ul", {}, {
        vdom.h("li", {}, "Item 1"),
        vdom.h("li", {}, "Item 2"),
    })
    local tree2 = vdom.h("ul", {}, {
        vdom.h("li", {}, "Item 1"),
    })
    local patches = vdom.diff(tree1, tree2)
    local hasRemove = false
    for _, p in ipairs(patches) do
        if p.type == vdom.PATCH_TYPES.REMOVE then
            hasRemove = true
            break
        end
    end
    assertEquals(true, hasRemove)
end)

-- Teste: Diff - Nó inserido (oldTree nil)
test("Diff - Nó inserido (oldTree nil)", function()
    local tree2 = vdom.h("div", {}, "New")
    local patches = vdom.diff(nil, tree2)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.INSERT, patches[1].type)
end)

-- Teste: Diff - Nó removido (newTree nil)
test("Diff - Nó removido (newTree nil)", function()
    local tree1 = vdom.h("div", {}, "Old")
    local patches = vdom.diff(tree1, nil)
    assertEquals(1, #patches)
    assertEquals(vdom.PATCH_TYPES.REMOVE, patches[1].type)
end)

-- Teste: isSameType
test("isSameType - Mesmo tipo", function()
    local node1 = vdom.h("div", {})
    local node2 = vdom.h("div", {})
    assertEquals(true, vdom.isSameType(node1, node2))
end)

-- Teste: isSameType - Tipos diferentes
test("isSameType - Tipos diferentes", function()
    local node1 = vdom.h("div", {})
    local node2 = vdom.h("span", {})
    assertEquals(false, vdom.isSameType(node1, node2))
end)

-- Teste: isSameType com keys
test("isSameType com keys iguais", function()
    local node1 = vdom.h("li", { key = "item-1" }, "Item")
    local node2 = vdom.h("li", { key = "item-1" }, "Item Updated")
    assertEquals(true, vdom.isSameType(node1, node2))
end)

-- Teste: isSameType com keys diferentes
test("isSameType com keys diferentes", function()
    local node1 = vdom.h("li", { key = "item-1" }, "Item")
    local node2 = vdom.h("li", { key = "item-2" }, "Item")
    assertEquals(false, vdom.isSameType(node1, node2))
end)

-- Teste: countNodes
test("countNodes", function()
    local tree = vdom.h("div", {}, {
        vdom.h("h1", {}, "Title"),
        vdom.h("ul", {}, {
            vdom.h("li", {}, "1"),
            vdom.h("li", {}, "2"),
        }),
    })
    -- div + h1 + text + ul + li + text + li + text = 8
    assertEquals(8, vdom.countNodes(tree))
end)

-- Teste: Cache de árvores
test("Cache de árvores", function()
    local tree = vdom.h("div", {}, "Cached")
    vdom.cacheTree("test-key", tree)
    local cached = vdom.getCachedTree("test-key")
    assertNotNil(cached)
    assertEquals("div", cached.type)
    vdom.clearCache()
    assertEquals(nil, vdom.getCachedTree("test-key"))
end)

-- Teste: generateUpdateScript
test("generateUpdateScript - Sem patches", function()
    local script = vdom.generateUpdateScript({})
    assertEquals("// No changes needed", script)
end)

-- Teste: generateUpdateScript - Com patches
test("generateUpdateScript - Com patches", function()
    local patches = {
        {
            type = vdom.PATCH_TYPES.TEXT,
            path = "root.children[1]",
            oldText = "Old",
            newText = "New",
        }
    }
    local script = vdom.generateUpdateScript(patches)
    assertNotNil(script:find("textContent"))
    assertNotNil(script:find("New"))
end)

-- Teste: inspect
test("inspect - Debug tree", function()
    local tree = vdom.h("div", { class = "test" }, "Hello")
    local output = vdom.inspect(tree)
    assertNotNil(output:find("div"))
    assertNotNil(output:find("class"))
    assertNotNil(output:find("Hello"))
end)

-- Resumo
print(string.format("\n=== Resultado: %d passaram, %d falharam ===\n", passed, failed))

if failed > 0 then
    os.exit(1)
end
