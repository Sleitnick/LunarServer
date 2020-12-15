-- Run the server

local LuaServer = require("luaserver")

local server = LuaServer.new("handler")

server:Listen(8080, function()
    print("Server listening")
end)
