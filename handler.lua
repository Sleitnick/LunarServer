-- Handle requests

local Route = require("route")

return function(request, response)
    Route.new(request, response)
        :On("*", function(req, res, nxt)
            print("LOGGER!", req.Path)
            nxt()
        end)
        :Get("/", function(req, res)
            res:HTML("test.html", {
                message = "Hello from Lua! Wow! Hello",
                path = req.Path
            }):Send()
        end)
        :Get("/test", function(req, res)
            res:HTML("test.html", {
                message = "This is another page. "  .. ("ABC is " .. (req.Query.abc or "N/A")),
                path = req.Path
            }):Send()
        end)
        :Get("/test/{Message}/{Another}", function(req, res)
            res:HTML("test.html", {
                message = "This is another page: " .. req.Params.Message .. ", " .. req.Params.Another,
                path = req.Path
            }):Send()
        end)
        :On("/test", function(req, res, nxt)
            res:HTML("test.html", {
                message = "This is another page",
                path = req.Path
            }):Send()
        end)
        :NotFound(function(req, res)
            if (req:Accepts("text/html")) then
                res:HTML("404.html", {
                    path = req.Path
                }):Send()
            else
                res:Text("Not Found: " .. req.Path):Send()
            end
        end)
        :Run()
end
