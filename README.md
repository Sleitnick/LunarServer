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

### About the Handler
The Handler script handles all requests sent to the server. Similar to AWS Lambdas, these handlers are stateless in design.

Also like Lambdas, LunarServer handlers will spawn for each request, but will be kept warm for a period of time. Thus it is most beneficial to create routes, connect to databases, etc., outside of the returned function handler. (See the Router example at the bottom of this document.)

### Tips

- Make sure the bound port within the `docker run` command is the same as the port defined in the `config.lua` file.
- The naming of `config.lua` and `handler.lua` can be anything, as long as the `docker run` command points to the config file and the config file points to the handler file under the Handler property.

## API

### Request
```
.Method: string
.Path: string
.Query: table
.Headers: Headers
.Body: string

:Accepts(mime: string): boolean
:JSON(json: string): table|string|boolean|number|nil
```

### Response
```
.Headers: Headers
.Status: number
.StatusText: string
.Body: string

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
local JSON = require("jsonlua")

.Null: Symbol

.Parse(json: string): table|string|boolean|number|JSON.Null
.Stringify(value: table|string|boolean|number|nil|JSON.Null)
```

An important note is that Lua doesn't support `nil` types within a table, unlike JSON. To make up for this, the JSON library for LunarServer includes the `JSON.Null` symbol to represent any `null` values within JSON.

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
	SomeDatabase:Write(req.Params.ID, data.info)
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