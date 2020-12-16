local Response = require("response")
local Request = require("request")

return function(handlerName, reqStr)
	local resTxt
	local success, result = pcall(function()
		local req, res = Request.new(reqStr), Response.new()
		local handler = require(handlerName)
		handler(req, res)
		return res
	end)
	if (success) then
		resTxt = tostring(result)
	else
		print(("Server Error: %s"):format(tostring(result)))
		local resErr = Response.new()
		local accepts = reqStr:match("Accept: (.-)\n")
		local acceptsHtml = (accepts and accepts:find("text/html"))
		resErr:SetStatus(500, "Internal Server Error")
		if (acceptsHtml) then
			resErr:HTML("/src/html/500.html", {
				title = resErr.StatusText;
				status = resErr.Status;
				error = tostring(result);
			}):Send()
		else
			resErr:Text(resErr.StatusText):Send()
		end
		resTxt = tostring(resErr)
	end
	return resTxt, #resTxt
end