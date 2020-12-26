--[[
print("START JSON TEST")

local json_lua = require("jsonlua")

local data = {
	{
		"xyz",
		"hello"
	},
	{
		hello = 32;
		data = {
			nested = 64;
		};
		nothing = {};
	},
	"test",
	"abc",
	"123",
	32,
	64
}

local start = os.clock()
local str = json.stringify(data)
local dur = (os.clock() - start)
print(str)
print(("C JSON Stringify duration: %.2fms"):format(dur * 1000))

local start2 = os.clock()
local luastr = json_lua.Stringify(data)
local dur2 = (os.clock() - start2)
print(("Lua JSON Stringify duration: %.2fms"):format(dur2 * 1000))

print("END JSON TEST")
]]
return {
	Port = 8080;
	Handler = "handler";
}