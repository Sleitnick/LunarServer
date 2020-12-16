local Util = {}

local function Decode(hex)
	return string.char(tonumber(hex, 16))
end

function Util.DecodeURIComponent(uriComponent)
	return uriComponent:gsub("%%(%x%x)", Decode)
end

function Util.StringSplit(inputstr, sep)
	if (sep == nil) then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

return Util