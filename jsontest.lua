package.path = (package.path .. ";src/scripts/?.lua")

local JSON = require("json")

local parsed = JSON.Parse([[
{
	"abc": [32, 75, null, true, false, null]
}
]])

print(table.unpack(parsed.abc))
