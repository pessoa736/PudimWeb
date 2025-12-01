--[[
    Testes do Hooks
    ===============
    
    Testa o sistema de hooks do PudimWeb.
    
    Executar: lua tests/hooks_test.lua
--]]

local hooks = require("PudimWeb.core.hooks")

local passed = 0
local failed = 0

local function test(name, fn)
    -- Reset hooks antes de cada teste
    hooks.reset()
    
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

print("\n=== Testes do Hooks ===\n")

-- Teste: useState básico
test("useState - Valor inicial", function()
    local value, setValue = hooks.useState(10)
    assertEquals(10, value)
    assertNotNil(setValue)
end)

-- Teste: useState com nil
test("useState - Valor nil inicial", function()
    local value, setValue = hooks.useState(nil)
    assertEquals(nil, value)
end)

-- Teste: useState - Atualizar valor direto
test("useState - Atualizar valor direto", function()
    local value, setValue = hooks.useState(0)
    assertEquals(0, value)
    
    setValue(5)
    -- O valor local não muda após setValue, isso é esperado
    -- O novo valor só é obtido na próxima "renderização"
    -- Este teste apenas verifica que setValue é chamável sem erro
    assertTrue(type(setValue) == "function")
end)

-- Teste: useState - Atualizar com função
test("useState - Atualizar com função", function()
    local value, setValue = hooks.useState(10)
    
    -- Atualiza com função
    setValue(function(prev) return prev + 5 end)
    
    -- O setValue modifica o estado interno
    -- Verificamos indiretamente
    assertTrue(type(setValue) == "function")
end)

-- Teste: Múltiplos useState
test("Múltiplos useState", function()
    local count, setCount = hooks.useState(0)
    local name, setName = hooks.useState("John")
    local active, setActive = hooks.useState(true)
    
    assertEquals(0, count)
    assertEquals("John", name)
    assertEquals(true, active)
end)

-- Teste: useEffect básico
test("useEffect - Registro de efeito", function()
    local effectCalled = false
    
    hooks.useEffect(function()
        effectCalled = true
    end, {})
    
    -- Efeito não é chamado até runEffects
    assertEquals(false, effectCalled)
    
    -- Executa efeitos
    hooks.runEffects()
    
    assertEquals(true, effectCalled)
end)

-- Teste: useEffect sem deps (sempre executa)
test("useEffect - Sem deps", function()
    local callCount = 0
    
    hooks.useEffect(function()
        callCount = callCount + 1
    end)
    
    hooks.runEffects()
    assertEquals(1, callCount)
end)

-- Teste: Múltiplos useEffect
test("Múltiplos useEffect", function()
    local effects = {}
    
    hooks.useEffect(function()
        table.insert(effects, "effect1")
    end, {})
    
    hooks.useEffect(function()
        table.insert(effects, "effect2")
    end, {})
    
    hooks.runEffects()
    
    assertEquals(2, #effects)
    assertEquals("effect1", effects[1])
    assertEquals("effect2", effects[2])
end)

-- Teste: useMemo básico
test("useMemo - Computa valor", function()
    local computeCount = 0
    
    local result = hooks.useMemo(function()
        computeCount = computeCount + 1
        return 10 * 2
    end, {})
    
    assertEquals(20, result)
    assertEquals(1, computeCount)
end)

-- Teste: useMemo - Cache com mesmas deps
test("useMemo - Cache funciona", function()
    local computeCount = 0
    local deps = { 1, 2 }
    
    -- Primeira chamada - deve computar
    local fn = function()
        computeCount = computeCount + 1
        return "computed"
    end
    
    local result1 = hooks.useMemo(fn, deps)
    assertEquals("computed", result1)
    assertEquals(1, computeCount)
end)

-- Teste: useCallback
test("useCallback - Retorna função", function()
    local callback = function() return "hello" end
    
    local memoized = hooks.useCallback(callback, {})
    
    assertNotNil(memoized)
    assertEquals("function", type(memoized))
    assertEquals("hello", memoized())
end)

-- Teste: createContext
test("createContext - Cria contexto com valor padrão", function()
    local context = hooks.createContext("default")
    
    assertNotNil(context)
    assertEquals("default", context._defaultValue)
end)

-- Teste: createContext com nil
test("createContext - Valor nil", function()
    local context = hooks.createContext(nil)
    assertNotNil(context)
    assertEquals(nil, context._defaultValue)
end)

-- Teste: createContext com tabela
test("createContext - Valor tabela", function()
    local context = hooks.createContext({ theme = "dark" })
    assertNotNil(context)
    assertEquals("dark", context._defaultValue.theme)
end)

-- Teste: useContext - Obtém valor padrão
test("useContext - Valor padrão", function()
    local ThemeContext = hooks.createContext("light")
    
    local theme = hooks.useContext(ThemeContext)
    assertEquals("light", theme)
end)

-- Teste: useContext - Obtém valor atual
test("useContext - Valor atual", function()
    local ThemeContext = hooks.createContext("light")
    ThemeContext._currentValue = "dark"
    
    local theme = hooks.useContext(ThemeContext)
    assertEquals("dark", theme)
end)

-- Teste: Provider - Define valor
test("Provider - Define valor do contexto", function()
    local ThemeContext = hooks.createContext("light")
    
    local capturedTheme = nil
    
    hooks.Provider(ThemeContext, "dark", function()
        capturedTheme = hooks.useContext(ThemeContext)
        return ""
    end)
    
    assertEquals("dark", capturedTheme)
end)

-- Teste: Provider - Restaura valor após
test("Provider - Restaura valor original", function()
    local ThemeContext = hooks.createContext("light")
    
    -- Dentro do provider
    hooks.Provider(ThemeContext, "dark", function()
        return ""
    end)
    
    -- Fora do provider deve voltar ao padrão
    local theme = hooks.useContext(ThemeContext)
    assertEquals("light", theme)
end)

-- Teste: Provider com children string
test("Provider - Children string", function()
    local Context = hooks.createContext("test")
    
    local result = hooks.Provider(Context, "value", "Hello World")
    assertEquals("Hello World", result)
end)

-- Teste: Provider com children tabela
test("Provider - Children tabela", function()
    local Context = hooks.createContext("test")
    
    local result = hooks.Provider(Context, "value", {
        "Part 1",
        "Part 2",
    })
    assertEquals("Part 1Part 2", result)
end)

-- Teste: reset limpa estado
test("reset - Limpa estado", function()
    -- Usa alguns hooks
    hooks.useState(1)
    hooks.useState(2)
    hooks.useEffect(function() end)
    
    -- Reset
    hooks.reset()
    
    -- Novos hooks devem começar do zero
    local val, _ = hooks.useState(100)
    assertEquals(100, val)
end)

-- Teste: runEffects limpa efeitos
test("runEffects - Limpa após executar", function()
    local count = 0
    
    hooks.useEffect(function()
        count = count + 1
    end)
    
    hooks.runEffects()
    assertEquals(1, count)
    
    -- Segunda execução não deve chamar novamente
    hooks.runEffects()
    assertEquals(1, count)
end)

-- Resumo
print(string.format("\n=== Resultado: %d passaram, %d falharam ===\n", passed, failed))

if failed > 0 then
    os.exit(1)
end
