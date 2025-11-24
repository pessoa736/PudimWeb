



-- Ajuste de ambiente para encontrar módulos instalados em lua_modules
pcall(require, "luarocks.loader")
local rel_paths = {
  "./lua_modules/share/lua/5.4/?.lua",
  "./lua_modules/share/lua/5.4/?/init.lua"
}
package.path = table.concat(rel_paths, ";") .. ";" .. package.path
local rel_cpaths = {
  "./lua_modules/lib/lua/5.4/?.so"
}
package.cpath = table.concat(rel_cpaths, ";") .. ";" .. package.cpath



-- imports
local luaXML = require("luaXML")
local socket = require("socket")
local main, div = require("taghtml")


-- server
local server = assert(socket.bind("127.0.0.1", 9000))
print("Servidor Lua 5.4 rodando na porta 9000")


while true do
  local client = server:accept()
  client:settimeout(1)
  local line = client:receive("*l")

  -- Aqui você pode fazer lógica de rota simples:
  local body = '<html><body><a href="google.com">Hello from Lua 5.4!</a></body></html>'
  local response = "HTTP/1.1 200 OK\r\n" ..
                   "Content-Type: text/html\r\n" ..
                   "Content-Length: " .. #body .. "\r\n" ..
                   "\r\n" ..
                   body

  client:send(response)
  client:close()
end
