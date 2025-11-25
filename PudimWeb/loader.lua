require("luaXML")
require("PudimWeb.taghtml")

local page = require("app.Pages.index")


return html.body({},page())
