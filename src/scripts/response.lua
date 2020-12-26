local Headers = require("headers")
local JSON = require("jsonlua")

local EXT_MIME_MAP = {

	[".css"] = "text/css";
	[".csv"] = "text/csv";
	[".html"] = "text/html";
	[".ics"] = "text/calendar";
	[".js"] = "text/javascript";
	[".txt"] = "text/plain";

	[".gif"] = "image/gif";
	[".jpeg"] = "image/jpeg";
	[".jpg"] = "image/jpeg";
	[".png"] = "image/png";
	[".svg"] = "image/svg+xml";
	[".tif"] = "image/tiff";
	[".tiff"] = "image/tiff";
	[".webp"] = "image/webp";
	[".ico"] = "image/vnd.microsoft.icon";

	[".bin"] = "application/octet-stream";
	[".gz"] = "application/gzip";
	[".json"] = "application/json";
	[".jsonld"] = "application/ld+json";
	[".ogx"] = "application/ogg";
	[".pdf"] = "application/pdf";
	[".rar"] = "application/vnd.rar";
	[".rtf"] = "application/rtf";
	[".tar"] = "application/x-tar";
	[".xml"] = "application/xml";
	[".zip"] = "application/zip";
	[".7z"] = "application/x-7z-compressed";

	[".aac"] = "audio/aac";
	[".mid"] = "audio/midi";
	[".midi"] = "audio/midi";
	[".mp3"] = "audio/mpeg";
	[".ogg"] = "audio/ogg";
	[".opus"] = "audio/opus";
	[".wav"] = "audio/wav";
	[".weba"] = "audio/webm";

	[".avi"] = "video/x-msvideo";
	[".mpeg"] = "video/mpeg";
	[".ogv"] = "video/ogg";
	[".ts"] = "video/mp2t";
	[".webm"] = "video/webm";

	[".otf"] = "font/otf";
	[".ttf"] = "font/ttf";
	[".woff"] = "font/woff";
	[".woff2"] = "font/woff2";

}

local NON_BINARY = {
	[".css"] = true; [".csv"] = true; [".html"] = true; [".ics"] = true; [".js"] = true;
	[".txt"] = true; [".json"] = true; [".jsonld"] = true; [".xml"] = true;
}

local Response = {}
Response.__index = Response

function Response.new()
	local self = setmetatable({
		Headers = Headers.new();
		Status = 200;
		StatusText = "OK";
		Body = "";
		_send = false;
	}, Response)
	return self
end

function Response:HTML(filepath, format)
	local file = io.open(filepath, "r")
	assert(file, "Failed to open " .. filepath)
	local content = file:read("*a")
	file:close()
	if (type(format) == "table") then
		content = content:gsub("%b{}", function(s)
			local capture = s:sub(3, -3)
			if (capture) then
				local key = capture:match("^%s*(.-)%s*$")
				if (key) then
					return format[key]
				end
			end
		end)
	end
	self.Body = content
	self.Headers["Content-Type"] = "text/html"
	self.Headers["Connection"] = "Keep-Alive"
	return self
end

function Response:JSON(value)
	local content = JSON.Stringify(value)
	self.Body = content
	self.Headers["Content-Type"] = "application/json"
	self.Headers["Connection"] = "Keep-Alive"
	return self
end

function Response:Text(text)
	self.Body = text
	self.Headers["Content-Type"] = "text/plain"
	self.Headers["Connection"] = "Keep-Alive"
	return self
end

function Response:File(filepath)
	local extension = filepath:match("%.[^.]+$")
	local isBinary = ((not extension) or (not NON_BINARY[extension]))
	local file = io.open(filepath, isBinary and "rb" or "r")
	if (not file) then
		self:SetStatus(404, "Not Found")
		return self
	end
	local content = file:read("*a")
	file:close()
	local mime = (extension and EXT_MIME_MAP[extension] or "text/plain")
	self.Body = content
	self.Headers["Content-Type"] = mime
	self.Headers["Connection"] = "Keep-Alive"
	return self
end

function Response:SetStatus(statusCode, text)
	self.Status = statusCode
	self.StatusText = (text or "")
	return self
end

function Response:Send()
	self._send = true
end

function Response:SendIfOk()
	if (self.Status >= 200 and self.Status <= 200) then
		self:Send()
	end
end

function Response:__tostring()
	self.Headers:SetIfNil("Content-Type", "text/plain")
	self.Headers:Set("Content-Length", #(self.Body or ""))
	self.Headers:Set("Server", "LunarServer")
	self.Headers:Set("Date", os.date("%a, %d %b %Y %X GMT"))
	local res = ("HTTP/1.1 %i%s\r\n%s\r\n\r\n%s"):format(
		self.Status,
		self.StatusText and " " .. self.StatusText or "",
		tostring(self.Headers),
		self.Body
	)
	return res
end

return Response
