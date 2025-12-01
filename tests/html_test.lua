--[[
    Testes do HTML
    ==============
    
    Testa o gerador de tags HTML do PudimWeb.
    
    Executar: lua tests/html_test.lua
--]]

local html = require("PudimWeb.html")

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

print("\n=== Testes do HTML ===\n")

-- Teste: Doctype
test("Doctype", function()
    assertEquals("<!DOCTYPE html>", html.doctype)
end)

-- Teste: Tag div simples
test("Tag div simples", function()
    local result = html.div({}, "Hello")
    assertEquals("<div>Hello</div>", result)
end)

-- Teste: Tag div com classe
test("Tag div com classe", function()
    local result = html.div({ class = "container" }, "Content")
    assertEquals('<div class="container">Content</div>', result)
end)

-- Teste: Tag div com múltiplos atributos
test("Tag div com múltiplos atributos", function()
    local result = html.div({ id = "main", class = "wrapper" }, "Text")
    assertContains(result, 'id="main"')
    assertContains(result, 'class="wrapper"')
    assertContains(result, ">Text</div>")
end)

-- Teste: Tag span
test("Tag span", function()
    local result = html.span({}, "inline")
    assertEquals("<span>inline</span>", result)
end)

-- Teste: Tag p (parágrafo)
test("Tag p", function()
    local result = html.p({ class = "text" }, "Paragraph")
    assertEquals('<p class="text">Paragraph</p>', result)
end)

-- Teste: Headings h1-h6
test("Headings h1-h6", function()
    assertEquals("<h1>Title</h1>", html.h1({}, "Title"))
    assertEquals("<h2>Subtitle</h2>", html.h2({}, "Subtitle"))
    assertEquals("<h3>Section</h3>", html.h3({}, "Section"))
    assertEquals("<h4>Sub</h4>", html.h4({}, "Sub"))
    assertEquals("<h5>Minor</h5>", html.h5({}, "Minor"))
    assertEquals("<h6>Small</h6>", html.h6({}, "Small"))
end)

-- Teste: Tag a (link)
test("Tag a (link)", function()
    local result = html.a({ href = "https://example.com" }, "Link")
    assertEquals('<a href="https://example.com">Link</a>', result)
end)

-- Teste: Tag img (void/self-closing)
test("Tag img (void)", function()
    local result = html.img({ src = "photo.jpg", alt = "Photo" })
    assertContains(result, '<img')
    assertContains(result, 'src="photo.jpg"')
    assertContains(result, 'alt="Photo"')
    assertContains(result, '/>')
end)

-- Teste: Tag input (void)
test("Tag input (void)", function()
    local result = html.input({ type = "text", name = "username" })
    assertContains(result, '<input')
    assertContains(result, 'type="text"')
    assertContains(result, 'name="username"')
    assertContains(result, '/>')
end)

-- Teste: Tag br (void)
test("Tag br (void)", function()
    local result = html.br({})
    assertEquals("<br />", result)
end)

-- Teste: Tag hr (void)
test("Tag hr (void)", function()
    local result = html.hr({})
    assertEquals("<hr />", result)
end)

-- Teste: Tag meta (void)
test("Tag meta (void)", function()
    local result = html.meta({ charset = "UTF-8" })
    assertContains(result, '<meta')
    assertContains(result, 'charset="UTF-8"')
    assertContains(result, '/>')
end)

-- Teste: Tag link (void)
test("Tag link (void)", function()
    local result = html.link({ rel = "stylesheet", href = "style.css" })
    assertContains(result, '<link')
    assertContains(result, 'rel="stylesheet"')
    assertContains(result, '/>')
end)

-- Teste: Children como tabela
test("Children como tabela", function()
    local result = html.ul({}, {
        html.li({}, "Item 1"),
        html.li({}, "Item 2"),
        html.li({}, "Item 3"),
    })
    assertEquals("<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>", result)
end)

-- Teste: Aninhamento profundo
test("Aninhamento profundo", function()
    local result = html.div({ class = "outer" }, {
        html.div({ class = "inner" }, {
            html.p({}, "Deep text")
        })
    })
    assertEquals('<div class="outer"><div class="inner"><p>Deep text</p></div></div>', result)
end)

-- Teste: Atributo booleano true
test("Atributo booleano true", function()
    local result = html.input({ type = "checkbox", checked = true })
    assertContains(result, "checked")
end)

-- Teste: Atributo booleano false (não deve aparecer)
test("Atributo booleano false", function()
    local result = html.input({ type = "checkbox", checked = false })
    local hasChecked = result:find("checked", 1, true) ~= nil
    assertEquals(false, hasChecked)
end)

-- Teste: Sem props
test("Sem props (nil)", function()
    local result = html.div(nil, "Content")
    assertEquals("<div>Content</div>", result)
end)

-- Teste: Sem children
test("Sem children", function()
    local result = html.div({ class = "empty" })
    assertEquals('<div class="empty"></div>', result)
end)

-- Teste: Fragment
test("Fragment", function()
    local result = html.fragment({
        html.span({}, "A"),
        html.span({}, "B"),
    })
    assertEquals("<span>A</span><span>B</span>", result)
end)

-- Teste: Fragment vazio
test("Fragment vazio", function()
    local result = html.fragment({})
    assertEquals("", result)
end)

-- Teste: text (escape)
test("text - Escapa HTML", function()
    local result = html.text("<script>alert('xss')</script>")
    assertContains(result, "&lt;script&gt;")
    assertContains(result, "&lt;/script&gt;")
end)

-- Teste: raw (sem escape)
test("raw - Sem escape", function()
    local result = html.raw("<strong>Bold</strong>")
    assertEquals("<strong>Bold</strong>", result)
end)

-- Teste: Escape de aspas em atributos
test("Escape de aspas em atributos", function()
    local result = html.div({ title = 'Test "quoted"' }, "Content")
    assertContains(result, '&quot;')
end)

-- Teste: Tag customizada
test("Tag customizada", function()
    local customTag = html.tag("custom-element")
    local result = customTag({ class = "my-class" }, "Custom content")
    assertEquals('<custom-element class="my-class">Custom content</custom-element>', result)
end)

-- Teste: Tabelas e formulários
test("Tag table", function()
    local result = html.table({ class = "data" }, {
        html.tr({}, {
            html.th({}, "Header 1"),
            html.th({}, "Header 2"),
        }),
        html.tr({}, {
            html.td({}, "Cell 1"),
            html.td({}, "Cell 2"),
        }),
    })
    assertContains(result, "<table")
    assertContains(result, "<tr>")
    assertContains(result, "<th>")
    assertContains(result, "<td>")
end)

-- Teste: Form
test("Tag form", function()
    local result = html.form({ action = "/submit", method = "POST" }, {
        html.label({}, "Name:"),
        html.input({ type = "text", name = "name" }),
        html.button({ type = "submit" }, "Submit"),
    })
    assertContains(result, '<form')
    assertContains(result, 'action="/submit"')
    assertContains(result, 'method="POST"')
    assertContains(result, '<label>')
    assertContains(result, '<input')
    assertContains(result, '<button')
end)

-- Teste: Número como children
test("Número como children", function()
    local result = html.span({}, 42)
    assertEquals("<span>42</span>", result)
end)

-- Teste: Tags semânticas HTML5
test("Tags semânticas HTML5", function()
    assertNotNil(html.header)
    assertNotNil(html.nav)
    assertNotNil(html.main)
    assertNotNil(html.section)
    assertNotNil(html.article)
    assertNotNil(html.aside)
    assertNotNil(html.footer)
    
    local result = html.header({}, html.nav({}, "Navigation"))
    assertContains(result, "<header>")
    assertContains(result, "<nav>")
end)

-- Teste: Script e style
test("Script e style tags", function()
    local script = html.script({ src = "app.js" })
    assertContains(script, "<script")
    assertContains(script, 'src="app.js"')
    assertContains(script, "</script>")
    
    local style = html.style({}, "body { color: red; }")
    assertEquals("<style>body { color: red; }</style>", style)
end)

-- Resumo
print(string.format("\n=== Resultado: %d passaram, %d falharam ===\n", passed, failed))

if failed > 0 then
    os.exit(1)
end
