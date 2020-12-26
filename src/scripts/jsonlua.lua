local Symbol = require("symbol")

local JSON = {}

JSON.Null = Symbol.new("JSON_NULL")

local ALLOWED_STRINGIFY_TYPES = {
	["nil"] = true;
	["boolean"] = true;
	["number"] = true;
	["string"] = true;
	["userdata"] = true;
	["table"] = true;
}

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

	local table_insert = table.insert
	local table_unpack = table.unpack
	local utf8_codes = utf8.codes
	local utf8_char = utf8.char

	local startClock = os.clock()

	local tokens = {}
	local codepoints = {}
	for _,c in utf8_codes(str) do
		table_insert(codepoints, c)
	end

	local index, tokenIndex = 1, 1

	local TokenizeObject, TokenizeArray, TokenizeString, TokenizeNumber, TokenizeValue
	local ParseObject, ParseArray, ParseString, ParseNumber, ParseToken

	local function GetCodepoints(ind, num)
		local all = {}
		for i = ind,ind + num - 1 do
			table_insert(all, codepoints[i])
		end
		return table_unpack(all)
	end

	TokenizeObject = function()
		table_insert(tokens, {s = "{", type = "obj"})
		index = (index + 1)
		local lookingForKey = true
		local lookingForColon = false
		local lookingForValue = false
		local foundAnyKey = false
		local completed = false
		while (index <= #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8_char(codepoint)
			if (lookingForKey) then
				if (char:match("%s")) then
					index = (index + 1)
				elseif (char == "\"") then
					TokenizeString()
					lookingForKey = false
					lookingForColon = true
					foundAnyKey = true
				elseif ((not foundAnyKey) and char == "}") then
					table_insert(tokens, {s = "}", type = "obj"})
					index = (index + 1)
					completed = true
					break
				else
					error("Unknown symbol when looking for object key: \"" .. char .. "\"")
				end
			elseif (lookingForColon) then
				if (char:match("%s")) then
					index = (index + 1)
				elseif (char == ":") then
					lookingForColon = false
					lookingForValue = true
					index = (index + 1)
				else
					error("Expected \":\" after object key; got \"" .. char .. "\"", 0)
				end
			elseif (lookingForValue) then
				if (char:match("%s")) then
					index = (index + 1)
				else
					local i = index
					TokenizeValue()
					if (i ~= index) then
						lookingForValue = false
					else
						error("Expected value", 0)
					end
				end
			else
				if (char:match("%s")) then
					index = (index + 1)
				elseif (char == ",") then
					lookingForKey = true
					--table_insert(tokens, {s = ",", type = "sep"})
					index = (index + 1)
				elseif (char == "}") then
					table_insert(tokens, {s = "}", type = "obj"})
					index = (index + 1)
					completed = true
					break
				else
					error("Expected \",\" or \"}\" between values; got \"" .. char .. "\"")
				end
			end
		end
		if (not completed) then
			error("Incomplete object", 0)
		end
	end

	TokenizeArray = function()
		table_insert(tokens, {s = "[", type = "arr"})
		index = (index + 1)
		local gotValue = false
		local gotSep = false
		local completed = false
		while (index <= #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8_char(codepoint)
			if (char:match("%s")) then
				index = (index + 1)
			elseif (char == "]") then
				if (gotSep) then
					error("Cannot end array with comma", 0)
				end
				index = (index + 1)
				table_insert(tokens, {s = "]", type = "arr"})
				completed = true
				break
			elseif (gotValue) then
				if (char == ",") then
					--table_insert(tokens, {s = ",", type = "sep"})
					index = (index + 1)
					gotValue = false
					gotSep = true
				else
					error("Unknown symbol when expecting comma in array: \"" .. char .. "\"", 0)
				end
			elseif (not gotValue) then
				gotSep = false
				if (char == ",") then
					error("More than one comma in a row within array", 0)
				end
				TokenizeValue()
				gotValue = true
			end
		end
		if (not completed) then
			error("Incomplete array", 0)
		end
	end

	TokenizeString = function()
		index = (index + 1)
		local startIndex = index
		local ctrl = false
		local completed = false
		while (index <= #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8_char(codepoint)
			if (ctrl) then
				if (char == "\"" or char == "\\" or char == "/" or char == "b" or char == "f" or char == "n" or char == "r" or char == "t")
						or (char == "u" and utf8_char(GetCodepoints(index + 1, 4)):lower():match("^[0-9a-f]+$")) then
					index = (index + 1)
					ctrl = false
				else
					error("Bad control character: \"" .. char .. "\"", 0)
				end
			else
				if (char == "\\") then
					index = (index + 1)
					ctrl = true
				elseif (char == "\"") then
					completed = true
					break
				else
					index = (index + 1)
				end
			end
		end
		if (not completed) then
			error("Incomplete string", 0)
		end
		local strng = utf8_char(GetCodepoints(startIndex, (index - startIndex)))
		index = (index + 1)
		table_insert(tokens, {s = strng, type = "str"})
	end

	TokenizeNumber = function()
		local startIndex = index
		local char = utf8_char(codepoints[index])
		local function GetAllDigits(throwIfNone)
			local startInd = index
			while (index <= #codepoints) do
				char = utf8_char(codepoints[index])
				if (char:match("%d")) then
					index = (index + 1)
				else
					break
				end
			end
			if (throwIfNone and startInd == index) then
				error("Invalid number", 0)
			end
		end
		if (char == "-") then
			index = (index + 1)
			char = utf8_char(codepoints[index])
		end
		if (char:match("[1-9]")) then
			index = (index + 1)
			GetAllDigits(false)
		else
			index = (index + 1)
		end
		char = utf8_char(codepoints[index])
		if (char == ".") then
			index = (index + 1)
			GetAllDigits(true)
		end
		char = utf8_char(codepoints[index])
		if (char == "e" or char == "E") then
			index = (index + 1)
			char = utf8_char(codepoints[index])
			if (char == "+" or char == "-") then
				index = (index + 1)
			end
			GetAllDigits(true)
		end
		local num = utf8_char(GetCodepoints(startIndex, (index - startIndex)))
		table_insert(tokens, {s = num, type = "num"})
	end

	TokenizeValue = function(top)
		while (index <= #codepoints) do
			local codepoint = codepoints[index]
			local char = utf8_char(codepoint)
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
			elseif (char == "t" and utf8_char(GetCodepoints(index, 4)) == "true") then
				table_insert(tokens, {s = true, type = "bool"})
				index = (index + 4)
			elseif (char == "f" and utf8_char(GetCodepoints(index, 5)) == "false") then
				table_insert(tokens, {s = false, type = "bool"})
				index = (index + 5)
			elseif (char == "n" and utf8_char(GetCodepoints(index, 4)) == "null") then
				table_insert(tokens, {s = "null", type = "null"})
				index = (index + 4)
			elseif (top) then
				error("Unknown symbol in value: \"" .. char .. "\"", 0)
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
		elseif (t == "bool") then
			return token.s
		elseif (t == "null") then
			return JSON.Null
		end
	end

	ParseObject = function(_startToken)
		local obj = {}
		tokenIndex = (tokenIndex + 1)
		local key = nil
		while (tokenIndex <= #tokens) do
			local token = tokens[tokenIndex]
			if (not key) then
				if (token.type == "str") then
					key = ParseString(token)
				elseif (token.type == "obj") then
					break
				else
					error("Parse error: Unexpected token parsing object: \"" .. token.type .. "\"", 0)
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

	ParseArray = function(_startToken)
		local arr = {}
		tokenIndex = (tokenIndex + 1)
		while (tokenIndex <= #tokens) do
			local token = tokens[tokenIndex]
			if (token.type == "arr" and token.s == "]") then
				break
			end
			local value = ParseToken(token)
			table_insert(arr, value)
			tokenIndex = (tokenIndex + 1)
		end
		return arr
	end

	ParseString = function(token)
		return token.s
	end

	ParseNumber = function(token)
		return tonumber(token.s)
	end

	TokenizeValue(true)
	assert(#tokens > 0, "No tokens")

	local startClockParse = os.clock()
	print(("Tokenize: %.0fms"):format((startClockParse - startClock) * 1000))

	local retVal = ParseToken(tokens[1])

	print(("Parse: %.0fms"):format((os.clock() - startClockParse) * 1000))
	print(("Total: %.0fms"):format((os.clock() - startClock) * 1000))

	return retVal

end

function JSON.Stringify(luaValue)
	local table_insert = table.insert
	local function Stringify(value)
		assert(ALLOWED_STRINGIFY_TYPES[type(value)], "Type \"" .. type(value) .. "\" cannot be encoded")
		local function TableToJSON(tbl, cyclicRef)
			assert(cyclicRef[tbl] == nil, "Cannot have cyclical tables")
			cyclicRef[tbl] = true
			local isArray = (#tbl > 0)
			if (isArray) then
				local stringBuilder = {}
				for _,v in ipairs(tbl) do
					table_insert(stringBuilder, Stringify(v, cyclicRef))
				end
				return "[" .. table.concat(stringBuilder, ",") .. "]"
			else
				local stringBuilder = {}
				for k,v in pairs(tbl) do
					assert(type(k) == "string", "Object must only have string keys")
					local key = ToJSONString(k)
					local val = Stringify(v, cyclicRef)
					table_insert(stringBuilder, ("%s:%s"):format(key, val))
				end
				return "{" .. table.concat(stringBuilder, ",") .. "}"
			end
		end
		if (type(value) == "table") then
			return TableToJSON(value, {})
		else
			return ToJSONString(value)
		end
	end
	return Stringify(luaValue)
end

JSON.Decode = JSON.Parse
JSON.Encode = JSON.Stringiy

return JSON
