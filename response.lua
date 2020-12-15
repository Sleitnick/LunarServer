local Response = {}
Response.__index = Response

function Response.new()
    local self = setmetatable({
        Headers = {};
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
    local headers = {}
    for k,v in pairs(self.Headers) do
        table.insert(headers, ("%s: %s"):format(k, v))
    end
    return ("HTTP/1.1 %i%s\nContent-Length: %i\n%s\n\n%s"):format(
        self.Status,
        self.StatusText and " " .. self.StatusText or "",
        string.len(self.Body or ""),
        table.concat(headers, "\n"),
        self.Body
    )
end

return Response