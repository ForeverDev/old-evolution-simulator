return function(classname)
	local class = {}
	class.__index = class
	return setmetatable(class, {
		__call = function(self, ...)
			local instance = setmetatable({classname = classname}, self)
			if instance.init then
				instance:init(...)
			end
			return instance
		end
	})
end
