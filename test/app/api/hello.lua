-- app/api/hello.lua
-- Rota: /api/hello

return {
    GET = function(req, res)
        res.json({
            message = "Hello from PudimWeb API!",
            timestamp = os.date(),
        })
    end,
    
    POST = function(req, res)
        res.json({
            message = "POST recebido!",
            body = req.body,
        })
    end,
}
