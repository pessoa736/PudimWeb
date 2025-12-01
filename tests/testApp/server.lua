-- Server configuration for PudimWeb
require("DaviLuaXML")
local pudim = require("PudimWeb")

-- Expose PudimWeb globals (component, html, etc.)
pudim.expose()

-- Start the server
pudim.start({
    port = 3000,
    host = "127.0.0.1",
    pagesDir = "./app/pages",
    publicDir = "./app/public",
    apiDir = "./app/api",
    componentsDir = "./app/components"
})
