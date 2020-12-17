# LunarServer

A stateless, multi-threaded, fast, and easy Lua server runtime.

**Warning:** This is experimental and should not be used for any real projects.

## Prerequisites
- Docker
- Make

## Build

```sh
make build
```

## Run

1. In your working directory, create a `config.lua` file with the following format:
	```lua
	-- config.lua
	return {
		Port = 8080;
		Handler = "handler"; -- Note: No file extension
	}
	```
1. Create the `handler.lua` file:
	```lua
	-- handler.lua
	return function(request, response)
		response:Text("Hello world!"):Send()
	end
	```
1. Run LunarServer:
	```sh
	docker run --rm -it --mount 'type=bind,src=${PWD},dst=/app' -p 8080:8080 lunarserver lunarserver /app/config.lua
	```

Tips:

- Make sure the bound port within the `docker run` command is the same as the port defined in the `config.lua` file.
- The naming of `config.lua` and `handler.lua` can be anything, as long as the `docker run` command points to the config file and the config file points to the handler file under the Handler property.

## API

### Request
```
.Method: string;
.Path: string;
.Query: table;
.Headers: Headers;
.Body: string;

:Accepts(mime: string): boolean
:JSON(json: string): table|string|boolean|number|nil
```

### Response
```
.Headers: Headers
.Status: number
.StatusText: string;
.Body: string;

:HTML(filepath: string [, format: table]): Response
:JSON(value: table|string|boolean|number|nil): Response
:Text(text: string): Response
:File(filepath: string): Response
:SetStatus(status: number [, statusText: string]): Response
:Send(): void
:SendIfOk(): void
```

### Headers
```
[name: string]: string
[name: string] = value: string

:Get(name: string): string
:Set(name: string, value: string): void
:SetIfNil(name: string, value: string): boolean
:Has(name: string): boolean
:All(): table
```

### Util
```
local Util = require("util")

.DecodeURIComponent(uriComponent: string): string
.StringSplit(str: string, sep: string): table
```

### Route
```
local Route = require("route")

CONSTRUCTOR:
.new()

METHODS:
:On(path: string, callback: (req: Request, res: Response, nxt: function) -> void): Route
:Get(path: string, callback: (req: Request, res: Response) -> void): Route
:Post(path: string, callback: (req: Request, res: Response) -> void): Route
:Put(path: string, callback: (req: Request, res: Response) -> void): Route
:Delete(path: string, callback: (req: Request, res: Response) -> void): Route
:Patch(path: string, callback: (req: Request, res: Response) -> void): Route
:Static(path: string, staticDirPath: string)
:NotFound(callback: (req: Request, res: Response) -> void)
:Run(req: Request, res: Response)
```

### JSON
```
local JSON = require("json")

.Parse(json: string): table|string|boolean|number|nil
.Stringify(value: table|string|boolean|number|nil)
```

## Router Example

```lua
-- config.lua
return {
	Port = 8080;
	Handler = "handler";
}
```

```lua
-- handler.lua

local route = require("route").new()

-- Log all requests:
route:On("*", function(req, res, nxt)
	print("Got request:", req.Path)
	nxt()
end)

-- Point "/static/..." to files under local public dir:
route:Static("/static", "./public")

-- Home page:
route:Get("/", function(req, res)
	res:HTML("./somewhere/index.html"):Send()
end)

-- Match path parameter:
route:Get("/api/{ID}", function(req, res)
	res:Text("ID: " .. req.Params.ID):Send()
end)

-- Handle posting JSON data on an API endpoint:
route:Post("/api/{ID}", function(req, res)
	local data = req:JSON() -- {"info": "hello world"}
	SomeDatabase:Write(req.params.ID, data.info)
	res:JSON({
		msg = "good";
	}):Send()
end)

-- Send a 404 HTML page:
route:NotFound(function(req, res)
	res:HTML("/somewhere/404.html"):Send()
end)

-- Run the router for each request:
return function(request, response)
	route:Run(request, response)
end
```