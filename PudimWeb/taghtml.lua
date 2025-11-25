local pr = require("luaXML.props")

local get_all_childrens = function (childrens)
    local str = ""
    for idx, children in ipairs(childrens) do
        str = str .. children
    end
    
    return str
end

local tmpTag = function(name, props, childrens) 
  local props = props or {}
  local props = childrens or {}
  
  if type(props)~="table" then error("props expected be table") end
 
  local str = "<"..name.." ".. pr.tableToPropsString(props) .." >" ..
      get_all_childrens(childrens) ..
  "</"..name..">"
  
  print(str)
  return str
end



local tagsnames = {
  "html","head","body","title",
  "div","span","p","a","img","button","input","label","form",
  "section","article","header","footer","nav","main",
  "ul","ol","li",
  "table","thead","tbody","tr","td","th",
  "script","style","meta","link",
  "h1","h2","h3","h4","h5","h6"
}

_G.html={}
for k, tag in ipairs(tagsnames) do
  _G.html[tag] = function (s, props, childrens)
    return  tmpTag(tag, props or {}, childrens or {})
  end
end


