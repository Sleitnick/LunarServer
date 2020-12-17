local JSON = {}

local function ToJSONString(value)
	if (type(value) == "string") then
		return ("%q"):format(value)
	elseif (value == nil) then
		return "null"
	else
		return tostring(value)
	end
end

function JSON.Parse(str)
	local tokens = {}
	local codepoints = {}
	for _,c in utf8.codes(str) do
		table.insert(codepoints, c)
	end
	local index = 1
	local TokenizeObject, TokenizeArray, TokenizeString, TokenizeNumber, TokenizeValue
	local function GetCodepoints(ind, num)
		local all = {}
		for i = ind,ind + num - 1 do
			table.insert(all, codepoints[i])
		end
		return table.unpack(all)
	end
	TokenizeObject = function()
		table.insert(tokens, {s = "{", type = "obj"})
		index = (index + 1)
		local lookingForKey = true
		local lookingForColon = false
		local lookingForValue = false
		local foundAnyKey = false
		while (index < #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8.char(codepoint)
			if (lookingForKey) then
				if (char:match("%s")) then
					index = (index + 1)
				elseif (char == "\"") then
					TokenizeString()
					lookingForKey = false
					lookingForColon = true
					foundAnyKey = true
				elseif ((not foundAnyKey) and char == "}") then
					table.insert(tokens, {s = "}", type = "obj"})
					index = (index + 1)
					break
				end
			elseif (lookingForColon) then
				if (char:match("%s")) then
					index = (index + 1)
				elseif (char == ":") then
					table.insert(tokens, {s = ":", type = "col"})
					lookingForColon = false
					lookingForValue = true
					index = (index + 1)
					print(char)
				else
					error("Expected \":\" after object key; got \"" .. char .. "\"")
				end
			elseif (lookingForValue) then
				if (char:match("%s")) then
					index = (index + 1)
				else
					TokenizeValue()
					lookingForValue = false
				end
			else
				if (char:match("%s")) then
					index = (index + 1)
				elseif (char == ",") then
					lookingForKey = true
					table.insert(tokens, {s = ",", type = "sep"})
					index = (index + 1)
				elseif (char == "}") then
					table.insert(tokens, {s = "}", type = "obj"})
					index = (index + 1)
					break
				else
					error("Expected \",\" or \"}\" between values; got \"" .. char .. "\"")
				end
			end
		end
	end
	TokenizeArray = function()
		table.insert(tokens, {s = "[", type = "arr"})
		index = (index + 1)
		local gotValue = false
		local gotSep = false
		while (index < #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8.char(codepoint)
			if (char:match("%s")) then
				index = (index + 1)
			elseif (char == "]") then
				if (gotSep) then
					error("Cannot end array with comma")
				end
				index = (index + 1)
				table.insert(tokens, {s = "]", type = "arr"})
				break
			elseif (gotValue) then
				if (char == ",") then
					table.insert(tokens, {s = ",", type = "sep"})
					index = (index + 1)
					gotValue = false
					gotSep = true
				else
					error("Unknown symbol when expecting comma in array: \"" .. char .. "\"")
				end
			elseif (not gotValue) then
				gotSep = false
				if (char == ",") then
					error("More than one comma in a row within array")
				end
				TokenizeValue()
				gotValue = true
			end
		end
	end
	TokenizeString = function()
		table.insert(tokens, {s = "\"", type = "qt"})
		index = (index + 1)
		local startIndex = index
		local ctrl = false
		while (index < #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8.char(codepoint)
			if (ctrl) then
				if (char == "\"" or char == "\\" or char == "/" or char == "b" or char == "f" or char == "n" or char == "r" or char == "t") then
					index = (index + 1)
					ctrl = false
				elseif (char == "u" and utf8.char(GetCodepoints(index + 1, 4)):lower():match("^[0-9a-f]+$")) then
					index = (index + 1)
					ctrl = false
				else
					error("Bad control character: \"" .. char .. "\"")
				end
			else
				if (char == "\\") then
					index = (index + 1)
					ctrl = true
				elseif (char == "\"") then
					break
				else
					index = (index + 1)
				end
			end
		end
		local strng = utf8.char(GetCodepoints(startIndex, (index - startIndex)))
		table.insert(tokens, {s = strng, type = "str"})
		table.insert(tokens, {s = "\"", type = "qt"})
		index = (index + 1)
	end
	TokenizeNumber = function()
		local startIndex = index
		local char = utf8.char(codepoints[index])
		local function GetAllDigits(throwIfNone)
			local startIndex = index
			while (index < #codepoints) do
				char = utf8.char(codepoints[index])
				if (char:match("%d")) then
					index = (index + 1)
				else
					break
				end
			end
			if (throwIfNone and startIndex == index) then
				error("Invalid number")
			end
		end
		if (char == "-") then
			index = (index + 1)
			char = utf8.char(codepoints[index])
		end
		if (char:match("[1-9]")) then
			index = (index + 1)
			GetAllDigits(false)
		else
			index = (index + 1)
		end
		char = utf8.char(codepoints[index])
		if (char == ".") then
			index = (index + 1)
			GetAllDigits(true)
		end
		char = utf8.char(codepoints[index])
		if (char == "e" or char == "E") then
			index = (index + 1)
			char = utf8.char(codepoints[index])
			if (char == "+" or char == "-") then
				index = (index + 1)
			end
			GetAllDigits(true)
		end
		local num = utf8.char(GetCodepoints(startIndex, (index - startIndex)))
		table.insert(tokens, {s = num, type = "num"})
	end
	TokenizeValue = function(top)
		while (index < #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8.char(codepoint)
			if (top and char:match("%s")) then
				index = (index + 1)
			elseif (char == "{") then
				TokenizeObject()
			elseif (char == "[") then
				TokenizeArray()
			elseif (char == "\"") then
				TokenizeString()
			elseif (char == "-" or char:match("%d")) then
				TokenizeNumber()
			elseif (char == "t" and utf8.char(GetCodepoints(index, 4)) == "true") then
				-- Boolean true
				table.insert(tokens, {s = "true", type = "bool"})
				index = (index + 4)
			elseif (char == "f" and utf8.char(GetCodepoints(index, 5)) == "false") then
				-- Boolean true
				table.insert(tokens, {s = "false", type = "bool"})
				index = (index + 5)
			elseif (char == "n" and utf8.char(GetCodepoints(index, 4)) == "null") then
				-- Nil
				table.insert(tokens, {s = "null", type = "null"})
				index = (index + 4)
			elseif (top) then
				error("Unknown symbol in value: \"" .. char .. "\"")
			else
				break
			end
		end
	end
	TokenizeValue(true)
	print("JSON PARSED TOKENS:")
	for i,token in ipairs(tokens) do
		print(i, token.type, token.s)
	end


	-- TODO: Parse the tokens into a Lua table
	error("JSON Parse not yet implemented")


end

function JSON.Stringify(value)
	local function Stringify(value)
		local function TableToJSON(tbl, cyclicRef)
			assert(cyclicRef[tbl] == nil, "Cannot have cyclical tables")
			cyclicRef[tbl] = true
			local isArray = (#tbl > 0)
			if (isArray) then
				local stringBuilder = {}
				for _,v in ipairs(tbl) do
					table.insert(stringBuilder, Stringify(v, cyclicRef))
				end
				return "[" .. table.concat(stringBuilder, ",") .. "]"
			else
				local stringBuilder = {}
				for k,v in pairs(tbl) do
					assert(type(k) == "string", "Object must only have string keys")
					local key = ToJSONString(k)
					local value = Stringify(v, cyclicRef)
					table.insert(stringBuilder, ("%s: %s"):format(key, value))
				end
				return "{" .. table.concat(stringBuilder, ",") .. "}"
			end
			return table.concat(stringBuilder, "")
		end
		if (type(value) == "table") then
			return TableToJSON(value, {})
		else
			return ToJSONString(value)
		end
	end
	return Stringify(value)
end

JSON.Decode = JSON.Parse
JSON.Encode = JSON.Stringiy

return JSON
