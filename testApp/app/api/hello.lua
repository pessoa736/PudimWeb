-- API Route: /api/hello
-- Returns JSON data

local json = require("PudimWeb.utils.json")

return {
    -- GET /api/hello
    GET = function(req, res)
        res:json({
            message = "Ola do PudimWeb!",
            timestamp = os.time(),
            method = "GET"
        })
    end,
    
    -- POST /api/hello
    POST = function(req, res)
        local body = req.body or {}
        res:json({
            message = "Dados recebidos!",
            received = body,
            method = "POST"
        })
    end
}
