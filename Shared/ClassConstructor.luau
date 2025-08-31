--!strict
--!native
--!optimize 2
local Constructor = {}

function Constructor:__call(...)
	local object = {}
	setmetatable(object, self)

	if self.__init then
		self.__init(object, ...)
	end

	return object
end

function Constructor.class(newClass)
	newClass.__index = newClass
	return setmetatable(newClass, Constructor)
end

return Constructor