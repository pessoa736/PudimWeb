#!/bin/bash
echo "🍮 Instalando dependências..."
luarocks install --tree lua_modules pudimweb
luarocks install --tree lua_modules daviluaxml
luarocks install --tree lua_modules loglua
luarocks install --tree lua_modules luasocket
echo "✓ Pronto! Execute: lua server.lua"
