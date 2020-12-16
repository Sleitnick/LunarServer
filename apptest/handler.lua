-- Handle requests

print("------ LOADED HANDLER ------")

local route = require("route").new()
	:On("*", function(_req, _res, nxt)
		--print("LOGGER!", req.Path)
		nxt()
	end)
	:Static("/static", "./public")
	:Get("/", function(req, res)
		res:HTML("html/test.html", {
			message = "Hello from Lua! Wow! Hello",
			path = req.Path
		}):Send()
	end)
	:Get("/test", function(req, res)
		error("Oh no!")
		res:HTML("html/test.html", {
			message = "This is another page. "  .. ("ABC is " .. (req.Query.abc or "N/A")),
			path = req.Path
		}):Send()
	end)
	:Get("/test/{Message}/{Another}", function(req, res)
		res:HTML("html/test.html", {
			message = "This is another page: " .. req.Params.Message .. ", " .. req.Params.Another,
			path = req.Path
		}):Send()
	end)
	:On("/test", function(req, res, _nxt)
		res:HTML("html/test.html", {
			message = "This is another page",
			path = req.Path
		}):Send()
	end)
	:NotFound(function(req, res)
		if (req:Accepts("text/html")) then
			res:HTML("html/404.html", {
				path = req.Path
			}):Send()
		else
			res:Text("Not Found: " .. req.Path):Send()
		end
	end)

return function(request, response)
	route:Run(request, response)
end
