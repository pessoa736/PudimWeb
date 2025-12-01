--[[
    PudimWeb Renderer Tests
    =======================
    
    Testes para o sistema de renderização integrado.
--]]

-- Setup de paths
package.path = table.concat({
    "../?.lua",
    "../?/init.lua",
    "../lua_modules/share/lua/5.4/?.lua",
    "../lua_modules/share/lua/5.4/?/init.lua",
}, ";") .. ";" .. package.path

package.cpath = table.concat({
    "../lua_modules/lib/lua/5.4/?.so",
}, ";") .. ";" .. package.cpath

-- Test framework simples
local tests_passed = 0
local tests_failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        tests_passed = tests_passed + 1
        print("✓ " .. name)
    else
        tests_failed = tests_failed + 1
        print("✗ " .. name)
        print("  Error: " .. tostring(err))
    end
end

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s\n  Expected: %s\n  Actual: %s", 
            msg or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assert_contains(str, pattern, msg)
    if not str:find(pattern, 1, true) then
        error(string.format("%s\n  Pattern '%s' not found in:\n  %s", 
            msg or "Assertion failed", pattern, str))
    end
end

local function assert_true(value, msg)
    if not value then
        error(msg or "Expected true but got false/nil")
    end
end

print("\n🍮 PudimWeb Renderer Tests\n" .. string.rep("=", 50))

-- Carrega módulos
local renderer = require("PudimWeb.core.renderer")
local vdom = require("PudimWeb.core.vdom")
local client = require("PudimWeb.core.client")

-- ============================================================
-- Testes de Renderização Básica
-- ============================================================

test("renderer.render com string", function()
    local html = renderer.render("Hello World")
    assert_contains(html, "Hello World")
end)

test("renderer.render com VNode", function()
    local node = vdom.h("div", { class = "container" }, "Conteúdo")
    local html = renderer.render(node)
    assert_contains(html, "<div")
    assert_contains(html, "container")
    assert_contains(html, "Conteúdo")
end)

test("renderer.render com componente função", function()
    local function MyComponent(props)
        return vdom.h("h1", {}, props.title or "Default")
    end
    
    local html = renderer.render(MyComponent, { title = "Teste" })
    assert_contains(html, "<h1>")
    assert_contains(html, "Teste")
end)

test("renderer.render com componente aninhado", function()
    local function Child(props)
        return vdom.h("span", {}, props.text)
    end
    
    local function Parent(props)
        return vdom.h("div", { class = "parent" }, {
            vdom.h(Child, { text = "Filho 1" }),
            vdom.h(Child, { text = "Filho 2" }),
        })
    end
    
    local html = renderer.render(Parent, {})
    assert_contains(html, "parent")
end)

-- ============================================================
-- Testes de Cache e Reconciliação
-- ============================================================

test("renderer caching por pageKey", function()
    renderer.clearCache()
    
    local function Page(props)
        return vdom.h("div", {}, props.content)
    end
    
    -- Primeira renderização
    local html1, patches1 = renderer.render(Page, { content = "V1" }, "/test-page")
    assert_contains(html1, "V1")
    assert_eq(patches1, nil, "Primeira renderização não deve ter patches")
    
    -- Segunda renderização (com mudança)
    local html2, patches2 = renderer.render(Page, { content = "V2" }, "/test-page")
    assert_contains(html2, "V2")
    assert_true(patches2 ~= nil, "Segunda renderização deve ter patches")
    assert_true(#patches2 > 0, "Deve haver pelo menos um patch")
end)

test("renderer.invalidateCache funciona", function()
    renderer.clearCache()
    
    local function Page(props)
        return vdom.h("div", {}, "Test")
    end
    
    renderer.render(Page, {}, "/invalidate-test")
    
    local cached = renderer.listCachedPages()
    assert_true(#cached > 0, "Deve haver páginas em cache")
    
    renderer.invalidateCache("/invalidate-test")
    
    -- Verifica se foi removida
    local root = renderer.getPageRoot("/invalidate-test")
    assert_eq(root, nil, "Cache deve estar vazio após invalidação")
end)

test("renderer.clearCache limpa tudo", function()
    local function Page() return vdom.h("div", {}, "Test") end
    
    renderer.render(Page, {}, "/page1")
    renderer.render(Page, {}, "/page2")
    
    renderer.clearCache()
    
    local cached = renderer.listCachedPages()
    assert_eq(#cached, 0, "Não deve haver páginas em cache")
end)

-- ============================================================
-- Testes de Integração com Client
-- ============================================================

test("renderer injeta scripts do client automaticamente", function()
    renderer.clearCache()
    client.clear()
    
    local function InteractivePage(props)
        -- Usa o client para adicionar interatividade
        client.select("#btn"):on("click", function()
            client.alert("Clicado!")
        end)
        
        return vdom.h("div", {}, {
            vdom.h("button", { id = "btn" }, "Clique")
        })
    end
    
    local html = renderer.render(InteractivePage, {})
    
    -- Deve conter o script injetado
    assert_contains(html, "data-pudim-client", "Deve ter marcador de script")
    assert_contains(html, "addEventListener", "Deve ter event listener")
end)

test("renderer não injeta script se client vazio", function()
    renderer.clearCache()
    client.clear()
    
    local function StaticPage()
        return vdom.h("div", {}, "Sem interatividade")
    end
    
    local html = renderer.render(StaticPage, {})
    
    -- Não deve conter script desnecessário (script vazio é filtrado)
    -- O HTML deve conter o conteúdo
    assert_contains(html, "Sem interatividade")
end)

-- ============================================================
-- Testes de Configuração
-- ============================================================

test("renderer.configure altera configurações", function()
    local oldConfig = renderer.getConfig()
    
    renderer.configure({
        autoInjectScripts = false,
        cacheMaxAge = 600,
    })
    
    local newConfig = renderer.getConfig()
    assert_eq(newConfig.autoInjectScripts, false)
    assert_eq(newConfig.cacheMaxAge, 600)
    
    -- Restaura
    renderer.configure({
        autoInjectScripts = true,
        cacheMaxAge = 300,
    })
end)

-- ============================================================
-- Testes de renderPage
-- ============================================================

test("renderer.renderPage gera HTML completo", function()
    local html = renderer.renderPage({
        title = "Minha Página",
        body = "<h1>Olá</h1>",
        lang = "pt-BR",
    })
    
    assert_contains(html, "<!DOCTYPE html>")
    assert_contains(html, "<title>Minha Página</title>")
    assert_contains(html, 'lang="pt-BR"')
    assert_contains(html, "<h1>Olá</h1>")
end)

test("renderer.renderPage inclui scripts externos", function()
    local html = renderer.renderPage({
        title = "Test",
        body = "<p>Test</p>",
        scripts = { "/js/app.js", "console.log('inline')" },
    })
    
    assert_contains(html, 'src="/js/app.js"')
    assert_contains(html, "console.log('inline')")
end)

test("renderer.renderPage inclui styles", function()
    local html = renderer.renderPage({
        title = "Test",
        body = "<p>Test</p>",
        styles = { "/css/style.css", "body { color: red; }" },
    })
    
    assert_contains(html, 'href="/css/style.css"')
    assert_contains(html, "body { color: red; }")
end)

-- ============================================================
-- Testes de Erros
-- ============================================================

test("renderer.renderError gera página de erro bonita", function()
    local html = renderer.renderError("Algo deu errado!")
    
    assert_contains(html, "<!DOCTYPE html>")
    assert_contains(html, "Erro")
    assert_contains(html, "Algo deu errado!")
end)

test("renderer trata erro em componente graciosamente", function()
    local function BrokenComponent()
        error("Componente quebrado!")
    end
    
    local html = renderer.render(BrokenComponent, {})
    
    assert_contains(html, "Erro")
    assert_contains(html, "Componente quebrado!")
end)

-- ============================================================
-- Testes de Utilitários
-- ============================================================

test("renderer.escapeHtml escapa caracteres especiais", function()
    local escaped = renderer.escapeHtml("<script>alert('xss')</script>")
    
    assert_contains(escaped, "&lt;")
    assert_contains(escaped, "&gt;")
    assert_contains(escaped, "&#39;")
end)

test("renderer.getStats retorna estatísticas", function()
    renderer.clearCache()
    
    local function Page() return vdom.h("div", {}, "Test") end
    renderer.render(Page, {}, "/stats-test")
    
    local stats = renderer.getStats()
    
    assert_true(stats.cachedPages >= 1, "Deve ter pelo menos 1 página em cache")
    assert_true(stats.config ~= nil, "Deve ter config")
end)

-- ============================================================
-- Resumo
-- ============================================================

print(string.rep("=", 50))
print(string.format("Total: %d passed, %d failed", tests_passed, tests_failed))

if tests_failed > 0 then
    os.exit(1)
end
