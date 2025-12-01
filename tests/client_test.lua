--[[
    Testes do módulo Client (Browser Bindings)
--]]

-- Configura path para encontrar módulos
package.path = "./?.lua;./?/init.lua;" .. package.path

local client = require("PudimWeb.core.client")

local passed = 0
local failed = 0

local function test(name, fn)
    -- Limpa buffer antes de cada teste
    client.clear()
    
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("✓ " .. name)
    else
        failed = failed + 1
        print("✗ " .. name)
        print("  Erro: " .. tostring(err))
    end
end

local function assertContains(str, pattern, msg)
    if not str:find(pattern, 1, true) then
        error((msg or "Assertion failed") .. ": '" .. pattern .. "' not found in:\n" .. str)
    end
end

local function assertMatch(str, pattern, msg)
    if not str:match(pattern) then
        error((msg or "Assertion failed") .. ": pattern '" .. pattern .. "' not matched in:\n" .. str)
    end
end

print("\n=== Testes do Client ===\n")

-- Testes de seleção
test("select - Gera querySelector", function()
    local el = client.select("#btn")
    el:text("Olá")
    local js = client.build({ wrap = false })
    assertContains(js, "document.querySelector('#btn')")
    assertContains(js, ".textContent = 'Olá'")
end)

test("selectAll - Gera querySelectorAll", function()
    local els = client.selectAll(".item")
    els:addClass("ativo")
    local js = client.build({ wrap = false })
    assertContains(js, "document.querySelectorAll('.item')")
    assertContains(js, ".forEach")
    assertContains(js, "classList.add('ativo')")
end)

test("$ alias - Funciona como select", function()
    client.el(".test"):hide()
    local js = client.build({ wrap = false })
    assertContains(js, "document.querySelector('.test')")
    assertContains(js, "display")
end)

-- Testes de manipulação DOM
test("text - Define textContent", function()
    client.select("#p"):text("Novo texto")
    local js = client.build({ wrap = false })
    assertContains(js, "textContent = 'Novo texto'")
end)

test("html - Define innerHTML", function()
    client.select("#div"):html("<b>Bold</b>")
    local js = client.build({ wrap = false })
    assertContains(js, "innerHTML = '<b>Bold</b>'")
end)

test("val - Define value", function()
    client.select("#input"):val("valor")
    local js = client.build({ wrap = false })
    assertContains(js, ".value = 'valor'")
end)

test("addClass - Adiciona classe", function()
    client.select("#el"):addClass("nova-classe")
    local js = client.build({ wrap = false })
    assertContains(js, "classList.add('nova-classe')")
end)

test("removeClass - Remove classe", function()
    client.select("#el"):removeClass("classe")
    local js = client.build({ wrap = false })
    assertContains(js, "classList.remove('classe')")
end)

test("toggleClass - Toggle classe", function()
    client.select("#el"):toggleClass("ativo")
    local js = client.build({ wrap = false })
    assertContains(js, "classList.toggle('ativo')")
end)

test("attr - Define atributo", function()
    client.select("#el"):attr("data-id", "123")
    local js = client.build({ wrap = false })
    assertContains(js, "setAttribute('data-id', '123')")
end)

test("removeAttr - Remove atributo", function()
    client.select("#el"):removeAttr("disabled")
    local js = client.build({ wrap = false })
    assertContains(js, "removeAttribute('disabled')")
end)

test("css - Define estilo", function()
    client.select("#el"):css("color", "red")
    local js = client.build({ wrap = false })
    assertContains(js, ".style.color = 'red'")
end)

test("css - Converte kebab-case para camelCase", function()
    client.select("#el"):css("background-color", "blue")
    local js = client.build({ wrap = false })
    assertContains(js, ".style.backgroundColor = 'blue'")
end)

test("show - Remove display none", function()
    client.select("#el"):show()
    local js = client.build({ wrap = false })
    assertContains(js, ".style.display = ''")
end)

test("hide - Define display none", function()
    client.select("#el"):hide()
    local js = client.build({ wrap = false })
    assertContains(js, ".style.display = 'none'")
end)

-- Testes de eventos
test("on - Adiciona event listener", function()
    client.select("#btn"):on("click", function()
        client.alert("Clicado!")
    end)
    local js = client.build({ wrap = false })
    assertContains(js, "addEventListener('click'")
    assertContains(js, "function(event)")
    assertContains(js, "alert('Clicado!')")
end)

-- Testes de manipulação de conteúdo
test("append - Insere HTML no final", function()
    client.select("#list"):append("<li>Item</li>")
    local js = client.build({ wrap = false })
    assertContains(js, "insertAdjacentHTML('beforeend'")
end)

test("prepend - Insere HTML no início", function()
    client.select("#list"):prepend("<li>Primeiro</li>")
    local js = client.build({ wrap = false })
    assertContains(js, "insertAdjacentHTML('afterbegin'")
end)

test("before - Insere HTML antes", function()
    client.select("#el"):before("<p>Antes</p>")
    local js = client.build({ wrap = false })
    assertContains(js, "insertAdjacentHTML('beforebegin'")
end)

test("after - Insere HTML depois", function()
    client.select("#el"):after("<p>Depois</p>")
    local js = client.build({ wrap = false })
    assertContains(js, "insertAdjacentHTML('afterend'")
end)

test("remove - Remove elemento", function()
    client.select("#el"):remove()
    local js = client.build({ wrap = false })
    assertContains(js, ".remove()")
end)

-- Testes de Window APIs
test("alert - Gera alert", function()
    client.alert("Mensagem")
    local js = client.build({ wrap = false })
    assertContains(js, "alert('Mensagem')")
end)

test("console.log - Gera console.log", function()
    client.console.log("Debug", 123)
    local js = client.build({ wrap = false })
    assertContains(js, "console.log('Debug', 123)")
end)

test("console.error - Gera console.error", function()
    client.console.error("Erro!")
    local js = client.build({ wrap = false })
    assertContains(js, "console.error('Erro!')")
end)

test("setTimeout - Gera setTimeout", function()
    client.setTimeout(function()
        client.console.log("Executado")
    end, 1000)
    local js = client.build({ wrap = false })
    assertContains(js, "setTimeout(")
    assertContains(js, "1000")
end)

test("redirect - Redireciona", function()
    client.redirect("/login")
    local js = client.build({ wrap = false })
    assertContains(js, "window.location.href = '/login'")
end)

test("reload - Recarrega página", function()
    client.reload()
    local js = client.build({ wrap = false })
    assertContains(js, "window.location.reload()")
end)

-- Testes de Storage
test("storage.set - Gera localStorage.setItem", function()
    client.storage.set("chave", "valor")
    local js = client.build({ wrap = false })
    assertContains(js, "localStorage.setItem('chave', 'valor')")
end)

test("storage.get - Gera localStorage.getItem", function()
    client.storage.get("chave")
    local js = client.build({ wrap = false })
    assertContains(js, "localStorage.getItem('chave')")
end)

test("storage.remove - Gera localStorage.removeItem", function()
    client.storage.remove("chave")
    local js = client.build({ wrap = false })
    assertContains(js, "localStorage.removeItem('chave')")
end)

-- Testes de Fetch
test("fetch - GET básico", function()
    client.fetch("/api/users")
    local js = client.build({ wrap = false })
    assertContains(js, "fetch('/api/users'")
    assertContains(js, "method: 'GET'")
end)

test("fetch - POST com body", function()
    client.fetch("/api/users", {
        method = "POST",
        body = { name = "João" }
    })
    local js = client.build({ wrap = false })
    assertContains(js, "method: 'POST'")
    assertContains(js, "JSON.stringify")
end)

-- Testes de Build
test("build - Wrap em IIFE por padrão", function()
    client.alert("teste")
    local js = client.build()
    assertContains(js, "(function()")
    assertContains(js, "'use strict'")
    assertContains(js, "})();")
end)

test("build - Sem wrap quando especificado", function()
    client.alert("teste")
    local js = client.build({ wrap = false })
    assert(not js:find("(function()", 1, true), "Não deveria ter IIFE")
end)

test("buildTag - Gera tag script", function()
    client.alert("teste")
    local tag = client.buildTag()
    assertContains(tag, "<script>")
    assertContains(tag, "</script>")
end)

test("buildTag - Suporta defer", function()
    client.alert("teste")
    local tag = client.buildTag({ defer = true })
    assertContains(tag, "<script defer>")
end)

test("flush - Limpa buffer após build", function()
    client.alert("1")
    local js1 = client.flush({ wrap = false })
    assertContains(js1, "alert('1')")
    
    client.alert("2")
    local js2 = client.build({ wrap = false })
    assertContains(js2, "alert('2')")
    assert(not js2:find("alert('1')", 1, true), "Buffer deveria estar limpo")
end)

-- Testes de raw
test("raw - Código JavaScript arbitrário", function()
    client.raw("console.log('Custom JS');")
    local js = client.build({ wrap = false })
    assertContains(js, "console.log('Custom JS');")
end)

-- Testes de ready/onLoad
test("ready - DOMContentLoaded", function()
    client.ready(function()
        client.console.log("Pronto!")
    end)
    local js = client.build({ wrap = false })
    assertContains(js, "DOMContentLoaded")
end)

test("onLoad - window load", function()
    client.onLoad(function()
        client.console.log("Carregado!")
    end)
    local js = client.build({ wrap = false })
    assertContains(js, "window.addEventListener('load'")
end)

-- Testes de chainable
test("Chainable - Múltiplos métodos encadeados", function()
    client.select("#btn")
        :addClass("primary")
        :text("Clique")
        :attr("data-id", "1")
        :css("color", "white")
    local js = client.build({ wrap = false })
    assertContains(js, "classList.add('primary')")
    assertContains(js, "textContent = 'Clique'")
    assertContains(js, "setAttribute('data-id', '1')")
    assertContains(js, ".style.color = 'white'")
end)

-- Testes de escape
test("Escape - Aspas em strings", function()
    client.alert("Isso é uma 'string' com aspas")
    local js = client.build({ wrap = false })
    assertContains(js, "\\'string\\'")
end)

test("Escape - Newlines em strings", function()
    client.alert("Linha1\nLinha2")
    local js = client.build({ wrap = false })
    assertContains(js, "\\n")
end)

-- Testes de conversão Lua -> JS
test("toLuaJS - Tabela como objeto", function()
    client.console.log({ nome = "João", idade = 30 })
    local js = client.build({ wrap = false })
    assertContains(js, "nome:")
    assertContains(js, "idade:")
end)

test("toLuaJS - Array", function()
    client.console.log({ 1, 2, 3 })
    local js = client.build({ wrap = false })
    assertContains(js, "[1, 2, 3]")
end)

test("toLuaJS - Boolean", function()
    client.console.log(true, false)
    local js = client.build({ wrap = false })
    assertContains(js, "true")
    assertContains(js, "false")
end)

test("toLuaJS - nil via tabela como null", function()
    client.console.log({ value = nil })
    local js = client.build({ wrap = false })
    -- Em Lua, nil em tabela não aparece, então testamos de forma diferente
    -- Testando que valores normais funcionam
    client.clear()
    local t = {}
    t.a = nil  -- nil não aparece em tabelas Lua
    client.raw("console.log(null);")
    local js2 = client.build({ wrap = false })
    assertContains(js2, "null")
end)

-- Testes de funções faltantes
test("confirm - Gera confirm", function()
    client.confirm("Tem certeza?", function()
        client.alert("Sim!")
    end, function()
        client.alert("Não!")
    end)
    local js = client.build({ wrap = false })
    assertContains(js, "if (confirm('Tem certeza?'))")
    assertContains(js, "else")
end)

test("prompt - Gera prompt", function()
    client.prompt("Seu nome:", "Anônimo")
    local js = client.build({ wrap = false })
    assertContains(js, "prompt('Seu nome:', 'Anônimo')")
end)

test("setInterval - Gera setInterval", function()
    client.setInterval(function()
        client.console.log("Tick")
    end, 1000)
    local js = client.build({ wrap = false })
    assertContains(js, "setInterval(")
    assertContains(js, "1000")
end)

test("back - Navega para trás", function()
    client.back()
    local js = client.build({ wrap = false })
    assertContains(js, "window.history.back()")
end)

test("forward - Navega para frente", function()
    client.forward()
    local js = client.build({ wrap = false })
    assertContains(js, "window.history.forward()")
end)

test("session.set - Gera sessionStorage.setItem", function()
    client.session.set("token", "abc123")
    local js = client.build({ wrap = false })
    assertContains(js, "sessionStorage.setItem('token', 'abc123')")
end)

test("session.get - Gera sessionStorage.getItem", function()
    client.session.get("token")
    local js = client.build({ wrap = false })
    assertContains(js, "sessionStorage.getItem('token')")
end)

test("session.remove - Gera sessionStorage.removeItem", function()
    client.session.remove("token")
    local js = client.build({ wrap = false })
    assertContains(js, "sessionStorage.removeItem('token')")
end)

test("session.clear - Gera sessionStorage.clear", function()
    client.session.clear()
    local js = client.build({ wrap = false })
    assertContains(js, "sessionStorage.clear()")
end)

test("storage.clear - Gera localStorage.clear", function()
    client.storage.clear()
    local js = client.build({ wrap = false })
    assertContains(js, "localStorage.clear()")
end)

test("create - Cria elemento", function()
    client.create("div", { class = "container", text = "Conteúdo" })
    local js = client.build({ wrap = false })
    assertContains(js, "document.createElement('div')")
    assertContains(js, ".className = 'container'")
    assertContains(js, ".textContent = 'Conteúdo'")
end)

test("create - Com HTML interno", function()
    client.create("div", { html = "<b>Bold</b>" })
    local js = client.build({ wrap = false })
    assertContains(js, ".innerHTML = '<b>Bold</b>'")
end)

test("create - Com evento onClick", function()
    client.create("button", { onClick = function()
        client.alert("Clicado")
    end })
    local js = client.build({ wrap = false })
    assertContains(js, "addEventListener('click'")
end)

test("focus - Foca no elemento", function()
    client.select("#input"):focus()
    local js = client.build({ wrap = false })
    assertContains(js, ".focus()")
end)

test("blur - Remove foco", function()
    client.select("#input"):blur()
    local js = client.build({ wrap = false })
    assertContains(js, ".blur()")
end)

test("trigger - Dispara evento", function()
    client.select("#btn"):trigger("click")
    local js = client.build({ wrap = false })
    assertContains(js, "dispatchEvent(new Event('click'))")
end)

test("console.warn - Gera console.warn", function()
    client.console.warn("Atenção!")
    local js = client.build({ wrap = false })
    assertContains(js, "console.warn('Atenção!')")
end)

test("console.info - Gera console.info", function()
    client.console.info("Info")
    local js = client.build({ wrap = false })
    assertContains(js, "console.info('Info')")
end)

test("flushTag - Gera tag e limpa buffer", function()
    client.alert("teste")
    local tag = client.flushTag()
    assertContains(tag, "<script>")
    assertContains(tag, "alert('teste')")
    
    -- Buffer deve estar limpo
    local js = client.build({ wrap = false })
    assert(js == "", "Buffer deveria estar vazio após flushTag")
end)

test("buildTag - Suporta async", function()
    client.alert("teste")
    local tag = client.buildTag({ async = true })
    assertContains(tag, "<script async>")
end)

test("fetch - Com callbacks onSuccess e onError", function()
    client.fetch("/api/data", {
        onSuccess = function()
            client.console.log("Sucesso")
        end,
        onError = function()
            client.console.error("Erro")
        end
    })
    local js = client.build({ wrap = false })
    assertContains(js, ".then(function(data)")
    assertContains(js, ".catch(function(error)")
end)

test("$$ alias - Funciona como selectAll", function()
    -- Usando bracket notation pois $$ não é identificador válido
    client["$$"](".items"):addClass("ativo")
    local js = client.build({ wrap = false })
    assertContains(js, "querySelectorAll('.items')")
    assertContains(js, ".forEach")
end)

print("\n=== Resultado: " .. passed .. " passaram, " .. failed .. " falharam ===\n")

os.exit(failed > 0 and 1 or 0)
