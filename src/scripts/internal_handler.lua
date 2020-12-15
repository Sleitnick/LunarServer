local Response = require("response")
local Request = require("request")

return function(handlerName, reqStr)
    local success, res = pcall(function()
        local req, r = Request.new(reqStr), Response.new()
        local handler = require(handlerName)
        handler(req, r)
        return r
    end)
    if (success) then
        return tostring(res)
    else
        print(("Server Error: %s"):format(tostring(res)))
        local resErr = Response.new()
        local accepts = reqStr:match("Accept: (.-)\n")
        local acceptsHtml = (accepts and accepts:find("text/html"))
        resErr:SetStatus(500, "Internal Server Error")
        if (acceptsHtml) then
            resErr:HTML("/src/html/500.html", {
                title = resErr.StatusText;
                status = resErr.Status;
                error = tostring(res);
            }):Send()
        else
            resErr:Text(resErr.StatusText):Send()
        end
        return tostring(resErr)
    end
end