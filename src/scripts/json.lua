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

	local index, tokenIndex = 1, 1

	local TokenizeObject, TokenizeArray, TokenizeString, TokenizeNumber, TokenizeValue
	local ParseObject, ParseArray, ParseString, ParseNumber, ParseToken

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
					lookingForColon = false
					lookingForValue = true
					index = (index + 1)
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
		local startIndex = index
		index = (index + 1)
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
		index = (index + 1)
		local strng = utf8.char(GetCodepoints(startIndex, (index - startIndex)))
		table.insert(tokens, {s = strng, type = "str"})
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

	ParseToken = function(token)
		local t = token.type
		if (t == "obj") then
			return ParseObject(token)
		elseif (t == "arr") then
			return ParseArray(token)
		elseif (t == "str") then
			return ParseString(token)
		elseif (t == "num") then
			return ParseNumber(token)
		end
	end

	ParseObject = function(startToken)
		local obj = {}
		tokenIndex = (tokenIndex + 1)
		local key = nil
		while (tokenIndex < #tokens) do
			local token = tokens[tokenIndex]
			if (not key) then
				if (token.type == "str") then
					key = ParseString(token)
				elseif (token.type == "obj") then
					break
				else
					warn("Parse error: Unexpected token parsing object: \"" .. token.type .. "\"")
				end
			else
				local value = ParseToken(token)
				obj[key] = value
				key = nil
			end
			tokenIndex = (tokenIndex + 1)
		end
		return obj
	end

	ParseArray = function(startToken)
		local arr = {}
		tokenIndex = (tokenIndex + 1)
		while (tokenIndex < #tokens) do
			local token = tokens[tokenIndex]
			if (token.type == "arr" and token.s == "]") then
				break
			end
			local value = ParseToken(token)
			table.insert(arr, value)
			tokenIndex = (tokenIndex + 1)
		end
		return arr
	end

	ParseString = function(token)
		return token.s:sub(2, -2)
	end

	ParseNumber = function(token)
		return tonumber(token.s)
	end

	TokenizeValue(true)
	assert(#tokens > 0, "No tokens")

	return ParseToken(tokens[1])

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
