local Headers = require("headers")

local Response = {}
Response.__index = Response

function Response.new()
    local self = setmetatable({
        Headers = Headers.new();
        Status = 200;
        StatusText = "OK";
        Body = "";
        _send = false;
    }, Response)
    return self
end

function Response:HTML(filepath, format)
    local file = io.open(filepath, "r")
    assert(file, "Failed to open " .. filepath)
    local content = file:read("*a")
    file:close()
    if (type(format) == "table") then
        content = content:gsub("%b{}", function(s)
            local capture = s:sub(3, -3)
            if (capture) then
                local key = capture:match("^%s*(.-)%s*$")
                if (key) then
                    return format[key]
                end
            end
        end)
    end
    self.Body = content
    self.Headers["Content-Type"] = "text/html"
    return self
end

function Response:Text(text)
    self.Body = text
    self.Headers["Content-Type"] = "text/plain"
    return self
end

function Response:SetStatus(statusCode, text)
    self.Status = statusCode
    self.StatusText = (text or "")
    return self
end

function Response:Send()
    self._send = true
end

function Response:__tostring()
    self.Headers:SetIfNil("Content-Type", "text/plain")
    self.Headers:Set("Content-Length", #(self.Body or ""))
    self.Headers:Set("Server", "LunarServer")
    self.Headers:Set("Date", os.date("%a, %d %b %Y %X GMT"))
    local res = ("HTTP/1.1 %i%s\n%s\n\n%s\n"):format(
        self.Status,
        self.StatusText and " " .. self.StatusText or "",
        tostring(self.Headers),
        self.Body
    )
    print("RESPONSE:\n" .. res)
    return res
end

return Response