local Symbol = {}
Symbol.__index = Symbol

function Symbol.new(id)
    local self = setmetatable({
        _id = id;
    }, Symbol)
    return self
end

function Symbol:__tostring()
    return ("Symbol<%s>"):format(self._id)
end

return Symbol
