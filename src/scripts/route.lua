local Util = require("util")

local Route = {}
Route.__index = Route

function Route.new()
    local self = setmetatable({
        -- _req = request;
        -- _res = response;
        _pathCallbacks = {};
        _notFound = nil;
    }, Route)
    return self
end

function Route:On(path, callback, method)
    table.insert(self._pathCallbacks, {
        Path = path;
        Callback = callback;
        Method = method or "ANY";
        PathSplit = Util.StringSplit(path, "/");
    })
    return self
end

function Route:Get(path, callback)
    return self:On(path, callback, "GET")
end

function Route:NotFound(callback)
    self._notFound = callback
    return self
end

function Route:_checkPathMatch(path, pathSplit, routePath, routePathSplit, req)
    if (path == routePath or routePath == "*") then
        return true
    elseif (#pathSplit == #routePathSplit) then
        for i,p1 in ipairs(pathSplit) do
            local p2 = routePathSplit[i]
            if (not p2) then break end
            local capture = p2:match("%b{}")
            if (capture) then
                local captureName = capture:sub(2, -2):match("^%s*(.-)%s*$")
                if (captureName) then
                    if (not req.Params) then
                        req.Params = {[captureName] = p1}
                    else
                        req.Params[captureName] = p1
                    end
                else
                    return false
                end
            elseif (p1 ~= p2) then
                return false
            end
        end
        return true
    end
    return false
end

function Route:Run(req, res)
    local path = req.Path
    local pathSplit = Util.StringSplit(path, "/")
    local method = req.Method
    local callbacks = {}
    for _,p in ipairs(self._pathCallbacks) do
        if (p.Method == method or p.Method == "ANY") then
            if (self:_checkPathMatch(path, pathSplit, p.Path, p.PathSplit, req)) then
                table.insert(callbacks, p.Callback)
            end
        end
    end
    if (#callbacks > 0) then
        local index = 0
        local function Nxt()
            if (res._send) then return end
            index = (index + 1)
            if (index > #callbacks) then return end
            callbacks[index](req, res, Nxt)
        end
        Nxt()
    end
    if ((not res._send) and self._notFound) then
        res:SetStatus(404, "Not Found")
        self._notFound(req, res)
    end
end

return Route