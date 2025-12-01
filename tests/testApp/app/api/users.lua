-- API Route: /api/users
-- RESTful users endpoint

local json = require("PudimWeb.utils.json")

-- Mock database
local users = {
    { id = 1, name = "Alice", email = "alice@email.com" },
    { id = 2, name = "Bob", email = "bob@email.com" },
    { id = 3, name = "Carol", email = "carol@email.com" }
}

return {
    -- GET /api/users - List all users
    GET = function(req, res)
        res:json({
            users = users,
            count = #users
        })
    end,
    
    -- POST /api/users - Create user
    POST = function(req, res)
        local body = req.body or {}
        
        if not body.name or not body.email then
            res:status(400):json({
                error = "name and email are required"
            })
            return
        end
        
        local newUser = {
            id = #users + 1,
            name = body.name,
            email = body.email
        }
        table.insert(users, newUser)
        
        res:status(201):json({
            message = "User created",
            user = newUser
        })
    end
}
