-- Run the server
--package.cpath = (package.cpath .. ";/lib/?.so")

local LuaServer = require("luaserver")

return function(config)
	local server = LuaServer.new(config.Handler)
	local port = tonumber(config.Port) or 8080
	server:Listen(port, function()
		print(("Server listening on port %i"):format(port))
	end)
end
