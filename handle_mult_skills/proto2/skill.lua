local Skill = {}

function Skill:_new(obj)
	obj = obj or {}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function Skill.new(name)
	result = Skill:_new{name = name}
	return result
end

return Skill
