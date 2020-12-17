package.path = (package.path .. ";src/scripts/?.lua")

local JSON = require("json")

local jsonFile = assert(io.open("./jsontest.json", "r"), "Failed to open JSON file")
local jsonStr = jsonFile:read("*a")
jsonFile:close()
local parsed = JSON.Parse(jsonStr)

print(parsed)
