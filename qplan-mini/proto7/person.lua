local Person = {}

function Person:_new(obj)
        obj = obj or {}
        setmetatable(obj, self)
        self.__index = self
        return obj
end

function Person.new(options)
	id = options.id or ""
        name = options.name or ""
        skills = options.skills or {}

	return Person:_new{id = id .. "", name = name, skills = skills}
end

function Person:get_skill_avail(num_weeks)
	local result = {}
	for skill, frac in pairs(self.skills) do
		result[skill] = frac * num_weeks
	end
	return result
end

return Person
