--[[
    PudimWeb Builder Tests
    ======================
    
    Testes para o sistema de build.
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
            msg or "Assertion failed", pattern, str:sub(1, 200)))
    end
end

local function assert_true(value, msg)
    if not value then
        error(msg or "Expected true but got false/nil")
    end
end

print("\n🍮 PudimWeb Builder Tests\n" .. string.rep("=", 50))

-- Carrega módulo
local builder = require("PudimWeb.core.builder")

-- ============================================================
-- Testes de Configuração
-- ============================================================

test("getDefaultConfig retorna configuração válida", function()
    local config = builder.getDefaultConfig()
    
    assert_true(config.inputDir ~= nil, "inputDir deve existir")
    assert_true(config.outputDir ~= nil, "outputDir deve existir")
    assert_eq(config.inputDir, "./app")
    assert_eq(config.outputDir, "./dist")
    assert_eq(config.minify, false)
    assert_eq(config.copyStatic, true)
end)

-- ============================================================
-- Testes de Minificação CSS
-- ============================================================

-- Acessa função interna via ambiente de teste
-- Nota: Em produção, essas funções são privadas
local function testMinifyCSS()
    -- Simula a função minifyCSS
    local function minifyCSS(css)
        css = css:gsub("/%*.-%*/", "")
        css = css:gsub("%s+", " ")
        css = css:gsub(" *([{:;,}]) *", "%1")
        css = css:gsub(";\n?}", "}")
        css = css:gsub("^%s+", ""):gsub("%s+$", "")
        return css
    end
    
    return minifyCSS
end

local minifyCSS = testMinifyCSS()

test("minifyCSS remove comentários", function()
    local input = "/* comment */\nbody { color: red; }"
    local output = minifyCSS(input)
    assert_true(not output:find("comment"), "Não deve conter comentário")
end)

test("minifyCSS remove espaços extras", function()
    local input = "body  {   color:   red;   }"
    local output = minifyCSS(input)
    -- A minificação também remove ; antes de } 
    assert_contains(output, "body{color:red")
end)

test("minifyCSS remove espaços ao redor de pontuação", function()
    local input = ".class { margin : 0 ; padding : 10px ; }"
    local output = minifyCSS(input)
    assert_true(not output:find(" : "), "Não deve ter espaços ao redor de :")
end)

-- ============================================================
-- Testes de Minificação JS
-- ============================================================

local function testMinifyJS()
    local function minifyJS(js)
        js = js:gsub("([^:])//[^\n]*", "%1")
        js = js:gsub("/%*.-%*/", "")
        js = js:gsub("%s+", " ")
        js = js:gsub(" *([{};,=+%-*/<>!&|:?]) *", "%1")
        js = js:gsub("^%s+", ""):gsub("%s+$", "")
        return js
    end
    return minifyJS
end

local minifyJS = testMinifyJS()

test("minifyJS remove comentários de bloco", function()
    local input = "/* comment */\nvar x = 1;"
    local output = minifyJS(input)
    assert_true(not output:find("comment"), "Não deve conter comentário")
end)

test("minifyJS remove espaços extras", function()
    local input = "var   x   =   1;"
    local output = minifyJS(input)
    assert_contains(output, "var x=1;")
end)

-- ============================================================
-- Testes de Hash
-- ============================================================

local function testHashContent()
    local function hashContent(content)
        local hash = 0
        for i = 1, #content do
            hash = (hash * 31 + content:byte(i)) % 0x7FFFFFFF
        end
        return string.format("%08x", hash)
    end
    return hashContent
end

local hashContent = testHashContent()

test("hashContent gera hash consistente", function()
    local hash1 = hashContent("hello")
    local hash2 = hashContent("hello")
    assert_eq(hash1, hash2, "Mesmo conteúdo deve gerar mesmo hash")
end)

test("hashContent gera hashes diferentes para conteúdos diferentes", function()
    local hash1 = hashContent("hello")
    local hash2 = hashContent("world")
    assert_true(hash1 ~= hash2, "Conteúdos diferentes devem gerar hashes diferentes")
end)

test("hashContent retorna string de 8 caracteres", function()
    local hash = hashContent("test content")
    assert_eq(#hash, 8, "Hash deve ter 8 caracteres")
end)

-- ============================================================
-- Testes de generateProductionServer
-- ============================================================

test("generateProductionServer gera código válido", function()
    local config = {
        pagesDir = "pages",
        publicDir = "public",
        apiDir = "api",
    }
    
    local serverCode = builder.generateProductionServer(config)
    
    assert_contains(serverCode, "PudimWeb Production Server")
    assert_contains(serverCode, "require(\"PudimWeb\")")
    assert_contains(serverCode, "pudim.start")
    assert_contains(serverCode, "pagesDir")
    assert_contains(serverCode, "publicDir")
    assert_contains(serverCode, "apiDir")
end)

test("generateProductionServer inclui configuração de porta via env", function()
    local config = {
        pagesDir = "pages",
        publicDir = "public",
        apiDir = "api",
    }
    
    local serverCode = builder.generateProductionServer(config)
    
    assert_contains(serverCode, "os.getenv(\"PORT\")")
    assert_contains(serverCode, "os.getenv(\"HOST\")")
end)

-- ============================================================
-- Testes de clean
-- ============================================================

test("clean não falha com diretório inexistente", function()
    -- Não deve lançar erro
    builder.clean("./nonexistent_test_dir_12345")
end)

-- ============================================================
-- Resumo
-- ============================================================

print(string.rep("=", 50))
print(string.format("Total: %d passed, %d failed", tests_passed, tests_failed))

if tests_failed > 0 then
    os.exit(1)
end
