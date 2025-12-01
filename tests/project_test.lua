--[[
    Teste de Criação e Execução de Projetos
    ========================================
    
    Testa se o CLI cria projetos corretamente e se eles executam sem erros.
]]

package.path = "../?.lua;../?/init.lua;../PudimWeb/?.lua;../PudimWeb/?/init.lua;" .. package.path

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

local function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "Assertion failed") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
    end
end

local function assert_true(v, msg)
    if not v then
        error(msg or "Expected true, got " .. tostring(v))
    end
end

local function assert_contains(str, pattern, msg)
    if not str:find(pattern, 1, true) then
        error((msg or "String não contém padrão") .. ": '" .. pattern .. "' not in '" .. str:sub(1, 100) .. "...'")
    end
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function exec(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    local result = handle:read("*a")
    local success, _, code = handle:close()
    return result, code or 0
end

-- Diretório temporário para testes
local TEST_DIR = "/tmp/pudimweb_test_" .. os.time()
local PROJECT_NAME = "test_project"
local PROJECT_PATH = TEST_DIR .. "/" .. PROJECT_NAME
local CLI_PATH = "/home/davi/Documentos/GitHub/PudimWeb/bin/pudim"

print("\n🍮 PudimWeb Project Creation Tests")
print("==================================================")
print("Test dir: " .. TEST_DIR)
print("==================================================\n")

-- Cleanup antes dos testes
os.execute("rm -rf " .. TEST_DIR)
os.execute("mkdir -p " .. TEST_DIR)

-- ============================================
-- Testes do CLI
-- ============================================

test("CLI help funciona", function()
    local output, code = exec("lua " .. CLI_PATH .. " help")
    assert_eq(code, 0, "Exit code")
    assert_contains(output, "PudimWeb CLI", "Output")
    assert_contains(output, "new", "Output")
    assert_contains(output, "serve", "Output")
end)

test("CLI version funciona", function()
    local output, code = exec("lua " .. CLI_PATH .. " version")
    assert_eq(code, 0, "Exit code")
    assert_contains(output, "PudimWeb", "Output")
end)

test("CLI new cria projeto", function()
    local output, code = exec("cd " .. TEST_DIR .. " && lua " .. CLI_PATH .. " new " .. PROJECT_NAME)
    assert_eq(code, 0, "Exit code")
    assert_contains(output, "Project created successfully", "Output")
end)

-- ============================================
-- Testes de Estrutura do Projeto
-- ============================================

test("server.lua existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/server.lua"), "server.lua não encontrado")
end)

test("app/layout.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/layout.lx"), "layout.lx não encontrado")
end)

test("app/pages/index.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/pages/index.lx"), "index.lx não encontrado")
end)

test("app/pages/about.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/pages/about.lx"), "about.lx não encontrado")
end)

test("app/pages/docs.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/pages/docs.lx"), "docs.lx não encontrado")
end)

test("app/pages/blog/index.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/pages/blog/index.lx"), "blog/index.lx não encontrado")
end)

test("app/pages/blog/[id].lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/pages/blog/[id].lx"), "[id].lx não encontrado")
end)

test("app/api/hello.lua existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/api/hello.lua"), "hello.lua não encontrado")
end)

test("app/api/users.lua existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/api/users.lua"), "users.lua não encontrado")
end)

test("app/components/Button.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/components/Button.lx"), "Button.lx não encontrado")
end)

test("app/components/Card.lx existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/components/Card.lx"), "Card.lx não encontrado")
end)

test("app/public/styles.css existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/public/styles.css"), "styles.css não encontrado")
end)

test("app/public/app.js existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/app/public/app.js"), "app.js não encontrado")
end)

test("README.md existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/README.md"), "README.md não encontrado")
end)

test(".gitignore existe", function()
    assert_true(file_exists(PROJECT_PATH .. "/.gitignore"), ".gitignore não encontrado")
end)

-- ============================================
-- Testes de Conteúdo dos Arquivos
-- ============================================

test("server.lua tem conteúdo correto", function()
    local content = read_file(PROJECT_PATH .. "/server.lua")
    assert_contains(content, "require(\"DaviLuaXML\")", "DaviLuaXML require")
    assert_contains(content, "require(\"PudimWeb\")", "PudimWeb require")
    assert_contains(content, "pudim.start", "pudim.start")
end)

test("index.lx usa aliases corretos (não tags minúsculas)", function()
    local content = read_file(PROJECT_PATH .. "/app/pages/index.lx")
    -- Não deve ter tags HTML minúsculas diretamente no JSX
    assert_true(not content:find("<header"), "Encontrou <header> minúsculo")
    assert_true(not content:find("<section"), "Encontrou <section> minúsculo")
    assert_true(not content:find("<span"), "Encontrou <span> minúsculo")
    -- Deve ter aliases
    assert_contains(content, "html.header", "Alias header")
    assert_contains(content, "html.section", "Alias section")
    assert_contains(content, "html.span", "Alias span")
end)

test("index.lx tem componente Counter", function()
    local content = read_file(PROJECT_PATH .. "/app/pages/index.lx")
    assert_contains(content, "local Counter", "Counter component")
    assert_contains(content, "client.function_", "client module usage")
end)

test("about.lx não tem tags minúsculas", function()
    local content = read_file(PROJECT_PATH .. "/app/pages/about.lx")
    assert_true(not content:find("<section>"), "Encontrou <section> minúsculo")
end)

test("API hello.lua tem GET e POST", function()
    local content = read_file(PROJECT_PATH .. "/app/api/hello.lua")
    assert_contains(content, "GET = function", "GET handler")
    assert_contains(content, "POST = function", "POST handler")
end)

test("styles.css tem variáveis CSS", function()
    local content = read_file(PROJECT_PATH .. "/app/public/styles.css")
    assert_contains(content, ":root", "CSS variables root")
    assert_contains(content, "--primary", "Primary color variable")
end)

-- ============================================
-- Testes de Sintaxe Lua (arquivos .lua)
-- ============================================

test("server.lua tem sintaxe válida", function()
    local output, code = exec("luac -p " .. PROJECT_PATH .. "/server.lua")
    assert_eq(code, 0, "Sintaxe inválida: " .. output)
end)

test("app/api/hello.lua tem sintaxe válida", function()
    local output, code = exec("luac -p " .. PROJECT_PATH .. "/app/api/hello.lua")
    assert_eq(code, 0, "Sintaxe inválida: " .. output)
end)

test("app/api/users.lua tem sintaxe válida", function()
    local output, code = exec("luac -p " .. PROJECT_PATH .. "/app/api/users.lua")
    assert_eq(code, 0, "Sintaxe inválida: " .. output)
end)

-- ============================================
-- Teste de Compilação DaviLuaXML (opcional)
-- ============================================

-- Verifica se DaviLuaXML está disponível
local davixml_available = pcall(require, "DaviLuaXML")

if davixml_available then
    test("index.lx compila com DaviLuaXML", function()
        require("DaviLuaXML")
        local transform = require("DaviLuaXML.transform")
        local f = io.open(PROJECT_PATH .. "/app/pages/index.lx", "r")
        local code = f:read("*a")
        f:close()
        local result, err = transform.transform(code)
        if not result then
            error("Falha na transformação: " .. tostring(err))
        end
    end)

    test("about.lx compila com DaviLuaXML", function()
        require("DaviLuaXML")
        local transform = require("DaviLuaXML.transform")
        local f = io.open(PROJECT_PATH .. "/app/pages/about.lx", "r")
        local code = f:read("*a")
        f:close()
        local result, err = transform.transform(code)
        if not result then
            error("Falha na transformação: " .. tostring(err))
        end
    end)

    test("layout.lx compila com DaviLuaXML", function()
        require("DaviLuaXML")
        local transform = require("DaviLuaXML.transform")
        local f = io.open(PROJECT_PATH .. "/app/layout.lx", "r")
        local code = f:read("*a")
        f:close()
        local result, err = transform.transform(code)
        if not result then
            error("Falha na transformação: " .. tostring(err))
        end
    end)
else
    print("⚠ DaviLuaXML não disponível - testes de compilação .lx ignorados")
end

-- ============================================
-- Cleanup
-- ============================================

print("\n==================================================")
print(string.format("Total: %d passed, %d failed", passed, failed))

-- Cleanup
os.execute("rm -rf " .. TEST_DIR)
print("✓ Cleanup: " .. TEST_DIR .. " removido")

if failed > 0 then
    os.exit(1)
end
