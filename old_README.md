# 🍮 PudimWeb

Framework web para **Lua 5.4** inspirado em **React/Next.js**.

[![Lua](https://img.shields.io/badge/Lua-5.4-blue.svg)](https://www.lua.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ✨ Características

- 📁 **File-based routing** - Rotas automáticas baseadas em arquivos (estilo Next.js)
- 🧩 **Componentes** - Componentes funcionais com props e children (estilo React)
- 🪝 **Hooks** - useState, useEffect, useMemo, useContext
- 🔌 **API Routes** - Endpoints HTTP em arquivos separados
- 📄 **Arquivos .lx** - Sintaxe JSX-like via DaviLuaXML
- 🎨 **Arquivos estáticos** - Servir CSS, JS, imagens automaticamente
- 🛠️ **CLI** - Ferramenta para criar e gerenciar projetos

## 📦 Instalação

### Via LuaRocks

```bash
luarocks install pudimweb
```

### Manual

```bash
git clone https://github.com/pessoa736/PudimWeb.git
cd PudimWeb
luarocks make rockspecs/pudimweb-dev-2.rockspec
```

## 🚀 Início Rápido

### Criar um novo projeto

```bash
pudim new meu-projeto
cd meu-projeto
./install.sh
lua server.lua
```

Acesse: http://localhost:3000

## 📁 Estrutura do Projeto

```
meu-projeto/
├── server.lua           # Ponto de entrada
├── app/
│   ├── pages/           # Rotas automáticas
│   │   ├── index.lx     # → /
│   │   ├── about.lx     # → /about
│   │   └── blog/
│   │       ├── index.lx # → /blog
│   │       └── [id].lx  # → /blog/:id (rota dinâmica)
│   ├── api/             # API Routes
│   │   └── hello.lua    # → /api/hello
│   ├── components/      # Componentes reutilizáveis
│   │   └── Button.lx
│   └── public/          # Arquivos estáticos
│       ├── css/
│       ├── js/
│       └── images/
└── lua_modules/         # Dependências
```

## 📝 Exemplos

### Página Básica (app/pages/index.lx)

```lua
-- Aliases para tags HTML
local Html, Head, Body = html.html, html.head, html.body
local Div, H1, P = html.div, html.h1, html.p

local function Home()
    return html.doctype .. <Html lang="pt-BR">
        <Head>
            <html.title>Meu Site</html.title>
        </Head>
        <Body>
            <Div class="container">
                <H1>Olá, PudimWeb!</H1>
                <P>Bem-vindo ao meu site.</P>
            </Div>
        </Body>
    </Html>
end

return Home
```

### Componente Reutilizável (app/components/Card.lx)

```lua
local Div, H2, P = html.div, html.h2, html.p

local Card = component(function(props, children)
    return <Div class="card">
        <H2>{props.title}</H2>
        <P>{children}</P>
    </Div>
end)

return Card
```

### API Route (app/api/users.lua)

```lua
return {
    GET = function(req, res)
        res.json({
            users = {"Alice", "Bob", "Carol"}
        })
    end,
    
    POST = function(req, res)
        local name = req.body.name
        res.json({
            message = "Usuário criado: " .. name
        })
    end,
}
```

### Rota Dinâmica (app/pages/blog/[id].lx)

```lua
local Div, H1, P = html.div, html.h1, html.p

local function BlogPost(req)
    local id = req.params.id
    
    return html.doctype .. <Div>
        <H1>Post #{id}</H1>
        <P>Conteúdo do post...</P>
    </Div>
end

return BlogPost
```

## 🪝 Hooks

### useState

```lua
local count, setCount = useState(0)
setCount(count + 1)
```

### useEffect

```lua
useEffect(function()
    print("Componente montado!")
    return function()
        print("Componente desmontado!")
    end
end, {})
```

### useMemo

```lua
local doubled = useMemo(function()
    return value * 2
end, {value})
```

### useContext

```lua
local ThemeContext = createContext("light")

-- No componente pai
<ThemeContext.Provider value="dark">
    {children}
</ThemeContext.Provider>

-- No componente filho
local theme = useContext(ThemeContext)
```

## ⚙️ Configuração do Servidor

```lua
-- server.lua
require("DaviLuaXML")
local pudim = require("PudimWeb")

pudim.expose()  -- Expõe globais (html, component, hooks)

pudim.start({
    port = 3000,              -- Porta do servidor
    host = "127.0.0.1",       -- Host
    pagesDir = "./app/pages", -- Diretório de páginas
    publicDir = "./app/public", -- Arquivos estáticos
    apiDir = "./app/api",     -- API Routes
})
```

## 🛠️ CLI

```bash
# Criar novo projeto
pudim new <nome-do-projeto>

# Iniciar servidor
pudim serve [porta]

# Ajuda
pudim help
```

## 📚 Dependências

- [Lua 5.4](https://www.lua.org/)
- [LuaSocket](https://github.com/lunarmodules/luasocket)
- [DaviLuaXML](https://github.com/pessoa736/DaviLuaXML)
- [loglua](https://github.com/pessoa736/loglua)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🙏 Agradecimentos

- Inspirado por [React](https://react.dev/) e [Next.js](https://nextjs.org/)
- Comunidade Lua

---

Feito com 🍮 por [pessoa736](https://github.com/pessoa736)
