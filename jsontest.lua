local JSON = require("src/scripts/json")

local parsed = JSON.Parse([[
{
	"abc": [32, 75]
}
]])

print(#parsed.abc)

print(JSON.Stringify({
	Hello = 32;
}))