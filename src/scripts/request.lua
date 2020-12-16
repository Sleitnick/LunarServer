local Util = require("util")
local Headers = require("headers")

local Request = {}
Request.__index = Request

function Request.new(reqStr)
	local method, path, httpVersion, remaining, body = reqStr:match("(%w+) (.+) (HTTP/.-)\n(.-)\n\n(.*)")
	if (not method) then
		method, path, httpVersion, remaining = reqStr:match("(%w+) (.+) (HTTP/.-)\n(.+)")
	end
	local headers = Headers.new()
	for k,v in remaining:gmatch("(.-): (.-)\n") do
		headers:Set(k, v)
	end
	if (body and #body == 0) then
		body = nil
	end
	local query = {}
	if (path:find("%?")) then
		local queryString = nil
		path, queryString = path:match("(.-)%?(.+)")
		for _,qItem in ipairs(Util.StringSplit(queryString, "&")) do
			local key, val = qItem:match("^(.-)=(.+)$")
			query[key] = Util.DecodeURIComponent(val)
		end
	end
	local self = setmetatable({
		Method = method;
		Path = path;
		Query = query;
		HttpVersion = httpVersion;
		Headers = headers;
		Body = body;
	}, Request)
	return self
end

function Request:Accepts(mime)
	return (self.Headers.Accept and self.Headers.Accept:find(mime) ~= nil)
end

return Request