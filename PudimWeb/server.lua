



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
local socket = require("socket")



-- server
local server = assert(socket.bind("127.0.0.1", 9001))
print("Servidor Lua 5.4 rodando na porta 9000")

local page = require("PudimWeb.loader")
print("pagina: ", page)

while true do
  local client = server:accept()
  client:settimeout(1)
  local line = client:receive("*l")

  -- Aqui você pode fazer lógica de rota simples:
  local body =  page
  local response = 
  "HTTP/1.1 200 OK\r\n" ..
   "Content-Type: text/html\r\n" ..
   "Content-Length: " .. #body .. "\r\n" ..
   "\r\n" ..
   body

  client:send(response)
  client:close()
end
