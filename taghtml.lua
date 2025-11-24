local pr = require("luaXML.props")

local get_all_childrens = function (childrens)
    local str = ""
    for idx, children in ipairs(childrens) do
        str = str .. children
    end
    
    return str
end

local tmpTag = function(name, props, childrens) 
    return
    "<"..name.." ".. pr.tableToPropsString(props) .." >" ..
        get_all_childrens(childrens) ..
    "</"..name..">"
end

local main = function (props, childrens) return  tmpTag("main", props, childrens) end
local div = function(props, childrens) return tmpTag("div", props, childrens) end



return main, div