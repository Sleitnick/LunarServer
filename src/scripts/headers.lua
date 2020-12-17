local Headers = {}


function Headers.new()
	local self = setmetatable({
		_headers = {};
	}, Headers)
	return self
end


function Headers:Get(name)
	return self._headers[name:lower()]
end


function Headers:Has(name)
	return (self._headers[name:lower()] ~= nil)
end


function Headers:Set(name, value)
	self._headers[name:lower()] = tostring(value)
end


function Headers:SetIfNil(name, value)
	if (not self:Has(name)) then
		self:Set(name, value)
		return true
	end
	return false
end


function Headers:All()
	return self._headers
end


function Headers:__tostring()
	local list = {}
	for k,v in pairs(self._headers) do
		table.insert(list, {k, v})
	end
	table.sort(list, function(a, b)
		return (a[1] < b[1])
	end)
	for i,v in ipairs(list) do
		local key = (v[1]:sub(1, 1):upper() .. v[1]:sub(2):lower():gsub("%-(%a)", function(s) return "-" .. s:upper() end))
		list[i] = ("%s: %s"):format(key, v[2])
	end
	return table.concat(list, "\r\n")
end


function Headers:__index(name)
	local prop = Headers[name]
	if (prop ~= nil) then
		return prop
	end
	return Headers.Get(self, name)
end


function Headers:__newindex(name, value)
	self:Set(name, value)
end


return Headers
