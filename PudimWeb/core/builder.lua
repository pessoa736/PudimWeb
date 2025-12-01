--[[
    PudimWeb Builder
    ================
    
    Sistema de build para gerar versão de produção do projeto.
    
    FUNCIONALIDADES:
    ----------------
    - Compila arquivos .lx para .lua puro
    - Bundla e minifica CSS
    - Bundla e minifica JavaScript
    - Pré-renderiza páginas estáticas (SSG)
    - Gera assets otimizados
    - Copia arquivos estáticos
    
    USO:
    ----
    local builder = require("PudimWeb.core.builder")
    
    builder.build({
        inputDir = "./app",
        outputDir = "./dist",
        minify = true,
        prerender = { "/", "/about" },
    })
    
    -- Ou via CLI:
    -- pudim build
    -- pudim build --minify
    -- pudim build --output ./dist
    
    @module PudimWeb.core.builder
    @author pessoa736
    @license MIT
--]]

if not _G.log then
    local ok, loglua = pcall(require, "loglua")
    if ok then _G.log = loglua end
end

local Builder = {}

-- Configurações padrão
local defaultConfig = {
    inputDir = "./app",
    outputDir = "./dist",
    pagesDir = "pages",
    apiDir = "api",
    componentsDir = "components",
    publicDir = "public",
    minify = false,
    prerender = {},
    copyStatic = true,
    generateManifest = true,
    sourceMaps = false,
    hashAssets = true,
    verbose = true,
}

-- Estado do build
local buildState = {
    files = {},
    assets = {},
    errors = {},
    warnings = {},
    startTime = 0,
}

-- Cores para output
local colors = {
    reset = "\27[0m",
    bold = "\27[1m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m",
    gray = "\27[90m",
}

local function colorize(text, color)
    return (colors[color] or "") .. text .. colors.reset
end

local function log_info(msg)
    if buildState.verbose then
        print(colorize("  → ", "cyan") .. msg)
    end
end

local function log_success(msg)
    if buildState.verbose then
        print(colorize("  ✓ ", "green") .. msg)
    end
end

local function log_warning(msg)
    table.insert(buildState.warnings, msg)
    if buildState.verbose then
        print(colorize("  ⚠ ", "yellow") .. msg)
    end
end

local function log_error(msg)
    table.insert(buildState.errors, msg)
    print(colorize("  ✗ ", "red") .. msg)
end

--[[
    Utilitários de Sistema de Arquivos
--]]

--- Verifica se caminho existe
local function pathExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

--- Verifica se é diretório
local function isDir(path)
    local handle = io.popen('test -d "' .. path .. '" && echo "yes" || echo "no"')
    if handle then
        local result = handle:read("*l")
        handle:close()
        return result == "yes"
    end
    return false
end

--- Lista arquivos em um diretório
local function listDir(path)
    local files = {}
    local handle = io.popen('find "' .. path .. '" -type f 2>/dev/null')
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end
    return files
end

--- Lista apenas arquivos diretos (não recursivo)
local function listDirShallow(path)
    local files = {}
    local handle = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end
    return files
end

--- Cria diretório recursivamente
local function mkdir(path)
    os.execute('mkdir -p "' .. path .. '"')
end

--- Copia arquivo
local function copyFile(src, dest)
    local srcFile = io.open(src, "rb")
    if not srcFile then return false end
    
    local content = srcFile:read("*a")
    srcFile:close()
    
    local destFile = io.open(dest, "wb")
    if not destFile then return false end
    
    destFile:write(content)
    destFile:close()
    return true
end

--- Lê arquivo
local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

--- Escreve arquivo
local function writeFile(path, content)
    -- Cria diretório pai se necessário
    local dir = path:match("(.*/)")
    if dir then
        mkdir(dir)
    end
    
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

--- Obtém extensão do arquivo
local function getExtension(path)
    return path:match("%.([^%.]+)$")
end

--- Obtém nome do arquivo sem extensão
local function getBasename(path)
    local name = path:match("([^/]+)$")
    if name then
        return name:gsub("%.[^%.]+$", "")
    end
    return path
end

--- Gera hash simples para cache busting
local function hashContent(content)
    local hash = 0
    for i = 1, #content do
        hash = (hash * 31 + content:byte(i)) % 0x7FFFFFFF
    end
    return string.format("%08x", hash)
end

--[[
    Compilação de Arquivos .lx
--]]

--- Compila arquivo .lx para .lua usando DaviLuaXML
local function compileLx(inputPath, outputPath)
    -- Tenta carregar o DaviLuaXML transform
    local ok, transform = pcall(require, "DaviLuaXML.transform")
    if not ok then
        log_warning("DaviLuaXML não disponível, copiando .lx sem transformar")
        return copyFile(inputPath, outputPath)
    end
    
    local content = readFile(inputPath)
    if not content then
        log_error("Não foi possível ler: " .. inputPath)
        return false
    end
    
    -- Transforma LuaXML para Lua puro
    local ok2, transformed = pcall(transform.transformCode, content)
    if not ok2 then
        log_error("Erro ao compilar " .. inputPath .. ": " .. tostring(transformed))
        return false
    end
    
    -- Adiciona header
    local header = "-- Compiled from " .. inputPath .. " by PudimWeb Builder\n"
    header = header .. "-- Generated at " .. os.date() .. "\n\n"
    
    return writeFile(outputPath, header .. transformed)
end

--[[
    Processamento de CSS
--]]

--- Minifica CSS (versão simples)
local function minifyCSS(css)
    -- Remove comentários
    css = css:gsub("/%*.-%*/", "")
    -- Remove espaços desnecessários
    css = css:gsub("%s+", " ")
    css = css:gsub(" *([{:;,}]) *", "%1")
    css = css:gsub(";\n?}", "}")
    -- Remove espaços no início e fim
    css = css:gsub("^%s+", ""):gsub("%s+$", "")
    return css
end

--- Bundla arquivos CSS
local function bundleCSS(files, outputPath, shouldMinify)
    local bundle = "/* PudimWeb CSS Bundle - " .. os.date() .. " */\n\n"
    
    for _, file in ipairs(files) do
        local content = readFile(file)
        if content then
            bundle = bundle .. "/* Source: " .. file .. " */\n"
            if shouldMinify then
                bundle = bundle .. minifyCSS(content)
            else
                bundle = bundle .. content
            end
            bundle = bundle .. "\n\n"
        end
    end
    
    if shouldMinify then
        bundle = minifyCSS(bundle)
    end
    
    return writeFile(outputPath, bundle)
end

--[[
    Processamento de JavaScript
--]]

--- Minifica JavaScript (versão simples)
local function minifyJS(js)
    -- Remove comentários de linha (cuidado com URLs)
    js = js:gsub("([^:])//[^\n]*", "%1")
    -- Remove comentários de bloco
    js = js:gsub("/%*.-%*/", "")
    -- Remove espaços múltiplos
    js = js:gsub("%s+", " ")
    -- Remove espaços ao redor de operadores
    js = js:gsub(" *([{};,=+%-*/<>!&|:?]) *", "%1")
    -- Remove espaços no início e fim
    js = js:gsub("^%s+", ""):gsub("%s+$", "")
    return js
end

--- Bundla arquivos JavaScript
local function bundleJS(files, outputPath, shouldMinify)
    local bundle = "/* PudimWeb JS Bundle - " .. os.date() .. " */\n"
    bundle = bundle .. "(function(){\n'use strict';\n\n"
    
    for _, file in ipairs(files) do
        local content = readFile(file)
        if content then
            bundle = bundle .. "/* Source: " .. file .. " */\n"
            bundle = bundle .. content
            bundle = bundle .. "\n\n"
        end
    end
    
    bundle = bundle .. "})();\n"
    
    if shouldMinify then
        bundle = minifyJS(bundle)
    end
    
    return writeFile(outputPath, bundle)
end

--[[
    Pré-renderização (SSG)
--]]

--- Pré-renderiza uma página
local function prerenderPage(pagePath, outputPath, config)
    log_info("Pré-renderizando: " .. pagePath)
    
    -- Carrega o PudimWeb
    local ok, pudim = pcall(require, "PudimWeb")
    if not ok then
        log_error("PudimWeb não disponível para pré-renderização")
        return false
    end
    
    -- Carrega o renderer
    local ok2, renderer = pcall(require, "PudimWeb.core.renderer")
    if not ok2 then
        log_error("Renderer não disponível para pré-renderização")
        return false
    end
    
    -- Carrega a página
    local pageModulePath = pagePath:gsub("^%./", ""):gsub("%.lx$", ""):gsub("/", ".")
    local ok3, pageModule = pcall(require, pageModulePath)
    if not ok3 then
        log_error("Erro ao carregar página para pré-renderização: " .. tostring(pageModule))
        return false
    end
    
    -- Determina o componente
    local component
    if type(pageModule) == "function" then
        component = pageModule
    elseif type(pageModule) == "table" and pageModule.default then
        component = pageModule.default
    else
        log_warning("Página não é um componente válido: " .. pagePath)
        return false
    end
    
    -- Renderiza
    local ok4, html = pcall(renderer.render, component, {}, pagePath)
    if not ok4 then
        log_error("Erro ao pré-renderizar: " .. tostring(html))
        return false
    end
    
    -- Salva
    return writeFile(outputPath, html)
end

--[[
    Build Principal
--]]

--- Executa o build completo
--- @param config table Configurações do build
--- @return table Resultado do build
function Builder.build(config)
    config = config or {}
    
    -- Merge com config padrão
    for k, v in pairs(defaultConfig) do
        if config[k] == nil then
            config[k] = v
        end
    end
    
    -- Inicializa estado
    buildState = {
        files = {},
        assets = {},
        errors = {},
        warnings = {},
        startTime = os.time(),
        verbose = config.verbose,
    }
    
    print(colorize([[

╔═══════════════════════════════════════════════════════════╗
║               🍮 PudimWeb Builder                         ║
╚═══════════════════════════════════════════════════════════╝
]], "yellow"))

    log_info("Input:  " .. config.inputDir)
    log_info("Output: " .. config.outputDir)
    log_info("Minify: " .. (config.minify and "sim" or "não"))
    print("")
    
    -- Limpa diretório de saída
    os.execute('rm -rf "' .. config.outputDir .. '"')
    mkdir(config.outputDir)
    
    -- 1. Compila páginas .lx
    print(colorize("  📄 Compilando páginas...", "bold"))
    local pagesInput = config.inputDir .. "/" .. config.pagesDir
    local pagesOutput = config.outputDir .. "/" .. config.pagesDir
    
    if pathExists(pagesInput) then
        mkdir(pagesOutput)
        local pageFiles = listDir(pagesInput)
        
        for _, file in ipairs(pageFiles) do
            local ext = getExtension(file)
            local relativePath = file:gsub(pagesInput .. "/", "")
            
            if ext == "lx" then
                local outputFile = pagesOutput .. "/" .. relativePath:gsub("%.lx$", ".lua")
                if compileLx(file, outputFile) then
                    log_success("Compilado: " .. relativePath)
                    table.insert(buildState.files, outputFile)
                end
            elseif ext == "lua" then
                local outputFile = pagesOutput .. "/" .. relativePath
                if copyFile(file, outputFile) then
                    log_success("Copiado: " .. relativePath)
                    table.insert(buildState.files, outputFile)
                end
            end
        end
    end
    print("")
    
    -- 2. Compila componentes .lx
    print(colorize("  🧩 Compilando componentes...", "bold"))
    local componentsInput = config.inputDir .. "/" .. config.componentsDir
    local componentsOutput = config.outputDir .. "/" .. config.componentsDir
    
    if pathExists(componentsInput) then
        mkdir(componentsOutput)
        local componentFiles = listDir(componentsInput)
        
        for _, file in ipairs(componentFiles) do
            local ext = getExtension(file)
            local relativePath = file:gsub(componentsInput .. "/", "")
            
            if ext == "lx" then
                local outputFile = componentsOutput .. "/" .. relativePath:gsub("%.lx$", ".lua")
                if compileLx(file, outputFile) then
                    log_success("Compilado: " .. relativePath)
                    table.insert(buildState.files, outputFile)
                end
            elseif ext == "lua" then
                local outputFile = componentsOutput .. "/" .. relativePath
                if copyFile(file, outputFile) then
                    log_success("Copiado: " .. relativePath)
                    table.insert(buildState.files, outputFile)
                end
            end
        end
    end
    print("")
    
    -- 3. Copia API (sem modificação)
    print(colorize("  🔌 Copiando APIs...", "bold"))
    local apiInput = config.inputDir .. "/" .. config.apiDir
    local apiOutput = config.outputDir .. "/" .. config.apiDir
    
    if pathExists(apiInput) then
        mkdir(apiOutput)
        local apiFiles = listDir(apiInput)
        
        for _, file in ipairs(apiFiles) do
            local relativePath = file:gsub(apiInput .. "/", "")
            local outputFile = apiOutput .. "/" .. relativePath
            
            if copyFile(file, outputFile) then
                log_success("Copiado: " .. relativePath)
                table.insert(buildState.files, outputFile)
            end
        end
    end
    print("")
    
    -- 4. Processa arquivos estáticos
    print(colorize("  📦 Processando assets...", "bold"))
    local publicInput = config.inputDir .. "/" .. config.publicDir
    local publicOutput = config.outputDir .. "/" .. config.publicDir
    
    if pathExists(publicInput) and config.copyStatic then
        mkdir(publicOutput)
        
        -- Coleta arquivos CSS para bundle
        local cssFiles = {}
        local jsFiles = {}
        local otherFiles = {}
        
        local staticFiles = listDir(publicInput)
        for _, file in ipairs(staticFiles) do
            local ext = getExtension(file)
            if ext == "css" then
                table.insert(cssFiles, file)
            elseif ext == "js" then
                table.insert(jsFiles, file)
            else
                table.insert(otherFiles, file)
            end
        end
        
        -- Bundle CSS
        if #cssFiles > 0 then
            local cssOutput = publicOutput .. "/css/bundle.css"
            mkdir(publicOutput .. "/css")
            
            if bundleCSS(cssFiles, cssOutput, config.minify) then
                local hash = config.hashAssets and ("." .. hashContent(readFile(cssOutput) or ""):sub(1, 8)) or ""
                local hashedPath = publicOutput .. "/css/bundle" .. hash .. ".css"
                
                if config.hashAssets then
                    os.rename(cssOutput, hashedPath)
                    cssOutput = hashedPath
                end
                
                log_success("CSS bundle: " .. (#cssFiles) .. " arquivo(s) → bundle" .. hash .. ".css")
                table.insert(buildState.assets, {
                    type = "css",
                    original = cssFiles,
                    output = cssOutput,
                    hash = hash,
                })
            end
        end
        
        -- Bundle JS
        if #jsFiles > 0 then
            local jsOutput = publicOutput .. "/js/bundle.js"
            mkdir(publicOutput .. "/js")
            
            if bundleJS(jsFiles, jsOutput, config.minify) then
                local hash = config.hashAssets and ("." .. hashContent(readFile(jsOutput) or ""):sub(1, 8)) or ""
                local hashedPath = publicOutput .. "/js/bundle" .. hash .. ".js"
                
                if config.hashAssets then
                    os.rename(jsOutput, hashedPath)
                    jsOutput = hashedPath
                end
                
                log_success("JS bundle: " .. (#jsFiles) .. " arquivo(s) → bundle" .. hash .. ".js")
                table.insert(buildState.assets, {
                    type = "js",
                    original = jsFiles,
                    output = jsOutput,
                    hash = hash,
                })
            end
        end
        
        -- Copia outros arquivos (imagens, fonts, etc)
        for _, file in ipairs(otherFiles) do
            local relativePath = file:gsub(publicInput .. "/", "")
            local outputFile = publicOutput .. "/" .. relativePath
            
            -- Não copia CSS/JS originais se bundlou
            local ext = getExtension(file)
            if ext ~= "css" and ext ~= "js" then
                if copyFile(file, outputFile) then
                    log_success("Copiado: " .. relativePath)
                end
            end
        end
    end
    print("")
    
    -- 5. Pré-renderização (SSG)
    if config.prerender and #config.prerender > 0 then
        print(colorize("  🖼️  Pré-renderizando páginas...", "bold"))
        mkdir(config.outputDir .. "/static")
        
        for _, route in ipairs(config.prerender) do
            local pageName = route == "/" and "index" or route:gsub("^/", "")
            local pagePath = config.inputDir .. "/" .. config.pagesDir .. "/" .. pageName .. ".lx"
            local outputPath = config.outputDir .. "/static/" .. pageName .. ".html"
            
            if pathExists(pagePath) then
                if prerenderPage(pagePath, outputPath, config) then
                    log_success("Pré-renderizado: " .. route .. " → " .. pageName .. ".html")
                end
            else
                log_warning("Página não encontrada para pré-render: " .. route)
            end
        end
        print("")
    end
    
    -- 6. Gera manifesto
    if config.generateManifest then
        print(colorize("  📋 Gerando manifesto...", "bold"))
        
        local manifest = {
            version = "1.0.0",
            buildTime = os.date(),
            buildTimestamp = os.time(),
            config = {
                minify = config.minify,
                hashAssets = config.hashAssets,
            },
            files = buildState.files,
            assets = buildState.assets,
            stats = {
                totalFiles = #buildState.files,
                totalAssets = #buildState.assets,
                errors = #buildState.errors,
                warnings = #buildState.warnings,
            }
        }
        
        -- Serializa manifesto
        local json = require("PudimWeb.utils.json")
        local manifestJson = json.encode(manifest)
        
        if writeFile(config.outputDir .. "/manifest.json", manifestJson) then
            log_success("Gerado: manifest.json")
        end
        print("")
    end
    
    -- 7. Gera server.lua para produção
    print(colorize("  🚀 Gerando servidor de produção...", "bold"))
    local serverContent = Builder.generateProductionServer(config)
    if writeFile(config.outputDir .. "/server.lua", serverContent) then
        log_success("Gerado: server.lua")
    end
    print("")
    
    -- Resultado final
    local elapsed = os.time() - buildState.startTime
    
    print(colorize("═══════════════════════════════════════════════════════════", "gray"))
    print("")
    
    if #buildState.errors > 0 then
        print(colorize("  ✗ Build completado com " .. #buildState.errors .. " erro(s)", "red"))
    else
        print(colorize("  ✓ Build completado com sucesso!", "green"))
    end
    
    print("")
    print("  📊 " .. colorize("Estatísticas:", "bold"))
    print("     • Arquivos processados: " .. #buildState.files)
    print("     • Assets gerados: " .. #buildState.assets)
    print("     • Warnings: " .. #buildState.warnings)
    print("     • Erros: " .. #buildState.errors)
    print("     • Tempo: " .. elapsed .. "s")
    print("")
    print("  📁 Output: " .. colorize(config.outputDir, "cyan"))
    print("")
    
    return {
        success = #buildState.errors == 0,
        files = buildState.files,
        assets = buildState.assets,
        errors = buildState.errors,
        warnings = buildState.warnings,
        elapsed = elapsed,
    }
end

--- Gera conteúdo do servidor de produção
function Builder.generateProductionServer(config)
    local pagesDir = config.pagesDir or "pages"
    local publicDir = config.publicDir or "public"
    local apiDir = config.apiDir or "api"
    
    local template = [=[
--[[
    PudimWeb Production Server
    Gerado automaticamente pelo PudimWeb Builder
    
    Execute com: lua server.lua
--]]

package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    "./lua_modules/share/lua/5.4/?.lua",
    "./lua_modules/share/lua/5.4/?/init.lua",
}, ";") .. ";" .. package.path

package.cpath = table.concat({
    "./lua_modules/lib/lua/5.4/?.so",
}, ";") .. ";" .. package.cpath

pcall(require, "luarocks.loader")

-- Em produção, arquivos já estão compilados (.lua)
-- Não precisa de DaviLuaXML runtime

local pudim = require("PudimWeb")

-- Configura renderer para produção
pudim.configureRenderer({
    autoInjectScripts = true,
    enableCache = true,
    cacheMaxAge = 3600,  -- 1 hora
})

-- Expõe globais
pudim.expose()

-- Inicia servidor
pudim.start({
    port = tonumber(os.getenv("PORT")) or 3000,
    host = os.getenv("HOST") or "0.0.0.0",
    pagesDir = "./{{PAGES_DIR}}",
    publicDir = "./{{PUBLIC_DIR}}",
    apiDir = "./{{API_DIR}}",
})
]=]
    
    template = template:gsub("{{PAGES_DIR}}", pagesDir)
    template = template:gsub("{{PUBLIC_DIR}}", publicDir)
    template = template:gsub("{{API_DIR}}", apiDir)
    
    return template
end

--- Build com configuração mínima (atalho)
function Builder.quickBuild(outputDir)
    return Builder.build({
        outputDir = outputDir or "./dist",
        minify = true,
    })
end

--- Limpa diretório de build
function Builder.clean(outputDir)
    outputDir = outputDir or "./dist"
    os.execute('rm -rf "' .. outputDir .. '"')
    print(colorize("  ✓ ", "green") .. "Diretório limpo: " .. outputDir)
end

--- Retorna configuração padrão
function Builder.getDefaultConfig()
    return defaultConfig
end

return Builder
