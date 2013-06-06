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

function add_skill_avail(a1, a2)
	local result = {}
	for k, v in pairs(a1) do result[k] = v end

        for skill, avail in pairs(a2) do
                if result[skill] then
			result[skill] = result[skill] + avail
                else
                        result[skill] = avail
                end
        end
        return result
end

-- Abstract this between here and work.lua
function Person.sum_skill_avail(people, num_weeks)
	local result = {}
	for _, person in pairs(people) do
		result = add_skill_avail(result, person:get_skill_avail(num_weeks))
	end
	return result
end

return Person
