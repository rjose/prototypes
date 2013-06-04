local Person = {}

function Person:_new(obj)
	obj = obj or {}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

-- *skills* is an array of skills
function Person.new(name, skills)
	local result = Person:_new{name = name}
	result.skill_distrib = {}

	if (#skills == 0) then
		return result
	end

	-- The default skill distribution will be 100% for the first skill and
	-- 0% for the rest.
	for i = 1, #skills do
		result.skill_distrib[skills[i].name] = 0.0
	end
	result.skill_distrib[skills[1].name] = 1.0
	return result
end

function Person:print_skill_distrib()
	for k, v in pairs(self.skill_distrib) do
		print(string.format("%s: %f", k, v))
	end
end

return Person
