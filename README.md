# PudimWeb

> **Status: being rewritten from scratch.** The code currently in this repository is the old version (December 2025) and will be replaced. The new version is still in the planning stage: nothing below the "Planned direction" section is final.
>
> **Note:** I'm now building another web framework, [Action-Chainsaw](https://github.com/pessoa736/Action-Chainsaw), on DSLX with [Pegasus](https://github.com/EvandroLG/pegasus.lua) as its web server. Because of it, the plan below may change.

A web framework for **Lua 5.4**, inspired by **React / Next.js**: pages and components written in Lua with JSX-like markup, routed by the file system.

## Planned direction (rewrite)

- **Markup with [DSLX](https://github.com/pessoa736/DLuaXML).** DSLX is my JSX-like layer for Lua (the successor of DaviLuaXML, rewritten on LPeg). The rewrite will be built on it and on `.dslx` files, instead of the old `.lx` files.
- **Hosting handled by Docker (probably).** Instead of the framework doing all the server work itself, the idea is to leave the hosting side to a Docker setup. This is still being planned.
- Everything else (API, project layout, CLI, how rendering works) will be redesigned, so the old documentation is not kept here.

## The old version

What is in `main` today is the first implementation, kept until the rewrite replaces it:

- file-based routing (`app/pages`, dynamic routes like `[id].lx`) and API routes (`app/api`)
- functional components and React-style hooks (`useState`, `useEffect`, `useMemo`, `useContext`)
- a virtual DOM, reconciler, server renderer and client bundle builder
- static files, an HTTP server on LuaSocket, and a `pudim` CLI that scaffolds projects
- `.lx` files through DaviLuaXML 1.x

It was published on LuaRocks as [`pudimweb`](https://luarocks.org/modules/pessoa736/pudimweb) (last release `1.0-3`). It is no longer maintained: install it only if you want to look at the old approach.

```bash
luarocks install pudimweb 1.0-3
```

## License

MIT. See [LICENSE](LICENSE).

---

Made by [pessoa736](https://github.com/pessoa736)
