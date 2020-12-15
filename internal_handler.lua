local Response = require("response")
local Request = require("request")

return function(handlerName, reqStr)
    local success, res = pcall(function()
        local req, res = Request.new(reqStr), Response.new()
        local handler = require(handlerName)
        handler(req, res)
        return res
    end)
    if (success) then
        return tostring(res)
    else
        local resErr = Response.new()
        local accepts = reqStr:match("Accept: (.-)\n")
        local acceptsHtml = (accepts and accepts:find("text/html"))
        resErr:SetStatus(500, "Internal Server Error")
        if (acceptsHtml) then
            resErr:HTML("500.html", {
                title = resErr.StatusText;
                status = resErr.Status;
                error = (tostring(res)):gsub("\n", "<br/>");
                request = reqStr:gsub("\n", "<br/>");
            }):Send()
        else
            resErr:Text(resErr.StatusText):Send()
        end
        return tostring(resErr)
    end
end