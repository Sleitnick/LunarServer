# LunarServer

Lua server runtime

**Note:** This is experimental and should not be used for any real projects.

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
```

### Response
```
.Headers: Headers
.Status: number
.StatusText: string;
.Body: string;

:HTML(filepath: string [, format: table]): Response
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
