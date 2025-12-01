# 🍮 Meu Projeto PudimWeb

Projeto criado com [PudimWeb](https://github.com/yourusername/PudimWeb).

## 📁 Estrutura

```
├── server.lua           # Entry point
├── app/
│   ├── layout.lx        # Global layout
│   ├── pages/           # File-based routing
│   │   ├── index.lx     # /
│   │   ├── about.lx     # /about
│   │   ├── docs.lx      # /docs
│   │   └── blog/
│   │       ├── index.lx # /blog
│   │       └── [id].lx  # /blog/:id
│   ├── api/             # API routes
│   │   ├── hello.lua    # /api/hello
│   │   └── users.lua    # /api/users
│   ├── components/      # Reusable components
│   └── public/          # Static files
```

## 🚀 Começando

```bash
# Iniciar servidor de desenvolvimento
lua server.lua

# Ou usando o CLI
pudim serve
```

O servidor estará disponível em `http://localhost:3000`.

## 📖 Documentação

Visite `/docs` no app para ver a documentação integrada.

## 🛠️ Comandos

```bash
pudim serve [port]  # Iniciar servidor
pudim build         # Build para produção
pudim clean         # Limpar arquivos de build
```

## 📝 Licença

MIT
