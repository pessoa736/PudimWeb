# PudimWeb - Copilot Instructions

Este é o PudimWeb, um framework web para Lua 5.4 inspirado em React/Next.js.

## Estrutura do Projeto

```
PudimWeb/
├── PudimWeb/           # Código fonte do framework
│   ├── init.lua        # Módulo principal
│   ├── router.lua      # Sistema de rotas
│   ├── core/           # Componentes, hooks, file router, vdom, reconciler
│   ├── html/           # Gerador de tags HTML
│   ├── http/           # Request, Response, Server
│   ├── middleware/     # Static files middleware
│   └── utils/          # JSON utils
├── bin/                # CLI (pudim)
├── rockspecs/          # Configurações do LuaRocks
└── test/               # Projeto de teste
```

## Dependências

- **Lua >= 5.4**
- **DaviLuaXML** - Permite usar sintaxe XML dentro de código Lua
- **loglua** - Sistema de logging modular
- **luasocket** - Sockets para servidor HTTP

---

## DaviLuaXML - Referência Rápida

DaviLuaXML é uma biblioteca que permite usar sintaxe XML dentro de código Lua.
As tags XML são transformadas em chamadas de função Lua.

### Início Rápido

```lua
-- 1. Carregue o DaviLuaXML no início do programa
require("DaviLuaXML")

-- 2. Agora você pode usar require() com arquivos .lx
local App = require("meu_componente")  -- carrega meu_componente.lx
```

### Sintaxe XML Suportada

#### Tags Básicas
```lua
-- Tag self-closing (sem conteúdo)
<MinhaTag/>

-- Tag com conteúdo
<MinhaTag>conteúdo aqui</MinhaTag>

-- Tags aninhadas
<Pai>
    <Filho>texto</Filho>
</Pai>
```

#### Atributos
```lua
-- Strings
<Tag nome="valor"/>

-- Sem aspas (valores simples)
<Tag ativo=true count=5/>

-- Expressões Lua em chaves
<Tag valor={10 + 5} lista={minhaTabela}/>
```

#### Expressões em Conteúdo
```lua
-- Expressões Lua dentro de tags
<Tag>{variavel}</Tag>
<Tag>{1 + 2 + 3}</Tag>
<Tag>{"string"}</Tag>

-- Múltiplas expressões
<Lista>{item1}{item2}{item3}</Lista>
```

#### Nomes com Ponto
```lua
-- Acesso a módulos/namespaces
<html.div class="container"/>
<ui.Button onClick={handler}/>
```

### Transformação

O código XML é transformado em chamadas de função:

```lua
-- Entrada:
<Tag prop="valor">texto</Tag>

-- Saída (Lua puro):
Tag({prop = 'valor'}, {[1] = 'texto'})

-- A função recebe: (props, children)
```

### Estrutura de Projeto com .lx

```
projeto/
    main.lua          -- require("DaviLuaXML") aqui
    config.lx
    components/
        App.lx
        Button.lx
```

### Módulos DaviLuaXML

| Módulo | Descrição |
|--------|-----------|
| `DaviLuaXML` | Registra searcher para require() de arquivos .lx |
| `DaviLuaXML.parser` | Converte strings XML em tabelas Lua |
| `DaviLuaXML.transform` | Converte código Lua+XML em código Lua puro |
| `DaviLuaXML.elements` | Criação de elementos programaticamente |
| `DaviLuaXML.props` | Conversão entre tabelas Lua e strings de atributos XML |
| `DaviLuaXML.errors` | Sistema de erros formatados |
| `DaviLuaXML.core` | Carregamento direto de arquivos .lx |

---

## LogLua - Referência Rápida

LogLua é um sistema de logging modular para Lua com suporte a seções, modo live e cores ANSI.

### Logging Básico

```lua
log("mensagem")              -- Adiciona log (atalho)
log.add("mensagem")          -- Adiciona log
log.debug("mensagem")        -- Adiciona debug (requer debugMode)
log.error("mensagem")        -- Adiciona erro
```

### Sistema de Seções

Seções permitem organizar logs por categoria (network, database, etc).

```lua
-- Método 1: log.section()
log.add(log.section("network"), "conectando...")
log.error(log.section("database"), "query falhou")

-- Método 2: log.inSection() - cria logger vinculado
local net = log.inSection("network")
net("mensagem 1")
net("mensagem 2")
net.error("falhou!")

-- Método 3: Seção padrão
log.setDefaultSection("game")
log("player spawned")  -- vai para seção "game"
```

### Exibição e Filtros

```lua
log.show()                   -- Mostra todos os logs
log.show("section")          -- Filtra por seção
log.show({"a", "b"})         -- Filtra por múltiplas seções
```

### Modo Live (Tempo Real)

```lua
log.live()                   -- Ativa modo live
log.unlive()                 -- Desativa modo live
log.isLive()                 -- Verifica se modo live está ativo

-- Exemplo de uso
log.live()
while running do
    log("evento aconteceu")
    log.show()              -- mostra só os novos logs
    sleep(1)
end
log.unlive()
```

### Salvamento

```lua
log.save()                   -- Salva em "log.txt"
log.save("./", "app.log")    -- Salva em arquivo específico
log.save("./", "net.log", "network")  -- Salva filtrado por seção
```

### Configuração

```lua
log.enableColors()           -- Habilita cores ANSI
log.disableColors()          -- Desabilita cores
log.activateDebugMode()      -- Ativa modo debug
log.deactivateDebugMode()    -- Desativa modo debug
log.clear()                  -- Limpa todos os logs
```

### API Completa do LogLua

| Função | Descrição |
|--------|-----------|
| `log(...)` | Atalho para log.add(...) |
| `log.add(...)` | Adiciona mensagem de log |
| `log.debug(...)` | Adiciona mensagem de debug |
| `log.error(...)` | Adiciona mensagem de erro |
| `log.section(name)` | Cria tag de seção |
| `log.inSection(name)` | Cria logger para seção específica |
| `log.setDefaultSection(name)` | Define seção padrão |
| `log.getDefaultSection()` | Retorna seção padrão atual |
| `log.getSections()` | Lista todas as seções usadas |
| `log.show([filter])` | Exibe logs (filtro opcional) |
| `log.save([dir], [name], [flt])` | Salva logs em arquivo |
| `log.live()` | Ativa modo live (tempo real) |
| `log.unlive()` | Desativa modo live |
| `log.isLive()` | Verifica se modo live está ativo |
| `log.enableColors()` | Habilita cores ANSI |
| `log.disableColors()` | Desabilita cores |
| `log.hasColors()` | Verifica se cores estão ativas |
| `log.activateDebugMode()` | Ativa modo debug |
| `log.deactivateDebugMode()` | Desativa modo debug |
| `log.checkDebugMode()` | Verifica estado do debug mode |
| `log.clear()` | Limpa logs e contadores |

---

## PudimWeb - API do Framework

### Componentes

Os componentes PudimWeb recebem `(props, children)` como argumentos separados:

```lua
-- Criando um componente
local Button = component(function(props, children)
    local class = props.class or "btn"
    return <button class={class}>{children}</button>
end)

-- Usando o componente
<Button class="primary">Clique aqui</Button>
```

**IMPORTANTE**: O `children` já vem como string renderizada, não como tabela.

### Integração com DaviLuaXML Middleware

O módulo `components` registra automaticamente um middleware no DaviLuaXML que:
1. Converte a tabela `children` para string concatenada
2. Permite que componentes recebam `children` como string diretamente

```lua
-- O middleware é registrado automaticamente ao carregar o módulo
local Components = require("PudimWeb.core.components")

-- Ou ao usar PudimWeb
local PudimWeb = require("PudimWeb")
PudimWeb.expose()  -- Expõe component(), html, etc. como globais

-- Agora os componentes funcionam transparentemente com DaviLuaXML
local Card = component(function(props, children)
    -- children já é uma string!
    return html.div({ class = "card" }, children)
end)
```

Para forçar re-registro do middleware (em casos especiais):

```lua
local Components = require("PudimWeb.core.components")
Components._middlewareRegistered = false
Components.setupMiddleware()
```

### HTML Tags

Todas as tags HTML5 são suportadas através do módulo `html`:

```lua
local html = require("PudimWeb.html")

-- Tags recebem (props, children)
html.div({ class = "container" }, "Conteúdo")
-- <div class="container">Conteúdo</div>

-- Tags self-closing
html.img({ src = "foto.jpg", alt = "Foto" })
-- <img src="foto.jpg" alt="Foto" />
```

### Aliases para DaviLuaXML

Como DaviLuaXML não suporta "." em tags, use aliases:

```lua
local Html, Head, Body = html.html, html.head, html.body
local Div, H1, P = html.div, html.h1, html.p

return <Html>
    <Head><Title>Meu App</Title></Head>
    <Body>
        <Div class="container">
            <H1>Olá Mundo</H1>
        </Div>
    </Body>
</Html>
```

### Hooks

```lua
local useState = PudimWeb.useState
local useEffect = PudimWeb.useEffect
local useMemo = PudimWeb.useMemo
local useContext = PudimWeb.useContext
local createContext = PudimWeb.createContext
```

### Virtual DOM (VDom) e Tree Diffing

Sistema de Virtual DOM inspirado no React para renderização eficiente.
Detecta mudanças entre renderizações e gera apenas os patches necessários.

#### Criando VNodes

```lua
local vdom = require("PudimWeb.core.vdom")

-- Criar elementos virtuais
local tree = vdom.h("div", { class = "container" }, {
    vdom.h("h1", {}, "Título"),
    vdom.h("p", { id = "texto" }, "Conteúdo")
})

-- Renderizar para HTML
local html = vdom.render(tree)
-- <div class="container"><h1>Título</h1><p id="texto">Conteúdo</p></div>
```

#### Calculando Diferenças (Diff)

```lua
-- Árvore original
local tree1 = vdom.h("div", {}, {
    vdom.h("p", {}, "Texto original")
})

-- Árvore modificada
local tree2 = vdom.h("div", {}, {
    vdom.h("p", {}, "Texto modificado")
})

-- Calcular patches
local patches = vdom.diff(tree1, tree2)
-- patches contém apenas a mudança: TEXT "Texto original" -> "Texto modificado"
```

#### Usando o Reconciler

```lua
local reconciler = require("PudimWeb.core.reconciler")

-- Criar componente
local function App(props)
    return vdom.h("div", { class = "app" }, {
        vdom.h("h1", {}, props.title),
        vdom.h("p", {}, props.content)
    })
end

-- Criar raiz da aplicação
local root = reconciler.createRoot(App)

-- Primeira renderização
local html = root:render({ title = "Olá", content = "Mundo" })

-- Atualização (gera patches mínimos)
local patches = root:update({ title = "Olá", content = "Mundo Atualizado" })

-- Verificar mudanças
if root:hasChanges() then
    print("Mudanças: " .. root:getChangeCount())
end

-- Gerar script JavaScript para atualização no cliente
local script = root:getUpdateScript()
```

#### Tipos de Patches

| Tipo | Descrição |
|------|-----------|
| `REPLACE` | Substitui nó inteiro |
| `PROPS` | Atualiza propriedades |
| `TEXT` | Atualiza texto |
| `INSERT` | Insere novo nó |
| `REMOVE` | Remove nó |
| `REORDER` | Reordena filhos |

#### API VDom

| Função | Descrição |
|--------|-----------|
| `vdom.h(tag, props, children)` | Cria VNode (elemento virtual) |
| `vdom.createTextNode(text)` | Cria nó de texto |
| `vdom.diff(oldTree, newTree)` | Calcula diferenças entre árvores |
| `vdom.render(vnode)` | Renderiza VNode para HTML |
| `vdom.generateUpdateScript(patches)` | Gera JavaScript de atualização |
| `vdom.inspect(vnode)` | Debug: mostra árvore formatada |
| `vdom.countNodes(vnode)` | Conta nós na árvore |
| `vdom.cacheTree(key, tree)` | Armazena árvore no cache |
| `vdom.getCachedTree(key)` | Obtém árvore do cache |

#### API Reconciler

| Função | Descrição |
|--------|-----------|
| `reconciler.createRoot(component)` | Cria raiz da aplicação |
| `root:render(props)` | Renderiza componente |
| `root:update(props)` | Atualiza e calcula patches |
| `root:hasChanges()` | Verifica se houve mudanças |
| `root:getChangeCount()` | Número de mudanças |
| `root:getUpdateScript()` | Script JS de atualização |
| `root:getHTML()` | HTML renderizado |
| `root:getPatches()` | Lista de patches |
| `root:inspect()` | Debug da árvore |

### Servidor

```lua
local pudim = require("PudimWeb")

pudim.start({
    port = 3000,
    host = "127.0.0.1",
    pagesDir = "./app/pages",
    publicDir = "./app/public",
    apiDir = "./app/api",
    componentsDir = "./app/components",
})
```

### Estrutura de Projeto PudimWeb

```
app/
├── pages/           # Rotas automáticas (como Next.js)
│   ├── index.lx     # → /
│   ├── about.lx     # → /about
│   └── blog/
│       ├── index.lx # → /blog
│       └── [id].lx  # → /blog/:id (rota dinâmica)
├── api/             # API Routes
│   └── users.lua    # → /api/users
├── components/      # Componentes reutilizáveis
├── public/          # Arquivos estáticos
└── layout.lx        # Layout global
```

---

## Comandos Úteis

```bash
# Instalar dependências do projeto
luarocks make rockspecs/pudimweb-dev-4.rockspec --local

# Instalar no diretório do projeto de teste
cd /caminho/projeto && luarocks make ../rockspecs/pudimweb-dev-4.rockspec --tree ./lua_modules

# Rodar servidor de teste
cd test && lua ./server.lua
```

---

## Workflow de Desenvolvimento

### Ao implementar uma nova feature

#### Antes
- Sempre verifique se as versões das dependências estão corretas e são as mais recentes

#### Depois
- Faça testes, e se der tudo certo, atualize a documentação e faça upload

---

## Upload / Release

1. Fazer os commits separados, com base nos commits anteriores
2. Os commits tem que ser informal, num parágrafo só
3. Atualizar o rockspec
4. Colocar a tag como a versão que está no rockspec
5. Fazer upload no luarocks
6. Fazer a sync ou push no github

---

## Tags de Versão

Padrão: `x.y-z`

| Situação | Ação |
|----------|------|
| Feature adicionada | `x.(y+1)-z` |
| Bugs corrigidos | `x.y-(z+1)` |

Exemplo:
- Versão atual: `1.2-3`
- Nova feature: `1.3-3`
- Bug fix: `1.2-4`
