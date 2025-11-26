# test

Projeto criado com [PudimWeb](https://github.com/pessoa736/PudimWeb) 🍮

## Estrutura (estilo Next.js)

```
test/
├── server.lua        # Ponto de entrada
├── app/
│   ├── pages/        # Rotas automáticas
│   │   ├── index.lx  # → /
│   │   └── about.lx  # → /about
│   ├── api/          # API Routes
│   │   └── hello.lua # → /api/hello
│   ├── components/   # Componentes
│   └── public/       # Arquivos estáticos
└── lua_modules/      # Dependências
```

## Instalação

```bash
./install.sh
```

## Executar

```bash
lua server.lua
```

Acesse: http://localhost:3000
