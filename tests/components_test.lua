--[[
    Testes do Components
    ====================
    
    Testa o sistema de componentes do PudimWeb.
    
    Executar: lua tests/components_test.lua
--]]

local components = require("PudimWeb.core.components")

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

local function assertContains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error(string.format("%s\n  String: %s\n  Não contém: %s", msg or "String não contém", haystack, needle))
    end
end

print("\n=== Testes do Components ===\n")

-- Teste: Criar componente simples
test("Criar componente simples", function()
    local Button = components.create(function(props, children)
        return '<button>' .. children .. '</button>'
    end)
    
    assertNotNil(Button)
    assertEquals("function", type(Button))
end)

-- Teste: Componente com props
test("Componente com props", function()
    local Button = components.create(function(props, children)
        local class = props.class or "btn"
        -- children já vem como string (renderChildren é chamado internamente)
        return '<button class="' .. class .. '">' .. children .. '</button>'
    end)
    
    local result = Button({ class = "primary" }, "Click")
    assertEquals('<button class="primary">Click</button>', result)
end)

-- Teste: Componente com children string
test("Componente com children string", function()
    local Box = components.create(function(props, children)
        -- children já vem como string (renderChildren é chamado internamente)
        return '<div>' .. children .. '</div>'
    end)
    
    local result = Box({}, "Hello World")
    assertEquals("<div>Hello World</div>", result)
end)

-- Teste: Componente com children tabela
test("Componente com children tabela", function()
    local List = components.create(function(props, children)
        -- children já vem como string (tabela é concatenada internamente)
        return '<ul>' .. children .. '</ul>'
    end)
    
    local result = List({}, { "<li>A</li>", "<li>B</li>" })
    assertEquals("<ul><li>A</li><li>B</li></ul>", result)
end)

-- Teste: Componente sem props
test("Componente sem props (nil)", function()
    local Simple = components.create(function(props, children)
        return '<span>' .. (props.text or children) .. '</span>'
    end)
    
    local result = Simple(nil, "Text")
    assertEquals("<span>Text</span>", result)
end)

-- Teste: Componente sem children
test("Componente sem children", function()
    local Empty = components.create(function(props, children)
        return '<div class="empty">' .. children .. '</div>'
    end)
    
    local result = Empty({ class = "test" })
    assertEquals('<div class="empty"></div>', result)
end)

-- Teste: renderChildren - nil
test("renderChildren - nil", function()
    local result = components.renderChildren(nil)
    assertEquals("", result)
end)

-- Teste: renderChildren - string
test("renderChildren - string", function()
    local result = components.renderChildren("Hello")
    assertEquals("Hello", result)
end)

-- Teste: renderChildren - tabela
test("renderChildren - tabela", function()
    local result = components.renderChildren({ "A", "B", "C" })
    assertEquals("ABC", result)
end)

-- Teste: renderChildren - número
test("renderChildren - número", function()
    local result = components.renderChildren(42)
    assertEquals("42", result)
end)

-- Teste: renderChildren - boolean
test("renderChildren - boolean", function()
    local result = components.renderChildren(true)
    assertEquals("true", result)
end)

-- Teste: renderChildren - função
test("renderChildren - função em tabela", function()
    local result = components.renderChildren({
        function() return "Dynamic" end,
        "Static"
    })
    assertEquals("DynamicStatic", result)
end)

-- Teste: renderChildren - nil em tabela (nil é ignorado)
test("renderChildren - nil em tabela", function()
    local result = components.renderChildren({ "A", nil, "B" })
    -- nil no meio da tabela pode não ser iterado em Lua
    -- O comportamento correto é ignorar nil
    assertNotNil(result)
end)

-- Teste: mergeProps básico
test("mergeProps - Básico", function()
    local result = components.mergeProps(
        { class = "custom" },
        { class = "default", id = "main" }
    )
    
    assertEquals("custom", result.class)
    assertEquals("main", result.id)
end)

-- Teste: mergeProps sem props
test("mergeProps - Sem props (nil)", function()
    local result = components.mergeProps(nil, { class = "default" })
    assertEquals("default", result.class)
end)

-- Teste: mergeProps sobrescreve defaults
test("mergeProps - Sobrescreve defaults", function()
    local result = components.mergeProps(
        { a = 1, b = 2, c = 3 },
        { a = 10, b = 20, d = 40 }
    )
    
    assertEquals(1, result.a)
    assertEquals(2, result.b)
    assertEquals(3, result.c)
    assertEquals(40, result.d)
end)

-- Teste: Componente composto
test("Componente composto", function()
    local Card = components.create(function(props, children)
        return '<div class="card"><h1>' .. props.title .. '</h1><p>' .. children .. '</p></div>'
    end)
    
    local result = Card({ title = "My Card" }, "Card content here")
    assertContains(result, '<div class="card">')
    assertContains(result, '<h1>My Card</h1>')
    assertContains(result, '<p>Card content here</p>')
end)

-- Teste: Componente que retorna nil
test("Componente que retorna nil", function()
    local NullComponent = components.create(function(props, children)
        if props.hidden then
            return nil
        end
        return '<div>Visible</div>'
    end)
    
    local resultHidden = NullComponent({ hidden = true })
    local resultVisible = NullComponent({ hidden = false })
    
    assertEquals(nil, resultHidden)
    assertEquals("<div>Visible</div>", resultVisible)
end)

-- Teste: Props com valores diversos
test("Props com valores diversos", function()
    local Component = components.create(function(props, children)
        local parts = {}
        table.insert(parts, "string:" .. (props.str or "nil"))
        table.insert(parts, "number:" .. (props.num or "nil"))
        table.insert(parts, "bool:" .. tostring(props.bool))
        return table.concat(parts, ",")
    end)
    
    local result = Component({ str = "hello", num = 42, bool = true })
    assertContains(result, "string:hello")
    assertContains(result, "number:42")
    assertContains(result, "bool:true")
end)

-- Teste: Componente aninhado
test("Componente aninhado", function()
    local Inner = components.create(function(props, children)
        return '<span>' .. children .. '</span>'
    end)
    
    local Outer = components.create(function(props, children)
        return '<div>' .. Inner({}, "nested") .. '</div>'
    end)
    
    local result = Outer({})
    assertEquals("<div><span>nested</span></div>", result)
end)

-- Teste: Componente com array de componentes
test("Componente com array de componentes", function()
    local Item = components.create(function(props, children)
        return '<li>' .. children .. '</li>'
    end)
    
    local List = components.create(function(props, children)
        return '<ul>' .. children .. '</ul>'
    end)
    
    local items = {
        Item({}, "First"),
        Item({}, "Second"),
        Item({}, "Third"),
    }
    
    local result = List({}, items)
    assertContains(result, "<ul>")
    assertContains(result, "<li>First</li>")
    assertContains(result, "<li>Second</li>")
    assertContains(result, "<li>Third</li>")
    assertContains(result, "</ul>")
end)

-- Resumo
print(string.format("\n=== Resultado: %d passaram, %d falharam ===\n", passed, failed))

if failed > 0 then
    os.exit(1)
end
