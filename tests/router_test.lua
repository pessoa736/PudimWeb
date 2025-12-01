--[[
    Testes do Router
    ================
    
    Testa o sistema de rotas do PudimWeb.
    
    Executar: lua tests/router_test.lua
--]]

local Router = require("PudimWeb.router")

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

local function assertNil(value, msg)
    if value ~= nil then
        error(msg or "Expected nil, got: " .. tostring(value))
    end
end

print("\n=== Testes do Router ===\n")

-- Teste: Criar router
test("Criar router", function()
    local router = Router.new()
    assertNotNil(router)
    assertNotNil(router.routes)
    assertNotNil(router.routes.GET)
    assertNotNil(router.routes.POST)
    assertNotNil(router.routes.PUT)
    assertNotNil(router.routes.DELETE)
end)

-- Teste: Adicionar rota GET
test("Adicionar rota GET", function()
    local router = Router.new()
    local handler = function() return "ok" end
    router:add("GET", "/test", handler)
    assertEquals(1, #router.routes.GET)
end)

-- Teste: Adicionar rota POST
test("Adicionar rota POST", function()
    local router = Router.new()
    local handler = function() return "ok" end
    router:add("POST", "/api/users", handler)
    assertEquals(1, #router.routes.POST)
end)

-- Teste: Adicionar rota PUT
test("Adicionar rota PUT", function()
    local router = Router.new()
    local handler = function() return "ok" end
    router:add("PUT", "/api/users/:id", handler)
    assertEquals(1, #router.routes.PUT)
end)

-- Teste: Adicionar rota DELETE
test("Adicionar rota DELETE", function()
    local router = Router.new()
    local handler = function() return "ok" end
    router:add("DELETE", "/api/users/:id", handler)
    assertEquals(1, #router.routes.DELETE)
end)

-- Teste: Match rota estática
test("Match rota estática", function()
    local router = Router.new()
    local handler = function() return "found" end
    router:add("GET", "/users", handler)
    
    local matched, params = router:match("GET", "/users")
    assertNotNil(matched)
    assertEquals(handler, matched)
end)

-- Teste: Match rota com parâmetro
test("Match rota com parâmetro", function()
    local router = Router.new()
    local handler = function() return "user" end
    router:add("GET", "/users/:id", handler)
    
    local matched, params = router:match("GET", "/users/123")
    assertNotNil(matched)
    assertEquals(handler, matched)
    assertNotNil(params)
    assertEquals("123", params.id)
end)

-- Teste: Match rota com múltiplos parâmetros
test("Match rota com múltiplos parâmetros", function()
    local router = Router.new()
    local handler = function() return "post" end
    router:add("GET", "/users/:userId/posts/:postId", handler)
    
    local matched, params = router:match("GET", "/users/42/posts/99")
    assertNotNil(matched)
    assertEquals("42", params.userId)
    assertEquals("99", params.postId)
end)

-- Teste: Match rota inexistente
test("Match rota inexistente", function()
    local router = Router.new()
    router:add("GET", "/exists", function() end)
    
    local matched, params = router:match("GET", "/not-exists")
    assertNil(matched)
end)

-- Teste: Match método errado
test("Match método errado", function()
    local router = Router.new()
    router:add("GET", "/users", function() end)
    
    local matched, params = router:match("POST", "/users")
    assertNil(matched)
end)

-- Teste: Case insensitive para método
test("Case insensitive para método", function()
    local router = Router.new()
    local handler = function() return "ok" end
    router:add("get", "/test", handler)
    
    local matched = router:match("GET", "/test")
    assertNotNil(matched)
end)

-- Teste: Múltiplas rotas
test("Múltiplas rotas", function()
    local router = Router.new()
    local handler1 = function() return "1" end
    local handler2 = function() return "2" end
    local handler3 = function() return "3" end
    
    router:add("GET", "/one", handler1)
    router:add("GET", "/two", handler2)
    router:add("POST", "/three", handler3)
    
    assertEquals(2, #router.routes.GET)
    assertEquals(1, #router.routes.POST)
    
    local m1 = router:match("GET", "/one")
    local m2 = router:match("GET", "/two")
    local m3 = router:match("POST", "/three")
    
    assertEquals(handler1, m1)
    assertEquals(handler2, m2)
    assertEquals(handler3, m3)
end)

-- Teste: Rota raiz
test("Rota raiz /", function()
    local router = Router.new()
    local handler = function() return "root" end
    router:add("GET", "/", handler)
    
    local matched = router:match("GET", "/")
    assertNotNil(matched)
    assertEquals(handler, matched)
end)

-- Teste: Parâmetro com underscore
test("Parâmetro com underscore", function()
    local router = Router.new()
    router:add("GET", "/items/:item_id", function() end)
    
    local matched, params = router:match("GET", "/items/abc123")
    assertNotNil(matched)
    assertEquals("abc123", params.item_id)
end)

-- Teste: Rota específica vs genérica (ordem de adição)
test("Rota específica vs genérica", function()
    local router = Router.new()
    local genericHandler = function() return "generic" end
    local specificHandler = function() return "specific" end
    
    -- Adiciona genérica primeiro
    router:add("GET", "/users/:id", genericHandler)
    -- Depois específica
    router:add("GET", "/users/new", specificHandler)
    
    -- A genérica deve ser encontrada primeiro (por ordem de adição)
    local matched = router:match("GET", "/users/new")
    assertNotNil(matched)
end)

-- Teste: Método não existente
test("Método não existente", function()
    local router = Router.new()
    local matched = router:match("PATCH", "/test")
    assertNil(matched)
end)

-- Resumo
print(string.format("\n=== Resultado: %d passaram, %d falharam ===\n", passed, failed))

if failed > 0 then
    os.exit(1)
end
